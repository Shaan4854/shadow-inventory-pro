import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/reports_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/analytics_card.dart';
import '../services/export_service.dart';
import '../widgets/report_filter_dialog.dart';
import '../models/report_filter.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsProvider = context.watch<ReportsProvider>();

    return Scaffold(
      backgroundColor: AppConstants.colors.background,
      appBar: AppBar(
        title: const Text('REPORTS & ANALYTICS'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.colors.primary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Sales'),
            Tab(text: 'Inventory'),
            Tab(text: 'Partners'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () async {
              final newFilter = await showDialog<ReportFilter>(
                context: context,
                builder: (context) => ReportFilterDialog(
                  initialFilter: reportsProvider.filter,
                ),
              );
              if (newFilter != null) {
                reportsProvider.updateFilter(newFilter);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _showExportMenu(context, reportsProvider),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DashboardTab(provider: reportsProvider),
          _SalesTab(provider: reportsProvider),
          _InventoryTab(provider: reportsProvider),
          _PartnersTab(provider: reportsProvider),
        ],
      ),
    );
  }

  void _showExportMenu(BuildContext context, ReportsProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded),
              title: const Text('Export Filtered Data to PDF'),
              onTap: () {
                Navigator.pop(context);
                ExportService.exportTransactionsToPdf(
                  provider.filteredTransactions,
                  'Filtered Report',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_rounded),
              title: const Text('Export to Excel'),
              onTap: () {
                Navigator.pop(context);
                ExportService.exportTransactionsToExcel(
                  provider.filteredTransactions,
                  'inventory_report',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_rounded),
              title: const Text('Export to CSV'),
              onTap: () {
                Navigator.pop(context);
                ExportService.exportTransactionsToCsv(
                  provider.filteredTransactions,
                  'inventory_report',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({required this.provider});
  final ReportsProvider provider;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppConstants.spacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AnalyticsCard(
                  label: 'Revenue',
                  value: '${AppConstants.currencySymbol}${provider.totalRevenue.toStringAsFixed(0)}',
                  icon: Icons.trending_up_rounded,
                  color: AppConstants.colors.green,
                ),
              ),
              SizedBox(width: AppConstants.spacing.md),
              Expanded(
                child: AnalyticsCard(
                  label: 'Net Profit',
                  value: '${AppConstants.currencySymbol}${provider.totalProfit.toStringAsFixed(0)}',
                  icon: Icons.auto_graph_rounded,
                  color: AppConstants.colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacing.md),
          Row(
            children: [
              Expanded(
                child: AnalyticsCard(
                  label: 'Purchases',
                  value: '${AppConstants.currencySymbol}${provider.totalPurchases.toStringAsFixed(0)}',
                  icon: Icons.shopping_bag_outlined,
                  color: AppConstants.colors.orange,
                ),
              ),
              SizedBox(width: AppConstants.spacing.md),
              Expanded(
                child: AnalyticsCard(
                  label: 'Valuation',
                  value: '${AppConstants.currencySymbol}${provider.inventoryValuation.toStringAsFixed(0)}',
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppConstants.colors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacing.xl),
          Text(
            'BEST SELLING PRODUCTS',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          SizedBox(height: AppConstants.spacing.md),
          ...provider.topSellingProducts.map(
            (e) => ListTile(
              leading: Text(e.key.emoji, style: const TextStyle(fontSize: 20)),
              title: Text(e.key.name),
              subtitle: Text('Sold: ${e.value} ${e.key.unit}'),
              trailing: Text(
                '${AppConstants.currencySymbol}${(e.value * e.key.sellPrice).toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesTab extends StatelessWidget {
  const _SalesTab({required this.provider});
  final ReportsProvider provider;

  @override
  Widget build(BuildContext context) {
    final trend = provider.dailySalesTrend;

    return Padding(
      padding: EdgeInsets.all(AppConstants.spacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('SALES TREND', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 20),
          if (trend.isNotEmpty)
            Expanded(
              flex: 2,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(),
                      isCurved: true,
                      color: AppConstants.colors.primary,
                      barWidth: 4,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppConstants.colors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const Expanded(
              flex: 2,
              child: Center(child: Text('Not enough sales data.')),
            ),
          const SizedBox(height: 20),
          Text('SALES LOG', style: Theme.of(context).textTheme.labelSmall),
          Expanded(
            flex: 3,
            child: ListView.builder(
              itemCount: provider.salesReport.length,
              itemBuilder: (context, index) {
                final tx = provider.salesReport[index];
                return ListTile(
                  title: Text(tx.entityName),
                  subtitle: Text(DateFormat('dd MMM yyyy').format(tx.createdAt)),
                  trailing: Text(
                    '${AppConstants.currencySymbol}${tx.grandTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppConstants.colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryTab extends StatelessWidget {
  const _InventoryTab({required this.provider});
  final ReportsProvider provider;

  @override
  Widget build(BuildContext context) {
    final distribution = provider.categoryDistribution;
    final lowStock = provider.lowStockReport;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppConstants.spacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'CATEGORY DISTRIBUTION (BY VALUE)',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: distribution.entries.map((e) {
                  return PieChartSectionData(
                    value: e.value,
                    title: '',
                    radius: 50,
                    color: Colors.primaries[distribution.keys.toList().indexOf(e.key) % Colors.primaries.length],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (lowStock.isNotEmpty) ...[
            Text(
              'LOW STOCK ALERTS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppConstants.colors.red,
                  ),
            ),
            const SizedBox(height: 10),
            ...lowStock.map(
              (p) => ListTile(
                leading: Text(p.emoji),
                title: Text(p.name),
                trailing: Text(
                  '${p.stock} left',
                  style: TextStyle(
                    color: AppConstants.colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'VALUATION BY CATEGORY',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          ...distribution.entries.map(
            (e) => ListTile(
              title: Text(e.key),
              trailing: Text(
                '${AppConstants.currencySymbol}${e.value.toStringAsFixed(0)}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnersTab extends StatelessWidget {
  const _PartnersTab({required this.provider});
  final ReportsProvider provider;

  @override
  Widget build(BuildContext context) {
    final topCustomersRevenue = provider.topCustomers;
    final topCustomersVolume = provider.topCustomersByVolume;
    final topSuppliers = provider.topSuppliers;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppConstants.spacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'TOP CUSTOMERS (BY REVENUE)',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 10),
          ...topCustomersRevenue.take(5).map(
            (e) => ListTile(
              leading: CircleAvatar(child: Text(e.key.name[0])),
              title: Text(e.key.name),
              trailing: Text(
                '${AppConstants.currencySymbol}${e.value.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'TOP CUSTOMERS (BY VOLUME)',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 10),
          ...topCustomersVolume.take(5).map(
            (e) => ListTile(
              leading: CircleAvatar(child: Text(e.key.name[0])),
              title: Text(e.key.name),
              trailing: Text(
                '${e.value} items',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'TOP SUPPLIERS (BY VOLUME)',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 10),
          ...topSuppliers.take(5).map(
            (e) => ListTile(
              leading: CircleAvatar(child: Text(e.key.name[0])),
              title: Text(e.key.name),
              trailing: Text(
                '${AppConstants.currencySymbol}${e.value.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
