import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/client_model.dart';
import '../controller/receipt_voucher_create_controller.dart';
import '../controller/receipt_vouchers_controller.dart';

class ReceiptVoucherCreateScreen extends StatefulWidget {
  const ReceiptVoucherCreateScreen({super.key});

  @override
  State<ReceiptVoucherCreateScreen> createState() => _ReceiptVoucherCreateScreenState();
}

class _ReceiptVoucherCreateScreenState extends State<ReceiptVoucherCreateScreen> {
  final ctrl = Get.find<ReceiptVoucherCreateController>();

  void _showBottomSheetMessage({required bool success, required String message}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(success ? Icons.check_circle : Icons.error_rounded,
                    color: success ? Colors.green : Colors.red, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSave() async {
    final result = await ctrl.submit();
    if (result != null) {
      _showBottomSheetMessage(success: true, message: result);
      
      // Refresh the list if the controller is registered
      if (Get.isRegistered<ReceiptVouchersController>()) {
        Get.find<ReceiptVouchersController>().fetch(reset: true);
      }
      
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop(); // Close bottom sheet
      
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) Navigator.of(context).pop(); // Close form screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Add Receipt Voucher',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close, color: Colors.grey),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: ctrl.formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // === Client & Balance Card ===
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF), // Softer light blue
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD1E9FF), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          text: 'Select Client ',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                          children: [
                            TextSpan(text: '*', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Obx(() => DropdownButtonFormField<ClientModel?>(
                        isExpanded: true,
                        value: ctrl.selectedClient.value,
                        hint: const Text('Choose a client...', style: TextStyle(fontSize: 14)),
                        decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: [
                          const DropdownMenuItem<ClientModel?>(value: null, child: Text('-- Select Client --')),
                          ...ctrl.clients.map((c) => DropdownMenuItem<ClientModel?>(value: c, child: Text(c.byrName))),
                        ],
                        onChanged: (v) async => await ctrl.onClientChanged(v),
                        validator: (v) => v == null ? 'Required' : null,
                      )),

                      const SizedBox(height: 20),

                      // Balance | Paid Amount | Remaining
                      LayoutBuilder(builder: (ctx, cons) {
                        final width = cons.maxWidth;
                        final spacing = width < 350 ? 8.0 : 12.0;

                        return Obx(() => Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _statField('Balance', ctrl.buyerBalance.value.toStringAsFixed(2), flex: 3),
                                SizedBox(width: spacing),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Paid Amount',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: ctrl.amountCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                        decoration: InputDecoration(
                                          fillColor: Colors.white,
                                          filled: true,
                                          border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: Colors.grey.shade300)),
                                          enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: Colors.grey.shade300)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                          isDense: true,
                                        ),
                                        validator: (v) {
                                          final val = double.tryParse((v ?? '').replaceAll(',', '')) ?? 0;
                                          if (val <= 0) return 'Required';
                                          return null;
                                        },
                                        inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                    onChanged: (value) {
                                      if (value.isEmpty) {
                                        ctrl.buyerBalance.refresh();
                                        return;
                                      }
                                      double amount = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
                                      final max = ctrl.buyerBalance.value;
                                      if (amount > max) {
                                        amount = max;
                                        ctrl.amountCtrl.text = amount.toStringAsFixed(2);
                                        ctrl.amountCtrl.selection = TextSelection.fromPosition(
                                            TextPosition(offset: ctrl.amountCtrl.text.length));
                                      }
                                      ctrl.buyerBalance.refresh();
                                    },
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: spacing),
                                _statField('Remaining', ctrl.remaining.toStringAsFixed(2), flex: 3),
                              ],
                            ));
                      }),

                      const SizedBox(height: 24),

                      // View Pending Invoices Button
                      Obx(() => SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: ctrl.canViewInvoices ? () => _showPendingInvoices(context, ctrl) : null,
                          icon: Icon(Icons.description_outlined, size: 18, color: ctrl.canViewInvoices ? const Color(0xFF6E91FF) : Colors.grey),
                          label: Text(
                            'View Pending Invoices',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ctrl.canViewInvoices ? const Color(0xFF6E91FF) : Colors.grey,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: ctrl.canViewInvoices ? const Color(0xFFC7D8FF) : Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            backgroundColor: Colors.white,
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Payment Date & Method
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            text: 'Payment Date ',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                            children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: ctrl.dateCtrl,
                          readOnly: true,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade400)),
                            suffixIcon: const Icon(Icons.calendar_month_outlined, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            fillColor: const Color(0xFFF8F9FA),
                            filled: true,
                          ),
                          onTap: () => ctrl.pickDate(context, ctrl.dateCtrl),
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            text: 'Payment Method ',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                            children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Obx(() => DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: ctrl.method.value.isEmpty ? null : ctrl.method.value,
                          hint: const Text('Select Method', style: TextStyle(fontSize: 14)),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade400)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            fillColor: const Color(0xFFF8F9FA),
                            filled: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Select Method', style: TextStyle(fontSize: 14))),
                            DropdownMenuItem(value: 'cash', child: Text('Cash', style: TextStyle(fontSize: 14))),
                            DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer', style: TextStyle(fontSize: 14))),
                            DropdownMenuItem(value: 'cheque', child: Text('Cheque', style: TextStyle(fontSize: 14))),
                          ],
                          onChanged: (v) => ctrl.method.value = v ?? '',
                        )),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Method Specific Fields
              _methodSpecificFields(ctrl, context),

              const SizedBox(height: 20),

              // Reference No
              const Text('Reference No', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: ctrl.referenceCtrl,
                decoration: const InputDecoration(
                  hintText: 'Enter reference number...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),

              const SizedBox(height: 20),

              // Notes
              const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: ctrl.notesCtrl,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Additional notes...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),

              const SizedBox(height: 40),

              // Cancel + Save Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() => ElevatedButton(
                      onPressed: ctrl.isSaving.value ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00AA55), // Figma green
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: ctrl.isSaving.value
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _balanceField(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(
        value,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _statField(String label, String value, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500), maxLines: 1),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F8), // Soft gray for read-only
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodSpecificFields(ReceiptVoucherCreateController ctrl, BuildContext context) {
    return Obx(() {
      if (ctrl.method.value.isEmpty || ctrl.method.value == 'cash') return const SizedBox.shrink();

      if (ctrl.method.value == 'bank_transfer') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bank Name *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: ctrl.bankName.value.isEmpty ? null : ctrl.bankName.value,
              decoration: InputDecoration(
                hintText: 'Select Bank',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade400)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                fillColor: const Color(0xFFF8F9FA),
                filled: true,
              ),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('Select Bank', style: TextStyle(fontSize: 14))),
                ...ctrl.banks.map((b) => DropdownMenuItem<String>(value: b, child: Text(b, style: const TextStyle(fontSize: 14)))),
              ],
              onChanged: (v) => ctrl.bankName.value = v ?? '',
              validator: (_) => (ctrl.method.value == 'bank_transfer' && ctrl.bankName.value.isEmpty) ? 'Required' : null,
            ),
          ],
        );
      }

      // Cheque
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cheque No *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: ctrl.chequeNoCtrl,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade400)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        fillColor: const Color(0xFFF8F9FA),
                        filled: true,
                      ),
                      validator: (v) => (ctrl.method.value == 'cheque' && (v?.isEmpty ?? true)) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cheque Date *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: ctrl.chequeDateCtrl,
                      readOnly: true,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade400)),
                        suffixIcon: const Icon(Icons.calendar_month_outlined, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        fillColor: const Color(0xFFF8F9FA),
                        filled: true,
                      ),
                      onTap: () => ctrl.pickDate(context, ctrl.chequeDateCtrl),
                      validator: (v) => (ctrl.method.value == 'cheque' && (v?.isEmpty ?? true)) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Bank Name *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: ctrl.bankName.value.isEmpty ? null : ctrl.bankName.value,
            decoration: InputDecoration(
              hintText: 'Select Bank',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade400)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              fillColor: const Color(0xFFF8F9FA),
              filled: true,
            ),
            items: [
              const DropdownMenuItem<String>(value: null, child: Text('Select Bank', style: TextStyle(fontSize: 14))),
              ...ctrl.banks.map((b) => DropdownMenuItem<String>(value: b, child: Text(b, style: const TextStyle(fontSize: 14)))),
            ],
            onChanged: (v) => ctrl.bankName.value = v ?? '',
            validator: (_) => (ctrl.method.value == 'cheque' && ctrl.bankName.value.isEmpty) ? 'Required' : null,
          ),
        ],
      );
    });
  }
  void _showPendingInvoices(BuildContext context, ReceiptVoucherCreateController ctrl) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: AppColors.primary, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Pending Invoices',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.grey),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Content
              Flexible(
                child: ctrl.pendingInvoices.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'No pending invoices found.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: ctrl.pendingInvoices.length,
                        itemBuilder: (context, index) {
                          final inv = ctrl.pendingInvoices[index];
                          final invNo = inv['invoice_no']?.toString() ?? '-';
                          final invDate = inv['invoice_date']?.toString() ?? '-';
                          final balance = inv['balance_due']?.toString() ?? '0.00';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        invNo,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            invDate,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Balance Due',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'PKR $balance',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        foregroundColor: Colors.blue,
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}