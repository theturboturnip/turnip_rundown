import 'package:collection/collection.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/model.dart';

sealed class WeatherInsight {
  static List<WeatherInsight> getInsights(HourlyPredictedWeather weather) {
    return [
      HighHumidityInsight.tryFor(weather),
      HighTemperatureInsight.tryFor(weather),
      LowTemperatureInsight.tryFor(weather),
      SlipperyInsight.tryFor(weather),
    ].whereType<WeatherInsight>().toList();
  }

  (String, String) userVisibleInfo();
}

final class HighHumidityInsight extends WeatherInsight {
  HighHumidityInsight({required this.max});

  final Data<Percent> max;

  static HighHumidityInsight? tryFor(HourlyPredictedWeather weather) {
    double maxHumidity = weather.relHumidity.valuesAs(Percent.outOf100).max;
    // In the UK, typically between 70-100 - put the threshold at the midpoint
    if (maxHumidity >= 85) {
      return HighHumidityInsight(max: Data(maxHumidity, Percent.outOf100));
    } else {
      return null;
    }
  }

  @override
  (String, String) userVisibleInfo() {
    return (
      "High Humidity - Avoid physical activity, or wear loose clothing",
      "Max Humidity: ${max.valueAs(Percent.outOf100).ceil()}%",
    );
  }
}

final class HighTemperatureInsight extends WeatherInsight {
  HighTemperatureInsight({required this.max});

  final Data<Temp> max;

  static HighTemperatureInsight? tryFor(HourlyPredictedWeather weather) {
    double maxTempC = weather.estimatedWetBulbGlobeTemp.valuesAs(Temp.celsius).max;
    // TODO figure out threshold
    if (maxTempC > 20) {
      return HighTemperatureInsight(max: Data(maxTempC, Temp.celsius));
    } else {
      return null;
    }
  }

  @override
  (String, String) userVisibleInfo() {
    return (
      "High Temperature - Avoid physical activity, or wear loose clothing",
      "Max Temperature: ${max.valueAs(Temp.celsius).ceil()}C",
    );
  }
}

final class LowTemperatureInsight extends WeatherInsight {
  LowTemperatureInsight({required this.min});

  final Data<Temp> min;

  static LowTemperatureInsight? tryFor(HourlyPredictedWeather weather) {
    double minTempC = weather.estimatedWetBulbGlobeTemp.valuesAs(Temp.celsius).min;
    if (minTempC < 10) {
      return LowTemperatureInsight(min: Data(minTempC, Temp.celsius));
    } else {
      return null;
    }
  }

  @override
  (String, String) userVisibleInfo() {
    return (
      "Low Temperature - Bundle up!",
      "Min Temperature: ${min.valueAs(Temp.celsius).ceil()}C",
    );
  }
}

final class SlipperyInsight extends WeatherInsight {
  final Data<Length> rainBefore;
  final Data<Length> rainInFuture;
  final bool futureRainIsNotable;

  SlipperyInsight({required this.rainBefore, required this.rainInFuture, required this.futureRainIsNotable});

  static SlipperyInsight? tryFor(HourlyPredictedWeather weather) {
    // If there was at least 1mm of rain since 8hr ago
    double rainBefore = weather.precipitationSince24hrAgo.valuesAs(Length.mm).take(16).sum;
    // or if there will be at least 1mm of rain in the next 24 hrs
    double rainInFuture = weather.precipitation.valuesAs(Length.mm).sum;

    if (rainBefore > 1 || rainInFuture > 1) {
      return SlipperyInsight(
        rainBefore: Data(rainBefore, Length.mm),
        rainInFuture: Data(rainInFuture, Length.mm),
        futureRainIsNotable: rainInFuture > 1,
      );
    } else {
      return null;
    }
  }

  @override
  (String, String) userVisibleInfo() {
    return (
      "Rain Alert - Wear grippy shoes${futureRainIsNotable ? ", and bring an umbrella" : ""}",
      "It rained ${rainBefore.valueAs(Length.mm).ceil()}mm in the last 8 hours, and may rain ${rainInFuture.valueAs(Length.mm).ceil()}mm",
    );
  }
}
