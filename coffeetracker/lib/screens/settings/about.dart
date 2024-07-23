import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Image.asset('assets/logo.png',height: 200),
              ),
              Center(
                child: Text(
                  'CoffeeTracker',
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'CoffeeTracker is an application designed to help users track their coffee buying and drinking habits. Recognizing that buying coffee in cafes can be both expensive and addictive, this app aims to provide a seamless and efficient way for users to log their coffee purchases and homemade coffee consumption.',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'The primary objectives of this project include:',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildBulletPoint(
                'User-Friendly Interface: Ensuring the interface is quick, fluid, and easy to use, allowing users to effortlessly record their coffee purchases, specify the type (e.g., espresso, latte), the shop, and the price.',
              ),
              _buildBulletPoint(
                'Comprehensive Tracking: Enabling users to log both cafe-bought and homemade coffee, providing a complete overview of their coffee consumption.',
              ),
              _buildBulletPoint(
                'Reporting and Insights: Offering robust reporting features that summarize coffee consumption and expenditure over different time periods (week, month, year), helping users understand their habits and manage their spending.',
              ),
              _buildBulletPoint(
                'Advanced Features: Exploring additional features such as detecting the user\'s location via GPS to automatically identify coffee shops, and the potential to upload summary data to a web service in CSV file for further analysis.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.montserrat(
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
