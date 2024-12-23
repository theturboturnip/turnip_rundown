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
    return BlocProvider(
      create: (context) => RundownBloc(
        RepositoryProvider.of<LocationRepository>(context),
        RepositoryProvider.of<WeatherRepository>(context),
      )..add(const RefreshCoordinate()),
      child: Scaffold(
        body: SingleChildScrollView(
          child: BlocBuilder<RundownBloc, RundownState>(
            builder: (context, state) {
              return Column(
                children: [
                  // _buildCurrentWeather(context),
                  _buildLocationDisplay(context, state),
                  ..._buildWeatherGraphs(context, state),
                  ..._buildWeatherInsights(context, state),
                ],
              );
            },
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
        if (state.error == RundownError.cantRetrieveLocation) const Text("Cannot retrieve location"),
        if (state.error == null && state.location == null)
          const SizedBox(
            width: 100,
            child: LinearProgressIndicator(),
          ),
        if (state.location != null) Text("Location: ${state.location!.lat} ${state.location!.long} ${state.location!.elevation ?? '??'}m"),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            context.read<RundownBloc>().add(const RefreshCoordinate());
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

  List<Widget> _buildWeatherGraphs(BuildContext context, RundownState state) {
    return [
      if (state.error == RundownError.cantRetrieveWeather) const Text("Cannot retrieve weather"),
      if (state.error == null && state.location == null && state.weather == null)
        const SizedBox(
          width: 100,
          child: LinearProgressIndicator(),
        ),
      if (state.weather != null) ...[
        chartOf(
          state.weather!.dryBulbTemp,
          Temp.celsius,
          defaultMin: const Data(5, Temp.celsius),
          baseline: const Data(15, Temp.celsius),
          defaultMax: const Data(25, Temp.celsius),
        ),
        chartOf(
          state.weather!.estimatedWetBulbGlobeTemp,
          Temp.celsius,
          defaultMin: const Data(5, Temp.celsius),
          baseline: const Data(15, Temp.celsius),
          defaultMax: const Data(25, Temp.celsius),
        ),
        chartOf(state.weather!.precipitationSince24hrAgo, Rainfall.mm),
        chartOf(state.weather!.precipitation, Rainfall.mm),
        chartOf(
          state.weather!.precipitationProb,
          Percent.outOf100,
          defaultMin: const Data(0, Percent.outOf100),
          defaultMax: const Data(100, Percent.outOf100),
        ),
        chartOf(
          state.weather!.relHumidity,
          Percent.outOf100,
          defaultMin: const Data(0, Percent.outOf100),
          defaultMax: const Data(100, Percent.outOf100),
        ),
      ]
    ];
  }

  List<Widget> _buildWeatherInsights(BuildContext context, RundownState state) {
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
