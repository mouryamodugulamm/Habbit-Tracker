import 'package:flutter/material.dart';

/// Unified snackbar styling: floating, rounded, theme-aware.
/// Use [success], [error], and [withAction] instead of raw [SnackBar].
abstract final class AppSnackbars {
  AppSnackbars._();

  static const double _radius = 10;

  static const _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(_radius)),
  );

  /// Success or neutral message (uses theme surface).
  static void success(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: _shape,
      ),
    );
  }

  /// Error message (uses theme error color).
  static void error(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: scheme.onError)),
        behavior: SnackBarBehavior.floating,
        shape: _shape,
        backgroundColor: scheme.error,
      ),
    );
  }

  /// Snackbar with an action button (e.g. Undo). [duration] defaults to 3 seconds.
  static void withAction(
    BuildContext context, {
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: _shape,
        duration: duration,
        action: SnackBarAction(
          label: actionLabel,
          onPressed: onAction,
        ),
      ),
    );
  }
}
