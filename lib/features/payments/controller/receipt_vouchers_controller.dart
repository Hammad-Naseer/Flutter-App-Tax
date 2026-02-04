import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import '../utils/receipt_voucher_pdf.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/receipt_voucher_model.dart';
import '../../../data/repositories/receipt_vouchers_repository.dart';
import '../../../data/repositories/client_repository.dart';
import '../../../data/models/client_model.dart';

class ReceiptVouchersController extends GetxController {
  final ReceiptVouchersRepository _repo;
  final ClientRepository _clientsRepo;
  ReceiptVouchersController(this._repo, this._clientsRepo);

  // Filters
  final Rx<ClientModel?> selectedClient = Rx<ClientModel?>(null);
  final TextEditingController dateFromCtrl = TextEditingController();
  final TextEditingController dateToCtrl = TextEditingController();
  final RxString method = 'all'.obs; // all, cash, bank_transfer, cheque

  // Data
  final RxList<ReceiptVoucherModel> items = <ReceiptVoucherModel>[].obs;
  final RxList<ClientModel> clients = <ClientModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;

  // Pagination
  int _page = 1;
  int _lastPage = 1;

  @override
  void onInit() {
    super.onInit();
    _loadClients();
    fetch(reset: true);
  }

  Future<void> _loadClients() async {
    try {
      final res = await _clientsRepo.fetchClients(page: 1);
      clients.assignAll((res['clients'] as List<ClientModel>));
    } catch (_) {}
  }

  Future<void> fetch({bool reset = false}) async {
    if (reset) {
      isLoading.value = true;
      _page = 1;
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
        method: method.value == 'all' ? null : method.value,
      );
      final list = (res['list'] as List<ReceiptVoucherModel>);
      _lastPage = (res['last_page'] as int?) ?? 1;

      if (reset) {
        items.assignAll(list);
      } else {
        items.addAll(list);
      }
    } catch (e) {
      // Silent for now; UI can show snackbar
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> printReceiptVoucher(int paymentId) async {
    try {
      isLoading.value = true;
      final data = await _repo.fetchById(paymentId);
      final bytes = await ReceiptVoucherPdf.generate(data);
      
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'Voucher_${data['payment_no'] ?? paymentId}.pdf',
      );
    } catch (e) {
      SnackbarHelper.showError('Error generating PDF: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void clearFilters() {
    selectedClient.value = null;
    dateFromCtrl.clear();
    dateToCtrl.clear();
    method.value = 'all';
    fetch(reset: true);
  }

  String _toYMD(String mmddyyyy) {
    // Expecting mm/dd/yyyy
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
