import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:turnip_rundown/data/api_cache.dart';
import 'package:turnip_rundown/data/geo/photon/repository.dart';
import 'package:turnip_rundown/data/geo/repository.dart';
import 'package:turnip_rundown/data/current_coordinate/repository.dart';
import 'package:turnip_rundown/data/weather/repository.dart';
import 'package:turnip_rundown/nav.dart';
import 'package:turnip_rundown/screens/settings/bloc.dart';

void main() async {
  // Use sqflite on MacOS/iOS/Android.
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    // // Use web implementation on the web.
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    // Use ffi on Linux and Windows.
    if (Platform.isLinux || Platform.isWindows) {
      databaseFactory = databaseFactoryFfi;
      sqfliteFfiInit();
    }
  }

  final dbPath = (kIsWeb)
      ? "turnip_rundown.db"
      : join(
          (await getApplicationCacheDirectory()).path,
          "turnip_rundown.db",
        );

  Hive.init((kIsWeb) ? null : (await getApplicationSupportDirectory()).path);
  final settingsBox = await Hive.openBox("settings");

  runApp(MyApp(
    cacheRepo: await SqfliteApiCacheRepository.getRepository(dbPath),
    settingsBox: settingsBox,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.cacheRepo, required this.settingsBox});

  final ApiCacheRepository cacheRepo;
  final Box settingsBox;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiCacheRepository>(create: (context) => cacheRepo),
        RepositoryProvider<CurrentCoordinateRepository>(create: (context) => GeolocatorCurrentCoordinateRepository()),
        RepositoryProvider<WeatherRepository>(
          create: (context) => OpenMeteoWeatherRepository(
            cache: RepositoryProvider.of<ApiCacheRepository>(context),
          ),
        ),
        RepositoryProvider<GeocoderRepository>(
          create: (context) => PhotonGeocoderRepository(
            cache: RepositoryProvider.of<ApiCacheRepository>(context),
          ),
        ),
      ],
      child: BlocProvider(
        create: (context) => SettingsBloc(settingsBox),
        child: MaterialApp.router(
          title: 'Turnip Rundown',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          routerConfig: router,
        ),
      ),
    );
  }
}
