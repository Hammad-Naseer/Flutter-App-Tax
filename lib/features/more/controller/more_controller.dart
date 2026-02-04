// lib/features/more/controller/more_controller.dart
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class MoreController extends GetxController {
  // User info (from login)
  final userName = ''.obs;
  final userEmail = ''.obs;
  final userRole = 'Administrator'.obs; // fallback label
  final tenantId = ''.obs; // also used as bus_config_id

  // Company configuration
  final companyName = ''.obs;
  final ntn = ''.obs;
  final province = ''.obs;
  final env = 'Sandbox'.obs; // Sandbox | Production

  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      // Read saved user info
      final prefs = await SharedPreferences.getInstance();
      userName.value = prefs.getString('user_name') ?? '';
      userEmail.value = prefs.getString('user_email') ?? '';
      tenantId.value = prefs.getString('bus_config_id') ?? prefs.getString('tenant_id') ?? '';

      print('📝 More Screen: Loading company configuration');
      print('📝 More Screen: bus_config_id: ${tenantId.value}');

      // Fetch configuration if we have a tenant/bus_config_id
      final api = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : ApiClient();
      final id = tenantId.value.isNotEmpty ? tenantId.value : '1';
      final res = await api.postFormData(
        ApiEndpoints.companyFetchConfiguration,
        fields: { 'bus_config_id': id },
        requiresAuth: true,
      );

      print('📝 More Screen: API Response received');
      print('📝 More Screen: Success: ${res['success']}');
      print('📝 More Screen: Response keys: ${res.keys.toList()}');

      // ✅ Handle both response formats (with/without success field)
      final hasSuccess = res.containsKey('success');
      final isSuccess = hasSuccess ? (res['success'] == true) : res.containsKey('data');

      if (isSuccess) {
        final data = (res['data'] ?? {}) as Map<String, dynamic>;
        final cfg = (data['config'] ?? {}) as Map<String, dynamic>;

        companyName.value = (cfg['bus_name'] ?? '').toString();
        ntn.value = (cfg['bus_ntn_cnic'] ?? '').toString();
        province.value = (cfg['bus_province'] ?? '').toString();
        final rawEnv = (cfg['fbr_env'] ?? '').toString().toLowerCase();
        env.value = rawEnv == 'production' ? 'Production' : 'Sandbox';

        print('✅ More Screen: Company data loaded');
        print('📋 Company Name: ${companyName.value}');
        print('📋 NTN: ${ntn.value}');
        print('📋 Province: ${province.value}');
      } else {
        print('❌ More Screen: Failed to load company configuration');
        print('❌ Message: ${res['message']}');
      }
    } catch (e) {
      print('❌ More Screen: Exception: $e');
      // keep fallbacks
    } finally {
      isLoading.value = false;
    }
  }
}

