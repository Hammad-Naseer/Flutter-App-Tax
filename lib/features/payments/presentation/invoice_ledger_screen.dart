import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/invoice_ledger_model.dart';
import '../../../data/models/client_model.dart';
import '../../../data/models/invoice_model.dart';
import '../controller/invoice_ledger_controller.dart';

class InvoiceLedgerScreen extends GetView<InvoiceLedgerController> {
  const InvoiceLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Invoice Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilters(context),
          Expanded(
            child: Obx(() {
              if (controller.entries.isEmpty && !controller.isLoading.value) {
                return _buildEmptyState();
              }
              return RefreshIndicator(
                onRefresh: () => controller.fetch(reset: true),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = controller.entries[index];
                    return _buildLedgerCard(entry);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(() => _dropdownField<ClientModel?>(
                      hint: 'Client *',
                      value: controller.selectedClient.value,
                      items: [
                        const DropdownMenuItem<ClientModel?>(value: null, child: Text('-- Select Client --', style: TextStyle(color: Colors.grey))),
                        ...controller.clients.map((c) => DropdownMenuItem<ClientModel?>(value: c, child: Text(c.byrName, overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: (val) {
                        controller.selectedClient.value = val;
                        if (val != null) {
                          controller.loadInvoicesForClient(val.byrId);
                        } else {
                          controller.invoices.clear();
                          controller.selectedInvoice.value = null;
                        }
                      },
                    )),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(() => _dropdownField<InvoiceModel>(
                      hint: 'Invoice No',
                      value: controller.selectedInvoice.value,
                      isLoading: controller.isLoadingInvoices.value,
                      items: controller.invoices.map((i) => DropdownMenuItem(value: i, child: Text(i.invoiceNo ?? 'N/A'))).toList(),
                      onChanged: (val) => controller.selectedInvoice.value = val,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(() => _dropdownField<String>(
                      hint: 'Entry Type',
                      value: controller.selectedEntryType.value,
                      items: controller.entryTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.capitalizeFirst!.replaceAll('_', ' ')))).toList(),
                      onChanged: (val) => controller.selectedEntryType.value = val ?? 'all',
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _dateField(context, controller.dateFromCtrl, 'From')),
              const SizedBox(width: 8),
              Expanded(child: _dateField(context, controller.dateToCtrl, 'To')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => controller.fetch(reset: true),
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: const Text('Apply Filter'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: controller.clearFilters,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text('Clear', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdownField<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          hint: Text(isLoading ? 'Loading...' : hint, style: const TextStyle(fontSize: 13)),
          value: value,
          items: items,
          onChanged: isLoading ? null : onChanged,
        ),
      ),
    );
  }

  Widget _dateField(BuildContext context, TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (date != null) ctrl.text = DateFormat('MM/dd/yyyy').format(date);
      },
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: const Icon(Icons.calendar_today, size: 16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildLedgerCard(InvoiceLedgerEntry entry) {
    final date = DateTime.tryParse(entry.createdAt);
    final dateStr = date != null ? DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal()) : entry.createdAt;
    
    final isDebit = double.tryParse(entry.debit) != 0;
    final color = isDebit ? Colors.red : Colors.green;
    final typeLabel = entry.entryType.capitalizeFirst!.replaceAll('_', ' ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Header with Entry Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.invoice?.invoiceNo ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: entry.entryType == 'invoice_created' ? Colors.blue.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: entry.entryType == 'invoice_created' ? Colors.blue.shade700 : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _row('Description', entry.description, isBolding: true),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(child: _amountCol('Debit', entry.debit, Colors.red)),
                    Container(height: 30, width: 1, color: Colors.grey.shade200),
                    Expanded(child: _amountCol('Credit', entry.credit, Colors.green)),
                  ],
                ),
                const Divider(height: 24),
                _row('Balance After', 'PKR ${_formatAmount(entry.balanceAfter)}', valueColor: AppColors.primary, isBolding: true),
                if (entry.metadata != null && entry.metadata!['invoice_no'] != null) ...[
                  const SizedBox(height: 8),
                  Text('Ref: ${entry.metadata!['invoice_no']}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor, bool isBolding = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBolding ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _amountCol(String label, String amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          _formatAmount(amount),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 70, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          const Text('Search result will appear here', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const Text('Select a client and invoice to begin', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatAmount(String amount) {
    try {
      final double val = double.parse(amount);
      return NumberFormat('#,##0.00').format(val);
    } catch (_) {
      return amount;
    }
  }
}
