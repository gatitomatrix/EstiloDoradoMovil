import 'package:flutter/material.dart';
import '../app_router.dart';

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
    final messenger = AppRouter.scaffoldMessengerKey.currentState ??
        (context.mounted ? ScaffoldMessenger.maybeOf(context) : null);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: kind.color,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        dismissDirection: DismissDirection.down,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: kind == AppSnackKind.success
                    ? const Color(0xFF2D2418)
                    : Colors.white,
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    onAction();
                  });
                },
              )
            : null,
      ),
    );
  }

  static void hide() {
    AppRouter.scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  }

  static void ok(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) =>
      show(context, message: message, kind: AppSnackKind.success, actionLabel: actionLabel, onAction: onAction);

  static void err(BuildContext context, String message) =>
      show(context, message: message, kind: AppSnackKind.error);

  static void warn(BuildContext context, String message) =>
      show(context, message: message, kind: AppSnackKind.warning);
}

enum AppSnackKind {
  success(Color(0xFF2D2418)),
  error(Color(0xFFB42318)),
  warning(Color(0xFFB54708)),
  info(Color(0xFF2D2418));

  final Color color;
  const AppSnackKind(this.color);
}
