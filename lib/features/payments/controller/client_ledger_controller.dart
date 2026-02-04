import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/client_ledger_model.dart';
import '../../../data/models/client_model.dart';
import '../../../data/repositories/client_ledger_repository.dart';
import '../../../data/repositories/client_repository.dart';
import '../../../core/utils/snackbar_helper.dart';

class ClientLedgerController extends GetxController {
  final ClientLedgerRepository _repo;
  final ClientRepository _clientsRepo;
  
  ClientLedgerController(this._repo, this._clientsRepo);

  // Filters
  final Rx<ClientModel?> selectedClient = Rx<ClientModel?>(null);
  final TextEditingController dateFromCtrl = TextEditingController();
  final TextEditingController dateToCtrl = TextEditingController();

  // Data
  final RxList<ClientLedgerEntry> entries = <ClientLedgerEntry>[].obs;
  final RxList<ClientModel> clients = <ClientModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;

  // Totals
  final RxString totalInvoiced = '0.00'.obs;
  final RxString totalPaid = '0.00'.obs;
  final RxString totalBalance = '0.00'.obs;

  // Pagination
  int _page = 1;
  int _lastPage = 1;

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

  Future<void> fetch({bool reset = false}) async {
    if (selectedClient.value == null) {
      SnackbarHelper.showWarning('Please select a client first');
      return;
    }

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
        startDate: dateFromCtrl.text.isNotEmpty ? _toYMD(dateFromCtrl.text) : null,
        endDate: dateToCtrl.text.isNotEmpty ? _toYMD(dateToCtrl.text) : null,
      );

      _lastPage = res.lastPage;
      totalInvoiced.value = res.totalInvoiced;
      totalPaid.value = res.totalPaid;
      totalBalance.value = res.totalBalance;

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
    dateFromCtrl.clear();
    dateToCtrl.clear();
    entries.clear();
    totalInvoiced.value = '0.00';
    totalPaid.value = '0.00';
    totalBalance.value = '0.00';
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
