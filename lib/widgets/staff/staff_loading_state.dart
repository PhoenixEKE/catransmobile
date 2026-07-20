import 'package:flutter/material.dart';

class StaffLoadingState extends StatelessWidget {
  final String message;

  const StaffLoadingState({super.key, this.message = 'Chargement...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(message),
        ],
      ),
    );
  }
}
