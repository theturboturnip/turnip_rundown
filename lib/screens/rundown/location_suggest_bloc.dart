import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:rxdart/rxdart.dart';
import 'package:turnip_rundown/data/geo/repository.dart';
import 'package:turnip_rundown/data/units.dart';

class LocationSuggestState {
  LocationSuggestState({required this.query, required this.suggested});

  final String query;
  final List<Location>? suggested;
}

class UpdateLocationQuery {
  UpdateLocationQuery({required this.newQuery, this.near});

  final String newQuery;
  final Coordinate? near;
}

class LocationSuggestBloc extends Bloc<UpdateLocationQuery, LocationSuggestState> {
  LocationSuggestBloc(GeocoderRepository geocoder) : super(LocationSuggestState(query: "", suggested: null)) {
    on<UpdateLocationQuery>(
      (event, emit) async {
        final suggested = await geocoder.suggestLocations(event.newQuery, near: event.near).onError((e, s) async {
          print("error $e $s");
          return [];
        });
        emit(LocationSuggestState(query: event.newQuery, suggested: suggested));
      },
      transformer: debounceRestartable(const Duration(milliseconds: 300)),
    );
  }
}

EventTransformer<RegistrationEvent> debounceRestartable<RegistrationEvent>(
  Duration duration,
) {
  // This feeds the debounced event stream to restartable() and returns that
  // as a transformer.
  return (events, mapper) => restartable<RegistrationEvent>().call(events.debounceTime(duration), mapper);
}
