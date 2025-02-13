import 'dart:convert';

import 'package:turnip_rundown/data/api_cache_repository.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/model.dart';

class SunriseSunsetOrgRepository {
  SunriseSunsetOrgRepository({required this.cache});

  final ApiCacheRepository cache;

  Future<SunriseSunset> getNextSunriseAndSunset(Coordinate coord, {bool forceRefreshCache = false}) async {
    final now = DateTime.timestamp();
    var response = await cache.makeHttpRequest(
      Uri(
        scheme: "https",
        host: "api.sunrise-sunset.org",
        path: "json",
        queryParameters: {
          "lat": coord.lat.toString(),
          "lng": coord.long.toString(),
          "formatted": "0",
          "tzid": "UTC",
          "date": "today",
        },
      ),
      forceRefreshCache: forceRefreshCache,
    );
    var jsonResponse = jsonDecode(response);
    final sunriseToday = DateTime.parse(jsonResponse["results"]["sunrise"]).toUtc();
    final sunsetToday = DateTime.parse(jsonResponse["results"]["sunset"]).toUtc();

    // Don't assume sunset is after sunrise?
    if (sunriseToday.isAfter(now) && sunsetToday.isAfter(now)) {
      return SunriseSunset(
        nextSunriseUtc: sunriseToday,
        nextSunsetUtc: sunsetToday,
      );
    }

    response = await cache.makeHttpRequest(
      Uri(
        scheme: "https",
        host: "api.sunrise-sunset.org",
        path: "json",
        queryParameters: {
          "lat": coord.lat.toString(),
          "lng": coord.long.toString(),
          "formatted": "0",
          "tzid": "UTC",
          "date": "tomorrow",
        },
      ),
    );
    jsonResponse = jsonDecode(response);
    final sunriseTomorrow = DateTime.parse(jsonResponse["results"]["sunrise"]).toUtc();
    final sunsetTomorrow = DateTime.parse(jsonResponse["results"]["sunset"]).toUtc();

    // TODO probably don't assert here
    assert(sunriseTomorrow.isAfter(sunriseToday));
    assert(sunsetTomorrow.isAfter(sunsetToday));

    return SunriseSunset(
      nextSunriseUtc: sunriseToday.isAfter(now) ? sunriseToday : sunriseTomorrow,
      nextSunsetUtc: sunsetToday.isAfter(now) ? sunsetToday : sunsetTomorrow,
    );
  }
}
