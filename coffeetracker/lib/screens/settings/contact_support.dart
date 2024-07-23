import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class ContactSupportPage extends StatelessWidget {
  final String email = 'kittinat.anatham@gmail.com';
  final String github = 'https://github.com/KittinatAna/coffeetracker';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contact and Support',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Contact Information'),
            _buildSectionContent('For privacy-related questions or concerns, please contact us via the following methods:'),
            _buildContactInfo(Icons.email, 'Email', email, () {
              Clipboard.setData(ClipboardData(text: email));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email address copied to clipboard')),
              );
            }),
            _buildContactInfo(Icons.link, 'GitHub', github, () {
              Clipboard.setData(ClipboardData(text: github));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('GitHub link copied to clipboard')),
              );
            }),
          ],
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

  Widget _buildContactInfo(IconData icon, String title, String info, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.black54),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          info,
          style: GoogleFonts.montserrat(
            fontSize: 16,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
