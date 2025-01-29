import 'package:turnip_rundown/data/settings/repository.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/model.dart';
export 'package:turnip_rundown/data/weather/openmeteo/repository.dart';

abstract class WeatherRepository {
  // Future<CurrentWeather> getWeather(double lat, double long);
  Future<HourlyPredictedWeather> getPredictedWeather(Coordinate coords, {bool forceRefreshCache = false});
}

final class NotWorkingWeatherRepository extends WeatherRepository {
  @override
  Future<HourlyPredictedWeather> getPredictedWeather(Coordinate coords, {bool forceRefreshCache = false}) {
    return Future.error("No weather connection");
  }
}

final class SwitchWeatherRepository extends WeatherRepository {
  final SettingsRepository settings;
  final Map<RequestedWeatherBackend, WeatherRepository?> repos;

  SwitchWeatherRepository({required this.settings, required this.repos});

  @override
  Future<HourlyPredictedWeather> getPredictedWeather(Coordinate coords, {bool forceRefreshCache = false}) {
    return (repos[settings.settings.backend] ?? repos[RequestedWeatherBackend.openmeteo])!.getPredictedWeather(coords, forceRefreshCache: forceRefreshCache);
  }
}
