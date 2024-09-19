import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // For time formatting

void main() => runApp(WorldTimeApp());

class WorldTimeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'World Time App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _countries = [];
  String _searchQuery = '';
  String? _currentTime;
  bool _isDayTime = true;

  @override
  void initState() {
    super.initState();
    _fetchCountries();  // Fetch all available countries at the start
  }

  Future<void> _fetchCountries() async {
    final url = 'http://worldtimeapi.org/api/timezone';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> timeZones = jsonDecode(response.body);
        setState(() {
          _countries = timeZones.cast<String>();  // Cast dynamic list to String list
        });
      } else {
        print('Failed to load country list');
      }
    } catch (e) {
      print('Error fetching countries: $e');
    }
  }

  Future<void> _fetchTime(String country) async {
    final url = 'http://worldtimeapi.org/api/timezone/$country';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        DateTime dateTime = DateTime.parse(data['datetime']);
        String utcOffset = data['utc_offset'];

        // Adjust time with UTC offset
        int hoursOffset = int.parse(utcOffset.substring(1, 3));
        int minutesOffset = int.parse(utcOffset.substring(4, 6));
        if (utcOffset.startsWith('-')) {
          dateTime = dateTime.subtract(Duration(hours: hoursOffset, minutes: minutesOffset));
        } else {
          dateTime = dateTime.add(Duration(hours: hoursOffset, minutes: minutesOffset));
        }

        // Format the time to 12-hour with AM/PM
        String formattedTime = DateFormat('hh:mm a').format(dateTime);

        setState(() {
          _currentTime = formattedTime;
          _isDayTime = dateTime.hour >= 6 && dateTime.hour < 18;  // 6 AM to 6 PM is considered daytime
        });
      } else {
        setState(() {
          _currentTime = 'Failed to load time';
        });
      }
    } catch (e) {
      setState(() {
        _currentTime = 'Error fetching time';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('World Time App'),
      ),
      body: Container(
        color: _isDayTime ? Colors.white : Colors.black87,  // Change background color based on day or night
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
              ),
            ),
            Expanded(
              child: _countries.isEmpty
                  ? Center(child: CircularProgressIndicator())  // Show loading indicator while fetching data
                  : ListView.builder(
                      itemCount: _countries.length,
                      itemBuilder: (context, index) {
                        final country = _countries[index];
                        if (_searchQuery.isEmpty || country.toLowerCase().contains(_searchQuery.toLowerCase())) {
                          return ListTile(
                            title: Text(
                              country,
                              style: TextStyle(color: _isDayTime ? Colors.black : Colors.white),  // Adjust text color
                            ),
                            onTap: () => _fetchTime(country),
                          );
                        }
                        return Container();
                      },
                    ),
            ),
            if (_currentTime != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Current time: $_currentTime',
                  style: TextStyle(
                    fontSize: 20,
                    color: _isDayTime ? Colors.black : Colors.white,  // Adjust text color based on day or night
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
