import 'package:flutter/material.dart';

class RundownScreen extends StatelessWidget {
  const RundownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCurrentWeather(context),
            _buildWeatherGraph(context),
            ..._buildWeatherInsights(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeather(BuildContext context) {
    return const SizedBox(width: 10, height: 10, child: ColoredBox(color: Colors.red));
  }

  Widget _buildWeatherGraph(BuildContext context) {
    return const SizedBox(width: 10, height: 10, child: ColoredBox(color: Colors.green));
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
