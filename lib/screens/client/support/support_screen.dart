import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  void _launchUrl(BuildContext context, String url) async {
    try {
      if (await canLaunch(url)) {
        await launch(url);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'ouvrir $url'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Support'),
        backgroundColor: const Color(0xFF0F056B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F056B),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                children: [
                  Icon(Icons.headset_mic, size: 50, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    'Besoin d\'aide ?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Notre équipe est à votre disposition',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nous contacter',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F056B)),
                    ),
                    const SizedBox(height: 16),
                    _buildContactItem(
                      context: context,
                      icon: Icons.phone,
                      iconColor: Colors.green,
                      title: 'Téléphone',
                      subtitle: '+221 77 123 45 67',
                      onTap: () => _launchUrl(context, 'tel:+221771234567'),
                    ),
                    _buildContactItem(
                      context: context,
                      icon: Icons.email,
                      iconColor: Colors.blue,
                      title: 'Email',
                      subtitle: 'support@catrans.sn',
                      onTap: () => _launchUrl(context, 'mailto:support@catrans.sn'),
                    ),
                    _buildContactItem(
                      context: context,
                      icon: Icons.location_on,
                      iconColor: Colors.red,
                      title: 'Adresse',
                      subtitle: 'Dakar, Sénégal',
                      onTap: () => _launchUrl(context, 'https://maps.google.com'),
                    ),
                    _buildContactItem(
                      context: context,
                      icon: Icons.chat,
                      iconColor: Colors.green,
                      title: 'WhatsApp',
                      subtitle: '+221 78 123 45 67',
                      onTap: () => _launchUrl(context, 'https://wa.me/221781234567'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}