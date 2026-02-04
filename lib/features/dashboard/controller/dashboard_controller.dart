// lib/features/dashboard/controller/dashboard_controller.dart
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/services/company_config_service.dart';

class DashboardController extends GetxController {

  final RxInt currentIndex = 0.obs;
  final RxString userName = ''.obs;
  final RxString fbrEnv = 'Sandbox'.obs;

  String get userInitials {
    if (userName.value.isEmpty) return '??';
    final parts = userName.value.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return userName.value[0].toUpperCase();
  }

  // Loading and error
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  // Dashboard metrics
  final RxInt totalClients = 0.obs;
  final RxInt totalInvoices = 0.obs;
  final RxInt fbrPostedInvoices = 0.obs;
  final RxInt draftInvoices = 0.obs;
  final RxDouble fbrPostedPercentage = 0.0.obs;
  final RxDouble draftPercentage = 0.0.obs;

  // Track if dashboard data has successfully loaded at least once
  final RxBool hasLoadedSuccessfully = false.obs;

  // Charts
  final RxList<double> salesTaxData = <double>[].obs;
  final RxList<double> furtherTaxData = <double>[].obs;
  final RxList<double> extraTaxData = <double>[].obs;
  final RxList<String> monthlyLabels = <String>[].obs;
  final RxList<int> monthlyDraftCounts = <int>[].obs;
  final RxList<int> monthlyPostedCounts = <int>[].obs;
  final RxList<int> invoicesCreatedCounts = <int>[].obs;
  final RxList<int> invoicesPostedCounts = <int>[].obs;

  final RxList<String> topClientNames = <String>[].obs;
  final RxList<double> topClientPercentages = <double>[].obs;

  final RxList<String> topServiceNamesRevenue = <String>[].obs;
  final RxList<double> topServicePercentagesRevenue = <double>[].obs;

  @override
  void onInit() {
    super.onInit();
    refreshProfileData();
  }

  Future<void> refreshProfileData() async {
    await _loadUserName();
    await _loadEnvironment();
  }

  @override
  void onReady() {
    super.onReady();
    // Wait even longer to ensure token is properly saved after login
    Future.delayed(const Duration(milliseconds: 1500), () => fetchDashboard(retryOnAuth: true));
  }

  Future<void> _loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('user_name') ?? '';
      print('👤 Loading user name: $name');
      userName.value = name;
    } catch (e) {
      print('❌ Error loading user name: $e');
    }
  }

  Future<void> _loadEnvironment() async {
    try {
      final config = await CompanyConfigService.getConfiguration();
      if (config != null) {
        final envRaw = (config['fbr_env'] ?? '').toString().toLowerCase();
        fbrEnv.value = envRaw == 'production' ? 'Production' : 'Sandbox';
        print('🌐 Loading FBR Environment: ${fbrEnv.value}');
      }
    } catch (e) {
      print('❌ Error loading environment: $e');
    }
  }

  Future<void> fetchDashboard({bool retryOnAuth = false}) async {
    isLoading(true);
    error.value = '';
    try {
      // ✅ Always refresh name and environment from local storage first
      await refreshProfileData();

      final api = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : ApiClient();

      // ✅ Verify token exists before making API call
      final token = await api.getToken();
      print('📝 Dashboard: Token exists: ${token != null && token.isNotEmpty}');
      if (token != null && token.isNotEmpty) {
        print('📝 Dashboard: Token preview: ${token.substring(0, 20)}...');
      }

      final res = await api.get(ApiEndpoints.dashboard);
      if (res['success'] == true) {
        final data = (res['data'] ?? {}) as Map<String, dynamic>;
        totalClients.value = (data['totalClients'] ?? 0) as int;
        totalInvoices.value = (data['totalInvoices'] ?? 0) as int;
        fbrPostedInvoices.value = (data['fbrPostedInvoices'] ?? 0) as int;
        draftInvoices.value = (data['draftInvoices'] ?? 0) as int;
        fbrPostedPercentage.value = ((data['fbrpostedPercentage'] ?? 0) as num).toDouble();
        draftPercentage.value = ((data['draftPercentage'] ?? 0) as num).toDouble();

        salesTaxData.assignAll(((data['salesTaxData'] ?? []) as List).map((e) => (e as num).toDouble()));
        furtherTaxData.assignAll(((data['furtherTaxData'] ?? []) as List).map((e) => (e as num).toDouble()));
        extraTaxData.assignAll(((data['extraTaxData'] ?? []) as List).map((e) => (e as num).toDouble()));

        monthlyLabels.assignAll(((data['monthlyLabels'] ?? []) as List).map((e) => e.toString()));
        monthlyDraftCounts.assignAll(((data['monthlyDraftCounts'] ?? []) as List).map((e) => (e as num).toInt()));
        monthlyPostedCounts.assignAll(((data['monthlyPostedCounts'] ?? []) as List).map((e) => (e as num).toInt()));

        // Parse invoiceMonthlyStats
        final ims = data['invoiceMonthlyStats'] as Map<String, dynamic>?;
        if (ims != null) {
          final months = (ims['months'] as List?)?.map((e) => e.toString()).toList();
          if (months != null && months.isNotEmpty) {
            monthlyLabels.assignAll(months);
          }
          final series = (ims['series'] as List?) ?? [];
          invoicesCreatedCounts.clear();
          invoicesPostedCounts.clear();
          for (final s in series) {
            final name = (s['name'] ?? '').toString().toLowerCase();
            final dataArr = ((s['data'] ?? []) as List).map((e) => (e as num).toInt()).toList();
            if (name.contains('created')) {
              invoicesCreatedCounts.assignAll(dataArr);
            } else if (name.contains('posted')) {
              invoicesPostedCounts.assignAll(dataArr);
            }
          }
        }

        topClientNames.assignAll(((data['topClientNames'] ?? []) as List).map((e) => e.toString()));
        topClientPercentages.assignAll(((data['topClientPercentages'] ?? []) as List).map((e) => (e as num).toDouble()));

        topServiceNamesRevenue.assignAll(((data['topServiceNamesRevenue'] ?? []) as List).map((e) => e.toString()));
        topServicePercentagesRevenue.assignAll(((data['topServicePercentagesRevenue'] ?? []) as List).map((e) => (e as num).toDouble()));
        hasLoadedSuccessfully.value = true;
      } else {
        final msg = (res['message']?.toString() ?? 'Failed to load dashboard');
        final lower = msg.toLowerCase();
        final isAuthLike = lower.contains('unauthenticated') || lower.contains('unauthorized');

        if (retryOnAuth && isAuthLike) {
          // Silent one-time retry when backend responds with an auth-like message
          await Future.delayed(const Duration(milliseconds: 1000));
          try {
            final apiRetry = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : ApiClient();
            final resRetry = await apiRetry.get(ApiEndpoints.dashboard);
            if (resRetry['success'] == true) {
              final data = (resRetry['data'] ?? {}) as Map<String, dynamic>;
              totalClients.value = (data['totalClients'] ?? 0) as int;
              totalInvoices.value = (data['totalInvoices'] ?? 0) as int;
              fbrPostedInvoices.value = (data['fbrPostedInvoices'] ?? 0) as int;
              draftInvoices.value = (data['draftInvoices'] ?? 0) as int;
              fbrPostedPercentage.value = ((data['fbrpostedPercentage'] ?? 0) as num).toDouble();
              draftPercentage.value = ((data['draftPercentage'] ?? 0) as num).toDouble();

              salesTaxData.assignAll(((data['salesTaxData'] ?? []) as List).map((e) => (e as num).toDouble()));
              furtherTaxData.assignAll(((data['furtherTaxData'] ?? []) as List).map((e) => (e as num).toDouble()));
              extraTaxData.assignAll(((data['extraTaxData'] ?? []) as List).map((e) => (e as num).toDouble()));

              monthlyLabels.assignAll(((data['monthlyLabels'] ?? []) as List).map((e) => e.toString()));
              monthlyDraftCounts.assignAll(((data['monthlyDraftCounts'] ?? []) as List).map((e) => (e as num).toInt()));
              monthlyPostedCounts.assignAll(((data['monthlyPostedCounts'] ?? []) as List).map((e) => (e as num).toInt()));

              topClientNames.assignAll(((data['topClientNames'] ?? []) as List).map((e) => e.toString()));
              topClientPercentages.assignAll(((data['topClientPercentages'] ?? []) as List).map((e) => (e as num).toDouble()));

              topServiceNamesRevenue.assignAll(((data['topServiceNamesRevenue'] ?? []) as List).map((e) => e.toString()));
              topServicePercentagesRevenue.assignAll(((data['topServicePercentagesRevenue'] ?? []) as List).map((e) => (e as num).toDouble()));
              error.value = '';
              hasLoadedSuccessfully.value = true;
            } else {
              error.value = resRetry['message']?.toString() ?? msg;
            }
          } catch (_) {
            error.value = msg;
          }
        } else {
          error.value = msg;
        }
      }
    } on UnauthorizedException catch (e) {
      // Token not valid - wait a bit longer and retry once
      error.value = 'Authenticating...';
      await Future.delayed(const Duration(milliseconds: 1000));
      try {
        final api = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : ApiClient();
        final res = await api.get(ApiEndpoints.dashboard);
        if (res['success'] == true) {
          final data = (res['data'] ?? {}) as Map<String, dynamic>;
          totalClients.value = (data['totalClients'] ?? 0) as int;
          totalInvoices.value = (data['totalInvoices'] ?? 0) as int;
          fbrPostedInvoices.value = (data['fbrPostedInvoices'] ?? 0) as int;
          draftInvoices.value = (data['draftInvoices'] ?? 0) as int;
          fbrPostedPercentage.value = ((data['fbrpostedPercentage'] ?? 0) as num).toDouble();
          draftPercentage.value = ((data['draftPercentage'] ?? 0) as num).toDouble();

          salesTaxData.assignAll(((data['salesTaxData'] ?? []) as List).map((e) => (e as num).toDouble()));
          furtherTaxData.assignAll(((data['furtherTaxData'] ?? []) as List).map((e) => (e as num).toDouble()));
          extraTaxData.assignAll(((data['extraTaxData'] ?? []) as List).map((e) => (e as num).toDouble()));

          monthlyLabels.assignAll(((data['monthlyLabels'] ?? []) as List).map((e) => e.toString()));
          monthlyDraftCounts.assignAll(((data['monthlyDraftCounts'] ?? []) as List).map((e) => (e as num).toInt()));
          monthlyPostedCounts.assignAll(((data['monthlyPostedCounts'] ?? []) as List).map((e) => (e as num).toInt()));

          topClientNames.assignAll(((data['topClientNames'] ?? []) as List).map((e) => e.toString()));
          topClientPercentages.assignAll(((data['topClientPercentages'] ?? []) as List).map((e) => (e as num).toDouble()));

          topServiceNamesRevenue.assignAll(((data['topServiceNamesRevenue'] ?? []) as List).map((e) => e.toString()));
          topServicePercentagesRevenue.assignAll(((data['topServicePercentagesRevenue'] ?? []) as List).map((e) => (e as num).toDouble()));
          error.value = '';
          hasLoadedSuccessfully.value = true;
        } else {
          error.value = res['message']?.toString() ?? e.toString();
        }
      } catch (_) {
        error.value = e.toString();
      }
    } on NetworkException catch (e) {
      // For generic network errors (including occasional "Unauthenticated" wraps),
      // retry once silently before showing an error on screen.
      final msg = e.message.toLowerCase();
      final isAuthLike = msg.contains('unauthenticated') || msg.contains('unauthorized');

      // Slightly longer delay for auth-related cases to allow token/config to settle
      await Future.delayed(Duration(milliseconds: isAuthLike ? 1000 : 500));
      try {
        final api = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : ApiClient();
        final res = await api.get(ApiEndpoints.dashboard);
        if (res['success'] == true) {
          final data = (res['data'] ?? {}) as Map<String, dynamic>;
          totalClients.value = (data['totalClients'] ?? 0) as int;
          totalInvoices.value = (data['totalInvoices'] ?? 0) as int;
          fbrPostedInvoices.value = (data['fbrPostedInvoices'] ?? 0) as int;
          draftInvoices.value = (data['draftInvoices'] ?? 0) as int;
          fbrPostedPercentage.value = ((data['fbrpostedPercentage'] ?? 0) as num).toDouble();
          draftPercentage.value = ((data['draftPercentage'] ?? 0) as num).toDouble();

          salesTaxData.assignAll(((data['salesTaxData'] ?? []) as List).map((e) => (e as num).toDouble()));
          furtherTaxData.assignAll(((data['furtherTaxData'] ?? []) as List).map((e) => (e as num).toDouble()));
          extraTaxData.assignAll(((data['extraTaxData'] ?? []) as List).map((e) => (e as num).toDouble()));

          monthlyLabels.assignAll(((data['monthlyLabels'] ?? []) as List).map((e) => e.toString()));
          monthlyDraftCounts.assignAll(((data['monthlyDraftCounts'] ?? []) as List).map((e) => (e as num).toInt()));
          monthlyPostedCounts.assignAll(((data['monthlyPostedCounts'] ?? []) as List).map((e) => (e as num).toInt()));

          topClientNames.assignAll(((data['topClientNames'] ?? []) as List).map((e) => e.toString()));
          topClientPercentages.assignAll(((data['topClientPercentages'] ?? []) as List).map((e) => (e as num).toDouble()));

          topServiceNamesRevenue.assignAll(((data['topServiceNamesRevenue'] ?? []) as List).map((e) => e.toString()));
          topServicePercentagesRevenue.assignAll(((data['topServicePercentagesRevenue'] ?? []) as List).map((e) => (e as num).toDouble()));
          error.value = '';
        } else {
          error.value = res['message']?.toString() ?? e.message;
        }
      } catch (_) {
        error.value = e.message;
      }
    } on UnauthorizedException catch (e) {
      // ✅ Handle authentication error with automatic retry
      print('🚫 Dashboard: UnauthorizedException caught: ${e.message}');

      if (retryOnAuth) {
        print('🔄 Dashboard: Retrying after 1 second...');
        await Future.delayed(const Duration(milliseconds: 1000));

        try {
          final api = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : ApiClient();

          // Verify token again before retry
          final token = await api.getToken();
          print('📝 Dashboard Retry: Token exists: ${token != null && token.isNotEmpty}');

          final res = await api.get(ApiEndpoints.dashboard);
          if (res['success'] == true) {
            print('✅ Dashboard: Retry successful!');
            final data = (res['data'] ?? {}) as Map<String, dynamic>;
            totalClients.value = (data['totalClients'] ?? 0) as int;
            totalInvoices.value = (data['totalInvoices'] ?? 0) as int;
            fbrPostedInvoices.value = (data['fbrPostedInvoices'] ?? 0) as int;
            draftInvoices.value = (data['draftInvoices'] ?? 0) as int;
            fbrPostedPercentage.value = ((data['fbrpostedPercentage'] ?? 0) as num).toDouble();
            draftPercentage.value = ((data['draftPercentage'] ?? 0) as num).toDouble();

            salesTaxData.assignAll(((data['salesTaxData'] ?? []) as List).map((e) => (e as num).toDouble()));
            furtherTaxData.assignAll(((data['furtherTaxData'] ?? []) as List).map((e) => (e as num).toDouble()));
            extraTaxData.assignAll(((data['extraTaxData'] ?? []) as List).map((e) => (e as num).toDouble()));

            monthlyLabels.assignAll(((data['monthlyLabels'] ?? []) as List).map((e) => e.toString()));
            monthlyDraftCounts.assignAll(((data['monthlyDraftCounts'] ?? []) as List).map((e) => (e as num).toInt()));
            monthlyPostedCounts.assignAll(((data['monthlyPostedCounts'] ?? []) as List).map((e) => (e as num).toInt()));

            topClientNames.assignAll(((data['topClientNames'] ?? []) as List).map((e) => e.toString()));
            topClientPercentages.assignAll(((data['topClientPercentages'] ?? []) as List).map((e) => (e as num).toDouble()));

            topServiceNamesRevenue.assignAll(((data['topServiceNamesRevenue'] ?? []) as List).map((e) => e.toString()));
            topServicePercentagesRevenue.assignAll(((data['topServicePercentagesRevenue'] ?? []) as List).map((e) => (e as num).toDouble()));
            error.value = '';
            hasLoadedSuccessfully.value = true;
          } else {
            print('❌ Dashboard: Retry failed - ${res['message']}');
            error.value = res['message']?.toString() ?? e.message;
          }
        } catch (retryError) {
          print('❌ Dashboard: Retry exception: $retryError');
          error.value = e.message;
        }
      } else {
        print('❌ Dashboard: No retry - showing error');
        error.value = e.message;
      }
    } catch (e) {
      print('❌ Dashboard: Generic error: $e');
      error.value = e.toString();
    } finally {
      isLoading(false);
    }
  }

  void changeTab(int index) {
    currentIndex.value = index;
    // Navigate based on tab
    switch (index) {
      case 1:
        Get.toNamed('/invoices');
        break;
      case 2:
        Get.toNamed('/clients');
        break;
      case 3:
        Get.toNamed('/more');
        break;
    }
  }
}