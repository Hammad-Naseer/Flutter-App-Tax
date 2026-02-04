// ─────────────────────────────────────────────────────────────────────────────
// lib/features/clients/controller/clients_controller.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:get/get.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/client_model.dart';
import '../../../data/repositories/client_repository.dart';

class ClientsController extends GetxController {
  final ClientRepository _repository;

  ClientsController(this._repository);

  // ───── Observable State ─────
  final RxList<ClientModel> clients = <ClientModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxInt currentPage = 1.obs;
  final RxInt lastPage = 1.obs;
  final RxInt total = 0.obs;

  // Search query for client-side filtering
  final RxString searchQuery = ''.obs;

  // ───── Selected Client for Edit ─────
  final Rx<ClientModel?> selectedClient = Rx<ClientModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchClients();
  }

  // ───── Filtered Clients (by name, NTN/CNIC, address, contact person) ─────
  List<ClientModel> get filteredClients {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return clients;

    return clients.where((c) {
      final name = c.byrName.toLowerCase();
      final id = (c.byrNtnCnic ?? '').toLowerCase();
      final addr = (c.byrAddress ?? '').toLowerCase();
      final contact = (c.byrContactPerson ?? '').toLowerCase();
      return name.contains(q) || id.contains(q) || addr.contains(q) || contact.contains(q);
    }).toList();
  }

  // ───── Fetch Clients ─────
  Future<void> fetchClients({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage.value = 1;
        clients.clear();
      }

      isLoading.value = true;

      final result = await _repository.fetchClients(page: currentPage.value);

      clients.value = result['clients'] as List<ClientModel>;
      currentPage.value = result['current_page'];
      lastPage.value = result['last_page'];
      total.value = result['total'];
    } catch (e) {
      SnackbarHelper.showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ───── Load More Clients ─────
  Future<void> loadMore() async {
    if (isLoadingMore.value || currentPage.value >= lastPage.value) return;

    try {
      isLoadingMore.value = true;
      currentPage.value++;

      final result = await _repository.fetchClients(page: currentPage.value);

      clients.addAll(result['clients'] as List<ClientModel>);
      lastPage.value = result['last_page'];
      total.value = result['total'];
    } catch (e) {
      SnackbarHelper.showError(e.toString());
      currentPage.value--; // Revert page increment on error
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ───── Fetch Single Client ─────
  Future<void> fetchClient(int byrId) async {
    try {
      isLoading.value = true;
      selectedClient.value = await _repository.fetchClient(byrId);
    } catch (e) {
      SnackbarHelper.showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ───── Create Client ─────
  Future<bool> createClient({
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
      isLoading.value = true;

      final newClient = await _repository.createClient(
        byrName: byrName,
        byrType: byrType,
        byrIdType: byrIdType,
        byrNtnCnic: byrNtnCnic,
        byrAddress: byrAddress,
        byrProvince: byrProvince,
        byrAccountTitle: byrAccountTitle,
        byrAccountNumber: byrAccountNumber,
        byrRegNum: byrRegNum,
        byrEmail: byrEmail,
        byrContactNum: byrContactNum,
        byrContactPerson: byrContactPerson,
        byrIBAN: byrIBAN,
        byrAccBranchName: byrAccBranchName,
        byrAccBranchCode: byrAccBranchCode,
        byrSwiftCode: byrSwiftCode,
        byrLogo: byrLogo,
      );

      // Insert a temporary client first so user sees it instantly
      clients.insert(0, newClient);
      total.value++;

      // Immediately refetch the created client to get latest logo URL and other fields
      try {
        final fullClient = await _repository.fetchClient(newClient.byrId);
        final index = clients.indexWhere((c) => c.byrId == newClient.byrId);
        if (index != -1) {
          clients[index] = fullClient;
        }
      } catch (e) {
        // Silent failure: fallback to the original created client if refetch fails
      }

      // Force UI refresh by triggering observable update
      clients.refresh();
      return true;
    } catch (e) {
      String msg = e.toString();
      // Handle the specific "email already exists" message from backend (including potential typos)
      if (msg.toLowerCase().contains('email') && 
          (msg.toLowerCase().contains('already') || 
           msg.toLowerCase().contains('arealdy') || 
           msg.toLowerCase().contains('exist') || 
           msg.toLowerCase().contains('taken'))) {
        msg = 'This email is already registered. Please use a different email address.';
      }
      SnackbarHelper.showError(msg);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ───── Update Client ─────
  Future<bool> updateClient({
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
      isLoading.value = true;

      final updatedClient = await _repository.updateClient(
        byrId: byrId,
        byrName: byrName,
        byrType: byrType,
        byrIdType: byrIdType,
        byrNtnCnic: byrNtnCnic,
        byrAddress: byrAddress,
        byrProvince: byrProvince,
        byrAccountTitle: byrAccountTitle,
        byrAccountNumber: byrAccountNumber,
        byrRegNum: byrRegNum,
        byrEmail: byrEmail,
        byrContactNum: byrContactNum,
        byrContactPerson: byrContactPerson,
        byrIBAN: byrIBAN,
        byrAccBranchName: byrAccBranchName,
        byrAccBranchCode: byrAccBranchCode,
        byrSwiftCode: byrSwiftCode,
        byrLogo: byrLogo,
      );

      final index = clients.indexWhere((c) => c.byrId == byrId);
      if (index != -1) {
        clients[index] = updatedClient;
        // Force UI refresh by triggering observable update
        clients.refresh();
      }

      selectedClient.value = updatedClient;
      return true;
    } catch (e) {
      String msg = e.toString();
      // Handle the specific "email already exists" message from backend (including potential typos)
      if (msg.toLowerCase().contains('email') && 
          (msg.toLowerCase().contains('already') || 
           msg.toLowerCase().contains('arealdy') || 
           msg.toLowerCase().contains('exist') || 
           msg.toLowerCase().contains('taken'))) {
        msg = 'This email is already registered. Please use a different email address.';
      }
      SnackbarHelper.showError(msg);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ───── Delete Client ─────
  Future<bool> deleteClient(int byrId, {bool silent = false}) async {
    try {
      isLoading.value = true;

      await _repository.deleteClient(byrId);

      clients.removeWhere((c) => c.byrId == byrId);
      total.value--;
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

  // ───── Clear Selected Client ─────
  void clearSelectedClient() {
    selectedClient.value = null;
  }
}
