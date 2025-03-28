import 'package:turnip_rundown/data/http_cache_repository.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/model.dart';
export 'package:turnip_rundown/data/weather/openmeteo/client.dart';

abstract class WeatherClient {
  // Future<CurrentWeather> getWeather(double lat, double long);
  Future<WeatherDataBank> getPredictedWeather(Coordinate coords, HttpCacheRepository cache, {bool forceRefreshCache = false});
}
