import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/model.dart';
import 'package:turnip_rundown/util.dart';

part 'insights.g.dart';

// TODO gusty warnings using gust vs. basic wind
// TODO use the significantWeatherCode from the MET

@JsonSerializable()
class WeatherInsightConfigV1 {
  const WeatherInsightConfigV1({
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
    this.boilingMinTemp,
    this.freezingMaxTemp,
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

  final Data<Temp>? boilingMinTemp;
  final Data<Temp>? freezingMaxTemp;

  static const WeatherInsightConfigV1 initial = WeatherInsightConfigV1(
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

  factory WeatherInsightConfigV1.fromJsonUnversioned(Map<String, dynamic> json) => _$WeatherInsightConfigV1FromJson(json);
  Map<String, dynamic> toJson() => _$WeatherInsightConfigV1ToJson(this);

  WeatherInsightConfigV1 copyWith({
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
      WeatherInsightConfigV1(
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

@JsonSerializable()
class WeatherInsightConfigV2 extends Equatable {
  const WeatherInsightConfigV2({
    required this.useEstimatedWetBulbTemp,
    required this.numberOfHoursPriorRainThreshold,
    required this.priorRainThreshold,
    required this.rainProbabilityThreshold,
    required this.rainMinLight,
    required this.rainMinMedium,
    required this.rainMinHeavy,
    required this.highHumidityThreshold,
    required this.maxTemperatureForHighHumidityMist,
    required this.minTemperatureForHighHumiditySweat,
    required this.windMinBreezy,
    required this.windMinWindy,
    required this.windMinGaley,
    required this.tempMinBoiling,
    required this.tempMinHot,
    required this.tempMinWarm,
    required this.tempMinMild,
    required this.tempMinChilly,
    required this.uvMinModerate,
    required this.uvMinHigh,
    required this.uvMinVeryHigh,
  });

  @JsonKey(includeFromJson: false, includeToJson: true)
  final version = 2;

  final bool useEstimatedWetBulbTemp;

  final int numberOfHoursPriorRainThreshold;
  final Data<Rainfall> priorRainThreshold;

  final Data<Percent> rainProbabilityThreshold;
  final Data<Rainfall> rainMinLight;
  final Data<Rainfall> rainMinMedium;
  final Data<Rainfall> rainMinHeavy;

  final Data<Percent> highHumidityThreshold;
  // We used to have a "cool mist" insight for (low temp + high humidity) that was quite inaccurate.
  // Now we got rid of that and this insight is really the minimum temperature for humidity to be relevant.
  final Data<Temp> maxTemperatureForHighHumidityMist;
  final Data<Temp> minTemperatureForHighHumiditySweat;

  final Data<Speed> windMinBreezy;
  final Data<Speed> windMinWindy;
  final Data<Speed> windMinGaley;

  final Data<Temp> tempMinChilly;
  final Data<Temp> tempMinMild;
  final Data<Temp> tempMinWarm;
  final Data<Temp> tempMinHot;
  final Data<Temp> tempMinBoiling;

  final Data<UVIndex> uvMinModerate;
  final Data<UVIndex> uvMinHigh;
  final Data<UVIndex> uvMinVeryHigh;

  factory WeatherInsightConfigV2.fromV1(WeatherInsightConfigV1 v1) {
    var v1Boiling = v1.boilingMinTemp;
    var v1Chilly = v1.freezingMaxTemp;

    late Data<Temp> tempMinChilly, tempMinMild, tempMinWarm, tempMinHot, tempMinBoiling;

    // If we aren't using the default values for the temperature range, migrate to the new default.
    final notUsingDefaultV1Boiling = (v1Boiling != null && (v1Boiling.valueAs(Temp.celsius) - 20.0).abs() > 0.1);
    final notUsingDefaultV1Chilly = (v1Chilly != null && (v1Chilly.valueAs(Temp.celsius) - 5.0).abs() > 0.1);
    if (notUsingDefaultV1Boiling || notUsingDefaultV1Chilly) {
      v1Boiling ??= WeatherInsightConfigV1.initial.boilingMinTemp!;
      v1Chilly ??= WeatherInsightConfigV1.initial.freezingMaxTemp!;
      if (v1Boiling.compareTo(v1Chilly) < 0) {
        // Completely give up and enforce defaults
        tempMinChilly = WeatherInsightConfigV2.initial.tempMinChilly;
        tempMinMild = WeatherInsightConfigV2.initial.tempMinMild;
        tempMinWarm = WeatherInsightConfigV2.initial.tempMinWarm;
        tempMinHot = WeatherInsightConfigV2.initial.tempMinHot;
        tempMinBoiling = WeatherInsightConfigV2.initial.tempMinBoiling;
      } else {
        // Evenly spread out the temperatures within the range
        final unit = v1Boiling.unit;
        final chillyAsUnit = v1Chilly.valueAs(unit);
        final boilingAsUnit = v1Boiling.valueAs(unit);
        final tempStep = (boilingAsUnit - chillyAsUnit) / 4;
        tempMinChilly = v1Chilly;
        tempMinMild = Data(chillyAsUnit + tempStep * 1, unit);
        tempMinWarm = Data(chillyAsUnit + tempStep * 2, unit);
        tempMinHot = Data(chillyAsUnit + tempStep * 3, unit);
        tempMinBoiling = v1Boiling; // i.e. chillyAsUnit + tempStep * 4
      }
    } else {
      tempMinChilly = WeatherInsightConfigV2.initial.tempMinChilly;
      tempMinMild = WeatherInsightConfigV2.initial.tempMinMild;
      tempMinWarm = WeatherInsightConfigV2.initial.tempMinWarm;
      tempMinHot = WeatherInsightConfigV2.initial.tempMinHot;
      tempMinBoiling = WeatherInsightConfigV2.initial.tempMinBoiling;
    }

    return WeatherInsightConfigV2(
      useEstimatedWetBulbTemp: v1.useEstimatedWetBulbTemp,
      numberOfHoursPriorRainThreshold: v1.numberOfHoursPriorRainThreshold,
      priorRainThreshold: v1.priorRainThreshold,
      rainProbabilityThreshold: v1.rainProbabilityThreshold,
      rainMinLight: initial.rainMinLight,
      rainMinMedium: v1.mediumRainThreshold,
      rainMinHeavy: v1.heavyRainThreshold,
      highHumidityThreshold: v1.highHumidityThreshold,
      maxTemperatureForHighHumidityMist: v1.maxTemperatureForHighHumidityMist,
      minTemperatureForHighHumiditySweat: v1.minTemperatureForHighHumiditySweat,
      windMinBreezy: v1.minimumBreezyWindspeed,
      windMinWindy: v1.minimumWindyWindspeed,
      windMinGaley: v1.minimumGaleyWindspeed,
      tempMinBoiling: tempMinBoiling,
      tempMinHot: tempMinHot,
      tempMinWarm: tempMinWarm,
      tempMinMild: tempMinMild,
      tempMinChilly: tempMinChilly,
      uvMinModerate: initial.uvMinModerate,
      uvMinHigh: initial.uvMinHigh,
      uvMinVeryHigh: initial.uvMinVeryHigh,
    );
  }

  static const WeatherInsightConfigV2 initial = WeatherInsightConfigV2(
    useEstimatedWetBulbTemp: true,
    // Guessed
    numberOfHoursPriorRainThreshold: 8,
    priorRainThreshold: Data(2.5, Length.mm),
    rainProbabilityThreshold: Data(15, Percent.outOf100),
    // From https://en.wikipedia.org/wiki/Rain#Intensity
    rainMinLight: Data(0.1, Length.mm),
    rainMinMedium: Data(2.5, Length.mm),
    rainMinHeavy: Data(7.6, Length.mm),
    // Guessed
    highHumidityThreshold: Data(80, Percent.outOf100),
    maxTemperatureForHighHumidityMist: Data(10, Temp.celsius),
    minTemperatureForHighHumiditySweat: Data(17, Temp.celsius),
    // https://www.weather.gov/pqr/wind
    windMinBreezy: Data(4, Speed.milesPerHour),
    windMinWindy: Data(13, Speed.milesPerHour),
    windMinGaley: Data(32, Speed.milesPerHour),
    // Guessed
    tempMinBoiling: Data(25, Temp.celsius),
    tempMinHot: Data(20, Temp.celsius),
    tempMinWarm: Data(15, Temp.celsius),
    tempMinMild: Data(10, Temp.celsius),
    tempMinChilly: Data(5, Temp.celsius),
    // https://www.cancerresearchuk.org/about-cancer/causes-of-cancer/sun-uv-and-cancer/the-uv-index-and-sunburn-risk
    // UvLevel.low: const Data(1.0, UVIndex.uv),
    uvMinModerate: Data(3.0, UVIndex.uv),
    uvMinHigh: Data(6.0, UVIndex.uv),
    uvMinVeryHigh: Data(8.0, UVIndex.uv),
  );

  static WeatherInsightConfigV2 migrateFromJson(Map<String, dynamic> json) => weatherInsightLoader.fromJson(json);

  factory WeatherInsightConfigV2.fromJsonUnversioned(Map<String, dynamic> json) => _$WeatherInsightConfigV2FromJson(json);
  Map<String, dynamic> toJson() => _$WeatherInsightConfigV2ToJson(this);

  WeatherInsightConfigV2 copyWith({
    bool? useEstimatedWetBulbTemp,
    int? numberOfHoursPriorRainThreshold,
    Data<Rainfall>? priorRainThreshold,
    Data<Percent>? rainProbabilityThreshold,
    Data<Rainfall>? rainMinLight,
    Data<Rainfall>? rainMinMedium,
    Data<Rainfall>? rainMinHeavy,
    Data<Percent>? highHumidityThreshold,
    Data<Temp>? maxTemperatureForHighHumidityMist,
    Data<Temp>? minTemperatureForHighHumiditySweat,
    Data<Speed>? windMinBreezy,
    Data<Speed>? windMinWindy,
    Data<Speed>? windMinGaley,
    Data<Temp>? tempMinBoiling,
    Data<Temp>? tempMinHot,
    Data<Temp>? tempMinWarm,
    Data<Temp>? tempMinMild,
    Data<Temp>? tempMinChilly,
    Data<UVIndex>? uvMinModerate,
    Data<UVIndex>? uvMinHigh,
    Data<UVIndex>? uvMinVeryHigh,
  }) =>
      WeatherInsightConfigV2(
        useEstimatedWetBulbTemp: useEstimatedWetBulbTemp ?? this.useEstimatedWetBulbTemp,
        numberOfHoursPriorRainThreshold: numberOfHoursPriorRainThreshold ?? this.numberOfHoursPriorRainThreshold,
        priorRainThreshold: priorRainThreshold ?? this.priorRainThreshold,
        rainProbabilityThreshold: rainProbabilityThreshold ?? this.rainProbabilityThreshold,
        rainMinLight: rainMinLight ?? this.rainMinLight,
        rainMinMedium: rainMinMedium ?? this.rainMinMedium,
        rainMinHeavy: rainMinHeavy ?? this.rainMinHeavy,
        highHumidityThreshold: highHumidityThreshold ?? this.highHumidityThreshold,
        maxTemperatureForHighHumidityMist: maxTemperatureForHighHumidityMist ?? this.maxTemperatureForHighHumidityMist,
        minTemperatureForHighHumiditySweat: minTemperatureForHighHumiditySweat ?? this.minTemperatureForHighHumiditySweat,
        windMinBreezy: windMinBreezy ?? this.windMinBreezy,
        windMinWindy: windMinWindy ?? this.windMinWindy,
        windMinGaley: windMinGaley ?? this.windMinGaley,
        tempMinBoiling: tempMinBoiling ?? this.tempMinBoiling,
        tempMinHot: tempMinHot ?? this.tempMinHot,
        tempMinWarm: tempMinWarm ?? this.tempMinWarm,
        tempMinMild: tempMinMild ?? this.tempMinMild,
        tempMinChilly: tempMinChilly ?? this.tempMinChilly,
        uvMinModerate: uvMinModerate ?? this.uvMinModerate,
        uvMinHigh: uvMinHigh ?? this.uvMinHigh,
        uvMinVeryHigh: uvMinVeryHigh ?? this.uvMinVeryHigh,
      );

  @override
  List<Object?> get props => [
        useEstimatedWetBulbTemp,
        numberOfHoursPriorRainThreshold,
        priorRainThreshold,
        rainProbabilityThreshold,
        rainMinMedium,
        rainMinHeavy,
        highHumidityThreshold,
        maxTemperatureForHighHumidityMist,
        minTemperatureForHighHumiditySweat,
        windMinBreezy,
        windMinWindy,
        windMinGaley,
        tempMinBoiling,
        tempMinHot,
        tempMinWarm,
        tempMinMild,
        tempMinChilly,
        uvMinModerate,
        uvMinHigh,
        uvMinVeryHigh,
      ];
}

final weatherInsightLoader = const JsonMigration.chainStart(
  load: WeatherInsightConfigV1.fromJsonUnversioned,
  migrate: WeatherInsightConfigV2.fromV1,
).complete(
  load: WeatherInsightConfigV2.fromJsonUnversioned,
  versionKey: "version",
  // Older JSONs didn't have a version key
  fallbackVersionIfNonePresent: 1,
  makeDefault: () => WeatherInsightConfigV2.initial,
);

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

class LevelsInsight<TLevel> {
  final List<TLevel> levels;
  // List of (level, firstHourWhereLevel, lastHourWhereLevel)
  // levels can repeat so [(breezy, 0, 1), (null, 2, 3), (breezy, 4, 7)] is possible
  final List<(TLevel, int, int)> levelRanges;

  LevelsInsight({required this.levels, required this.levelRanges});

  // Takes the levelRanges and removes short ranges where the level == null
  // would be [([breezy, 0, 3), (breezy 4, 5)], 0, 5)] for the above level range
  List<(List<(TLevel, int, int)>, int, int)> nonNullLevelRanges({int hysterisis = 1}) {
    final nonNullRanges = <(List<(TLevel, int, int)>, int, int)>[];
    (List<(TLevel, int, int)>, int, int)? current;
    for (final (level, start, end) in levelRanges) {
      if (level == null) {
        // Under hysterisis we can merge (Breezy, null, Breezy) together into one if the null is short enough.
        if (current != null && end - start > hysterisis) {
          nonNullRanges.add(current);
          current = null;
        }
        continue;
      }

      if (current == null) {
        current = ([(level, start, end)], start, end);
      } else {
        if (level == current.$1.last.$1) {
          current.$1.last = (current.$1.last.$1, current.$1.last.$2, end);
        } else {
          current.$1.add((level, start, end));
        }
        current = (current.$1, current.$2, end);
      }
    }
    if (current != null) {
      nonNullRanges.add(current);
    }
    return nonNullRanges;
  }

  static LevelsInsight<TLev> levelRangesFromData<TLev, TUnit extends Unit<TUnit>>(DataSeries<TUnit> dataPlusOne, LevelMap<TLev, TUnit> levelMap) {
    assert(dataPlusOne.length >= 1);
    final levels = dataPlusOne.datas().map((data) => levelMap.levelFor(data)).take(dataPlusOne.length - 1).toList();
    return LevelsInsight(levels: levels, levelRanges: levelRangesFromLevels(levels));
  }

  static List<(TLev, int, int)> levelRangesFromLevels<TLev>(List<TLev> levels) {
    return buildLikeRanges(
      levels,
      firstFunc: (level) => level,
      shouldCombineFunc: (lastLevel, newLevel) {
        if (lastLevel == newLevel) {
          return (true, lastLevel);
        } else {
          return (false, newLevel);
        }
      },
    );
  }
}

// LevelsInsight where each hour is a Set<TLevel> for every level at every location during that hour.
//
// Hours are combined into a range if
// - the set of levels for that hour is a subset of that range's
class CombinedLevelsInsight<TLevel> {
  final List<LevelsInsight<TLevel>> bases;
  final List<(Set<TLevel>, int, int)> levelRanges;

  CombinedLevelsInsight._({required this.bases, required this.levelRanges});

  static CombinedLevelsInsight<TLev> combine<TLev>(List<LevelsInsight<TLev>> bases) {
    assert(bases.isNotEmpty);
    assert(!bases.any((base) => base.levels.length != bases.first.levels.length));

    // Iterator over (Set of levels at given hour i)
    final perHourLevelSets = Iterable.generate(bases.first.levels.length).map((i) => bases.map((base) => base.levels[i]).toSet());
    final levelRanges = buildLikeRanges(
      perHourLevelSets,
      firstFunc: (levelSet) => levelSet,
      shouldCombineFunc: (oldLevelSet, newLevelSet) {
        if (setEquals(oldLevelSet, newLevelSet)) {
          return (true, oldLevelSet);
        } else if (oldLevelSet.length > 1 && newLevelSet.length > 1 && oldLevelSet.intersection(newLevelSet).isNotEmpty) {
          return (true, oldLevelSet.union(newLevelSet));
        } else {
          return (false, newLevelSet);
        }
      },
    );
    return CombinedLevelsInsight._(
      bases: bases,
      levelRanges: levelRanges,
    );
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

class HeatLevelInsight {
  final Data<Temp> min;
  final Data<Temp> max;
  final LevelsInsight<Heat?> levels;

  HeatLevelInsight(DataSeries<Temp> dataPlusOne, LevelMap<Heat?, Temp> levelMap)
      : min = dataPlusOne.datas().min,
        max = dataPlusOne.datas().max,
        levels = LevelsInsight.levelRangesFromData(dataPlusOne, levelMap);
}

enum Wind {
  breezy,
  windy,
  galey;
}

LevelsInsight<Wind?> windLevelInsight(DataSeries<Speed> dataPlusOne, LevelMap<Wind?, Speed> levelMap) => LevelsInsight.levelRangesFromData(dataPlusOne, levelMap);

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

LevelsInsight<Precipitation?> precipitationLevelInsight(WeatherInsightConfigV2 config, DataSeries<Percent> precipChance, DataSeries<Length> precipitation) {
  final precip = <Precipitation?>[];
  assert(precipChance.length == precipitation.length);
  for (int i = 0; i < precipitation.length; i++) {
    final precipMM = precipitation[i].valueAs(Length.mm);
    late final Precipitation? precipEnum;
    if (precipChance[i].valueAs(Percent.outOf100) > config.rainProbabilityThreshold.valueAs(Percent.outOf100)) {
      if (precipMM > config.rainMinHeavy.valueAs(Length.mm)) {
        precipEnum = Precipitation.heavyRain;
      } else if (precipMM > config.rainMinMedium.valueAs(Length.mm)) {
        precipEnum = Precipitation.mediumRain;
      } else if (precipMM > config.rainMinLight.valueAs(Length.mm)) {
        precipEnum = Precipitation.lightRain;
      } else {
        precipEnum = Precipitation.sprinkles;
      }
    } else {
      precipEnum = null;
    }
    precip.add(precipEnum);
  }

  final levelRanges = LevelsInsight.levelRangesFromLevels(precip);
  return LevelsInsight(levelRanges: levelRanges, levels: precip);
}

enum UvLevel {
  // low,
  moderate,
  high,
  veryHigh;
}

LevelsInsight<UvLevel?> uvLevelInsight(DataSeries<UVIndex> dataPlusOne, LevelMap<UvLevel?, UVIndex> levelMap) => LevelsInsight.levelRangesFromData(dataPlusOne, levelMap);

class WeatherInsightsPerLocation {
  final HeatLevelInsight heat;
  final LevelsInsight<Wind?> wind;
  final LevelsInsight<Precipitation?> precipitation;
  final LevelsInsight<UvLevel?> uv;
  final Map<EventInsightType, ActiveHours> eventInsights;
  final SunriseSunset? sunriseSunset;

  WeatherInsightsPerLocation({
    required this.heat,
    required this.wind,
    required this.precipitation,
    required this.uv,
    required this.eventInsights,
    required this.sunriseSunset,
  });

  static WeatherInsightsPerLocation fromAnalysis(HourlyPredictedWeather weather, WeatherInsightConfigV2 config, int maxLookahead) {
    late final DataSeries<Temp> futureTemp;
    if (config.useEstimatedWetBulbTemp) {
      futureTemp = weather.estimatedWetBulbGlobeTemp;
    } else {
      futureTemp = weather.dryBulbTemp;
    }

    // We want to include the value at the final hour in the analysis,
    // .sublist() takes an exclusive end index
    // => use this as the sublist end
    final sublistEndExcl = maxLookahead + 1;

    final heatInsight = HeatLevelInsight(
        futureTemp.sublist(0, sublistEndExcl),
        LevelMap(
          min: Heat.freezing,
          minValueForLevel: {
            // for compatibility with previous setup, use this:
            // null: config.freezingMaxTemp,
            // for new setup use this:
            Heat.chilly: config.tempMinChilly,
            Heat.mild: config.tempMinMild,
            Heat.warm: config.tempMinWarm,
            Heat.hot: config.tempMinHot,

            // this should always be there
            Heat.boiling: config.tempMinBoiling,
          },
        ));
    final precipInsight = precipitationLevelInsight(
      config,
      weather.precipitationProb.sublist(0, sublistEndExcl),
      weather.precipitation.sublist(0, sublistEndExcl),
    );
    final windInsight = windLevelInsight(
        weather.windspeed.sublist(0, sublistEndExcl),
        LevelMap(
          min: null,
          minValueForLevel: {
            Wind.breezy: config.windMinBreezy,
            Wind.windy: config.windMinWindy,
            Wind.galey: config.windMinGaley,
          },
        ));
    final uvInsight = uvLevelInsight(
        weather.uvIndex.sublist(0, sublistEndExcl),
        LevelMap(
          min: null,
          minValueForLevel: {
            // https://www.cancerresearchuk.org/about-cancer/causes-of-cancer/sun-uv-and-cancer/the-uv-index-and-sunburn-risk
            // UvLevel.low: const Data(1.0, UVIndex.uv),
            UvLevel.moderate: config.uvMinModerate,
            UvLevel.high: config.uvMinHigh,
            UvLevel.veryHigh: config.uvMinVeryHigh,
          },
        ));

    final futureRainfallMM = weather.precipitation.valuesAs(Length.mm).mapIndexed(
      (index, len) {
        if (weather.precipitationProb[index].valueAs(Percent.outOf100) >= config.rainProbabilityThreshold.valueAs(Percent.outOf100)) {
          // If no precipitation is expected, but there is a high chance of precipitation, treat that as 0.5mm
          return math.max(0.5, len);
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

    // Measure event-based insights up to and EXCLUDING the last data point
    for (int hour = 0; hour < sublistEndExcl - 1; hour++) {
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

    if (kDebugMode) {
      // insights[EventInsightType.slippery]!.add(1);
      // insights[EventInsightType.snow]!.add(2);
      // insights[EventInsightType.sunny]!.add(3);
      // insights[EventInsightType.sweaty]!.add(4);
      // insights[EventInsightType.uncomfortablyHumid]!.add(5);
    }

    return WeatherInsightsPerLocation(
      heat: heatInsight,
      wind: windInsight,
      precipitation: precipInsight,
      uv: uvInsight,
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

  static WeatherInsights fromAnalysis(List<HourlyPredictedWeather> weathers, WeatherInsightConfigV2 config, {int maxLookahead = 24}) {
    if (maxLookahead < 0 || maxLookahead > 24) {
      maxLookahead = 24;
    }

    final insightsByLocation = weathers.map((weather) => WeatherInsightsPerLocation.fromAnalysis(weather, config, maxLookahead)).toList();

    return WeatherInsights(
      insightsByLocation: insightsByLocation,
    );
  }
}
