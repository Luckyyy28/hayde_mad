import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'forecast_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String city = 'Urdaneta';
  WeatherData? weather;
  List<WeatherData> forecast = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initLocationAndFetch();
  }

  Future<void> _initLocationAndFetch() async {
    try {
      Position position = await _determinePosition();
      List<Placemark> placemark = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemark.isNotEmpty) {
        String? foundCity = placemark[0].locality;
        if (foundCity == null || foundCity.isEmpty) {
          foundCity = placemark[0].administrativeArea;
        }
        if (foundCity == null || foundCity.isEmpty) {
          foundCity = placemark[0].country;
        }
        setState(() {
          city = foundCity ?? 'Urdaneta';
        });
      }
    } catch (e) {
      // fallback to default city
      setState(() {
        city = 'Urdaneta';
      });
    }
    fetchWeather();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> fetchWeather() async {
    setState(() => isLoading = true);
    final data = await WeatherService.fetchWeather(city);
    final days = await WeatherService.fetchForecast(city);
    setState(() {
      weather = data;
      forecast = days;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final outfit = weather != null ? OutfitAdvisor.getOutfit(weather!) : '';

    return Scaffold(
      appBar: AppBar(title: Text('WeatherFit Lite')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Enter location'),
              onSubmitted: (val) {
                city = val;
                fetchWeather();
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.my_location),
              label: Text('Use My Location'),
              onPressed: _initLocationAndFetch,
            ),
            const SizedBox(height: 20),
            if (isLoading)
              CircularProgressIndicator()
            else if (weather != null)
              Column(
                children: [
                  Text('${weather!.city}', style: TextStyle(fontSize: 24)),
                  Text('${weather!.description}, ${weather!.temperature}°C'),
                  const SizedBox(height: 10),
                  Text('Suggested Outfit:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(outfit),
                ],
              )
            else
              Text('No data'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text("Refresh"),
              onPressed: fetchWeather,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today),
                  SizedBox(width: 8),
                  Text("See 5-Day Forecast"),
                ],
              ),
              onPressed: forecast.isNotEmpty
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForecastScreen(forecast: forecast),
                        ),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// Weather Data Model 
class WeatherData {
  final String city;
  final String description;
  final double temperature;

  WeatherData({required this.city, required this.description, required this.temperature});

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      city: json['name'] ?? '',
      description: json['weather'][0]['description'],
      temperature: (json['main']['temp'] as num).toDouble(),
    );
  }
}

// Dito yung pag call ng api
class WeatherService {
  static const String apiKey = 'd267f21ecb9398aa396673c91e2efe2b'; 
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  static Future<WeatherData> fetchWeather(String city) async {
    final url = Uri.parse('$baseUrl/weather?q=$city&appid=$apiKey&units=metric');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return WeatherData.fromJson(data);
    } else {
      throw Exception('Failed to load weather');
    }
  }

  static Future<List<WeatherData>> fetchForecast(String city) async {
    final url = Uri.parse('$baseUrl/forecast?q=$city&appid=$apiKey&units=metric');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List list = data['list'];
      // Dito yung mga next day
      final forecast = list.where((item) => item['dt_txt'].contains('12:00:00')).take(5).map<WeatherData>((item) {
        return WeatherData(
          city: data['city']['name'],
          description: item['weather'][0]['description'],
          temperature: (item['main']['temp'] as num).toDouble(),
        );
      }).toList();
      return forecast;
    } else {
      throw Exception('Failed to load forecast');
    }
  }
}

// Dito yung magsasabi kung anong outfit
class OutfitAdvisor {
  static String getOutfit(WeatherData weather) {
    if (weather.temperature > 28) return 'T-shirt and shorts';
    if (weather.temperature > 20) return 'Light jacket';
    return 'Jacket and pants';
  }
}