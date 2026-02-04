import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input_field.dart';
import '../controller/auth_controller.dart';
import 'package:get/get.dart';

class ForgotPasswordScreen extends StatelessWidget {
  ForgotPasswordScreen({Key? key}) : super(key: key);

  final AuthController _controller = Get.find<AuthController>();
  final TextEditingController _emailCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallHeight = constraints.maxHeight < 700;
            final headerTop = isSmallHeight ? 24.0 : 40.0;
            final headerBottom = isSmallHeight ? 20.0 : 32.0;
            final titleFontSize = isSmallHeight ? 24.0 : 28.0;
            final headerToCardSpacing = isSmallHeight ? 20.0 : 32.0;
            final cardPadding = EdgeInsets.all(isSmallHeight ? 16 : 24);
            final cardBottomSpacing = isSmallHeight ? 12.0 : 24.0;

            // Only allow scroll when keyboard is visible
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
                      // ────── Header ──────
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(24, headerTop, 24, headerBottom),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.primary, Color(0xFF0D47A1)],
                          ),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.appName,
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              AppStrings.forgotPassword,
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: headerToCardSpacing),

                      // ────── Form Card ──────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppStrings.forgotSubtitle,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                AppInputField(
                                  label: AppStrings.emailHint,
                                  hint: AppStrings.emailHint,
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!GetUtils.isEmail(v)) {
                                      return 'Invalid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                Obx(() => AppButton(
                                      label: AppStrings.submit,
                                      isLoading: _controller.isLoading.value,
                                      onPressed: () async {
                                        if (_emailCtrl.text.isNotEmpty &&
                                            GetUtils.isEmail(_emailCtrl.text)) {
                                          await _controller
                                              .forgotPassword(_emailCtrl.text);
                                        }
                                      },
                                    )),
                                const SizedBox(height: 16),

                                Center(
                                  child: TextButton(
                                    onPressed: () => Get.back(),
                                    child: const Text(
                                      AppStrings.backToLogin,
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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