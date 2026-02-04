import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/invoice_ledger_model.dart';
import '../../../data/models/client_model.dart';
import '../../../data/repositories/invoice_ledger_repository.dart';
import '../../../data/repositories/client_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/models/invoice_model.dart';
import '../../../core/utils/snackbar_helper.dart';

class InvoiceLedgerController extends GetxController {
  final InvoiceLedgerRepository _repo;
  final ClientRepository _clientsRepo;
  final InvoiceRepository _invoiceRepo;

  InvoiceLedgerController(this._repo, this._clientsRepo, this._invoiceRepo);

  // Filters
  final Rx<ClientModel?> selectedClient = Rx<ClientModel?>(null);
  final Rx<InvoiceModel?> selectedInvoice = Rx<InvoiceModel?>(null);
  final RxString selectedEntryType = 'all'.obs;
  final TextEditingController dateFromCtrl = TextEditingController();
  final TextEditingController dateToCtrl = TextEditingController();

  // Data
  final RxList<ClientModel> clients = <ClientModel>[].obs;
  final RxList<InvoiceModel> invoices = <InvoiceModel>[].obs;
  final RxList<InvoiceLedgerEntry> entries = <InvoiceLedgerEntry>[].obs;
  
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isLoadingInvoices = false.obs;

  // Pagination
  int _page = 1;
  int _lastPage = 1;

  final List<String> entryTypes = [
    'all',
    'invoice_created',
    'payment_received',
    'invoice_cancelled',
    'credit_note',
    'debit_note'
  ];

  @override
  void onInit() {
    super.onInit();
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final res = await _clientsRepo.fetchClients(page: 1);
      clients.assignAll((res['clients'] as List<ClientModel>));
    } catch (_) {}
  }

  Future<void> loadInvoicesForClient(int buyerId) async {
    try {
      isLoadingInvoices.value = true;
      selectedInvoice.value = null;
      invoices.clear();
      
      final res = await _invoiceRepo.fetchInvoicesByBuyer(buyerId: buyerId);
      invoices.assignAll(res);
    } catch (e) {
      debugPrint('Error loading invoices: $e');
    } finally {
      isLoadingInvoices.value = false;
    }
  }

  Future<void> fetch({bool reset = false}) async {
    if (reset) {
      isLoading.value = true;
      _page = 1;
      entries.clear();
    } else {
      if (isLoadingMore.value || _page >= _lastPage) return;
      isLoadingMore.value = true;
      _page += 1;
    }

    try {
      final res = await _repo.fetch(
        page: _page,
        buyerId: selectedClient.value?.byrId,
        invoiceId: selectedInvoice.value?.invoiceId,
        entryType: selectedEntryType.value,
        startDate: dateFromCtrl.text.isNotEmpty ? _toYMD(dateFromCtrl.text) : null,
        endDate: dateToCtrl.text.isNotEmpty ? _toYMD(dateToCtrl.text) : null,
      );

      _lastPage = res.lastPage;
      if (reset) {
        entries.assignAll(res.entries);
      } else {
        entries.addAll(res.entries);
      }
    } catch (e) {
      SnackbarHelper.showError(e.toString());
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  void clearFilters() {
    selectedClient.value = null;
    selectedInvoice.value = null;
    selectedEntryType.value = 'all';
    dateFromCtrl.clear();
    dateToCtrl.clear();
    entries.clear();
    invoices.clear();
  }

  String _toYMD(String mmddyyyy) {
    try {
      final parts = mmddyyyy.split('/');
      if (parts.length == 3) {
        final m = parts[0].padLeft(2, '0');
        final d = parts[1].padLeft(2, '0');
        final y = parts[2];
        return '$y-$m-$d';
      }
    } catch (_) {}
    return mmddyyyy;
  }

  @override
  void onClose() {
    dateFromCtrl.dispose();
    dateToCtrl.dispose();
    super.onClose();
  }
}
