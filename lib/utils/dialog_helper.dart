import 'package:flutter/material.dart';

class DialogHelper {
  static void showMessage(
    BuildContext context,
    String message, {
    String title = 'Thông báo',
    bool isError = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    showMessage(context, message, title: 'Thành công', isError: false);
  }

  static void showError(BuildContext context, String message) {
    showMessage(context, message, title: 'Lỗi', isError: true);
  }
}
