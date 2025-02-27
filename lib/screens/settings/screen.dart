import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:turnip_rundown/data/api_cache_repository.dart';
import 'package:turnip_rundown/data/settings/repository.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/met/repository.dart';
import 'package:turnip_rundown/screens/settings/bloc.dart';
import 'package:turnip_rundown/util.dart';

// Interface to a single-selection-of-list widget.
// Can be backed by a segmented button or a dropdown menu.
class SimpleDataSelectorWidget<T> extends StatelessWidget {
  final T selected;
  final List<DropdownMenuEntry<T>> entries;
  final void Function(T) onSelected;
  final bool useSegmentedButton;

  const SimpleDataSelectorWidget({
    super.key,
    required this.selected,
    required this.entries,
    required this.onSelected,
    this.useSegmentedButton = false,
  });

  @override
  Widget build(BuildContext context) {
    if (useSegmentedButton) {
      return SegmentedButton<T>(
        segments: entries
            .map(
              (entry) => ButtonSegment(
                value: entry.value,
                label: Text(entry.label),
                enabled: entry.enabled,
              ),
            )
            .toList(),
        selected: {selected},
        emptySelectionAllowed: false,
        multiSelectionEnabled: false,
        onSelectionChanged: (selected) {
          assert(selected.length == 1);
          onSelected(selected.first);
        },
      );
    } else {
      return DropdownMenu<T>(
        dropdownMenuEntries: entries,
        initialSelection: selected,
        enableSearch: false,
        enableFilter: false,
        textAlign: TextAlign.end,
        onSelected: (t) {
          if (t != null) {
            onSelected(t);
          }
        },
      );
    }
  }
}

class DataPickerWidget<T extends Unit<T>> extends StatefulWidget {
  const DataPickerWidget({
    super.key,
    required this.initial,
    required this.onChanged,
    this.textWidth = 60,
    this.unitWidth = 100,
  });

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
          inputDecorationTheme: InputDecorationTheme(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            constraints: BoxConstraints.tight(const Size.fromHeight(48)),

            // border: OutlineInputBorder(
            //   borderRadius: BorderRadius.circular(8),
            // ),
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

  Widget _settingsTile(BuildContext context, {required Widget title, Widget? description, required Widget input}) {
    // if (description == null) {
    //   return ListTile(
    //     title: title,
    //     trailing: input,
    //     minTileHeight: 70,
    //   );
    // } else {
    // return ListTile(
    //   title: title,
    //   trailing: input,
    //   minTileHeight: 70,
    // );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.bodyLarge!,
                  textAlign: TextAlign.start,
                  child: title,
                ),
                if (description != null) description,
              ],
            ),
          ),
          // IconButton(onPressed: () {}, icon: Icon(Icons.info_outline)),
          SizedBox(
            width: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [input],
            ),
          ),
        ],
      ),
    );
    //   return ExpansionTile(
    //     // title: Row(
    //     //   children: [
    //     //     title,
    //     //     const Spacer(),
    //     //     SizedBox(
    //     //       width: 160,
    //     //       height: null,
    //     //       child: input,
    //     //     ),
    //     //   ],
    //     // ),
    //     title: title,
    //     trailing: input,
    //     controlAffinity: ListTileControlAffinity.leading,
    //     minTileHeight: 70,
    //     children: [description],
    //   );
    // }
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
                    context,
                    title: const Text("Backend"),
                    description: const Text("The backend for weather data. Met Office may not be available on specific platforms."),
                    input: SimpleDataSelectorWidget<RequestedWeatherBackend>(
                      selected: state.backend,
                      entries: [
                        const DropdownMenuEntry(
                          value: RequestedWeatherBackend.openmeteo,
                          label: "Openmeteo",
                        ),
                        DropdownMenuEntry(
                          value: RequestedWeatherBackend.met,
                          label: "Met Office",
                          enabled: metOfficeApiKey.isNotEmpty,
                        ),
                      ],
                      onSelected: (backend) {
                        context.read<SettingsBloc>().add(SettingsEvent(backend: backend));
                      },
                    ),
                  ),
                  _settingsTile(
                    context,
                    title: const Text("Sunrise/set Backend"),
                    input: TextButton(
                      onPressed: () => launchUrl(
                        Uri(scheme: "https", host: "sunrise-sunset.org"),
                      ),
                      child: const Text(
                        "https://sunrise-sunset.org",
                        style: TextStyle(
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),

                  _settingsHeader("Display Units"),
                  _settingsTile(
                    context,
                    title: const Text("Temperature"),
                    input: SimpleDataSelectorWidget(
                      selected: state.temperatureUnit,
                      entries: const [
                        DropdownMenuEntry(value: TempDisplay.celsius, label: "°C"),
                        DropdownMenuEntry(value: TempDisplay.farenheit, label: "°F"),
                        DropdownMenuEntry(value: TempDisplay.both, label: "°C and °F"),
                      ],
                      onSelected: (s) {
                        context.read<SettingsBloc>().add(SettingsEvent(temperatureUnit: s));
                      },
                    ),
                  ),
                  _settingsTile(
                    context,
                    title: const Text("Rainfall"),
                    input: SimpleDataSelectorWidget(
                      selected: state.rainfallUnit,
                      entries: const [
                        DropdownMenuEntry(value: Rainfall.mm, label: "mm"),
                        DropdownMenuEntry(value: Rainfall.inch, label: "in"),
                      ],
                      onSelected: (s) {
                        context.read<SettingsBloc>().add(SettingsEvent(rainfallUnit: s));
                      },
                    ),
                  ),
                  // TODO windspeed display unit
                  // _settingsTile(context,
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
                    context,
                    title: const Text("Wake-Up Time"),
                    description: const Text(
                        "The time you typically wake up. When you open the app between your wake-up and bed times, it will automatically show you the weather for now til bedtime. Whole hours only, minutes are ignored."),
                    input: TextButton(
                      child: Text(jmFormatHour(state.wakingHours.start)),
                      onPressed: () async {
                        final selectedTime = await showTimePicker(context: context, initialTime: TimeOfDay(hour: state.wakingHours.start, minute: 0));
                        if (selectedTime != null && context.mounted) {
                          context.read<SettingsBloc>().add(SettingsEvent(wakingHourStart: selectedTime.hour));
                        }
                      },
                    ),
                  ),
                  _settingsTile(
                    context,
                    title: const Text("Bedtime"),
                    description: const Text("The time you typically go to bed. Whole hours only, minutes are ignored."),
                    input: TextButton(
                      child: Text(jmFormatHour(state.wakingHours.end)),
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
                    context,
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
                    context,
                    title: const Text("Temperature - Freezing"),
                    description: const Text("Temperatures above this threshold show a Freezing insight."),
                    input: DataPickerWidget(
                      initial: state.weatherConfig.freezingMaxTemp,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(SettingsEvent(freezingMaxTemp: value));
                      },
                    ),
                  ),
                  _settingsTile(
                    context,
                    title: const Text("Temperature - Boiling"),
                    description: const Text("Temperatures above this threshold show a Boiling insight."),
                    input: DataPickerWidget(
                      initial: state.weatherConfig.boilingMinTemp,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(SettingsEvent(boilingMinTemp: value));
                      },
                    ),
                  ),
                  _settingsTile(
                    context,
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
                    context,
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
                    context,
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
                    context,
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
                    context,
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
                    context,
                    title: const Text("High Humidity Threshold"),
                    description: const Text(
                      "Humidity higher than this is counted as 'high', showing a Uncomfortable or Sweaty insight.",
                    ),
                    input: DataPickerWidget(
                      initial: state.weatherConfig.highHumidityThreshold,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(SettingsEvent(highHumidityThreshold: value));
                      },
                    ),
                  ),
                  _settingsTile(
                    context,
                    title: const Text("High Humidity Temperature - Uncomfortable"),
                    description: const Text("High humidity insights require the temperature to be above this."),
                    input: DataPickerWidget(
                      initial: state.weatherConfig.maxTemperatureForHighHumidityMist,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(SettingsEvent(maxTemperatureForHighHumidityMist: value));
                      },
                    ),
                  ),
                  _settingsTile(
                    context,
                    title: const Text("High Humidity Temperature - Sweaty"),
                    description: const Text(
                      "At high humidity, any temperatures above this show a Sweaty insight. Temperatures between Uncomfortable and Sweaty show an Uncomfortable insight.",
                    ),
                    input: DataPickerWidget(
                      initial: state.weatherConfig.minTemperatureForHighHumiditySweat,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(SettingsEvent(minTemperatureForHighHumiditySweat: value));
                      },
                    ),
                  ),
                  _settingsTile(
                    context,
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
                    context,
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
                    context,
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
