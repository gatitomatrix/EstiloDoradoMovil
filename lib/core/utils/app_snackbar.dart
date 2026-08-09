import 'package:flutter/material.dart';

/// Feedback unificado (éxito / error / aviso) con estilo Estilo Dorado.
class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    AppSnackKind kind = AppSnackKind.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kind.color,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static void ok(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) =>
      show(context, message: message, kind: AppSnackKind.success, actionLabel: actionLabel, onAction: onAction);

  static void err(BuildContext context, String message) =>
      show(context, message: message, kind: AppSnackKind.error);

  static void warn(BuildContext context, String message) =>
      show(context, message: message, kind: AppSnackKind.warning);
}

enum AppSnackKind {
  success(Color(0xFFD4AF37)),
  error(Color(0xFFB42318)),
  warning(Color(0xFFB54708)),
  info(Color(0xFF2D2418));

  final Color color;
  const AppSnackKind(this.color);
}
