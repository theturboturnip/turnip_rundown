import 'package:bloc/bloc.dart';
import 'package:hive/hive.dart';
import 'package:turnip_rundown/data/units.dart';

enum TempDisplay {
  celsius,
  farenheit,
  both;

  Iterable<Temp> displayUnits() {
    switch (this) {
      case TempDisplay.celsius:
        return [Temp.celsius];
      case TempDisplay.farenheit:
        return [Temp.farenheit];
      case TempDisplay.both:
        return [Temp.celsius, Temp.farenheit];
    }
  }
}

class SettingsState {
  SettingsState({required this.temperatureUnit, required this.rainfallUnit});

  final TempDisplay temperatureUnit;
  final Rainfall rainfallUnit;

  factory SettingsState.fromBox(Box box) {
    return SettingsState(
      temperatureUnit: TempDisplay.values[box.get("temperatureUnit", defaultValue: TempDisplay.both.index)],
      rainfallUnit: Rainfall.values[box.get("rainfallUnit", defaultValue: Rainfall.mm.index)],
    );
  }

  SettingsState withArgs({
    TempDisplay? temperatureUnit,
    Rainfall? rainfallUnit,
  }) {
    return SettingsState(
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      rainfallUnit: rainfallUnit ?? this.rainfallUnit,
    );
  }

  void applyToBox(Box box) {
    box.put("temperatureUnit", temperatureUnit.index);
    box.put("rainfallUnit", rainfallUnit.index);
  }
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this.box) : super(SettingsState.fromBox(box));

  final Box box;

  void updateTemperature(TempDisplay temperatureUnit) {
    emit(state.withArgs(temperatureUnit: temperatureUnit)..applyToBox(box));
  }

  void updateRainfall(Rainfall rainfallUnit) {
    emit(state.withArgs(rainfallUnit: rainfallUnit)..applyToBox(box));
  }
}
