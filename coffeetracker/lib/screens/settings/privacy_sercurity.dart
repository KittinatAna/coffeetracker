import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacySecurityPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy & Security',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildSectionContent(
                'Welcome to CoffeeTracker, your personal assistant for tracking your coffee purchases and consumption. We take your privacy and security seriously and want to ensure you understand how we collect, use, and protect your data.'
              ),
              _buildSectionTitle('Data Collection'),
              _buildSectionContent(
                'We collect data directly from you through the CoffeeTracker app, including details about your coffee purchases such as the type of coffee (espresso, latte, etc.), the coffee shop, and the price. Additionally, we may collect location data when you record a coffee purchase to enhance the accuracy of the records.',
              ),
              _buildSectionTitle('Data Usage'),
              _buildSectionContent(
                'The data collected is used solely within the CoffeeTracker app to provide you with a better user experience. This includes:\n- Improving the app\'s functionality and user interface.\n- Displaying historical records of your coffee purchases.\n- Summarizing your coffee consumption in the form of statistics and insights.',
              ),
              _buildSectionTitle('Data Sharing'),
              _buildSectionContent(
                'Currently, we do not share your data with any third parties. Your data is used exclusively for the purposes described in this privacy policy.',
              ),
              _buildSectionTitle('Data Storage'),
              _buildSectionContent(
                'Your data is securely stored on cloud storage services provided by Firebase. To enhance security, we do not store your device ID; instead, we use a hashed UUID (Universally Unique Identifier) to maintain your anonymity and protect your personal information.',
              ),
              _buildSectionTitle('User Rights'),
              _buildSectionContent(
                'You have full control over your data within the CoffeeTracker app. You can:\n- Access your coffee purchase records.\n- Update any existing records.\n- Delete any records you no longer wish to keep.',
              ),
              _buildSectionTitle('Tracking'),
              _buildSectionContent(
                'We use tracking technologies solely to improve the CoffeeTracker app. We do not track your activities beyond the necessary scope for enhancing app functionality and user experience.',
              ),
              _buildSectionTitle('Contact Information'),
              _buildSectionContent(
                'If you have any questions or concerns about your privacy and security, please feel free to reach out to us. We are here to support you and address any issues you may have. You can contact us via email or GitHub.\n\nEmail: kittinat.anatham@gmail.com\nGitHub: https://github.com/KittinatAna/coffeetracker',
              ),
              _buildSectionTitle('Policy Updates'),
              _buildSectionContent(
                'We may update this privacy policy from time to time to reflect changes in our practices or for other operational, legal, or regulatory reasons. We will notify you of any significant changes through the app. We encourage you to review this policy periodically.',
              ),
              _buildSectionContent(
                'Thank you for using CoffeeTracker. We are committed to protecting your privacy and ensuring the security of your data.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Text(
        content,
        style: GoogleFonts.montserrat(
          fontSize: 16,
        ),
      ),
    );
  }
}
