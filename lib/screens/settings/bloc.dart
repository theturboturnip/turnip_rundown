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
    this.mediumRainThreshold,
    this.heavyRainThreshold,
    this.highHumidityThreshold,
    this.maxTemperatureForHighHumidityMist,
    this.minTemperatureForHighHumiditySweat,
    this.minimumBreezyWindspeed,
    this.minimumWindyWindspeed,
    this.minimumGaleyWindspeed,
    this.wakingHourStart,
    this.wakingHourEnd,
    this.boilingMinTemp,
    this.freezingMaxTemp,
  });

  final TempDisplay? temperatureUnit;
  final Rainfall? rainfallUnit;
  final RequestedWeatherBackend? backend;
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
  final int? wakingHourStart;
  final int? wakingHourEnd;
  final Data<Temp>? boilingMinTemp;
  final Data<Temp>? freezingMaxTemp;

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
        mediumRainThreshold: mediumRainThreshold,
        heavyRainThreshold: heavyRainThreshold,
        highHumidityThreshold: highHumidityThreshold,
        maxTemperatureForHighHumidityMist: maxTemperatureForHighHumidityMist,
        minTemperatureForHighHumiditySweat: minTemperatureForHighHumiditySweat,
        minimumBreezyWindspeed: minimumBreezyWindspeed,
        minimumWindyWindspeed: minimumWindyWindspeed,
        minimumGaleyWindspeed: minimumGaleyWindspeed,
        tempMinBoiling: boilingMinTemp,
        tempMinChilly: freezingMaxTemp,
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
