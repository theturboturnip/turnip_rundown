import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:turnip_rundown/data.dart';
import 'package:turnip_rundown/data/geo/repository.dart';

final class LocationListState extends Equatable {
  const LocationListState({
    required this.currentCoordinate,
    required this.includeCurrentCoordinateInInsights,
    required this.otherNamedLocations,
    this.currentCoordinateError,
  });

  factory LocationListState.initial() => const LocationListState(
        currentCoordinate: null,
        includeCurrentCoordinateInInsights: true,
        otherNamedLocations: [],
      );

  final Coordinate? currentCoordinate;
  final bool includeCurrentCoordinateInInsights;
  final List<Location> otherNamedLocations;
  final String? currentCoordinateError;

  @override
  List<Object?> get props => [
        currentCoordinate,
        includeCurrentCoordinateInInsights,
        otherNamedLocations,
        currentCoordinateError,
      ];

  List<Location> get coordinates => [
        if (includeCurrentCoordinateInInsights && currentCoordinate != null) Location(name: "your location", address: "", coordinate: currentCoordinate!),
        ...otherNamedLocations,
      ];
}

sealed class LocationListEvent {
  const LocationListEvent();
}

final class RefreshCurrentCoordinate extends LocationListEvent {
  const RefreshCurrentCoordinate();
}

final class MarkCurrentCoordinateAsIncluded extends LocationListEvent {
  const MarkCurrentCoordinateAsIncluded();
}

final class MarkCurrentCoordinateAsExcluded extends LocationListEvent {
  const MarkCurrentCoordinateAsExcluded();
}

final class AppendOtherLocation extends LocationListEvent {
  const AppendOtherLocation({required this.otherLocation});
  final Location otherLocation;
}

final class RemoveOtherLocation extends LocationListEvent {
  const RemoveOtherLocation({required this.index});
  final int index;
}

class LocationListBloc extends Bloc<LocationListEvent, LocationListState> {
  LocationListBloc(CurrentCoordinateRepository location)
      : super(
          LocationListState.initial(),
        ) {
    on<RefreshCurrentCoordinate>(
      (event, emit) async {
        await location.getCoordinate().then((newCoordinate) async {
          // TODO make rounding precision a preference?
          newCoordinate = newCoordinate.roundedTo(2, elevationDp: 0);
          if (state.includeCurrentCoordinateInInsights) {
            emit(LocationListState(
              currentCoordinate: newCoordinate,
              includeCurrentCoordinateInInsights: state.includeCurrentCoordinateInInsights,
              otherNamedLocations: state.otherNamedLocations,
            ));
          } else {
            emit(LocationListState(
              currentCoordinate: newCoordinate,
              includeCurrentCoordinateInInsights: state.includeCurrentCoordinateInInsights,
              otherNamedLocations: state.otherNamedLocations,
            ));
          }
        }).onError((e, s) {
          print("error $e $s");
          emit(LocationListState(
            currentCoordinate: null,
            includeCurrentCoordinateInInsights: state.includeCurrentCoordinateInInsights,
            otherNamedLocations: state.otherNamedLocations,
            currentCoordinateError: "$e",
          ));
        });
      },
      transformer: restartable(),
    );
    // TODO handle MarkCurrentLocationAsBlah with a common subclass so that events don't conflict with each other concurrently?
    on<MarkCurrentCoordinateAsIncluded>(
      (event, emit) {
        emit(LocationListState(
          currentCoordinate: state.currentCoordinate,
          includeCurrentCoordinateInInsights: true,
          otherNamedLocations: state.otherNamedLocations,
        ));
      },
      transformer: sequential(),
    );
    on<MarkCurrentCoordinateAsExcluded>(
      (event, emit) {
        emit(LocationListState(
          currentCoordinate: state.currentCoordinate,
          includeCurrentCoordinateInInsights: false,
          otherNamedLocations: state.otherNamedLocations,
        ));
      },
      transformer: sequential(),
    );
    // TODO handle AppendOtherLocation and RemoveOtherLocation with a common subclass so that events don't conflict with each other concurrently?
    on<AppendOtherLocation>(
      (event, emit) {
        emit(LocationListState(
          currentCoordinate: state.currentCoordinate,
          includeCurrentCoordinateInInsights: state.includeCurrentCoordinateInInsights,
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
        emit(LocationListState(
          currentCoordinate: state.currentCoordinate,
          includeCurrentCoordinateInInsights: state.includeCurrentCoordinateInInsights,
          otherNamedLocations: List.from(state.otherNamedLocations)..removeAt(event.index),
        ));
      },
      transformer: sequential(),
    );
  }
}
