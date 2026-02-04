import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/client_model.dart';
import '../../../data/repositories/client_repository.dart';
import '../../../data/repositories/receipt_vouchers_repository.dart';
import '../../../core/utils/snackbar_helper.dart';
import 'receipt_vouchers_controller.dart';

class ReceiptVoucherCreateController extends GetxController {
  final ReceiptVouchersRepository _repo;
  final ClientRepository _clientsRepo;
  ReceiptVoucherCreateController(this._repo, this._clientsRepo);

  // Form
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final Rx<ClientModel?> selectedClient = Rx<ClientModel?>(null);
  final RxList<ClientModel> clients = <ClientModel>[].obs;
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController dateCtrl = TextEditingController();
  final RxString method = 'cash'.obs; // cash | bank_transfer | cheque
  final RxString bankName = ''.obs; // selected bank name
  final TextEditingController referenceCtrl = TextEditingController();
  final TextEditingController chequeNoCtrl = TextEditingController();
  final TextEditingController chequeDateCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();

  // Buyer balance and invoices
  final RxDouble buyerBalance = 0.0.obs;
  final RxList<dynamic> pendingInvoices = <dynamic>[].obs;
  double get paidAmount => double.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0.0;
  double get remaining => (buyerBalance.value - paidAmount).clamp(-999999999.0, 999999999.0);

  // Loading
  final RxBool isFetchingClients = false.obs;
  final RxBool isFetchingBalance = false.obs;
  final RxBool isSaving = false.obs;

  bool get canViewInvoices => selectedClient.value != null && !isFetchingBalance.value;

  // Bank list (static for now; can be moved to API later)
  final List<String> banks = const [
    'HBL (Habib Bank Limited)',
    'Allied Bank Limited',
    'Askari Bank Limited',
    'Faysal Bank Limited',
    'MCB (Muslim Commercial Bank)',
    'UBL (United Bank Limited)',
    'NBP (National Bank of Pakistan)',
    'Bank Alfalah Limited',
    'Meezan Bank Limited',
    'Standard Chartered Bank Pakistan',
    'Bank Al Habib Limited',
    'Soneri Bank Limited',
    'JS Bank Limited',
    'Silk Bank Limited',
    'Summit Bank Limited',
    'Bank of Punjab',
    'Sindh Bank Limited',
    'Samba Bank Limited',
    'Dubai Islamic Bank Pakistan',
    'Al Baraka Bank Pakistan',
    'BankIslami Pakistan Limited',
    'First Women Bank Limited',
    'Industrial and Commercial Bank of China',
    'Habib Metropolitan Bank',
  ];

  @override
  void onInit() {
    super.onInit();
    _loadClients();
    final now = DateTime.now();
    dateCtrl.text = _toMDY(now);
  }

  Future<void> _loadClients() async {
    try {
      isFetchingClients.value = true;
      final res = await _clientsRepo.fetchClients(page: 1);
      clients.assignAll(res['clients'] as List<ClientModel>);
    } catch (_) {} finally {
      isFetchingClients.value = false;
    }
  }

  Future<void> onClientChanged(ClientModel? client) async {
    selectedClient.value = client;
    buyerBalance.value = 0.0;
    pendingInvoices.clear();
    amountCtrl.text = '';
    
    // Trigger remaining to recalc (becomes 0 - 0)
    buyerBalance.refresh();
    
    if (client == null) return;
    try {
      isFetchingBalance.value = true;
      final res = await _repo.buyerBalance(buyerId: client.byrId);
      print('DEBUG: Buyer Balance Response: $res');
      
      // Total Balance
      final tb = res['total_balance'];
      buyerBalance.value = tb is num ? tb.toDouble() : double.tryParse(tb?.toString() ?? '0') ?? 0.0;
      print('DEBUG: Parsed Balance: ${buyerBalance.value}');
      
      // Pending Invoices
      final invs = res['invoices'];
      if (invs is List) {
        pendingInvoices.assignAll(invs);
      }
      print('DEBUG: Pending Invoices Count: ${pendingInvoices.length}');
      
      // After setting new balance, clear paid and recalc remaining to full balance
      amountCtrl.text = '';
      buyerBalance.refresh();
    } catch (_) {
      buyerBalance.value = 0.0;
      pendingInvoices.clear();
      amountCtrl.text = '';
      buyerBalance.refresh();
    } finally {
      isFetchingBalance.value = false;
    }
  }

  Future<void> pickDate(BuildContext context, TextEditingController ctrl) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime initial = today;
    
    try {
      if (ctrl.text.isNotEmpty) {
        final parts = ctrl.text.split('/');
        if (parts.length == 3) {
          final parsed = DateTime(int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
          // If parsed date is in the past, default to today
          initial = parsed.isBefore(today) ? today : parsed;
        }
      }
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ctrl.text = _toMDY(picked);
    }
  }

  Future<String?> submit() async {
    if (selectedClient.value == null) {
      SnackbarHelper.showWarning('Please select a client');
      return null;
    }
    if (!(formKey.currentState?.validate() ?? false)) return null;

    isSaving.value = true;
    try {
      final res = await _repo.store(
        buyerId: selectedClient.value!.byrId,
        paymentAmount: amountCtrl.text.trim(),
        paymentDate: _toYMD(dateCtrl.text.trim()),
        paymentMethod: method.value,
        bankName: method.value == 'bank_transfer' || method.value == 'cheque' ? (bankName.value.isEmpty ? null : bankName.value) : null,
        referenceNo: referenceCtrl.text.trim().isEmpty ? null : referenceCtrl.text.trim(),
        chequeNo: method.value == 'cheque' ? chequeNoCtrl.text.trim() : null,
        chequeDate: method.value == 'cheque' && chequeDateCtrl.text.isNotEmpty ? _toYMD(chequeDateCtrl.text.trim()) : null,
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      );
      
      isSaving.value = false;
      return res['message']?.toString() ?? 'Receipt saved successfully';
    } catch (e) {
      isSaving.value = false;
      SnackbarHelper.showError(e.toString());
      return null;
    }
  }

  String _toMDY(DateTime d) => '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
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
    amountCtrl.dispose();
    dateCtrl.dispose();
    referenceCtrl.dispose();
    chequeNoCtrl.dispose();
    chequeDateCtrl.dispose();
    notesCtrl.dispose();
    super.onClose();
  }
}
