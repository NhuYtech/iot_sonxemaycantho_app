import 'package:flutter/material.dart';

class WarningBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const WarningBanner({super.key, required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.orange.shade100,
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.black87)),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
