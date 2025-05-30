import 'package:flutter/material.dart';
import 'home_screen.dart'; // For WeatherData

class ForecastScreen extends StatelessWidget {
  final List<WeatherData> forecast;

  const ForecastScreen({Key? key, required this.forecast}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('5-Day Forecast (12 PM)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: forecast.isEmpty
            ? Center(child: Text('No forecast data'))
            : ListView(
                children: forecast
                    .map((day) => ListTile(
                          title: Text('${day.description} - ${day.temperature}°C'),
                          subtitle: Text(day.city),
                        ))
                    .toList(),
              ),
      ),
    );
  }
}
