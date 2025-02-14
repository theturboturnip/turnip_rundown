import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:turnip_rundown/data/settings/repository.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/insights.dart';

final class SettingsEvent {
  SettingsEvent({
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

  Settings copyOf(Settings base) {
    return Settings(
      temperatureUnit: temperatureUnit ?? base.temperatureUnit,
      rainfallUnit: rainfallUnit ?? base.rainfallUnit,
      backend: backend ?? base.backend,
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
        boilingMinTemp: boilingMinTemp,
        freezingMaxTemp: freezingMaxTemp,
      ),
      wakingHours: base.wakingHours.copyWith(
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
        final newState = event.copyOf(state);
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
