// lib/features/auth/controller/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/network_exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/services/company_config_service.dart';
import '../../dashboard/controller/dashboard_controller.dart';

class AuthController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  void _showBottomSheetMessage({required bool success, required String message}) {
    Get.bottomSheet(
      Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_rounded,
                color: success ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
    );
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (Get.isOverlaysOpen == true || (Get.isBottomSheetOpen ?? false)) {
        if (Get.key.currentState?.canPop() == true) {
          Get.back();
        }
      }
    });
  }

  // ────── LOGIN ──────
  Future<void> login(String email, String password) async {
    errorMessage.value = ''; // reset

    debugPrint('🔹 Login started with email: $email');

    // ───── Local validation (user-friendly messages) ─────
    if (email.trim().isEmpty) {
      errorMessage.value = 'Please enter your email address.';
      debugPrint('⚠️ Validation failed: Email empty');
      return;
    }

    if (!GetUtils.isEmail(email.trim())) {
      errorMessage.value = 'Please enter a valid email address.';
      debugPrint('⚠️ Validation failed: Invalid email format');
      return;
    }
    if (password.isEmpty) {
      errorMessage.value = 'Please enter your password.';
      debugPrint('⚠️ Validation failed: Password empty');
      return;
    }
    if (password.length < 6) {
      errorMessage.value = 'Password must be at least 6 characters long.';
      debugPrint('⚠️ Validation failed: Password too short');
      return;
    }

    isLoading(true);
    try {
      debugPrint('🔹 Fetching ApiClient instance...');
      final api = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : ApiClient();

      debugPrint('📤 Sending login request to ${ApiEndpoints.login}');
      final res = await api.postFormData(
        ApiEndpoints.login,
        fields: {
          'email': email.trim(),
          'password': password,
        },
        requiresAuth: false,
      );

      debugPrint('📥 API Response: $res');

      if (res['success'] == true) {
        final data = (res['data'] ?? {}) as Map<String, dynamic>;
        final token = (data['access_token'] ?? data['token'] ?? '').toString();

        if (token.isEmpty) {
          errorMessage.value = 'Login succeeded but token missing in response.';
          SnackbarHelper.showError(errorMessage.value, title: 'Login');
          return;
        }

        // ✅ Save token and refresh token
        await api.saveToken(token);
        if (data['refresh_token'] != null) {
          await api.saveRefreshToken(data['refresh_token'].toString());
        }

        // ✅ Wait longer to ensure token is written to SharedPreferences
        await Future.delayed(const Duration(milliseconds: 300));

        // ✅ Verify token was saved (retry up to 3 times)
        String? savedToken;
        for (int i = 0; i < 3; i++) {
          savedToken = await api.getToken();
          if (savedToken != null && savedToken.isNotEmpty) {
            debugPrint('✅ Token verified and saved (attempt ${i + 1}): ${savedToken.substring(0, 20)}...');
            break;
          }
          debugPrint('⚠️ Token verification attempt ${i + 1} failed, retrying...');
          await Future.delayed(const Duration(milliseconds: 100));
        }

        if (savedToken == null || savedToken.isEmpty) {
          debugPrint('❌ Token verification failed after 3 attempts');
          errorMessage.value = 'Failed to save authentication token';
          SnackbarHelper.showError(errorMessage.value, title: 'Login');
          return;
        }

        // Persist basic user info for More screen
        String tenantId = '';
        try {
          final user = (data['user'] ?? {}) as Map<String, dynamic>;
          final prefs = await SharedPreferences.getInstance();
          final name = (user['name'] ?? '').toString();
          final emailResp = (user['email'] ?? '').toString();
          tenantId = user['tenant_id']?.toString() ?? '';
          await prefs.setString('user_name', name);
          await prefs.setString('user_email', emailResp);
          if (tenantId.isNotEmpty) {
            await prefs.setString('tenant_id', tenantId);
            await prefs.setString('bus_config_id', tenantId);
          }
        } catch (_) {}

        // Fetch and save company configuration
        final okConfig = await _fetchAndSaveCompanyConfig(tenantId.isNotEmpty ? tenantId : '1');

        // If configuration is not available (e.g., no active package), stop here and show message.
        if (!okConfig) {
          final msg = errorMessage.value.isNotEmpty
              ? errorMessage.value
              : 'Your business does not have an active package.';
          _showBottomSheetMessage(success: false, message: msg);
          return;
        }

        // Show success message BEFORE navigation
        _showBottomSheetMessage(success: true, message: 'User login successful');

        // Wait for snackbar to be visible
        await Future.delayed(const Duration(milliseconds: 500));

        // Navigate to dashboard
        await Get.offAllNamed(AppRoutes.dashboard);
      } else {
        errorMessage.value = res['message'] ?? 'Login failed. Please try again.';
        debugPrint('❌ Login failed: ${errorMessage.value}');
        _showBottomSheetMessage(success: false, message: errorMessage.value);
      }
    } on ValidationException catch (e) {
      errorMessage.value = e.message;
      debugPrint('⚠️ ValidationException: ${e.message}');
      _showBottomSheetMessage(success: false, message: errorMessage.value);
    } on UnauthorizedException catch (e) {
      errorMessage.value = e.message;
      debugPrint('🚫 UnauthorizedException: ${e.message}');
      _showBottomSheetMessage(success: false, message: errorMessage.value);
    } on NetworkException catch (e) {
      errorMessage.value = e.message;
      debugPrint('🌐 NetworkException: ${e.message}');
      _showBottomSheetMessage(success: false, message: errorMessage.value);
    } catch (e, stack) {
      errorMessage.value = 'Login error: ${e.toString()}';
      debugPrint('💥 Unexpected error: $e');
      debugPrint('🧩 StackTrace:\n$stack');
      _showBottomSheetMessage(success: false, message: errorMessage.value);
    } finally {
      isLoading(false);
      debugPrint('🔚 Login process finished.');
    }
  }

  // ────── FORGOT PASSWORD ──────
  Future<void> forgotPassword(String email) async {
    errorMessage.value = '';

    if (email.trim().isEmpty) {
      errorMessage.value = 'Please enter your email address.';
      return;
    }
    if (!GetUtils.isEmail(email.trim())) {
      errorMessage.value = 'Please enter a valid email address.';
      return;
    }

    isLoading(true);
    try {
      final api = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : ApiClient();
      final token = await api.getToken();
      final res = await api.postFormData(
        ApiEndpoints.forgotPassword,
        fields: {
          'email': email.trim(),
        },
        requiresAuth: token != null,
      );

      final ok = res['success'] == true;
      final msg = (res['message'] ?? 'Request processed').toString();
      if (ok) {
        Get.offNamed(AppRoutes.passwordResetSuccess, arguments: {
          'email': email.trim(),
        });

        // Show success message after navigation
        SchedulerBinding.instance.addPostFrameCallback((_) {
          SnackbarHelper.showSuccess(
              msg.isNotEmpty ? msg : 'A password reset link has been sent to your email. Please check your inbox'
          );
        });
      } else {
        errorMessage.value = msg;
        SnackbarHelper.showError(msg, title: 'Failed');
      }
    } catch (e) {
      errorMessage.value = 'Failed to send reset link. Please try again later.';
      SnackbarHelper.showError(errorMessage.value);
    } finally {
      isLoading(false);
    }
  }

  // ────── RESET PASSWORD ──────
  Future<bool> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    errorMessage.value = '';

    if (token.trim().isEmpty) {
      errorMessage.value = 'Reset token is required.';
      return false;
    }
    if (email.trim().isEmpty || !GetUtils.isEmail(email.trim())) {
      errorMessage.value = 'Valid email is required.';
      return false;
    }
    if (password.length < 6) {
      errorMessage.value = 'Password must be at least 6 characters.';
      return false;
    }
    if (password != passwordConfirmation) {
      errorMessage.value = 'Passwords do not match.';
      return false;
    }

    isLoading(true);
    try {
      final api = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : ApiClient();
      final savedToken = await api.getToken();
      final res = await api.postFormData(
        ApiEndpoints.resetPassword,
        fields: {
          'token': token.trim(),
          'email': email.trim(),
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
        requiresAuth: savedToken != null,
      );

      final ok = res['success'] == true;
      final msg = (res['message'] ?? (ok ? 'Password reset successful' : 'Password reset failed')).toString();

      if (ok) {
        SnackbarHelper.showSuccess(msg);
        return true;
      } else {
        errorMessage.value = msg;
        SnackbarHelper.showError(msg, title: 'Reset Failed');
        return false;
      }
    } on ValidationException catch (e) {
      errorMessage.value = e.message;
      SnackbarHelper.showError(e.message);
      return false;
    } on NetworkException catch (e) {
      errorMessage.value = e.message;
      SnackbarHelper.showError(e.message);
      return false;
    } catch (e) {
      errorMessage.value = 'Unexpected error: ${e.toString()}';
      SnackbarHelper.showError(errorMessage.value);
      return false;
    } finally {
      isLoading(false);
    }
  }

  // ────── FETCH AND SAVE COMPANY CONFIGURATION ──────
  Future<bool> _fetchAndSaveCompanyConfig(String busConfigId) async {
    try {
      print('📋 Fetching company configuration for bus_config_id: $busConfigId');

      final ctrl = Get.find<DashboardController>();
      final api = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : ApiClient();
      final res = await api.postFormData(
        ApiEndpoints.companyFetchConfiguration,
        fields: {'bus_config_id': busConfigId},
        requiresAuth: true,
      );

      if (res['success'] == true) {
        final config = (res['data']?['config'] ?? {}) as Map<String, dynamic>;
        print('✅ Company configuration fetched successfully');
        print('📋 Logo URL: ${config['bus_logo_url']}');

        // Save to local storage
        await CompanyConfigService.saveConfiguration(config);
        ctrl.fetchDashboard();
        return true;
      } else {
        final msg = (res['message'] ?? 'Failed to fetch company configuration').toString();
        print('⚠️ Failed to fetch company configuration: $msg');
        errorMessage.value = msg;
        return false;
      }
    } catch (e) {
      print('❌ Error fetching company configuration: $e');
      // Treat as failure and block navigation
      errorMessage.value = e.toString();
      return false;
    }
  }

  // ────── LOGOUT ──────
  Future<void> logout() async {
    try {
      final api = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : ApiClient();

      // Clear tokens
      await api.clearTokens();

      // Clear user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('tenant_id');
      await prefs.remove('bus_config_id');

      // Clear company configuration
      await CompanyConfigService.clearConfiguration();

      print('✅ Logout successful - all data cleared');

      // Show success message
      _showBottomSheetMessage(success: true, message: 'Logout successful');

      // Wait for snackbar to be visible
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to login
      await Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      print('❌ Error during logout: $e');
      _showBottomSheetMessage(success: false, message: 'Logout failed');
    }
  }
}