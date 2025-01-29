import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turnip_rundown/data/api_cache_repository.dart';
import 'package:turnip_rundown/data/settings/repository.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/met/repository.dart';
import 'package:turnip_rundown/screens/settings/bloc.dart';
import 'package:turnip_rundown/util.dart';

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

  Widget _settingsHeader(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
    );
  }

  Widget _settingsTile({required Widget title, Widget? description, required Widget input}) {
    return ListTile(
      title: title,
      subtitle: description,
      trailing: input,
    );
  }

  Widget _settingsButton({required Widget child, required void Function() onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, Settings>(
      builder: (context, state) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _settingsHeader("Weather Backend"),
                  _settingsTile(
                    title: const Text("Backend"),
                    description: const Text("The backend for weather data. Met Office may not be available on specific platforms."),
                    input: SegmentedButton<RequestedWeatherBackend>(
                      segments: [
                        const ButtonSegment(value: RequestedWeatherBackend.openmeteo, label: Text("Openmeteo")),
                        ButtonSegment(value: RequestedWeatherBackend.met, label: const Text("Met Office"), enabled: metOfficeApiKey.isNotEmpty),
                      ],
                      selected: {state.backend},
                      emptySelectionAllowed: false,
                      multiSelectionEnabled: false,
                      onSelectionChanged: (selected) {
                        assert(selected.length == 1);
                        context.read<SettingsBloc>().add(SettingsEvent(backend: selected.first));
                      },
                    ),
                  ),
                  _settingsHeader("Display Units"),
                  _settingsTile(
                    title: const Text("Temperature"),
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
                    title: const Text("Rainfall"),
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
                  // TODO windspeed display unit
                  // _settingsTile(
                  //   title: const Text("Windspeed"),
                  //   input: SegmentedButton<Speed>(
                  //     segments: const [
                  //       ButtonSegment(value: Speed.kmPerH, label: Text("kmph")),
                  //       ButtonSegment(value: Speed.mPerS, label: Text("m/s")),
                  //       ButtonSegment(value: Speed.milesPerHour, label: Text("mph")),
                  //     ],
                  //     selected: {state.rainfallUnit},
                  //     emptySelectionAllowed: false,
                  //     multiSelectionEnabled: false,
                  //     onSelectionChanged: (selected) {
                  //       assert(selected.length == 1);
                  //       context.read<SettingsBloc>().add(SettingsEvent(rainfallUnit: selected.first));
                  //     },
                  //   ),
                  // ),
                  _settingsHeader("Waking Hours"),
                  _settingsTile(
                    title: const Text("Wake-Up Time"),
                    description: const Text(
                        "The time you typically wake up. When you open the app between your wake-up and bed times, it will automatically show you the weather for now til bedtime. Whole hours only, minutes are ignored."),
                    input: TextButton(
                      child: Text(jmLocalTime(DateTime(2000, 1, 1, state.wakingHours.start))),
                      onPressed: () async {
                        final selectedTime = await showTimePicker(context: context, initialTime: TimeOfDay(hour: state.wakingHours.start, minute: 0));
                        if (selectedTime != null && context.mounted) {
                          context.read<SettingsBloc>().add(SettingsEvent(wakingHourStart: selectedTime.hour));
                        }
                      },
                    ),
                  ),
                  _settingsTile(
                    title: const Text("Bedtime"),
                    description: const Text("The time you typically go to bed. Whole hours only, minutes are ignored."),
                    input: TextButton(
                      child: Text(jmLocalTime(DateTime(2000, 1, 1, state.wakingHours.end))),
                      onPressed: () async {
                        final selectedTime = await showTimePicker(context: context, initialTime: TimeOfDay(hour: state.wakingHours.end, minute: 0));
                        if (selectedTime != null && context.mounted) {
                          context.read<SettingsBloc>().add(SettingsEvent(wakingHourEnd: selectedTime.hour));
                        }
                      },
                    ),
                  ),
                  _settingsHeader("Insight Parameters"),
                  _settingsTile(
                    title: const Text("Use Estimated Wet Bulb Temperature"),
                    description: const Text(
                      "Wet Bulb Temperature is a better approximation of how it feels outside. When enabled, the main display and insights will display this temperature.",
                    ),
                    input: Switch(
                      value: state.weatherConfig.useEstimatedWetBulbTemp,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(SettingsEvent(useEstimatedWetBulbTemp: value));
                      },
                    ),
                  ),
                  _settingsTile(
                    title: const Text("Slippery - Recent Rainfall Threshold"),
                    description: Text("If rainfall over the last ${state.weatherConfig.numberOfHoursPriorRainThreshold} hours is higher than this, show a Slippery insight."),
                    input: DataPickerWidget(
                      initial: state.weatherConfig.priorRainThreshold,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(SettingsEvent(priorRainThreshold: value));
                      },
                    ),
                  ),
                  _settingsTile(
                    title: const Text("Slippery - Definition of Recent"),
                    description: const Text("Rainfall this many hours ago will be counted towards the Slippery insight total."),
                    input: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            context.read<SettingsBloc>().add(
                                  SettingsEvent(
                                    numberOfHoursPriorRainThreshold: math.max(state.weatherConfig.numberOfHoursPriorRainThreshold - 1, 0),
                                  ),
                                );
                          },
                        ),
                        Text(
                          state.weatherConfig.numberOfHoursPriorRainThreshold.toString(),
                          style: const TextStyle(fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            context.read<SettingsBloc>().add(
                                  SettingsEvent(
                                    numberOfHoursPriorRainThreshold: math.min(state.weatherConfig.numberOfHoursPriorRainThreshold + 1, 24),
                                  ),
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                  _settingsTile(
                    title: const Text("Rain Chance Threshold"),
                    description: const Text("If the chance of rain is higher than this, show a Light/Medium/Heavy Rain insight."),
                    input: DataPickerWidget(
                      initial: state.weatherConfig.rainProbabilityThreshold,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(SettingsEvent(rainProbabilityThreshold: value));
                      },
                    ),
                  ),
                  _settingsTile(
                    title: const Text("Rain Threshold - Medium"),
                    description: const Text("Predicted rainfall above this value shows a Medium Rain insight, and Light Rain otherwise."),
                    input: DataPickerWidget(
                      initial: state.weatherConfig.mediumRainThreshold,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(SettingsEvent(mediumRainThreshold: value));
                      },
                    ),
                  ),
                  _settingsTile(
                    title: const Text("Rain Threshold - Heavy"),
                    description: const Text("Predicted rainfall below this value shows a Heavy Rain insight."),
                    input: DataPickerWidget(
                      initial: state.weatherConfig.heavyRainThreshold,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(SettingsEvent(heavyRainThreshold: value));
                      },
                    ),
                  ),
                  _settingsTile(
                    title: const Text("High Humidity Threshold"),
                    description: const Text(
                      "Humidity higher than this is counted as 'high', showing a Misty, Uncomfortable, or Sweaty insight.",
                    ),
                    input: DataPickerWidget(
                      initial: state.weatherConfig.highHumidityThreshold,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(SettingsEvent(highHumidityThreshold: value));
                      },
                    ),
                  ),
                  _settingsTile(
                    title: const Text("High Humidity Threshold - Mist"),
                    description: const Text("At high humidity, any temperatures below this show a Misty insight."),
                    input: DataPickerWidget(
                      initial: state.weatherConfig.maxTemperatureForHighHumidityMist,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(SettingsEvent(maxTemperatureForHighHumidityMist: value));
                      },
                    ),
                  ),
                  _settingsTile(
                    title: const Text("High Humidity Threshold - Sweat"),
                    description: const Text(
                      "At high humidity, any temperatures above this show a Sweaty insight. Temperatures between Misty and Sweaty show an Uncomfortable insight.",
                    ),
                    input: DataPickerWidget(
                      initial: state.weatherConfig.minTemperatureForHighHumiditySweat,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(SettingsEvent(minTemperatureForHighHumiditySweat: value));
                      },
                    ),
                  ),
                  _settingsTile(
                    title: const Text("Windspeed - Breezy"),
                    description: const Text("Any wind faster than this will show a Breezy insight. Wind slower than this will be ignored."),
                    input: DataPickerWidget(
                      initial: state.weatherConfig.minimumBreezyWindspeed,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(SettingsEvent(minimumBreezyWindspeed: value));
                      },
                    ),
                  ),
                  _settingsTile(
                    title: const Text("Windspeed - Windy"),
                    description: const Text("Any wind faster than this will show a Windy insight."),
                    input: DataPickerWidget(
                      initial: state.weatherConfig.minimumWindyWindspeed,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(SettingsEvent(minimumWindyWindspeed: value));
                      },
                    ),
                  ),
                  _settingsTile(
                    title: const Text("Windspeed - Gale"),
                    description: const Text("Any wind faster than this will show a Gale-y insight."),
                    input: DataPickerWidget(
                      initial: state.weatherConfig.minimumGaleyWindspeed,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(SettingsEvent(minimumGaleyWindspeed: value));
                      },
                    ),
                  ),
                  _settingsButton(
                    child: const Text("Reset insight parameters"),
                    onPressed: () {
                      context.read<SettingsBloc>().add(SettingsEvent.withInitialWeatherConfig());
                    },
                  ),
                  _settingsButton(
                    child: const Text("Check API cache"),
                    onPressed: () async {
                      final stats = await RepositoryProvider.of<ApiCacheRepository>(context).getStats();
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("API cache statistics"),
                              content: Text(
                                stats.hostStats.entries.map((entry) => "${entry.key} : hit ${entry.value.cacheHits} miss ${entry.value.cacheMisses}").join("\n"),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                  _settingsButton(
                    child: const Text("Reset API cache"),
                    onPressed: () {
                      RepositoryProvider.of<ApiCacheRepository>(context).resetStats();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
