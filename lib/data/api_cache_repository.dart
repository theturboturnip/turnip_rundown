class HostStats {
  HostStats({required this.cacheHits, required this.cacheMisses});

  final int cacheHits;
  final int cacheMisses;
}

class ApiStats {
  ApiStats({required this.hostStats});

  final Map<String, HostStats> hostStats;
}

abstract interface class ApiCacheRepository {
  /// The Future will emit a [ClientException] if the http request is attempted and fails
  Future<String> makeHttpRequest(Uri uri, {bool forceRefreshCache = false, Duration timeout = const Duration(minutes: 15)});
  Future<void> clearTimedOutEntries();
  Future<void> resetStats();
  Future<ApiStats> getStats();
}
