// ─────────────────────────────────────────────────────────────────────────────
// lib/features/items/controller/items_controller.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:get/get.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/service_item_model.dart';
import '../../../data/repositories/item_repository.dart';

class ItemsController extends GetxController {
  final ItemRepository _repository;

  ItemsController(this._repository);

  // ───── Observable State ─────
  final RxList<ServiceItemModel> items = <ServiceItemModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxInt currentPage = 1.obs;
  final RxInt lastPage = 1.obs;
  final RxInt total = 0.obs;

  // Search query for item-side filtering
  final RxString searchQuery = ''.obs;

  // ───── Selected Item for Edit ─────
  final Rx<ServiceItemModel?> selectedItem = Rx<ServiceItemModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchItems();
  }

  // ───── Filtered Items (by description, HS code, UOM) ─────
  List<ServiceItemModel> get filteredItems {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return items;

    return items.where((i) {
      final desc = i.itemDescription.toLowerCase();
      final hs   = (i.itemHsCode ?? '').toLowerCase();
      final uom  = (i.itemUom ?? '').toLowerCase();
      return desc.contains(q) || hs.contains(q) || uom.contains(q);
    }).toList();
  }

  // ───── Fetch Items ─────
  Future<void> fetchItems({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage.value = 1;
        items.clear();
      }

      isLoading.value = true;

      final result = await _repository.fetchItems(page: currentPage.value);

      items.value = result['items'] as List<ServiceItemModel>;
      currentPage.value = result['current_page'];
      lastPage.value = result['last_page'];
      total.value = result['total'];
    } catch (e) {
      SnackbarHelper.showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ───── Load More Items ─────
  Future<void> loadMore() async {
    if (isLoadingMore.value || currentPage.value >= lastPage.value) return;

    try {
      isLoadingMore.value = true;
      currentPage.value++;

      final result = await _repository.fetchItems(page: currentPage.value);

      items.addAll(result['items'] as List<ServiceItemModel>);
      lastPage.value = result['last_page'];
      total.value = result['total'];
    } catch (e) {
      SnackbarHelper.showError(e.toString());
      currentPage.value--; // Revert page increment on error
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ───── Fetch Single Item ─────
  Future<void> fetchItem(int itemId) async {
    try {
      isLoading.value = true;
      selectedItem.value = await _repository.fetchItem(itemId);
    } catch (e) {
      SnackbarHelper.showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ───── Create Item ─────
  Future<bool> createItem({
    required String itemDescription,
    String? itemHsCode,
    required double itemPrice,
    String? itemTaxRate,
    String? itemUom,
    bool silent = false,
  }) async {
    try {
      isLoading.value = true;

      final result = await _repository.createItem(
        itemDescription: itemDescription,
        itemHsCode: itemHsCode,
        itemPrice: itemPrice,
        itemTaxRate: itemTaxRate,
        itemUom: itemUom,
      );

      final newItem = result['item'] as ServiceItemModel;
      final message = result['message'] as String;

      items.insert(0, newItem);
      total.value++;

      if (!silent) {
        SnackbarHelper.showSuccess(message);
      }
      return true;
    } catch (e) {
      SnackbarHelper.showError(e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ───── Update Item ─────
  Future<bool> updateItem({
    required int itemId,
    required String itemDescription,
    String? itemHsCode,
    required double itemPrice,
    String? itemTaxRate,
    String? itemUom,
    bool silent = false,
  }) async {
    try {
      isLoading.value = true;

      final result = await _repository.updateItem(
        itemId: itemId,
        itemDescription: itemDescription,
        itemHsCode: itemHsCode,
        itemPrice: itemPrice,
        itemTaxRate: itemTaxRate,
        itemUom: itemUom,
      );

      final updatedItem = result['item'] as ServiceItemModel;
      final message = result['message'] as String;

      final index = items.indexWhere((i) => i.itemId == itemId);
      if (index != -1) {
        items[index] = updatedItem;
      }

      selectedItem.value = updatedItem;

      if (!silent) {
        SnackbarHelper.showSuccess(message);
      }
      return true;
    } catch (e) {
      SnackbarHelper.showError(e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ───── Delete Item ─────
  Future<bool> deleteItem(int itemId, {bool silent = false}) async {
    try {
      isLoading.value = true;

      final message = await _repository.deleteItem(itemId);

      items.removeWhere((i) => i.itemId == itemId);
      total.value--;

      if (!silent) {
        SnackbarHelper.showSuccess(message);
      }
      return true;
    } catch (e) {
      SnackbarHelper.showError(e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ───── Clear Selected Item ─────
  void clearSelectedItem() {
    selectedItem.value = null;
  }
}

