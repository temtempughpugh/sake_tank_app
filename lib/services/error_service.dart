// lib/services/error_service.dart - エラーハンドリングの一元化
import 'package:flutter/material.dart';

class ErrorService {
  // エラーダイアログ表示
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  // 成功メッセージ表示
  static void showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // 警告メッセージ表示
  static void showWarningMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange,
      ),
    );
  }
  
  // ロギング（本番環境ではより高度なロギングシステムに置き換える）
  static void logError(String error, [StackTrace? stackTrace]) {
    print('エラー: $error');
    if (stackTrace != null) {
      print('StackTrace: $stackTrace');
    }
  }
}