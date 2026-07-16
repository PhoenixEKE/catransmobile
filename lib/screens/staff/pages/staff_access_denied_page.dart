import 'package:flutter/material.dart';

class StaffAccessDeniedPage extends StatelessWidget {
  const StaffAccessDeniedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Accès personnel indisponible. Veuillez vous reconnecter.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
