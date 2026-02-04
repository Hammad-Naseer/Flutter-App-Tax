// lib/features/more/presentation/more_menu.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../navigation/nav_controller.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/more_controller.dart';
import '../../../core/services/update_service.dart';

class MoreMenu extends StatelessWidget {
  const MoreMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navCtrl = Get.find<NavController>();
    final more = Get.put(MoreController());
    // Ensure the More tab is highlighted
    navCtrl.currentIndex.value = 3;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'More',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sandbox/Production Chip (dynamic)
          Obx(() => _buildSandboxChip(more.env.value)),
          const SizedBox(height: 24),

          // User Profile Card
          Obx(() => _buildUserCard(
                name: more.userName.value,
                email: more.userEmail.value,
                role: more.userRole.value,
              )),
          const SizedBox(height: 24),

          // Company Details Card
          Obx(() => _buildCompanyCard(
                company: more.companyName.value,
                ntn: more.ntn.value,
                province: more.province.value,
              )),
          const SizedBox(height: 24),

          // Section Title
          const Text(
            'Settings & Tools',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Menu Items
          _menuTile(
            icon: Icons.inventory_2_outlined,
            color: Colors.purple,
            title: 'Items / Services',
            subtitle: 'Manage your products and services',
            onTap: () => Get.toNamed(AppRoutes.itemsServices),
          ),
          _menuTile(
            icon: Icons.settings_outlined,
            color: Colors.blue,
            title: 'Configuration',
            subtitle: 'Company and system settings',
            onTap: () => Get.toNamed(AppRoutes.configuration),
          ),
          _menuTile(
            icon: Icons.show_chart,
            color: Colors.green,
            title: 'Activity Logs',
            subtitle: 'View system activity history',
            onTap: () => Get.toNamed(AppRoutes.activityLogs),
          ),
          _menuTile(
            icon: Icons.payments_outlined,
            color: Colors.teal,
            title: 'Receipt Vouchers',
            subtitle: 'View and filter receipts',
            onTap: () => Get.toNamed(AppRoutes.paymentsReceiptVouchers),
          ),
          _menuTile(
            icon: Icons.account_balance_wallet_outlined,
            color: Colors.amber.shade700,
            title: 'Client Ledger',
            subtitle: 'View client payment history',
            onTap: () => Get.toNamed(AppRoutes.paymentsClientLedger),
          ),
          _menuTile(
            icon: Icons.receipt_long_outlined,
            color: Colors.blue.shade700,
            title: 'Invoice Ledger',
            subtitle: 'Transaction history per invoice',
            onTap: () => Get.toNamed(AppRoutes.paymentsInvoiceLedger),
          ),
          _menuTile(
            icon: Icons.security,
            color: Colors.indigo,
            title: 'Audit Logs',
            subtitle: 'Security and audit trail',
            onTap: () => Get.toNamed(AppRoutes.auditLogs),
          ),
          _menuTile(
            icon: Icons.error_outline,
            color: Colors.red,
            title: 'FBR Post Errors',
            subtitle: 'View FBR posting errors',
            onTap: () => Get.toNamed(AppRoutes.fbrPostErrors),
          ),
          _menuTile(
            icon: Icons.system_update_outlined,
            color: Colors.blueAccent,
            title: 'Check for Updates',
            subtitle: 'Ensure you have the latest features',
            onTap: () => Get.find<UpdateService>().checkForUpdate(showNoUpdateMessage: true),
          ),

          const SizedBox(height: 32),

          // Logout Button
          ElevatedButton.icon(
            onPressed: () async {
              // Get or create AuthController
              final authCtrl = Get.isRegistered<AuthController>()
                  ? Get.find<AuthController>()
                  : Get.put(AuthController());

              // Call proper logout method
              await authCtrl.logout();
            },
            icon: const Icon(Icons.logout, color: Colors.red, size: 20),
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.08),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.red.withOpacity(0.3)),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Footer
          Center(
            child: Obx(() => Text(
              'TaxBridge Mobile v${Get.find<UpdateService>().currentVersion.value}\n© 2025 Taxbridge.pk - All rights reserved',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            )),
          ),

          const SizedBox(height: 100), // Bottom nav space
        ],
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

  // Sandbox/Production Chip
  Widget _buildSandboxChip(String env) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.code, color: Color(0xFF9E7800), size: 16),
          const SizedBox(width: 6),
          Text(
            '$env Environment',
            style: const TextStyle(
              color: Color(0xFF9E7800),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // User Card
  Widget _buildUserCard({required String name, required String email, required String role}) {
    String initialsFrom(String n) {
      final parts = n.trim().split(RegExp(r'\s+'));
      if (parts.isEmpty || parts.first.isEmpty) return 'U';
      final first = parts.first[0];
      final second = parts.length > 1 ? parts[1][0] : '';
      return (first + second).toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.green,
            child: Text(
              initialsFrom(name),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isNotEmpty ? name : '—', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(email.isNotEmpty ? email : '—', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(role.isNotEmpty ? role : 'User', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Company Card
  Widget _buildCompanyCard({required String company, required String ntn, required String province}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Company Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _infoRow('Company:', company.isNotEmpty ? company : '—'),
          _infoRow('NTN:', ntn.isNotEmpty ? ntn : '—'),
          _infoRow('Province:', province.isNotEmpty ? province : '—'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable Menu Tile
  Widget _menuTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
    );
  }
}