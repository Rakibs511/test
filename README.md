```python
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;  // For making API requests
import 'dart:convert';  // For decoding JSON data
import 'package:intl/intl.dart';  // For formatting dates and times

void main() => runApp(WorldTimeApp());  // Entry point of the app

class WorldTimeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,  // Hides the debug banner in the top right corner
      title: 'World Time App',
      theme: ThemeData(
        primarySwatch: Colors.blue,  // Sets the primary color for the app
      ),
      home: HomeScreen(),  // HomeScreen is the first screen of the app
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();  // Creates a mutable state
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _countries = [];  // Stores the list of available countries (time zones)
  String _searchQuery = '';  // Stores the search query for filtering countries
  String? _currentTime;  // Stores the current time of the selected country
  String? _currentDate;  // Stores the current date of the selected country
  bool _isDayTime = true;  // Determines if it's day or night based on the time

  @override
  void initState() {
    super.initState();
    _fetchCountries();  // Fetches the list of available time zones when the screen loads
  }

  // Function to fetch the list of time zones from the API
  Future<void> _fetchCountries() async {
    final url = 'http://worldtimeapi.org/api/timezone';  // World Time API endpoint for all time zones
    try {
      final response = await http.get(Uri.parse(url));  // Make an API request
      if (response.statusCode == 200) {
        // If request is successful (status 200), parse the response
        final List<dynamic> timeZones = jsonDecode(response.body);
        setState(() {
          _countries = timeZones.cast<String>();  // Convert dynamic list to a list of strings (country names)
        });
      } else {
        print('Failed to load country list');  // Error message if request fails
      }
    } catch (e) {
      print('Error fetching countries: $e');  // Catch and print any errors
    }
  }

  // Function to fetch the current time for a specific country
  Future<void> _fetchTime(String country) async {
    final url = 'http://worldtimeapi.org/api/timezone/$country';  // API endpoint for a specific time zone
    try {
      final response = await http.get(Uri.parse(url));  // Make an API request
      if (response.statusCode == 200) {
        // If the request is successful, parse the response
        final data = jsonDecode(response.body);
        DateTime dateTime = DateTime.parse(data['datetime']);  // Parse the 'datetime' from the response
        String utcOffset = data['utc_offset'];  // Extract the UTC offset for time zone adjustment

        // Adjust the time with the UTC offset
        int hoursOffset = int.parse(utcOffset.substring(1, 3));  // Get the hours part of the offset
        int minutesOffset = int.parse(utcOffset.substring(4, 6));  // Get the minutes part of the offset
        if (utcOffset.startsWith('-')) {
          // If the offset is negative, subtract it from the current time
          dateTime = dateTime.subtract(Duration(hours: hoursOffset, minutes: minutesOffset));
        } else {
          // If the offset is positive, add it to the current time
          dateTime = dateTime.add(Duration(hours: hoursOffset, minutes: minutesOffset));
        }

        // Format the time into 12-hour format with AM/PM
        String formattedTime = DateFormat('hh:mm a').format(dateTime);
        // Format the date to show day of the week, month, day, and year
        String formattedDate = DateFormat('EEEE, MMM d, y').format(dateTime);

        // Update the state with the current time, date, and day/night status
        setState(() {
          _currentTime = formattedTime;  // Display the formatted time
          _currentDate = formattedDate;  // Display the formatted date
          // Determine if it's day (6 AM to 6 PM) or night
          _isDayTime = dateTime.hour >= 6 && dateTime.hour < 18;
        });
      } else {
        setState(() {
          _currentTime = 'Failed to load time';  // If the request fails, show an error message
        });
      }
    } catch (e) {
      setState(() {
        _currentTime = 'Error fetching time';  // Catch any error and update the message
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('World Time App'),  // App bar title
      ),
      body: Container(
        color: _isDayTime ? Colors.white : Colors.black87,  // Change background color based on day/night
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search country...',  // Placeholder for the search input
                  border: OutlineInputBorder(),
                ),
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;  // Update the search query in real-time
                  });
                },
              ),
            ),
            // The list of countries with search functionality
            Expanded(
              child: _countries.isEmpty
                  ? Center(child: CircularProgressIndicator())  // Show loading indicator if countries are not loaded yet
                  : ListView.builder(
                      itemCount: _countries.length,  // Number of countries in the list
                      itemBuilder: (context, index) {
                        final country = _countries[index];  // Get the country at the current index
                        // If the search query matches or is empty, display the country
                        if (_searchQuery.isEmpty || country.toLowerCase().contains(_searchQuery.toLowerCase())) {
                          return ListTile(
                            title: Text(
                              country,
                              style: TextStyle(color: _isDayTime ? Colors.black : Colors.white),  // Adjust text color based on day/night
                            ),
                            onTap: () => _fetchTime(country),  // When tapped, fetch the current time for the country
                          );
                        }
                        return Container();  // If the search query doesn't match, return an empty container
                      },
                    ),
            ),
            // Display the current time and date if available
            if (_currentTime != null && _currentDate != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Current time: $_currentTime',  // Show the current time
                      style: TextStyle(
                        fontSize: 20,
                        color: _isDayTime ? Colors.black : Colors.white,  // Adjust text color based on day/night
                      ),
                    ),
                    SizedBox(height: 10),  // Add some space between time and date
                    Text(
                      'Current date: $_currentDate',  // Show the current date
                      style: TextStyle(
                        fontSize: 18,
                        color: _isDayTime ? Colors.black : Colors.white,  // Adjust text color based on day/night
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

```

# Key Explanations:
- intl Package: This package is used to format the date and time. The DateFormat class allows you to format the date and time in the desired way (e.g., hh:mm a for time with AM/PM, and EEEE, MMM d, y for the full date).

- API Call for Countries:

- The http.get() function is used to make a request to the World Time API. This fetches the list of time zones (_fetchCountries()) or the current time for a specific country (_fetchTime()).
Handling Time Zones:

- The utc_offset returned by the API is used to adjust the time appropriately for each country. The offset can be positive or negative, and the code adjusts the dateTime accordingly.
Day/Night Detection:

- The app determines whether it's daytime or nighttime based on the hour of the returned dateTime. It considers the time between 6 AM and 6 PM as daytime. The background color and text color are adjusted accordingly.
Search Functionality:

- The search bar allows users to filter the list of countries based on their search input. It uses a TextField to capture input, and the ListView.builder() shows countries that match the query.
Displaying Time and Date:

- After fetching the time for a selected country, the app displays both the current time (with AM/PM) and the current date on the screen.
