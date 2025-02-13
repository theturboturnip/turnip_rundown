import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:geojson_vi/geojson_vi.dart';
import 'package:turnip_rundown/data/api_cache_repository.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/model.dart';
import 'package:turnip_rundown/data/weather/repository.dart';
import 'package:turnip_rundown/data/weather/sunrise-sunset-org/repository.dart';

// See https://datahub.metoffice.gov.uk/docs/f/category/site-specific/type/site-specific/api-documentation#get-/point/hourly

HourlyPredictedWeather predictWeatherFromMetGeoJson(
  String featuresJson, {
  required DateTime cutoffTime,
  required SunriseSunset? sunriseSunset,
  int numAfterCutoff = 24,
}) {
  cutoffTime = cutoffTime.toUtc();

  final featuresJsonMap = jsonDecode(featuresJson);
  final features = GeoJSONFeatureCollection.fromMap(featuresJsonMap);

  if (features.features.length != 1) {
    throw "Met Office data returned ${features.features.length} features, expected 1 - $features";
  }
  final timeSeries = features.features[0]?.properties?["timeSeries"] as List<dynamic>?;
  if (timeSeries == null) {
    throw "Met Office data returned a feature without a timeSeries - $features";
  }

  final timeSeriesDateTimesUtc = <DateTime>[];
  final dataToCapture = <String, List<double>>{
    "screenTemperature": [],
    // TODO minScreenAirTemp, maxScreenAirTemp
    "screenDewPointTemperature": [],
    // TODO feelsLikeTemperature
    "windSpeed10m": [],
    // TODO windGustSpeed? max10mWindGust?
    // TODO visibility?
    "screenRelativeHumidity": [],
    // TODO mslp, uvIndex, significantWeatherCode
    // TODO precipitationRate? how is it different
    "totalPrecipAmount": [],
    "totalSnowAmount": [],
    "probOfPrecipitation": [],
  };

  for (final timeSeriesEntry in timeSeries.sortedBy((entry) => entry["time"] as String)) {
    final timeStr = timeSeriesEntry["time"] as String;
    timeSeriesDateTimesUtc.add(DateTime.parse(timeStr).toUtc());

    for (final doubleSeries in dataToCapture.entries) {
      // Sometimes the data can be null. TODO do we need defaults other than 0 lol.
      doubleSeries.value.add(((timeSeriesEntry[doubleSeries.key] ?? 0) as num).toDouble());
    }
  }

  final unitParameters = (featuresJsonMap["parameters"][0] as Map<String, dynamic>).map(
    (unit, description) => MapEntry(
      unit,
      description["unit"]["symbol"]["type"] as String,
    ),
  );

  final int indexInTimeSeriesForCutoff = timeSeriesDateTimesUtc.indexWhere((givenTime) {
    return cutoffTime.difference(givenTime) < const Duration(hours: 1);
  });

  DataSeries<TUnit> extractDataSeries<TUnit extends Unit<TUnit>>(String name, TUnit Function(String?) unitFunc) {
    return DataSeries<TUnit>(
      dataToCapture[name]!.skip(indexInTimeSeriesForCutoff).take(numAfterCutoff).toList(),
      unitFunc(unitParameters[name]),
    );
  }

  final dryBulbTemp = extractDataSeries("screenTemperature", tempUnitFromMet);
  final dewPointTemp = extractDataSeries("screenDewPointTemperature", tempUnitFromMet);
  final windspeed = extractDataSeries("windSpeed10m", speedUnitFromMet);
  final relHumidity = extractDataSeries("screenRelativeHumidity", percentUnitFromMet);

  final wetBulbGlobeTemp = estimateWetBulbGlobeTemps(
    dryBulbTemp: dryBulbTemp,
    windspeed: windspeed,
    relHumidity: relHumidity,
    dewPointTemp: dewPointTemp,
    solarRadiation: null,
  );

  return HourlyPredictedWeather(
    precipitationUpToNow: const DataSeries([], Length.mm), // TODO predict this?
    dateTimesForPredictions: timeSeriesDateTimesUtc.skip(indexInTimeSeriesForCutoff).toList(),
    precipitation: extractDataSeries("totalPrecipAmount", lengthUnitFromMet),
    precipitationProb: extractDataSeries("probOfPrecipitation", percentUnitFromMet),
    dryBulbTemp: dryBulbTemp,
    estimatedWetBulbGlobeTemp: wetBulbGlobeTemp,
    windspeed: windspeed,
    relHumidity: relHumidity,
    directRadiation: null,
    snowfall: extractDataSeries("totalSnowAmount", lengthUnitFromMet),
    cloudCover: null,
    sunriseSunset: sunriseSunset,
  );

  // final DataSeries<Rainfall> precipitation;
  // final DataSeries<Percent> precipitationProb;
  // final DataSeries<Temp> dryBulbTemp;
  // final DataSeries<Temp> estimatedWetBulbGlobeTemp;
  // final DataSeries<Speed> windspeed;
  // final DataSeries<Percent> relHumidity;
  // final DataSeries<SolarRadiation> directRadiation; DONT HAVE
  // final DataSeries<Length> snowfall;
  // final DataSeries<Percent> cloudCover; DONT HAVE

  // "screenTemperature": 6.29,
  // "maxScreenAirTemp": 6.38,
  // "minScreenAirTemp": 6.25,
  // "screenDewPointTemperature": 3.51,
  // "feelsLikeTemperature": 2.96,
  // "windSpeed10m": 4.95,
  // "windDirectionFrom10m": 257,
  // "windGustSpeed10m": 11.31,
  // "max10mWindGust": 11.86,
  // "visibility": 20675,
  // "screenRelativeHumidity": 82.38,
  // "mslp": 99678,
  // "uvIndex": 0,
  // "significantWeatherCode": 2,
  // "precipitationRate": 0,
  // "totalPrecipAmount": 0,
  // "totalSnowAmount": 0,
  // "probOfPrecipitation": 0
}

Temp tempUnitFromMet(String? str) {
  switch (str) {
    case "Cel":
      return Temp.celsius;
    // GUESSES
    // case "°F":
    //   return Temp.farenheit;
    // case "°K":
    //   return Temp.kelvin;

    default:
      throw ("Unexpected temp unit from Met: '$str'");
  }
}

Percent percentUnitFromMet(String? str) {
  switch (str) {
    case "%":
      return Percent.outOf100;
    default:
      throw ("Unexpected percent unit from Met: '$str'");
  }
}

Length lengthUnitFromMet(String? str) {
  switch (str) {
    case "m":
      return Length.m;
    case "cm":
      return Length.cm;
    case "mm":
      return Length.mm;
    case "inch":
      return Length.inch;
    default:
      throw ("Unexpected length unit from Met: '$str'");
  }
}

Speed speedUnitFromMet(String? str) {
  switch (str) {
    case "m/s":
      return Speed.mPerS;
    // GUESS
    case "km/h":
      return Speed.kmPerH;
    default:
      throw ("Unexpected speed unit from Met: '$str'");
  }
}

// SolarRadiation solarUnitFromMet(String? str, {required SolarRadiation expected}) {
//   switch (str) {
//     case "W/m²":
//       return SolarRadiation.wPerM2;
//     default:
//       print("Unexpected solar unit from Met: '$str'");
//       return expected;
//   }
// }

const metOfficeApiKey = String.fromEnvironment('MET_OFFICE_KEY');

class MetOfficeRepository extends WeatherRepository {
  static MetOfficeRepository? load(ApiCacheRepository cache) {
    return metOfficeApiKey.isEmpty ? null : MetOfficeRepository._(cache: cache);
  }

  MetOfficeRepository._({required this.cache}) : sunriseSunsetRepo = SunriseSunsetOrgRepository(cache: cache);

  final ApiCacheRepository cache;
  final SunriseSunsetOrgRepository sunriseSunsetRepo;

  @override
  Future<HourlyPredictedWeather> getPredictedWeather(Coordinate coords, {bool forceRefreshCache = false}) async {
    // Pre-request sunriseSunset because it can be multiple HTTP requests and therefore slow
    final Future<SunriseSunset?> sunriseSunsetRequest = sunriseSunsetRepo.getNextSunriseAndSunset(
      coords,
      forceRefreshCache: forceRefreshCache,
    );
    // Get 48hrs worth of predicted data
    final responseStr = await cache.makeHttpRequest(
      Uri(
        scheme: "https",
        host: "data.hub.api.metoffice.gov.uk",
        path: "/sitespecific/v0/point/hourly",
        queryParameters: {
          "dataSource": "BD1",
          "latitude": coords.lat.toString(),
          "longitude": coords.long.toString(),
          // TODO use this to reverse lookup location
          // "includeLocationName": true,
        },
      ),
      headers: {
        "apikey": metOfficeApiKey,
        "accept": "application/json",
      },
      forceRefreshCache: forceRefreshCache,
    );
    return predictWeatherFromMetGeoJson(
      responseStr,
      sunriseSunset: await sunriseSunsetRequest.onError((err, stacktrace) {
        print("$err, $stacktrace");
        return null;
      }),
      cutoffTime: DateTime.timestamp(),
    );
  }
}
