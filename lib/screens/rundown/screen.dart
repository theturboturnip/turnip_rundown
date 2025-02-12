import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:turnip_rundown/data.dart';
import 'package:turnip_rundown/data/geo/repository.dart';
import 'package:turnip_rundown/data/settings/repository.dart';
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
          )..add(const RefreshCurrentCoordinate()),
        ),
        BlocProvider(
          create: (context) => WeatherPredictBloc(
            RepositoryProvider.of<WeatherRepository>(context),
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
                          ),
                        );
                    return BlocBuilder<WeatherPredictBloc, WeatherPredictState>(
                      builder: (context, weatherState) {
                        final DateTime utcHourInLocalTime = DateTime.timestamp()
                            .copyWith(
                              minute: 0,
                              second: 0,
                              millisecond: 0,
                              microsecond: 0,
                            )
                            .toLocal();
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
                            context.read<WeatherPredictBloc>().add(const RefreshPredictedWeather(config: null));
                          },
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  ..._buildWeatherSummary(
                                    context,
                                    hoursLookaheadState,
                                    weatherState,
                                    settings,
                                    dateTimesForEachHour,
                                  ),
                                  ..._buildWeatherInsights(
                                    context,
                                    weatherState,
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
                                    weatherState,
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
    WeatherPredictState weather,
    Settings settings,
    List<DateTime> dateTimesForEachHour,
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
              final minString = (weather is SuccessfulWeatherPrediction) ? weather.insights.minTempAt?.$1.valueAs(unit).toStringAsFixed(1) : null;
              final maxString = (weather is SuccessfulWeatherPrediction) ? weather.insights.maxTempAt?.$1.valueAs(unit).toStringAsFixed(1) : null;
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
                    ? "until ${jmLocalTime(hoursLookaheadState.lockedUtcLookaheadTo!)}"
                    : _renderTimeRange(
                        (0, currentNumLookaheadHours - 1),
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
    WeatherPredictState state,
    Settings settings, {
    required List<DateTime> dateTimesForEachHour,
    required List<DateTime> dateTimesForPriorHours,
  }) {
    return [
      if (state is FailedWeatherPrediction) Text("Cannot retrieve weather: ${state.error}"),
      if (state is SuccessfulWeatherPrediction && state.weathers.isEmpty) const Text("No locations selected!"),
      if (state is SuccessfulWeatherPrediction && state.weathers.isNotEmpty) ...[
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
            state.weathers.map((weather) => weather.dryBulbTemp),
            settings.temperatureUnit.displayUnits().first,
            dateTimesForEachHour,
            defaultMin: const Data(5, Temp.celsius),
            baseline: const Data(15, Temp.celsius),
            defaultMax: const Data(25, Temp.celsius),
            hoursLookedAhead: state.config.hoursToLookAhead,
            otherUnit: (settings.temperatureUnit == TempDisplay.both ? Temp.farenheit : null),
          ),
        if (settings.weatherConfig.useEstimatedWetBulbTemp)
          chartOf(
            context,
            "Wet Bulb Globe Temperature (est.)",
            state.weathers.map((weather) => weather.estimatedWetBulbGlobeTemp),
            settings.temperatureUnit.displayUnits().first,
            dateTimesForEachHour,
            defaultMin: const Data(5, Temp.celsius),
            baseline: const Data(15, Temp.celsius),
            defaultMax: const Data(25, Temp.celsius),
            hoursLookedAhead: state.config.hoursToLookAhead,
            otherUnit: (settings.temperatureUnit == TempDisplay.both ? Temp.farenheit : null),
          ),
        chartOf(
          context,
          "Humidity",
          state.weathers.map((weather) => weather.relHumidity),
          Percent.outOf100,
          dateTimesForEachHour,
          defaultMin: const Data(0, Percent.outOf100),
          defaultMax: const Data(100, Percent.outOf100),
          hoursLookedAhead: state.config.hoursToLookAhead,
        ),
        chartOf(
          context,
          "Wind Speed",
          state.weathers.map((weather) => weather.windspeed),
          Speed.milesPerHour,
          dateTimesForEachHour,
          defaultMin: const Data(0, Speed.milesPerHour),
          defaultMax: const Data(10, Speed.milesPerHour),
          hoursLookedAhead: state.config.hoursToLookAhead,
        ),
        if (!state.weathers.any((weather) => weather.directRadiation == null))
          chartOf(
            context,
            "Direct Radiation",
            state.weathers.map((weather) => weather.directRadiation!),
            SolarRadiation.wPerM2,
            dateTimesForEachHour,
            defaultMin: const Data(0, SolarRadiation.wPerM2),
            defaultMax: const Data(1000, SolarRadiation.wPerM2),
            hoursLookedAhead: state.config.hoursToLookAhead,
          ),
        if (!state.weathers.any((weather) => weather.cloudCover == null))
          chartOf(
            context,
            "Cloud Cover",
            state.weathers.map((weather) => weather.cloudCover!),
            Percent.outOf100,
            dateTimesForEachHour,
            defaultMin: const Data(0, Percent.outOf100),
            defaultMax: const Data(100, Percent.outOf100),
            hoursLookedAhead: state.config.hoursToLookAhead,
          ),
        chartOf(
          context,
          "Precipitation Chance",
          state.weathers.map((weather) => weather.precipitationProb),
          Percent.outOf100,
          dateTimesForEachHour,
          defaultMin: const Data(0, Percent.outOf100),
          defaultMax: const Data(100, Percent.outOf100),
          hoursLookedAhead: state.config.hoursToLookAhead,
        ),
        chartOf(
          context,
          "Precipitation",
          state.weathers.map((weather) => weather.precipitation),
          settings.rainfallUnit,
          dateTimesForEachHour,
          defaultMin: const Data(0, Length.mm),
          defaultMax: const Data(10, Length.mm),
          hoursLookedAhead: state.config.hoursToLookAhead,
        ),
        chartOf(
          context,
          "Snowfall",
          state.weathers.map((weather) => weather.snowfall),
          settings.rainfallUnit, // TODO
          dateTimesForEachHour,
          defaultMin: const Data(0, Length.mm),
          defaultMax: const Data(10, Length.mm),
          hoursLookedAhead: state.config.hoursToLookAhead,
        ),
        chartOf(
          context,
          "Precipitation (Last 24hrs)",
          state.weathers.map((weather) => weather.precipitationUpToNow),
          settings.rainfallUnit,
          dateTimesForPriorHours,
          defaultMin: const Data(0, Length.mm),
          defaultMax: const Data(10, Length.mm),
          numDataPoints: state.weathers.first.precipitationUpToNow.length,
          hoursLookedAhead: state.weathers.first.precipitationUpToNow.length,
        ),
      ]
    ];
  }

  String _renderTimeRange(
    (int, int) range,
    List<DateTime> dateTimesForEachHour, {
    required bool allowBareUntil,
    int? endOfRange,
  }) {
    // The range should end at the end of hour = the start of the *next* hour
    // e.g. (1, 2) is the two-hour range for (the hour starting at 1) and (the hour starting at 2)
    // therefore is actually 1AM-3AM
    if (range.$1 == 0) {
      if (allowBareUntil) {
        return "until ${jmLocalTime(dateTimesForEachHour[range.$2 + 1])}";
      } else {
        return "from now to ${jmLocalTime(dateTimesForEachHour[range.$2 + 1])}";
      }
    }
    if (range.$2 + 1 == endOfRange) {
      return "from ${jmLocalTime(dateTimesForEachHour[range.$1])}";
    }
    return "${jmLocalTime(dateTimesForEachHour[range.$1])}-${jmLocalTime(dateTimesForEachHour[range.$2 + 1])}";
  }

  String _renderActiveHours(
    ActiveHours hours,
    List<DateTime> dateTimesForEachHour,
    int hoursLookedAhead,
  ) {
    if (hours.asRanges.length == 1) {
      return _renderTimeRange(
        hours.asRanges.first,
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
              range,
              dateTimesForEachHour,
              endOfRange: hoursLookedAhead,
              allowBareUntil: false,
            ),
          )
          .join(", ");
    }
  }

  List<Widget> _buildWeatherWarningInsight<TWarning>(
    Iterable<Map<TWarning, ActiveHours>> listOfMappingOfWarningToHoursForEachLocation,
    Map<TWarning, (String, IconData)> nameOfWarning,
    List<String> listOfLocations,
    List<DateTime> dateTimesForEachHour,
    int hoursLookedAhead,
  ) {
    // if there are no warnings that apply for any hours in any location, return null.
    // if there is exactly one warning that applies for any hours in exactly one location, show a simple warning
    //  - e.g. "humid between x-y", optionally appending location if total locations != 1
    // if there is exactly one warning

    final groupedByWarning = <TWarning, Map<int, ActiveHours>>{};
    for (final (index, map) in listOfMappingOfWarningToHoursForEachLocation.indexed) {
      for (final entry in map.entries) {
        if (entry.value.isNotEmpty) {
          groupedByWarning.putIfAbsent(entry.key, () => <int, ActiveHours>{});
          groupedByWarning[entry.key]![index] = entry.value;
        }
      }
    }

    return groupedByWarning.entries
        .map((entry) {
          final warning = nameOfWarning[entry.key]!.$1;
          final warningIcon = Icon(nameOfWarning[entry.key]!.$2);
          return entry.value.entries.map((entry) {
            final locationIndex = entry.key;
            final locationHours = entry.value;
            var title = "$warning ${listOfLocations.length > 1 ? "at ${listOfLocations[locationIndex]} " : ""}";
            var subtitle = _renderActiveHours(
              locationHours,
              dateTimesForEachHour,
              hoursLookedAhead,
            );
            return ListTile(leading: warningIcon, title: Text(title), subtitle: Text(subtitle));
          });
        })
        .flattened
        .toList();
  }

  static const insightTypeMap = {
    InsightType.sprinkles: ("Sprinkles?", Symbols.sprinkler),
    InsightType.lightRain: ("Light rain", Symbols.rainy_light),
    InsightType.mediumRain: ("Medium rain", Symbols.rainy_heavy),
    InsightType.heavyRain: ("Heavy rain", Symbols.rainy_heavy),
    InsightType.slippery: ("Slippery", Symbols.do_not_step),
    InsightType.sweaty: ("Sweaty", Icons.thermostat),
    InsightType.uncomfortablyHumid: ("Uncomfortably humid", Symbols.humidity_mid),
    // InsightType.coolMist: ("Misty", Symbols.mist),
    InsightType.boiling: ("Boiling hot", Symbols.emergency_heat),
    InsightType.freezing: ("Freezing cold", Icons.severe_cold),
    InsightType.sunny: ("Sunny", Icons.brightness_high),
    InsightType.breezy: ("Breezy", Icons.air),
    InsightType.windy: ("Windy", Icons.air),
    InsightType.galey: ("Gale-y", Icons.storm),
    InsightType.snow: ("Snow", Symbols.weather_snowy),
  };

  List<Widget> _buildWeatherInsights(
    BuildContext context,
    WeatherPredictState state,
    Settings settings,
    List<DateTime> dateTimesForEachHour,
  ) {
    if (state is SuccessfulWeatherPrediction) {
      final listOfLocations = state.config.legend.map((legendElem) => legendElem.isYourCoordinate ? "your location" : legendElem.location.name).toList();
      assert(insightTypeMap.keys.toSet().containsAll(InsightType.values));
      return [
        ..._buildWeatherWarningInsight(
          state.insights.insightsByLocation,
          insightTypeMap,
          listOfLocations,
          dateTimesForEachHour,
          state.config.hoursToLookAhead,
        ),
      ].whereType<Widget>().toList();
    } else {
      return [];
    }
  }

  Widget chartOf<TUnit extends Unit<TUnit>>(
    BuildContext context,
    String title,
    Iterable<DataSeries<TUnit>> datas,
    TUnit asUnit,
    List<DateTime> dateTimesForEachHour, {
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

    numDataPoints ??= (hoursLookedAhead >= 12) ? 24 : 12;

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
                      jmLocalTime(
                        dateTimesForEachHour[hour].add(
                          Duration(
                            seconds: (3600 * remainder).round(),
                          ),
                        ),
                      ),
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
                final dateTimeForPoint = jmLocalTime(
                  dateTimesForEachHour[hour].add(
                    Duration(
                      seconds: (3600 * remainder).round(),
                    ),
                  ),
                );

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
