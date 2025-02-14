class HostStats {
  HostStats({required this.cacheHits, required this.cacheMisses});

  int cacheHits;
  int cacheMisses;
}

class ApiStats {
  ApiStats({required this.hostStats});

  final Map<String, HostStats> hostStats;
}

abstract interface class ApiCacheRepository {
  /// The Future will emit a [ClientException] if the http request is attempted and fails.
  /// 'headers' are ignored for the purposes of caching: i.e. if you make two requests to the same uri with different headers each time, the second
  /// request will return the cached data even though the headers are different.
  Future<String> makeHttpRequest(Uri uri, {Map<String, String>? headers, bool forceRefreshCache = false, Duration timeout = const Duration(minutes: 15)});
  Future<void> clearTimedOutEntries();
  Future<void> resetStats();
  Future<ApiStats> getStats();
}
