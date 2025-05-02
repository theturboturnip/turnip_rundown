import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/model.dart';

part 'insights.g.dart';

// TODO gusty warnings using gust vs. basic wind
// TODO use the significantWeatherCode from the MET

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

enum EventInsightType {
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

  // TODO replace this with a separate "is-sunny" boolean? exact time ranges matter less?
  sunny;
}

class LevelMap<TLevel, TUnit extends Unit<TUnit>> {
  final TLevel min;
  // Thresholds for a given value (threshold, level) where threshold is ordered i.e. minimum first.
  // Scan through the list from the end backwards, take the first level where the value is above the threshold
  final List<(Data<TUnit>, TLevel)> linearLevelMap;

  LevelMap({required this.min, required Map<TLevel, Data<TUnit>> minValueForLevel})
      : linearLevelMap = minValueForLevel.entries.map((entry) => (entry.value, entry.key)).sortedBy((elem) => elem.$1);

  TLevel levelFor(Data<TUnit> value) {
    for (final (nextVal, nextLevel) in linearLevelMap.reversed) {
      if (value.compareTo(nextVal) > 0) {
        return nextLevel;
      }
    }
    return min;
  }
}

abstract class LevelsInsight<TLevel> {
  // List of (level, firstHourWhereLevel, lastHourWhereLevel)
  // levels can repeat so [(breezy, 0, 1), (null, 2, 3), (breezy, 4, 7)] is possible
  final List<(TLevel, int, int)> levelRanges;

  LevelsInsight({required this.levelRanges});

  // Takes the levelRanges and removes short ranges where the level == null
  // would be [([breezy, 0, 3), (breezy 4, 5)], 0, 5)] for the above level range
  List<(List<(TLevel, int, int)>, int, int)> nonNullLevelRanges({int hysterisis = 1}) {
    final nonNullRanges = <(List<(TLevel, int, int)>, int, int)>[];
    (List<(TLevel, int, int)>, int, int)? current;
    for (final (level, start, end) in levelRanges) {
      if (level == null) {
        if (current != null && end - start > hysterisis) {
          nonNullRanges.add(current);
          current = null;
        }
        continue;
      }

      if (current == null) {
        current = ([(level, start, end)], start, end);
      } else {
        // Under hysterisis we can merge (Breezy, null, Breezy) together into one if the null is short enough.
        // TODO this hysteresis is only for null, not short-term bumps. is that ok?
        if (level != current.$1.last.$1) {
          current.$1.add((level, start, end));
        }
        current = (current.$1, current.$2, end);
      }
    }
    if (current != null) {
      current = (current.$1, current.$2, levelRanges.last.$3);
      nonNullRanges.add(current);
    }
    return nonNullRanges;
  }

  static List<(TLev, int, int)> levelRangesFromData<TLev, TUnit extends Unit<TUnit>>(DataSeries<TUnit> data, LevelMap<TLev, TUnit> levelMap) {
    final levels = data.datas().map((data) => levelMap.levelFor(data)).toList();
    return levelRangesFromLevels(levels);
  }

  static List<(TLev, int, int)> levelRangesFromLevels<TLev>(List<TLev> levels) {
    var hourRanges = <(TLev, int, int)>[];
    int currentRangeStart = 0;
    TLev currentRangeLevel = levels[0];
    for (int i = 1; i < levels.length; i++) {
      // If we're still in the same range as the previous hour
      if (currentRangeLevel == levels[i]) {
        continue;
      } else {
        hourRanges.add((currentRangeLevel, currentRangeStart, i - 1));
        currentRangeStart = i;
        currentRangeLevel = levels[i];
      }
    }
    hourRanges.add((currentRangeLevel, currentRangeStart, levels.length - 1));
    return hourRanges;
  }
}

enum Heat {
  // <5C
  freezing,
  // <10C
  chilly,
  // <15C
  mild,
  // <20C
  warm,
  // <25C
  hot,
  // maximum
  boiling;
}

class HeatLevelInsight extends LevelsInsight<Heat> {
  final Data<Temp> min;
  final Data<Temp> max;

  HeatLevelInsight(DataSeries<Temp> data, LevelMap<Heat, Temp> levelMap)
      : min = data.datas().min,
        max = data.datas().max,
        super(levelRanges: LevelsInsight.levelRangesFromData(data, levelMap));
}

enum Wind {
  breezy,
  windy,
  galey;
}

class WindLevelInsight extends LevelsInsight<Wind?> {
  WindLevelInsight(DataSeries<Speed> data, LevelMap<Wind?, Speed> levelMap) : super(levelRanges: LevelsInsight.levelRangesFromData(data, levelMap));
}

enum Precipitation {
  sprinkles,
  lightRain,
  mediumRain,
  heavyRain; // TODO include snow inside here?
}

// EventInsightType.sprinkles: ("Sprinkles?", Symbols.sprinkler),
// EventInsightType.lightRain: ("Light rain", ),
// EventInsightType.mediumRain: ("Medium rain", Symbols.rainy_heavy),
// EventInsightType.heavyRain: ("Heavy rain", Symbols.rainy_heavy),

class PrecipitationLevelInsight extends LevelsInsight<Precipitation?> {
  PrecipitationLevelInsight(WeatherInsightConfig config, DataSeries<Percent> precipChance, DataSeries<Length> precipitation)
      : super(
          levelRanges: LevelsInsight.levelRangesFromLevels(
            overallPrecip(config, precipChance, precipitation),
          ),
        );

  static List<Precipitation?> overallPrecip(WeatherInsightConfig config, DataSeries<Percent> precipChance, DataSeries<Length> precipitation) {
    final precip = <Precipitation?>[];
    assert(precipChance.length == precipitation.length);
    for (int i = 0; i < precipitation.length; i++) {
      final precipMM = precipitation[i].valueAs(Length.mm);
      late final Precipitation? precipEnum;
      if (precipChance[i].valueAs(Percent.outOf100) > config.rainProbabilityThreshold.valueAs(Percent.outOf100)) {
        if (precipMM > config.heavyRainThreshold.valueAs(Length.mm)) {
          precipEnum = Precipitation.heavyRain;
        } else if (precipMM > config.mediumRainThreshold.valueAs(Length.mm)) {
          precipEnum = Precipitation.mediumRain;
        } else if (precipMM > 0) {
          precipEnum = Precipitation.lightRain;
        } else {
          precipEnum = Precipitation.sprinkles;
        }
      } else {
        precipEnum = null;
      }
      precip.add(precipEnum);
    }
    return precip;
  }
}

class WeatherInsightsPerLocation {
  final HeatLevelInsight heat;
  final WindLevelInsight wind;
  final PrecipitationLevelInsight precipitation;
  final Map<EventInsightType, ActiveHours> eventInsights;
  final SunriseSunset? sunriseSunset;

  WeatherInsightsPerLocation({
    required this.heat,
    required this.wind,
    required this.precipitation,
    required this.eventInsights,
    required this.sunriseSunset,
  });

  static WeatherInsightsPerLocation fromAnalysis(HourlyPredictedWeather weather, WeatherInsightConfig config, int maxLookahead) {
    late final DataSeries<Temp> futureTemp;
    if (config.useEstimatedWetBulbTemp) {
      futureTemp = weather.estimatedWetBulbGlobeTemp;
    } else {
      futureTemp = weather.dryBulbTemp;
    }

    // We want to include the value at the final hour,
    // .sublist() takes an exclusive end index
    // => use this as the sublist end
    final sublistEndExcl = maxLookahead + 1;

    final heatInsight = HeatLevelInsight(
        futureTemp.sublist(0, sublistEndExcl),
        LevelMap(
          min: Heat.freezing,
          minValueForLevel: {
            Heat.chilly: config.freezingMaxTemp,
            // TODO MAKE THIS CONFIGURABLE
            Heat.mild: const Data(10, Temp.celsius),
            Heat.warm: const Data(15, Temp.celsius),
            Heat.hot: const Data(20, Temp.celsius),
            Heat.boiling: config.boilingMinTemp,
          },
        ));
    final precipInsight = PrecipitationLevelInsight(
      config,
      weather.precipitationProb.sublist(0, sublistEndExcl),
      weather.precipitation.sublist(0, sublistEndExcl),
    );
    final windInsight = WindLevelInsight(
        weather.windspeed.sublist(0, sublistEndExcl),
        LevelMap(min: null, minValueForLevel: {
          Wind.breezy: config.minimumBreezyWindspeed,
          Wind.windy: config.minimumWindyWindspeed,
          Wind.galey: config.minimumGaleyWindspeed,
        }));

    final futureRainfallMM = weather.precipitation.valuesAs(Length.mm).mapIndexed(
      (index, len) {
        if (weather.precipitationProb[index].valueAs(Percent.outOf100) >= config.rainProbabilityThreshold.valueAs(Percent.outOf100)) {
          // If no precipitation is expected, but there is a high chance of precipitation, treat that as 0.5mm
          return max(0.5, len);
        } else {
          return 0.0;
        }
      },
    ).toList();
    final allRainfallMMIncludingPast = weather.precipitationUpToNow.valuesAs(Length.mm).toList()
      ..addAll(
        futureRainfallMM,
      );

    final insights = {for (final t in EventInsightType.values) t: ActiveHours({})};

    // Measure insights up to and including the last data point
    for (int hour = 0; hour < sublistEndExcl; hour++) {
      int indexForRainfallMM = hour + weather.precipitationUpToNow.length;

      // TODO MAKE THIS CONFIGURABLE
      const minSunnyDirectRadidationWm2 = 650;
      const maxSunnyCloudCoverOutOf100 = 50;
      const minSnowySnowfallMM = 10;

      // rain
      final currentSnowMM = weather.snowfall[hour].valueAs(Length.mm);
      if (currentSnowMM > minSnowySnowfallMM) {
        insights[EventInsightType.snow]!.add(hour);
      }

      // slippery
      final startIndexForPreviousHoursPrecipitation = indexForRainfallMM - config.numberOfHoursPriorRainThreshold;
      final previousHoursPrecipitations = (startIndexForPreviousHoursPrecipitation >= 0)
          ? allRainfallMMIncludingPast.skip(startIndexForPreviousHoursPrecipitation).take(config.numberOfHoursPriorRainThreshold + 1)
          : allRainfallMMIncludingPast.take(indexForRainfallMM + 1);
      final previousHoursPrecipitationMM = previousHoursPrecipitations.sum;
      if (previousHoursPrecipitationMM > config.priorRainThreshold.valueAs(Length.mm)) {
        insights[EventInsightType.slippery]!.add(hour);
      }

      // // hail
      // TODO can't reliably retrieve hail from weather? it works if we specify a UK models but returns null if we just specify a location *in* the UK.
      // if (weather.hail != null) {
      //   if (weather.hail![hour].valueAs(Length.mm) > 0.000001) {
      //     insights[EventInsightType.hail]!.add(hour);
      //   }
      // }

      late final double tempC = futureTemp[hour].valueAs(Temp.celsius);

      // humidity
      {
        if (weather.relHumidity[hour].valueAs(Percent.outOf100) > config.highHumidityThreshold.valueAs(Percent.outOf100)) {
          if (tempC > config.minTemperatureForHighHumiditySweat.valueAs(Temp.celsius)) {
            insights[EventInsightType.sweaty]!.add(hour);
          } else if (tempC > config.maxTemperatureForHighHumidityMist.valueAs(Temp.celsius)) {
            insights[EventInsightType.uncomfortablyHumid]!.add(hour);
          }
        }
      }

      // >650W/m2 with <50% cloud cover
      if (weather.directRadiation != null && weather.cloudCover != null) {
        if (weather.directRadiation![hour].valueAs(SolarRadiation.wPerM2) >= minSunnyDirectRadidationWm2 &&
            weather.cloudCover![hour].valueAs(Percent.outOf100) < maxSunnyCloudCoverOutOf100) {
          insights[EventInsightType.sunny]!.add(hour);
        }
      }
    }

    // if (kDebugMode) {
    //   insights[EventInsightType.slippery]!.add(1);
    //   insights[EventInsightType.snow]!.add(2);
    //   insights[EventInsightType.sunny]!.add(3);
    //   insights[EventInsightType.sweaty]!.add(4);
    //   insights[EventInsightType.uncomfortablyHumid]!.add(5);
    // }

    return WeatherInsightsPerLocation(
      heat: heatInsight,
      wind: windInsight,
      precipitation: precipInsight,
      eventInsights: insights,
      sunriseSunset: weather.sunriseSunset,
    );
  }
}

final class WeatherInsights {
  WeatherInsights({
    required this.insightsByLocation,
  });

  Data<Temp>? get minTemp => insightsByLocation.map((insight) => insight.heat.min).minOrNull;
  Data<Temp>? get maxTemp => insightsByLocation.map((insight) => insight.heat.max).maxOrNull;

  final List<WeatherInsightsPerLocation> insightsByLocation;

  static WeatherInsights fromAnalysis(List<HourlyPredictedWeather> weathers, WeatherInsightConfig config, {int maxLookahead = 24}) {
    if (maxLookahead < 0 || maxLookahead > 24) {
      maxLookahead = 24;
    }

    final insightsByLocation = weathers.map((weather) => WeatherInsightsPerLocation.fromAnalysis(weather, config, maxLookahead)).toList();

    return WeatherInsights(
      insightsByLocation: insightsByLocation,
    );
  }
}
