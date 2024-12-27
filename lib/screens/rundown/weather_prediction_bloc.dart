import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:turnip_rundown/data.dart';
import 'package:turnip_rundown/screens/rundown/location_list_bloc.dart';

class WeatherPredictConfig extends Equatable {
  const WeatherPredictConfig({
    required this.legend,
    required this.hoursToLookAhead,
    required this.insightConfig,
  });

  final List<LegendElement> legend;
  final int hoursToLookAhead;
  final WeatherInsightConfig insightConfig;

  @override
  List<Object?> get props => [legend, hoursToLookAhead, insightConfig];
}

sealed class WeatherPredictState extends Equatable {
  const WeatherPredictState({
    required this.config,
  });

  final WeatherPredictConfig config;

  @override
  List<Object?> get props => [config];
}

final class LoadingWeatherPrediction extends WeatherPredictState {
  const LoadingWeatherPrediction({required super.config});
}

final class FailedWeatherPrediction extends WeatherPredictState {
  const FailedWeatherPrediction({
    required super.config,
    required this.error,
  });

  final String error;

  @override
  List<Object?> get props => [config, error];
}

final class SuccessfulWeatherPrediction extends WeatherPredictState {
  const SuccessfulWeatherPrediction({
    required super.config,
    required this.weathers,
    required this.insights,
  });

  final List<HourlyPredictedWeather> weathers;
  final WeatherInsights insights;

  @override
  List<Object?> get props => [config, weathers, insights];
}

final class RefreshPredictedWeather {
  const RefreshPredictedWeather({
    required this.config,
  });

  // If this is null that signals to kill any cached stuff.
  final WeatherPredictConfig? config;
}

class WeatherPredictBloc extends Bloc<RefreshPredictedWeather, WeatherPredictState> {
  WeatherPredictBloc(WeatherRepository weather)
      : super(LoadingWeatherPrediction(config: WeatherPredictConfig(legend: const [], hoursToLookAhead: 24, insightConfig: WeatherInsightConfig.initial()))) {
    on<RefreshPredictedWeather>(
      (event, emit) async {
        final config = event.config ?? state.config;
        final weathers =
            Future.wait(config.legend.map((legendElem) => weather.getPredictedWeather(legendElem.location.coordinate, forceRefreshCache: event.config == null)).toList());
        await weathers.then((predictions) {
          emit(SuccessfulWeatherPrediction(
            config: config,
            weathers: predictions,
            insights: WeatherInsights.fromAnalysis(predictions, config.insightConfig, maxLookahead: config.hoursToLookAhead),
          ));
        }).onError((e, s) async {
          print("error $e $s");
          emit(FailedWeatherPrediction(config: config, error: e.toString()));
        });
      },
      transformer: restartable(),
    );
  }
}
