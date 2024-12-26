import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:turnip_rundown/data/settings/repository.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/insights.dart';

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
  SettingsBloc(SettingsRepository repo) : super(repo.settings) {
    on<SettingsEvent>(
      (event, emit) async {
        final newState = event.copyOf(state);
        emit(newState);
        await repo.storeSettings(newState);
      },
      transformer: sequential(),
    );
  }
}
