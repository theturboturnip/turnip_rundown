import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'package:turnip_rundown/data.dart';

import 'package:turnip_rundown/data/http_cache_repository.dart';
import 'package:turnip_rundown/data/settings/repository.dart';
import 'package:turnip_rundown/data/weather_data_bank_repository.dart';
import 'package:turnip_rundown/util.dart';

// A class that implements both ApiCache and Settings repositories on top of a single sqlite database.
// On Android the cache and settings dbs are in separate files, because the platform requests it.
// Both repositories are capable of both behaviours, we just don't use them.
// On web, it's one DB.
class SqfliteApiCacheAndSettingsRepository extends WeatherDataBankRepository implements SettingsRepository {
  SqfliteApiCacheAndSettingsRepository(
    this.db,
    this._settings,
    this._lockedUtcLookaheadTo,
    this._lastGeocoordLookup, {
    required super.clients,
    required super.cachedWeatherDataAndSoftTimeouts,
  });

  final Database db;
  Settings _settings;
  UtcDateTime? _lockedUtcLookaheadTo;
  Coordinate? _lastGeocoordLookup;

  static Future<SqfliteApiCacheAndSettingsRepository> getRepository(
    String databasePath, {
    required Map<RequestedWeatherBackend, WeatherClient?> clients,
  }) async {
    final db = await openDatabase(
      databasePath,
      version: 5,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion == 0) {
          await db.execute("CREATE TABLE cache(uri TEXT UNIQUE, response TEXT, timeoutAfter TEXT)");
          await db.execute("CREATE TABLE stats(host TEXT UNIQUE, cacheHits INTEGER, cacheMisses INTEGER)");
          oldVersion = 1;
        }
        if (oldVersion == 1) {
          await db.execute("CREATE TABLE keyval(key TEXT UNIQUE, val TEXT)");
          await db.insert("keyval", {"key": "settingsJson", "val": "{}"});
          oldVersion = 2;
        }
        if (oldVersion == 2) {
          await db.insert("keyval", {"key": "lockedUtcLookaheadTo", "val": ""});
          oldVersion = 3;
        }
        if (oldVersion == 3) {
          await db.insert("keyval", {"key": "lastGeocoordLookup", "val": ""});
          oldVersion = 4;
        }
        if (oldVersion == 4) {
          await db.execute("CREATE TABLE weatherData(backend TEXT, coordJson TEXT, dataJson TEXT, utcSoftTimeout TEXT, utcHardTimeout TEXT)");
          oldVersion = 5;
        }
      },
    );
    final keyvalRows = await db.query("keyval", columns: ["key", "val"]);
    final keyvals = <String, String>{
      for (final row in keyvalRows) row["key"] as String: row["val"] as String,
    };
    final settings = Settings.fromJson(jsonDecode(keyvals["settingsJson"]!));
    final lockedUtcLookaheadTo = UtcDateTime.tryParseAndCoerceFullIso8601(keyvals["lockedUtcLookaheadTo"]!);
    final lastGeocoordLookupJson = keyvals["lastGeocoordLookup"]!;
    final lastGeocoordLookup = lastGeocoordLookupJson.isNotEmpty ? Coordinate.fromJson(jsonDecode(lastGeocoordLookupJson)) : null;

    final cachedWeatherRows = await db.query("weatherData", columns: ["backend", "coordJson", "dataJson", "utcSoftTimeout"]);
    late final Map<(RequestedWeatherBackend, Coordinate), (WeatherDataBank, UtcDateTime)> cachedWeather;
    try {
      cachedWeather = <(RequestedWeatherBackend, Coordinate), (WeatherDataBank, UtcDateTime)>{
        for (final row in cachedWeatherRows)
          (
            RequestedWeatherBackend.values.byName(row["backend"] as String),
            Coordinate.fromJson(jsonDecode(row["coordJson"] as String)),
          ): (
            WeatherDataBank.fromJson(jsonDecode(row["dataJson"] as String)),
            UtcDateTime.parseAndCoerceFullIso8601(row["utcSoftTimeout"] as String),
          ),
      };
    } catch (ex) {
      print("Got exception decoding cached weather: $ex");
      print("Clearing cached weather");
      await db.execute("DELETE FROM weatherData");
      cachedWeather = {};
    }

    final repo = SqfliteApiCacheAndSettingsRepository(
      db,
      settings,
      lockedUtcLookaheadTo,
      lastGeocoordLookup,
      clients: clients,
      cachedWeatherDataAndSoftTimeouts: cachedWeather,
    );
    await repo.clearTimedOutEntries();

    return repo;
  }

  @override
  void addToCache(RequestedWeatherBackend backend, Coordinate coords, WeatherDataBank data, UtcDateTime softTimeout) {
    super.addToCache(backend, coords, data, softTimeout);
    db.insert("weatherData", {
      "backend": backend.name,
      "coordJson": jsonEncode(coords.toJson()),
      "dataJson": jsonEncode(data.toJson()),
      "utcHardTimeout": data.hardTimeout.toIso8601String(),
      "utcSoftTimeout": softTimeout.toIso8601String(),
    });
  }

  @override
  void clearCacheOfHardTimedOut() {
    super.clearCacheOfHardTimedOut();
    db.delete("weatherData", where: "utcHardTimeout < ?", whereArgs: [UtcDateTime.timestamp().toIso8601String()]);
  }

  // The Future will emit a [ClientException] if http fails.
  @override
  Future<String> makeHttpRequest(Uri uri, {Map<String, String>? headers, bool forceRefreshCache = false, Duration timeout = const Duration(minutes: 15)}) async {
    final timestamp = UtcDateTime.timestamp();
    if (!forceRefreshCache) {
      final cachedApiResponse = (await db.query(
        "cache",
        columns: ["response", "timeoutAfter"],
        where: "uri = ?",
        whereArgs: [uri.toString()],
      )).firstOrNull;
      final timeoutAfterStr = cachedApiResponse != null ? cachedApiResponse["timeoutAfter"] as String : null;
      final timeoutAfter = timeoutAfterStr != null ? UtcDateTime.tryParseAndCoerceFullIso8601(timeoutAfterStr) : null;
      if (timeoutAfter != null && timeoutAfter.isAfter(timestamp)) {
        await db.transaction((txn) async {
          await txn.rawInsert("INSERT OR IGNORE INTO stats (host, cacheHits, cacheMisses) VALUES (?, 0, 0)", [uri.host]);
          await txn.rawUpdate("UPDATE stats SET cacheHits = cacheHits + 1 WHERE host = ?", [uri.host]);
        });
        return cachedApiResponse!["response"] as String;
      }
    }

    await db.transaction((txn) async {
      await txn.rawInsert("INSERT OR IGNORE INTO stats (host, cacheHits, cacheMisses) VALUES (?, 0, 0)", [uri.host]);
      await txn.rawUpdate("UPDATE stats SET cacheMisses = cacheMisses + 1 WHERE host = ?", [uri.host]);
    });

    print("doing HTTP request $uri");

    final timeoutAfter = timestamp.add(timeout);
    final response = await http.read(uri, headers: headers);

    await db.rawInsert(
      "INSERT OR REPLACE INTO cache (uri, response, timeoutAfter) VALUES (?, ?, ?)",
      [
        uri.toString(),
        response,
        timeoutAfter.toIso8601String(),
      ],
    );

    return response;
  }

  @override
  Future<void> clearTimedOutEntries() async {
    await db.delete("cache", where: "timeoutAfter < ?", whereArgs: [UtcDateTime.timestamp().toIso8601String()]);
  }

  @override
  Future<ApiStats> getStats() async {
    final stats = await db.query("stats", columns: ["host", "cacheHits", "cacheMisses"]);
    return ApiStats(
      hostStats: {
        for (final row in stats)
          (row["host"] as String): HostStats(
            cacheHits: row["cacheHits"] as int,
            cacheMisses: row["cacheMisses"] as int,
          ),
      },
    );
  }

  @override
  Future<void> resetStats() async {
    await db.delete("stats");
  }

  @override
  Settings get settings => _settings;

  @override
  Future<void> storeSettings(Settings settings) async {
    await db.update("keyval", {"val": jsonEncode(settings.toJson())}, where: "key like 'settingsJson'");
    _settings = settings;
  }

  @override
  UtcDateTime? get lockedUtcLookaheadTo => _lockedUtcLookaheadTo;

  @override
  Future<void> storeLockedUtcLookaheadTo(UtcDateTime? lockedUtcLookaheadTo) async {
    if (lockedUtcLookaheadTo == null) {
      await db.update("keyval", {"val": ""}, where: "key like 'lockedUtcLookaheadTo'");
    } else {
      await db.update("keyval", {"val": lockedUtcLookaheadTo.toIso8601String()}, where: "key like 'lockedUtcLookaheadTo'");
    }
    _lockedUtcLookaheadTo = lockedUtcLookaheadTo;
  }

  @override
  Coordinate? get lastGeocoordLookup => _lastGeocoordLookup;

  @override
  Future<void> storeLastGeocoordLookup(Coordinate? lastGeocoordLookup) async {
    if (lastGeocoordLookup == null) {
      await db.update("keyval", {"val": "null"}, where: "key like 'lastGeocoordLookup'");
    } else {
      await db.update("keyval", {"val": jsonEncode(lastGeocoordLookup.toJson())}, where: "key like 'lastGeocoordLookup'");
    }
    _lastGeocoordLookup = lastGeocoordLookup;
  }
}
