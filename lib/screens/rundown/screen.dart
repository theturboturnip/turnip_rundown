import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turnip_rundown/data/location/repository.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/repository.dart';
import 'package:turnip_rundown/screens/rundown/bloc.dart';

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
                child: BlocBuilder<RundownBloc, RundownState>(builder: _buildLocationDisplay),
              ),
              BlocBuilder<WeatherPredictBloc, WeatherPredictState>(builder: (context, state) {
                return Column(
                  children: [
                    ..._buildWeatherGraphs(context, state),
                    ..._buildWeatherInsights(context, state),
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

  Widget _buildLocationDisplay(BuildContext context, RundownState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.currentLocationError != null) Text("Cannot retrieve location: ${state.currentLocationError}"),
        if (state.currentLocationError == null && state.currentLocation == null)
          const SizedBox(
            width: 100,
            child: LinearProgressIndicator(),
          ),
        if (state.currentLocation != null) Text("Location: ${state.currentLocation!.lat} ${state.currentLocation!.long} ${state.currentLocation!.elevation ?? '??'}m"),
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
      ],
    );
  }

  List<Widget> _buildWeatherGraphs(BuildContext context, WeatherPredictState state) {
    // TODO combine weather plots
    final weather = state.weathers.firstOrNull;
    return [
      if (state.weatherPredictError != null) Text("Cannot retrieve weather: ${state.weatherPredictError}"),
      if (weather != null) ...[
        chartOf(
          weather.dryBulbTemp,
          Temp.celsius,
          defaultMin: const Data(5, Temp.celsius),
          baseline: const Data(15, Temp.celsius),
          defaultMax: const Data(25, Temp.celsius),
        ),
        chartOf(
          weather.estimatedWetBulbGlobeTemp,
          Temp.celsius,
          defaultMin: const Data(5, Temp.celsius),
          baseline: const Data(15, Temp.celsius),
          defaultMax: const Data(25, Temp.celsius),
        ),
        chartOf(weather.precipitationSince24hrAgo, Rainfall.mm),
        chartOf(weather.precipitation, Rainfall.mm),
        chartOf(
          weather.precipitationProb,
          Percent.outOf100,
          defaultMin: const Data(0, Percent.outOf100),
          defaultMax: const Data(100, Percent.outOf100),
        ),
        chartOf(
          weather.relHumidity,
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

  Widget chartOf<TUnit extends Convert<TUnit>>(DataSeries<TUnit> unit, TUnit asUnit, {Data<TUnit>? defaultMin, Data<TUnit>? baseline, Data<TUnit>? defaultMax}) {
    // return Text(unit.valuesAs(asUnit).join(","));
    List<double> dataPoints = unit.valuesAs(asUnit).toList();
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: dataPoints.indexed.map((item) => FlSpot(item.$1.toDouble(), item.$2)).toList(),
              isCurved: true,
              preventCurveOverShooting: true,
              dotData: const FlDotData(show: false),
            )
          ],
          titlesData: const FlTitlesData(),
          minY: defaultMin != null ? min(dataPoints.min, defaultMin.valueAs(asUnit).floorToDouble()) : dataPoints.min,
          maxY: defaultMax != null ? max(dataPoints.max, defaultMax.valueAs(asUnit).ceilToDouble()) : dataPoints.max,
          baselineY: baseline?.valueAs(asUnit).roundToDouble(),
        ),
      ),
    );
  }
}
