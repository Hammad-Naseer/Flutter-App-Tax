// ─────────────────────────────────────────────────────────────────────────────
// lib/main.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_routes.dart';
import 'features/auth/controller/auth_controller.dart';
import 'routes/app_pages.dart';
import 'di/injection_container.dart';
import 'core/utils/snackbar_helper.dart';

Future<void> main() async {
  // Ensure plugins (e.g., shared_preferences) are registered before use
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences early to avoid platform channel errors
  try {
    await SharedPreferences.getInstance();
    debugPrint('✅ SharedPreferences initialized successfully');
  } catch (e) {
    debugPrint('⚠️ SharedPreferences initialization error: $e');
  }

  // Register AuthController once
  final ctrl = Get.put(AuthController(), permanent: true);

  // Initialize other controllers/services
  InjectionContainer.init();

  // ───── GLOBAL ERROR SNACKBAR LISTENER (runs once) ─────
  ever(ctrl.errorMessage, (msg) {
    if (msg.isNotEmpty) {
      try {
        // Only try to show snackbar when an overlay context is available
        if (Get.overlayContext != null) {
          SnackbarHelper.showError(msg, title: 'Login Error');
        } else {
          debugPrint('⚠️ Unable to show snackbar (no overlay). Error: $msg');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to show error snackbar: $e');
      } finally {
        // Clear the message after a short delay so it doesn't re-trigger
        Future.delayed(const Duration(seconds: 4), () {
          if (ctrl.errorMessage.value == msg) {
            ctrl.errorMessage.value = '';
          }
        });
      }
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.error,
        surface: AppColors.background,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.textPrimary),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        errorStyle: const TextStyle(color: AppColors.error),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.green;
          return Colors.grey.shade400;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );

    return GetMaterialApp(
      title: 'TaxBridge',
      theme: theme,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
    );
  }
}