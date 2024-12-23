import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:turnip_rundown/data.dart';

enum RundownError {
  cantRetrieveLocation,
  cantRetrieveWeather,
}

final class RundownState {
  RundownState({
    required this.location,
    required this.weather,
    required this.insights,
    this.error,
  });

  final Coordinate? location;
  final HourlyPredictedWeather? weather;
  final List<WeatherInsight> insights;
  final RundownError? error;
}

sealed class RundownEvent {
  const RundownEvent();
}

final class RefreshCoordinate extends RundownEvent {
  const RefreshCoordinate();
}

final class RefreshPredictedWeather extends RundownEvent {
  const RefreshPredictedWeather();
}

class RundownBloc extends Bloc<RundownEvent, RundownState> {
  RundownBloc(LocationRepository location, WeatherRepository weather) : super(RundownState(location: null, weather: null, insights: [])) {
    on<RefreshCoordinate>(
      (event, emit) async {
        await location.getLocation().then((newCoordinate) async {
          // TODO make rounding precision a preference?
          newCoordinate = newCoordinate.roundedTo(2, elevationDp: 0);
          emit(RundownState(location: newCoordinate, weather: null, insights: []));
          await emitNewWeatherPrediction(weather, newCoordinate, emit);
        }).onError((e, s) {
          print("error $e $s");
          emit(RundownState(location: null, weather: null, insights: [], error: RundownError.cantRetrieveLocation));
        });
      },
      transformer: droppable(),
    );
    on<RefreshPredictedWeather>(
      (event, emit) async {
        if (state.location != null) {
          await emitNewWeatherPrediction(weather, state.location!, emit);
        }
      },
      transformer: droppable(),
    );
  }

  Future<void> emitNewWeatherPrediction(WeatherRepository weather, Coordinate location, Emitter emit) {
    return weather.getPredictedWeather(location).then((predictions) {
      final newInsights = WeatherInsight.getInsights(predictions);
      emit(RundownState(location: location, weather: predictions, insights: newInsights));
    }).onError((e, s) async {
      print("error $e $s");
      emit(RundownState(location: location, weather: null, insights: [], error: RundownError.cantRetrieveWeather));
    });
  }
}
