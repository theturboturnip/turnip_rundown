import 'package:collection/collection.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/model.dart';

// From a set of numbers, starting from the lowest number find all contiguous ranges of numbers in the set
// e.g. {1,2, 4, 6,7,8} => (1, 2), (4, 4), (6, 8)
List<(int, int)> hourRangesFromSet(Set<int> hours) {
  if (hours.isEmpty) return [];
  final sortedHours = hours.sorted((a, b) => a.compareTo(b));
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

// From https://en.wikipedia.org/wiki/Rain#Intensity
enum PredictedRain implements Comparable<PredictedRain> {
  light, // x < 2.5mm
  medium, // 2.5mm < x < 7.6mm
  heavy; // 7.6mm < x

  @override
  int compareTo(PredictedRain other) {
    return index.compareTo(other.index);
  }
}

// bool hourMakesConditionsDryer(Data<Temp> temperature, Data<Percent> relHumidity, Data<SolarRadiation> solarRadiation, PredictedRain rainfall) {
//   if (rainfall != PredictedRain.none) {
//     return false;
//   }
//   // Pulled this out of my ass :)
//   return (relHumidity.valueAs(Percent.outOf100) < 60) && (solarRadiation.valueAs(SolarRadiation.wPerM2) >= 1000) || (temperature.valueAs(Temp.celsius) > 15);
// }

class RainStatus {
  RainStatus({required this.preRain, required this.predictedRain});

  // sum of rainfall in the 8 preceding hours
  final Data<Length> preRain;
  // foreach level of predicted rain, the ranges of hours for which that rainfall is predicted (prediction > 15%)
  final Map<PredictedRain, List<(int, int)>> predictedRain;

  factory RainStatus.fromAnalysis(HourlyPredictedWeather weather, int maxLookahead) {
    final preRainMM = weather.precipitationSince24hrAgo.valuesAs(Length.mm).skip(16).sum;
    var predictedRain = <PredictedRain, Set<int>>{
      PredictedRain.light: {},
      PredictedRain.medium: {},
      PredictedRain.heavy: {},
    };
    for (int i = 0; i < weather.precipitation.length && i < maxLookahead; i++) {
      if (weather.precipitationProb[i].valueAs(Percent.outOf100) > 15) {
        var key = PredictedRain.light;
        final length = weather.precipitation[i].valueAs(Length.mm);
        if (length > 7.6) {
          key = PredictedRain.heavy;
        } else if (length > 2.5) {
          key = PredictedRain.medium;
        } else {
          // key already = PredictedRain.light
        }
        predictedRain[key]!.add(i);
      }
    }

    return RainStatus(
      preRain: Data(preRainMM, Length.mm),
      predictedRain: predictedRain.map((key, hours) => MapEntry(key, hourRangesFromSet(hours))),
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
  final Map<PredictedHighHumidity, List<(int, int)>> predictedHumitity;

  factory HumidStatus.fromAnalysis(HourlyPredictedWeather weather, int maxLookahead) {
    var predictedHumitity = <PredictedHighHumidity, Set<int>>{
      PredictedHighHumidity.sweaty: {},
      PredictedHighHumidity.uncomfortable: {},
      PredictedHighHumidity.coolMist: {},
    };
    for (int i = 0; i < weather.relHumidity.length && i < maxLookahead; i++) {
      if (weather.relHumidity[i].valueAs(Percent.outOf100) > 80) {
        var key = PredictedHighHumidity.coolMist;
        final tempC = weather.estimatedWetBulbGlobeTemp[i].valueAs(Temp.celsius);
        if (tempC > 17) {
          key = PredictedHighHumidity.sweaty;
        } else if (tempC > 10) {
          key = PredictedHighHumidity.uncomfortable;
        } else {
          key = PredictedHighHumidity.coolMist;
        }
        predictedHumitity[key]!.add(i);
      }
    }
    return HumidStatus(predictedHumitity: predictedHumitity.map((key, hours) => MapEntry(key, hourRangesFromSet(hours))));
  }
}

// https://www.weather.gov/pqr/wind
enum PredictedWind implements Comparable<PredictedWind> {
  breezy, // 4mph < x < 13mph
  windy, // 13mph < x < 32mph
  galey; // 32+mph

  @override
  int compareTo(PredictedWind other) {
    return index.compareTo(other.index);
  }
}

class WindStatus {
  WindStatus({required this.predictedWind});

  // foreach level of wind, the set of hours for which that level is predicted
  final Map<PredictedWind, List<(int, int)>> predictedWind;

  factory WindStatus.fromAnalysis(HourlyPredictedWeather weather, int maxLookahead) {
    var predictedWind = <PredictedWind, Set<int>>{
      PredictedWind.breezy: {},
      PredictedWind.windy: {},
      PredictedWind.galey: {},
    };
    for (int i = 0; i < weather.windspeed.length && i < maxLookahead; i++) {
      final windSpeedMph = weather.windspeed[i].valueAs(Speed.milesPerHour);

      PredictedWind? key;
      if (windSpeedMph > 32) {
        key = PredictedWind.galey;
      } else if (windSpeedMph > 13) {
        key = PredictedWind.windy;
      } else if (windSpeedMph > 4) {
        key = PredictedWind.breezy;
      }

      if (key != null) {
        predictedWind[key]!.add(i);
      }
    }
    return WindStatus(predictedWind: predictedWind.map((key, hours) => MapEntry(key, hourRangesFromSet(hours))));
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

  factory WeatherInsights.fromAnalysis(List<HourlyPredictedWeather> weathers, {int maxLookahead = 24}) {
    assert(weathers.isNotEmpty);
    List<(double, double)> minMaxTempC = weathers.map((weather) => weather.estimatedWetBulbGlobeTemp.valuesAs(Temp.celsius).take(maxLookahead).minMax as (double, double)).toList();
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
      rainAt: weathers.map((weather) => RainStatus.fromAnalysis(weather, maxLookahead)).toList(),
      humidityAt: weathers.map((weather) => HumidStatus.fromAnalysis(weather, maxLookahead)).toList(),
      windAt: weathers.map((weather) => WindStatus.fromAnalysis(weather, maxLookahead)).toList(),
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
