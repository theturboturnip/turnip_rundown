import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:turnip_rundown/screens/rundown/screen.dart';

final router = GoRouter(initialLocation: "/", routes: [
  GoRoute(
    name: "rundown",
    path: "/",
    builder: (context, state) => const RundownScreen(),
  )
]);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Turnip Rundown',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
