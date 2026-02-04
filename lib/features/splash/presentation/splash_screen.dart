import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/update_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSplashScreen();
  }

  Future<void> _startSplashScreen() async {
    // 1. Minimum delay for splash animation
    final animationFuture = Future.delayed(const Duration(milliseconds: 2200));

    // 2. Check for app updates (but don't show dialog immediately)
    bool isForceUpdate = false;
    bool hasUpdate = false;
    try {
      if (Get.isRegistered<UpdateService>()) {
        final updateService = Get.find<UpdateService>();
        // Check for update but don't show dialog immediately
        // We'll show it after navigation to avoid Get.offAllNamed closing it
        isForceUpdate = await updateService.checkForUpdate(
          showDialogImmediately: false, // Don't show dialog yet
        );
        // Wait a tiny bit to ensure reactive value is updated
        await Future.delayed(const Duration(milliseconds: 100));
        hasUpdate = updateService.isUpdateAvailable.value;
        debugPrint('📊 Update check result - isForceUpdate: $isForceUpdate, hasUpdate: $hasUpdate');
      }
    } catch (e) {
      debugPrint('⚠️ Splash Version Check Error: $e');
    }

    // 3. Wait for animation to finish
    await animationFuture;

    // 4. If forced update is active, show dialog and STOP here.
    if (isForceUpdate) {
      debugPrint('🛑 Forced Update active. Stopping navigation.');
      if (Get.isRegistered<UpdateService>()) {
        final updateService = Get.find<UpdateService>();
        // Show forced update dialog now
        updateService.showPendingUpdateDialog();
      }
      return;
    }

    if (!mounted) {
      debugPrint('⚠️ Widget not mounted, skipping navigation');
      return;
    }
    
    // 5. Schedule update dialog BEFORE navigation (so it shows after navigation)
    if (hasUpdate && Get.isRegistered<UpdateService>()) {
      debugPrint('🔄 Scheduling update dialog to show after navigation');
      // Schedule dialog to show after navigation completes
      // Using a longer delay to ensure navigation is fully done
      Future.delayed(const Duration(milliseconds: 800), () {
        debugPrint('⏰ Delay completed, calling showPendingUpdateDialog');
        try {
          if (Get.isRegistered<UpdateService>()) {
            Get.find<UpdateService>().showPendingUpdateDialog();
          } else {
            debugPrint('❌ UpdateService not registered after delay');
          }
        } catch (e) {
          debugPrint('❌ Error calling showPendingUpdateDialog: $e');
        }
      });
    } else {
      debugPrint('ℹ️ Not scheduling update dialog - hasUpdate: $hasUpdate, isRegistered: ${Get.isRegistered<UpdateService>()}');
    }

    if (!mounted) {
      debugPrint('⚠️ Widget not mounted, skipping navigation');
      return;
    }
    
    debugPrint('🚀 Navigating to login screen...');
    // 6. Navigate to Login (or Dashboard if already logged in)
    // Navigation happens after dialog is scheduled
    Get.offAllNamed(AppRoutes.login);
    debugPrint('✅ Navigation initiated');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double screenWidth = size.width;

    // Bigger & Prominent Logo
    final double logoSize = screenWidth * 0.40; // 40% of screen width
    final double maxLogoSize = 220.0;
    final double minLogoSize = 120.0;
    final double finalLogoSize = logoSize.clamp(minLogoSize, maxLogoSize);

    // Soft glow behind logo (no hard circle)
    final double glowSize = finalLogoSize + 80;

    final gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // GLOW + LOGO (NO CIRCLE, JUST GLOW & IMAGE)
              Stack(
                alignment: Alignment.center,
                children: [
                  // Soft Glow Background
                  Container(
                    width: glowSize,
                    height: glowSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.25),
                          blurRadius: 70,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  // Logo (Prominent & Big)
                  Image.asset(
                    'assets/images/tax-bridge-logo.png',
                    width: finalLogoSize,
                    height: finalLogoSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) => Icon(
                      Icons.description_rounded,
                      color: Colors.white,
                      size: finalLogoSize * 0.6,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // App Name - Bolder
              const Text(
                'TaxBridge',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black38,
                      offset: Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Tagline
              const Text(
                'Tax Management Solution',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}