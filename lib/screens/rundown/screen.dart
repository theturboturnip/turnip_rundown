import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turnip_rundown/data/location/repository.dart';
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
                  _buildWeatherGraph(context, state),
                  ..._buildWeatherInsights(context),
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

  Widget _buildWeatherGraph(BuildContext context, RundownState state) {
    return SizedBox(
      height: 100,
      child: Center(
        child: (state.error == RundownError.cantRetrieveWeather) ? const Text("Cannot retrieve weather") : const Text("No weather found"),
      ),
    );
  }

  List<Widget> _buildWeatherInsights(BuildContext context) {
    return const [
      SizedBox(width: 50, height: 10, child: ColoredBox(color: Colors.pink)),
      SizedBox(width: 50, height: 10, child: ColoredBox(color: Colors.brown)),
      SizedBox(width: 50, height: 10, child: ColoredBox(color: Colors.orange)),
      SizedBox(width: 50, height: 10, child: ColoredBox(color: Colors.purple)),
    ];
  }
}
