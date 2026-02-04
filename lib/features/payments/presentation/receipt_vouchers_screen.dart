import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/client_model.dart';
import '../../payments/controller/receipt_vouchers_controller.dart';

class ReceiptVouchersScreen extends StatelessWidget {
  const ReceiptVouchersScreen({super.key});

  Future<void> _pickDate(BuildContext context, TextEditingController ctrl) async {
    final now = DateTime.now();
    DateTime? initial;
    try {
      if (ctrl.text.isNotEmpty) {
        final parts = ctrl.text.split('/');
        if (parts.length == 3) {
          initial = DateTime(int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
        }
      }
    } catch (_) {}
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ctrl.text = '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ReceiptVouchersController>();

    return Scaffold(
      resizeToAvoidBottomInset: true, // Important for keyboard handling
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Receipt Vouchers', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filters card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client + Method (responsive) - FIXED: Separate Obx for each dropdown
                  LayoutBuilder(builder: (c, cons) {
                    final narrow = cons.maxWidth < 380;

                    final clientField = Obx(() => DropdownButtonFormField<ClientModel?>(
                      value: ctrl.selectedClient.value,
                      isExpanded: true,
                      menuMaxHeight: 300,
                      decoration: const InputDecoration(labelText: 'Client *', isDense: true),
                      items: [
                        const DropdownMenuItem<ClientModel?>(value: null, child: Text('-- Select Client --')),
                        ...ctrl.clients.map((c) => DropdownMenuItem<ClientModel?>(value: c, child: Text(c.byrName)))
                      ],
                      onChanged: (v) => ctrl.selectedClient.value = v,
                    ));

                    final methodField = Obx(() => DropdownButtonFormField<String>(
                      value: ctrl.method.value,
                      decoration: const InputDecoration(labelText: 'Method', isDense: true),
                      menuMaxHeight: 300,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                        DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                      ],
                      onChanged: (v) => ctrl.method.value = v ?? 'all',
                    ));

                    if (narrow) {
                      return Column(children: [clientField, const SizedBox(height: 8), methodField]);
                    }
                    return Row(children: [Expanded(child: clientField), const SizedBox(width: 8), Expanded(child: methodField)]);
                  }),
                  const SizedBox(height: 8),
                  // Date From / To
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl.dateFromCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: 'Date From', isDense: true, suffixIcon: Icon(Icons.calendar_today, size: 18)),
                        onTap: () => _pickDate(context, ctrl.dateFromCtrl),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: ctrl.dateToCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: 'Date To', isDense: true, suffixIcon: Icon(Icons.calendar_today, size: 18)),
                        onTap: () => _pickDate(context, ctrl.dateToCtrl),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  // Buttons
                  Row(children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (ctrl.selectedClient.value == null) {
                            SnackbarHelper.showWarning('Please select a client');
                            return;
                          }
                          await ctrl.fetch(reset: true);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Filter'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: ctrl.clearFilters,
                        child: const Text('Clear'),
                      ),
                    ),
                  ]),
                ],
              ),
            ),

            // List - remains the same
            Expanded(
              child: Obx(() {
                if (ctrl.isLoading.value && ctrl.items.isEmpty) {
                  return const Center(child: AppLoader());
                }
                if (ctrl.items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No receipt vouchers found', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  );
                }
                return NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                      ctrl.fetch();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80), // Increased bottom padding for FAB
                    itemCount: ctrl.items.length + (ctrl.isLoadingMore.value ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index >= ctrl.items.length) {
                        return const Center(child: Padding(padding: EdgeInsets.all(12), child: AppLoader()));
                      }
                      final v = ctrl.items[index];
                      final badgeColor = () {
                        switch (v.paymentMethod) {
                          case 'cash':
                            return Colors.green;
                          case 'bank_transfer':
                            return Colors.blue;
                          case 'cheque':
                            return Colors.orange;
                          default:
                            return Colors.grey;
                        }
                      }();
                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(v.paymentNo, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: badgeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: badgeColor.withOpacity(0.4))),
                                    child: Text(
                                      v.paymentMethod.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? w : (w[0].toUpperCase() + w.substring(1))).join(' '),
                                      style: TextStyle(color: badgeColor, fontWeight: FontWeight.w600, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _kv('Date', v.paymentDate),
                              _kv('Amount', 'PKR ${v.paymentAmount}'),
                              if ((v.referenceNo ?? '').isNotEmpty) _kv('Reference', v.referenceNo!),
                              _kv('Received By', v.receivedByName ?? '-'),
                              _kv('Client', v.buyerName ?? '-'),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => ctrl.printReceiptVoucher(v.paymentId),
                                  icon: const Icon(Icons.print, size: 18, color: AppColors.textSecondary),
                                  label: const Text('Print'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: const StadiumBorder(),
                                    side: BorderSide(color: Colors.grey.shade300),
                                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.paymentsReceiptCreate),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Receipt',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );

  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text('$k:', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        Expanded(child: Text(v, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
      ],
    ),
  );
}