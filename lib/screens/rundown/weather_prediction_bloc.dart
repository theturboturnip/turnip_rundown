import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:turnip_rundown/data.dart';
import 'package:turnip_rundown/screens/rundown/location_list_bloc.dart';

final class WeatherPredictState extends Equatable {
  const WeatherPredictState({
    required this.legend,
    required this.weathers,
    required this.insights,
    this.weatherPredictError,
  });

  final List<LegendElement> legend;
  final List<HourlyPredictedWeather> weathers;
  final WeatherInsights? insights;
  final String? weatherPredictError;

  @override
  List<Object?> get props => [legend, weathers, insights, weatherPredictError];
}

final class RefreshPredictedWeather {
  const RefreshPredictedWeather({required this.legend});

  final List<LegendElement> legend;
}

class WeatherPredictBloc extends Bloc<RefreshPredictedWeather, WeatherPredictState> {
  WeatherPredictBloc(WeatherRepository weather) : super(const WeatherPredictState(legend: [], weathers: [], insights: null)) {
    on<RefreshPredictedWeather>(
      (event, emit) {
        final weathers = Future.wait(event.legend.map((legendElem) => weather.getPredictedWeather(legendElem.location.coordinate)).toList());
        return weathers.then((predictions) {
          emit(WeatherPredictState(
            legend: event.legend,
            weathers: predictions,
            insights: WeatherInsights.fromAnalysis(predictions),
          ));
        }).onError((e, s) async {
          print("error $e $s");
          emit(WeatherPredictState(
            legend: const [],
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
