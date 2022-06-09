import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int temperature = 0;
  String location = "Jakarta";
  int woeid = 1047378;

  String errorMessage = '';

  String weather = "clear";

  String abbreviation = 'c';

  var minTemp = List.filled(7, 0);
  var maxTemp = List.filled(7, 0);

  var abbreviationForecast = List.filled(7, 'c');

  String searchApiUrl =
      "https://www.metaweather.com/api/location/search/?query=";

  String locationApiUrl = "https://www.metaweather.com/api/location/";

  @override
  void initState() {
    super.initState();
    fetchLocation();
    fetchLocationDay();
  }

  void fetchSearch(String input) async {
    try {
      var searchResult = await http.get(Uri.parse(searchApiUrl + input));
      var result = jsonDecode(searchResult.body)[0];

      setState(() {
        location = result["title"];
        woeid = result["woeid"];
      });
    } catch (e) {
      setState(() {
        errorMessage = "Location not found";
      });
    }
  }

  Future<void> fetchLocation() async {
    var locationResult =
        await http.get(Uri.parse(locationApiUrl + woeid.toString()));
    var result = jsonDecode(locationResult.body);
    var consolidatedWeather = result["consolidated_weather"];
    var data = consolidatedWeather[0];

    setState(() {
      temperature = data['the_temp'].round();
      weather = data['weather_state_name'].replaceAll(' ', '').toLowerCase();
      abbreviation = data['weather_state_abbr'];
    });
  }

  void fetchLocationDay() async {
    var today = DateTime.now();
    for (var i = 0; i < 7; i++) {
      var locationDayResult = await http.get(Uri.parse(locationApiUrl +
          woeid.toString() +
          '/' +
          DateFormat('y/M/d').format(today.add(Duration(days: i + 1)))));

      var result = json.decode(locationDayResult.body);
      var data = result[0];

      setState(() {
        minTemp[i] = data['min_temp'].round();
        maxTemp[i] = data['max_temp'].round();
        abbreviationForecast[i] = data['weather_state_abbr'];
      });
    }
  }

  void onTextFieldSubmitted(String input) async {
    fetchSearch(input);
    fetchLocation();
    fetchLocationDay();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/$weather.png"), 
            fit: BoxFit.cover, 
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.4), BlendMode.dstATop
            )
          )
      ),
      child: temperature == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Scaffold(
            resizeToAvoidBottomInset: false,
              backgroundColor: Colors.transparent,
              body: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Center(
                        child: Image.network(
                          'https://www.metaweather.com/static/img/weather/png/$abbreviation.png',
                          width: 100,
                        ),
                      ),
                      Center(
                        child: Text(
                          temperature.toString() + " ˚C",
                            style: const TextStyle(
                                fontSize: 60, color: Colors.white)),
                      ),
                      Center(
                        child: Text(
                          location,
                          style: const TextStyle(
                              fontSize: 40, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        forecastElement(1, abbreviationForecast[1], maxTemp[1], minTemp[1]),
                        forecastElement(2, abbreviationForecast[2], maxTemp[2], minTemp[2]),
                        forecastElement(3, abbreviationForecast[3], maxTemp[3], minTemp[3]),
                        forecastElement(4, abbreviationForecast[4], maxTemp[4], minTemp[4]),
                        forecastElement(5, abbreviationForecast[5], maxTemp[5], minTemp[5]),
                        forecastElement(6, abbreviationForecast[6], maxTemp[6], minTemp[6]),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      SizedBox(
                        width: 300,
                        child: TextField(
                          onSubmitted: (String input) {
                            errorMessage = '';
                            onTextFieldSubmitted(input.toLowerCase());
                          },
                          style: const TextStyle(
                              color: Colors.white, fontSize: 25),
                          decoration: const InputDecoration(
                              hintText: 'Search Location...',
                              hintStyle:
                                  TextStyle(color: Colors.white, fontSize: 16),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.white,
                              )),
                        ),
                      ),
                      Text(errorMessage,
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: Platform.isAndroid ? 15 : 20))
                    ],
                  )
                ],
              ),
            ),
    );
  }
}

Widget forecastElement(daysFromNow, abbr, maxTemp, minTemp) {
  var now = DateTime.now();
  var oneDayFromNow = now.add(Duration(days: daysFromNow));

  return Padding(
    padding: const EdgeInsets.only(left: 12),
    child: Container(
      decoration: BoxDecoration(
          color: const Color.fromRGBO(205, 212, 228, 0.2),
          borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(DateFormat.E().format(oneDayFromNow),
                style: const TextStyle(color: Colors.white, fontSize: 25)),
            Text(
              DateFormat.MMMd().format(oneDayFromNow),
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              child: Image.network(
                'https://www.metaweather.com/static/img/weather/png/$abbr.png',
                width: 50,
              ),
            ),
            Text(
              "High: " + maxTemp.toString() + " ˚C",
              style: const TextStyle(
                fontSize: 15, color: Colors.white
                )
            ),
            Text(
              "Low: " + minTemp.toString() + " ˚C",
              style: const TextStyle(
                fontSize: 15, color: Colors.white
                )
            )
          ],
        ),
      ),
    ),
  );
}
