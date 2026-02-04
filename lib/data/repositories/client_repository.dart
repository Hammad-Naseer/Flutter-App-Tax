// ─────────────────────────────────────────────────────────────────────────────
// lib/data/repositories/client_repository.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/client_model.dart';

class ClientRepository {
  final ApiClient _apiClient;

  ClientRepository(this._apiClient);

  // ───── Fetch All Clients (Paginated) ─────
  Future<Map<String, dynamic>> fetchClients({int page = 1}) async {
    try {
      // Include tenant/bus_config filtering if available
      final prefs = await SharedPreferences.getInstance();
      final busConfigId = prefs.getString('bus_config_id') ?? prefs.getString('tenant_id');
      final qp = <String, String>{'page': page.toString()};
      if (busConfigId != null && busConfigId.isNotEmpty) {
        qp['bus_config_id'] = busConfigId;
      }

      final response = await _apiClient.get(
        ApiEndpoints.buyersList,
        queryParams: qp,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final root = response['data'];
        List<dynamic> listNode = const [];
        int currentPage = 1, lastPage = 1, perPage = 0, total = 0;

        if (root is Map<String, dynamic>) {
          // Common Laravel pagination shape
          final map = root;
          final maybeList = map['data'] ?? map['buyers'] ?? map['list'];
          if (maybeList is List) listNode = maybeList;

          int _toInt(dynamic v) {
            if (v is int) return v;
            if (v is String) return int.tryParse(v) ?? 0;
            return 0;
          }

          currentPage = _toInt(map['current_page']);
          lastPage = _toInt(map['last_page']);
          perPage = _toInt(map['per_page']);
          total = _toInt(map['total']);
        } else if (root is List) {
          // Non-paginated list
          listNode = root;
          total = root.length;
          currentPage = 1;
          lastPage = 1;
        }

        final clientsList = listNode
            .map((json) => ClientModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return {
          'clients': clientsList,
          'current_page': currentPage,
          'last_page': lastPage,
          'per_page': perPage,
          'total': total,
        };
      }
      throw Exception(response['message'] ?? 'Failed to fetch clients');
    } catch (e) {
      rethrow;
    }
  }

  // ───── Fetch Single Client ─────
  Future<ClientModel> fetchClient(int byrId) async {
    try {
      final response = await _apiClient.postFormData(
        ApiEndpoints.buyersFetch,
        fields: {'byr_id': byrId.toString()},
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return ClientModel.fromJson(response['data']);
      }
      throw Exception(response['message'] ?? 'Failed to fetch client');
    } catch (e) {
      rethrow;
    }
  }

  // ───── Create Client ─────
  Future<ClientModel> createClient({
    required String byrName,
    required int byrType,
    String? byrIdType,
    String? byrNtnCnic,
    String? byrAddress,
    String? byrProvince,
    String? byrAccountTitle,
    String? byrAccountNumber,
    String? byrRegNum,
    String? byrEmail,
    String? byrContactNum,
    String? byrContactPerson,
    String? byrIBAN,
    String? byrAccBranchName,
    String? byrAccBranchCode,
    String? byrSwiftCode,
    File? byrLogo,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final busConfigId = prefs.getString('bus_config_id') ?? prefs.getString('tenant_id') ?? '1';

      final fields = <String, dynamic>{
        'byr_name': byrName,
        'byr_type': byrType.toString(),
        'bus_config_id': busConfigId,
        if (byrIdType != null) 'byr_id_type': byrIdType,
        if (byrNtnCnic != null) 'byr_ntn_cnic': byrNtnCnic,
        if (byrEmail != null) 'byr_email': byrEmail,
        if (byrAddress != null) 'byr_address': byrAddress,
        if (byrProvince != null) 'byr_province': byrProvince,
        if (byrAccountTitle != null) 'byr_account_title': byrAccountTitle,
        if (byrAccountNumber != null) 'byr_account_number': byrAccountNumber,
        if (byrRegNum != null) 'byr_reg_num': byrRegNum,
        if (byrContactNum != null) 'byr_contact_num': byrContactNum,
        if (byrContactPerson != null) 'byr_contact_person': byrContactPerson,
        if (byrIBAN != null) 'byr_IBAN': byrIBAN,
        if (byrAccBranchName != null) 'byr_acc_branch_name': byrAccBranchName,
        if (byrAccBranchCode != null) 'byr_acc_branch_code': byrAccBranchCode,
        if (byrSwiftCode != null) 'byr_swift_code': byrSwiftCode,
      };

      final files = <String, File>{};
      if (byrLogo != null) {
        files['byr_logo'] = byrLogo;
      }

      print('📤 Repository: Creating client with fields: $fields');

      final response = await _apiClient.postFormData(
        ApiEndpoints.buyersStore,
        fields: fields,
        files: files.isNotEmpty ? files : null,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return ClientModel.fromJson(response['data']);
      }
      throw Exception(response['message'] ?? 'Failed to create client');
    } catch (e) {
      rethrow;
    }
  }

  // ───── Update Client ─────
  Future<ClientModel> updateClient({
    required int byrId,
    required String byrName,
    required int byrType,
    String? byrIdType,
    String? byrNtnCnic,
    String? byrAddress,
    String? byrProvince,
    String? byrAccountTitle,
    String? byrAccountNumber,
    String? byrRegNum,
    String? byrEmail,
    String? byrContactNum,
    String? byrContactPerson,
    String? byrIBAN,
    String? byrAccBranchName,
    String? byrAccBranchCode,
    String? byrSwiftCode,
    File? byrLogo,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final busConfigId = prefs.getString('bus_config_id') ?? prefs.getString('tenant_id') ?? '1';

      final fields = <String, dynamic>{
        'byr_id': byrId.toString(),
        'byr_name': byrName,
        'byr_type': byrType.toString(),
        'bus_config_id': busConfigId,
        if (byrIdType != null) 'byr_id_type': byrIdType,
        if (byrNtnCnic != null) 'byr_ntn_cnic': byrNtnCnic,
        if (byrEmail != null) 'byr_email': byrEmail,
        if (byrAddress != null) 'byr_address': byrAddress,
        if (byrProvince != null) 'byr_province': byrProvince,
        if (byrAccountTitle != null) 'byr_account_title': byrAccountTitle,
        if (byrAccountNumber != null) 'byr_account_number': byrAccountNumber,
        if (byrRegNum != null) 'byr_reg_num': byrRegNum,
        if (byrContactNum != null) 'byr_contact_num': byrContactNum,
        if (byrContactPerson != null) 'byr_contact_person': byrContactPerson,
        if (byrIBAN != null) 'byr_IBAN': byrIBAN,
        if (byrAccBranchName != null) 'byr_acc_branch_name': byrAccBranchName,
        if (byrAccBranchCode != null) 'byr_acc_branch_code': byrAccBranchCode,
        if (byrSwiftCode != null) 'byr_swift_code': byrSwiftCode,
      };

      final files = <String, File>{};
      if (byrLogo != null) {
        files['byr_logo'] = byrLogo;
      }

      print('📤 Repository: Updating client with fields: $fields');

      final response = await _apiClient.postFormData(
        ApiEndpoints.buyersUpdate,
        fields: fields,
        files: files.isNotEmpty ? files : null,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return ClientModel.fromJson(response['data']);
      }
      throw Exception(response['message'] ?? 'Failed to update client');
    } catch (e) {
      rethrow;
    }
  }

  // ───── Delete Client ─────
  Future<bool> deleteClient(int byrId) async {
    try {
      final response = await _apiClient.postFormData(
        ApiEndpoints.buyersDelete,
        fields: {'byr_id': byrId.toString()},
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return true;
      }
      throw Exception(response['message'] ?? 'Failed to delete client');
    } catch (e) {
      rethrow;
    }
  }
}
