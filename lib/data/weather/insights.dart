import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/model.dart';

part 'insights.g.dart';

// TODO distinguish rain from snow

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
  });

  final bool useEstimatedWetBulbTemp;

  final int numberOfHoursPriorRainThreshold;
  final Data<Rainfall> priorRainThreshold;

  final Data<Percent> rainProbabilityThreshold;
  final Data<Rainfall> mediumRainThreshold;
  final Data<Rainfall> heavyRainThreshold;

  final Data<Percent> highHumidityThreshold;
  final Data<Temp> maxTemperatureForHighHumidityMist;
  final Data<Temp> minTemperatureForHighHumiditySweat;

  final Data<Speed> minimumBreezyWindspeed;
  final Data<Speed> minimumWindyWindspeed;
  final Data<Speed> minimumGaleyWindspeed;

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
      );
}

class ActiveHours {
  ActiveHours(this._hours);

  final Set<int> _hours;

  Iterable<int> get individualHours => _hours;

  bool get isEmpty => _hours.isEmpty;
  bool get isNotEmpty => _hours.isNotEmpty;

  int get numActiveHours => _hours.length;

  void add(int hour) {
    _hours.add(hour);
  }

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
  lightRain,
  mediumRain,
  heavyRain,

  // slippery
  slippery,

  // Humidity
  sweaty,
  uncomfortablyHumid,
  coolMist,

  // General temperature
  boiling,
  freezing,

  // TODO replace this with a separate "is-sunny" boolean?
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
  });
  final (Data<Temp>, int)? minTempAt;
  final (Data<Temp>, int)? maxTempAt;
  final List<Map<InsightType, ActiveHours>> insightsByLocation;

  static WeatherInsights fromAnalysis(List<HourlyPredictedWeather> weathers, WeatherInsightConfig config, {int maxLookahead = 24}) {
    if (maxLookahead < 0 || maxLookahead > 24) {
      maxLookahead = 24;
    }

    late final (Data<Temp>, int)? minTempAt, maxTempAt;
    if (weathers.isEmpty) {
      return WeatherInsights(minTempAt: null, maxTempAt: null, insightsByLocation: []);
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
                  return len;
                } else {
                  return 0;
                }
              },
            ),
          );

        final insights = {for (final t in InsightType.values) t: ActiveHours({})};

        for (int hour = 0; hour < maxLookahead; hour++) {
          int indexForRainfallMM = hour + weather.precipitationUpToNow.length;

          // rain
          final currentPrecipitationMM = allRainfallMMIncludingPast[indexForRainfallMM];
          if (currentPrecipitationMM > config.heavyRainThreshold.valueAs(Length.mm)) {
            insights[InsightType.heavyRain]!.add(hour);
          } else if (currentPrecipitationMM > config.mediumRainThreshold.valueAs(Length.mm)) {
            insights[InsightType.mediumRain]!.add(hour);
          } else if (currentPrecipitationMM > 0) {
            insights[InsightType.lightRain]!.add(hour);
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

          // humidity
          {
            if (weather.relHumidity[hour].valueAs(Percent.outOf100) > config.highHumidityThreshold.valueAs(Percent.outOf100)) {
              late final double tempC;
              if (config.useEstimatedWetBulbTemp) {
                tempC = weather.estimatedWetBulbGlobeTemp[hour].valueAs(Temp.celsius);
              } else {
                tempC = weather.dryBulbTemp[hour].valueAs(Temp.celsius);
              }

              if (tempC > config.minTemperatureForHighHumiditySweat.valueAs(Temp.celsius)) {
                insights[InsightType.sweaty]!.add(hour);
              } else if (tempC > config.maxTemperatureForHighHumidityMist.valueAs(Temp.celsius)) {
                insights[InsightType.uncomfortablyHumid]!.add(hour);
              } else {
                insights[InsightType.coolMist]!.add(hour);
              }
            }
          }

          // TODO boiling, freezing, sunny

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
      );
    }
  }
}
