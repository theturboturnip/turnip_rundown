import 'dart:math';

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/model.dart';

part 'insights.g.dart';

// TODO gusty warnings using gust vs. basic wind
// TODO use the significantWeatherCode from the MET
// TODO remove mist

@JsonSerializable()
class WeatherInsightConfig {
  const WeatherInsightConfig({
    required this.useEstimatedWetBulbTemp,
    required this.numberOfHoursPriorRainThreshold,
    required this.priorRainThreshold,
    required this.rainProbabilityThreshold,
    required this.mediumRainThreshold,
    required this.heavyRainThreshold,
    required this.highHumidityThreshold,
    required this.maxTemperatureForHighHumidityMist,
    required this.minTemperatureForHighHumiditySweat,
    required this.minimumBreezyWindspeed,
    required this.minimumWindyWindspeed,
    required this.minimumGaleyWindspeed,
    this.boilingMinTemp = const Data(20, Temp.celsius),
    this.freezingMaxTemp = const Data(5, Temp.celsius),
  });

  final bool useEstimatedWetBulbTemp;

  final int numberOfHoursPriorRainThreshold;
  final Data<Rainfall> priorRainThreshold;

  final Data<Percent> rainProbabilityThreshold;
  final Data<Rainfall> mediumRainThreshold;
  final Data<Rainfall> heavyRainThreshold;

  final Data<Percent> highHumidityThreshold;
  // We used to have a "cool mist" insight for (low temp + high humidity) that was quite inaccurate.
  // Now we got rid of that and this insight is really the minimum temperature for humidity to be relevant.
  final Data<Temp> maxTemperatureForHighHumidityMist;
  final Data<Temp> minTemperatureForHighHumiditySweat;

  final Data<Speed> minimumBreezyWindspeed;
  final Data<Speed> minimumWindyWindspeed;
  final Data<Speed> minimumGaleyWindspeed;

  final Data<Temp> boilingMinTemp;
  final Data<Temp> freezingMaxTemp;

  factory WeatherInsightConfig.initial() => const WeatherInsightConfig(
        useEstimatedWetBulbTemp: true,
        // Guessed
        numberOfHoursPriorRainThreshold: 8,
        priorRainThreshold: Data(2.5, Length.mm),
        rainProbabilityThreshold: Data(15, Percent.outOf100),
        // From https://en.wikipedia.org/wiki/Rain#Intensity
        mediumRainThreshold: Data(2.5, Length.mm),
        heavyRainThreshold: Data(7.6, Length.mm),
        // Guessed
        highHumidityThreshold: Data(80, Percent.outOf100),
        maxTemperatureForHighHumidityMist: Data(10, Temp.celsius),
        minTemperatureForHighHumiditySweat: Data(17, Temp.celsius),
        // https://www.weather.gov/pqr/wind
        minimumBreezyWindspeed: Data(4, Speed.milesPerHour),
        minimumWindyWindspeed: Data(13, Speed.milesPerHour),
        minimumGaleyWindspeed: Data(32, Speed.milesPerHour),
        // Guessed
        boilingMinTemp: Data(20, Temp.celsius),
        freezingMaxTemp: Data(5, Temp.celsius),
      );
  // }

  factory WeatherInsightConfig.fromJson(Map<String, dynamic> json) => _$WeatherInsightConfigFromJson(json);
  Map<String, dynamic> toJson() => _$WeatherInsightConfigToJson(this);

  WeatherInsightConfig copyWith({
    bool? useEstimatedWetBulbTemp,
    int? numberOfHoursPriorRainThreshold,
    Data<Rainfall>? priorRainThreshold,
    Data<Percent>? rainProbabilityThreshold,
    Data<Rainfall>? mediumRainThreshold,
    Data<Rainfall>? heavyRainThreshold,
    Data<Percent>? highHumidityThreshold,
    Data<Temp>? maxTemperatureForHighHumidityMist,
    Data<Temp>? minTemperatureForHighHumiditySweat,
    Data<Speed>? minimumBreezyWindspeed,
    Data<Speed>? minimumWindyWindspeed,
    Data<Speed>? minimumGaleyWindspeed,
    Data<Temp>? boilingMinTemp,
    Data<Temp>? freezingMaxTemp,
  }) =>
      WeatherInsightConfig(
        useEstimatedWetBulbTemp: useEstimatedWetBulbTemp ?? this.useEstimatedWetBulbTemp,
        numberOfHoursPriorRainThreshold: numberOfHoursPriorRainThreshold ?? this.numberOfHoursPriorRainThreshold,
        priorRainThreshold: priorRainThreshold ?? this.priorRainThreshold,
        rainProbabilityThreshold: rainProbabilityThreshold ?? this.rainProbabilityThreshold,
        mediumRainThreshold: mediumRainThreshold ?? this.mediumRainThreshold,
        heavyRainThreshold: heavyRainThreshold ?? this.heavyRainThreshold,
        highHumidityThreshold: highHumidityThreshold ?? this.highHumidityThreshold,
        maxTemperatureForHighHumidityMist: maxTemperatureForHighHumidityMist ?? this.maxTemperatureForHighHumidityMist,
        minTemperatureForHighHumiditySweat: minTemperatureForHighHumiditySweat ?? this.minTemperatureForHighHumiditySweat,
        minimumBreezyWindspeed: minimumBreezyWindspeed ?? this.minimumBreezyWindspeed,
        minimumWindyWindspeed: minimumWindyWindspeed ?? this.minimumWindyWindspeed,
        minimumGaleyWindspeed: minimumGaleyWindspeed ?? this.minimumGaleyWindspeed,
        boilingMinTemp: boilingMinTemp ?? this.boilingMinTemp,
        freezingMaxTemp: freezingMaxTemp ?? this.freezingMaxTemp,
      );
}

class ActiveHours {
  ActiveHours(this._hours);
  ActiveHours.empty() : _hours = {};

  final Set<int> _hours;

  Iterable<int> get individualHours => _hours;

  bool get isEmpty => _hours.isEmpty;
  bool get isNotEmpty => _hours.isNotEmpty;

  int get numActiveHours => _hours.length;
  int? get firstHour => _hours.minOrNull;

  void add(int hour) {
    _hours.add(hour);
  }

  bool contains(int hour) => _hours.contains(hour);

  List<(int, int)> get asRanges {
    // From a set of numbers, starting from the lowest number find all contiguous ranges of numbers in the set
    // e.g. {1,2, 4, 6,7,8} => (1, 2), (4, 4), (6, 8)
    if (_hours.isEmpty) return [];
    final sortedHours = _hours.sorted((a, b) => a.compareTo(b));
    var hourRanges = <(int, int)>[];
    int currentRangeStart = sortedHours[0];
    for (int i = 0; i < sortedHours.length; i++) {
      if (currentRangeStart == sortedHours[i]) continue;
      if (sortedHours[i] == sortedHours[i - 1] + 1) {
        continue;
      } else {
        hourRanges.add((currentRangeStart, sortedHours[i - 1]));
        currentRangeStart = sortedHours[i];
      }
    }
    hourRanges.add((currentRangeStart, sortedHours.last));
    return hourRanges;
  }
}

enum InsightType {
  // rainy
  sprinkles,
  lightRain,
  mediumRain,
  heavyRain,

  // slippery
  slippery,

  // snowy
  // TODO heavySnow?
  snow,
  // TODO hail,

  // Humidity
  sweaty,
  uncomfortablyHumid,
  // coolMist, // TODO this isn't really relevant. replace with low vis?

  // General temperature
  boiling,
  freezing,

  // TODO replace this with a separate "is-sunny" boolean? exact time ranges matter less?
  sunny,

  // wind
  breezy,
  windy,
  galey;
}

final class WeatherInsights {
  WeatherInsights({
    required this.minTempAt,
    required this.maxTempAt,
    required this.insightsByLocation,
    required this.sunriseSunsetByLocation,
  });
  final (Data<Temp>, int)? minTempAt;
  final (Data<Temp>, int)? maxTempAt;
  final List<Map<InsightType, ActiveHours>> insightsByLocation;
  final List<SunriseSunset?> sunriseSunsetByLocation;

  static WeatherInsights fromAnalysis(List<HourlyPredictedWeather> weathers, WeatherInsightConfig config, {int maxLookahead = 24}) {
    if (maxLookahead < 0 || maxLookahead > 24) {
      maxLookahead = 24;
    }

    late final (Data<Temp>, int)? minTempAt, maxTempAt;
    if (weathers.isEmpty) {
      return WeatherInsights(
        minTempAt: null,
        maxTempAt: null,
        insightsByLocation: [],
        sunriseSunsetByLocation: [],
      );
    } else {
      List<(double, double)> minMaxTempC;
      if (config.useEstimatedWetBulbTemp) {
        minMaxTempC = weathers.map((weather) => weather.estimatedWetBulbGlobeTemp.valuesAs(Temp.celsius).take(maxLookahead).minMax as (double, double)).toList();
      } else {
        minMaxTempC = weathers.map((weather) => weather.dryBulbTemp.valuesAs(Temp.celsius).take(maxLookahead).minMax as (double, double)).toList();
      }
      (double, int) minCAt = (minMaxTempC[0].$1, 0);
      (double, int) maxCAt = (minMaxTempC[0].$2, 0);
      for (final (index, (min, max)) in minMaxTempC.indexed) {
        if (min < minCAt.$1) {
          minCAt = (min, index);
        }
        if (max > maxCAt.$1) {
          maxCAt = (max, index);
        }
      }
      minTempAt = (Data(minCAt.$1, Temp.celsius), minCAt.$2);
      maxTempAt = (Data(maxCAt.$1, Temp.celsius), maxCAt.$2);

      final insightsByLocation = weathers.map((weather) {
        final allRainfallMMIncludingPast = weather.precipitationUpToNow.valuesAs(Length.mm).toList()
          ..addAll(
            weather.precipitation.valuesAs(Length.mm).mapIndexed(
              (index, len) {
                if (weather.precipitationProb[index].valueAs(Percent.outOf100) >= config.rainProbabilityThreshold.valueAs(Percent.outOf100)) {
                  // If no precipitation is expected, but there is a high chance of precipitation, treat that as 0.5mm
                  return max(0.5, len);
                } else {
                  return 0;
                }
              },
            ),
          );

        final insights = {for (final t in InsightType.values) t: ActiveHours({})};

        for (int hour = 0; hour < maxLookahead; hour++) {
          int indexForRainfallMM = hour + weather.precipitationUpToNow.length;

          // TODO MAKE THIS CONFIGURABLE
          final boilingMinTempC = config.boilingMinTemp.valueAs(Temp.celsius);
          final freezingMaxTempC = config.freezingMaxTemp.valueAs(Temp.celsius);
          const minSunnyDirectRadidationWm2 = 650;
          const maxSunnyCloudCoverOutOf100 = 50;
          const minSnowySnowfallMM = 10;

          // rain
          final currentPrecipitationMM = allRainfallMMIncludingPast[indexForRainfallMM];
          final currentSnowMM = weather.snowfall[hour].valueAs(Length.mm);
          if (currentSnowMM > minSnowySnowfallMM) {
            insights[InsightType.snow]!.add(hour);
            if (currentPrecipitationMM > currentSnowMM) {
              if (currentPrecipitationMM > config.heavyRainThreshold.valueAs(Length.mm)) {
                insights[InsightType.heavyRain]!.add(hour);
              } else if (currentPrecipitationMM > config.mediumRainThreshold.valueAs(Length.mm)) {
                insights[InsightType.mediumRain]!.add(hour);
              } else if (currentPrecipitationMM > 0) {
                insights[InsightType.lightRain]!.add(hour);
              } else {
                insights[InsightType.sprinkles]!.add(hour);
              }
            }
          } else if (weather.precipitationProb[hour].valueAs(Percent.outOf100) > config.rainProbabilityThreshold.valueAs(Percent.outOf100)) {
            // Some APIs tend to return nonzero chance of rain with no actual precipitation value.
            // This caused issues when comparing (currentPrecipitationMM > currentSnowMM).
            // if they're both 0, you don't get a warning even for a high chance of rain.
            // => if there's no significant snow, just care about the rain without comparing.
            if (currentPrecipitationMM > config.heavyRainThreshold.valueAs(Length.mm)) {
              insights[InsightType.heavyRain]!.add(hour);
            } else if (currentPrecipitationMM > config.mediumRainThreshold.valueAs(Length.mm)) {
              insights[InsightType.mediumRain]!.add(hour);
            } else if (currentPrecipitationMM > 0) {
              insights[InsightType.lightRain]!.add(hour);
            } else {
              insights[InsightType.sprinkles]!.add(hour);
            }
          }

          // slippery
          final startIndexForPreviousHoursPrecipitation = indexForRainfallMM - config.numberOfHoursPriorRainThreshold;
          final previousHoursPrecipitations = (startIndexForPreviousHoursPrecipitation >= 0)
              ? allRainfallMMIncludingPast.skip(startIndexForPreviousHoursPrecipitation).take(config.numberOfHoursPriorRainThreshold + 1)
              : allRainfallMMIncludingPast.take(indexForRainfallMM + 1);
          final previousHoursPrecipitationMM = previousHoursPrecipitations.sum;
          if (previousHoursPrecipitationMM > config.priorRainThreshold.valueAs(Length.mm)) {
            insights[InsightType.slippery]!.add(hour);
          }

          // // hail
          // TODO can't reliably retrieve hail from weather? it works if we specify a UK models but returns null if we just specify a location *in* the UK.
          // if (weather.hail != null) {
          //   if (weather.hail![hour].valueAs(Length.mm) > 0.000001) {
          //     insights[InsightType.hail]!.add(hour);
          //   }
          // }

          late final double tempC;
          if (config.useEstimatedWetBulbTemp) {
            tempC = weather.estimatedWetBulbGlobeTemp[hour].valueAs(Temp.celsius);
          } else {
            tempC = weather.dryBulbTemp[hour].valueAs(Temp.celsius);
          }

          // humidity
          {
            if (weather.relHumidity[hour].valueAs(Percent.outOf100) > config.highHumidityThreshold.valueAs(Percent.outOf100)) {
              if (tempC > config.minTemperatureForHighHumiditySweat.valueAs(Temp.celsius)) {
                insights[InsightType.sweaty]!.add(hour);
              } else if (tempC > config.maxTemperatureForHighHumidityMist.valueAs(Temp.celsius)) {
                insights[InsightType.uncomfortablyHumid]!.add(hour);
              }
            }
          }

          // If it's over the min boiling temp, put a boiling warning.
          // TODO If sweaty entirely implies boiling, and it is sweaty, don't bother?
          if (tempC > boilingMinTempC) {
            insights[InsightType.boiling]!.add(hour);
          }
          // If it's under the min freezing temp, put a freezing warning
          if (tempC < freezingMaxTempC) {
            insights[InsightType.freezing]!.add(hour);
          }

          // >650W/m2 with <50% cloud cover
          if (weather.directRadiation != null && weather.cloudCover != null) {
            if (weather.directRadiation![hour].valueAs(SolarRadiation.wPerM2) >= minSunnyDirectRadidationWm2 &&
                weather.cloudCover![hour].valueAs(Percent.outOf100) < maxSunnyCloudCoverOutOf100) {
              insights[InsightType.sunny]!.add(hour);
            }
          }

          // wind
          final windSpeedMph = weather.windspeed[hour].valueAs(Speed.milesPerHour);
          if (windSpeedMph > config.minimumGaleyWindspeed.valueAs(Speed.milesPerHour)) {
            insights[InsightType.galey]!.add(hour);
          } else if (windSpeedMph > config.minimumWindyWindspeed.valueAs(Speed.milesPerHour)) {
            insights[InsightType.windy]!.add(hour);
          } else if (windSpeedMph > config.minimumBreezyWindspeed.valueAs(Speed.milesPerHour)) {
            insights[InsightType.breezy]!.add(hour);
          }
        }
        return insights;
      }).toList();

      return WeatherInsights(
        minTempAt: minTempAt,
        maxTempAt: maxTempAt,
        insightsByLocation: insightsByLocation,
        sunriseSunsetByLocation: weathers.map((weather) => weather.sunriseSunset).toList(),
      );
    }
  }
}
