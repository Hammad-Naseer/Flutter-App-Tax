// ─────────────────────────────────────────────────────────────────────────────
// lib/core/utils/snackbar_helper.dart (SIMPLIFIED VERSION)
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';

class SnackbarHelper {
  SnackbarHelper._();

  static double _topMargin() {
    // Get.overlayContext provides a more stable context for global overlays
    final ctx = Get.overlayContext;

    // Fallback to platform view padding if Get.overlayContext is null
    final topInset = ctx != null
        ? MediaQuery.of(ctx).padding.top
        : WidgetsBinding.instance.platformDispatcher.views.first.viewPadding.top;

    return topInset + kToolbarHeight + 8;
  }

  // NOTE: _afterFrame is removed as it's not needed for simple Get.snackbar calls
  // and AuthController already handles post-navigation timing via SchedulerBinding.

  static void _show({
    required String title,
    required String message,
    required SnackPosition position,
    required EdgeInsets margin,
    Color? backgroundColor,
    Color? colorText,
    Color? borderColor,
    double? borderWidth,
    required Widget? icon,
    required Widget titleText,
    required Widget messageText,
    required Duration duration,
  }) {
    // Call Get.snackbar directly.
    // We rely on GetMaterialApp and correct usage (like SchedulerBinding)
    // from the calling context (e.g., AuthController).
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      snackStyle: SnackStyle.FLOATING,
      backgroundColor: backgroundColor,
      colorText: colorText,
      borderColor: borderColor,
      borderWidth: borderWidth ?? 0,
      borderRadius: 12,
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      icon: icon,
      titleText: titleText,
      messageText: messageText,
      duration: duration,
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOut,
      reverseAnimationCurve: Curves.easeIn,
    );
  }

  static void showSuccess(String message, {String title = 'Success'}) {
    _show(
      title: title,
      message: message,
      position: SnackPosition.TOP,
      margin: EdgeInsets.fromLTRB(12, _topMargin(), 12, 12),
      backgroundColor: const Color(0xFF2E7D32), // Green
      colorText: Colors.white,
      icon: const Padding(
        padding: EdgeInsets.only(left: 8),
        child: Icon(Icons.check_circle, color: Colors.white, size: 26),
      ),
      titleText: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
      messageText: Text(message, style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.3)),
      duration: const Duration(seconds: 3),
    );
  }

  static void showError(String message, {String title = 'Error'}) {
    // Clean common transport prefixes from message (e.g., 'Request failed: ...')
    final cleanMessage = message.replaceFirst(RegExp(r'^Request failed:\s*'), '');
    _show(
      title: title,
      message: cleanMessage,
      position: SnackPosition.TOP,
      margin: EdgeInsets.fromLTRB(12, _topMargin(), 12, 12),
      backgroundColor: AppColors.error,
      colorText: Colors.white,
      icon: const Padding(
        padding: EdgeInsets.only(left: 8),
        child: Icon(Icons.error_outline, color: Colors.white, size: 26),
      ),
      titleText: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
      messageText: Text(cleanMessage, style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.3)),
      duration: const Duration(seconds: 6),
    );
  }

  static void showInfo(String message, {String title = 'Info'}) {
    final color = Colors.blue.shade700;
    _show(
      title: title,
      message: message,
      position: SnackPosition.TOP,
      margin: EdgeInsets.fromLTRB(16, _topMargin(), 16, 16),
      backgroundColor: Colors.blue.withOpacity(0.1),
      colorText: color,
      borderColor: Colors.blue,
      borderWidth: 1,
      icon: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Icon(Icons.info_outline, color: color, size: 28),
      ),
      titleText: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
      messageText: Text(message, style: TextStyle(fontSize: 14, color: color, height: 1.3)),
      duration: const Duration(seconds: 6),
    );
  }

  static void showWarning(String message, {String title = 'Warning'}) {
    final color = Colors.orange.shade700;
    _show(
      title: title,
      message: message,
      position: SnackPosition.TOP,
      margin: EdgeInsets.fromLTRB(16, _topMargin(), 16, 16),
      backgroundColor: Colors.orange.withOpacity(0.1),
      colorText: color,
      borderColor: Colors.orange,
      borderWidth: 1,
      icon: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Icon(Icons.warning_amber_outlined, color: color, size: 28),
      ),
      titleText: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
      messageText: Text(message, style: TextStyle(fontSize: 14, color: color, height: 1.3)),
      duration: const Duration(seconds: 6),
    );
  }
}