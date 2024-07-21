import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coffeetracker/screens/welcome.dart';
import 'package:coffeetracker/screens/home.dart';
import 'package:coffeetracker/screens/addcoffee/choose_coffee.dart';
import 'package:coffeetracker/screens/calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const CoffeeTrackerApp());
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
}

class CoffeeTrackerApp extends StatelessWidget {
  const CoffeeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoffeeTracker',
      theme: ThemeData(
        // primarySwatch: Colors.brown,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.montserratTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const Welcome(),
        '/home': (context) => const Home(),
        '/choose-coffee': (context) => const ChooseCoffee(),
        '/calendar': (context) => CalendarPage(),
      },
    );
  }
}
