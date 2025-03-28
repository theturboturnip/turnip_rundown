import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:turnip_rundown/data.dart';
import 'package:turnip_rundown/data/geo/repository.dart';
import 'package:turnip_rundown/data/settings/repository.dart';

final class LocationListState extends Equatable {
  const LocationListState({
    required this.currentCoordinate,
    required this.includeCurrentCoordinateInInsights,
    required this.otherNamedLocations,
    this.currentCoordinateError,
  });

  factory LocationListState.initial(Coordinate? currentCoordinate) => LocationListState(
        currentCoordinate: currentCoordinate,
        includeCurrentCoordinateInInsights: true,
        otherNamedLocations: const [],
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

  List<LegendElement> get legend {
    var legend = <LegendElement>[];
    if (includeCurrentCoordinateInInsights && currentCoordinate != null) {
      legend.add(
        LegendElement(
          isYourCoordinate: true,
          location: Location(
            name: "Your Location",
            address: "",
            coordinate: currentCoordinate!,
          ),
        ),
      );
    }
    legend.addAll(otherNamedLocations.map((location) => LegendElement(isYourCoordinate: false, location: location)));
    return legend;
  }
}

final class LegendElement {
  final bool isYourCoordinate;
  final Location location;

  LegendElement({required this.isYourCoordinate, required this.location});
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
  LocationListBloc(CurrentCoordinateRepository location, SettingsRepository settings)
      : super(
          LocationListState.initial(settings.lastGeocoordLookup),
        ) {
    on<RefreshCurrentCoordinate>(
      (event, emit) async {
        await location.getCoordinate().then((newCoordinate) async {
          // TODO make rounding precision a preference?
          newCoordinate = newCoordinate.roundedTo(2, elevationDp: 0);
          settings.storeLastGeocoordLookup(newCoordinate);
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
          currentCoordinateError: state.currentCoordinateError,
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
          currentCoordinateError: state.currentCoordinateError,
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
          currentCoordinateError: state.currentCoordinateError,
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
          currentCoordinateError: state.currentCoordinateError,
        ));
      },
      transformer: sequential(),
    );
  }
}
