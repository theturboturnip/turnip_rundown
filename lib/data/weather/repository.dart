import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/model.dart';

abstract class WeatherRepository {
  // Future<CurrentWeather> getWeather(double lat, double long);
  Future<List<HourlyPredictedWeather>> getPredictedWeather(List<Coordinate> coords);
}

final class NotWorkingWeatherRepository extends WeatherRepository {
  @override
  Future<List<HourlyPredictedWeather>> getPredictedWeather(List<Coordinate> coords) {
    return Future.error("No weather connection");
  }
}
