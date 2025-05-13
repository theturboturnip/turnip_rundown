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
  final GlobalKey? jumpTo;

  const InsightWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.startTimeUtc,
    required this.jumpTo,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon,
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: (jumpTo == null)
          ? null
          : () {
              final ctx = jumpTo?.currentContext;
              if (ctx != null) {
                Scrollable.ensureVisible(
                  ctx,
                  alignment: 0.5,
                  alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
                  duration: const Duration(milliseconds: 200),
                );
              }
            },
    );
  }
}

class DataGraph<TUnit extends Unit<TUnit>> extends StatelessWidget {
  const DataGraph({
    super.key,
    required this.title,
    required this.datas,
    required this.asUnit,
    this.secondUnit,
    required this.dateTimesForEachHour,
    required this.hoursLookedAhead,
    this.fixedNumDataPoints,
    required this.defaultMin,
    required this.defaultMax,
    this.baseline,
  });

  final String title;
  final List<DataSeries<TUnit>> datas;
  final TUnit asUnit;
  final List<LocalDateTime> dateTimesForEachHour;
  final int hoursLookedAhead;
  final int? fixedNumDataPoints;
  final Data<TUnit> defaultMin;
  final Data<TUnit> defaultMax;
  final Data<TUnit>? baseline;
  final TUnit? secondUnit;

  @override
  Widget build(BuildContext context) {
    List<List<double>> dataPointss = datas.map((series) => series.valuesAs(asUnit).toList()).toList();
    final dataPointsFlat = dataPointss.flattened;
    final (dataMin, dataMax) = dataPointsFlat.isEmpty ? (defaultMin.valueAs(asUnit), defaultMax.valueAs(asUnit)) : dataPointsFlat.minMax as (double, double);
    final overallMin = min(dataMin, defaultMin.valueAs(asUnit));
    final overallMax = max(dataMax, defaultMax.valueAs(asUnit));

    final selectedNumDataPoints = fixedNumDataPoints ?? min((hoursLookedAhead >= 12) ? 24 : 12, dataPointss.map((dataPoints) => dataPoints.length).max);

    final secondUnit = this.secondUnit;
    final usingTwoUnits = (secondUnit != null) && (secondUnit != asUnit);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineBarsData: dataPointss
              .mapIndexed(
                (index, dataPoints) => LineChartBarData(
                  spots: dataPoints.indexed
                      .take(selectedNumDataPoints)
                      .map((item) => FlSpot(
                            item.$1.toDouble(),
                            item.$2,
                          ))
                      .toList(),
                  isCurved: true,
                  preventCurveOverShooting: true,
                  dotData: const FlDotData(show: false),
                  color: nthWeatherResultColor(index),
                  curveSmoothness: 0,
                ),
              )
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
                      usingTwoUnits ? "${Data(value, asUnit).valueAs(secondUnit).toStringAsFixed(0)}${secondUnit.display}" : meta.formattedValue,
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
                interval: (MediaQuery.of(context).size.width < 600 && selectedNumDataPoints > 12) ? 8 : 4,
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
                  "${usingTwoUnits ? "/${Data(spot.y, asUnit).valueAs(secondUnit).toStringAsFixed(1)}${secondUnit.display}" : ""}",
                  textStyle,
                );
              }).toList(),
            ),
          ),
          rangeAnnotations: RangeAnnotations(verticalRangeAnnotations: [
            if (hoursLookedAhead != selectedNumDataPoints)
              VerticalRangeAnnotation(
                x1: hoursLookedAhead.toDouble(),
                x2: selectedNumDataPoints.toDouble() - 1,
                color: Colors.grey.withValues(alpha: 0.5),
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

class RundownScreen extends StatelessWidget {
  RundownScreen({super.key});

  final GlobalKey graphTemp = GlobalKey(debugLabel: "graphTemp");
  final GlobalKey graphHumid = GlobalKey(debugLabel: "graphHumid");
  final GlobalKey graphWindSpeed = GlobalKey(debugLabel: "graphWindSpeed");
  final GlobalKey graphSunny = GlobalKey(debugLabel: "graphSunny");
  final GlobalKey graphUv = GlobalKey(debugLabel: "graphUv");
  final GlobalKey graphPrecip = GlobalKey(debugLabel: "graphPrecip");

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
    return settings.temperatureUnit.displayUnits().map((unit) {
          final minString = insightsResult.insights?.minTemp?.valueAs(unit).toStringAsFixed(1);
          final maxString = insightsResult.insights?.maxTemp?.valueAs(unit).toStringAsFixed(1);
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              "${minString ?? "..."}–${maxString ?? "..."}${unit.display}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 50),
            ),
          ) as Widget;
        }).toList() +
        [
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
          DataGraph(
            title: "Dry Bulb Temperature",
            datas: insightsResult.weathersByHour!.map((weather) => weather.dryBulbTemp).toList(),
            asUnit: settings.temperatureUnit.displayUnits().first,
            secondUnit: (settings.temperatureUnit == TempDisplay.both ? Temp.farenheit : null),
            dateTimesForEachHour: dateTimesForEachHour,
            defaultMin: const Data(5, Temp.celsius),
            baseline: const Data(15, Temp.celsius),
            defaultMax: const Data(25, Temp.celsius),
            hoursLookedAhead: config.hoursToLookAhead,
            key: graphTemp,
          ),
        if (settings.weatherConfig.useEstimatedWetBulbTemp)
          DataGraph(
            title: "Wet Bulb Globe Temperature (est.)",
            datas: insightsResult.weathersByHour!.map((weather) => weather.estimatedWetBulbGlobeTemp).toList(),
            asUnit: settings.temperatureUnit.displayUnits().first,
            secondUnit: (settings.temperatureUnit == TempDisplay.both ? Temp.farenheit : null),
            dateTimesForEachHour: dateTimesForEachHour,
            defaultMin: const Data(5, Temp.celsius),
            baseline: const Data(15, Temp.celsius),
            defaultMax: const Data(25, Temp.celsius),
            hoursLookedAhead: config.hoursToLookAhead,
            key: graphTemp,
          ),
        DataGraph(
          title: "Humidity",
          datas: insightsResult.weathersByHour!.map((weather) => weather.relHumidity).toList(),
          asUnit: Percent.outOf100,
          dateTimesForEachHour: dateTimesForEachHour,
          defaultMin: const Data(0, Percent.outOf100),
          defaultMax: const Data(100, Percent.outOf100),
          hoursLookedAhead: config.hoursToLookAhead,
          key: graphHumid,
        ),
        DataGraph(
          title: "Wind Speed",
          datas: insightsResult.weathersByHour!.map((weather) => weather.windspeed).toList(),
          asUnit: Speed.milesPerHour,
          dateTimesForEachHour: dateTimesForEachHour,
          defaultMin: const Data(0, Speed.milesPerHour),
          defaultMax: const Data(10, Speed.milesPerHour),
          hoursLookedAhead: config.hoursToLookAhead,
          key: graphWindSpeed,
        ),
        if (!insightsResult.weathersByHour!.any((weather) => weather.uvIndex == null))
          DataGraph(
            title: "UV Index",
            datas: insightsResult.weathersByHour!.map((weather) => weather.uvIndex!).toList(),
            asUnit: UVIndex.uv,
            dateTimesForEachHour: dateTimesForEachHour,
            defaultMin: const Data(0, UVIndex.uv),
            defaultMax: const Data(9, UVIndex.uv),
            hoursLookedAhead: config.hoursToLookAhead,
            key: graphUv,
          ),
        if (!insightsResult.weathersByHour!.any((weather) => weather.directRadiation == null))
          DataGraph(
            title: "Direct Radiation",
            datas: insightsResult.weathersByHour!.map((weather) => weather.directRadiation!).toList(),
            asUnit: SolarRadiation.wPerM2,
            dateTimesForEachHour: dateTimesForEachHour,
            defaultMin: const Data(0, SolarRadiation.wPerM2),
            defaultMax: const Data(1000, SolarRadiation.wPerM2),
            hoursLookedAhead: config.hoursToLookAhead,
            key: graphSunny,
          ),
        if (!insightsResult.weathersByHour!.any((weather) => weather.cloudCover == null))
          DataGraph(
            title: "Cloud Cover",
            datas: insightsResult.weathersByHour!.map((weather) => weather.cloudCover!).toList(),
            asUnit: Percent.outOf100,
            dateTimesForEachHour: dateTimesForEachHour,
            defaultMin: const Data(0, Percent.outOf100),
            defaultMax: const Data(100, Percent.outOf100),
            hoursLookedAhead: config.hoursToLookAhead,
            key: null,
          ),
        DataGraph(
          title: "Precipitation Chance",
          datas: insightsResult.weathersByHour!.map((weather) => weather.precipitationProb).toList(),
          asUnit: Percent.outOf100,
          dateTimesForEachHour: dateTimesForEachHour,
          defaultMin: const Data(0, Percent.outOf100),
          defaultMax: const Data(100, Percent.outOf100),
          hoursLookedAhead: config.hoursToLookAhead,
          key: graphPrecip,
        ),
        DataGraph(
          title: "Precipitation",
          datas: insightsResult.weathersByHour!.map((weather) => weather.precipitation).toList(),
          asUnit: settings.rainfallUnit,
          dateTimesForEachHour: dateTimesForEachHour,
          defaultMin: const Data(0, Length.mm),
          defaultMax: const Data(10, Length.mm),
          hoursLookedAhead: config.hoursToLookAhead,
          key: null,
        ),
        DataGraph(
          title: "Snowfall",
          datas: insightsResult.weathersByHour!.map((weather) => weather.snowfall).toList(),
          asUnit: settings.rainfallUnit, // TODO
          dateTimesForEachHour: dateTimesForEachHour,
          defaultMin: const Data(0, Length.mm),
          defaultMax: const Data(10, Length.mm),
          hoursLookedAhead: config.hoursToLookAhead,
          key: null,
        ),
        DataGraph(
          title: "Precipitation (Last 24hrs)",
          datas: insightsResult.weathersByHour!.map((weather) => weather.precipitationUpToNow).toList(),
          asUnit: settings.rainfallUnit,
          dateTimesForEachHour: dateTimesForEachHour,
          defaultMin: const Data(0, Length.mm),
          defaultMax: const Data(10, Length.mm),
          fixedNumDataPoints: insightsResult.weathersByHour!.first.precipitationUpToNow.length,
          hoursLookedAhead: insightsResult.weathersByHour!.first.precipitationUpToNow.length,
          key: null,
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

  // Given the LevelsInsight for all locations, either
  // render out the individual non-null ranges in each for each location as separate widgets
  // or combine them all into one widget if they get too complicated.
  // Complexity is measured by two metrics:
  // 1. maxWidgets simply limits the number of widgets.
  //    Screen real estate is limited, don't want a lot of individual widgets cluttrying things.
  // 2. maxUniqueLevelsPerLocationBeforeCombining monitors the individual complexity of each widget.
  //    If we have one super complex widget like (Chilly and Mild and Warm at X) with another (Mild at Y)
  //    that could overload the user.
  //    TODO maybe it's ok for (many) and (one)...
  // TODO want to merge identical things e.g. (Boiling then Warm at London), (Boiling then Warm at Paris)?
  Iterable<InsightWidget> _buildWeatherWarningInsightForLevel<TLevel>(
    List<LevelsInsight<TLevel>> levelsByLocation,
    Map<TLevel, (int, String, IconData)> renderInfo,
    List<String> listOfLocations,
    List<LocalDateTime> dateTimesForEachHour,
    int hoursLookedAhead, {
    int maxWidgets = 2,
    int maxUniqueLevelsPerLocationBeforeCombining = 2,
    required GlobalKey jumpTo,
  }) {
    final uniqueLevelsPerLocation = <int, Set<TLevel>>{};
    final individualWidgetPlansWhenNotCombined = levelsByLocation.indexed
        .map((indexAndInsight) {
          final (index, insight) = indexAndInsight;
          uniqueLevelsPerLocation[index] = <TLevel>{};
          return insight.nonNullLevelRanges().map((t) {
            uniqueLevelsPerLocation[index]!.addAll(t.$1.map((levelRange) => levelRange.$1));
            return (t.$1, t.$2, t.$3, listOfLocations[index]);
          });
        })
        .flattened
        .toList();

    final maxUniqueLevelsPerLocation = uniqueLevelsPerLocation.values.map((levelSet) => levelSet.length).maxOrNull ?? 0;
    if (individualWidgetPlansWhenNotCombined.length <= maxWidgets && maxUniqueLevelsPerLocation <= maxUniqueLevelsPerLocationBeforeCombining) {
      return individualWidgetPlansWhenNotCombined.map((plan) {
        final levelsForRange = plan.$1;
        final location = plan.$4;
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

        final locationPostfix = listOfLocations.length > 1 ? " at $location" : "";

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
                  (levelsForRange[1].$2, levelsForRange[1].$3 + 1),
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
                    (levelsForRange[2].$2, levelsForRange[2].$3 + 1),
                    dateTimesForEachHour,
                    allowBareUntil: true,
                    endOfRange: hoursLookedAhead,
                  );
                  subtitle = "${renderInfo[levelsForRange[2].$1]!.$2} $range";
                } else if (levelsForRange[1].$1 == levelsForRange[2].$1) {
                  // [a, b, b] with a difference removed by hysteresis
                  final range = _renderTimeRange(
                    (levelsForRange[1].$2, levelsForRange[2].$3 + 1),
                    dateTimesForEachHour,
                    allowBareUntil: true,
                    endOfRange: hoursLookedAhead,
                  );
                  subtitle = "${renderInfo[levelsForRange[1].$1]!.$2} $range";
                } else {
                  // all levels are distinct
                  // [a, b, c]
                  final range = _renderTimeRange(
                    (levelsForRange[1].$2, levelsForRange[1].$3 + 1),
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
              (plan.$2, plan.$3 + 1),
              dateTimesForEachHour,
              endOfRange: hoursLookedAhead,
              allowBareUntil: true,
            );

        final sortedLevels = plan.$1.map((levelStartEnd) => levelStartEnd.$1).toList();
        const DefaultSortingStrategy().sort(sortedLevels, (level, otherLevel) => renderInfo[level]!.$1.compareTo(renderInfo[otherLevel]!.$1));
        final mostSignificantLevel = sortedLevels.last;
        return InsightWidget(
          icon: Icon(renderInfo[mostSignificantLevel]!.$3),
          title: title,
          subtitle: nonNullSubtitle,
          startTimeUtc: dateTimesForEachHour[plan.$2].toUtc(),
          jumpTo: jumpTo,
        );
      });
    }

    final combined = CombinedLevelsInsight.combine(levelsByLocation);
    final allRangesToShow = combined.levelRanges.where((range) => range.$1 != {null}).toList();
    late List<(Set<TLevel>, int, int)> combinedRangesToWidget;
    if (allRangesToShow.length > maxWidgets) {
      // Combine everything into one widget
      print("folding $allRangesToShow");
      final allLevels = allRangesToShow.fold(<TLevel>{}, (start, range) => start.union(range.$1));
      combinedRangesToWidget = [
        (
          allLevels,
          allRangesToShow.map((r) => r.$2).min,
          allRangesToShow.map((r) => r.$3).max,
        ),
      ];
    } else {
      // One widget per range
      combinedRangesToWidget = allRangesToShow;
    }

    return combinedRangesToWidget.map((range) {
      final (dedupedLevels, rangeStart, rangeEnd) = range;
      final nonNullLevels = dedupedLevels.whereNot((l) => l == null).toList();
      final String title = nonNullLevels.map((level) => renderInfo[level]!.$2).join(" and ");
      final String subtitle = _renderTimeRange(
        (rangeStart, rangeEnd + 1),
        dateTimesForEachHour,
        endOfRange: hoursLookedAhead,
        allowBareUntil: true,
      );
      const DefaultSortingStrategy().sort(nonNullLevels, (level, otherLevel) => renderInfo[level]!.$1.compareTo(renderInfo[otherLevel]!.$1));
      final mostSignificantLevel = nonNullLevels.last;
      return InsightWidget(
        icon: Icon(renderInfo[mostSignificantLevel]!.$3),
        title: title,
        subtitle: subtitle,
        startTimeUtc: dateTimesForEachHour[rangeStart].toUtc(),
        jumpTo: jumpTo,
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

    // Add important insights first
    insightWidgets.addAll(
      _buildWeatherWarningInsightForLevel(
        insights.insightsByLocation.map((insight) => insight.heat.levels).toList(),
        heatInsightMap,
        listOfLocations,
        dateTimesForEachHour,
        hoursLookedAhead,
        jumpTo: graphTemp,
      ),
    );
    insightWidgets.addAll(
      _buildWeatherWarningInsightForLevel(
        insights.insightsByLocation.map((insight) => insight.precipitation).toList(),
        precipInsightMap,
        listOfLocations,
        dateTimesForEachHour,
        hoursLookedAhead,
        jumpTo: graphPrecip,
      ),
    );
    if (!insights.insightsByLocation.any((insight) => insight.uv == null)) {
      insightWidgets.addAll(
        _buildWeatherWarningInsightForLevel(
          insights.insightsByLocation.map((insight) => insight.uv!).toList(),
          uvInsightMap,
          listOfLocations,
          dateTimesForEachHour,
          hoursLookedAhead,
          maxWidgets: 1,
          jumpTo: graphUv,
        ),
      );
    }

    insightWidgets.addAll(
      _buildWeatherWarningInsightForLevel(
        insights.insightsByLocation.map((insight) => insight.wind).toList(),
        windInsightMap,
        listOfLocations,
        dateTimesForEachHour,
        hoursLookedAhead,
        maxWidgets: 1,
        jumpTo: graphWindSpeed,
      ),
    );

    final eventTypeToKey = {
      EventInsightType.slippery: graphPrecip,
      EventInsightType.snow: graphPrecip,
      EventInsightType.sunny: graphSunny,
      EventInsightType.sweaty: graphHumid,
      EventInsightType.uncomfortablyHumid: graphHumid,
    };
    // Check they're all defined
    assert(!EventInsightType.values.any((eventType) => !eventTypeToKey.containsKey(eventType)));

    // TODO merge sunsets if close

    for (final (locationIndex, insight) in insights.insightsByLocation.indexed) {
      final locationPostfix = listOfLocations.length > 1 ? " at ${listOfLocations[locationIndex]}" : "";

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
            jumpTo: eventTypeToKey[entry.key]!,
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
            jumpTo: null,
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
            jumpTo: null,
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
    UvLevel.moderate: (2, "Mild UV", Symbols.brightness_5),
    UvLevel.high: (3, "High UV", Symbols.brightness_7),
    UvLevel.veryHigh: (4, "Extreme UV", Symbols.brightness_alert),
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
      ).cast<Widget>();
    } else {
      widgets = <Widget>[];
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
