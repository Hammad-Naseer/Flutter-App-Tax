import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/invoice_model.dart';

class InvoiceDetailDialog extends StatelessWidget {
  final InvoiceModel invoice;
  const InvoiceDetailDialog({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final details = invoice.details ?? [];
    final totalExc = invoice.totalAmountExcludingTax ?? 0;
    final totalSales = invoice.totalSalesTax ?? 0;
    final totalFurther = invoice.totalFurtherTax ?? 0;
    final totalInc = invoice.totalAmount ?? 0;

    return Container(
      width: Get.width * 0.9,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Invoice Item Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  print('❌ Close button pressed in Invoice Detail Dialog');
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Get.back();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: const Row(
              children: [
                Expanded(child: Text('DESCRIPTION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)) ),
                SizedBox(width: 8),
                SizedBox(width: 60, child: Text('QTY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                SizedBox(width: 80, child: Text('PRICE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          ...details.map((d) => Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.item?.itemDescription ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Wrap(spacing: 16, runSpacing: 6, children: [
                            Text('Price: PKR ${(d.totalValue ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
                            Text('Tax: ${(d.salesTaxApplicable ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(width: 60, child: Text('${d.quantity ?? 0}')),
                    SizedBox(width: 80, child: Text('PKR ${(d.totalValue ?? 0).toStringAsFixed(0)}')),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _row('Total (Exc):', 'PKR ${totalExc.toStringAsFixed(0)}'),
                _row('Sales Tax:', 'PKR ${totalSales.toStringAsFixed(0)}'),
                _row('Further Tax:', 'PKR ${totalFurther.toStringAsFixed(0)}'),
                const SizedBox(height: 6),
                _row('Total (Inc Tax):', 'PKR ${totalInc.toStringAsFixed(0)}', highlight: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                print('❌ Close button (bottom) pressed in Invoice Detail Dialog');
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Get.back();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Close'),
            ),
          )
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: highlight ? Colors.green : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
