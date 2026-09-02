import 'package:flutter/material.dart';

class GlobalDialogs {
  static void showMessage(BuildContext context, String title, String message, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.info_outline,
                color: isError ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static void showError(BuildContext context, String message) {
    showMessage(context, 'Error', message, isError: true);
  }

  static void showSuccess(BuildContext context, String message) {
    showMessage(context, 'Success', message, isError: false);
  }

  static Future<bool> showConfirm(BuildContext context, String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
