import 'package:turnip_rundown/data.dart';
import 'package:turnip_rundown/data/http_cache_repository.dart';
import 'package:turnip_rundown/data/settings/repository.dart';
import 'package:turnip_rundown/util.dart';

class CachedWeatherDataBank {
  final RequestedWeatherBackend backend;
  final Coordinate coords;
  final WeatherDataBank data;
  final UtcDateTime timeoutAfter;

  CachedWeatherDataBank({required this.backend, required this.coords, required this.data, required this.timeoutAfter});
}

class HourlyPredictedWeatherAndStatus {
  final HourlyPredictedWeather? weather;
  final bool isStale;
  final String? errorWhenFetching;

  HourlyPredictedWeatherAndStatus({
    required this.weather,
    required this.isStale,
    required this.errorWhenFetching,
  });
}

abstract class WeatherDataBankRepository implements HttpCacheRepository {
  final Map<RequestedWeatherBackend, WeatherClient?> clients;
  // (backend, location) => (data, softTimeoutAfter)
  final Map<(RequestedWeatherBackend, Coordinate), (WeatherDataBank, UtcDateTime)> cachedWeatherDataAndSoftTimeouts;

  WeatherDataBankRepository({required this.clients, required this.cachedWeatherDataAndSoftTimeouts});

  void clearCacheOfHardTimedOut() {
    final now = UtcDateTime.timestamp();
    cachedWeatherDataAndSoftTimeouts.removeWhere((key, val) => now.isAfter(val.$1.hardTimeout));
  }

  void addToCache(RequestedWeatherBackend backend, Coordinate coords, WeatherDataBank data, UtcDateTime softTimeout) {
    cachedWeatherDataAndSoftTimeouts[(backend, coords)] = (data, softTimeout);
  }

  // Returns (data, maybeStale)
  // maybeStale = true if the hourly data was extracted from a data bank after its "soft timeout".
  Future<HourlyPredictedWeatherAndStatus> getPredictedWeather(RequestedWeatherBackend backend, Coordinate coords, {int nextHours = 24, bool forceRefreshCache = false}) async {
    clearCacheOfHardTimedOut();

    var now = UtcDateTime.timestamp();
    HourlyPredictedWeather? cachedPerHour;
    UtcDateTime? cachedPerHourSoftTimeout;

    final cachedWeatherData = cachedWeatherDataAndSoftTimeouts[(backend, coords)];
    if (cachedWeatherData != null) {
      final (cachedWeatherBank, softTimeout) = cachedWeatherData;
      cachedPerHour = cachedWeatherBank.tryExtract(now, nextHours: nextHours);
      if (cachedPerHour != null) {
        cachedPerHourSoftTimeout = softTimeout;
      }
    }

    final isStale = cachedPerHourSoftTimeout != null ? now.isAfter(cachedPerHourSoftTimeout) : false;
    if (!forceRefreshCache && cachedPerHour != null && !isStale) {
      print("retrieving weather for $coords directly from cached bank, not stale");
      return HourlyPredictedWeatherAndStatus(weather: cachedPerHour, isStale: false, errorWhenFetching: null);
    }
    print("banked weather for $coords is null or stale, looking up online");

    final client = (clients[backend] ?? clients[RequestedWeatherBackend.openmeteo]!);
    return await client.getPredictedWeather(coords, this, forceRefreshCache: forceRefreshCache).then(
      (newBank) {
        now = UtcDateTime.timestamp();
        addToCache(backend, coords, newBank, now.add(const Duration(minutes: 30)));
        return HourlyPredictedWeatherAndStatus(
          weather: newBank.tryExtract(now, nextHours: nextHours)!,
          isStale: false,
          errorWhenFetching: null,
        );
      },
    ).catchError(
      (err, stackTrace) {
        print("failed to look up weather online $err $stackTrace");
        return HourlyPredictedWeatherAndStatus(
          weather: cachedPerHour,
          isStale: isStale,
          errorWhenFetching: "$err",
        );
      },
    );
  }
}
