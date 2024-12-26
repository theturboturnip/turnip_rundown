import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/insights.dart';

part 'repository.g.dart';

@JsonEnum()
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

@JsonSerializable()
class Settings {
  Settings({required this.temperatureUnit, required this.rainfallUnit, required this.weatherConfig});

  @JsonKey(defaultValue: TempDisplay.both)
  final TempDisplay temperatureUnit;
  // TODO actually use this
  @JsonKey(defaultValue: Rainfall.mm)
  final Rainfall rainfallUnit;

  // TODO round current location preference
  // TODO preferences for autodetecting the number of hours to analyse

  @JsonKey(defaultValue: WeatherInsightConfig.initial)
  final WeatherInsightConfig weatherConfig;

  factory Settings.initial() => Settings.fromJson(jsonDecode("{}"));

  factory Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);
  Map<String, dynamic> toJson() => _$SettingsToJson(this);
}

abstract interface class SettingsRepository {
  Settings get settings;
  Future<void> storeSettings(Settings settings);
}
