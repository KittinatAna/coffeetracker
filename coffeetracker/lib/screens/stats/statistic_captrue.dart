import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

class StatisticCapturePage extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String range;
  final Widget content;
  final ScreenshotController screenshotController;

  StatisticCapturePage({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.range,
    required this.content,
    required this.screenshotController,
  }) : super(key: key);

  String _getFormattedDateRange() {
    if (range == 'day') {
      DateTime startofDate = DateTime(startDate.year, startDate.month, startDate.day + 1);
      return DateFormat('d MMMM yyyy').format(startofDate);
    } else if (range == 'week') {
      DateTime startOfWeek = startDate.subtract(Duration(days: startDate.weekday - 8));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
      return '${DateFormat('d MMM').format(startOfWeek)} - ${DateFormat('d MMM yyyy').format(endOfWeek)}';
    } else if (range == 'month') {
      DateTime startOfMonth = DateTime(startDate.year, startDate.month + 2, 0);
      return DateFormat('MMMM yyyy').format(startOfMonth);
    } else if (range == 'year') {
      DateTime startOfYear = DateTime(startDate.year + 2, 1, 0);
      return DateFormat('yyyy').format(startOfYear);
    } else {
      return '';
    }
  }

  Future<void> _captureAndSave(BuildContext context) async {
    Uint8List? image = await screenshotController.capture();
    final result = await ImageGallerySaver.saveImage(image!);

    if (result['isSuccess']) {
      // print('Image saved to gallery');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Image saved to gallery',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.green,
          dismissDirection: DismissDirection.up,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 210,
            left: 15,
            right: 15,
          ),
        ),
      );
      Navigator.of(context)..pop()..pop();
    } else {
      // print('Failed to save image');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save image',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          dismissDirection: DismissDirection.up,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 210,
            left: 15,
            right: 15,
          ),
        ),
      );
    }
  }

  Future<void> _captureAndShare(BuildContext context) async {
    Uint8List? image = await screenshotController.capture();

    final directory = await getApplicationDocumentsDirectory();
    final imgFile = File('${directory.path}/statistics.png');
    await imgFile.writeAsBytes(image!);

    final XFile file = XFile(imgFile.path);
    await Share.shareXFiles([file], text: 'Here are my coffee statistics in ${_getFormattedDateRange()}');
    Navigator.of(context)..pop()..pop();
  }

  void _selectAction(BuildContext context, String action) {
    switch (action) {
      case 'download':
        _captureAndSave(context);
        break;
      case 'share':
        _captureAndShare(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Share your statistics',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Screenshot(
            controller: screenshotController,
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      _getFormattedDateRange(),
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  content,
                  const SizedBox(height: 20),
                  Center(
                    child: Text('by CoffeeTracker',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _selectAction(context, 'download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 110, 22, 240),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  fixedSize: const Size(180, 45),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Icon(Icons.download),
                      Text(
                        'Download',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _selectAction(context, 'share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 110, 22, 240),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  fixedSize: const Size(180, 45),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Icon(Icons.share_rounded),
                      Text(
                        'Share',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
