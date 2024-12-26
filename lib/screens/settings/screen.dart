import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turnip_rundown/data/api_cache_repository.dart';
import 'package:turnip_rundown/data/settings/repository.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/screens/settings/bloc.dart';

class DataPickerWidget<T extends Unit<T>> extends StatefulWidget {
  const DataPickerWidget({super.key, required this.initial, required this.onChanged, this.textWidth = 60, this.unitWidth = 90});

  final Data<T> initial;
  final void Function(Data<T>) onChanged;
  final double textWidth;
  final double unitWidth;

  @override
  State<StatefulWidget> createState() => DataPickerWidgetState<T>();
}

class DataPickerWidgetState<T extends Unit<T>> extends State<DataPickerWidget<T>> {
  DataPickerWidgetState() : _numberController = TextEditingController();

  final TextEditingController _numberController;
  late Data<T> _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
    _updateNumberControllerToMatchValue();
  }

  @override
  void didUpdateWidget(DataPickerWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial) {
      _value = widget.initial;
      _updateNumberControllerToMatchValue();
    }
  }

  void _updateNumberControllerToMatchValue() {
    _numberController.text = _value.valueAs(_value.unit).toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.textWidth,
          child: TextField(
            controller: _numberController,
            textAlign: TextAlign.end,
            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
            onSubmitted: (newValueString) {
              setState(() {
                _value = Data(double.tryParse(newValueString) ?? _value.valueAs(_value.unit), _value.unit);
                _updateNumberControllerToMatchValue();
                widget.onChanged(_value);
              });
            },
          ),
        ),
        DropdownMenu<T>(
          dropdownMenuEntries: _value.unit.enumValues.map((value) => DropdownMenuEntry(value: value, label: value.display)).toList(),
          initialSelection: _value.unit,
          width: widget.unitWidth,
          enableSearch: false,
          enableFilter: false,
          textAlign: TextAlign.end,
          onSelected: (newUnit) {
            if (newUnit != null) {
              setState(() {
                _value = _value.convertedTo(newUnit);
                _updateNumberControllerToMatchValue();
                widget.onChanged(_value);
              });
            }
          },
          inputDecorationTheme: const InputDecorationTheme(
            isDense: true,
          ),
        ),
      ],
    );
  }
}

Widget percentDataPickerSlider(Data<Percent> value, void Function(Data<Percent> newValue) onChanged) {
  return Slider(
    value: value.valueAs(Percent.outOf1),
    onChanged: (newValueOutOf1) => onChanged(Data(newValueOutOf1, Percent.outOf1)),
  );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _settingsTile({required Widget title, required Widget input}) {
    return ListTile(
      title: title,
      trailing: input,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, Settings>(
      builder: (context, state) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _settingsTile(
                  title: const Text("Temperature Unit"),
                  input: SegmentedButton<TempDisplay>(
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
                      context.read<SettingsBloc>().add(SettingsEvent(temperatureUnit: selected.first));
                    },
                  ),
                ),
                _settingsTile(
                  title: const Text("Rainfall Unit"),
                  input: SegmentedButton<Rainfall>(
                    segments: const [
                      ButtonSegment(value: Rainfall.mm, label: Text("mm")),
                      ButtonSegment(value: Rainfall.inch, label: Text("in")),
                    ],
                    selected: {state.rainfallUnit},
                    emptySelectionAllowed: false,
                    multiSelectionEnabled: false,
                    onSelectionChanged: (selected) {
                      assert(selected.length == 1);
                      context.read<SettingsBloc>().add(SettingsEvent(rainfallUnit: selected.first));
                    },
                  ),
                ),
                // TODO waking hours start, waking hours end settings
                // _settingsTile(title: const Text("Waking Hours - Start"), input: input)
                _settingsTile(
                  title: const Text("Use Estimated Wet Bulb Temperature"),
                  input: Switch(
                    value: state.weatherConfig.useEstimatedWetBulbTemp,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(SettingsEvent(useEstimatedWetBulbTemp: value));
                    },
                  ),
                ),
// TODO numberOfHoursPriorRainThreshold;
                _settingsTile(
                  title: const Text("priorRainThreshold"), // TODO
                  input: DataPickerWidget(
                    initial: state.weatherConfig.priorRainThreshold,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(SettingsEvent(priorRainThreshold: value));
                    },
                  ),
                ),
                _settingsTile(
                  title: const Text("rainProbabilityThreshold"), // TODO
                  input: DataPickerWidget(
                    initial: state.weatherConfig.rainProbabilityThreshold,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(SettingsEvent(rainProbabilityThreshold: value));
                    },
                  ),
                ),
                _settingsTile(
                  title: const Text("mediumRainThreshold"), // TODO
                  input: DataPickerWidget(
                    initial: state.weatherConfig.mediumRainThreshold,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(SettingsEvent(mediumRainThreshold: value));
                    },
                  ),
                ),
                _settingsTile(
                  title: const Text("heavyRainThreshold"), // TODO
                  input: DataPickerWidget(
                    initial: state.weatherConfig.heavyRainThreshold,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(SettingsEvent(heavyRainThreshold: value));
                    },
                  ),
                ),
                _settingsTile(
                  title: const Text("highHumidityThreshold"), // TODO
                  input: DataPickerWidget(
                    initial: state.weatherConfig.highHumidityThreshold,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(SettingsEvent(highHumidityThreshold: value));
                    },
                  ),
                ),
                _settingsTile(
                  title: const Text("maxTemperatureForHighHumidityMist"), // TODO
                  input: DataPickerWidget(
                    initial: state.weatherConfig.maxTemperatureForHighHumidityMist,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(SettingsEvent(maxTemperatureForHighHumidityMist: value));
                    },
                  ),
                ),
                _settingsTile(
                  title: const Text("minTemperatureForHighHumiditySweat"), // TODO
                  input: DataPickerWidget(
                    initial: state.weatherConfig.minTemperatureForHighHumiditySweat,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(SettingsEvent(minTemperatureForHighHumiditySweat: value));
                    },
                  ),
                ),
                _settingsTile(
                  title: const Text("minimumBreezyWindspeed"), // TODO
                  input: DataPickerWidget(
                    initial: state.weatherConfig.minimumBreezyWindspeed,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(SettingsEvent(minimumBreezyWindspeed: value));
                    },
                  ),
                ),
                _settingsTile(
                  title: const Text("minimumWindyWindspeed"), // TODO
                  input: DataPickerWidget(
                    initial: state.weatherConfig.minimumWindyWindspeed,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(SettingsEvent(minimumWindyWindspeed: value));
                    },
                  ),
                ),
                _settingsTile(
                  title: const Text("minimumGaleyWindspeed"), // TODO
                  input: DataPickerWidget(
                    initial: state.weatherConfig.minimumGaleyWindspeed,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(SettingsEvent(minimumGaleyWindspeed: value));
                    },
                  ),
                ),
                TextButton(
                  child: const Text("Reset insight config"),
                  onPressed: () {
                    context.read<SettingsBloc>().add(SettingsEvent.withInitialWeatherConfig());
                  },
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
