import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Mensagens à utilizador sem depender do overlay do GetX (evita «No Overlay»).
abstract final class AppMessenger {
  static void success(String message, {String title = 'Sucesso'}) {
    _show(title: title, message: message, background: Colors.green.shade700);
  }

  static void error(String message, {String title = 'Erro'}) {
    _show(title: title, message: message, background: Colors.red.shade700);
  }

  static void info(String message, {String title = 'Atenção'}) {
    _show(title: title, message: message, background: Colors.orange.shade800);
  }

  static void _show({
    required String title,
    required String message,
    required Color background,
  }) {
    final text = title.isEmpty ? message : '$title: $message';
    final snackBar = SnackBar(
      content: Text(text, style: const TextStyle(color: Colors.white)),
      backgroundColor: background,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      duration: const Duration(seconds: 3),
    );

    for (final ctx in <BuildContext?>[
      Get.overlayContext,
      Get.context,
      Get.key.currentContext,
    ]) {
      if (ctx == null) continue;
      final messenger = ScaffoldMessenger.maybeOf(ctx);
      if (messenger != null) {
        messenger.showSnackBar(snackBar);
        return;
      }
    }

    debugPrint(text);
  }
}
