// ─────────────────────────────────────────────────────────────────────────────
// lib/features/dashboard/presentation/dashboard_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input_field.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/empty_state.dart';
import '../../navigation/nav_controller.dart';
import '../controller/dashboard_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DashboardController>();
    final navCtrl = Get.find<NavController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Dashboard',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ctrl.userInitials,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 2),
            Obx(() => Text(
              'Welcome back, ${ctrl.userName.value}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            )),
          ],
        ),
      ),
      body: Obx(() {
        // 1) While loading: always show full-screen loader
        if (ctrl.isLoading.value) {
          return const Center(child: AppLoader());
        }

        // 2) If not loading and there is an error, show error UI with retry
        if (ctrl.error.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(ctrl.error.value, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: ctrl.fetchDashboard,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // 3) Otherwise show dashboard content
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ───── Environment Chip ─────
            Obx(() {
              final isProd = ctrl.fbrEnv.value == 'Production';
              final bgColor = isProd ? const Color(0xFFE8F5E9) : const Color(0xFFFFF9C4);
              final textColor = isProd ? const Color(0xFF1B5E20) : const Color(0xFF9E7800);
              final iconColor = isProd ? const Color(0xFF1B5E20) : const Color(0xFF9E7800);
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: textColor.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isProd ? Icons.rocket_launch : Icons.code, color: iconColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${ctrl.fbrEnv.value} Environment',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // ───── Stat Cards Grid ─────
            _buildStatCards(ctrl),
            const SizedBox(height: 24),

            // ───── Top 5 Clients Pie Chart ─────
            _buildPieChart(
              title: 'Top Five Clients - Revenue Basis',
              sections: List.generate(ctrl.topClientPercentages.length, (i) {
                final colors = [AppColors.primary, Colors.green, Colors.orange, Colors.purple, Colors.blueGrey];
                final percent = ctrl.topClientPercentages[i];
                return PieChartSectionData(
                  color: colors[i % colors.length],
                  value: percent,
                  title: '${percent.toStringAsFixed(1)}%',
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }),
              legend: List.generate(ctrl.topClientNames.length, (i) {
                final colors = [AppColors.primary, Colors.green, Colors.orange, Colors.purple, Colors.blueGrey];
                final percent = i < ctrl.topClientPercentages.length ? ctrl.topClientPercentages[i] : 0.0;
                return _legendItem(colors[i % colors.length], ctrl.topClientNames[i], '${percent.toStringAsFixed(1)}%');
              }),
              centerSpaceRadius: 0.0, // will be scaled inside builder when > 0
            ),
            const SizedBox(height: 24),

            // ───── Top 5 Services Pie Chart ─────
            _buildPieChart(
              title: 'Top Five Services - Revenue Basis',
              sections: List.generate(ctrl.topServicePercentagesRevenue.length, (i) {
                final colors = [AppColors.primary, Colors.green, Colors.orange, Colors.purple, Colors.blueGrey];
                final percent = ctrl.topServicePercentagesRevenue[i];
                return PieChartSectionData(
                  color: colors[i % colors.length],
                  value: percent,
                  title: '${percent.toStringAsFixed(1)}%',
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }),
              legend: List.generate(ctrl.topServiceNamesRevenue.length, (i) {
                final colors = [AppColors.primary, Colors.green, Colors.orange, Colors.purple, Colors.blueGrey];
                final percent = i < ctrl.topServicePercentagesRevenue.length ? ctrl.topServicePercentagesRevenue[i] : 0.0;
                return _legendItem(colors[i % colors.length], ctrl.topServiceNamesRevenue[i], '${percent.toStringAsFixed(1)}%');
              }),
              centerSpaceRadius: 0.0,
            ),
            const SizedBox(height: 24),

            // ───── Month-wise Tax Details ─────
            _buildLineChart(ctrl),
            const SizedBox(height: 24),

            // ───── Month-wise Invoice Details ─────
            _buildBarChart(ctrl),
            const SizedBox(height: 24),

            // ───── Quick Actions ─────
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _quickActionCard(Icons.receipt, 'New Invoice', Colors.green),
                const SizedBox(width: 12),
                _quickActionCard(Icons.person_add, 'Add Client', Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _quickActionCard(Icons.inventory, 'Add Item', Colors.purple),
                const SizedBox(width: 12),
                _quickActionCard(Icons.analytics, 'View Reports', Colors.orange),
              ],
            ),
            const SizedBox(height: 80), // Bottom nav space
          ],
        );
      }),
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

  // ───── Reusable Stat Cards ─────
  Widget _buildStatCards(DashboardController ctrl) {
    return Column(
      children: [
        Row(
          children: [
            _statCard('Total Clients', ctrl.totalClients.value.toString(), '+${ctrl.totalClients.value}%'.toString(), Icons.people, Colors.green),
            const SizedBox(width: 12),
            _statCard('Total Invoices', ctrl.totalInvoices.value.toString(), '+${ctrl.totalInvoices.value}%'.toString(), Icons.receipt, Colors.orange),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _statCard('Total FBR Posted', ctrl.fbrPostedInvoices.value.toString(), '${ctrl.fbrPostedPercentage.value.toStringAsFixed(0)}%', Icons.check_circle, Colors.green),
            const SizedBox(width: 12),
            _statCard('Total Draft', ctrl.draftInvoices.value.toString(), '${ctrl.draftPercentage.value.toStringAsFixed(0)}%', Icons.edit, Colors.red),
          ],
        ),
      ],
    );
  }
  Widget _statCard(String title, String value, String change, IconData icon, Color color) {
    final bool isPositive = change.contains('+');
    final bool isZero = change == '0%';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Icon + Change Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isZero
                        ? Colors.grey.withOpacity(0.1)
                        : (isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    change,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isZero ? Colors.grey : (isPositive ? Colors.green : Colors.red),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Number + Title (Horizontal)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // ───── Pie Chart with Legend ─────
  Widget _buildPieChart({
    required String title,
    required List<PieChartSectionData> sections,
    required List<Widget> legend,
    double centerSpaceRadius = 0,
  }) {
    return Container(
      padding: const EdgeInsets.all(20), // Increased padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // Centered Pie Chart (Responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final double maxW = constraints.maxWidth;
              final double size = maxW * 0.68 < 180
                  ? 180
                  : (maxW * 0.68 > 280 ? 280 : maxW * 0.68);
              final double sectionRadius = (size / 2) - 12;
              final mapped = sections
                  .map((s) => s.copyWith(
                        radius: sectionRadius,
                      ))
                  .toList();
              final double cs = centerSpaceRadius > 0 ? size * 0.24 : 0.0;
              return Center(
                child: SizedBox(
                  width: size,
                  height: size,
                  child: PieChart(
                    PieChartData(
                      sections: mapped,
                      centerSpaceRadius: cs, // 0 => solid pie, >0 => donut
                      sectionsSpace: 4,
                      pieTouchData: PieTouchData(enabled: false),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 28), // More space before legend


          ...legend,
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, String percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Text(
            percent,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  // ───── Line Chart (Tax Details) ─────
  // ───── Month-wise Tax Details (FIXED + LEGEND) ─────
  Widget _buildLineChart(DashboardController ctrl) {
    // Build spots from API arrays
    final len = ctrl.salesTaxData.isNotEmpty ? ctrl.salesTaxData.length : 12;
    final List<FlSpot> salesTax = List.generate(len, (i) => FlSpot(i.toDouble(), (i < ctrl.salesTaxData.length ? ctrl.salesTaxData[i] : 0).toDouble()));
    final List<FlSpot> furtherTax = List.generate(len, (i) => FlSpot(i.toDouble(), (i < ctrl.furtherTaxData.length ? ctrl.furtherTaxData[i] : 0).toDouble()));
    final List<FlSpot> extraTax = List.generate(len, (i) => FlSpot(i.toDouble(), (i < ctrl.extraTaxData.length ? ctrl.extraTaxData[i] : 0).toDouble()));
    final double maxYValue = [
      ...salesTax.map((e) => e.y),
      ...furtherTax.map((e) => e.y),
      ...extraTax.map((e) => e.y),
    ].fold<double>(0, (p, c) => c > p ? c : p);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Month-wise Tax Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // ---------- LINE CHART ----------
          SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                // ---- Grid & Border ----
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: true),

                // ---- Axis limits ----
                minX: 0,
                maxX: (len - 1).toDouble(),
                minY: 0,
                maxY: maxYValue == 0 ? 10 : maxYValue * 1.1,

                // ---- Titles (Months + K/L) ----
                titlesData: FlTitlesData(
                  // ----- Bottom – Tilted months -----
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 55,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final labels = ctrl.monthlyLabels.isNotEmpty ? ctrl.monthlyLabels : const [
                          'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
                        ];
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox();
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Transform.rotate(
                            angle: -0.8, // ~45°
                            child: Text(
                              labels[i],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ----- Left – K / L formatting -----
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      interval: 50000,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('0', style: TextStyle(fontSize: 12));
                        if (value >= 100000) {
                          return Text(
                            '${(value / 100000).toStringAsFixed(0)}L',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          );
                        }
                        if (value >= 1000) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}K',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          );
                        }
                        return Text(value.toInt().toString(),
                            style: const TextStyle(fontSize: 12));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),

                // ---- Touch (optional) ----
                lineTouchData: LineTouchData(enabled: false),

                // ---- The three tax lines ----
                lineBarsData: [
                  // Sales Tax (Blue)
                  LineChartBarData(
                    spots: salesTax,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                  // Further Tax (Green) – only visible in Sep
                  LineChartBarData(
                    spots: furtherTax,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                  // Extra Tax (Orange) – only visible in Sep
                  LineChartBarData(
                    spots: extraTax,
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ---------- LEGEND ----------
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              _legendChip(Colors.orange, 'Extra Tax'),
              _legendChip(Colors.green, 'Further Tax'),
              _legendChip(AppColors.primary, 'Sales Tax'),
            ],
          ),
        ],
      ),
    );
  }

// ───── Re-usable legend chip (same as bar-chart) ─────
  Widget _legendChip(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ───── Bar Chart (Invoice Details) ─────
  Widget _buildBarChart(DashboardController ctrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Month-wise Invoice Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              _legendChip(AppColors.primary, 'Total Invoices Created'),
              _legendChip(Colors.green, 'FBR Posted Invoices'),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 380;
              final labels = ctrl.monthlyLabels.isNotEmpty ? ctrl.monthlyLabels : const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
              final created = ctrl.invoicesCreatedCounts.isNotEmpty ? ctrl.invoicesCreatedCounts : List<int>.filled(labels.length, 0);
              final posted  = ctrl.invoicesPostedCounts.isNotEmpty  ? ctrl.invoicesPostedCounts  : List<int>.filled(labels.length, 0);
              final maxVal = [
                ...created,
                ...posted,
              ].fold<int>(0, (p, c) => c > p ? c : p);
              final maxY = (maxVal == 0 ? 10.0 : maxVal.toDouble() + 2);
              return SizedBox(
                height: isSmall ? 280 : 260,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceBetween,
                    groupsSpace: 10,
                    barGroups: List.generate(labels.length, (i) => BarChartGroupData(
                      x: i,
                      barsSpace: 6,
                      barRods: [
                        BarChartRodData(
                          toY: i < created.length ? created[i].toDouble() : 0,
                          color: AppColors.primary,
                          width: isSmall ? 10 : 12,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: i < posted.length ? posted[i].toDouble() : 0,
                          color: Colors.green,
                          width: isSmall ? 10 : 12,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    )),
                    titlesData: FlTitlesData(
                      // BOTTOM: Tilted Months
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            final months = labels;
                            int i = value.toInt();
                            if (i < 0 || i >= months.length) return const Text('');
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Transform.rotate(
                                angle: -0.8,
                                child: Text(
                                  months[i],
                                  style: TextStyle(fontSize: isSmall ? 9 : 10, fontWeight: FontWeight.w600),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // LEFT: Clear Numbers
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: (maxY / 7).clamp(1, 10),
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    maxY: maxY,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ───── Quick Action Card ─────
  Widget _quickActionCard(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}