// ─────────────────────────────────────────────────────────────────────────────
// lib/features/invoices/presentation/invoice_create.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input_field.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/client_model.dart';
import '../../../data/models/service_item_model.dart';
import '../../../data/models/scenario_model.dart';
import '../controller/invoices_controller.dart';
import '../../navigation/nav_controller.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/services/company_config_service.dart';

class InvoiceCreate extends StatelessWidget {
  final int? invoiceId; // null → create, otherwise edit
  const InvoiceCreate({super.key, this.invoiceId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InvoicesController>();

    // ───── Local reactive variables (only for the form) ─────
    final _invoiceType = RxnString();
    final _registrationType = RxnString();
    final _selectedBuyer = Rxn<ClientModel>();
    final _selectedScenario = Rxn<ScenarioModel>();

    // Controllers that are NOT reactive (simple TextEditingController)
    final _invoiceDateCtrl = TextEditingController();
    final _dueDateCtrl = TextEditingController();
    final _invoiceRefCtrl = TextEditingController();
    final _notesCtrl = TextEditingController();
    final _invoiceNoCtrl = TextEditingController(text: 'Auto‑generated');
    final _shippingCtrl = TextEditingController();
    final _otherChargesCtrl = TextEditingController();
    final _discountCtrl = TextEditingController();
    final _paidAmountCtrl = TextEditingController(text: '0');
    final _chequeNoCtrl = TextEditingController();
    final _chequeDateCtrl = TextEditingController();
    final _advanceRefundCtrl = TextEditingController();

    final _paymentMethod = RxnString();
    final _paymentStatus = RxString('unpaid');
    final _selectedBankName = RxnString();

    final List<String> _banksList = const [
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

    // ───── Load data on first build ─────
    Future<void> _initData() async {
      if (invoiceId != null) {
        // ✅ Edit mode - fetch invoice and populate form
        print('📝 EDIT MODE - Invoice ID: $invoiceId');
        final success = await controller.fetchInvoiceForEdit(invoiceId: invoiceId!, tenantId: 1);

        if (!success) {
          print('❌ Failed to fetch invoice for edit');
          return;
        }

        final inv = controller.selectedInvoice.value;
        print('📝 Selected invoice: ${inv?.invoiceNo}');

        if (inv != null) {
          // Populate form fields
          _invoiceType.value = inv.invoiceType;
          print('✅ Invoice Type set: ${_invoiceType.value}');

          // Pick buyer instance from available list so DropdownButton can match by reference
          final buyers = controller.availableBuyers;
          print('👥 Available buyers: ${buyers.length}');
          print('🔍 Looking for buyer ID: ${inv.buyerId ?? inv.buyer?.byrId}');

          final buyerFromList = buyers.firstWhereOrNull(
            (b) => b.byrId == (inv.buyerId ?? inv.buyer?.byrId),
          );
          _selectedBuyer.value = buyerFromList;
          print('✅ Buyer selected: ${buyerFromList?.byrName ?? "NOT FOUND"}');

          // Populate dates
          if (inv.invoiceDate != null) {
            final d = inv.invoiceDate!;
            _invoiceDateCtrl.text = '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
            print('✅ Invoice Date set: ${_invoiceDateCtrl.text}');
          }
          if (inv.dueDate != null) {
            final d = inv.dueDate!;
            _dueDateCtrl.text = '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
            print('✅ Due Date set: ${_dueDateCtrl.text}');
          }

          // Populate scenario
          final scenarios = controller.availableScenarios;
          print('📋 Available scenarios: ${scenarios.length}');
          String normalize(String? v) => (v ?? '').trim().toUpperCase();
          String onlyDigits(String? v) => (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');

          final invScenarioRaw = inv.scenarioId?.toString();
          final invScenario = normalize(invScenarioRaw);
          final invDigits = onlyDigits(invScenarioRaw);

          final scenario = scenarios.firstWhereOrNull((s) {
            final codeNorm = normalize(s.scenarioCode);
            final codeDigits = onlyDigits(s.scenarioCode);

            if (codeNorm == invScenario) return true; // exact match
            if (invScenario.isNotEmpty && codeNorm.endsWith(invScenario)) return true; // e.g. "SN018" vs "018"
            if (invScenario.isNotEmpty && invScenario.endsWith(codeNorm)) return true;

            if (codeDigits.isNotEmpty && invDigits.isNotEmpty && codeDigits == invDigits) {
              return true;
            }
            return false;
          });

          _selectedScenario.value = scenario;
          print('✅ Scenario selected: ${scenario?.scenarioCode ?? "NOT FOUND"}');

          // Populate other fields
          _invoiceRefCtrl.text = '';
          _notesCtrl.text = inv.notes ?? '';
          _invoiceNoCtrl.text = inv.invoiceNo ?? 'Auto‑generated';
          
          _shippingCtrl.text = inv.shippingCharges != null && inv.shippingCharges! > 0 
              ? inv.shippingCharges!.toStringAsFixed(2) : '';
          _otherChargesCtrl.text = inv.otherCharges != null && inv.otherCharges! > 0 
              ? inv.otherCharges!.toStringAsFixed(2) : '';
          _discountCtrl.text = inv.discountAmount != null && inv.discountAmount! > 0 
              ? inv.discountAmount!.toStringAsFixed(2) : '';
          _paidAmountCtrl.text = inv.paidAmount != null ? inv.paidAmount!.toStringAsFixed(2) : '0.00';
          
          if (inv.paymentMethod != null && inv.paymentMethod!.isNotEmpty) {
            _paymentMethod.value = inv.paymentMethod!.toLowerCase();
          }
          if (inv.paymentStatus != null && inv.paymentStatus!.isNotEmpty) {
             _paymentStatus.value = inv.paymentStatus!.toLowerCase();
          }
          
          _selectedBankName.value = inv.bankName;
          _chequeNoCtrl.text = inv.chequeNo ?? '';
          if (inv.chequeDate != null) {
            final cd = inv.chequeDate!;
            _chequeDateCtrl.text = '${cd.month.toString().padLeft(2, '0')}/${cd.day.toString().padLeft(2, '0')}/${cd.year}';
          }

          print('✅ Invoice No set: ${_invoiceNoCtrl.text}');
          print('✅ Summary fields populated: Shipping=${_shippingCtrl.text}, Paid=${_paidAmountCtrl.text}');
          print('✅ Payment Method: ${_paymentMethod.value}');
          print('📋 DEBUG - Payment fields from API:');
          print('   paidAmount: ${inv.paidAmount}');
          print('   paymentMethod: ${inv.paymentMethod}');
          print('   paymentStatus: ${inv.paymentStatus}');
          print('   bankName: ${inv.bankName}');
          print('   chequeNo: ${inv.chequeNo}');
          print('   chequeDate: ${inv.chequeDate}');

          // Derive Registration Type (trust byrType only)
          final b = buyerFromList ?? inv.buyer;
          if (b != null) {
            final isReg = (b.byrType == 1);
            _registrationType.value = isReg ? 'Registered' : 'Unregistered';
            print('✅ Registration Type set: ${_registrationType.value}');
          }

          print('📋 Invoice details count: ${inv.details?.length ?? 0}');
          print('✅ Form population complete!');
        } else {
          print('❌ Invoice is null after fetch');
        }
      } else {
        // ✅ Create mode - load initial data based on stored company configuration
        print('📝 CREATE MODE');

        int? busConfigId;
        try {
          final config = await CompanyConfigService.getConfiguration();
          if (config != null) {
            final rawId = config['bus_config_id'];
            if (rawId is int) {
              busConfigId = rawId;
            } else if (rawId is String) {
              busConfigId = int.tryParse(rawId);
            }
            print('🏢 Loaded bus_config_id from storage: $busConfigId');
          } else {
            print('⚠️ No company configuration found in storage, falling back to default bus_config_id=1');
            busConfigId = 1;
          }
        } catch (e) {
          print('❌ Failed to load company configuration: $e');
          busConfigId = 1;
        }

        await controller.fetchInvoiceCreateData(busConfigId: busConfigId, tenantId: 1);

        // auto‑select scenario if server/config marked one via "selected" flag
        final pre = controller.availableScenarios.firstWhereOrNull((s) => s.selected);
        _selectedScenario.value = pre;
        print('✅ Pre-selected Scenario from config: ${pre?.scenarioCode ?? "NONE"}');
      }
    }

    // run once
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          invoiceId == null ? 'Add New Invoice' : 'Edit Invoice',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(ctx).maybePop(),
          ),
        ),
      ),
      body: Obx(() {
        final seller = controller.seller.value;
        final buyers = controller.availableBuyers;
        final items = controller.availableItems;
        final details = controller.invoiceDetails;
        final isEditMode = invoiceId != null;
        final isAlreadyPosted = isEditMode && (controller.selectedInvoice.value?.isPostedToFbr == 1);

        return Form(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ───── Invoice Info ─────
              _sectionTitle('Invoice Info'),
              _card(Column(children: [
                Row(children: [
                  Expanded(
                    child: _dropdownFieldRequired(
                      label: 'Invoice Type *',
                      value: _invoiceType.value,
                      // Must match backend values (InvoiceModel.invoiceType)
                      items: const ['Sale Invoice', 'Debit Note'],
                      hint: 'Select Invoice Type',
                      onChanged: (v) => _invoiceType.value = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppInputField(
                      label: 'Invoice Date *',
                      controller: _invoiceDateCtrl,
                      hint: 'mm/dd/yyyy',
                      suffixIcon: const Icon(Icons.calendar_today),
                      readOnly: true,
                      onTap: () async => _pickDate(context, _invoiceDateCtrl),
                      validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: AppInputField(
                      label: 'Due Date',
                      controller: _dueDateCtrl,
                      hint: 'mm/dd/yyyy',
                      suffixIcon: const Icon(Icons.calendar_today),
                      readOnly: true,
                      onTap: () async => _pickDate(context, _dueDateCtrl),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppInputField(
                      label: 'Invoice #',
                      controller: _invoiceNoCtrl,
                      enabled: false,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                // ✅ Added Scenario dropdown
                Obx(() => _dropdownScenarioRequired(
                  'Scenario ID *',
                  controller.availableScenarios,
                  _selectedScenario.value,
                  (s) {
                    _selectedScenario.value = s;
                    // ✅ Debug: Print scenario details
                    print('🔍 Selected Scenario: ${s?.scenarioCode}');
                    print('🔍 Scenario Description: ${s?.scenarioDescription}');
                    print('🔍 Sale Type: ${s?.saleType}');
                  },
                )),
                const SizedBox(height: 12),
                Obx(() => _invoiceType.value == 'Debit Note'
                    ? AppInputField(
                        label: 'Invoice Ref No (If Debit Note)',
                        controller: _invoiceRefCtrl,
                        hint: 'Enter reference number',
                      )
                    : const SizedBox.shrink()),
              ])),

              // ───── Seller Info ─────
              _sectionTitle('Seller Info'),
              _card(Column(children: [
                Row(children: [
                  Expanded(
                    child: AppInputField(
                      label: 'NTN / CNIC *',
                      controller: TextEditingController(text: seller?.busNtnCnic ?? ''),
                      enabled: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppInputField(
                      label: 'Business Name *',
                      controller: TextEditingController(text: seller?.busName ?? ''),
                      enabled: false,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: AppInputField(
                      label: 'Province *',
                      controller: TextEditingController(text: seller?.busProvince ?? ''),
                      enabled: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppInputField(
                      label: 'Address *',
                      controller: TextEditingController(text: seller?.busAddress ?? ''),
                      enabled: false,
                    ),
                  ),
                ]),
              ])),

              // ───── Client Info ─────
              _sectionTitle('Client Info'),
              _card(Column(children: [
                if (_registrationType.value == 'Unregistered')
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Note: If Client Registration Type is Unregistered, then all fields except Registration Type are optional.',
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ]),
                  ),
                _dropdownBuyerRequired(
                  label: 'Select Client *',
                  buyers: buyers,
                  selected: _selectedBuyer.value,
                  onChanged: (c) {
                    _selectedBuyer.value = c;
                    // ✅ Debug: Print byrType to check API data
                    print('🔍 Selected Client: ${c?.byrName}');
                    print('🔍 byrType: ${c?.byrType}');
                    print('🔍 byrRegNum: ${c?.byrRegNum}');
                    print('🔍 byrNtnCnic: ${c?.byrNtnCnic}');

                    final isReg = (c?.byrType == 1);
                    _registrationType.value = isReg ? 'Registered' : 'Unregistered';
                    print('🔍 Registration Type: ${_registrationType.value}');
                  },
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: Obx(() => AppInputField(
                          label: 'NTN / CNIC',
                          controller: TextEditingController(text: _selectedBuyer.value?.byrNtnCnic ?? ''),
                          enabled: false,
                        )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => AppInputField(
                          label: 'Business Name',
                          controller: TextEditingController(text: _selectedBuyer.value?.byrName ?? ''),
                          enabled: false,
                        )),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: Obx(() => AppInputField(
                          label: 'Province',
                          controller: TextEditingController(text: _selectedBuyer.value?.byrProvince ?? ''),
                          enabled: false,
                        )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => AppInputField(
                          label: 'Registration Type *',
                          controller: TextEditingController(text: _registrationType.value ?? 'Unregistered'),
                          enabled: false,
                        )),
                  ),
                ]),
                const SizedBox(height: 12),
                Obx(() => AppInputField(
                      label: 'Address',
                      controller: TextEditingController(text: _selectedBuyer.value?.byrAddress ?? ''),
                      enabled: false,
                    )),
              ])),

              // ───── Invoice Items ─────
              _sectionTitle('Invoice Items'),
              Obx(() {
                final d = controller.invoiceDetails;
                final saleType = _deriveSaleType(_selectedScenario.value);
                return Column(children: [
                  for (int i = 0; i < d.length; i++) _itemCard(i, d[i], items, saleType),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => controller.addInvoiceDetail(
                      InvoiceDetailModel(quantity: 1, totalValue: 0),
                    ),
                    icon: const Icon(Icons.add, color: Colors.green),
                    label: const Text('Add Another Item', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ]);
              }),

              // ───── Summary ─────
              _sectionTitle('Invoice Summary'),
              Obx(() => _summaryCard(
                controller.invoiceDetails,
                _shippingCtrl,
                _otherChargesCtrl,
                _discountCtrl,
                _paidAmountCtrl,
                _paymentMethod,
                _paymentStatus,
                _selectedBankName,
                _chequeNoCtrl,
                _chequeDateCtrl,
                _banksList,
                context,
              )),

              const SizedBox(height: 12),
              // ───── Notes (moved before buttons) ─────
              AppInputField(label: 'Notes', controller: _notesCtrl, hint: 'Enter any notes', maxLines: 3),

              const SizedBox(height: 16),

              // ───── Action Buttons ─────
              Row(
                children: isAlreadyPosted
                    ? [
                        // Cancel
                        Expanded(
                          child: Builder(
                            builder: (ctx) => OutlinedButton(
                              onPressed: () {
                                print('❌ Cancel button pressed in Invoice Create');
                                Navigator.of(ctx).maybePop();
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Save as Draft
                        Expanded(
                          child: AppButton(
                            label: 'Save as Draft',
                            isLoading: controller.isSavingDraft.value,
                            onPressed: controller.isSavingDraft.value
                                ? null
                                : () async {
                                    await _saveOrPost(
                                      controller,
                                      invoiceId,
                                      ctx: context,
                                      postNow: false,
                                      invoiceType: _invoiceType,
                                      invoiceDateCtrl: _invoiceDateCtrl,
                                      dueDateCtrl: _dueDateCtrl,
                                      selectedScenario: _selectedScenario,
                                      invoiceRefCtrl: _invoiceRefCtrl,
                                      selectedBuyer: _selectedBuyer,
                                      registrationType: _registrationType,
                                      shippingCtrl: _shippingCtrl,
                                      otherChargesCtrl: _otherChargesCtrl,
                                      discountCtrl: _discountCtrl,
                                      paidAmountCtrl: _paidAmountCtrl,
                                      paymentMethod: _paymentMethod,
                                      paymentStatus: _paymentStatus,
                                      bankName: _selectedBankName,
                                      chequeNoCtrl: _chequeNoCtrl,
                                      chequeDateCtrl: _chequeDateCtrl,
                                      notesCtrl: _notesCtrl,
                                    );
                                  },
                          ),
                        ),
                      ]
                    : [
                        // Cancel
                        Expanded(
                          child: Builder(
                            builder: (ctx) => OutlinedButton(
                              onPressed: () {
                                print('❌ Cancel button pressed in Invoice Create');
                                Navigator.of(ctx).maybePop();
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Save as Draft
                        Expanded(
                          child: AppButton(
                            label: 'Save as Draft',
                            isLoading: controller.isSavingDraft.value,
                            onPressed: controller.isSavingDraft.value
                                ? null
                                : () async {
                                    await _saveOrPost(
                                      controller,
                                      invoiceId,
                                      ctx: context,
                                      postNow: false,
                                      invoiceType: _invoiceType,
                                      invoiceDateCtrl: _invoiceDateCtrl,
                                      dueDateCtrl: _dueDateCtrl,
                                      selectedScenario: _selectedScenario,
                                      invoiceRefCtrl: _invoiceRefCtrl,
                                      selectedBuyer: _selectedBuyer,
                                      registrationType: _registrationType,
                                      shippingCtrl: _shippingCtrl,
                                      otherChargesCtrl: _otherChargesCtrl,
                                      discountCtrl: _discountCtrl,
                                      paidAmountCtrl: _paidAmountCtrl,
                                      paymentMethod: _paymentMethod,
                                      paymentStatus: _paymentStatus,
                                      bankName: _selectedBankName,
                                      chequeNoCtrl: _chequeNoCtrl,
                                      chequeDateCtrl: _chequeDateCtrl,
                                      notesCtrl: _notesCtrl,
                                    );
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Post to FBR (only for non-posted invoices)
                        Expanded(
                          child: AppButton(
                            label: 'Post to FBR',
                            isLoading: controller.isPostingToFbr.value,
                            onPressed: controller.isPostingToFbr.value
                                ? null
                                : () async {
                                    await _saveOrPost(
                                      controller,
                                      invoiceId,
                                      ctx: context,
                                      postNow: true,
                                      invoiceType: _invoiceType,
                                      invoiceDateCtrl: _invoiceDateCtrl,
                                      dueDateCtrl: _dueDateCtrl,
                                      selectedScenario: _selectedScenario,
                                      invoiceRefCtrl: _invoiceRefCtrl,
                                      selectedBuyer: _selectedBuyer,
                                      registrationType: _registrationType,
                                      shippingCtrl: _shippingCtrl,
                                      otherChargesCtrl: _otherChargesCtrl,
                                      discountCtrl: _discountCtrl,
                                      paidAmountCtrl: _paidAmountCtrl,
                                      paymentMethod: _paymentMethod,
                                      paymentStatus: _paymentStatus,
                                      bankName: _selectedBankName,
                                      chequeNoCtrl: _chequeNoCtrl,
                                      chequeDateCtrl: _chequeDateCtrl,
                                      notesCtrl: _notesCtrl,
                                    );
                                  },
                          ),
                        ),
                      ],
              ),
            ],
          ),
        );
      }),
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
    Future.delayed(const Duration(milliseconds: 1400), () {
      final nav = Navigator.of(context);
      if (nav.canPop()) nav.pop();
    });
  }

  // ───── Helper Widgets ─────
  Widget _sectionTitle(String title) => Container(
    margin: const EdgeInsets.only(top: 8, bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)),
    child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
  );

  Widget _card(Widget child) => Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );

  // ───── Dropdown (required) ─────
  Widget _dropdownFieldRequired({
    required String label,
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Colors.green, width: 2)),
        errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Colors.red)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: items.map((e) => DropdownMenuItem<String>(
        value: e, 
        child: Text(e.replaceAll('_', ' ').capitalizeFirst ?? e)
      )).toList(),
      onChanged: onChanged,
      validator: validator ?? ((v) => (v == null || v.isEmpty) ? 'Required' : null),
    );
  }

  // ───── Buyer Dropdown ─────
  Widget _dropdownBuyerRequired({
    required String label,
    required List<ClientModel> buyers,
    required ClientModel? selected,
    required ValueChanged<ClientModel?> onChanged,
  }) {
    final items = [
      const DropdownMenuItem<ClientModel>(value: null, child: Text('-- Choose Client --', style: TextStyle(color: Colors.grey))),
      ...buyers.map((c) => DropdownMenuItem<ClientModel>(value: c, child: Text(c.byrName))),
    ];

    return DropdownButtonFormField<ClientModel>(
      value: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: '-- Choose Client --',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Colors.green, width: 2)),
        errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Colors.red)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: items,
      onChanged: onChanged,
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  // ───── Scenario Dropdown ─────
  Widget _dropdownScenarioRequired(
    String label,
    List<ScenarioModel> scenarios,
    ScenarioModel? selected,
    ValueChanged<ScenarioModel?> onChanged,
  ) {
    final items = [
      const DropdownMenuItem<ScenarioModel>(
        value: null,
        child: Text('-- Select Scenario --', style: TextStyle(color: Colors.grey)),
      ),
      ...scenarios.map((s) => DropdownMenuItem<ScenarioModel>(
        value: s,
        child: Text('${s.scenarioCode} - ${s.scenarioDescription}'),
      )),
    ];

    return DropdownButtonFormField<ScenarioModel>(
      value: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: '-- Select Scenario --',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Colors.green, width: 2)),
        errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Colors.red)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: items,
      onChanged: onChanged,
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  String _deriveSaleType(ScenarioModel? s) {
    if (s == null) return 'Services';
    final st = (s.saleType).trim();
    if (st.isNotEmpty) return st;
    final desc = (s.scenarioDescription).toLowerCase();
    if (desc.contains('fed') && desc.contains('st mode')) return 'Services (FED in ST Mode)';
    if (desc.contains('sale of services')) return 'Services';
    if (desc.contains('goods')) return 'Goods';
    return 'Services';
  }

  // ───── Item Card ─────
  Widget _itemCard(int index, InvoiceDetailModel detail, List<ServiceItemModel> items, String saleType) {
    final controller = Get.find<InvoicesController>();
    final selectedItem = items.firstWhereOrNull((i) => i.itemId == detail.itemId);

    // Get current values from detail or defaults
    final qty = detail.quantity ?? 0;
    final unitPrice = selectedItem?.itemPrice ?? 0.0;
    final taxRate = double.tryParse(selectedItem?.itemTaxRate ?? '') ?? 16.0;
    final fTaxPercent = detail.furtherTaxPercent ?? 0.0;
    final eTaxPercent = detail.extraTaxPercent ?? 0.0;
    final fedPercent = detail.fedPercent ?? 0.0;
    final discountVal = detail.discount ?? 0.0;

    // ✅ CRITICAL: Use stored totalValue from detail if available (edit mode), otherwise calculate fresh
    // This ensures we use the exact excluding-tax base that was parsed from the API
    final totalExcludingTax = detail.totalValue ?? (unitPrice * qty);
    final salesTax = detail.salesTaxApplicable ?? ((totalExcludingTax * taxRate) / 100.0);
    final totalIncludingTax = totalExcludingTax + salesTax;
    final furtherTax = detail.furtherTaxApplicable ?? ((fTaxPercent * totalExcludingTax) / 100.0);
    final extraTax = detail.extraTaxApplicable ?? ((eTaxPercent * totalExcludingTax) / 100.0);
    final fedPayable = (fedPercent * totalExcludingTax) / 100.0;

    // Update detail model with calculated values
    void updateCalculations({
      int? newQty,
      double? newFTaxPct,
      double? newETaxPct,
      double? newFedPct,
      double? newDiscount,
    }) {
      final q = newQty ?? qty;
      final fPct = newFTaxPct ?? fTaxPercent;
      final ePct = newETaxPct ?? eTaxPercent;
      final fedPct = newFedPct ?? fedPercent;
      final discount = newDiscount ?? discountVal;

      final excl = unitPrice * q;
      final st = (excl * taxRate) / 100.0;
      final ft = (fPct * excl) / 100.0;
      final et = (ePct * excl) / 100.0;
      final fed = (fedPct * excl) / 100.0;

      controller.updateInvoiceDetail(
        index,
        InvoiceDetailModel(
          invoiceDetailId: detail.invoiceDetailId,
          itemId: selectedItem?.itemId,
          quantity: q,
          totalValue: excl,
          salesTaxApplicable: st,
          furtherTaxApplicable: ft,
          extraTaxApplicable: et,
          furtherTaxPercent: fPct,
          extraTaxPercent: ePct,
          fedPercent: fedPct,
          discount: discount,
          item: selectedItem,
        ),
      );
      controller.invoiceDetails.refresh();
    }

    return _card(LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Item ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),

          // Row 1: Select Item (full width)
          _dropdownItem(
            label: 'Select Item/Service *',
            value: selectedItem,
            items: items,
            onChanged: (ServiceItemModel? it) {
              final unit = it?.itemPrice ?? 0;
              final q = qty;
              final rate = double.tryParse(it?.itemTaxRate ?? '') ?? 0.0;
              final excl = unit * q;
              final st = excl * (rate / 100.0);
              Get.find<InvoicesController>().updateInvoiceDetail(
                index,
                InvoiceDetailModel(
                  invoiceDetailId: detail.invoiceDetailId,
                  itemId: it?.itemId,
                  quantity: q,
                  totalValue: excl, // store excl total in model
                  salesTaxApplicable: st,
                  discount: detail.discount,
                  item: it,
                ),
              );
              Get.find<InvoicesController>().invoiceDetails.refresh();
            },
          ),
          const SizedBox(height: 12),

          // Row 2: HS Code and UoM
          Row(children: [
            Expanded(
              child: AppInputField(
                label: 'HS Code *',
                controller: TextEditingController(text: selectedItem?.itemHsCode ?? ''),
                enabled: false,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppInputField(
                label: 'UoM *',
                controller: TextEditingController(text: selectedItem?.itemUom ?? ''),
                enabled: false,
                maxLines: 1,
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Row 3: Product Description (full width)
          AppInputField(
            label: 'Product Description *',
            controller: TextEditingController(text: selectedItem?.itemDescription ?? ''),
            enabled: false,
            maxLines: 2,
          ),
          const SizedBox(height: 12),

          // Row 4: Item Price, Tax Rate, Quantity
          Row(children: [
            Expanded(
              child: AppInputField(
                label: 'Item Price *',
                controller: TextEditingController(text: unitPrice.toStringAsFixed(2)),
                hint: '0.00',
                enabled: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppInputField(
                label: 'Tax Rate in % *',
                controller: TextEditingController(text: taxRate.toStringAsFixed(0)),
                hint: '16',
                enabled: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppInputField(
                label: 'Quantity *',
                controller: TextEditingController(text: qty.toString()),
                hint: '0',
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final newQty = int.tryParse(v) ?? 0;
                  updateCalculations(newQty: newQty);
                },
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Required';
                  final n = int.tryParse(v!);
                  if (n == null || n <= 0) return 'Invalid';
                  return null;
                },
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Row 5: Totals (Excl, Incl, Sales Tax)
          if (!isNarrow)
            Row(children: [
              Expanded(
                child: AppInputField(
                  label: 'Total Excl Tax *',
                  controller: TextEditingController(text: totalExcludingTax.toStringAsFixed(2)),
                  enabled: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppInputField(
                  label: 'Total Incl Tax *',
                  controller: TextEditingController(text: totalIncludingTax.toStringAsFixed(2)),
                  enabled: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppInputField(
                  label: 'Sales Tax Applicable *',
                  controller: TextEditingController(text: salesTax.toStringAsFixed(2)),
                  enabled: false,
                ),
              ),
            ])
          else ...[
            AppInputField(
              label: 'Total Excl Tax *',
              controller: TextEditingController(text: totalExcludingTax.toStringAsFixed(2)),
              enabled: false,
            ),
            const SizedBox(height: 8),
            AppInputField(
              label: 'Total Incl Tax *',
              controller: TextEditingController(text: totalIncludingTax.toStringAsFixed(2)),
              enabled: false,
            ),
            const SizedBox(height: 8),
            AppInputField(
              label: 'Sales Tax Applicable *',
              controller: TextEditingController(text: salesTax.toStringAsFixed(2)),
              enabled: false,
            ),
          ],
          const SizedBox(height: 12),
          // Row 3b: Retail Price (separate for better mobile layout)
          Row(children: [
            Expanded(
              child: AppInputField(
                label: 'Retail Price',
                controller: TextEditingController(text: ''),
                hint: '0.00',
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Row 3c: Sale Type (full width)
          Row(children: [
            Expanded(
              child: AppInputField(
                label: 'Sale Type *',
                controller: TextEditingController(text: saleType.isNotEmpty ? saleType : 'Services'),
                enabled: false,
                maxLines: 2,
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Row 4: Further Tax %, Further Tax, Extra Tax %, Extra Tax
          if (!isNarrow)
            Row(children: [
              Expanded(
                child: AppInputField(
                  label: 'Further Tax %',
                  controller: TextEditingController(text: fTaxPercent.toStringAsFixed(0)),
                  hint: '0',
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final newPct = double.tryParse(v) ?? 0.0;
                    updateCalculations(newFTaxPct: newPct);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppInputField(
                  label: 'Further Tax',
                  controller: TextEditingController(text: furtherTax.toStringAsFixed(2)),
                  enabled: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppInputField(
                  label: 'Extra Tax %',
                  controller: TextEditingController(text: eTaxPercent.toStringAsFixed(0)),
                  hint: '0',
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final newPct = double.tryParse(v) ?? 0.0;
                    updateCalculations(newETaxPct: newPct);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppInputField(
                  label: 'Extra Tax',
                  controller: TextEditingController(text: extraTax.toStringAsFixed(2)),
                  enabled: false,
                ),
              ),
            ])
          else ...[
            AppInputField(
              label: 'Further Tax %',
              controller: TextEditingController(text: fTaxPercent.toStringAsFixed(0)),
              hint: '0',
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final newPct = double.tryParse(v) ?? 0.0;
                updateCalculations(newFTaxPct: newPct);
              },
            ),
            const SizedBox(height: 8),
            AppInputField(
              label: 'Further Tax',
              controller: TextEditingController(text: furtherTax.toStringAsFixed(2)),
              enabled: false,
            ),
            const SizedBox(height: 8),
            AppInputField(
              label: 'Extra Tax %',
              controller: TextEditingController(text: eTaxPercent.toStringAsFixed(0)),
              hint: '0',
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final newPct = double.tryParse(v) ?? 0.0;
                updateCalculations(newETaxPct: newPct);
              },
            ),
            const SizedBox(height: 8),
            AppInputField(
              label: 'Extra Tax',
              controller: TextEditingController(text: extraTax.toStringAsFixed(2)),
              enabled: false,
            ),
          ],
          const SizedBox(height: 12),

          // Row 5: FED Payable %, FED Payable, Discount
          if (!isNarrow)
            Row(children: [
              Expanded(
                child: AppInputField(
                  label: 'FED Payable %',
                  controller: TextEditingController(text: fedPercent.toStringAsFixed(0)),
                  hint: '0',
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final newPct = double.tryParse(v) ?? 0.0;
                    updateCalculations(newFedPct: newPct);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppInputField(
                  label: 'FED Payable',
                  controller: TextEditingController(text: fedPayable.toStringAsFixed(2)),
                  enabled: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppInputField(
                  label: 'Discount',
                  controller: TextEditingController(
                    // Keep zero empty so user can type freely, and avoid forcing .00
                    text: discountVal == 0
                        ? ''
                        : discountVal.toString(),
                  ),
                  hint: '0',
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final d = double.tryParse(v) ?? 0.0;
                    updateCalculations(newDiscount: d);
                  },
                ),
              ),
            ])
          else ...[
            AppInputField(
              label: 'FED Payable %',
              controller: TextEditingController(text: fedPercent.toStringAsFixed(0)),
              hint: '0',
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final newPct = double.tryParse(v) ?? 0.0;
                updateCalculations(newFedPct: newPct);
              },
            ),
            const SizedBox(height: 8),
            AppInputField(
              label: 'FED Payable',
              controller: TextEditingController(text: fedPayable.toStringAsFixed(2)),
              enabled: false,
            ),
            const SizedBox(height: 8),
            AppInputField(
              label: 'Discount',
              controller: TextEditingController(
                // Keep zero empty so user can type freely, and avoid forcing .00
                text: discountVal == 0
                    ? ''
                    : discountVal.toString(),
              ),
              hint: '0',
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final d = double.tryParse(v) ?? 0.0;
                updateCalculations(newDiscount: d);
              },
            ),
          ],
          const SizedBox(height: 12),

          // Row 6: SRO Schedule No, SRO Item Serial No, Tax Withheld, Tax Amount
          if (!isNarrow)
            Row(children: [
              Expanded(
                child: AppInputField(
                  label: 'SRO Schedule No',
                  controller: TextEditingController(text: ''),
                  hint: '',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppInputField(
                  label: 'SRO Item Serial No',
                  controller: TextEditingController(text: ''),
                  hint: '',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppInputField(
                  label: 'Tax Withheld *',
                  controller: TextEditingController(text: '0'),
                  hint: '0',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppInputField(
                  label: 'Sales Tax Amount',
                  controller: TextEditingController(text: salesTax.toStringAsFixed(2)),
                  enabled: false,
                ),
              ),
            ])
          else ...[
            AppInputField(
              label: 'SRO Schedule No',
              controller: TextEditingController(text: ''),
              hint: '',
            ),
            const SizedBox(height: 8),
            AppInputField(
              label: 'SRO Item Serial No',
              controller: TextEditingController(text: ''),
              hint: '',
            ),
            const SizedBox(height: 8),
            AppInputField(
              label: 'Tax Withheld *',
              controller: TextEditingController(text: '0'),
              hint: '0',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            AppInputField(
              label: 'Tax Amount',
              controller: TextEditingController(text: salesTax.toStringAsFixed(2)),
              enabled: false,
            ),
          ],
          const SizedBox(height: 12),

          // Remove button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => Get.find<InvoicesController>().removeInvoiceDetail(index),
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ),
        ]);
      },
    ));
  }

  // ───── Item Dropdown (custom style) ─────
  Widget _dropdownItem({
    required String label,
    required ServiceItemModel? value,
    required List<ServiceItemModel> items,
    required ValueChanged<ServiceItemModel?> onChanged,
  }) {
    final dropdownItems = [
      const DropdownMenuItem<ServiceItemModel>(
        value: null,
        child: Text(
          '-- Choose Item --',
          style: TextStyle(color: Colors.grey),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      ...items.map((it) => DropdownMenuItem<ServiceItemModel>(
            value: it,
            child: Text(
              it.itemDescription,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          )),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<ServiceItemModel>(
            value: value,
            isExpanded: true,
            hint: const Text('-- Choose Item --'),
            items: dropdownItems,
            onChanged: onChanged,
          ),
        ),
      ),
    ]);
  }

  // ───── Summary Card ─────
  Widget _summaryCard(
      List<InvoiceDetailModel> details,
      TextEditingController shippingCtrl,
      TextEditingController otherCtrl,
      TextEditingController summaryDiscountCtrl,
      TextEditingController paidAmountCtrl,
      RxnString paymentMethod,
      RxString paymentStatus,
      RxnString selectedBankName,
      TextEditingController chequeNoCtrl,
      TextEditingController chequeDateCtrl,
      List<String> banksList,
      BuildContext context,
      ) {
    // 1. Calculate base totals from all items
    final totalExc = details.fold<double>(0, (s, d) => s + (d.totalValue ?? 0));
    final totalSales = details.fold<double>(0, (s, d) => s + (d.salesTaxApplicable ?? 0));
    final totalFurther = details.fold<double>(0, (s, d) => s + (d.furtherTaxApplicable ?? 0));
    final totalExtra = details.fold<double>(0, (s, d) => s + (d.extraTaxApplicable ?? 0));
    final totalFED = details.fold<double>(0, (s, d) {
      final excl = d.totalValue ?? 0;
      final fedPct = d.fedPercent ?? 0;
      return s + ((fedPct * excl) / 100.0);
    });
    final totalItemDiscount = details.fold<double>(0, (s, d) => s + (d.discount ?? 0));
    
    // Subtotal Incl Tax = Subtotal Excl Tax + Sales Tax
    final totalInc = totalExc + totalSales;

    // 2. Summary Level Calculations
    final shipping = double.tryParse(shippingCtrl.text) ?? 0.0;
    final other = double.tryParse(otherCtrl.text) ?? 0.0;
    final summaryDiscount = double.tryParse(summaryDiscountCtrl.text) ?? 0.0;
    final paidAmount = double.tryParse(paidAmountCtrl.text) ?? 0.0;

    // Formula: Grand Total = (Subtotal Incl Tax) + taxes + shipping + other - ItemTotalDiscount
    final grandTotal = (totalInc + totalFurther + totalExtra + totalFED + shipping + other) - totalItemDiscount;
    
    // Ensure paid amount does not exceed grand total (as per user request)
    double paidAmountValue = paidAmount;
    if (paidAmountValue > grandTotal) {
      paidAmountValue = grandTotal;
      // Optionally update controller text to match if needed, but usually better to just show 0 balance
    }
    final balanceDue = (grandTotal - paidAmountValue).clamp(0.0, double.infinity);

    // Derive Payment Status automatically
    String derivedStatus = 'unpaid';
    if (paidAmountValue >= grandTotal && grandTotal > 0) {
      derivedStatus = 'paid';
    } else if (paidAmountValue > 0) {
      derivedStatus = 'partial';
    }
    paymentStatus.value = derivedStatus;

    Widget _inputRow(Widget w1, Widget w2) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [Expanded(child: w1), const SizedBox(width: 12), Expanded(child: w2)]),
    );

    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Row 1: Subtotal Excl Tax | Subtotal Incl Tax
      _inputRow(
        AppInputField(label: 'Subtotal (Excl. Tax) *', controller: TextEditingController(text: totalExc.toStringAsFixed(2)), enabled: false),
        AppInputField(label: 'Subtotal (Incl. Tax) *', controller: TextEditingController(text: totalInc.toStringAsFixed(2)), enabled: false),
      ),
      // Row 2: Sales Tax | Further Tax
      _inputRow(
        AppInputField(label: 'Sales Tax *', controller: TextEditingController(text: totalSales.toStringAsFixed(2)), enabled: false),
        AppInputField(label: 'Further Tax', controller: TextEditingController(text: totalFurther.toStringAsFixed(2)), enabled: false),
      ),
      // Row 3: Extra Tax | FED Tax
      _inputRow(
        AppInputField(label: 'Extra Tax', controller: TextEditingController(text: totalExtra.toStringAsFixed(2)), enabled: false),
        AppInputField(label: 'FED Tax', controller: TextEditingController(text: totalFED.toStringAsFixed(2)), enabled: false),
      ),
      // Row 4: Item Total Discount | Shipping Charges
      _inputRow(
        AppInputField(label: 'Items Discount', controller: TextEditingController(text: totalItemDiscount.toStringAsFixed(2)), enabled: false),
        AppInputField(label: 'Shipping Charges', controller: shippingCtrl, hint: '0', keyboardType: TextInputType.number, onChanged: (v) => Get.find<InvoicesController>().invoiceDetails.refresh()),
      ),
      // Row 5: Other Charges | Grand Total
      _inputRow(
        AppInputField(label: 'Other Charges', controller: otherCtrl, hint: '0', keyboardType: TextInputType.number, onChanged: (v) => Get.find<InvoicesController>().invoiceDetails.refresh()),
        AppInputField(label: 'Grand Total *', controller: TextEditingController(text: grandTotal.toStringAsFixed(2)), enabled: false),
      ),
      // Row 6: Paid Amount | Balance Due
      _inputRow(
        AppInputField(
          label: 'Paid Amount *', 
          controller: paidAmountCtrl, 
          hint: '0', 
          keyboardType: TextInputType.number, 
          onChanged: (v) {
            final val = double.tryParse(v) ?? 0.0;
            if (val > grandTotal) {
              paidAmountCtrl.text = grandTotal.toStringAsFixed(2);
              paidAmountCtrl.selection = TextSelection.fromPosition(TextPosition(offset: paidAmountCtrl.text.length));
            }
            Get.find<InvoicesController>().invoiceDetails.refresh();
          },
        ),
        AppInputField(label: 'Balance Due', controller: TextEditingController(text: balanceDue.toStringAsFixed(2)), enabled: false),
      ),
      
      const Divider(height: 32),
      const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
      const SizedBox(height: 12),

      // Payment Details Section
      _inputRow(
        _dropdownFieldRequired(
          label: 'Payment Method',
          value: paymentMethod.value,
          items: const ['cash', 'bank_transfer', 'cheque'],
          hint: 'Select Method',
          onChanged: (v) => paymentMethod.value = v,
          validator: (v) {
            final paid = double.tryParse(paidAmountCtrl.text) ?? 0.0;
            if (paid > 0 && (v == null || v.isEmpty)) {
              return 'Required when Paid Amount > 0';
            }
            return null;
          },
        ),
        paymentMethod.value == 'cheque'
          ? AppInputField(label: 'Cheque No', controller: chequeNoCtrl, hint: 'Enter cheque number')
          : paymentMethod.value == 'bank_transfer'
            ? _dropdownValueRequired(label: 'Bank Name', value: selectedBankName.value, items: banksList, hint: 'Select Bank', onChanged: (v) => selectedBankName.value = v)
            : const SizedBox.shrink(),
      ),

      if (paymentMethod.value == 'cheque')
        _inputRow(
          AppInputField(
            label: 'Cheque Date',
            controller: chequeDateCtrl,
            hint: 'mm/dd/yyyy',
            suffixIcon: const Icon(Icons.calendar_today),
            readOnly: true,
            onTap: () => _pickDate(context, chequeDateCtrl, firstDate: DateTime.now()),
          ),
          _dropdownValueRequired(label: 'Bank Name', value: selectedBankName.value, items: banksList, hint: 'Select Bank', onChanged: (v) => selectedBankName.value = v),
        ),
    ]));
  }

  Widget _dropdownValueRequired({
    required String label,
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Colors.green, width: 2)),
        errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Colors.red)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: items.map((e) => DropdownMenuItem<String>(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
      onChanged: onChanged,
    );
  }

  // ───── Date Picker Helper ─────
  Future<void> _pickDate(BuildContext ctx, TextEditingController ctrl, {DateTime? firstDate}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: ctx,
      initialDate: now,
      firstDate: firstDate ?? DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      ctrl.text = '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  // ───── Save or Post Invoice Helper ─────
  Future<void> _saveOrPost(
    InvoicesController controller,
    int? invoiceId,
    {
    required BuildContext ctx,
    required bool postNow,
    required RxnString invoiceType,
    required TextEditingController invoiceDateCtrl,
    required TextEditingController dueDateCtrl,
    required Rxn<ScenarioModel> selectedScenario,
    required TextEditingController invoiceRefCtrl,
    required Rxn<ClientModel> selectedBuyer,
    required RxnString registrationType,
    required TextEditingController shippingCtrl,
    required TextEditingController otherChargesCtrl,
    required TextEditingController discountCtrl,
    required TextEditingController paidAmountCtrl,
    required RxnString paymentMethod,
    required RxString paymentStatus,
    required RxnString bankName,
    required TextEditingController chequeNoCtrl,
    required TextEditingController chequeDateCtrl,
    required TextEditingController notesCtrl,
    }
  ) async {
    void _resetButtonLoaders() {
      controller.isSavingDraft.value = false;
      controller.isPostingToFbr.value = false;
    }

    controller.isSavingDraft.value = !postNow;
    controller.isPostingToFbr.value = postNow;

    if (invoiceType.value == null || invoiceType.value!.isEmpty) {
      _showBottomSheetMessage(ctx, success: false, message: 'Please select Invoice Type');
      _resetButtonLoaders();
      return;
    }
    if (invoiceDateCtrl.text.isEmpty) {
      _showBottomSheetMessage(ctx, success: false, message: 'Please select Invoice Date');
      _resetButtonLoaders();
      return;
    }
    if (dueDateCtrl.text.isEmpty) {
      _showBottomSheetMessage(ctx, success: false, message: 'Please select Due Date');
      _resetButtonLoaders();
      return;
    }
    if (selectedScenario.value == null) {
      _showBottomSheetMessage(ctx, success: false, message: 'Please select Scenario');
      _resetButtonLoaders();
      return;
    }
    if (selectedBuyer.value == null) {
      _showBottomSheetMessage(ctx, success: false, message: 'Please select Client');
      _resetButtonLoaders();
      return;
    }

    final paidAmt = double.tryParse(paidAmountCtrl.text) ?? 0.0;
    if (paidAmt > 0 && (paymentMethod.value == null || paymentMethod.value!.isEmpty)) {
      _showBottomSheetMessage(ctx, success: false, message: 'Please select Payment Method (Paid Amount > 0)');
      _resetButtonLoaders();
      return;
    }

    final seller = controller.seller.value;
    if (seller == null) {
      _showBottomSheetMessage(ctx, success: false, message: 'Seller info not available');
      _resetButtonLoaders();
      return;
    }

    final busId = seller.busConfigId;
    final buyerId = selectedBuyer.value?.byrId;
    if (busId == null || buyerId == null) {
      _showBottomSheetMessage(ctx, success: false, message: 'Invalid ID configuration');
      _resetButtonLoaders();
      return;
    }

    // Calculations
    final totalExc = controller.invoiceDetails.fold<double>(0, (s, d) => s + (d.totalValue ?? 0));
    final totalSales = controller.invoiceDetails.fold<double>(0, (s, d) => s + (d.salesTaxApplicable ?? 0));
    final totalFurther = controller.invoiceDetails.fold<double>(0, (s, d) => s + (d.furtherTaxApplicable ?? 0));
    final totalExtra = controller.invoiceDetails.fold<double>(0, (s, d) => s + (d.extraTaxApplicable ?? 0));
    final totalFED = controller.invoiceDetails.fold<double>(0, (s, d) {
      final excl = d.totalValue ?? 0;
      final fedPct = d.fedPercent ?? 0;
      return s + ((fedPct * excl) / 100.0);
    });
    final totalItemsDiscount = controller.invoiceDetails.fold<double>(0, (s, d) => s + (d.discount ?? 0));
    final totalInc = totalExc + totalSales;

    final shipping = double.tryParse(shippingCtrl.text) ?? 0.0;
    final other = double.tryParse(otherChargesCtrl.text) ?? 0.0;
    final summaryDiscount = double.tryParse(discountCtrl.text) ?? 0.0;
    final paid = double.tryParse(paidAmountCtrl.text) ?? 0.0;

    final grandTotal = (totalInc + totalFurther + totalExtra + totalFED + shipping + other) - summaryDiscount - totalItemsDiscount;
    final balanceDue = grandTotal - paid;

    final items = controller.invoiceDetails.map((detail) {
      final item = detail.item;
      final excl = detail.totalValue ?? 0;
      final salesTax = detail.salesTaxApplicable ?? 0;
      final fedPct = detail.fedPercent ?? 0;
      final fedPayable = (fedPct * excl) / 100.0;
      
      return {
        'item_id': detail.itemId ?? item?.itemId,
        'hsCode': item?.itemHsCode ?? '',
        'productDescription': item?.itemDescription ?? '',
        'rate': item?.itemTaxRate ?? '0',
        'uoM': item?.itemUom ?? '',
        'quantity': detail.quantity ?? 0,
        'totalValues': excl + salesTax, // Subtotal including sales tax
        'valueSalesExcludingST': excl,
        'fixedNotifiedValueOrRetailPrice': 0,
        'SalesTaxApplicable': salesTax,
        'SalesTaxWithheldAtSource': 0,
        'extraTax': detail.extraTaxApplicable ?? 0,
        'furtherTax': detail.furtherTaxApplicable ?? 0,
        'sroScheduleNo': '',
        'fedPayable': fedPayable,
        'discount': detail.discount ?? 0,
        'saleType': selectedScenario.value?.saleType ?? 'Services',
        'sroItemSerialNo': '',
      };
    }).toList();

    String convertDate(String d) {
       final p = d.split('/');
       return (p.length == 3) ? '${p[2]}-${p[0]}-${p[1]}' : d;
    }

    final result = await controller.saveOrPostInvoice(
      invoiceId: invoiceId,
      busConfigId: busId,
      postNow: postNow,
      invoiceType: invoiceType.value!,
      invoiceDate: convertDate(invoiceDateCtrl.text),
      dueDate: convertDate(dueDateCtrl.text),
      scenarioId: selectedScenario.value!.scenarioCode,
      invoiceRefNo: invoiceRefCtrl.text.isEmpty ? null : invoiceRefCtrl.text,
      sellerId: busId,
      buyerId: buyerId,
      buyerRegistrationType: registrationType.value ?? 'Unregistered',
      sellerNTNCNIC: seller.busNtnCnic ?? '',
      sellerBusinessName: seller.busName ?? '',
      sellerProvince: seller.busProvince ?? '',
      sellerAddress: seller.busAddress ?? '',
      buyerNTNCNIC: selectedBuyer.value!.byrNtnCnic ?? '',
      buyerProvince: selectedBuyer.value!.byrProvince ?? '',
      buyerBusinessName: selectedBuyer.value!.byrName ?? '',
      buyerAddress: selectedBuyer.value!.byrAddress ?? '',
      totalAmountExcludingTax: totalExc,
      totalAmountIncludingTax: totalInc,
      totalSalesTax: totalSales,
      totalFurtherTax: totalFurther,
      totalExtraTax: totalExtra,
      totalFedTax: totalFED,
      totalDiscount: totalItemsDiscount,
      shippingCharges: shipping,
      otherCharges: other,
      discountAmount: summaryDiscount,
      grandTotal: grandTotal,
      paidAmount: paid,
      balanceDue: balanceDue,
      paymentMethod: paymentMethod.value ?? '',
      bankName: bankName.value,
      chequeNo: chequeNoCtrl.text.isEmpty ? null : chequeNoCtrl.text,
      chequeDate: chequeDateCtrl.text.isEmpty ? null : convertDate(chequeDateCtrl.text),
      paymentStatus: paymentStatus.value,
      notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
      items: items,
    );

    if (result != null) {
      _resetButtonLoaders();
      final message = postNow ? 'Invoice posted successfully' : 'Invoice saved successfully';
      final nav = Get.key.currentState;
      if (nav != null && nav.canPop()) nav.pop(true);
      if (Get.isRegistered<NavController>()) Get.find<NavController>().changeTab(1);
      if (Get.isRegistered<InvoicesController>()) Get.find<InvoicesController>().fetchInvoices(refresh: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = Get.context;
        if (ctx != null) _showBottomSheetMessage(ctx, success: true, message: message);
      });
    } else {
      _resetButtonLoaders();
    }
  }
}