import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input_field.dart';
import '../controller/auth_controller.dart';

class ResetPasswordScreen extends StatelessWidget {
  ResetPasswordScreen({Key? key}) : super(key: key);

  final _auth = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();

  final _tokenCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _pwd2Ctrl = TextEditingController();

  final _obscure1 = true.obs;
  final _obscure2 = true.obs;

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final passedEmail = (args != null ? args['email'] : null)?.toString();
    if (passedEmail != null && passedEmail.isNotEmpty && _emailCtrl.text.isEmpty) {
      _emailCtrl.text = passedEmail;
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Enter the token from your email and set a new password',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Token', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              AppInputField(
                                label: 'Token',
                                hint: 'Paste the token you received',
                                controller: _tokenCtrl,
                                prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Token is required' : null,
                              ),
                              const SizedBox(height: 16),

                              const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              AppInputField(
                                label: 'Email',
                                hint: 'Enter your email',
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Email is required'
                                    : !GetUtils.isEmail(v.trim())
                                        ? 'Invalid email'
                                        : null,
                              ),
                              const SizedBox(height: 16),

                              const Text('New Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Obx(() => AppInputField(
                                    label: 'New Password',
                                    hint: 'Enter new password',
                                    controller: _pwdCtrl,
                                    obscureText: _obscure1.value,
                                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscure1.value ? Icons.visibility_off : Icons.visibility),
                                      onPressed: _obscure1.toggle,
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Password is required'
                                        : v.length < 6
                                            ? 'Minimum 6 characters'
                                            : null,
                                  )),
                              const SizedBox(height: 16),

                              const Text('Confirm Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Obx(() => AppInputField(
                                    label: 'Confirm Password',
                                    hint: 'Re-enter new password',
                                    controller: _pwd2Ctrl,
                                    obscureText: _obscure2.value,
                                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscure2.value ? Icons.visibility_off : Icons.visibility),
                                      onPressed: _obscure2.toggle,
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Please confirm password'
                                        : v != _pwdCtrl.text
                                            ? 'Passwords do not match'
                                            : null,
                                  )),
                              const SizedBox(height: 24),

                              Obx(() => AppButton(
                                    label: 'Reset Password',
                                    isLoading: _auth.isLoading.value,
                                    onPressed: () async {
                                      if (_formKey.currentState?.validate() != true) return;
                                      final ok = await _auth.resetPassword(
                                        token: _tokenCtrl.text.trim(),
                                        email: _emailCtrl.text.trim(),
                                        password: _pwdCtrl.text,
                                        passwordConfirmation: _pwd2Ctrl.text,
                                      );
                                      if (ok) {
                                        await Future.delayed(const Duration(milliseconds: 500));
                                        Get.offAllNamed(AppRoutes.login);
                                      }
                                    },
                                  )),
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton(
                                  onPressed: () => Get.back(),
                                  child: const Text('Back', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
