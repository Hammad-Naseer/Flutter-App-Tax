class AppRoutes {
  AppRoutes._(); // Private constructor

  // ───── Auth Routes ─────
  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot_password';
  static const String resetPassword = '/reset_password';
  static const String passwordResetSuccess = '/password_reset_success';

  // ───── Main Tab Routes ─────
  static const String dashboard = '/dashboard';
  static const String invoices = '/invoices';
  static const String clients = '/clients';
  static const String more = '/more';

  // ───── More Sub-Screens ─────
  static const String itemsServices = '/more/items-services';
  static const String configuration = '/more/configuration';
  static const String activityLogs = '/more/activity-logs';
  static const String auditLogs = '/more/audit-logs';
  static const String fbrPostErrors = '/more/fbr-post-errors';
  // static const String fbrLookups = '/more/fbr-lookups';

  // ───── Payments ─────
  static const String paymentsReceiptVouchers = '/payments/receipt-vouchers';
  static const String paymentsReceiptCreate = '/payments/receipt-vouchers/create';
  static const String paymentsClientLedger = '/payments/client-ledger';
  static const String paymentsInvoiceLedger = '/payments/invoice-ledger';
  // Future: invoice ledger
}