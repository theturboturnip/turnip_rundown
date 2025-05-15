import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:turnip_rundown/data.dart';
import 'package:turnip_rundown/data/settings/repository.dart';
import 'package:turnip_rundown/data/weather_data_bank_repository.dart';
import 'package:turnip_rundown/screens/rundown/location_list_bloc.dart';
import 'package:turnip_rundown/util.dart';

class WeatherPredictConfig extends Equatable {
  const WeatherPredictConfig({
    required this.legend,
    required this.hoursToLookAhead,
    required this.insightConfig,
  });

  final List<LegendElement> legend;
  final int hoursToLookAhead;
  final WeatherInsightConfigV2 insightConfig;

  @override
  List<Object?> get props => [legend, hoursToLookAhead, insightConfig];
}

class WeatherInsightsResult extends Equatable {
  final List<HourlyPredictedWeather>? weathersByHour;
  final bool weatherMayBeStale;
  final WeatherInsights? insights;
  final String? error;

  const WeatherInsightsResult({
    required this.weathersByHour,
    required this.weatherMayBeStale,
    required this.insights,
    required this.error,
  });

  @override
  List<Object?> get props => [weathersByHour, insights, error];
}

final class WeatherPredictState extends Equatable {
  const WeatherPredictState({
    required this.config,
    required this.isLoading,
    required this.mostRecentWeatherResult,
  });

  final WeatherPredictConfig config;
  final bool isLoading;
  final WeatherInsightsResult? mostRecentWeatherResult;

  @override
  List<Object?> get props => [config, isLoading, mostRecentWeatherResult];
}

final class RefreshPredictedWeather {
  const RefreshPredictedWeather({
    required this.config,
    required this.forceRefreshCache,
  });

  // can override the current state's config
  final WeatherPredictConfig? config;
  final bool forceRefreshCache;
}

class WeatherPredictBloc extends Bloc<RefreshPredictedWeather, WeatherPredictState> {
  WeatherPredictBloc(SettingsRepository settings, WeatherDataBankRepository weather)
      : super(const WeatherPredictState(
          config: WeatherPredictConfig(legend: [], hoursToLookAhead: 24, insightConfig: WeatherInsightConfigV2.initial),
          isLoading: true,
          mostRecentWeatherResult: null,
        )) {
    // Set a timer: every minute, if any of the weathers we've already fetched are out of date (i.e. we're no longer inside the first hour of the data)
    // then ask to refresh the predicted weather.
    timer = Timer(const Duration(minutes: 1), () {
      final now = UtcDateTime.timestamp();
      if (!state.isLoading &&
          (state.mostRecentWeatherResult?.weathersByHour?.any(
                (hourly) {
                  return hourly.dateTimesForPredictions.length > 1 && hourly.dateTimesForPredictions[1].isBefore(now);
                },
              ) ==
              true)) {
        add(const RefreshPredictedWeather(config: null, forceRefreshCache: false));
      }
    });
    on<RefreshPredictedWeather>(
      (event, emit) async {
        // Tell the user we're now loading
        emit(WeatherPredictState(
          config: state.config,
          isLoading: true,
          mostRecentWeatherResult: state.mostRecentWeatherResult,
        ));

        final config = event.config ?? state.config;

        print("${DateTime.timestamp()} start fetching weather");
        final weathersFuture = Future.wait(
          config.legend.map(
            (legendElem) => weather.getPredictedWeather(
              settings.settings.backend,
              legendElem.location.coordinate,
              nextHours: config.hoursToLookAhead + 7 /* TODO tune this */,
              forceRefreshCache: event.forceRefreshCache,
            ),
          ),
        );
        await weathersFuture.then((weathersAndStatus) {
          final weathers = <HourlyPredictedWeather>[];
          bool missingWeathers = false;
          bool maybeStale = false;
          List<String> errors = [];
          for (final weatherAndStatus in weathersAndStatus) {
            if (weatherAndStatus.isStale) {
              maybeStale = true;
            }
            if (weatherAndStatus.weather == null) {
              missingWeathers = true;
            } else {
              weathers.add(weatherAndStatus.weather!);
            }
            if (weatherAndStatus.errorWhenFetching != null) {
              errors.add(weatherAndStatus.errorWhenFetching!);
            } else if (weatherAndStatus.weather == null) {
              errors.add("Failed to retrieve weather");
            }
          }
          final error = errors.isEmpty ? null : errors.join(", ");

          if (missingWeathers) {
            emit(
              WeatherPredictState(
                config: config,
                isLoading: false,
                mostRecentWeatherResult: WeatherInsightsResult(
                  weathersByHour: null,
                  weatherMayBeStale: maybeStale,
                  insights: null,
                  error: error,
                ),
              ),
            );
          } else {
            print("${DateTime.timestamp()} computing insights");
            final insights = WeatherInsights.fromAnalysis(
              weathers,
              config.insightConfig,
              maxLookahead: config.hoursToLookAhead,
            );
            print("${DateTime.timestamp()} emitting");
            emit(
              WeatherPredictState(
                config: config,
                isLoading: false,
                mostRecentWeatherResult: WeatherInsightsResult(
                  weathersByHour: weathers,
                  weatherMayBeStale: maybeStale,
                  insights: insights,
                  error: error,
                ),
              ),
            );
          }
        }).onError((e, s) async {
          print("error $e $s");
          emit(
            WeatherPredictState(
              config: config,
              isLoading: false,
              mostRecentWeatherResult: WeatherInsightsResult(
                weathersByHour: null,
                weatherMayBeStale: false,
                insights: null,
                error: e?.toString(),
              ),
            ),
          );
        });
      },
      transformer: restartable(),
    );
  }

  late final Timer timer;
}
