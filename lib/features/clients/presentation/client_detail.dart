// ─────────────────────────────────────────────────────────────────────────────
// lib/features/clients/presentation/client_detail.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/client_model.dart';
import 'client_create.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/image_url_helper.dart';

class ClientDetail extends StatelessWidget {
  final ClientModel client;

  const ClientDetail({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Client Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: const [],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ───── Header Card ─────
          Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: FutureBuilder<String?>(
                      future: (Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : ApiClient()).getToken(),
                      builder: (context, snap) {
                        // If byrLogoUrl is present (presigned S3 URL), use it directly
                        if (client.byrLogoUrl != null && client.byrLogoUrl!.isNotEmpty) {
                          final imageUrl = client.byrLogoUrl!;
                          return CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.green.withOpacity(0.1),
                            // No auth headers or URL rewriting for external S3 URLs
                            foregroundImage: NetworkImage(imageUrl),
                            child: Text(
                              client.byrName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }

                        // Fallback: use local storage path with optional auth headers
                        final token = snap.data;
                        final headers = token != null && token.isNotEmpty
                            ? {
                                'Authorization': token.toLowerCase().startsWith('bearer ') ? token : 'Bearer $token',
                                'Accept': 'image/*',
                              }
                            : <String, String>{};

                        final rawUrl = (client.byrLogo != null && client.byrLogo!.isNotEmpty)
                            ? '${ApiEndpoints.baseUrl.replaceAll('/api', '')}/storage/${client.byrLogo}'
                            : '';
                        final imageUrl = rawUrl.isNotEmpty ? ImageUrlHelper.fixUrl(rawUrl) : null;

                        return CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.green.withOpacity(0.1),
                          foregroundImage: imageUrl != null ? NetworkImage(imageUrl, headers: headers) : null,
                          child: Text(
                            client.byrName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    client.byrName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: client.byrType == 1
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      client.typeLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: client.byrType == 1 ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ───── Information Card ─────
          Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (client.byrNtnCnic != null)
                    _buildInfoRow(
                      Icons.badge,
                      '${client.byrIdType ?? 'ID'}',
                      client.byrNtnCnic!,
                    ),
                  if (client.byrAddress != null)
                    _buildInfoRow(Icons.location_on, 'Address', client.byrAddress!),
                  if (client.byrProvince != null)
                    _buildInfoRow(Icons.map, 'Province', client.byrProvince!),
                  if (client.byrContactPerson != null)
                    _buildInfoRow(Icons.person, 'Contact Person', client.byrContactPerson!),
                  if (client.byrContactNum != null)
                    _buildInfoRow(Icons.phone, 'Contact Number', client.byrContactNum!),
                  if (client.byrAccountTitle != null)
                    _buildInfoRow(Icons.account_balance, 'Account Title', client.byrAccountTitle!),
                  if (client.byrAccountNumber != null)
                    _buildInfoRow(Icons.credit_card, 'Account Number', client.byrAccountNumber!),
                  if (client.byrIBAN != null)
                    _buildInfoRow(Icons.account_balance_wallet, 'IBAN', client.byrIBAN!),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => ClientCreate(client: client)),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('Edit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
