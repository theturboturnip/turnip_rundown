import 'dart:convert';

import 'package:turnip_rundown/data/http_cache_repository.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/model.dart';
import 'package:turnip_rundown/util.dart';

class SunriseSunsetOrgRepository {
  Future<SunriseSunset> getNextSunriseAndSunset(Coordinate coord, HttpCacheRepository cache, {bool forceRefreshCache = false}) async {
    final now = UtcDateTime.timestamp();
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
    final sunriseToday = UtcDateTime.parseAndCoerceFullIso8601(jsonResponse["results"]["sunrise"]);
    final sunsetToday = UtcDateTime.parseAndCoerceFullIso8601(jsonResponse["results"]["sunset"]);

    // Don't assume sunset is after sunrise?
    if (sunriseToday.isAfter(now) && sunsetToday.isAfter(now)) {
      return SunriseSunset(
        nextSunrise: sunriseToday,
        nextSunset: sunsetToday,
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
    final sunriseTomorrow = UtcDateTime.parseAndCoerceFullIso8601(jsonResponse["results"]["sunrise"]);
    final sunsetTomorrow = UtcDateTime.parseAndCoerceFullIso8601(jsonResponse["results"]["sunset"]);

    // TODO probably don't assert here
    assert(sunriseTomorrow.isAfter(sunriseToday));
    assert(sunsetTomorrow.isAfter(sunsetToday));

    return SunriseSunset(
      nextSunrise: sunriseToday.isAfter(now) ? sunriseToday : sunriseTomorrow,
      nextSunset: sunsetToday.isAfter(now) ? sunsetToday : sunsetTomorrow,
    );
  }
}
