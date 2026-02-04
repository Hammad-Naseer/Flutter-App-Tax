// ─────────────────────────────────────────────────────────────────────────────
// lib/core/network/api_endpoints.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiEndpoints {
  ApiEndpoints._();

  // Base URL - Local Development Server (platform-aware)
  // You can override at build time: --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  // static String get baseUrl {
  //   // If you run with --dart-define=API_BASE_URL=...
  //   if (_overrideBaseUrl.isNotEmpty) {
  //     return _overrideBaseUrl;
  //   }
  //
  //   // Web (Flutter Web)
  //   if (kIsWeb) {
  //     return 'https://app.taxbridge.pk/api';
  //   }
  //
  //   // Mobile (Android/iOS) – Live Server
  //   return 'https://app.taxbridge.pk/api';
  // }
  static String get baseUrl {
    // If you run with --dart-define=API_BASE_URL=...
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }

    // Web (Flutter Web)
    if (kIsWeb) {
      return 'https://app.taxbridge.pk/api';
    }

    // Mobile (Android/iOS) – Live Server
    return 'https://app.taxbridge.pk/api';
  }

  // ───── Auth Endpoints ─────
  static const String login = '/login';
  static const String logout = '/logout';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String refreshToken = '/refresh-token';

  // ───── Buyers/Clients Endpoints ─────
  static const String buyersStore = '/buyers/store';
  static const String buyersUpdate = '/buyers/update';
  static const String buyersDelete = '/buyers/delete';
  static const String buyersList = '/buyers';
  static const String buyersFetch = '/buyers/fetch';

  // ───── Items/Services Endpoints ─────
  static const String itemsStore = '/items/store';
  static const String itemsUpdate = '/items/update';
  static const String itemsDelete = '/items/delete';
  static const String itemsList = '/items';
  static const String itemsFetch = '/items/fetch';

  // ───── Payments Endpoints ─────
  static const String receiptVouchers = '/receipt-vouchers';
  static const String receiptVouchersStore = '/receipt-vouchers/store';
  static const String receiptVouchersShow = '/receipt-vouchers/show';
  static const String receiptVouchersBuyerBalance = '/receipt-vouchers/buyer-balance';
  // Some backends expose a singular path; try this as a fallback
  static const String receiptVoucherBuyerBalanceAlt = '/receipt-voucher/buyer-balance';
  static const String clientLedger = '/client-ledger';
  static const String invoiceLedger = '/invoice-ledger-entries';
  static const String invoicesByBuyer = '/invoice-ledger-entries/invoices-by-buyer';
  // Future: invoice ledger

  // ───── Invoices Endpoints ─────
  static const String invoicesCreate = '/invoices/create';
  static const String invoicesUpdate = '/invoices/update';
  static const String invoicesDelete = '/invoices/delete';
  static const String invoicesList = '/invoices';
  static const String invoicesEdit = '/invoices/edit';
  static const String invoicesPostToFBR = '/invoices/post-to-fbr';
  static const String invoicesSaveDraft = '/invoices/save-draft';
  static const String invoicesSaveOrPost = '/invoices/save-or-post'; // ✅ New unified endpoint
  static const String invoicesFilter = '/invoices/filter';

  // ───── Company/Configuration Endpoints ─────
  static const String companyFetchConfiguration = '/company/fetch-configuration';
  static const String companyUpdateConfiguration = '/company/update-configuration';

  // ───── Settings/Logs Endpoints ─────
  static const String activityLogs = '/activity-logs';
  static const String auditLogs = '/audit-logs';
  static const String fbrErrors = '/fbr-errors';

  // ───── Dashboard & Version Endpoints ─────
  static const String dashboard = '/dashboard';
  static const String appVersion = '/app-version';
}
