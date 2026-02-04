// ─────────────────────────────────────────────────────────────────────────────
// lib/features/invoices/controller/invoices_controller.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:get/get.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/invoice_pdf.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/client_model.dart';
import '../../../data/models/service_item_model.dart';
import '../../../data/models/scenario_model.dart';
import '../../../data/repositories/invoice_repository.dart';

class InvoicesController extends GetxController {
  final InvoiceRepository _repository;

  InvoicesController(this._repository);

  // ───── Observable State ─────
  final RxList<InvoiceModel> invoices = <InvoiceModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxInt currentPage = 1.obs;
  final RxInt lastPage = 1.obs;
  final RxInt total = 0.obs;

  // Separate loading flags for invoice create actions
  final RxBool isSavingDraft = false.obs;
  final RxBool isPostingToFbr = false.obs;

  // ───── Filter State for Listing ─────
  String? activeInvoiceType; // e.g. 'Sale Invoice' or 'Debit Note'
  String? activeDateFrom; // 'YYYY-MM-DD'
  String? activeDateTo;   // 'YYYY-MM-DD'
  int? activeIsPostedToFbr; // 1 = Yes, 0 = No, null = All

  // ───── Selected Invoice for Edit ─────
  final Rx<InvoiceModel?> selectedInvoice = Rx<InvoiceModel?>(null);
  final RxList<ClientModel> availableBuyers = <ClientModel>[].obs;
  final RxList<ServiceItemModel> availableItems = <ServiceItemModel>[].obs;
  final RxList<ScenarioModel> availableScenarios = <ScenarioModel>[].obs;
  final Rx<SellerModel?> seller = Rx<SellerModel?>(null);

  // ───── Invoice Form State ─────
  final RxList<InvoiceDetailModel> invoiceDetails = <InvoiceDetailModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchInvoices();
  }

  // ───── Print / Share Invoice PDF ─────
  Future<void> printInvoice(int invoiceId, {InvoiceModel? fallback}) async {
    try {
      print('🖨️ Print Invoice Started - ID: $invoiceId');
      isLoading.value = true;

      // ✅ Get tenant_id from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final tenantId = prefs.getString('tenant_id') ?? prefs.getString('bus_config_id');
      print('📋 Tenant ID for print: $tenantId');

      InvoiceModel inv;
      try {
        final result = await _repository.fetchInvoiceForEdit(
          invoiceId: invoiceId,
          tenantId: tenantId != null ? int.tryParse(tenantId) : null,
        );
        inv = result['invoice'] as InvoiceModel;
        print('✅ Invoice fetched from API');
      } catch (e) {
        print('⚠️ Failed to fetch invoice from API: $e');
        if (fallback != null) {
          inv = fallback;
          print('✅ Using fallback invoice');
          print('📋 Fallback Invoice ID: ${inv.invoiceId}');
          print('📋 Fallback Invoice No: ${inv.invoiceNo}');
          print('📋 Fallback QR Code: ${inv.qrCode}');
          print('📋 Fallback FBR Invoice Number: ${inv.fbrInvoiceNumber}');
        } else {
          rethrow;
        }
      }


      print('📄 Generating PDF...');
      print('📋 Invoice QR Code value: ${inv.qrCode}');
      print('📋 Invoice FBR Number: ${inv.fbrInvoiceNumber}');
      print('📋 Invoice is posted to FBR: ${inv.isPostedToFbr}');
      final bytes = await InvoicePdf.generate(inv);
      print('✅ PDF generated - Size: ${bytes.length} bytes');

      // Try to open platform print preview (may not work on some emulators)
      try {
        print('🖨️ Opening print preview...');
        await Printing.layoutPdf(onLayout: (format) async => bytes);
        print('✅ Print preview opened');
      } catch (e) {
        print('⚠️ Print preview failed: $e');
        /* ignore and continue to share */
      }

      // Offer share/download
      String name = inv.invoiceNo ?? 'INV-${inv.invoiceId.toString().padLeft(6, '0')}';
      if (!name.toLowerCase().endsWith('.pdf')) {
        name = '$name.pdf';
      }
      try {
        print('📤 Sharing PDF: $name');
        await Printing.sharePdf(bytes: bytes, filename: name);
        print('✅ PDF shared successfully');
        try {
          if (Get.overlayContext != null) {
            SnackbarHelper.showSuccess('PDF generated successfully');
          } else {
            print('⚠️ Unable to show success snackbar (no overlay)');
          }
        } catch (snackErr) {
          print('⚠️ Failed to show success snackbar: $snackErr');
        }
      } catch (e) {
        print('⚠️ Share PDF failed: $e');
        try {
          if (Get.overlayContext != null) {
            SnackbarHelper.showError('Failed to share PDF: $e');
          } else {
            print('⚠️ Unable to show error snackbar (no overlay). Error: $e');
          }
        } catch (snackErr) {
          print('⚠️ Failed to show error snackbar: $snackErr');
        }
      }
    } catch (e) {
      print('❌ Print Invoice Error: $e');
      try {
        if (Get.overlayContext != null) {
          SnackbarHelper.showError('Failed to generate PDF: $e');
        } else {
          print('⚠️ Unable to show error snackbar (no overlay). Error: $e');
        }
      } catch (snackErr) {
        print('⚠️ Failed to show error snackbar: $snackErr');
      }
    } finally {
      isLoading.value = false;
      print('🖨️ Print Invoice Completed');
    }
  }

  // ───── Load data for Create Invoice form ─────
  Future<bool> fetchInvoiceCreateData({int? busConfigId, int? tenantId}) async {
    try {
      clearInvoiceForm();
      isLoading.value = true;
      print('📝 Invoice Create: Loading data - busConfigId: $busConfigId, tenantId: $tenantId');

      final result = await _repository.fetchInvoiceCreateData(
        busConfigId: busConfigId,
        tenantId: tenantId,
      );

      print('📝 Invoice Create: API Response keys: ${result.keys.toList()}');

      // ---------- Seller ----------
      seller.value = result['seller'] != null
          ? SellerModel.fromJson(result['seller'])
          : null;
      print('🏢 Seller loaded: ${seller.value?.busName ?? "NULL"}');

      // ---------- Buyers ----------
      final buyersList = result['buyers'] as List?;
      availableBuyers.assignAll(
        buyersList?.map((e) => ClientModel.fromJson(e)).toList() ?? [],
      );
      print('👥 Buyers loaded: ${availableBuyers.length}');

      // ---------- Items ----------
      final itemsList = result['items'] as List?;
      availableItems.assignAll(
        itemsList?.map((e) => ServiceItemModel.fromJson(e)).toList() ?? [],
      );
      print('📦 Items loaded: ${availableItems.length}');

      // ---------- Scenarios ----------
      final scenariosList = result['scenarios'] as List?;
      availableScenarios.assignAll(
        scenariosList?.map((e) => ScenarioModel.fromJson(e)).toList() ?? [],
      );
      print('📋 Scenarios loaded: ${availableScenarios.length}');

      if (availableScenarios.isEmpty) {
        print('⚠️ WARNING: No scenarios loaded! Check API response.');
      } else {
        // print('📋 First scenario: ${availableScenarios.first.scenarioCode} - ${availableScenarios.first.scenarioName}');
      }

      // Add a default empty row (only once)
      if (invoiceDetails.isEmpty) {
        addInvoiceDetail(InvoiceDetailModel(quantity: 1, totalValue: 0));
      }

      return true;
    } catch (e, s) {
      print('❌ Invoice Create: Error loading data: $e');
      print('❌ Stack trace: $s');
      try {
        // Avoid crashing if there is no Overlay available yet
        if (Get.overlayContext != null) {
          SnackbarHelper.showError(e.toString());
        } else {
          print('⚠️ Unable to show snackbar (no overlay). Error: $e');
        }
      } catch (err) {
        print('⚠️ Failed to show error snackbar: $err');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ───── Fetch Invoices ─────
  Future<void> fetchInvoices({
    bool refresh = false,
    String? invoiceType,
    String? dateFrom,
    String? dateTo,
    int? isPostedToFbr,
  }) async {
    try {
      if (refresh) {
        currentPage.value = 1;
        invoices.clear();
      }

      isLoading.value = true;
      // If new filter values provided, update active filter state
      if (invoiceType != null || dateFrom != null || dateTo != null || isPostedToFbr != null) {
        activeInvoiceType = invoiceType;
        activeDateFrom = dateFrom;
        activeDateTo = dateTo;
        activeIsPostedToFbr = isPostedToFbr;
      }

      final bool hasFilters =
          (activeInvoiceType != null && activeInvoiceType!.isNotEmpty) ||
          (activeDateFrom != null && activeDateFrom!.isNotEmpty) ||
          (activeDateTo != null && activeDateTo!.isNotEmpty) ||
          (activeIsPostedToFbr != null);

      final result = hasFilters
          ? await _repository.fetchInvoicesFiltered(
              page: currentPage.value,
              invoiceType: activeInvoiceType,
              dateFrom: activeDateFrom,
              dateTo: activeDateTo,
              isPostedToFbr: activeIsPostedToFbr,
            )
          : await _repository.fetchInvoices(page: currentPage.value);

      invoices.value = result['invoices'] as List<InvoiceModel>;
      currentPage.value = result['current_page'];
      lastPage.value = result['last_page'];
      total.value = result['total'];
    } catch (e) {
      SnackbarHelper.showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ───── Load More Invoices ─────
  Future<void> loadMore() async {
    if (isLoadingMore.value || currentPage.value >= lastPage.value) return;

    try {
      isLoadingMore.value = true;
      currentPage.value++;
      final bool hasFilters =
          (activeInvoiceType != null && activeInvoiceType!.isNotEmpty) ||
          (activeDateFrom != null && activeDateFrom!.isNotEmpty) ||
          (activeDateTo != null && activeDateTo!.isNotEmpty) ||
          (activeIsPostedToFbr != null);

      final result = hasFilters
          ? await _repository.fetchInvoicesFiltered(
              page: currentPage.value,
              invoiceType: activeInvoiceType,
              dateFrom: activeDateFrom,
              dateTo: activeDateTo,
              isPostedToFbr: activeIsPostedToFbr,
            )
          : await _repository.fetchInvoices(page: currentPage.value);

      invoices.addAll(result['invoices'] as List<InvoiceModel>);
      lastPage.value = result['last_page'];
      total.value = result['total'];
    } catch (e) {
      SnackbarHelper.showError(e.toString());
      currentPage.value--; // Revert page increment on error
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ───── Create Draft Invoice ─────
  Future<InvoiceModel?> createDraftInvoice({
    required int busConfigId,
    int? tenantId,
  }) async {
    try {
      // isLoading can still be used for global operations (like list reloads),
      // but for the form buttons we rely on isSavingDraft / isPostingToFbr.
      isLoading.value = true;

      final newInvoice = await _repository.createInvoice(
        busConfigId: busConfigId,
        tenantId: tenantId,
      );

      invoices.insert(0, newInvoice);
      total.value++;

      // Show message in UI layer (bottom sheet). Keep Snackbar optional.
      // SnackbarHelper.showSuccess('Draft invoice created successfully');
      return newInvoice;
    } catch (e) {
      SnackbarHelper.showError(e.toString());
      return null;
    } finally {
      isLoading.value = false;
      isSavingDraft.value = false;
      isPostingToFbr.value = false;
    }
  }

  // ───── Fetch Invoice for Edit ─────
  Future<bool> fetchInvoiceForEdit({
    required int invoiceId,
    int? tenantId,
  }) async {
    try {
      isLoading.value = true;
      print('📝 Fetching invoice for edit - ID: $invoiceId');

      final result = await _repository.fetchInvoiceForEdit(
        invoiceId: invoiceId,
        tenantId: tenantId,
      );

      print('📝 API Response keys: ${result.keys.toList()}');

      selectedInvoice.value = result['invoice'] as InvoiceModel;
      print('✅ Invoice loaded: ${selectedInvoice.value?.invoiceNo}');
      print('📋 Invoice Type: ${selectedInvoice.value?.invoiceType}');
      print('📋 Scenario ID: ${selectedInvoice.value?.scenarioId}');
      print('📋 Buyer ID: ${selectedInvoice.value?.buyerId}');
      print('📋 Invoice Date: ${selectedInvoice.value?.invoiceDate}');
      print('📋 Due Date: ${selectedInvoice.value?.dueDate}');
      print('📋 Details count: ${selectedInvoice.value?.details?.length ?? 0}');

      // Parse buyers
      if (result['buyers'] != null) {
        availableBuyers.value = (result['buyers'] as List)
            .map((json) => ClientModel.fromJson(json))
            .toList();
        print('👥 Buyers loaded: ${availableBuyers.length}');
      }

      // Parse items
      if (result['items'] != null) {
        availableItems.value = (result['items'] as List)
            .map((json) => ServiceItemModel.fromJson(json))
            .toList();
        print('📦 Items loaded: ${availableItems.length}');
      }

      // Parse seller
      if (result['seller'] != null) {
        seller.value = SellerModel.fromJson(result['seller']);
        print('🏢 Seller loaded: ${seller.value?.busName}');
      }

      // ✅ Parse scenarios
      if (result['scenarios'] != null) {
        availableScenarios.value = (result['scenarios'] as List)
            .map((json) => ScenarioModel.fromJson(json))
            .toList();
        print('📋 Scenarios loaded from edit API: ${availableScenarios.length}');
      } else {
        print('⚠️ No scenarios in edit API response, falling back to create-data');
        // If edit API doesn't send scenarios, fetch them from create-data endpoint
        try {
          final sellerBusConfigId = seller.value?.busConfigId;
          final createData = await _repository.fetchInvoiceCreateData(
            busConfigId: sellerBusConfigId,
            tenantId: tenantId,
          );
          final scenariosList = createData['scenarios'] as List?;
          if (scenariosList != null) {
            availableScenarios.value =
                scenariosList.map((json) => ScenarioModel.fromJson(json)).toList();
            print('📋 Scenarios loaded from create-data: ${availableScenarios.length}');
          } else {
            print('⚠️ No scenarios in create-data response either');
          }
        } catch (e) {
          // Silent fallback; scenario dropdown will remain empty if this fails
          print('⚠️ Failed to load scenarios for edit via create-data: $e');
        }
      }

      // Set invoice details
      invoiceDetails.value = selectedInvoice.value?.details ?? [];
      print('📋 Invoice details set: ${invoiceDetails.length} items');

      return true;
    } catch (e, stack) {
      print('❌ Error fetching invoice for edit: $e');
      print('❌ Stack trace: $stack');
      SnackbarHelper.showError(e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ───── Update Invoice ─────
  Future<bool> updateInvoice({
    required int invoiceId,
    required String invoiceDate,
    required String dueDate,
    required String scenarioId,
    required int buyerId,
    String? notes,
    required List<Map<String, dynamic>> details,
    bool silent = false,
  }) async {
    try {
      isLoading.value = true;

      final updatedInvoice = await _repository.updateInvoice(
        invoiceId: invoiceId,
        invoiceDate: invoiceDate,
        dueDate: dueDate,
        scenarioId: scenarioId,
        buyerId: buyerId,
        notes: notes,
        details: details,
      );

      final index = invoices.indexWhere((inv) => inv.invoiceId == invoiceId);
      if (index != -1) {
        invoices[index] = updatedInvoice;
      }

      selectedInvoice.value = updatedInvoice;

      if (!silent) {
        SnackbarHelper.showSuccess('Invoice updated successfully');
      }
      return true;
    } catch (e) {
      if (!silent) {
        SnackbarHelper.showError(e.toString());
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ───── Delete Invoice ─────
  Future<bool> deleteInvoice(int invoiceId, {bool silent = false}) async {
    try {
      isLoading.value = true;

      await _repository.deleteInvoice(invoiceId);

      invoices.removeWhere((inv) => inv.invoiceId == invoiceId);
      total.value--;

      if (!silent) {
        SnackbarHelper.showSuccess('Invoice deleted successfully');
      }
      return true;
    } catch (e) {
      if (!silent) {
        SnackbarHelper.showError(e.toString());
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ───── Post Invoice to FBR ─────
  Future<bool> postToFBR(int invoiceId, {bool silent = false}) async {
    try {
      isLoading.value = true;

      final updatedInvoice = await _repository.postToFBR(invoiceId);

      final index = invoices.indexWhere((inv) => inv.invoiceId == invoiceId);
      if (index != -1) {
        invoices[index] = updatedInvoice;
      }

      selectedInvoice.value = updatedInvoice;

      if (!silent) {
        SnackbarHelper.showSuccess('Invoice posted to FBR successfully');
      }
      return true;
    } catch (e) {
      if (!silent) {
        SnackbarHelper.showError(e.toString());
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ───── Add Invoice Detail ─────
  void addInvoiceDetail(InvoiceDetailModel detail) {
    invoiceDetails.add(detail);
  }

  // ───── Remove Invoice Detail ─────
  void removeInvoiceDetail(int index) {
    invoiceDetails.removeAt(index);
  }

  // ───── Update Invoice Detail ─────
  void updateInvoiceDetail(int index, InvoiceDetailModel detail) {
    invoiceDetails[index] = detail;
  }

  // ───── Clear Invoice Form ─────
  void clearInvoiceForm() {
    selectedInvoice.value = null;
    invoiceDetails.clear();
    availableBuyers.clear();
    availableItems.clear();
    availableScenarios.clear();
    seller.value = null;
  }

  // ───── Save Draft Invoice ─────
  Future<InvoiceModel?> saveDraftInvoice({
    required int busConfigId,
    required String invoiceType,
    required String invoiceDate,
    required String dueDate,
    required String scenarioId,
    String? invoiceRefNo,
    required int sellerId,
    required int buyerId,
    required String buyerRegistrationType,
    required String sellerNTNCNIC,
    required String sellerBusinessName,
    required String sellerProvince,
    required String sellerAddress,
    required String buyerNTNCNIC,
    required String buyerProvince,
    required String buyerBusinessName,
    required String buyerAddress,
    required double totalAmountExcludingTax,
    required double totalAmountIncludingTax,
    required double totalSalesTax,
    required double totalFurtherTax,
    required double totalExtraTax,
    required double totalFedTax,
    required double totalDiscount,
    required double shippingCharges,
    required double otherCharges,
    required double discountAmount,
    required String paymentStatus,
    String? notes,
    required int invoiceStatus,
    required List<Map<String, dynamic>> items,
    bool silent = false,
  }) async {
    try {
      isLoading.value = true;

      final newInvoice = await _repository.saveDraftInvoice(
        busConfigId: busConfigId,
        invoiceType: invoiceType,
        invoiceDate: invoiceDate,
        dueDate: dueDate,
        scenarioId: scenarioId,
        invoiceRefNo: invoiceRefNo,
        sellerId: sellerId,
        buyerId: buyerId,
        buyerRegistrationType: buyerRegistrationType,
        sellerNTNCNIC: sellerNTNCNIC,
        sellerBusinessName: sellerBusinessName,
        sellerProvince: sellerProvince,
        sellerAddress: sellerAddress,
        buyerNTNCNIC: buyerNTNCNIC,
        buyerProvince: buyerProvince,
        buyerBusinessName: buyerBusinessName,
        buyerAddress: buyerAddress,
        totalAmountExcludingTax: totalAmountExcludingTax,
        totalAmountIncludingTax: totalAmountIncludingTax,
        totalSalesTax: totalSalesTax,
        totalFurtherTax: totalFurtherTax,
        totalExtraTax: totalExtraTax,
        totalFedTax: totalFedTax,
        totalDiscount: totalDiscount,
        shippingCharges: shippingCharges,
        otherCharges: otherCharges,
        discountAmount: discountAmount,
        paymentStatus: paymentStatus,
        notes: notes,
        invoiceStatus: invoiceStatus,
        items: items,
      );

      invoices.insert(0, newInvoice);
      total.value++;

      if (!silent) {
        SnackbarHelper.showSuccess('Invoice saved as draft successfully');
      }
      return newInvoice;
    } catch (e) {
      if (!silent) {
        SnackbarHelper.showError(e.toString());
      }
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ───── Save or Post Invoice (Unified Method) ─────
  Future<InvoiceModel?> saveOrPostInvoice({
    int? invoiceId, // ✅ For edit mode
    required int busConfigId,
    required bool postNow, // ✅ false = draft, true = post to FBR
    required String invoiceType,
    required String invoiceDate,
    required String dueDate,
    required String scenarioId,
    String? invoiceRefNo,
    required int sellerId,
    required int buyerId,
    required String buyerRegistrationType,
    required String sellerNTNCNIC,
    required String sellerBusinessName,
    required String sellerProvince,
    required String sellerAddress,
    required String buyerNTNCNIC,
    required String buyerProvince,
    required String buyerBusinessName,
    required String buyerAddress,
    required double totalAmountExcludingTax,
    required double totalAmountIncludingTax,
    required double totalSalesTax,
    required double totalFurtherTax,
    required double totalExtraTax,
    required double totalFedTax,
    required double totalDiscount,
    required double shippingCharges,
    required double otherCharges,
    required double discountAmount,
    required double grandTotal,
    required double paidAmount,
    required double balanceDue,
    required String paymentMethod,
    String? bankName,
    String? chequeNo,
    String? chequeDate,
    required String paymentStatus,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      isLoading.value = true;

      final invoice = await _repository.saveOrPostInvoice(
        invoiceId: invoiceId,
        busConfigId: busConfigId,
        postNow: postNow,
        invoiceStatus: postNow ? 'posted' : 'draft',
        invoiceType: invoiceType,
        invoiceDate: invoiceDate,
        dueDate: dueDate,
        scenarioId: scenarioId,
        invoiceRefNo: invoiceRefNo,
        sellerId: sellerId,
        buyerId: buyerId,
        buyerRegistrationType: buyerRegistrationType,
        sellerNTNCNIC: sellerNTNCNIC,
        sellerBusinessName: sellerBusinessName,
        sellerProvince: sellerProvince,
        sellerAddress: sellerAddress,
        buyerNTNCNIC: buyerNTNCNIC,
        buyerProvince: buyerProvince,
        buyerBusinessName: buyerBusinessName,
        buyerAddress: buyerAddress,
        totalAmountExcludingTax: totalAmountExcludingTax,
        totalAmountIncludingTax: totalAmountIncludingTax,
        totalSalesTax: totalSalesTax,
        totalFurtherTax: totalFurtherTax,
        totalExtraTax: totalExtraTax,
        totalFedTax: totalFedTax,
        totalDiscount: totalDiscount,
        shippingCharges: shippingCharges,
        otherCharges: otherCharges,
        discountAmount: discountAmount,
        grandTotal: grandTotal,
        paidAmount: paidAmount,
        balanceDue: balanceDue,
        paymentMethod: paymentMethod,
        bankName: bankName,
        chequeNo: chequeNo,
        chequeDate: chequeDate,
        paymentStatus: paymentStatus,
        notes: notes,
        items: items,
      );

      // Update or add to list
      if (invoiceId != null) {
        // Edit mode - update existing invoice
        final index = invoices.indexWhere((inv) => inv.invoiceId == invoiceId);
        if (index != -1) {
          invoices[index] = invoice;
        }
        selectedInvoice.value = invoice;
      } else {
        // Create mode - add new invoice
        invoices.insert(0, invoice);
        total.value++;
      }

      // ✅ Don't show snackbar here - let the UI handle it
      return invoice;
    } catch (e) {
      SnackbarHelper.showError(e.toString());
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
