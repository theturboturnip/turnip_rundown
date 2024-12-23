import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turnip_rundown/data/location/repository.dart';
import 'package:turnip_rundown/data/weather/repository.dart';
import 'package:turnip_rundown/nav.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LocationRepository>(create: (context) => GeolocatorLocationRepository()),
        RepositoryProvider<WeatherRepository>(create: (context) => OpenMeteoWeatherRepository()),
      ],
      child: MaterialApp.router(
        title: 'Turnip Rundown',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}
