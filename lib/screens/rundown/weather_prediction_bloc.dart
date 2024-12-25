import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:turnip_rundown/data.dart';
import 'package:turnip_rundown/data/geo/repository.dart';

final class WeatherPredictState extends Equatable {
  const WeatherPredictState({
    required this.locations,
    required this.weathers,
    required this.insights,
    this.weatherPredictError,
  });

  final List<Location> locations;
  final List<HourlyPredictedWeather> weathers;
  final WeatherInsights? insights;
  final String? weatherPredictError;

  @override
  List<Object?> get props => [locations, weathers, insights, weatherPredictError];
}

final class RefreshPredictedWeather {
  const RefreshPredictedWeather({required this.locations});

  final List<Location> locations;
}

class WeatherPredictBloc extends Bloc<RefreshPredictedWeather, WeatherPredictState> {
  WeatherPredictBloc(WeatherRepository weather) : super(const WeatherPredictState(locations: [], weathers: [], insights: null)) {
    on<RefreshPredictedWeather>(
      (event, emit) {
        final weathers = Future.wait(event.locations.map((location) => weather.getPredictedWeather(location.coordinate)).toList());
        return weathers.then((predictions) {
          emit(WeatherPredictState(
            locations: event.locations,
            weathers: predictions,
            insights: WeatherInsights.fromAnalysis(predictions),
          ));
        }).onError((e, s) async {
          print("error $e $s");
          emit(WeatherPredictState(
            locations: const [],
            weathers: const [],
            insights: null,
            weatherPredictError: "$e",
          ));
        });
      },
      transformer: restartable(),
    );
  }
}
