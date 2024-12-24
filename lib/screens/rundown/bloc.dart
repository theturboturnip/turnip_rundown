import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:turnip_rundown/data.dart';
import 'package:turnip_rundown/data/geo/repository.dart';

final class RundownState extends Equatable {
  const RundownState({
    required this.currentLocation,
    required this.includeCurrentLocationInInsights,
    required this.otherNamedLocations,
    this.currentLocationError,
  });

  factory RundownState.initial() => const RundownState(
        currentLocation: null,
        includeCurrentLocationInInsights: true,
        otherNamedLocations: [],
      );

  final Coordinate? currentLocation;

  final bool includeCurrentLocationInInsights;
  final List<NamedCoordinate> otherNamedLocations;
  final String? currentLocationError;

  @override
  List<Object?> get props => [
        currentLocation,
        includeCurrentLocationInInsights,
        otherNamedLocations,
        currentLocationError,
      ];

  List<Coordinate> get coordinates => [
        if (includeCurrentLocationInInsights && currentLocation != null) currentLocation!,
        ...otherNamedLocations.map((namedLocation) => namedLocation.location),
      ];
}

sealed class RundownEvent {
  const RundownEvent();
}

final class RefreshCurrentLocation extends RundownEvent {
  const RefreshCurrentLocation();
}

final class MarkCurrentLocationAsIncluded extends RundownEvent {
  const MarkCurrentLocationAsIncluded();
}

final class MarkCurrentLocationAsExcluded extends RundownEvent {
  const MarkCurrentLocationAsExcluded();
}

final class AppendOtherLocation extends RundownEvent {
  const AppendOtherLocation({required this.otherLocation});
  final NamedCoordinate otherLocation;
}

final class RemoveOtherLocation extends RundownEvent {
  const RemoveOtherLocation({required this.index});
  final int index;
}

class RundownBloc extends Bloc<RundownEvent, RundownState> {
  RundownBloc(LocationRepository location)
      : super(
          RundownState.initial(),
        ) {
    on<RefreshCurrentLocation>(
      (event, emit) async {
        await location.getLocation().then((newCoordinate) async {
          // TODO make rounding precision a preference?
          newCoordinate = newCoordinate.roundedTo(2, elevationDp: 0);
          if (state.includeCurrentLocationInInsights) {
            emit(RundownState(
              currentLocation: newCoordinate,
              includeCurrentLocationInInsights: state.includeCurrentLocationInInsights,
              otherNamedLocations: state.otherNamedLocations,
            ));
          } else {
            emit(RundownState(
              currentLocation: newCoordinate,
              includeCurrentLocationInInsights: state.includeCurrentLocationInInsights,
              otherNamedLocations: state.otherNamedLocations,
            ));
          }
        }).onError((e, s) {
          print("error $e $s");
          emit(RundownState(
            currentLocation: null,
            includeCurrentLocationInInsights: state.includeCurrentLocationInInsights,
            otherNamedLocations: state.otherNamedLocations,
            currentLocationError: "$e",
          ));
        });
      },
      transformer: restartable(),
    );
    // TODO handle MarkCurrentLocationAsBlah with a common subclass so that events don't conflict with each other concurrently?
    on<MarkCurrentLocationAsIncluded>(
      (event, emit) {
        emit(RundownState(
          currentLocation: state.currentLocation,
          includeCurrentLocationInInsights: true,
          otherNamedLocations: state.otherNamedLocations,
        ));
      },
      transformer: sequential(),
    );
    on<MarkCurrentLocationAsExcluded>(
      (event, emit) {
        emit(RundownState(
          currentLocation: state.currentLocation,
          includeCurrentLocationInInsights: true,
          otherNamedLocations: state.otherNamedLocations,
        ));
      },
      transformer: sequential(),
    );
    // TODO handle AppendOtherLocation and RemoveOtherLocation with a common subclass so that events don't conflict with each other concurrently?
    on<AppendOtherLocation>(
      (event, emit) {
        emit(RundownState(
          currentLocation: state.currentLocation,
          includeCurrentLocationInInsights: state.includeCurrentLocationInInsights,
          otherNamedLocations: [
            ...state.otherNamedLocations,
            event.otherLocation,
          ],
        ));
      },
      transformer: sequential(),
    );
    on<RemoveOtherLocation>(
      (event, emit) {
        emit(RundownState(
          currentLocation: state.currentLocation,
          includeCurrentLocationInInsights: state.includeCurrentLocationInInsights,
          otherNamedLocations: List.from(state.otherNamedLocations)..removeAt(event.index),
        ));
      },
      transformer: sequential(),
    );
  }
}

final class WeatherPredictState extends Equatable {
  const WeatherPredictState({
    required this.weathers,
    required this.insights,
    this.weatherPredictError,
  });

  final List<HourlyPredictedWeather> weathers;
  final List<WeatherInsight> insights;
  final String? weatherPredictError;

  @override
  List<Object?> get props => [weathers, insights, weatherPredictError];
}

final class RefreshPredictedWeather {
  const RefreshPredictedWeather({required this.coordinates});

  final List<Coordinate> coordinates;
}

class WeatherPredictBloc extends Bloc<RefreshPredictedWeather, WeatherPredictState> {
  WeatherPredictBloc(WeatherRepository weather) : super(const WeatherPredictState(weathers: [], insights: [])) {
    on<RefreshPredictedWeather>(
      (event, emit) {
        final weathers = Future.wait(event.coordinates.map((coords) => weather.getPredictedWeather(coords)).toList());
        return weathers.then((predictions) {
          // TODO do predictions a little more sensibly - put in a Set to avoid uniqueness? process all weathers together?
          final newInsights = predictions.map((p) => WeatherInsight.getInsights(p)).flattened.toList();
          emit(WeatherPredictState(
            weathers: predictions,
            insights: newInsights,
          ));
        }).onError((e, s) async {
          print("error $e $s");
          emit(WeatherPredictState(
            weathers: const [],
            insights: const [],
            weatherPredictError: "$e",
          ));
        });
      },
      transformer: restartable(),
    );
  }
}
