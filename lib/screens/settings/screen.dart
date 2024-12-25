import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turnip_rundown/data/api_cache.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/screens/settings/bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ListTile(
                  title: const Text("Temperature Unit"),
                  trailing: SegmentedButton<TempDisplay>(
                    segments: const [
                      ButtonSegment(value: TempDisplay.celsius, label: Text("°C")),
                      ButtonSegment(value: TempDisplay.both, label: Text("Both")),
                      ButtonSegment(value: TempDisplay.farenheit, label: Text("°F")),
                    ],
                    selected: {state.temperatureUnit},
                    emptySelectionAllowed: false,
                    multiSelectionEnabled: false,
                    onSelectionChanged: (selected) {
                      assert(selected.length == 1);
                      context.read<SettingsCubit>().updateTemperature(selected.first);
                    },
                  ),
                ),
                ListTile(
                  title: const Text("Rainfall Unit"),
                  trailing: SegmentedButton<Rainfall>(
                    segments: const [
                      ButtonSegment(value: Rainfall.mm, label: Text("mm")),
                      ButtonSegment(value: Rainfall.inch, label: Text("in")),
                    ],
                    selected: {state.rainfallUnit},
                    emptySelectionAllowed: false,
                    multiSelectionEnabled: false,
                    onSelectionChanged: (selected) {
                      assert(selected.length == 1);
                      context.read<SettingsCubit>().updateRainfall(selected.first);
                    },
                  ),
                ),
                TextButton(
                  child: const Text("Check API cache"),
                  onPressed: () async {
                    final stats = await RepositoryProvider.of<ApiCacheRepository>(context).getStats();
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Info"),
                            content: Text(
                              stats.hostStats.entries.map((entry) => "${entry.key} : hit ${entry.value.cacheHits} miss ${entry.value.cacheMisses}").join("\n"),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
                TextButton(
                  child: const Text("Reset API cache"),
                  onPressed: () {
                    RepositoryProvider.of<ApiCacheRepository>(context).resetStats();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
