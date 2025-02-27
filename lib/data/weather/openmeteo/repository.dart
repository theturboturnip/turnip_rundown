// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:turnip_rundown/data/api_cache_repository.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/model.dart';
import 'package:turnip_rundown/data/weather/repository.dart';
import 'package:turnip_rundown/data/weather/sunrise-sunset-org/repository.dart';
import 'package:turnip_rundown/util.dart';

part 'repository.g.dart';

@JsonSerializable()
class OpenMeteoHourlyRequest {
  OpenMeteoHourlyRequest({
    required this.latitude,
    required this.longitude,
    required this.generationtime_ms,
    required this.utc_offset_seconds,
    required this.timezone,
    required this.timezone_abbreviation,
    required this.elevation,
    required this.hourly_units,
    required this.hourly,
  });

  final double latitude;
  final double longitude;
  final double generationtime_ms;
  final double utc_offset_seconds;
  final String timezone;
  final String timezone_abbreviation;
  final double elevation;

  final Map<String, String> hourly_units;
  final OpenMeteoHourlyDatapoints hourly;

  factory OpenMeteoHourlyRequest.fromJson(Map<String, dynamic> json) => _$OpenMeteoHourlyRequestFromJson(json);

  Map<String, dynamic> toJson() => _$OpenMeteoHourlyRequestToJson(this);
}

@JsonSerializable()
class OpenMeteoHourlyDatapoints {
  OpenMeteoHourlyDatapoints({
    required this.time,
    required this.temperature,
    required this.relHumidity,
    required this.dewPoint,
    required this.precipitationProb,
    required this.precipitation,
    required this.windspeed,
    required this.directRadiation,
    required this.snowfall,
    required this.cloudCover,
  });

  @JsonKey(name: "time")
  final List<String> time;
  @JsonKey(name: "temperature_2m")
  final List<double> temperature;
  @JsonKey(name: "relative_humidity_2m")
  final List<double> relHumidity;
  @JsonKey(name: "dew_point_2m")
  final List<double> dewPoint;
  @JsonKey(name: "precipitation_probability")
  final List<double> precipitationProb;
  @JsonKey(name: "precipitation")
  final List<double> precipitation;
  @JsonKey(name: "wind_speed_10m")
  final List<double> windspeed;
  @JsonKey(name: "direct_radiation_instant")
  final List<double> directRadiation;
  @JsonKey(name: "snowfall")
  final List<double> snowfall;
  @JsonKey(name: "cloud_cover")
  final List<double> cloudCover;

  factory OpenMeteoHourlyDatapoints.fromJson(Map<String, dynamic> json) => _$OpenMeteoHourlyDatapointsFromJson(json);

  Map<String, dynamic> toJson() => _$OpenMeteoHourlyDatapointsToJson(this);
}

Temp tempUnitFromOpenMeteo(String? str, {required Temp expected}) {
  switch (str) {
    case "°C":
      return Temp.celsius;
    // GUESSES
    case "°F":
      return Temp.farenheit;
    case "°K":
      return Temp.kelvin;

    default:
      print("Unexpected temp unit from openmeteo: '$str'");
      return expected;
  }
}

Percent percentUnitFromOpenMeteo(String? str, {required Percent expected}) {
  switch (str) {
    case "%":
      return Percent.outOf100;
    default:
      print("Unexpected percent unit from openmeteo: '$str'");
      return expected;
  }
}

Length lengthUnitFromOpenMeteo(String? str, {required Length expected}) {
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
      print("Unexpected length unit from openmeteo: '$str'");
      return expected;
  }
}

Speed speedUnitFromOpenMeteo(String? str, {required Speed expected}) {
  switch (str) {
    case "km/h":
      return Speed.kmPerH;
    case "m/s":
      return Speed.mPerS;
    default:
      print("Unexpected speed unit from openmeteo: '$str'");
      return expected;
  }
}

SolarRadiation solarUnitFromOpenMeteo(String? str, {required SolarRadiation expected}) {
  switch (str) {
    case "W/m²":
      return SolarRadiation.wPerM2;
    default:
      print("Unexpected solar unit from openmeteo: '$str'");
      return expected;
  }
}

class OpenMeteoWeatherRepository extends WeatherRepository {
  OpenMeteoWeatherRepository({required this.cache}) : sunriseSunsetRepo = SunriseSunsetOrgRepository(cache: cache);

  final ApiCacheRepository cache;
  final SunriseSunsetOrgRepository sunriseSunsetRepo;

  @override
  Future<HourlyPredictedWeather> getPredictedWeather(Coordinate coords, {bool forceRefreshCache = false}) async {
    // Pre-request sunriseSunset because it can be multiple HTTP requests and therefore slow
    final Future<SunriseSunset?> sunriseSunsetRequest = sunriseSunsetRepo.getNextSunriseAndSunset(
      coords,
      forceRefreshCache: forceRefreshCache,
    );
    // Get 3 days worth of predicted/measured data
    final responseStr = await cache.makeHttpRequest(
      Uri(
        scheme: "https",
        host: "api.open-meteo.com",
        path: "/v1/forecast",
        queryParameters: {
          "latitude": coords.lat.toString(),
          "longitude": coords.long.toString(),
          if (coords.elevation != null) "elevation": coords.elevation.toString(),
          "hourly": "temperature_2m,relative_humidity_2m,dew_point_2m,precipitation_probability,precipitation,wind_speed_10m,direct_radiation_instant,snowfall,cloud_cover",
          "temperature_unit": "celsius",
          "wind_speed_unit": "kmh",
          "precipitation_unit": "mm",
          "timeformat": "iso8601",
          "timezone": "Etc/UTC",
          "past_days": "1",
          "forecast_days": "2",
        },
      ),
      headers: {},
      forceRefreshCache: forceRefreshCache,
    );
    final response = OpenMeteoHourlyRequest.fromJson(jsonDecode(responseStr));

    // Generate the baseline data series for all three days
    final temperature_3day = response.hourly.temperature.toDataSeries(
      tempUnitFromOpenMeteo(
        response.hourly_units["temperature_2m"],
        expected: Temp.celsius,
      ),
    );
    final relHumidity_3day = response.hourly.relHumidity.toDataSeries(
      percentUnitFromOpenMeteo(
        response.hourly_units["relative_humidity_2m"],
        expected: Percent.outOf100,
      ),
    );
    final dew_point_3day = response.hourly.dewPoint.toDataSeries(
      tempUnitFromOpenMeteo(
        response.hourly_units["dew_point_2m"],
        expected: Temp.celsius,
      ),
    );
    final precipitationProb_3day = response.hourly.precipitationProb.toDataSeries(
      percentUnitFromOpenMeteo(
        response.hourly_units["precipitation_probability"],
        expected: Percent.outOf100,
      ),
    );
    final precipitation_3day = response.hourly.precipitation.toDataSeries(
      lengthUnitFromOpenMeteo(
        response.hourly_units["precipitation"],
        expected: Length.mm,
      ),
    );
    final windspeed_3day = response.hourly.windspeed.toDataSeries(
      speedUnitFromOpenMeteo(
        response.hourly_units["wind_speed_10m"],
        expected: Speed.kmPerH,
      ),
    );
    final directRadiation_3day = response.hourly.directRadiation.toDataSeries(
      solarUnitFromOpenMeteo(
        response.hourly_units["direct_radiation_instant"],
        expected: SolarRadiation.wPerM2,
      ),
    );
    final snowfall_3day = response.hourly.snowfall.toDataSeries(
      lengthUnitFromOpenMeteo(
        response.hourly_units["snowfall"],
        expected: Length.cm,
      ),
    );
    final cloudCover_3day = response.hourly.cloudCover.toDataSeries(
      percentUnitFromOpenMeteo(
        response.hourly_units["cloud_cover"],
        expected: Percent.outOf100,
      ),
    );
    final wetBulb_3day = estimateWetBulbGlobeTemps(
      dryBulbTemp: temperature_3day,
      windspeed: windspeed_3day,
      relHumidity: relHumidity_3day,
      dewPointTemp: dew_point_3day,
      solarRadiation: directRadiation_3day,
    );
    // Compute wet bulb temperature

    // Extract the 24hrs preceding right now and the 24hrs following right now
    final UtcDateTime currentTime = UtcDateTime.timestamp();
    final datapointDateTimes = response.hourly.time.map((givenTimeStr) => UtcDateTime.parsePartialIso8601AsUtc(givenTimeStr)).toList();
    final int indexInTimeSeriesForRightNow = datapointDateTimes.indexWhere((givenTime) {
      return currentTime.difference(givenTime) < const Duration(hours: 1);
    });
    assert(indexInTimeSeriesForRightNow >= 24);
    assert(indexInTimeSeriesForRightNow + 24 <= datapointDateTimes.length);
    // Capture the range [indexInTimeSeriesForRightNow - 24:indexInTimeSeriesForRightNow - 1] for previous 24hr
    // Capture the range [indexInTimeSeriesForRightNow:indexInTimeSeriesForRightNow + 23] for next 24hr

    return HourlyPredictedWeather(
      precipitationUpToNow: precipitation_3day.slice(indexInTimeSeriesForRightNow - 24, indexInTimeSeriesForRightNow - 1),
      // sublist() uses non-inclusive end
      dateTimesForPredictions: datapointDateTimes.sublist(indexInTimeSeriesForRightNow, indexInTimeSeriesForRightNow + 24),
      precipitation: precipitation_3day.slice(indexInTimeSeriesForRightNow, indexInTimeSeriesForRightNow + 23),
      precipitationProb: precipitationProb_3day.slice(indexInTimeSeriesForRightNow, indexInTimeSeriesForRightNow + 23),
      dryBulbTemp: temperature_3day.slice(indexInTimeSeriesForRightNow, indexInTimeSeriesForRightNow + 23),
      estimatedWetBulbGlobeTemp: wetBulb_3day.slice(indexInTimeSeriesForRightNow, indexInTimeSeriesForRightNow + 23),
      windspeed: windspeed_3day.slice(indexInTimeSeriesForRightNow, indexInTimeSeriesForRightNow + 23),
      relHumidity: relHumidity_3day.slice(indexInTimeSeriesForRightNow, indexInTimeSeriesForRightNow + 23),
      directRadiation: directRadiation_3day.slice(indexInTimeSeriesForRightNow, indexInTimeSeriesForRightNow + 23),
      snowfall: snowfall_3day.slice(indexInTimeSeriesForRightNow, indexInTimeSeriesForRightNow + 23),
      cloudCover: cloudCover_3day.slice(indexInTimeSeriesForRightNow, indexInTimeSeriesForRightNow + 23),
      sunriseSunset: await sunriseSunsetRequest.onError((err, stacktrace) {
        print("$err, $stacktrace");
        return null;
      }),
    );
  }
}

DataSeries<Temp> estimateWetBulbGlobeTemps({
  required DataSeries<Temp> dryBulbTemp,
  required DataSeries<Speed> windspeed,
  required DataSeries<Percent> relHumidity,
  required DataSeries<Temp>? dewPointTemp,
  required DataSeries<SolarRadiation>? solarRadiation,
}) {
  final length = dryBulbTemp.length;
  return IterableZip([
    dryBulbTemp.datas(),
    windspeed.datas(),
    relHumidity.datas(),
    dewPointTemp?.datas() ?? Iterable.generate(length, (i) => null),
    solarRadiation?.datas() ?? Iterable.generate(length, (i) => null),
  ]).map((datas) {
    return estimateWetBulbGlobeTemp(
      dryBulbTemp: datas[0] as Data<Temp>,
      windspeed: datas[1] as Data<Speed>,
      relHumidity: datas[2] as Data<Percent>,
      dewPointTemp: datas[3] as Data<Temp>?,
      solarRadiation: datas[4] as Data<SolarRadiation>?,
    );
  }).toDataSeries(Temp.celsius);
}
