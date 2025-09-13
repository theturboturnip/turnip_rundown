import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:turnip_rundown/data/http_cache_repository.dart';
import 'package:http/http.dart' as http;
import 'package:turnip_rundown/data/settings/repository.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather_data_bank_repository.dart';
import 'package:turnip_rundown/util.dart';

class InMemoryHttpCacheRepository extends WeatherDataBankRepository {
  InMemoryHttpCacheRepository({required super.clients}) : cache = {}, stats = {}, super(cachedWeatherDataAndSoftTimeouts: {});

  // Uri -> (timeout, response data)
  final Map<Uri, (UtcDateTime, String)> cache;
  final Map<String, HostStats> stats;

  // The Future will emit a [ClientException] if http fails
  @override
  Future<String> makeHttpRequest(
    Uri uri, {
    Map<String, String>? headers,
    bool forceRefreshCache = false,
    Duration timeout = const Duration(minutes: 15),
  }) async {
    final timestamp = UtcDateTime.timestamp();
    final cachedTimeoutAndResponse = cache[uri];

    final hostStats = stats[uri.host] ?? HostStats(cacheHits: 0, cacheMisses: 0);
    late final String response;

    // If we're forcing a reset
    // or we don't have anything in the cache
    // or we do have something in the cache but it's timed out
    if (forceRefreshCache || cachedTimeoutAndResponse == null || cachedTimeoutAndResponse.$1.isBefore(timestamp)) {
      // refetch
      print("fetching from $uri");
      response = await http.read(uri, headers: headers);
      cache[uri] = (timestamp.add(timeout), response);
      hostStats.cacheMisses += 1;
    } else {
      // use cached
      response = cachedTimeoutAndResponse.$2;
      hostStats.cacheHits += 1;
    }

    stats[uri.host] = hostStats;

    return response;
  }

  @override
  Future<void> clearTimedOutEntries() async {
    final timestamp = UtcDateTime.timestamp();
    cache.removeWhere((uri, timeoutAndResponse) => timeoutAndResponse.$1.isAfter(timestamp));
  }

  @override
  Future<ApiStats> getStats() async {
    return ApiStats(
      hostStats: Map.fromEntries(stats.entries),
    );
  }

  @override
  Future<void> resetStats() async {
    stats.clear();
  }
}

class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository({required this.prefs}) {
    _settings = Settings.fromJson(jsonDecode(prefs.getString("settingsJson") ?? "{}"));
    _lockedUtcLookaheadTo = UtcDateTime.tryParseAndCoerceFullIso8601(prefs.getString("lockedUtcLookaheadTo") ?? "");
    final lastGeocoordLookupJson = prefs.getString("lastGeocoordLookupJson") ?? "";
    _lastGeocoordLookup = lastGeocoordLookupJson.isNotEmpty ? Coordinate.fromJson(jsonDecode(lastGeocoordLookupJson)) : null;
  }

  final SharedPreferences prefs;
  late Settings _settings;
  UtcDateTime? _lockedUtcLookaheadTo;
  Coordinate? _lastGeocoordLookup;

  @override
  UtcDateTime? get lockedUtcLookaheadTo => _lockedUtcLookaheadTo;

  @override
  Future<void> storeLockedUtcLookaheadTo(UtcDateTime? lockedUtcLookaheadTo) async {
    prefs.setString("lockedUtcLookaheadTo", lockedUtcLookaheadTo?.toIso8601String() ?? "");
    _lockedUtcLookaheadTo = lockedUtcLookaheadTo;
  }

  @override
  Settings get settings => _settings;

  @override
  Future<void> storeSettings(Settings settings) async {
    prefs.setString("settingsJson", jsonEncode(settings.toJson()));
    _settings = settings;
  }

  @override
  Coordinate? get lastGeocoordLookup => _lastGeocoordLookup;

  @override
  Future<void> storeLastGeocoordLookup(Coordinate? lastGeocoordLookup) async {
    prefs.setString("lastGeocoordLookup", jsonEncode(lastGeocoordLookup?.toJson()));
    _lastGeocoordLookup = lastGeocoordLookup;
  }
}
