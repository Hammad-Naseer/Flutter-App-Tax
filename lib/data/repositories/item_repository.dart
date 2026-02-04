// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/item_repository.dart
// ─────────────────────────────────────────────────────────────────────────────

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/service_item_model.dart';

class ItemRepository {
  final ApiClient _apiClient;

  ItemRepository(this._apiClient);

  // ───── Fetch All Items (Paginated) ─────
  Future<Map<String, dynamic>> fetchItems({int page = 1}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.itemsList,
        queryParams: {'page': page.toString()},
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final itemsList = (data['data'] as List)
            .map((json) => ServiceItemModel.fromJson(json))
            .toList();

        return {
          'items': itemsList,
          'current_page': data['current_page'],
          'last_page': data['last_page'],
          'per_page': data['per_page'],
          'total': data['total'],
        };
      }
      throw Exception(response['message'] ?? 'Failed to fetch items');
    } catch (e) {
      rethrow;
    }
  }

  // ───── Fetch Single Item ─────
  Future<ServiceItemModel> fetchItem(int itemId) async {
    try {
      final response = await _apiClient.postFormData(
        ApiEndpoints.itemsFetch,
        fields: {'item_id': itemId.toString()},
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return ServiceItemModel.fromJson(response['data']);
      }
      throw Exception(response['message'] ?? 'Failed to fetch item');
    } catch (e) {
      rethrow;
    }
  }

  // ───── Create Item ─────
  Future<Map<String, dynamic>> createItem({
    required String itemDescription,
    String? itemHsCode,
    required double itemPrice,
    String? itemTaxRate,
    String? itemUom,
  }) async {
    try {
      final fields = <String, dynamic>{
        'item_description': itemDescription,
        'item_price': itemPrice.toString(),
        if (itemHsCode != null) 'item_hs_code': itemHsCode,
        if (itemTaxRate != null) 'item_tax_rate': itemTaxRate,
        if (itemUom != null) 'item_uom': itemUom,
      };

      final response = await _apiClient.postFormData(
        ApiEndpoints.itemsStore,
        fields: fields,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return {
          'item': ServiceItemModel.fromJson(response['data']),
          'message': response['message'] ?? 'Item created successfully',
        };
      }
      throw Exception(response['message'] ?? 'Failed to create item');
    } catch (e) {
      rethrow;
    }
  }

  // ───── Update Item ─────
  Future<Map<String, dynamic>> updateItem({
    required int itemId,
    required String itemDescription,
    String? itemHsCode,
    required double itemPrice,
    String? itemTaxRate,
    String? itemUom,
  }) async {
    try {
      final fields = <String, dynamic>{
        'item_id': itemId.toString(),
        'item_description': itemDescription,
        'item_price': itemPrice.toString(),
        if (itemHsCode != null) 'item_hs_code': itemHsCode,
        if (itemTaxRate != null) 'item_tax_rate': itemTaxRate,
        if (itemUom != null) 'item_uom': itemUom,
      };

      final response = await _apiClient.postFormData(
        ApiEndpoints.itemsUpdate,
        fields: fields,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return {
          'item': ServiceItemModel.fromJson(response['data']),
          'message': response['message'] ?? 'Item updated successfully',
        };
      }
      throw Exception(response['message'] ?? 'Failed to update item');
    } catch (e) {
      rethrow;
    }
  }

  // ───── Delete Item ─────
  Future<String> deleteItem(int itemId) async {
    try {
      final response = await _apiClient.postFormData(
        ApiEndpoints.itemsDelete,
        fields: {'item_id': itemId.toString()},
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return response['message'] ?? 'Item deleted successfully';
      }
      throw Exception(response['message'] ?? 'Failed to delete item');
    } catch (e) {
      rethrow;
    }
  }
}

