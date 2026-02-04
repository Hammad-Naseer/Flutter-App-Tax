// ─────────────────────────────────────────────────────────────────────────────
// lib/features/clients/presentation/clients_list.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/utils/image_url_helper.dart';
import '../controller/clients_controller.dart';
import 'client_create.dart';
import 'client_detail.dart';
import '../../navigation/nav_controller.dart';

class ClientsList extends StatelessWidget {
  const ClientsList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ClientsController>();
    final navCtrl = Get.find<NavController>();
    // Ensure Clients tab is highlighted
    navCtrl.currentIndex.value = 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Clients',
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
            onPressed: () => controller.fetchClients(refresh: true),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.clients.isEmpty) {
          return const Center(child: AppLoader());
        }

        if (controller.clients.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline,
            title: 'No Clients',
            message: 'Add your first client to get started',
            actionLabel: 'Add Client',
            onAction: () => Get.to(() => const ClientCreate()),
          );
        }

        // Apply client-side search filter
        final visibleClients = controller.filteredClients;

        return RefreshIndicator(
          onRefresh: () => controller.fetchClients(refresh: true),
          child: Column(
            children: [
              // ───── Top Actions: Search + Add ─────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Name, CNIC, Address...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (q) {
                        controller.searchQuery.value = q;
                      },
                    ),
                    // Add button moved to floating action button only (to avoid duplicate buttons)
                  ],
                ),
              ),

              // ───── Clients List ─────
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: visibleClients.length +
                      (controller.isLoadingMore.value ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == visibleClients.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: AppLoader(),
                        ),
                      );
                    }

                    final client = visibleClients[index];
                    return _buildClientCard(context, client, controller);
                  },
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const ClientCreate()),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Client',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
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

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(
      BuildContext context, client, ClientsController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title and status
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: (client.byrLogo == null || client.byrLogo!.isEmpty)
                        ? CircleAvatar(
                            backgroundColor: Colors.green.withOpacity(0.1),
                            child: Text(
                              client.byrName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          )
                        : FutureBuilder<String?>(
                            future: (Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : ApiClient()).getToken(),
                            builder: (context, snap) {
                              if (snap.connectionState != ConnectionState.done) {
                                return CircleAvatar(
                                  backgroundColor: Colors.green.withOpacity(0.05),
                                  child: const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              }
                              // If byrLogoUrl is present (presigned S3 URL), use it directly
                              if (client.byrLogoUrl != null && client.byrLogoUrl!.isNotEmpty) {
                                final imageUrl = client.byrLogoUrl!;
                                return CircleAvatar(
                                  backgroundColor: Colors.green.withOpacity(0.1),
                                  // No auth headers or URL rewriting for external S3 URLs
                                  foregroundImage: NetworkImage(imageUrl),
                                  child: Text(
                                    client.byrName[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                );
                              }

                              // Fallback: use local storage path WITHOUT auth headers (public file)
                              final rawUrl = '${ApiEndpoints.baseUrl.replaceAll('/api', '')}/storage/${client.byrLogo}';

                              // Fix URL for Android emulator (127.0.0.1 → 10.0.2.2)
                              final imageUrl = ImageUrlHelper.fixUrl(rawUrl);

                              return CircleAvatar(
                                backgroundColor: Colors.green.withOpacity(0.1),
                                backgroundImage: NetworkImage(imageUrl),
                                // If image fails to load (e.g. 403), just keep the initial avatar
                                onBackgroundImageError: (_, __) {},
                                child: Text(
                                  client.byrName[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.byrName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: client.byrType == 1 ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          client.typeLabel,
                          style: TextStyle(fontSize: 11, color: client.byrType == 1 ? Colors.green : Colors.orange, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text('Status', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    SizedBox(height: 2),
                    Text('OK', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Details panel
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _infoText('${client.byrIdType ?? 'ID'}', client.byrNtnCnic),
                      ),
                      Expanded(
                        child: _infoText('Contact Person', client.byrContactPerson),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _infoText('Mobile', client.byrContactNum),
                      ),
                      Expanded(
                        child: _infoText('Account Title', client.byrAccountTitle),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (client.byrAddress != null || client.byrIBAN != null)
                    Row(
                      children: [
                        Expanded(child: _infoText('Address', client.byrAddress)),
                        Expanded(child: _infoText('IBAN', client.byrIBAN)),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Actions: View Details + edit/delete
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Get.to(() => ClientDetail(client: client)),
                    icon: const Icon(Icons.visibility, size: 18, color: AppColors.textSecondary),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => Get.to(() => ClientCreate(client: client)),
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: () => _showDeleteDialog(context, client, controller),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoText(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
      ],
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
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    });
  }

  void _showDeleteDialog(
      BuildContext context, client, ClientsController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Client'),
        content: Text('Are you sure you want to delete ${client.byrName}?'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final ok = await controller.deleteClient(client.byrId, silent: true);
              if (ok) {
                _showBottomSheetMessage(context, success: true, message: 'Client deleted successfully');
              } else {
                _showBottomSheetMessage(context, success: false, message: 'Failed to delete client');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
