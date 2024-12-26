import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/insights.dart';

part 'bloc.g.dart';

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

  factory Settings.fromBox(Box box) {
    return Settings.fromJson(jsonDecode(box.get("asJson", defaultValue: "{}")));
  }

  factory Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);
  Map<String, dynamic> toJson() => _$SettingsToJson(this);

  Future<void> applyToBox(Box box) {
    return box.put("asJson", jsonEncode(toJson()));
  }
}

final class SettingsEvent {
  SettingsEvent({
    this.temperatureUnit,
    this.rainfallUnit,
    this.useEstimatedWetBulbTemp,
    this.numberOfHoursPriorRainThreshold,
    this.priorRainThreshold,
    this.rainProbabilityThreshold,
    this.mediumRainThreshold,
    this.heavyRainThreshold,
    this.highHumidityThreshold,
    this.maxTemperatureForHighHumidityMist,
    this.minTemperatureForHighHumiditySweat,
    this.minimumBreezyWindspeed,
    this.minimumWindyWindspeed,
    this.minimumGaleyWindspeed,
  });

  factory SettingsEvent.withInitialWeatherConfig() {
    final config = WeatherInsightConfig.initial();
    return SettingsEvent(
      useEstimatedWetBulbTemp: config.useEstimatedWetBulbTemp,
      numberOfHoursPriorRainThreshold: config.numberOfHoursPriorRainThreshold,
      priorRainThreshold: config.priorRainThreshold,
      rainProbabilityThreshold: config.rainProbabilityThreshold,
      mediumRainThreshold: config.mediumRainThreshold,
      heavyRainThreshold: config.heavyRainThreshold,
      highHumidityThreshold: config.highHumidityThreshold,
      maxTemperatureForHighHumidityMist: config.maxTemperatureForHighHumidityMist,
      minTemperatureForHighHumiditySweat: config.minTemperatureForHighHumiditySweat,
      minimumBreezyWindspeed: config.minimumBreezyWindspeed,
      minimumWindyWindspeed: config.minimumWindyWindspeed,
      minimumGaleyWindspeed: config.minimumGaleyWindspeed,
    );
  }

  final TempDisplay? temperatureUnit;
  final Rainfall? rainfallUnit;
  final bool? useEstimatedWetBulbTemp;
  final int? numberOfHoursPriorRainThreshold;
  final Data<Rainfall>? priorRainThreshold;
  final Data<Percent>? rainProbabilityThreshold;
  final Data<Rainfall>? mediumRainThreshold;
  final Data<Rainfall>? heavyRainThreshold;
  final Data<Percent>? highHumidityThreshold;
  final Data<Temp>? maxTemperatureForHighHumidityMist;
  final Data<Temp>? minTemperatureForHighHumiditySweat;
  final Data<Speed>? minimumBreezyWindspeed;
  final Data<Speed>? minimumWindyWindspeed;
  final Data<Speed>? minimumGaleyWindspeed;

  Settings copyOf(Settings base) {
    return Settings(
      temperatureUnit: temperatureUnit ?? base.temperatureUnit,
      rainfallUnit: rainfallUnit ?? base.rainfallUnit,
      weatherConfig: base.weatherConfig.copyWith(
        useEstimatedWetBulbTemp: useEstimatedWetBulbTemp,
        numberOfHoursPriorRainThreshold: numberOfHoursPriorRainThreshold,
        priorRainThreshold: priorRainThreshold,
        rainProbabilityThreshold: rainProbabilityThreshold,
        mediumRainThreshold: mediumRainThreshold,
        heavyRainThreshold: heavyRainThreshold,
        highHumidityThreshold: highHumidityThreshold,
        maxTemperatureForHighHumidityMist: maxTemperatureForHighHumidityMist,
        minTemperatureForHighHumiditySweat: minTemperatureForHighHumiditySweat,
        minimumBreezyWindspeed: minimumBreezyWindspeed,
        minimumWindyWindspeed: minimumWindyWindspeed,
        minimumGaleyWindspeed: minimumGaleyWindspeed,
      ),
    );
  }
}

class SettingsBloc extends Bloc<SettingsEvent, Settings> {
  SettingsBloc(this.box) : super(Settings.fromBox(box)) {
    on<SettingsEvent>(
      (event, emit) async {
        final newState = event.copyOf(state);
        emit(newState);
        await newState.applyToBox(box);
      },
      transformer: sequential(),
    );
  }

  final Box box;
}
