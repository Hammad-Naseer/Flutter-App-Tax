import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../constants/app_colors.dart';

class UpdateService extends GetxService {
  static UpdateService get to => Get.find<UpdateService>();

  final RxString latestVersion = ''.obs;
  final RxString currentVersion = ''.obs;
  final RxBool isUpdateAvailable = false.obs;
  
  // App update info state
  String? _pendingPlayStoreUrl;
  bool _pendingIsForceUpdate = false;

  @override
  void onInit() {
    super.onInit();
    _initCurrentVersion();
  }

  Future<void> _initCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    currentVersion.value = packageInfo.version;
    debugPrint('📱 Current App Version: ${currentVersion.value}');
  }

  /// Checks for updates and returns if it's a forced update
  Future<bool> checkForUpdate({bool showNoUpdateMessage = false, bool showDialogImmediately = true}) async {
    try {
      if (currentVersion.value.isEmpty) await _initCurrentVersion();

      final api = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : ApiClient();
      final res = await api.get(ApiEndpoints.appVersion, requiresAuth: false);
      
      if (res['success'] == true) {
        final data = res['data'];
        final String latest = (data['latest_version'] ?? '').toString();
        String playStoreUrl = (data['play_store_url'] ?? '').toString();
        final bool isForceUpdate = data['force_update'] == true || data['force_update'] == 1;

        debugPrint('📡 Backend Latest Version: $latest');
        debugPrint('📡 Backend Play Store URL: $playStoreUrl');
        debugPrint('📡 Backend Force Update: $isForceUpdate');
        
        // If URL is empty, use default Play Store URL
        if (playStoreUrl.isEmpty) {
          playStoreUrl = 'https://play.google.com/store/apps/details?id=com.hexclan.taxbridge';
          debugPrint('⚠️ Play Store URL was empty, using default: $playStoreUrl');
        }
        
        if (latest.isNotEmpty) {
          latestVersion.value = latest;
          _pendingPlayStoreUrl = playStoreUrl;
          _pendingIsForceUpdate = isForceUpdate;
          debugPrint('💾 Stored pending update - URL: $_pendingPlayStoreUrl, Force: $_pendingIsForceUpdate');
          
          if (_isNewVersionAvailable(currentVersion.value, latest)) {
            isUpdateAvailable.value = true;
            debugPrint('✅ Update available: Current=${currentVersion.value}, Latest=$latest, Force=$isForceUpdate');
            
            if (showDialogImmediately || isForceUpdate) {
              _showUpdateDialog(playStoreUrl, isForceUpdate);
            }
            return isForceUpdate;
          } else {
            debugPrint('ℹ️ No update needed: Current=${currentVersion.value}, Latest=$latest');
            if (showNoUpdateMessage) {
            Get.snackbar(
              'Up to Date',
              'You are already using the latest version.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking for update: $e');
    }
    return false;
  }

  /// Call this after navigation to show the pending update dialog
  /// Handles both forced and optional updates
  void showPendingUpdateDialog() {
    debugPrint('🔍 showPendingUpdateDialog called - isUpdateAvailable: ${isUpdateAvailable.value}, _pendingPlayStoreUrl: $_pendingPlayStoreUrl');
    if (isUpdateAvailable.value && _pendingPlayStoreUrl != null && _pendingPlayStoreUrl!.isNotEmpty) {
      debugPrint('✅ Conditions met, scheduling dialog after delay');
      // Small delay to ensure navigation is finished
      Future.delayed(const Duration(milliseconds: 500), () {
        if (Get.isDialogOpen ?? false) {
          debugPrint('⚠️ Dialog already open, skipping update dialog');
          // If dialog is already open, don't show another one
          return;
        }
        debugPrint('📱 Calling _showUpdateDialog with URL: $_pendingPlayStoreUrl');
        _showUpdateDialog(_pendingPlayStoreUrl!, _pendingIsForceUpdate);
      });
    } else {
      debugPrint('❌ Conditions not met - isUpdateAvailable: ${isUpdateAvailable.value}, URL: $_pendingPlayStoreUrl');
    }
  }

  bool _isNewVersionAvailable(String current, String latest) {
    if (current.isEmpty || latest.isEmpty) return false;
    
    List<int> currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < latestParts.length; i++) {
        int latestPart = latestParts[i];
        int currentPart = i < currentParts.length ? currentParts[i] : 0;
        if (latestPart > currentPart) return true;
        if (latestPart < currentPart) return false;
    }
    return false;
  }

  void _showUpdateDialog(String url, bool isForceUpdate) {
    if (Get.isDialogOpen ?? false) {
      debugPrint('⚠️ Dialog already open, skipping update dialog');
      return; // Don't show multiple dialogs
    }

    debugPrint('📱 Showing update dialog - Force: $isForceUpdate, URL: $url');
    Get.dialog(
      WillPopScope(
        onWillPop: () async => !isForceUpdate,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Header with Icon and Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.system_update_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                  child: Text(
                        'Update Available',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Message Text
                const Text(
                  'A new version of TaxBridge is available with improvements and bug fixes.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Version Info Cards
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Version',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                currentVersion.value,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Latest Version',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                latestVersion.value,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Force Update Warning
                if (isForceUpdate) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.red.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This is a required update to continue using the app.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    if (!isForceUpdate) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Later',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      flex: isForceUpdate ? 1 : 1,
                      child: ElevatedButton(
                        onPressed: () => _launchPlayStore(url),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.download_rounded, size: 20, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Update Now',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: !isForceUpdate,
      barrierColor: Colors.black54,
    );
  }

  Future<void> _launchPlayStore(String url) async {
    // Note: The package name in build.gradle is com.secureism.tax_bridge
    // If the backend sends the wrong URL (hexclan), we override it here to ensure it works.
    String finalUrl = url;
    if (url.contains('com.hexclan.taxbridge')) {
      finalUrl = url.replaceFirst('com.hexclan.taxbridge', 'com.secureism.tax_bridge');
    }
    
    final Uri uri = Uri.parse(finalUrl.isNotEmpty ? finalUrl : 'https://play.google.com/store/apps/details?id=com.secureism.tax_bridge');
    
    debugPrint('🔗 Launching Play Store: $uri');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'Could not open Play Store.');
    }
  }
}
