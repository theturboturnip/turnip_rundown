import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:turnip_rundown/data/settings/repository.dart';
import 'package:turnip_rundown/util.dart';

class HoursLookaheadState extends Equatable {
  const HoursLookaheadState({required this.lockedUtcLookaheadTo, required this.decrementWillResultInReset});

  final UtcDateTime? lockedUtcLookaheadTo;
  // If the locked time is close enough to the current time, decrementing it will result in it resetting entirely.
  final bool decrementWillResultInReset;

  @override
  List<Object?> get props => [lockedUtcLookaheadTo, decrementWillResultInReset];
}

sealed class ChangeLockedLookaheadEvent {
  const ChangeLockedLookaheadEvent();
}

final class CheckLockedLookaheadEvent extends ChangeLockedLookaheadEvent {
  const CheckLockedLookaheadEvent();
}

final class IncrementLockedLookaheadEvent extends ChangeLockedLookaheadEvent {
  const IncrementLockedLookaheadEvent({
    required this.hour0InLocalTime,
    required this.currentNumLookaheadHours,
  });

  final LocalDateTime hour0InLocalTime;
  final int currentNumLookaheadHours;
}

final class DecrementLockedLookaheadEvent extends ChangeLockedLookaheadEvent {
  const DecrementLockedLookaheadEvent({
    required this.hour0InLocalTime,
    required this.currentNumLookaheadHours,
  });

  final LocalDateTime hour0InLocalTime;
  final int currentNumLookaheadHours;
}

final class ClearLockedLookaheadEvent extends ChangeLockedLookaheadEvent {
  const ClearLockedLookaheadEvent();
}

class HoursLookaheadBloc extends Bloc<ChangeLockedLookaheadEvent, HoursLookaheadState> {
  final Stream _refreshStream;
  // This field keeps a stream-subscription alive to keep a timer going for this bloc. Every minute it rechecks the lockedUtcLookaheadTo to see if we've passed it.
  // ignore: unused_field
  late StreamSubscription _streamSubscription;

  HoursLookaheadBloc(SettingsRepository repo)
    : _refreshStream = Stream.periodic(const Duration(minutes: 1), (x) => x),
      super(HoursLookaheadState(lockedUtcLookaheadTo: repo.lockedUtcLookaheadTo, decrementWillResultInReset: false)) {
    on<ChangeLockedLookaheadEvent>(
      (event, emit) async {
        var lockedUtcLookaheadTo = state.lockedUtcLookaheadTo;
        final timestamp = UtcDateTime.timestamp();
        switch (event) {
          case CheckLockedLookaheadEvent():
            print("checking locked-lookahead $lockedUtcLookaheadTo");
            break;
          case IncrementLockedLookaheadEvent():
            if (lockedUtcLookaheadTo == null) {
              lockedUtcLookaheadTo = (event.hour0InLocalTime.toUtc()).add(Duration(hours: math.min(event.currentNumLookaheadHours + 1, 23)));
            } else {
              final cap = (event.hour0InLocalTime.toUtc()).add(const Duration(hours: 23));
              lockedUtcLookaheadTo = lockedUtcLookaheadTo.add(const Duration(hours: 1));
              if (lockedUtcLookaheadTo.isAfter(cap)) {
                lockedUtcLookaheadTo = cap;
              }
            }
          case DecrementLockedLookaheadEvent():
            if (lockedUtcLookaheadTo == null) {
              lockedUtcLookaheadTo = (event.hour0InLocalTime.toUtc()).add(Duration(hours: math.min(event.currentNumLookaheadHours - 1, 23)));
            } else {
              lockedUtcLookaheadTo = lockedUtcLookaheadTo.subtract(const Duration(hours: 1));
            }
          case ClearLockedLookaheadEvent():
            lockedUtcLookaheadTo = null;
        }
        if (lockedUtcLookaheadTo != null && timestamp.isAfter(lockedUtcLookaheadTo)) {
          lockedUtcLookaheadTo = null;
        }

        if (lockedUtcLookaheadTo != state.lockedUtcLookaheadTo) {
          await repo.storeLockedUtcLookaheadTo(lockedUtcLookaheadTo);
        }

        emit(
          HoursLookaheadState(
            lockedUtcLookaheadTo: lockedUtcLookaheadTo,
            decrementWillResultInReset: (lockedUtcLookaheadTo != null && lockedUtcLookaheadTo.subtract(const Duration(hours: 1)).isBefore(timestamp)),
          ),
        );
      },
      transformer: sequential(),
    );
    _streamSubscription = _refreshStream.listen((_) => add(const CheckLockedLookaheadEvent()));
  }
}
