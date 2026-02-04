import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/client_ledger_model.dart';
import '../../../data/models/client_model.dart';
import '../controller/client_ledger_controller.dart';

class ClientLedgerScreen extends GetView<ClientLedgerController> {
  const ClientLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilters(context),
          Obx(() {
            if (controller.entries.isEmpty && !controller.isLoading.value && controller.selectedClient.value != null) {
              return Expanded(child: _buildEmptyState());
            }
            if (controller.selectedClient.value == null) {
              return Expanded(child: _buildWelcomeState());
            }
            return Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.fetch(reset: true),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    const Text(
                      'Ledger Entries',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    _buildEntriesList(),
                  ],
                ),
              ),
            );
          }),
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
          // Client Dropdown
          Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ClientModel?>(
                    isExpanded: true,
                    hint: const Text('Select Client *'),
                    value: controller.selectedClient.value,
                    items: [
                      const DropdownMenuItem<ClientModel?>(value: null, child: Text('-- Select Client --', style: TextStyle(color: Colors.grey))),
                      ...controller.clients.map((c) {
                        return DropdownMenuItem<ClientModel?>(
                          value: c,
                          child: Text(c.byrName, overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      controller.selectedClient.value = val;
                      if (val != null) {
                        controller.fetch(reset: true);
                      } else {
                        controller.entries.clear();
                      }
                    },
                  ),
                ),
              )),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _dateField(context, controller.dateFromCtrl, 'Start Date'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dateField(context, controller.dateToCtrl, 'End Date'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => controller.fetch(reset: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Filter'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: controller.clearFilters,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Clear', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ],
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
        if (date != null) {
          ctrl.text = DateFormat('MM/dd/yyyy').format(date);
        }
      },
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: const Icon(Icons.calendar_month, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _summaryCard('Total Invoiced', controller.totalInvoiced.value, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _summaryCard('Total Paid', controller.totalPaid.value, Colors.green)),
          ],
        ),
        const SizedBox(height: 12),
        _summaryCard('Total Balance', controller.totalBalance.value, Colors.red, isFullWidth: true),
      ],
    );
  }

  Widget _summaryCard(String title, String amount, Color color, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: isFullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            'PKR ${_formatAmount(amount)}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final e = controller.entries[index];
          return _ledgerCard(e);
        },
      );
    });
  }

  Widget _ledgerCard(ClientLedgerEntry e) {
    final date = DateTime.tryParse(e.createdAt);
    final dateStr = date != null ? DateFormat('dd-MMM-yyyy hh:mm a').format(date.toLocal()) : e.createdAt;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Header: Date & Balance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    dateStr,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'PKR ${_formatAmount(e.totalBalance)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _kvRow('Total Invoiced', e.totalInvoiced, Colors.blue),
                const Divider(height: 20),
                _kvRow('Total Paid', e.totalPaid, Colors.green),
                const Divider(height: 20),
                _kvRow('Inv Balance', e.invBalAmount, e.invBalAmount.startsWith('-') ? Colors.green : Colors.red),
                if (e.lastPaymentDate != null) ...[
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Last Payment', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text(DateFormat('dd-MMM-yyyy').format(DateTime.parse(e.lastPaymentDate!)),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kvRow(String label, String value, Color valueColor) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            'PKR ${_formatAmount(value)}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No ledger entries found', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildWelcomeState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search, size: 80, color: Colors.green.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text('Select a client to view their ledger',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          const Text('Use the filters above to narrow results',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
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
