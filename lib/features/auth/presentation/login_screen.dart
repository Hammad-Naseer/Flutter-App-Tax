// ─────────────────────────────────────────────────────────────────────────────
// lib/features/auth/presentation/login_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/app_input_field.dart';
import '../controller/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();
    final emailCtrl = TextEditingController();
    final pwdCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final remember = false.obs;
    final obscurePwd = true.obs;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallHeight = constraints.maxHeight < 700;
            final headerTop = isSmallHeight ? 24.0 : 40.0;
            final headerBottom = isSmallHeight ? 20.0 : 32.0;
            final logoHeight = isSmallHeight ? 90.0 : 120.0;
            final titleFontSize = isSmallHeight ? 22.0 : 26.0;
            final headerToCardSpacing = isSmallHeight ? 24.0 : 48.0;
            final cardPadding = EdgeInsets.all(isSmallHeight ? 16 : 20);
            // Extra bottom spacing so the card clearly sits above the system bottom bar on real devices
            final cardBottomSpacing = isSmallHeight ? 56.0 : 72.0;

            // Only allow scroll when keyboard is visible to avoid tiny scroll on some physical devices
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            final scrollPhysics = bottomInset > 0
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics();

            return SingleChildScrollView(
              physics: scrollPhysics,
              padding: EdgeInsets.zero,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // ────────────────────── BLUE HEADER ──────────────────────
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(20, headerTop, 20, headerBottom),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
                          ),
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: Image.asset(
                                'assets/images/tax-bridge-logo.png',
                                height: logoHeight,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.description_rounded,
                                  color: Colors.white,
                                  size: logoHeight * 0.7,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tax Management Solution",
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: headerToCardSpacing),

                      // ────────────────────── WHITE CARD ──────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              child: Padding(
                                padding: cardPadding,
                                child: Form(
                                  key: formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Welcome Back', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                      const SizedBox(height: 4),
                                      const Text('Sign in to continue to TaxBridge', style: TextStyle(color: AppColors.textSecondary)),
                                      const SizedBox(height: 16),

                                      // ───── DEMO BADGE ─────
                                      // Container(
                                      //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                                      //   decoration: BoxDecoration(
                                      //     color: const Color(0xFFE3F2FD),
                                      //     borderRadius: BorderRadius.circular(10),
                                      //     border: Border.all(color: const Color(0xFFBBDEFB)),
                                      //   ),
                                      //   child: Row(
                                      //     children: const [
                                      //       Icon(Icons.info_outline, color: Color(0xFF1976D2), size: 16),
                                      //       SizedBox(width: 6),
                                      //       Expanded(
                                      //         child: Text(
                                      //           'Demo: hammad@secureism.com / admin123',
                                      //           style: TextStyle(color: Color(0xFF1976D2), fontSize: 12.5, fontWeight: FontWeight.w500),
                                      //           maxLines: 2,
                                      //           overflow: TextOverflow.ellipsis,
                                      //         ),
                                      //       ),
                                      //     ],
                                      //   ),
                                      // ),
                                      // const SizedBox(height: 16),

                                      // ───── Email Label + Field ─────
                                      const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                      const SizedBox(height: 8),
                                      AppInputField(
                                        label: 'Email',
                                        hint: 'Enter your email',
                                        controller: emailCtrl,
                                        keyboardType: TextInputType.emailAddress,
                                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                                        validator: (v) => v == null || v.trim().isEmpty
                                            ? 'Email is required'
                                            : !GetUtils.isEmail(v.trim())
                                            ? 'Invalid email'
                                            : null,
                                      ),
                                      const SizedBox(height: 18),

                                      // ───── Password Label ─────
                                      const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                      const SizedBox(height: 8),

                                      // ───── Password Field ─────
                                      Obx(() => AppInputField(
                                        label: 'Password',
                                        hint: 'Enter your password',
                                        controller: pwdCtrl,
                                        obscureText: obscurePwd.value,
                                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                        suffixIcon: IconButton(
                                          icon: Icon(obscurePwd.value ? Icons.visibility_off : Icons.visibility),
                                          onPressed: obscurePwd.toggle,
                                        ),
                                        validator: (v) => v == null || v.isEmpty
                                            ? 'Password is required'
                                            : v.length < 6
                                            ? 'Minimum 6 characters'
                                            : null,
                                      )),
                                      const SizedBox(height: 8),

                                      // ───── FORGOT PASSWORD? (NOW BELOW PASSWORD FIELD) ─────
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Obx(() => Row(
                                            children: [
                                              Checkbox(
                                                value: remember.value,
                                                activeColor: Colors.green,
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                onChanged: (v) => remember(v),
                                              ),
                                              const Text('Remember me', style: TextStyle(fontSize: 13.5)),
                                            ],
                                          )),
                                          TextButton(
                                            onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(0, 0),
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: const Text(
                                              'Forgot Password?',
                                              style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),
                                      // ───── Sign In Button ─────
                                      Obx(() => SizedBox(
                                        width: double.infinity,
                                        height: 52,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          onPressed: ctrl.isLoading.value
                                              ? null
                                              : () async {
                                            if (formKey.currentState!.validate()) {
                                              await ctrl.login(emailCtrl.text.trim(), pwdCtrl.text);
                                            }
                                          },
                                          child: ctrl.isLoading.value
                                              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                              : const Text('Sign In', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: Colors.white)),
                                        ),
                                      )),

                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: cardBottomSpacing),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}