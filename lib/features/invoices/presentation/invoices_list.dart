import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/invoice_model.dart';
import '../controller/invoices_controller.dart';
import 'invoice_create.dart';
import 'invoice_detail.dart';
import '../../navigation/nav_controller.dart';

class InvoicesList extends StatefulWidget {
  const InvoicesList({super.key});

  @override
  State<InvoicesList> createState() => _InvoicesListState();
}

class _InvoicesListState extends State<InvoicesList> {
  final Set<int> _expanded = <int>{};

  String? _filterInvoiceType; // 'Sale Invoice' or 'Debit Note'
  int? _filterIsPostedToFbr; // 1 = Yes, 0 = No, null = All
  DateTime? _filterDateFrom;
  DateTime? _filterDateTo;
  final TextEditingController _dateFromCtrl = TextEditingController();
  final TextEditingController _dateToCtrl = TextEditingController();

  @override
  void dispose() {
    _dateFromCtrl.dispose();
    _dateToCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // When Invoices screen opens, clear any previous filter state and fetch latest invoices
    final controller = Get.find<InvoicesController>();
    controller.activeInvoiceType = null;
    controller.activeDateFrom = null;
    controller.activeDateTo = null;
    controller.activeIsPostedToFbr = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchInvoices(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InvoicesController>();

    final navCtrl = Get.find<NavController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Invoices',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: () => controller.fetchInvoices(refresh: true),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.invoices.isEmpty) {
          return const Center(child: AppLoader());
        }

        if (controller.invoices.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long,
            title: 'No Invoices',
            message: 'Create your first invoice to get started',
            actionLabel: 'Add Invoice',
            onAction: () async {
              final ok = await _preflightCreate(context);
              if (ok) Get.to(() => const InvoiceCreate());
            },
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchInvoices(refresh: true),
          child: Column(
            children: [
              // Search + Add
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Invoice Type + Posted to FBR
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            value: _filterInvoiceType,
                            decoration: const InputDecoration(
                              labelText: 'Invoice Type',
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem<String?>(value: null, child: Text('All Types')),
                              DropdownMenuItem<String?>(value: 'Sale Invoice', child: Text('Sale Invoice')),
                              DropdownMenuItem<String?>(value: 'Debit Note', child: Text('Debit Note')),
                            ],
                            onChanged: (String? v) {
                              setState(() {
                                _filterInvoiceType = v;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Posted to FBR?',
                              isDense: true,
                            ),
                            value: _filterIsPostedToFbr == null
                                ? 'all'
                                : (_filterIsPostedToFbr == 1 ? 'yes' : 'no'),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All')),
                              DropdownMenuItem(value: 'yes', child: Text('Yes')),
                              DropdownMenuItem(value: 'no', child: Text('No')),
                            ],
                            onChanged: (v) {
                              setState(() {
                                if (v == 'yes') {
                                  _filterIsPostedToFbr = 1;
                                } else if (v == 'no') {
                                  _filterIsPostedToFbr = 0;
                                } else {
                                  _filterIsPostedToFbr = null;
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Row 2: Date From + Date To + Filter / Clear buttons (responsive for mobile)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isNarrow = constraints.maxWidth < 380;

                        Widget buildDateRow() => Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _dateFromCtrl,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Date From',
                                  isDense: true,
                                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                                ),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _filterDateFrom ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _filterDateFrom = picked;
                                      _dateFromCtrl.text = _formatDisplayDate(picked);
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _dateToCtrl,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Date To',
                                  isDense: true,
                                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                                ),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _filterDateTo ?? (_filterDateFrom ?? DateTime.now()),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _filterDateTo = picked;
                                      _dateToCtrl.text = _formatDisplayDate(picked);
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        );

                        Widget buildButtonsRow({bool expanded = true}) {
                          final filterButton = SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () async {
                                final dateFrom = _filterDateFrom != null ? _formatYMD(_filterDateFrom!) : null;
                                final dateTo = _filterDateTo != null ? _formatYMD(_filterDateTo!) : null;
                                await controller.fetchInvoices(
                                  refresh: true,
                                  invoiceType: _filterInvoiceType,
                                  dateFrom: dateFrom,
                                  dateTo: dateTo,
                                  isPostedToFbr: _filterIsPostedToFbr,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Filter', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          );

                          final clearButton = SizedBox(
                            height: 44,
                            child: OutlinedButton(
                              onPressed: () async {
                                final controller = Get.find<InvoicesController>();
                                setState(() {
                                  _filterInvoiceType = null;
                                  _filterIsPostedToFbr = null;
                                  _filterDateFrom = null;
                                  _filterDateTo = null;
                                  _dateFromCtrl.clear();
                                  _dateToCtrl.clear();
                                });
                                controller.activeInvoiceType = null;
                                controller.activeDateFrom = null;
                                controller.activeDateTo = null;
                                controller.activeIsPostedToFbr = null;
                                await controller.fetchInvoices(refresh: true);
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Clear', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          );

                          if (expanded) {
                            return Row(
                              children: [
                                Expanded(child: filterButton),
                                const SizedBox(width: 8),
                                Expanded(child: clearButton),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              filterButton,
                              const SizedBox(width: 8),
                              clearButton,
                            ],
                          );
                        }

                        if (isNarrow) {
                          return Column(
                            children: [
                              buildDateRow(),
                              const SizedBox(height: 8),
                              buildButtonsRow(expanded: true),
                            ],
                          );
                        }

                        // Wide screens: single-row layout similar to original
                        return Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _dateFromCtrl,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Date From',
                                  isDense: true,
                                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                                ),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _filterDateFrom ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _filterDateFrom = picked;
                                      _dateFromCtrl.text = _formatDisplayDate(picked);
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _dateToCtrl,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Date To',
                                  isDense: true,
                                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                                ),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _filterDateTo ?? (_filterDateFrom ?? DateTime.now()),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _filterDateTo = picked;
                                      _dateToCtrl.text = _formatDisplayDate(picked);
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            buildButtonsRow(expanded: false),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: ListView.separated(
                  // Extra bottom padding so the last card does not touch screen edge / FAB
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: controller.invoices.length + (controller.isLoadingMore.value ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == controller.invoices.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: AppLoader(),
                        ),
                      );
                    }

                    final inv = controller.invoices[index];
                    return _invoiceCard(context, inv, controller);
                  },
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ok = await _preflightCreate(context);
          if (ok) Get.to(() => const InvoiceCreate());
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Invoice',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
        currentIndex: navCtrl.currentIndex.value,
        onTap: navCtrl.changeTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Invoices'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clients'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      )),
    );
  }

  void _showBottomSheetMessage(BuildContext context, {required bool success, required String message}) {
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
                Icon(success ? Icons.check_circle : Icons.error_rounded, color: success ? Colors.green : Colors.red, size: 24),
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
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    });
  }

  Widget _invoiceCard(BuildContext context, InvoiceModel inv, InvoicesController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallWidth = constraints.maxWidth < 360;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header: number, date, buyer + FBR chips and amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv.invoiceNo ?? 'INV-${inv.invoiceId}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            inv.invoiceDate != null ? _fmtDate(inv.invoiceDate!) : '-',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Buyer:',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  inv.buyer?.byrName ?? '-',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                  maxLines: isSmallWidth ? 2 : 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _chip('FBR', Colors.green),
                            const SizedBox(width: 6),
                            _chip(
                              inv.isPostedToFbr == 1 ? 'Posted' : 'Pending',
                              inv.isPostedToFbr == 1 ? Colors.green : Colors.orange,
                            ),
                            if (inv.isPostedToFbr != 1) ...[
                              const SizedBox(width: 4),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                                onSelected: (v) async {
                                  if (v == 'edit' && inv.invoiceId != 0) {
                                    Get.to(() => InvoiceCreate(invoiceId: inv.invoiceId));
                                  } else if (v == 'delete') {
                                    final ok = await controller.deleteInvoice(inv.invoiceId, silent: true);
                                    if (ok) {
                                      _showBottomSheetMessage(context,
                                          success: true, message: 'Invoice deleted successfully');
                                    } else {
                                      _showBottomSheetMessage(context,
                                          success: false, message: 'Failed to delete invoice');
                                    }
                                  } else if (v == 'post') {
                                    final ok = await controller.postToFBR(inv.invoiceId, silent: true);
                                    if (ok) {
                                      _showBottomSheetMessage(context,
                                          success: true, message: 'Invoice posted to FBR successfully');
                                    } else {
                                      _showBottomSheetMessage(context,
                                          success: false, message: 'Failed to post invoice');
                                    }
                                  }
                                },
                                itemBuilder: (context) {
                                  return const [
                                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(value: 'post', child: Text('Post to FBR')),
                                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ];
                                },
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          inv.formattedTotal,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Actions row: View / Print / expand / menu
                if (!isSmallWidth) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showItemDetails(inv),
                          icon: const Icon(Icons.visibility, size: 18, color: AppColors.textSecondary),
                          label: const Text('View'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: const StadiumBorder(),
                            side: BorderSide(color: Colors.grey.shade300),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => controller.printInvoice(inv.invoiceId, fallback: inv),
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
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          _expanded.contains(inv.invoiceId)
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_expanded.contains(inv.invoiceId)) {
                              _expanded.remove(inv.invoiceId);
                            } else {
                              _expanded.add(inv.invoiceId);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ] else ...[
                  // Compact, mobile-friendly layout: buttons full-width in two rows
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showItemDetails(inv),
                              icon: const Icon(Icons.visibility, size: 18, color: AppColors.textSecondary),
                              label: const Text('View'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: const StadiumBorder(),
                                side: BorderSide(color: Colors.grey.shade300),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => controller.printInvoice(inv.invoiceId, fallback: inv),
                              icon: const Icon(Icons.print, size: 18, color: AppColors.textSecondary),
                              label: const Text('Print'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: const StadiumBorder(),
                                side: BorderSide(color: Colors.grey.shade300),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(
                              _expanded.contains(inv.invoiceId)
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                if (_expanded.contains(inv.invoiceId)) {
                                  _expanded.remove(inv.invoiceId);
                                } else {
                                  _expanded.add(inv.invoiceId);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],

                // Extra bottom spacing so buttons don't touch card edge
                const SizedBox(height: 8),

                // Expanded details section
                if (_expanded.contains(inv.invoiceId)) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isSmallWidth) ...[
                          Row(
                            children: [
                              Expanded(child: _kv('Type:', inv.invoiceType ?? 'Regular')),
                              Expanded(child: _kv('FBR Env:', 'Sandbox')),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _kv(
                                  'Further Tax:',
                                  'PKR ${(inv.totalFurtherTax ?? 0).toStringAsFixed(0)}',
                                ),
                              ),
                              Expanded(
                                child: _kv(
                                  'Tampered:',
                                  (inv.buyer?.tampered == true) ? 'Yes' : 'No',
                                  highlight: inv.buyer?.tampered != true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _kv('Seller:', inv.seller?.busName ?? '-'),
                        ] else ...[
                          // On very small screens, show details in a clean vertical list
                          _kv('Type:', inv.invoiceType ?? 'Regular'),
                          const SizedBox(height: 6),
                          _kv('FBR Env:', 'Sandbox'),
                          const SizedBox(height: 6),
                          _kv(
                            'Further Tax:',
                            'PKR ${(inv.totalFurtherTax ?? 0).toStringAsFixed(0)}',
                          ),
                          const SizedBox(height: 6),
                          _kv(
                            'Tampered:',
                            (inv.buyer?.tampered == true) ? 'Yes' : 'No',
                            highlight: inv.buyer?.tampered != true,
                          ),
                          const SizedBox(height: 6),
                          _kv('Seller:', inv.seller?.busName ?? '-'),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmtDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}-${_mon(d.month)}-${d.year}';
  }

  // UI display format for filter dates (dd/MM/yyyy)
  String _formatDisplayDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year.toString().padLeft(4, '0')}';
  }

  String _formatYMD(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _mon(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  void _showItemDetails(InvoiceModel inv) {
    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: InvoiceDetailDialog(invoice: inv),
      ),
    );
  }

  Future<bool> _preflightCreate(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final busConfigIdStr = prefs.getString('bus_config_id') ?? prefs.getString('tenant_id') ?? '1';
      final busConfigId = int.tryParse(busConfigIdStr) ?? 1;

      // Direct API probe to ensure we capture server message exactly
      final api = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : ApiClient();
      final res = await api.postFormData(
        ApiEndpoints.invoicesCreate,
        fields: {
          'bus_config_id': busConfigId.toString(),
          'tenant_id': busConfigId.toString(),
        },
        requiresAuth: true,
      );

      final isSuccess = res['success'] == true;
      if (!isSuccess) {
        final msg = (res['message'] ?? 'Invoices limit exceeded for your package.').toString();
        _showBottomSheetMessage(
          context,
          success: false,
          message: msg,
        );
        return false;
      }
      return true;
    } catch (e) {
      _showBottomSheetMessage(
        context,
        success: false,
        message: e.toString(),
      );
      return false;
    }
  }

  Widget _kv(String k, String v, {bool highlight = false}) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(k, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(
            v,
            style: TextStyle(fontSize: 13, color: highlight ? Colors.green : AppColors.textPrimary, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
