import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherData {
  final String cityName;
  final double temperature;
  final String weatherCondition;
  final int humidity;
  final double windSpeed;

  WeatherData({
    required this.cityName,
    required this.temperature,
    required this.weatherCondition,
    required this.humidity,
    required this.windSpeed,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      cityName: json['name'],
      temperature: json['main']['temp'].toDouble(),
      weatherCondition: json['weather'][0]['main'],
      humidity: json['main']['humidity'],
      windSpeed: json['wind']['speed'].toDouble(),
    );
  }
}

Future<void> main() async {
  await dotenv.load(fileName: "assets/.env");
  runApp(MyApp());
}


class AppColors {
  static const Color primaryColor = Colors.deepPurple;
  static const Color accentColor = Colors.deepPurpleAccent;

  // Weather condition colors
  static Color getWeatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Colors.orange.shade300;
      case 'clouds':
        return Colors.blueGrey;
      case 'rain':
        return Colors.blue;
      case 'snow':
        return Colors.white70;
      default:
        return primaryColor;
    }
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        primarySwatch: Colors.deepPurple,

        appBarTheme: AppBarTheme(
            color: Color(0xFF0A5EB0),
            iconTheme: IconThemeData(color: Colors.white)),

        cardTheme: CardTheme(
          color: Color(0xFF80C4E9),
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> savedLocations = ['New York', 'London', 'Tokyo'];

  void _addNewLocation() async {
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                SearchScreen(savedLocations: savedLocations)));

    if (result != null) {
      setState(() {
        savedLocations.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Weather',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
              onPressed: _addNewLocation,
              icon: Icon(Icons.add, color: Colors.white))
        ],
      ),
      body: ListView.builder(
          itemCount: savedLocations.length,
          itemBuilder: (context, index) {
            return LocationWeatherCard(
              cityName: savedLocations[index],
              onRemove: (String cityToRemove) {
                setState(() {
                  savedLocations.remove(cityToRemove);
                });
              },
            );
          }),
    );
  }
}

class LocationWeatherCard extends StatefulWidget {
  final String cityName;

  final Function(String) onRemove; // Add a callback function

  const LocationWeatherCard(
      {Key? key, required this.cityName, required this.onRemove})
      : super(key: key);
  @override
  _LocationWeatherCardState createState() => _LocationWeatherCardState();
}

class _LocationWeatherCardState extends State<LocationWeatherCard> {
  WeatherData? weatherData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  void _removeLocation(String city) {
    setState(() {
      widget.onRemove(widget.cityName);
    });
  }

  Future<void> fetchWeather() async {
   final apiKey = dotenv.env['API_KEY'];


    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=${widget.cityName}&appid=$apiKey&units=metric';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          weatherData = WeatherData.fromJson(jsonDecode(response.body));
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching weather: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Card(
      child: ListTile(
        title: Text(
          weatherData!.cityName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
            '${weatherData!.temperature}°C , ${weatherData!.weatherCondition}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${weatherData!.humidity}% Humidity',
                style: TextStyle(fontSize: 14)),
            SizedBox(
              height: 15,
            ),
            IconButton(
              icon: Icon(Icons.delete,
                  color: const Color.fromARGB(255, 247, 68, 55)),
              onPressed: () {
                // Add remove logic here
                // Example:
                _removeLocation(weatherData!.cityName);
              },
            )
          ],
        ),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      DetailWeatherScreen(weatherData: weatherData!)));
        },
      ),
    );
  }
}

class DetailWeatherScreen extends StatelessWidget {
  final WeatherData weatherData;

  const DetailWeatherScreen({super.key, required this.weatherData});


  
  @override
  Widget build(BuildContext context) {
    Color backgroundColor =
        AppColors.getWeatherColor(weatherData.weatherCondition);
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(weatherData.cityName,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${weatherData.temperature}°C',
              style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
            ),
            Text(
              weatherData.weatherCondition,
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Icon(Icons.water_drop),
                    SizedBox(height: 10),
                    Text(
                      '${weatherData.humidity}%',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      'Humidity',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.air),
                    SizedBox(height: 10),
                    Text(
                      '${weatherData.windSpeed} m/s',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      'Wind Speed',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  final List<String> savedLocations;

  SearchScreen({required this.savedLocations});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  WeatherData? searchedWeatherData;

  void searchCity() async {
    final apiKey = dotenv.env['API_KEY'];

    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=${_searchController.text}&appid=$apiKey&units=metric';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          searchedWeatherData = WeatherData.fromJson(jsonDecode(response.body));
        });
      }
    } catch (e) {
      debugPrint('Error searching weather: $e');
    }
  }

  void addCity() {
    if (searchedWeatherData != null) {
      if (!widget.savedLocations.contains(searchedWeatherData!.cityName)) {
        Navigator.pop(context, searchedWeatherData!.cityName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('City already exists in saved locations')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search City',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter city name',
                suffixIcon: IconButton(
                  onPressed: searchCity,
                  icon: Icon(Icons.search),
                ),
              ),
            ),
          ),
          // Conditionally rendering the Card only when searchedWeatherData is not null
          if (searchedWeatherData != null)
            Card(
              child: ListTile(
                title: Text(searchedWeatherData!.cityName,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    '${searchedWeatherData!.temperature}°C , ${searchedWeatherData!.weatherCondition}'),
                trailing: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: addCity,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailWeatherScreen(
                          weatherData: searchedWeatherData!),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
