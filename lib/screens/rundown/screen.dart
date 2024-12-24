import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turnip_rundown/data/geo/repository.dart';
import 'package:turnip_rundown/data/location/repository.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/repository.dart';
import 'package:turnip_rundown/screens/rundown/bloc.dart';
import 'package:turnip_rundown/screens/rundown/location_suggest_bloc.dart';

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
      // the 'RundownBloc' TODO RENAME which gathers locations to generate a rundown for,
      // and the 'WeatherPredictBloc' which re-predicts the weather based on state changes from the RundownBloc
      providers: [
        BlocProvider(
          create: (context) => RundownBloc(
            RepositoryProvider.of<LocationRepository>(context),
          )..add(const RefreshCurrentLocation()),
        ),
        BlocProvider(
          create: (context) => WeatherPredictBloc(
            RepositoryProvider.of<WeatherRepository>(context),
          ),
        ),
      ],
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    "Rundown",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              // _buildCurrentWeather(context),
              // Whenever the RundownBloc changes,
              // 1. rebuild the UI
              // 2. refresh the predicted weather based on that change
              BlocListener<RundownBloc, RundownState>(
                listener: (context, state) => context.read<WeatherPredictBloc>().add(
                      RefreshPredictedWeather(coordinates: state.coordinates),
                    ),
                child: BlocBuilder<RundownBloc, RundownState>(
                  builder: (context, state) {
                    return Column(children: _buildLocationsDisplay(context, state));
                  },
                ),
              ),
              BlocBuilder<WeatherPredictBloc, WeatherPredictState>(builder: (context, state) {
                return Column(
                  children: [
                    ..._buildWeatherInsights(context, state),
                    ..._buildWeatherGraphs(context, state),
                  ],
                );
              })
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentWeather(BuildContext context) {
    return const SizedBox(width: 10, height: 10, child: ColoredBox(color: Colors.red));
  }

  List<Widget> _buildLocationsDisplay(BuildContext context, RundownState state) {
    String formattedCurrentLocation;
    if (state.currentLocationError != null) {
      formattedCurrentLocation = state.currentLocationError!;
    } else if (state.currentLocation != null) {
      formattedCurrentLocation = state.currentLocation!.toString();
    } else {
      formattedCurrentLocation = "...";
    }

    final currentLocationStyle = TextStyle(decoration: (state.includeCurrentLocationInInsights) ? null : TextDecoration.lineThrough);

    final currentLocation = ListTile(
      leading: IconButton(
        icon: Icon((state.includeCurrentLocationInInsights) ? Icons.near_me : Icons.near_me_disabled),
        onPressed: () {
          // Invert the current include-location state
          if (state.includeCurrentLocationInInsights) {
            context.read<RundownBloc>().add(const MarkCurrentLocationAsExcluded());
          } else {
            context.read<RundownBloc>().add(const MarkCurrentLocationAsIncluded());
          }
        },
      ),
      title: Text("My Location", style: currentLocationStyle),
      subtitle: Text(formattedCurrentLocation, style: currentLocationStyle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<RundownBloc>().add(const RefreshCurrentLocation());
            },
          ),
          if (!kIsWeb && (Platform.isAndroid || Platform.isWindows))
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                RepositoryProvider.of<LocationRepository>(context).openExternalLocationSettings();
              },
            ),
          Container(
            width: 20,
            height: 20,
            color: state.includeCurrentLocationInInsights ? nthWeatherResultColor(0) : Colors.transparent,
          ),
        ],
      ),

      // if (state.currentLocationError != null) Text("Cannot retrieve location: ${state.currentLocationError}"),
      // if (state.currentLocationError == null && state.currentLocation == null)
      //   const SizedBox(
      //     width: 100,
      //     child: LinearProgressIndicator(),
      //   ),
      // if (state.currentLocation != null) Text("Location: ${state.currentLocation!.lat} ${state.currentLocation!.long} ${state.currentLocation!.elevation ?? '??'}m"),

      // Checkbox(value: state.includeCurrentLocationInInsights, onChanged: (newValue) {
      //   switch (newValue) {
      //     case true:
      //       context.read<RundownBloc>().add(const MarkCurrentLocationAsIncluded());
      //       break;
      //     case false:
      //       context.read<RundownBloc>().add(const MarkCurrentLocationAsExcluded());
      //       break;
      //     default:
      //       break;
      //   }
      // },),
    );

    final otherLocations = state.otherNamedLocations.mapIndexed((index, namedLocation) {
      return ListTile(
        leading: IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () {
            context.read<RundownBloc>().add(RemoveOtherLocation(index: index));
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
              color: nthWeatherResultColor(index + (state.includeCurrentLocationInInsights ? 1 : 0)),
            ),
          ],
        ),
      );
    });

    // final newLocationSearch = SearchAnchor(
    //   builder: (BuildContext context, SearchController controller) {
    //     return BlocProvider.value(
    //       value: BlocProvider.of<RundownBloc>(context),
    //       child: SearchBar(
    //         controller: controller,
    //         hintText: "Add a location...",
    //         padding: const WidgetStatePropertyAll<EdgeInsets>(
    //           EdgeInsets.symmetric(horizontal: 16.0),
    //         ),
    //         trailing: const [
    //           Icon(Icons.search),
    //         ],
    //         textInputAction: TextInputAction.search,
    //         onTap: () {
    //           controller.openView();
    //         },
    //         onChanged: (newQuery) {
    //           controller.openView();
    //         },
    //       ),
    //     );
    //   },
    //   suggestionsBuilder: (context, controller) async {
    //     final geocoder = RepositoryProvider.of<GeocoderRepository>(context);
    //     final suggested = await geocoder.suggestLocations(controller.text, near: null /* TODO */).onError((e, s) async {
    //       return [];
    //     });
    //     return suggested.map(
    //       (namedLocation) => ListTile(
    //         title: Text(namedLocation.name),
    //         subtitle: Text(namedLocation.location.roundedTo(2, elevationDp: 0).toString()),
    //         trailing: const Icon(Icons.add),
    //         onTap: () {
    //           if (context.mounted) {
    //             context.read<RundownBloc>().add(AppendOtherLocation(otherLocation: namedLocation));
    //             controller.clear();
    //             controller.closeView(null);
    //           }
    //         },
    //       ),
    //     );
    //   },
    // );

    final currentLocationCoord = state.currentLocation;

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
                                    near: currentLocationCoord,
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
        if (context.mounted && locationToAdd is NamedCoordinate) {
          context.read<RundownBloc>().add(AppendOtherLocation(otherLocation: locationToAdd));
        }
      },
    );

    return [
      currentLocation,
      ...otherLocations,
      newLocationSearch,
    ];
  }

  List<Widget> _buildWeatherGraphs(BuildContext context, WeatherPredictState state) {
    return [
      if (state.weatherPredictError != null) Text("Cannot retrieve weather: ${state.weatherPredictError}"),
      if (state.weathers.isNotEmpty) ...[
        chartOf(
          state.weathers.map((weather) => weather.dryBulbTemp),
          Temp.celsius,
          defaultMin: const Data(5, Temp.celsius),
          baseline: const Data(15, Temp.celsius),
          defaultMax: const Data(25, Temp.celsius),
        ),
        chartOf(
          state.weathers.map((weather) => weather.estimatedWetBulbGlobeTemp),
          Temp.celsius,
          defaultMin: const Data(5, Temp.celsius),
          baseline: const Data(15, Temp.celsius),
          defaultMax: const Data(25, Temp.celsius),
        ),
        chartOf(state.weathers.map((weather) => weather.precipitationSince24hrAgo), Rainfall.mm),
        chartOf(state.weathers.map((weather) => weather.precipitation), Rainfall.mm),
        chartOf(
          state.weathers.map((weather) => weather.precipitationProb),
          Percent.outOf100,
          defaultMin: const Data(0, Percent.outOf100),
          defaultMax: const Data(100, Percent.outOf100),
        ),
        chartOf(
          state.weathers.map((weather) => weather.relHumidity),
          Percent.outOf100,
          defaultMin: const Data(0, Percent.outOf100),
          defaultMax: const Data(100, Percent.outOf100),
        ),
      ]
    ];
  }

  List<Widget> _buildWeatherInsights(BuildContext context, WeatherPredictState state) {
    return state.insights.map((insight) {
      final (title, subtitle) = insight.userVisibleInfo();
      return ListTile(
        leading: const Icon(Icons.warning_amber),
        title: Text(title),
        subtitle: Text(subtitle),
      );
    }).toList();
  }

  Widget chartOf<TUnit extends Convert<TUnit>>(Iterable<DataSeries<TUnit>> datas, TUnit asUnit, {Data<TUnit>? defaultMin, Data<TUnit>? baseline, Data<TUnit>? defaultMax}) {
    List<List<double>> dataPointss = datas.map((series) => series.valuesAs(asUnit).toList()).toList();
    final (dataMin, dataMax) = dataPointss.flattened.minMax as (double, double);
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineBarsData: dataPointss
              .mapIndexed((index, dataPoints) => LineChartBarData(
                    spots: dataPoints.indexed.map((item) => FlSpot(item.$1.toDouble(), item.$2)).toList(),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    dotData: const FlDotData(show: false),
                    color: nthWeatherResultColor(index),
                  ))
              .toList(),
          titlesData: const FlTitlesData(),
          minY: defaultMin != null ? min(dataMin, defaultMin.valueAs(asUnit).floorToDouble()) : dataMin,
          maxY: defaultMax != null ? max(dataMax, defaultMax.valueAs(asUnit).ceilToDouble()) : dataMax,
          baselineY: baseline?.valueAs(asUnit).roundToDouble(),
        ),
      ),
    );
  }
}
