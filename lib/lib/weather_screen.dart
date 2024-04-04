import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:material_symbols_icons/symbols.dart';

import 'package:weather_app/additional_info_item.dart';
import 'package:weather_app/hourly_forecast_item.dart';
import 'package:weather_app/secrets.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<List<Map>> weather;
  late DateTime lastCalled;

  Future<List<Map>> getWeatherData() async {
    try {
      String cityName = "Bhatpara";
      String countyCode = "in";
      Uri weatherUrl = Uri.parse(
          "https://api.openweathermap.org/data/2.5/weather?q=$cityName,$countyCode&APPID=$apiKey");
      Uri forecastUrl = Uri.parse(
          "https://api.openweathermap.org/data/2.5/forecast?q=$cityName,$countyCode&APPID=$apiKey");

      final weather = await http.get(weatherUrl);
      final forecast = await http.get(forecastUrl);
      final weatherData = jsonDecode(weather.body);
      final forecastData = jsonDecode(forecast.body);

      if (weatherData["cod"] != 200 && forecastData["cod"] != "200") {
        throw "An unexpected error has occurred";
      }

      return [weatherData, forecastData];
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    weather = getWeatherData();
    lastCalled = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, IconData> iconMap = Map.of({
      "Clear": Symbols.sunny,
      "Clouds": Symbols.cloud,
      "Rain": Symbols.rainy,
      "Thunderstorm": Symbols.thunderstorm,
      "Snow": Symbols.ac_unit,
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Weather Report",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              if (lastCalled.difference(DateTime.now()).inSeconds >= 30) {
                setState(() {
                  weather = getWeatherData();
                });
              }
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder(
          future: weather,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation(Colors.white54),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  snapshot.error.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              );
            } else {
              final currentWeatherData = snapshot.data![0];
              final forecastWeatherData = snapshot.data![1]["list"];

              final double currentTemp =
                  currentWeatherData["main"]["temp"] - 273;
              final String currentSky =
                  currentWeatherData["weather"][0]["main"];
              final int humidity = currentWeatherData["main"]["humidity"];
              final int pressure = currentWeatherData["main"]["pressure"];
              final double windSpeed =
                  currentWeatherData["wind"]["speed"] * 3.6;
              final String sunrise = TimeOfDay.fromDateTime(
                      DateTime.fromMillisecondsSinceEpoch(
                          currentWeatherData["sys"]["sunrise"] * 1000 + 19800,
                          isUtc: false))
                  .format(context);

              final String sunset = TimeOfDay.fromDateTime(
                      DateTime.fromMillisecondsSinceEpoch(
                          currentWeatherData["sys"]["sunset"] * 1000 + 19800,
                          isUtc: false))
                  .format(context);

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Card
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 10,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(16)),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 10,
                              sigmaY: 10,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    "${currentTemp.toStringAsFixed(0)}°C",
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  Icon(
                                    iconMap.containsKey(currentSky)
                                        ? iconMap[currentSky]
                                        : Icons.waves,
                                    fill: 1,
                                    grade: 200,
                                    weight: 500,
                                    size: 72,
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  Text(
                                    currentSky,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "24-Hour Forecast",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    // Forecast Cards
                    //
                    SizedBox(
                      height: 125,
                      child: ListView.builder(
                        itemCount: 8,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final forecastData = forecastWeatherData[index];
                          return HourlyForecastItem(
                            time: TimeOfDay.fromDateTime(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        forecastData["dt"] * 1000 + 19800,
                                        isUtc: false))
                                .format(context),
                            icon: iconMap.containsKey(
                                    forecastData["weather"][0]["main"])
                                ? iconMap[forecastData["weather"][0]["main"]]!
                                : Icons.waves,
                            temp: forecastData["main"]["temp"] - 273,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Additional Information
                    const Text(
                      "Additional Information",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            AdditionalInfoItem(
                              icon: Icons.water_drop,
                              label: "Humidity",
                              value: "$humidity %",
                            ),
                            AdditionalInfoItem(
                              icon: Icons.air,
                              label: "Wind Speed",
                              value: "${windSpeed.toStringAsFixed(1)} km/h",
                            ),
                            AdditionalInfoItem(
                              icon: Symbols.thermostat,
                              label: "Pressure",
                              value: "$pressure mb",
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            AdditionalInfoItem(
                              icon: Symbols.wb_sunny,
                              label: "Sunrise at",
                              value: sunrise,
                            ),
                            AdditionalInfoItem(
                              icon: Symbols.wb_twilight,
                              label: "Sunset at",
                              value: sunset,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
          }),
    );
  }
}
