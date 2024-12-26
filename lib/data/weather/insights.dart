import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/model.dart';

part 'insights.g.dart';

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

enum PredictedRain implements Comparable<PredictedRain> {
  light,
  medium,
  heavy;

  @override
  int compareTo(PredictedRain other) {
    return index.compareTo(other.index);
  }
}

class RainStatus {
  RainStatus({required this.preRain, required this.preRainMeansSlippery, required this.predictedRain});

  // sum of rainfall in the preceding hours
  final Data<Length> preRain;
  // if that sum of rainfall in preceding hours > the "slippery" threshold
  final bool preRainMeansSlippery;
  // foreach level of predicted rain, the ranges of hours for which that rainfall is predicted (prediction > 15%)
  final Map<PredictedRain, ActiveHours> predictedRain;

  factory RainStatus.fromAnalysis(HourlyPredictedWeather weather, WeatherInsightConfig config, int maxLookahead) {
    final preRainMM = weather.precipitationSince24hrAgo.valuesAs(Length.mm).skip(24 - config.numberOfHoursPriorRainThreshold).sum;
    var predictedRain = <PredictedRain, Set<int>>{
      PredictedRain.light: {},
      PredictedRain.medium: {},
      PredictedRain.heavy: {},
    };
    for (int i = 0; i < weather.precipitation.length && i < maxLookahead; i++) {
      if (weather.precipitationProb[i].valueAs(Percent.outOf100) > config.rainProbabilityThreshold.valueAs(Percent.outOf100)) {
        final lengthMm = weather.precipitation[i].valueAs(Length.mm);

        late final PredictedRain key;
        if (lengthMm > config.heavyRainThreshold.valueAs(Length.mm)) {
          key = PredictedRain.heavy;
        } else if (lengthMm > config.mediumRainThreshold.valueAs(Length.mm)) {
          key = PredictedRain.medium;
        } else {
          key = PredictedRain.light;
        }
        predictedRain[key]!.add(i);
      }
    }

    return RainStatus(
      preRain: Data(preRainMM, Length.mm),
      preRainMeansSlippery: (preRainMM >= config.priorRainThreshold.valueAs(Length.mm)),
      predictedRain: predictedRain.map((key, hours) => MapEntry(key, ActiveHours(hours))),
    );
  }
}

enum PredictedHighHumidity {
  sweaty, // hot 17+C
  uncomfortable, // medium 10-17C
  coolMist; // cold <10C
}

class HumidStatus {
  HumidStatus({required this.predictedHumitity});

  // foreach level of high humidity, the set of hours for which that humidity is predicted
  final Map<PredictedHighHumidity, ActiveHours> predictedHumitity;

  factory HumidStatus.fromAnalysis(HourlyPredictedWeather weather, WeatherInsightConfig config, int maxLookahead) {
    var predictedHumitity = <PredictedHighHumidity, Set<int>>{
      PredictedHighHumidity.sweaty: {},
      PredictedHighHumidity.uncomfortable: {},
      PredictedHighHumidity.coolMist: {},
    };
    for (int i = 0; i < weather.relHumidity.length && i < maxLookahead; i++) {
      if (weather.relHumidity[i].valueAs(Percent.outOf100) > config.highHumidityThreshold.valueAs(Percent.outOf100)) {
        late final double tempC;
        if (config.useEstimatedWetBulbTemp) {
          tempC = weather.estimatedWetBulbGlobeTemp[i].valueAs(Temp.celsius);
        } else {
          tempC = weather.dryBulbTemp[i].valueAs(Temp.celsius);
        }

        late final PredictedHighHumidity key;
        if (tempC > config.minTemperatureForHighHumiditySweat.valueAs(Temp.celsius)) {
          key = PredictedHighHumidity.sweaty;
        } else if (tempC > config.maxTemperatureForHighHumidityMist.valueAs(Temp.celsius)) {
          key = PredictedHighHumidity.uncomfortable;
        } else {
          key = PredictedHighHumidity.coolMist;
        }
        predictedHumitity[key]!.add(i);
      }
    }
    return HumidStatus(predictedHumitity: predictedHumitity.map((key, hours) => MapEntry(key, ActiveHours(hours))));
  }
}

enum PredictedWind implements Comparable<PredictedWind> {
  breezy,
  windy,
  galey;

  @override
  int compareTo(PredictedWind other) {
    return index.compareTo(other.index);
  }
}

class WindStatus {
  WindStatus({required this.predictedWind});

  // foreach level of wind, the set of hours for which that level is predicted
  final Map<PredictedWind, ActiveHours> predictedWind;

  factory WindStatus.fromAnalysis(HourlyPredictedWeather weather, WeatherInsightConfig config, int maxLookahead) {
    var predictedWind = <PredictedWind, Set<int>>{
      PredictedWind.breezy: {},
      PredictedWind.windy: {},
      PredictedWind.galey: {},
    };
    for (int i = 0; i < weather.windspeed.length && i < maxLookahead; i++) {
      final windSpeedMph = weather.windspeed[i].valueAs(Speed.milesPerHour);

      PredictedWind? key;
      if (windSpeedMph > config.minimumGaleyWindspeed.valueAs(Speed.milesPerHour)) {
        key = PredictedWind.galey;
      } else if (windSpeedMph > config.minimumWindyWindspeed.valueAs(Speed.milesPerHour)) {
        key = PredictedWind.windy;
      } else if (windSpeedMph > config.minimumBreezyWindspeed.valueAs(Speed.milesPerHour)) {
        key = PredictedWind.breezy;
      }

      if (key != null) {
        predictedWind[key]!.add(i);
      }
    }
    return WindStatus(predictedWind: predictedWind.map((key, hours) => MapEntry(key, ActiveHours(hours))));
  }
}

final class WeatherInsights {
  WeatherInsights({
    required this.minTempAt,
    required this.maxTempAt,
    required this.rainAt,
    required this.humidityAt,
    required this.windAt,
  });
  final (Data<Temp>, int) minTempAt;
  final (Data<Temp>, int) maxTempAt;
  final List<RainStatus> rainAt;
  final List<HumidStatus> humidityAt;
  final List<WindStatus> windAt;

  static WeatherInsights? fromAnalysis(List<HourlyPredictedWeather> weathers, WeatherInsightConfig config, {int maxLookahead = 24}) {
    if (weathers.isEmpty) return null;
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

    return WeatherInsights(
      minTempAt: (Data(minCAt.$1, Temp.celsius), minCAt.$2),
      maxTempAt: (Data(maxCAt.$1, Temp.celsius), maxCAt.$2),
      rainAt: weathers.map((weather) => RainStatus.fromAnalysis(weather, config, maxLookahead)).toList(),
      humidityAt: weathers.map((weather) => HumidStatus.fromAnalysis(weather, config, maxLookahead)).toList(),
      windAt: weathers.map((weather) => WindStatus.fromAnalysis(weather, config, maxLookahead)).toList(),
    );
  }
}

// final class HighHumidityInsight extends WeatherInsight {
//   HighHumidityInsight({required this.max});

//   final Data<Percent> max;

//   static HighHumidityInsight? tryFor(HourlyPredictedWeather weather) {
//     double maxHumidity = weather.relHumidity.valuesAs(Percent.outOf100).max;
//     // In the UK, typically between 70-100 - put the threshold at the midpoint
//     if (maxHumidity >= 85) {
//       return HighHumidityInsight(max: Data(maxHumidity, Percent.outOf100));
//     } else {
//       return null;
//     }
//   }

//   @override
//   (String, String) userVisibleInfo() {
//     return (
//       "High Humidity - Avoid physical activity, or wear loose clothing",
//       "Max Humidity: ${max.valueAs(Percent.outOf100).ceil()}%",
//     );
//   }
// }

// final class HighTemperatureInsight extends WeatherInsight {
//   HighTemperatureInsight({required this.max});

//   final Data<Temp> max;

//   static HighTemperatureInsight? tryFor(HourlyPredictedWeather weather) {
//     double maxTempC = weather.estimatedWetBulbGlobeTemp.valuesAs(Temp.celsius).max;
//     // TODO figure out threshold
//     if (maxTempC > 20) {
//       return HighTemperatureInsight(max: Data(maxTempC, Temp.celsius));
//     } else {
//       return null;
//     }
//   }

//   @override
//   (String, String) userVisibleInfo() {
//     return (
//       "High Temperature - Avoid physical activity, or wear loose clothing",
//       "Max Temperature: ${max.valueAs(Temp.celsius).ceil()}C",
//     );
//   }
// }

// final class LowTemperatureInsight extends WeatherInsight {
//   LowTemperatureInsight({required this.min});

//   final Data<Temp> min;

//   static LowTemperatureInsight? tryFor(HourlyPredictedWeather weather) {
//     double minTempC = weather.estimatedWetBulbGlobeTemp.valuesAs(Temp.celsius).min;
//     if (minTempC < 10) {
//       return LowTemperatureInsight(min: Data(minTempC, Temp.celsius));
//     } else {
//       return null;
//     }
//   }

//   @override
//   (String, String) userVisibleInfo() {
//     return (
//       "Low Temperature - Bundle up!",
//       "Min Temperature: ${min.valueAs(Temp.celsius).ceil()}C",
//     );
//   }
// }

// final class SlipperyInsight extends WeatherInsight {
//   final Data<Length> rainBefore;
//   final Data<Length> rainInFuture;
//   final bool futureRainIsNotable;

//   SlipperyInsight({required this.rainBefore, required this.rainInFuture, required this.futureRainIsNotable});

//   static SlipperyInsight? tryFor(HourlyPredictedWeather weather) {
//     // If there was at least 1mm of rain since 8hr ago
//     double rainBefore = weather.precipitationSince24hrAgo.valuesAs(Length.mm).toList().reversed.take(8).sum;
//     // or if there will be at least 1mm of rain in the next 24 hrs
//     double rainInFuture = weather.precipitation.valuesAs(Length.mm).sum;

//     if (rainBefore > 1 || rainInFuture > 1) {
//       return SlipperyInsight(
//         rainBefore: Data(rainBefore, Length.mm),
//         rainInFuture: Data(rainInFuture, Length.mm),
//         futureRainIsNotable: rainInFuture > 1,
//       );
//     } else {
//       return null;
//     }
//   }

//   @override
//   (String, String) userVisibleInfo() {
//     return (
//       "Rain Alert - Wear grippy shoes${futureRainIsNotable ? ", and bring an umbrella" : ""}",
//       "It rained ${rainBefore.valueAs(Length.mm).ceil()}mm in the last 8 hours, and may rain ${rainInFuture.valueAs(Length.mm).ceil()}mm later",
//     );
//   }
// }
