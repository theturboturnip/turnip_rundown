import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:turnip_rundown/data/api_cache_repository.dart';
import 'package:http/http.dart' as http;
import 'package:turnip_rundown/data/settings/repository.dart';

class UncachedApiCacheRepository implements ApiCacheRepository {
  // The Future will emit a [ClientException] if http fails
  @override
  Future<String> makeHttpRequest(Uri uri, {bool forceRefreshCache = false, Duration timeout = const Duration(minutes: 15)}) async {
    print("doing HTTP request $uri");

    // We don't cache anything :)
    final response = await http.read(uri);

    return response;
  }

  @override
  Future<void> clearTimedOutEntries() async {
    // We don't cache anything :)
  }

  @override
  Future<ApiStats> getStats() async {
    // We don't cache anything :)
    return ApiStats(
      hostStats: {},
    );
  }

  @override
  Future<void> resetStats() async {
    // We don't cache anything :)
  }
}

class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository({required this.prefs}) {
    _settings = Settings.fromJson(jsonDecode(prefs.getString("settingsJson") ?? "{}"));
    _lockedUtcLookaheadTo = DateTime.tryParse(prefs.getString("lockedUtcLookaheadTo") ?? "");
  }

  final SharedPreferences prefs;
  late Settings _settings;
  DateTime? _lockedUtcLookaheadTo;

  @override
  DateTime? get lockedUtcLookaheadTo => _lockedUtcLookaheadTo;

  @override
  Future<void> storeLockedUtcLookaheadTo(DateTime? lockedUtcLookaheadTo) async {
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
}
