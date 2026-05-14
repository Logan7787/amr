import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/repository.dart';
import '../core/localization_service.dart';
import '../core/export_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DataRepository _repository = DataRepository();
  double _dailySales = 0.0;
  double _monthlySales = 0.0;
  List<Map<String, dynamic>> _weeklySales = [];
  List<Map<String, dynamic>> _topItems = [];
  double _expenseTotal = 0.0;
  double _purchaseTotal = 0.0;
  List<Map<String, dynamic>> _collectionData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final daily = await _repository.getDailySales(now);
    final monthly = await _repository.getMonthlySales(now);

    final weekly = await _repository.getSalesLast7Days();
    final topItems = await _repository.getTopSellingItems();

    // Financials for the current month
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final expenses = await _repository.getTotalExpenses(
      startOfMonth,
      endOfMonth,
    );
    final purchases = await _repository.getTotalPurchases(
      startOfMonth,
      endOfMonth,
    );
    final collection = await _repository.getCollectionData();

    if (mounted) {
      setState(() {
        _dailySales = daily;
        _monthlySales = monthly;
        _weeklySales = weekly;
        _topItems = topItems;
        _expenseTotal = expenses;
        _purchaseTotal = purchases;
        _collectionData = collection;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('reports'))),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReportCard(
                    title: loc.translate('today_sales'),
                    amount: _dailySales,
                    color: Colors.blue,
                    icon: Icons.today,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final txns = await _repository.getTransactions();
                            if (context.mounted) {
                              ExportService.exportSalesToExcel(txns, loc);
                            }
                          },
                          icon: const Icon(Icons.file_download),
                          label: Text(loc.translate('export_excel')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final items = await _repository.getItems();
                            if (context.mounted) {
                              ExportService.exportInventoryToExcel(items, loc);
                            }
                          },
                          icon: const Icon(Icons.inventory),
                          label: const Text('Inventory'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ReportCard(
                    title: loc.translate('this_month'),
                    amount: _monthlySales,
                    color: Colors.green,
                    icon: Icons.calendar_month,
                  ),
                  SizedBox(height: 32),
                  Text(
                    loc.translate('sales_trends'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 200,
                    padding: EdgeInsets.only(right: 16, top: 16),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxY(),
                        barGroups: _getBarGroups(),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: _getBottomTitles,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: false),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  Text(
                    loc.translate('top_selling_items'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  if (_topItems.isEmpty)
                    Center(child: Text('No sales data yet'))
                  else
                    AspectRatio(
                      aspectRatio: 1.5,
                      child: PieChart(
                        PieChartData(
                          sections: _getPieSections(),
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                  SizedBox(height: 32),
                  const Divider(),
                  SizedBox(height: 16),
                  Text(
                    loc.translate('profit_loss'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _ReportCard(
                    title: loc.translate('profit_loss'),
                    amount: _monthlySales - (_expenseTotal + _purchaseTotal),
                    color:
                        (_monthlySales - (_expenseTotal + _purchaseTotal)) >= 0
                        ? Colors.green
                        : Colors.red,
                    icon: Icons.account_balance_wallet,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${loc.translate('invoice')}: ₹ ${_monthlySales.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.green),
                        ),
                        Text(
                          '${loc.translate('expenses')}: ₹ ${_expenseTotal.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        Text(
                          '${loc.translate('purchases')}: ₹ ${_purchaseTotal.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  const Divider(),
                  SizedBox(height: 16),
                  Text(
                    loc.translate('collection_report'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  if (_collectionData.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No pending payments'),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _collectionData.length,
                      itemBuilder: (context, index) {
                        final data = _collectionData[index];
                        return ListTile(
                          title: Text(data['name']),
                          subtitle: Text(data['mobile'] ?? ''),
                          trailing: Text(
                            '₹ ${data['pending_balance'].toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        );
                      },
                    ),
                  SizedBox(height: 64),
                ],
              ),
            ),
    );
  }

  double _getMaxY() {
    double max = 0;
    for (var d in _weeklySales) {
      if (d['total'] > max) max = d['total'];
    }
    return max == 0 ? 100 : max * 1.2;
  }

  List<BarChartGroupData> _getBarGroups() {
    return List.generate(_weeklySales.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: _weeklySales[i]['total'],
            color: Colors.blueAccent,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    if (value.toInt() < 0 || value.toInt() >= _weeklySales.length) {
      return Container();
    }
    final dateStr = _weeklySales[value.toInt()]['date'] as String;
    final day = dateStr.split('-').last;
    return SideTitleWidget(
      meta: meta,
      child: Text(day, style: TextStyle(fontSize: 10)),
    );
  }

  List<PieChartSectionData> _getPieSections() {
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    return List.generate(_topItems.length, (i) {
      return PieChartSectionData(
        color: colors[i % colors.length],
        value: _topItems[i]['total_qty'],
        title: _topItems[i]['item_name'],
        radius: 60,
        titleStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _ReportCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              radius: 30,
              child: Icon(icon, color: color, size: 30),
            ),
            SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                SizedBox(height: 8),
                Text(
                  '₹ ${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
