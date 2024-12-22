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
}

final class HighHumidityInsight extends WeatherInsight {
  static HighHumidityInsight? tryFor(HourlyPredictedWeather weather) {}
}

final class HighTemperatureInsight extends WeatherInsight {
  static HighTemperatureInsight? tryFor(HourlyPredictedWeather weather) {}
}

final class LowTemperatureInsight extends WeatherInsight {
  static LowTemperatureInsight? tryFor(HourlyPredictedWeather weather) {}
}

final class SlipperyInsight extends WeatherInsight {
  static SlipperyInsight? tryFor(HourlyPredictedWeather weather) {}
}
