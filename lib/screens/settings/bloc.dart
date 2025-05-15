import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:turnip_rundown/data/settings/repository.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/insights.dart';

abstract class SettingsEvent {
  const SettingsEvent();

  Settings newSettings(Settings old);
}

final class ResetSettingsWeatherConfigEvent extends SettingsEvent {
  const ResetSettingsWeatherConfigEvent();

  @override
  Settings newSettings(Settings old) {
    return Settings(
      temperatureUnit: old.temperatureUnit,
      rainfallUnit: old.rainfallUnit,
      weatherConfig: WeatherInsightConfigV2.initial,
      wakingHours: old.wakingHours,
      backend: old.backend,
    );
  }
}

final class TweakSettingsEvent extends SettingsEvent {
  TweakSettingsEvent({
    this.temperatureUnit,
    this.rainfallUnit,
    this.backend,
    this.useEstimatedWetBulbTemp,
    this.numberOfHoursPriorRainThreshold,
    this.priorRainThreshold,
    this.rainProbabilityThreshold,
    this.rainMinLight,
    this.rainMinMedium,
    this.rainMinHeavy,
    this.highHumidityThreshold,
    this.maxTemperatureForHighHumidityMist,
    this.minTemperatureForHighHumiditySweat,
    this.windMinBreezy,
    this.windMinWindy,
    this.windMinGaley,
    this.wakingHourStart,
    this.wakingHourEnd,
    this.tempMinBoiling,
    this.tempMinHot,
    this.tempMinWarm,
    this.tempMinMild,
    this.tempMinChilly,
    this.uvMinModerate,
    this.uvMinHigh,
    this.uvMinVeryHigh,
  });

  final TempDisplay? temperatureUnit;
  final Rainfall? rainfallUnit;
  final RequestedWeatherBackend? backend;
  final bool? useEstimatedWetBulbTemp;
  final int? numberOfHoursPriorRainThreshold;
  final Data<Rainfall>? priorRainThreshold;
  final Data<Percent>? rainProbabilityThreshold;
  final Data<Rainfall>? rainMinLight;
  final Data<Rainfall>? rainMinMedium;
  final Data<Rainfall>? rainMinHeavy;
  final Data<Percent>? highHumidityThreshold;
  final Data<Temp>? maxTemperatureForHighHumidityMist;
  final Data<Temp>? minTemperatureForHighHumiditySweat;
  final Data<Speed>? windMinBreezy;
  final Data<Speed>? windMinWindy;
  final Data<Speed>? windMinGaley;
  final int? wakingHourStart;
  final int? wakingHourEnd;
  final Data<Temp>? tempMinBoiling;
  final Data<Temp>? tempMinHot;
  final Data<Temp>? tempMinWarm;
  final Data<Temp>? tempMinMild;
  final Data<Temp>? tempMinChilly;
  final Data<UVIndex>? uvMinModerate;
  final Data<UVIndex>? uvMinHigh;
  final Data<UVIndex>? uvMinVeryHigh;

  @override
  Settings newSettings(Settings old) {
    return Settings(
      temperatureUnit: temperatureUnit ?? old.temperatureUnit,
      rainfallUnit: rainfallUnit ?? old.rainfallUnit,
      backend: backend ?? old.backend,
      weatherConfig: old.weatherConfig.copyWith(
        useEstimatedWetBulbTemp: useEstimatedWetBulbTemp,
        numberOfHoursPriorRainThreshold: numberOfHoursPriorRainThreshold,
        priorRainThreshold: priorRainThreshold,
        rainProbabilityThreshold: rainProbabilityThreshold,
        rainMinMedium: rainMinMedium,
        rainMinHeavy: rainMinHeavy,
        highHumidityThreshold: highHumidityThreshold,
        maxTemperatureForHighHumidityMist: maxTemperatureForHighHumidityMist,
        minTemperatureForHighHumiditySweat: minTemperatureForHighHumiditySweat,
        windMinBreezy: windMinBreezy,
        windMinWindy: windMinWindy,
        windMinGaley: windMinGaley,
        tempMinBoiling: tempMinBoiling,
        tempMinHot: tempMinHot,
        tempMinWarm: tempMinWarm,
        tempMinMild: tempMinMild,
        tempMinChilly: tempMinChilly,
        uvMinModerate: uvMinModerate,
        uvMinHigh: uvMinHigh,
        uvMinVeryHigh: uvMinVeryHigh,
      ),
      wakingHours: old.wakingHours.copyWith(
        start: wakingHourStart,
        end: wakingHourEnd,
      ),
    );
  }
}

class SettingsBloc extends Bloc<SettingsEvent, Settings> {
  SettingsBloc(SettingsRepository repo) : super(repo.settings) {
    on<SettingsEvent>(
      (event, emit) async {
        final newState = event.newSettings(state);
        // Don't emit state until it's stored
        // because repo.storeSettings also updates
        // the repo.settings getter that some components use
        await repo.storeSettings(newState);
        emit(newState);
      },
      transformer: sequential(),
    );
  }
}
