import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:turnip_rundown/data/api_cache.dart';
import 'package:turnip_rundown/screens/rundown/screen.dart';
import 'package:turnip_rundown/screens/settings/screen.dart';

final router = GoRouter(
  initialLocation: "/rundown",
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AdaptiveScaffold(
          internalAnimations: false,
          transitionDuration: const Duration(milliseconds: 300),
          selectedIndex: navigationShell.currentIndex,
          destinations: const [
            NavigationDestination(
              label: "Rundown",
              icon: Icon(Icons.auto_graph),
            ),
            NavigationDestination(
              label: 'Settings',
              icon: Icon(Icons.settings),
            ),
            NavigationDestination(
              label: 'About',
              icon: Icon(Icons.info),
            ),
          ],
          appBar: AppBar(title: const Text('Turnip Rundown')),
          onSelectedIndexChange: (index) async {
            // if there's a drawer, close it
            // if (_drawerSize) Navigator.pop(context);

            switch (index) {
              case 0:
                context.go('/rundown');
                break;
              case 1:
                context.go('/settings');
                break;
              case 2:
                // final packageInfo = await PackageInfo.fromPlatform();
                // showAboutDialog(
                //   context: context,
                //   applicationName: packageInfo.appName,
                //   applicationVersion: 'v${packageInfo.version}',
                //   applicationLegalese: 'Copyright © 2022, Acme, Corp.',
                // );
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
                break;
              default:
                throw Exception('Invalid index');
            }
          },
          body: (context) => SafeArea(child: navigationShell),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: "rundown",
              path: "/rundown",
              builder: (context, state) => const RundownScreen(),
            )
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: "settings",
              path: "/settings",
              builder: (context, state) => const SettingsScreen(),
            )
          ],
        ),
      ],
    ),
  ],
);
