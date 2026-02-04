import 'package:get/get.dart';
import '../core/constants/app_routes.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/password_reset_success.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/more/presentation/more_menu.dart';
import '../features/items/presentation/items_list.dart';
import '../features/more/presentation/configuration_screen.dart';
import '../features/more/presentation/activity_logs_screen.dart';
import '../features/audit_logs/presentation/audit_logs_screen.dart';
import '../features/more/presentation/fbr_post_errors_screen.dart';
import '../features/more/presentation/fbr_lookups_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../core/network/api_client.dart';
import '../data/repositories/item_repository.dart';
import '../features/items/controller/items_controller.dart';
import '../data/repositories/activity_logs_repository.dart';
import '../features/more/controller/activity_logs_controller.dart';
import '../data/repositories/client_repository.dart';
import '../features/clients/controller/clients_controller.dart';
import '../features/clients/presentation/clients_list.dart';
import '../data/repositories/invoice_repository.dart';
import '../features/invoices/controller/invoices_controller.dart';
import '../features/invoices/presentation/invoices_list.dart';
import '../data/repositories/receipt_vouchers_repository.dart';
import '../features/payments/controller/receipt_vouchers_controller.dart';
import '../features/payments/presentation/receipt_vouchers_screen.dart';
import '../features/payments/controller/receipt_voucher_create_controller.dart';
import '../features/payments/presentation/receipt_voucher_create_screen.dart';

import '../data/repositories/client_ledger_repository.dart';
import '../data/repositories/invoice_ledger_repository.dart';
import '../features/payments/controller/client_ledger_controller.dart';
import '../features/payments/controller/invoice_ledger_controller.dart';
import '../features/payments/presentation/client_ledger_screen.dart';
import '../features/payments/presentation/invoice_ledger_screen.dart';

class AppPages {
  AppPages._();

  static final routes = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.forgotPassword, page: () => ForgotPasswordScreen()),
    GetPage(name: AppRoutes.resetPassword, page: () => ResetPasswordScreen()),
    GetPage(name: AppRoutes.passwordResetSuccess, page: () => const PasswordResetSuccess()),
    GetPage(name: AppRoutes.dashboard, page: () => const DashboardScreen()),
    GetPage(name: '/dashboard', page: () => const DashboardScreen()),
    GetPage(
      name: AppRoutes.invoices,
      page: () => const InvoicesList(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ApiClient>()) Get.put(ApiClient(), permanent: true);
        if (!Get.isRegistered<InvoiceRepository>()) {
          Get.put(InvoiceRepository(Get.find<ApiClient>()), permanent: true);
        }
        if (!Get.isRegistered<InvoicesController>()) {
          Get.put(InvoicesController(Get.find<InvoiceRepository>()), permanent: true);
        }
      }),
    ),
    GetPage(
      name: AppRoutes.clients,
      page: () => const ClientsList(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ApiClient>()) Get.put(ApiClient(), permanent: true);
        if (!Get.isRegistered<ClientRepository>()) {
          Get.put(ClientRepository(Get.find<ApiClient>()), permanent: true);
        }
        if (!Get.isRegistered<ClientsController>()) {
          Get.put(ClientsController(Get.find<ClientRepository>()), permanent: true);
        }
      }),
    ),
    GetPage(name: AppRoutes.more, page: () => const MoreMenu(),),
    GetPage(
      name: AppRoutes.itemsServices,
      page: () => const ItemsList(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ApiClient>()) Get.put(ApiClient(), permanent: true);
        if (!Get.isRegistered<ItemRepository>()) {
          Get.put(ItemRepository(Get.find<ApiClient>()), permanent: true);
        }
        if (!Get.isRegistered<ItemsController>()) {
          Get.put(ItemsController(Get.find<ItemRepository>()), permanent: true);
        }
      }),
    ),
    GetPage(name: AppRoutes.configuration, page: () => const ConfigurationScreen()),
    GetPage(
      name: AppRoutes.activityLogs,
      page: () => const ActivityLogsScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ApiClient>()) Get.put(ApiClient(), permanent: true);
        if (!Get.isRegistered<ActivityLogsRepository>()) {
          Get.put(ActivityLogsRepository(Get.find<ApiClient>()), permanent: true);
        }
        if (!Get.isRegistered<ActivityLogsController>()) {
          Get.put(ActivityLogsController(Get.find<ActivityLogsRepository>()), permanent: true);
        }
      }),
    ),
    GetPage(
      name: AppRoutes.auditLogs,
      page: () => const AuditLogsScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ApiClient>()) Get.put(ApiClient(), permanent: true);
      }),
    ),
    GetPage(name: AppRoutes.fbrPostErrors, page: () => const FbrPostErrorsScreen()),
    // GetPage(name: AppRoutes.fbrLookups, page: () => const FbrLookupsScreen()),
    
    // ───── Payments ─────
    GetPage(
      name: AppRoutes.paymentsReceiptVouchers,
      page: () => const ReceiptVouchersScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ApiClient>()) Get.put(ApiClient(), permanent: true);
        if (!Get.isRegistered<ClientRepository>()) {
          Get.put(ClientRepository(Get.find<ApiClient>()), permanent: true);
        }
        if (!Get.isRegistered<ReceiptVouchersRepository>()) {
          Get.put(ReceiptVouchersRepository(Get.find<ApiClient>()), permanent: true);
        }
        if (!Get.isRegistered<ReceiptVouchersController>()) {
          Get.put(ReceiptVouchersController(
            Get.find<ReceiptVouchersRepository>(),
            Get.find<ClientRepository>(),
          ), permanent: true);
        }
      }),
    ),
    GetPage(
      name: AppRoutes.paymentsReceiptCreate,
      page: () => const ReceiptVoucherCreateScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ApiClient>()) Get.put(ApiClient(), permanent: true);
        if (!Get.isRegistered<ClientRepository>()) {
          Get.put(ClientRepository(Get.find<ApiClient>()), permanent: true);
        }
        if (!Get.isRegistered<ReceiptVouchersRepository>()) {
          Get.put(ReceiptVouchersRepository(Get.find<ApiClient>()), permanent: true);
        }
        Get.put(ReceiptVoucherCreateController(
          Get.find<ReceiptVouchersRepository>(),
          Get.find<ClientRepository>(),
        ));
      }),
    ),
    GetPage(
      name: AppRoutes.paymentsClientLedger,
      page: () => const ClientLedgerScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ApiClient>()) Get.put(ApiClient(), permanent: true);
        if (!Get.isRegistered<ClientRepository>()) {
          Get.put(ClientRepository(Get.find<ApiClient>()), permanent: true);
        }
        if (!Get.isRegistered<ClientLedgerRepository>()) {
          Get.put(ClientLedgerRepository(Get.find<ApiClient>()), permanent: true);
        }
        Get.put(ClientLedgerController(
          Get.find<ClientLedgerRepository>(),
          Get.find<ClientRepository>(),
        ));
      }),
    ),
    GetPage(
      name: AppRoutes.paymentsInvoiceLedger,
      page: () => const InvoiceLedgerScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ApiClient>()) Get.put(ApiClient(), permanent: true);
        if (!Get.isRegistered<ClientRepository>()) {
          Get.put(ClientRepository(Get.find<ApiClient>()), permanent: true);
        }
        if (!Get.isRegistered<InvoiceRepository>()) {
          Get.put(InvoiceRepository(Get.find<ApiClient>()), permanent: true);
        }
        if (!Get.isRegistered<InvoiceLedgerRepository>()) {
          Get.put(InvoiceLedgerRepository(Get.find<ApiClient>()), permanent: true);
        }
        Get.put(InvoiceLedgerController(
          Get.find<InvoiceLedgerRepository>(),
          Get.find<ClientRepository>(),
          Get.find<InvoiceRepository>(),
        ));
      }),
    ),
  ];
}
