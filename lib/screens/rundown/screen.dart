import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sorted/sorted.dart';
import 'package:turnip_rundown/data.dart';
import 'package:turnip_rundown/data/geo/repository.dart';
import 'package:turnip_rundown/data/settings/repository.dart';
import 'package:turnip_rundown/data/weather_data_bank_repository.dart';
import 'package:turnip_rundown/screens/rundown/hours_lookahead_bloc.dart';
import 'package:turnip_rundown/screens/rundown/location_list_bloc.dart';
import 'package:turnip_rundown/screens/rundown/location_suggest_bloc.dart';
import 'package:turnip_rundown/screens/rundown/weather_prediction_bloc.dart';
import 'package:turnip_rundown/screens/settings/bloc.dart';
import 'package:turnip_rundown/util.dart';

Color nthWeatherResultColor(int index) {
  const colors = [
    Colors.blue,
    Colors.orange,
    Colors.red,
    Colors.green,
    Colors.purple,
  ];

  final baseColor = colors[index % colors.length];
  // take shade[]
  final int offset = 400 + (index ~/ colors.length) * 400;
  if (offset > 900) {
    throw "too many nth weather colors!";
  }
  return baseColor[offset]!;
}

class InsightWidget extends StatelessWidget {
  final Icon icon;
  final String title;
  final String subtitle;
  final UtcDateTime startTimeUtc;

  const InsightWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.startTimeUtc,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon,
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class RundownScreen extends StatelessWidget {
  const RundownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      // Create two blocs and glue them together:
      // the 'LocationListBloc' which gathers locations to generate a rundown for,
      // the 'HoursLookaheadBloc' which determines how many hours forward to look,
      // and the 'WeatherPredictBloc' which re-predicts the weather based on state changes from the LocationListBloc
      providers: [
        BlocProvider(
          create: (context) => LocationListBloc(
            RepositoryProvider.of<CurrentCoordinateRepository>(context),
            RepositoryProvider.of<SettingsRepository>(context),
          )..add(const RefreshCurrentCoordinate()),
        ),
        BlocProvider(
          create: (context) => WeatherPredictBloc(
            RepositoryProvider.of<SettingsRepository>(context),
            RepositoryProvider.of<WeatherDataBankRepository>(context),
          ),
        ),
        BlocProvider(
          create: (context) => HoursLookaheadBloc(
            RepositoryProvider.of<SettingsRepository>(context),
          )..add(const CheckLockedLookaheadEvent()),
        ),
      ],
      child: Scaffold(
        body: BlocBuilder<LocationListBloc, LocationListState>(
          builder: (context, locationState) {
            return BlocBuilder<SettingsBloc, Settings>(
              builder: (context, settings) {
                return BlocBuilder<HoursLookaheadBloc, HoursLookaheadState>(
                  builder: (context, hoursLookaheadState) {
                    // Whenever the LocationListBloc or the settings change, refresh the predicted weather based on that change
                    context.read<WeatherPredictBloc>().add(
                          RefreshPredictedWeather(
                            config: WeatherPredictConfig(
                              legend: locationState.legend,
                              hoursToLookAhead: settings.wakingHours.numHoursToLookahead(hoursLookaheadState.lockedUtcLookaheadTo),
                              insightConfig: settings.weatherConfig,
                            ),
                            forceRefreshCache: false,
                          ),
                        );
                    return BlocBuilder<WeatherPredictBloc, WeatherPredictState>(
                      builder: (context, weatherState) {
                        final predictConfig = weatherState.config;
                        final insightResults = weatherState.mostRecentWeatherResult ??
                            const WeatherInsightsResult(
                              weathersByHour: null,
                              weatherMayBeStale: false,
                              insights: null,
                              error: null,
                            );
                        final LocalDateTime utcHourInLocalTime = LocalDateTime(
                          DateTime.timestamp()
                              .copyWith(
                                minute: 0,
                                second: 0,
                                millisecond: 0,
                                microsecond: 0,
                              )
                              .toLocal(),
                        );
                        final dateTimesForEachHour = List.generate(
                          24,
                          (index) => utcHourInLocalTime.add(Duration(hours: index)),
                        );
                        final dateTimesForPriorHours = List.generate(
                          24,
                          (index) => utcHourInLocalTime.subtract(Duration(hours: 24 - index)),
                        );

                        return RefreshIndicator(
                          onRefresh: () async {
                            context.read<LocationListBloc>().add(const RefreshCurrentCoordinate());
                            context.read<HoursLookaheadBloc>().add(const CheckLockedLookaheadEvent());
                            context.read<WeatherPredictBloc>().add(const RefreshPredictedWeather(config: null, forceRefreshCache: true));
                          },
                          child: SingleChildScrollView(
                            // Ensure the refresh indicator can always be used,
                            // even if there isn't enough content to scroll
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  ..._buildWeatherSummary(
                                    context,
                                    hoursLookaheadState,
                                    insightResults,
                                    settings,
                                    dateTimesForEachHour,
                                  ),
                                  if (weatherState.isLoading)
                                    const LinearProgressIndicator(
                                      value: null,
                                      minHeight: 4,
                                    ),
                                  if (!weatherState.isLoading)
                                    const SizedBox(
                                      height: 4,
                                    ),
                                  ..._buildWeatherInsights(
                                    context,
                                    predictConfig,
                                    insightResults,
                                    settings,
                                    dateTimesForEachHour,
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: const BoxDecoration(
                                      border: Border.symmetric(horizontal: BorderSide()),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: _buildLocationsDisplay(context, locationState),
                                    ),
                                  ),
                                  ..._buildWeatherGraphs(
                                    context,
                                    predictConfig,
                                    insightResults,
                                    settings,
                                    dateTimesForEachHour: dateTimesForEachHour,
                                    dateTimesForPriorHours: dateTimesForPriorHours,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildWeatherSummary(
    BuildContext context,
    HoursLookaheadState hoursLookaheadState,
    WeatherInsightsResult insightsResult,
    Settings settings,
    List<LocalDateTime> dateTimesForEachHour,
  ) {
    final currentNumLookaheadHours = settings.wakingHours.numHoursToLookahead(hoursLookaheadState.lockedUtcLookaheadTo);
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: 40.0,
          children: settings.temperatureUnit.displayUnits().map(
            (unit) {
              final minString = insightsResult.insights?.minTemp?.valueAs(unit).toStringAsFixed(1);
              final maxString = insightsResult.insights?.maxTemp?.valueAs(unit).toStringAsFixed(1);
              return Text(
                "${minString ?? "..."}–${maxString ?? "..."}${unit.display}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50),
              );
            },
          ).toList(),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              icon: Icon((hoursLookaheadState.decrementWillResultInReset) ? Icons.replay : Icons.remove),
              color: hoursLookaheadState.lockedUtcLookaheadTo == null ? Colors.grey : Colors.grey[700],
              onPressed: () {
                context.read<HoursLookaheadBloc>().add(
                      DecrementLockedLookaheadEvent(
                        hour0InLocalTime: dateTimesForEachHour[0],
                        currentNumLookaheadHours: currentNumLookaheadHours,
                      ),
                    );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                (hoursLookaheadState.lockedUtcLookaheadTo != null)
                    ? "until ${hoursLookaheadState.lockedUtcLookaheadTo!.toLocal().jmFormat()}"
                    : _renderTimeRange(
                        (0, currentNumLookaheadHours),
                        dateTimesForEachHour,
                        allowBareUntil: true,
                      ),
                style: const TextStyle(fontWeight: FontWeight.bold),
                // The plan:
                // have a button which when pressed triggers an action IncrementPlannedHoursLookedAhead.
                // if the weatherConfigState indicates the hoursLookedAhead is locked, have a button which when pressed DecrementPlannedHoursLookedAhead
                // which may decrement it past now, in which case it resets and is not locked.
                // the bloc has a timer which periodically triggers CheckLockedPlannedHoursLookedAhead
                // which compares the current time to the locked time and resets to not-locked if current time > locked time.
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              color: hoursLookaheadState.lockedUtcLookaheadTo == null ? Colors.grey : Colors.grey[700],
              onPressed: () {
                context.read<HoursLookaheadBloc>().add(
                      IncrementLockedLookaheadEvent(
                        hour0InLocalTime: dateTimesForEachHour[0],
                        currentNumLookaheadHours: currentNumLookaheadHours,
                      ),
                    );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<WeatherPredictBloc>().add(
                      const RefreshPredictedWeather(
                        config: null,
                        forceRefreshCache: true,
                      ),
                    );
              },
            )
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildLocationsDisplay(BuildContext context, LocationListState state) {
    String formattedCurrentCoordinate;
    if (state.currentCoordinateError != null) {
      formattedCurrentCoordinate = state.currentCoordinateError!;
    } else if (state.currentCoordinate != null) {
      formattedCurrentCoordinate = state.currentCoordinate!.toString();
    } else {
      formattedCurrentCoordinate = "...";
    }

    final currentCoordinateStyle = TextStyle(decoration: (state.includeCurrentCoordinateInInsights) ? null : TextDecoration.lineThrough);

    // The current coordinate formatted as a location, with a faux address and name
    final currentLocation = ListTile(
      leading: IconButton(
        icon: Icon((state.includeCurrentCoordinateInInsights) ? Icons.near_me : Icons.near_me_disabled),
        onPressed: () {
          // Invert the current include-location state
          if (state.includeCurrentCoordinateInInsights) {
            context.read<LocationListBloc>().add(const MarkCurrentCoordinateAsExcluded());
          } else {
            context.read<LocationListBloc>().add(const MarkCurrentCoordinateAsIncluded());
          }
        },
      ),
      title: Text("Your Location", style: currentCoordinateStyle),
      subtitle: Text(formattedCurrentCoordinate, style: currentCoordinateStyle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<LocationListBloc>().add(const RefreshCurrentCoordinate());
            },
          ),
          if (!kIsWeb && (Platform.isAndroid || Platform.isWindows))
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                RepositoryProvider.of<CurrentCoordinateRepository>(context).openExternalSettings();
              },
            ),
          Container(
            width: 20,
            height: 20,
            color: state.includeCurrentCoordinateInInsights && (state.currentCoordinate != null) ? nthWeatherResultColor(0) : Colors.transparent,
          ),
        ],
      ),
    );

    final otherLocations = state.otherNamedLocations.mapIndexed((index, namedLocation) {
      return ListTile(
        leading: IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () {
            context.read<LocationListBloc>().add(RemoveOtherLocation(index: index));
          },
        ),
        title: Text(namedLocation.name),
        subtitle: Text(namedLocation.address + "\n" + namedLocation.coordinate.roundedTo(2, elevationDp: 0).toString()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              color: nthWeatherResultColor(index + (state.includeCurrentCoordinateInInsights && (state.currentCoordinate != null) ? 1 : 0)),
            ),
          ],
        ),
      );
    });

    final currentCoordinate = state.currentCoordinate;

    final newLocationSearch = IconButton(
      icon: const Icon(Icons.add),
      onPressed: () async {
        final locationToAdd = await showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              child: BlocProvider(
                create: (context) => LocationSuggestBloc(RepositoryProvider.of<GeocoderRepository>(context)),
                child: BlocBuilder<LocationSuggestBloc, LocationSuggestState>(
                  builder: (context, state) {
                    final suggestions = state.suggested
                            ?.map(
                              (namedLocation) => ListTile(
                                title: Text(namedLocation.name),
                                subtitle: Text(namedLocation.address + "\n" + namedLocation.coordinate.roundedTo(2, elevationDp: 0).toString()),
                                trailing: const Icon(Icons.add),
                                onTap: () {
                                  Navigator.of(context).pop(namedLocation);
                                },
                              ),
                            )
                            .toList() ??
                        [];
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            key: const ValueKey("search"),
                            onChanged: (newQuery) => context.read<LocationSuggestBloc>().add(
                                  UpdateLocationQuery(
                                    newQuery: newQuery,
                                    near: currentCoordinate,
                                  ),
                                ),
                            decoration: const InputDecoration(
                              hintText: "Search for a new location...",
                              suffixIcon: Icon(Icons.search),
                              counterText: '',
                            ),
                            autofocus: true,
                          ),
                          ...suggestions
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
        if (context.mounted && locationToAdd is Location) {
          context.read<LocationListBloc>().add(AppendOtherLocation(otherLocation: locationToAdd));
        }
      },
    );

    return [
      currentLocation,
      ...otherLocations,
      newLocationSearch,
    ];
  }

  List<Widget> _buildWeatherGraphs(
    BuildContext context,
    WeatherPredictConfig config,
    WeatherInsightsResult insightsResult,
    Settings settings, {
    required List<LocalDateTime> dateTimesForEachHour,
    required List<LocalDateTime> dateTimesForPriorHours,
  }) {
    return [
      if (insightsResult.error != null) Text("Cannot retrieve weather: ${insightsResult.error}"),
      if (insightsResult.weathersByHour != null && insightsResult.weathersByHour!.isEmpty) const Text("No locations selected!"),
      if (insightsResult.weathersByHour != null && insightsResult.weathersByHour!.isNotEmpty) ...[
        // Wrap(
        //   crossAxisAlignment: WrapCrossAlignment.center,
        //   spacing: 10.0,
        //   runSpacing: 10.0,
        //   children: state.legend
        //       .mapIndexed(
        //         (index, legendElem) => Chip(
        //           avatar: Container(
        //             width: 10,
        //             height: 10,
        //             padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        //             color: nthWeatherResultColor(index),
        //           ),
        //           label: Text(legendElem.location.name),
        //           backgroundColor: Colors.transparent,
        //         ),
        //         // if (legendElem.isYourCoordinate)
        //         //   Icon(
        //         //     Icons.near_me,
        //         //     size: 15,
        //         //     color: Colors.grey[700]!,
        //         //   ),
        //         // ],
        //       )
        //       .toList(),
        // ),
        if (!settings.weatherConfig.useEstimatedWetBulbTemp)
          chartOf(
            context,
            "Dry Bulb Temperature",
            insightsResult.weathersByHour!.map((weather) => weather.dryBulbTemp),
            settings.temperatureUnit.displayUnits().first,
            dateTimesForEachHour,
            defaultMin: const Data(5, Temp.celsius),
            baseline: const Data(15, Temp.celsius),
            defaultMax: const Data(25, Temp.celsius),
            hoursLookedAhead: config.hoursToLookAhead,
            otherUnit: (settings.temperatureUnit == TempDisplay.both ? Temp.farenheit : null),
          ),
        if (settings.weatherConfig.useEstimatedWetBulbTemp)
          chartOf(
            context,
            "Wet Bulb Globe Temperature (est.)",
            insightsResult.weathersByHour!.map((weather) => weather.estimatedWetBulbGlobeTemp),
            settings.temperatureUnit.displayUnits().first,
            dateTimesForEachHour,
            defaultMin: const Data(5, Temp.celsius),
            baseline: const Data(15, Temp.celsius),
            defaultMax: const Data(25, Temp.celsius),
            hoursLookedAhead: config.hoursToLookAhead,
            otherUnit: (settings.temperatureUnit == TempDisplay.both ? Temp.farenheit : null),
          ),
        chartOf(
          context,
          "Humidity",
          insightsResult.weathersByHour!.map((weather) => weather.relHumidity),
          Percent.outOf100,
          dateTimesForEachHour,
          defaultMin: const Data(0, Percent.outOf100),
          defaultMax: const Data(100, Percent.outOf100),
          hoursLookedAhead: config.hoursToLookAhead,
        ),
        chartOf(
          context,
          "Wind Speed",
          insightsResult.weathersByHour!.map((weather) => weather.windspeed),
          Speed.milesPerHour,
          dateTimesForEachHour,
          defaultMin: const Data(0, Speed.milesPerHour),
          defaultMax: const Data(10, Speed.milesPerHour),
          hoursLookedAhead: config.hoursToLookAhead,
        ),
        if (!insightsResult.weathersByHour!.any((weather) => weather.directRadiation == null))
          chartOf(
            context,
            "Direct Radiation",
            insightsResult.weathersByHour!.map((weather) => weather.directRadiation!),
            SolarRadiation.wPerM2,
            dateTimesForEachHour,
            defaultMin: const Data(0, SolarRadiation.wPerM2),
            defaultMax: const Data(1000, SolarRadiation.wPerM2),
            hoursLookedAhead: config.hoursToLookAhead,
          ),
        if (!insightsResult.weathersByHour!.any((weather) => weather.cloudCover == null))
          chartOf(
            context,
            "Cloud Cover",
            insightsResult.weathersByHour!.map((weather) => weather.cloudCover!),
            Percent.outOf100,
            dateTimesForEachHour,
            defaultMin: const Data(0, Percent.outOf100),
            defaultMax: const Data(100, Percent.outOf100),
            hoursLookedAhead: config.hoursToLookAhead,
          ),
        chartOf(
          context,
          "Precipitation Chance",
          insightsResult.weathersByHour!.map((weather) => weather.precipitationProb),
          Percent.outOf100,
          dateTimesForEachHour,
          defaultMin: const Data(0, Percent.outOf100),
          defaultMax: const Data(100, Percent.outOf100),
          hoursLookedAhead: config.hoursToLookAhead,
        ),
        chartOf(
          context,
          "Precipitation",
          insightsResult.weathersByHour!.map((weather) => weather.precipitation),
          settings.rainfallUnit,
          dateTimesForEachHour,
          defaultMin: const Data(0, Length.mm),
          defaultMax: const Data(10, Length.mm),
          hoursLookedAhead: config.hoursToLookAhead,
        ),
        chartOf(
          context,
          "Snowfall",
          insightsResult.weathersByHour!.map((weather) => weather.snowfall),
          settings.rainfallUnit, // TODO
          dateTimesForEachHour,
          defaultMin: const Data(0, Length.mm),
          defaultMax: const Data(10, Length.mm),
          hoursLookedAhead: config.hoursToLookAhead,
        ),
        chartOf(
          context,
          "Precipitation (Last 24hrs)",
          insightsResult.weathersByHour!.map((weather) => weather.precipitationUpToNow),
          settings.rainfallUnit,
          dateTimesForPriorHours,
          defaultMin: const Data(0, Length.mm),
          defaultMax: const Data(10, Length.mm),
          numDataPoints: insightsResult.weathersByHour!.first.precipitationUpToNow.length,
          hoursLookedAhead: insightsResult.weathersByHour!.first.precipitationUpToNow.length,
        ),
      ]
    ];
  }

  String _renderTimeRange(
    // The first and last hour indices where the condition holds
    (int, int) rangeInclusive,
    List<LocalDateTime> dateTimesForEachHour, {
    required bool allowBareUntil,
    int? endOfRange,
  }) {
    if (rangeInclusive.$1 == 0) {
      if (rangeInclusive.$2 == endOfRange) {
        return "throughout";
      } else if (allowBareUntil) {
        return "until ${dateTimesForEachHour[rangeInclusive.$2].jmFormat()}";
      } else {
        return "from now to ${dateTimesForEachHour[rangeInclusive.$2].jmFormat()}";
      }
    }
    if (rangeInclusive.$2 == endOfRange) {
      return "from ${dateTimesForEachHour[rangeInclusive.$1].jmFormat()}";
    }
    return "${dateTimesForEachHour[rangeInclusive.$1].jmFormat()}-${dateTimesForEachHour[rangeInclusive.$2].jmFormat()}";
  }

  String _renderActiveHours(
    ActiveHours hours,
    List<LocalDateTime> dateTimesForEachHour,
    int hoursLookedAhead,
  ) {
    if (hours.asRanges.length == 1) {
      var range = hours.asRanges.first;
      // _renderTimeRange expects (firstHourWhereConditionHolds, lastHourWhereConditionHolds)
      // The range should end at the end of hour = the start of the *next* hour
      // e.g. (1, 2) is the two-hour range for (the hour starting at 1) and (the hour starting at 2)
      // therefore is actually 1AM-3AM
      range = (range.$1, range.$2 + 1);
      return _renderTimeRange(
        range,
        dateTimesForEachHour,
        endOfRange: hoursLookedAhead,
        allowBareUntil: true,
      );
    } else if (hours.numActiveHours > (hoursLookedAhead / 2)) {
      return "throughout";
    } else {
      return hours.asRanges
          .map(
            (range) => _renderTimeRange(
              // See above
              (range.$1, range.$2 + 1),
              dateTimesForEachHour,
              endOfRange: hoursLookedAhead,
              allowBareUntil: false,
            ),
          )
          .join(", ");
    }
  }

  Iterable<InsightWidget> _buildWeatherWarningInsightForLevel<TLevel>(
    LevelsInsight<TLevel> levels,
    Map<TLevel, (int, String, IconData)> renderInfo,
    List<String> listOfLocations,
    List<LocalDateTime> dateTimesForEachHour,
    int hoursLookedAhead,
    String locationPostfix,
  ) {
    return levels.nonNullLevelRanges().map((range) {
      final levelsForRange = range.$1;
      late final String name;
      if (levelsForRange.length > 3) {
        final dedupedLevels = <TLevel>[];
        for (final (level, _, _) in levelsForRange) {
          if (!dedupedLevels.contains(level)) {
            dedupedLevels.add(level);
          }
        }
        name = dedupedLevels.map((level) => renderInfo[level]!.$2).join(" and ");
      } else {
        name = levelsForRange.map((levelStartEnd) => renderInfo[levelStartEnd.$1]!.$2).join(", then ");
      }

      final title = "$name$locationPostfix";
      String? subtitle = null;
      if (levelsForRange.length > 1) {
        // If this is for the whole range and there are multiple levels, we can convey more information
        switch (levelsForRange.length) {
          case 2:
            // two possibilities here:
            // [(hot, 0, 2), (cold, 3, 4)] i.e. an actual difference
            // or [(breezy, 0, 2), (windy, 3, 4)] i.e. a difference removed by hysteresis
            // or [(breezy, 0, 2), (breezy, 3, 4)] i.e. a difference removed by hysteresis between two of the same level
            // in the latter case, don't use a different label
            if (levelsForRange[0].$1 != levelsForRange[1].$1) {
              final range = _renderTimeRange(
                (levelsForRange[1].$2, levelsForRange[1].$3),
                dateTimesForEachHour,
                allowBareUntil: true,
                endOfRange: hoursLookedAhead,
              );
              subtitle = "${renderInfo[levelsForRange[1].$1]!.$2} $range";
            }
          case 3:
            {
              // four possibilities
              if (levelsForRange[0].$1 == levelsForRange[1].$1 && levelsForRange[1].$1 != levelsForRange[2].$1) {
                // [a, a, b] with a difference removed by hysteresis
                final range = _renderTimeRange(
                  (levelsForRange[2].$2, levelsForRange[2].$3),
                  dateTimesForEachHour,
                  allowBareUntil: true,
                  endOfRange: hoursLookedAhead,
                );
                subtitle = "${renderInfo[levelsForRange[2].$1]!.$2} $range";
              } else if (levelsForRange[1].$1 == levelsForRange[2].$1) {
                // [a, b, b] with a difference removed by hysteresis
                final range = _renderTimeRange(
                  (levelsForRange[1].$2, levelsForRange[2].$3),
                  dateTimesForEachHour,
                  allowBareUntil: true,
                  endOfRange: hoursLookedAhead,
                );
                subtitle = "${renderInfo[levelsForRange[1].$1]!.$2} $range";
              } else {
                // all levels are distinct
                // [a, b, c]
                final range = _renderTimeRange(
                  (levelsForRange[1].$2, levelsForRange[1].$3),
                  dateTimesForEachHour,
                  allowBareUntil: true,
                  endOfRange: hoursLookedAhead,
                );
                subtitle = "${renderInfo[levelsForRange[1].$1]!.$2} $range";
              }
              // [a, a, a] means use the default subtitle
            }

          default:
            {}
        }
      }
      final nonNullSubtitle = subtitle ??
          _renderTimeRange(
            (range.$2, range.$3),
            dateTimesForEachHour,
            endOfRange: hoursLookedAhead,
            allowBareUntil: true,
          );

      final sortedLevels = range.$1.map((levelStartEnd) => levelStartEnd.$1).toList();
      const DefaultSortingStrategy().sort(sortedLevels, (level, otherLevel) => renderInfo[level]!.$1.compareTo(renderInfo[otherLevel]!.$1));
      final mostSignificantLevel = sortedLevels.last;
      return InsightWidget(
        icon: Icon(renderInfo[mostSignificantLevel]!.$3),
        title: title,
        subtitle: nonNullSubtitle,
        startTimeUtc: dateTimesForEachHour[range.$2].toUtc(),
      );
    });
  }

  List<InsightWidget> _buildWeatherWarningInsight(
    WeatherInsights insights,
    List<String> listOfLocations,
    List<LocalDateTime> dateTimesForEachHour,
    int hoursLookedAhead,
  ) {
    final insightWidgets = <InsightWidget>[];

    final timestamp = UtcDateTime.timestamp();
    final timeRangeEndUtc = dateTimesForEachHour[hoursLookedAhead].toUtc();

    for (final (locationIndex, insight) in insights.insightsByLocation.indexed) {
      final locationPostfix = listOfLocations.length > 1 ? " at ${listOfLocations[locationIndex]}" : "";

      // Add important insights first
      insightWidgets.addAll(
        _buildWeatherWarningInsightForLevel(
          insight.heat,
          heatInsightMap,
          listOfLocations,
          dateTimesForEachHour,
          hoursLookedAhead,
          locationPostfix,
        ),
      );
      insightWidgets.addAll(
        _buildWeatherWarningInsightForLevel(
          insight.precipitation,
          precipInsightMap,
          listOfLocations,
          dateTimesForEachHour,
          hoursLookedAhead,
          locationPostfix,
        ),
      );
      if (insight.uv != null) {
        insightWidgets.addAll(
          _buildWeatherWarningInsightForLevel(
            insight.uv!,
            uvInsightMap,
            listOfLocations,
            dateTimesForEachHour,
            hoursLookedAhead,
            locationPostfix,
          ),
        );
      }

      insightWidgets.addAll(
        _buildWeatherWarningInsightForLevel(
          insight.wind,
          windInsightMap,
          listOfLocations,
          dateTimesForEachHour,
          hoursLookedAhead,
          locationPostfix,
        ),
      );

      for (final entry in insight.eventInsights.entries) {
        if (entry.value.isNotEmpty) {
          final (name, icon) = eventInsightTypeMap[entry.key]!;

          var title = "$name$locationPostfix";
          var subtitle = _renderActiveHours(
            entry.value,
            dateTimesForEachHour,
            hoursLookedAhead,
          );
          insightWidgets.add(InsightWidget(
            icon: Icon(icon),
            title: title,
            subtitle: subtitle,
            startTimeUtc: dateTimesForEachHour[entry.value.firstHour!].toUtc(),
          ));
        }
      }

      final sunrise = insight.sunriseSunset?.nextSunrise;
      final sunset = insight.sunriseSunset?.nextSunset;

      if (sunrise?.isBefore(timeRangeEndUtc) == true && sunrise?.isAfter(timestamp) == true) {
        var title = "Sunrise ${listOfLocations.length > 1 ? "at ${listOfLocations[locationIndex]} " : ""}";
        var subtitle = sunrise!.toLocal().jmFormat();
        insightWidgets.add(
          InsightWidget(
            icon: const Icon(Symbols.wb_twilight),
            title: title,
            subtitle: subtitle,
            startTimeUtc: sunrise,
          ),
        );
      }

      if (sunset?.isBefore(timeRangeEndUtc) == true && sunset?.isAfter(timestamp) == true) {
        var title = "Sunset ${listOfLocations.length > 1 ? "at ${listOfLocations[locationIndex]} " : ""}";
        var subtitle = sunset!.toLocal().jmFormat();
        insightWidgets.add(
          InsightWidget(
            icon: const Icon(Symbols.wb_twilight),
            title: title,
            subtitle: subtitle,
            startTimeUtc: sunset,
          ),
        );
      }
    }

    // Use a stable sort to ensure the importance we encoded above still holds
    const MergeSortingStrategy().sort(
      insightWidgets,
      (a, b) => a.startTimeUtc.compareTo(b.startTimeUtc),
    );

    return insightWidgets;
  }

  static const eventInsightTypeMap = {
    EventInsightType.slippery: ("Slippery", Symbols.do_not_step),
    EventInsightType.sweaty: ("Sweaty", Icons.thermostat),
    EventInsightType.uncomfortablyHumid: ("Uncomfortably humid", Symbols.humidity_mid),
    EventInsightType.sunny: ("Sunny", Icons.brightness_high),
    EventInsightType.snow: ("Snow", Symbols.weather_snowy),
  };

  static const heatInsightMap = {
    Heat.freezing: (2, "Freezing", Icons.severe_cold),
    Heat.chilly: (1, "Chilly", Symbols.thermometer_loss),
    Heat.mild: (0, "Mild", Symbols.thermometer),
    Heat.warm: (1, "Warm", Symbols.thermometer_add),
    Heat.hot: (2, "Hot", Symbols.heat),
    Heat.boiling: (3, "Boiling", Symbols.emergency_heat),
  };

  static const windInsightMap = {
    Wind.breezy: (1, "Breezy", Icons.air),
    Wind.windy: (2, "Windy", Icons.air),
    Wind.galey: (3, "Gale-y", Icons.storm),
  };

  static const precipInsightMap = {
    Precipitation.sprinkles: (1, "Sprinkles", Symbols.sprinkler),
    Precipitation.lightRain: (2, "Light rain", Symbols.rainy_light),
    Precipitation.mediumRain: (3, "Medium rain", Symbols.rainy_heavy),
    Precipitation.heavyRain: (4, "Heavy rain", Symbols.rainy_heavy),
  };

  static const uvInsightMap = {
    // UvLevel.low: (1, "Low UV", Symbols.brightness_5),
    UvLevel.moderate: (2, "Moderate UV", Symbols.brightness_5),
    UvLevel.high: (3, "High UV", Symbols.brightness_7),
    UvLevel.veryHigh: (4, "Very High UV", Symbols.brightness_alert),
  };

  List<Widget> _buildWeatherInsights(
    BuildContext context,
    WeatherPredictConfig config,
    WeatherInsightsResult insightsResult,
    Settings settings,
    List<LocalDateTime> dateTimesForEachHour,
  ) {
    late final List<Widget> widgets;
    if (insightsResult.insights != null) {
      final listOfLocations = config.legend.map((legendElem) => legendElem.isYourCoordinate ? "your location" : legendElem.location.name).toList();
      assert(eventInsightTypeMap.keys.toSet().containsAll(EventInsightType.values));

      widgets = _buildWeatherWarningInsight(
        insightsResult.insights!,
        listOfLocations,
        dateTimesForEachHour,
        config.hoursToLookAhead,
      );
    } else {
      widgets = [];
    }

    if (insightsResult.weatherMayBeStale) {
      widgets.insert(
        0,
        const ListTile(
          leading: Icon(Symbols.warning),
          title: Text("Stale Data"),
          subtitle: Text("Warning: data fetched from one or more sources may be out of date. Try refreshing the app."),
        ),
      );
    }

    return widgets;
  }

  Widget chartOf<TUnit extends Unit<TUnit>>(
    BuildContext context,
    String title,
    Iterable<DataSeries<TUnit>> datas,
    TUnit asUnit,
    List<LocalDateTime> dateTimesForEachHour, {
    required int hoursLookedAhead,
    int? numDataPoints,
    required Data<TUnit> defaultMin,
    required Data<TUnit> defaultMax,
    Data<TUnit>? baseline,
    TUnit? otherUnit,
  }) {
    List<List<double>> dataPointss = datas.map((series) => series.valuesAs(asUnit).toList()).toList();
    final dataPointsFlat = dataPointss.flattened;
    final (dataMin, dataMax) = dataPointsFlat.isEmpty ? (defaultMin.valueAs(asUnit), defaultMax.valueAs(asUnit)) : dataPointsFlat.minMax as (double, double);
    final overallMin = min(dataMin, defaultMin.valueAs(asUnit));
    final overallMax = max(dataMax, defaultMax.valueAs(asUnit));

    numDataPoints ??= min((hoursLookedAhead >= 12) ? 24 : 12, dataPointss.map((dataPoints) => dataPoints.length).max);

    final usingTwoUnits = (otherUnit != null) && (otherUnit != asUnit);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineBarsData: dataPointss
              .mapIndexed((index, dataPoints) => LineChartBarData(
                    spots: dataPoints.indexed.take(numDataPoints!).map((item) => FlSpot(item.$1.toDouble(), item.$2)).toList(),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    dotData: const FlDotData(show: false),
                    color: nthWeatherResultColor(index),
                  ))
              .toList(),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(
              axisNameWidget: Text(title + (usingTwoUnits ? "" : " (${asUnit.display})")),
              axisNameSize: 20,
              sideTitles: const SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              // axisNameWidget: usingTwoUnits ? Text(asUnit.display) : null,
              sideTitles: SideTitles(
                reservedSize: 55,
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      meta.formattedValue + (usingTwoUnits ? asUnit.display : ""),
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(
              // axisNameWidget: usingTwoUnits ? Text(otherUnit.display) : null,
              sideTitles: SideTitles(
                reservedSize: 55,
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      usingTwoUnits ? "${Data(value, asUnit).valueAs(otherUnit).toStringAsFixed(0)}${otherUnit.display}" : meta.formattedValue,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final hour = value.floor();
                  final remainder = value - hour;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      dateTimesForEachHour[hour]
                          .add(
                            Duration(
                              seconds: (3600 * remainder).round(),
                            ),
                          )
                          .jmFormat(),
                    ),
                  );
                },
                // Make sure the time text doesn't overlap
                interval: (MediaQuery.of(context).size.width < 600 && numDataPoints > 12) ? 8 : 4,
              ),
            ),
          ),
          minY: (overallMin / 5).floorToDouble() * 5,
          maxY: (overallMax / 5).ceilToDouble() * 5,
          baselineY: baseline?.valueAs(asUnit).roundToDouble(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((spot) {
                final textStyle = TextStyle(
                  color: spot.bar.gradient?.colors.first ?? spot.bar.color ?? Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                );

                final hour = spot.x.floor();
                final remainder = spot.x - hour;
                final dateTimeForPoint = dateTimesForEachHour[hour]
                    .add(
                      Duration(
                        seconds: (3600 * remainder).round(),
                      ),
                    )
                    .jmFormat();

                return LineTooltipItem(
                  "${spot.barIndex == 0 ? "$dateTimeForPoint\n" : ""}"
                  "${spot.y.toStringAsFixed(1)}${asUnit.display}"
                  "${usingTwoUnits ? "/${Data(spot.y, asUnit).valueAs(otherUnit).toStringAsFixed(1)}${otherUnit.display}" : ""}",
                  textStyle,
                );
              }).toList(),
            ),
          ),
          rangeAnnotations: RangeAnnotations(verticalRangeAnnotations: [
            if (hoursLookedAhead != numDataPoints)
              VerticalRangeAnnotation(
                x1: hoursLookedAhead.toDouble(),
                x2: numDataPoints.toDouble() - 1,
                color: Colors.grey.withOpacity(0.5),
              ),
          ]),
          gridData: const FlGridData(
            drawHorizontalLine: true,
            horizontalInterval: null,
            drawVerticalLine: true,
            verticalInterval: 1,
          ),
        ),
      ),
    );
  }
}

class GrabbingWidget extends StatelessWidget {
  const GrabbingWidget({super.key, required this.legend});

  final List<LegendElement> legend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20), bottom: Radius.circular(0)),
        boxShadow: [
          BoxShadow(blurRadius: 25, color: Colors.black.withOpacity(0.2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 20, bottom: 10),
            width: 100,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          Text(legend.map((legendElem) => legendElem.location.name).join(", ")),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
