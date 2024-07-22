import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';

class StatisticCapturePage extends StatelessWidget {
  final String range;
  final Widget content;
  final ScreenshotController screenshotController;

  StatisticCapturePage({
    required this.range,
    required this.content,
    required this.screenshotController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Statistics Capture',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Screenshot(
        controller: screenshotController,
        child: content,
      ),
    );
  }
}
