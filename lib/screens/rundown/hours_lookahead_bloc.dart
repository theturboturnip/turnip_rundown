import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:turnip_rundown/data/settings/repository.dart';

class HoursLookaheadState extends Equatable {
  const HoursLookaheadState({required this.lockedUtcLookaheadTo});

  final DateTime? lockedUtcLookaheadTo;

  @override
  List<Object?> get props => [lockedUtcLookaheadTo];
}

sealed class ChangeLockedLookaheadEvent {}

final class CheckLockedLookaheadEvent extends ChangeLockedLookaheadEvent {}

final class IncrementLockedLookaheadEvent extends ChangeLockedLookaheadEvent {
  IncrementLockedLookaheadEvent({required this.currentNumLookaheadHours});

  final int currentNumLookaheadHours;
}

final class DecrementLockedLookaheadEvent extends ChangeLockedLookaheadEvent {
  DecrementLockedLookaheadEvent({required this.currentNumLookaheadHours});

  final int currentNumLookaheadHours;
}

class HoursLookaheadBloc extends Bloc<ChangeLockedLookaheadEvent, HoursLookaheadState> {
  final Stream _refreshStream;
  // This field keeps a stream-subscription alive to keep a timer going for this bloc. Every minute it rechecks the lockedUtcLookaheadTo to see if we've passed it.
  // ignore: unused_field
  late StreamSubscription _streamSubscription;

  HoursLookaheadBloc(SettingsRepository repo)
      : _refreshStream = Stream.periodic(const Duration(minutes: 1), (x) => x),
        super(HoursLookaheadState(lockedUtcLookaheadTo: repo.lockedUtcLookaheadTo)) {
    on<ChangeLockedLookaheadEvent>(
      (event, emit) async {
        var lockedUtcLookaheadTo = state.lockedUtcLookaheadTo;
        final timestamp = DateTime.timestamp();
        switch (event) {
          case CheckLockedLookaheadEvent():
            print("checking");
            break;
          case IncrementLockedLookaheadEvent():
            if (lockedUtcLookaheadTo == null) {
              lockedUtcLookaheadTo = timestamp.add(Duration(hours: math.min(event.currentNumLookaheadHours + 1, 24)));
            } else {
              final cap = timestamp.add(const Duration(hours: 24));
              lockedUtcLookaheadTo = lockedUtcLookaheadTo.add(const Duration(hours: 1));
              if (lockedUtcLookaheadTo.isAfter(cap)) {
                lockedUtcLookaheadTo = cap;
              }
            }
          case DecrementLockedLookaheadEvent():
            if (lockedUtcLookaheadTo == null) {
              lockedUtcLookaheadTo = timestamp.add(Duration(hours: math.min(event.currentNumLookaheadHours - 1, 24)));
            } else {
              lockedUtcLookaheadTo = lockedUtcLookaheadTo.subtract(const Duration(hours: 1));
            }
        }
        if (lockedUtcLookaheadTo != null && timestamp.isAfter(lockedUtcLookaheadTo)) {
          lockedUtcLookaheadTo = null;
        }
        emit(HoursLookaheadState(lockedUtcLookaheadTo: lockedUtcLookaheadTo));
        await repo.storeLockedUtcLookaheadTo(lockedUtcLookaheadTo);
      },
      transformer: sequential(),
    );
    _streamSubscription = _refreshStream.listen((_) => add(CheckLockedLookaheadEvent()));
  }
}
