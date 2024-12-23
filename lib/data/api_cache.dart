import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

class HostStats {
  HostStats({required this.cacheHits, required this.cacheMisses});

  final int cacheHits;
  final int cacheMisses;
}

class ApiStats {
  ApiStats({required this.hostStats});

  final Map<String, HostStats> hostStats;
}

abstract class ApiCacheRepository {
  /// The Future will emit a [ClientException] if the http request is attempted and fails
  Future<String> makeHttpRequest(Uri uri, {bool forceRefreshCache = false, Duration timeout = const Duration(minutes: 15)});
  Future<void> clearTimedOutEntries();
  Future<void> resetStats();
  Future<ApiStats> getStats();
}

class SqfliteApiCacheRepository extends ApiCacheRepository {
  SqfliteApiCacheRepository(this.db);

  final Database db;

  static Future<SqfliteApiCacheRepository> getRepository(String databasePath) async {
    final db = await openDatabase(
      databasePath,
      version: 1,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion == 0) {
          await db.execute("CREATE TABLE cache(uri TEXT UNIQUE, response TEXT, timeoutAfter TEXT)");
          await db.execute("CREATE TABLE stats(host TEXT UNIQUE, cacheHits INTEGER, cacheMisses INTEGER)");
          oldVersion = 1;
        }
      },
    );
    final repo = SqfliteApiCacheRepository(db);
    await repo.clearTimedOutEntries();
    return repo;
  }

  // The Future will emit a [ClientException] if http fails
  @override
  Future<String> makeHttpRequest(Uri uri, {bool forceRefreshCache = false, Duration timeout = const Duration(minutes: 15)}) async {
    final timestamp = DateTime.timestamp();
    if (!forceRefreshCache) {
      final cachedApiResponse = (await db.query(
        "cache",
        columns: ["response", "timeoutAfter"],
        where: "uri = ?",
        whereArgs: [uri.toString()],
      ))
          .firstOrNull;
      final timeoutAfterStr = cachedApiResponse != null ? cachedApiResponse["timeoutAfter"] as String : null;
      final timeoutAfter = timeoutAfterStr != null ? DateTime.tryParse(timeoutAfterStr) : null;
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

    final timeoutAfter = timestamp.add(timeout);
    final response = await http.read(uri);

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
    await db.delete("cache", where: "timeoutAfter < ?", whereArgs: [DateTime.timestamp().toIso8601String()]);
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
          )
      },
    );
  }

  @override
  Future<void> resetStats() async {
    await db.delete("stats");
  }
}
