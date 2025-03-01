import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:turnip_rundown/data/api_cache_repository.dart';
import 'package:turnip_rundown/data/geo/photon/repository.dart';
import 'package:turnip_rundown/data/geo/repository.dart';
import 'package:turnip_rundown/data/current_coordinate/repository.dart';
import 'package:turnip_rundown/data/settings/repository.dart';
import 'package:turnip_rundown/data/sqflite_repositories.dart';
import 'package:turnip_rundown/data/weather/met/repository.dart';
import 'package:turnip_rundown/data/weather/repository.dart';
import 'package:turnip_rundown/data/web_repositories.dart';
import 'package:turnip_rundown/nav.dart';
import 'package:turnip_rundown/screens/settings/bloc.dart';

void main() async {
  // Use sqflite on MacOS/iOS/Android.
  WidgetsFlutterBinding.ensureInitialized();

  late ApiCacheRepository cacheRepo;
  late SettingsRepository settingsRepo;

  if (kIsWeb) {
    // Use an in-memory cache for API responses
    cacheRepo = InMemoryApiCacheRepository();

    // TODO prob don't need this?
    SharedPreferences.setMockInitialValues({});
    // Use SharedPreferences to store settings
    settingsRepo = SharedPreferencesSettingsRepository(prefs: await SharedPreferences.getInstance());
  } else {
    // Use ffi on Linux and Windows.
    if (Platform.isLinux || Platform.isWindows) {
      databaseFactory = databaseFactoryFfi;
      sqfliteFfiInit();
    }

    late final String dbFolder;
    if (Platform.isAndroid) {
      dbFolder = await getDatabasesPath();
    } else if (Platform.isIOS || Platform.isMacOS) {
      dbFolder = (await getLibraryDirectory()).path;
    } else if (kDebugMode) {
      dbFolder = (await getTemporaryDirectory()).path;
    } else {
      dbFolder = (await getApplicationDocumentsDirectory()).path;
    }

    // Create separate repositories in the relevant directories for different purposes.
    // The repositories will both be capable of storing the other kind of data,
    // they just won't.
    // NOPE DONT DO THAT I DONT THINK SQFLITE SUPPORTS THAT
    // cacheRepo = await SqfliteApiCacheAndSettingsRepository.getRepository(join(
    //   (await getApplicationCacheDirectory()).path,
    //   "turnip_rundown_cache.db",
    // ));
    cacheRepo = settingsRepo = await SqfliteApiCacheAndSettingsRepository.getRepository(join(
      dbFolder,
      "turnip_rundown.db",
    ));
  }

  runApp(MyApp(
    cacheRepo: cacheRepo,
    settingsRepo: settingsRepo,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.cacheRepo, required this.settingsRepo});

  final ApiCacheRepository cacheRepo;
  final SettingsRepository settingsRepo;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiCacheRepository>(create: (context) => cacheRepo),
        RepositoryProvider<SettingsRepository>(create: (context) => settingsRepo),
        RepositoryProvider<CurrentCoordinateRepository>(create: (context) => GeolocatorCurrentCoordinateRepository()),
        RepositoryProvider<WeatherRepository>(
          create: (context) {
            final cache = RepositoryProvider.of<ApiCacheRepository>(context);
            return SwitchWeatherRepository(
              settings: settingsRepo,
              repos: {
                RequestedWeatherBackend.openmeteo: OpenMeteoWeatherRepository(
                  cache: cache,
                ),
                RequestedWeatherBackend.met: MetOfficeRepository.load(cache),
              },
            );
          },
        ),
        RepositoryProvider<GeocoderRepository>(
          create: (context) => PhotonGeocoderRepository(
            cache: RepositoryProvider.of<ApiCacheRepository>(context),
          ),
        ),
      ],
      child: BlocProvider(
        create: (context) => SettingsBloc(RepositoryProvider.of<SettingsRepository>(context)),
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
