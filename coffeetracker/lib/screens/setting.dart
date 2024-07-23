import 'package:coffeetracker/screens/calendar.dart';
import 'package:coffeetracker/screens/home.dart';
import 'package:coffeetracker/screens/stats/statistic.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class NoTransitionPageRoute<T> extends MaterialPageRoute<T> {
  NoTransitionPageRoute({required WidgetBuilder builder}) : super(builder: builder);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkTheme = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Settings',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
                        child: Text('Application',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Future Development
                  // _buildSettingsOption(
                  //   icon: Icons.person,
                  //   title: 'Account',
                  //   trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 20),
                  //   onTap: () {
                  //     // Navigate to account settings page
                  //   },
                  // ),
                  // _buildSettingsOption(
                  //   icon: Icons.coffee_rounded,
                  //   title: 'Your Coffee',
                  //   trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 20),
                  //   onTap: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (context) => CoffeeSelectionPage()),
                  //     );
                  //   },
                  // ),
                  _buildSettingsOption(
                    icon: Icons.dark_mode,
                    title: 'Dark Mode',
                    trailing: Switch(
                      // activeColor: Colors.white,
                      value: isDarkTheme,
                      onChanged: (value) {
                        setState(() {
                          isDarkTheme = value;
                          // Add your notification toggle logic here
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
                        child: Text('Support',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildSettingsOption(
                    icon: Icons.lock,
                    title: 'Privacy & Security',
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 20),
                    onTap: () {
                      // Navigate to privacy & security settings page
                    },
                  ),
                  _buildSettingsOption(
                    icon: Icons.help,
                    title: 'Contact and Support',
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 20),
                    onTap: () {
                      // Navigate to help and support page
                    },
                  ),
                  _buildSettingsOption(
                    icon: Icons.feedback,
                    title: 'Feedback',
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 20),
                    onTap: () {
                      // Navigate to privacy & security settings page
                    },
                  ),
                  _buildSettingsOption(
                    icon: Icons.info,
                    title: 'About',
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 20),
                    onTap: () {
                      // Navigate to about page
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
        currentIndex: 3,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (int index) {
          setState(() {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                NoTransitionPageRoute(builder: (context) => const Home()),
              );
            } else if (index == 1) {
              Navigator.pushReplacement(
                context,
                NoTransitionPageRoute(builder: (context) => CalendarPage()),
              );
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                NoTransitionPageRoute(builder: (context) => StatisticPage()),
              );
            }
          });
        },
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required Widget trailing,
    void Function()? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.black54),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}