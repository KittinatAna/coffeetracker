import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  textTheme: GoogleFonts.montserratTextTheme(),
  colorScheme: ColorScheme.light(
    surface: Colors.grey.shade400,
    primary: Colors.grey.shade300,
    secondary: Colors.grey.shade200,
  ),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  textTheme: GoogleFonts.montserratTextTheme(),
  colorScheme: ColorScheme.dark(
    surface: Colors.grey.shade700,
    primary: Colors.grey.shade600,
    secondary: Colors.grey.shade500,
  ),
);
