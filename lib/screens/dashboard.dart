import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/localization_service.dart';
import 'customer_list_screen.dart';
import 'item_master_screen.dart';
import 'transaction_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'backup_screen.dart';
import 'language_selection_screen.dart';
import 'expense_screen.dart';
import 'supplier_screen.dart';
import 'purchase_screen.dart';
import 'low_stock_screen.dart';
import 'transaction_history_screen.dart';
import '../core/supabase_service.dart';
import '../widgets/analytics_card.dart';

import '../data/repository.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final DataRepository _repository = DataRepository();
  double _todaySales = 0.0;
  List<Map<String, dynamic>> _salesData = [];
  List<Map<String, dynamic>> _expenseData = [];
  int _lowStockCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final today = DateTime.now();
    final sales = await _repository.getDailySales(today);
    final stats = await _repository.getSalesLast7Days();
    final expenses = await _repository.getExpensesLast7Days();
    final lowStockItems = await _repository.getLowStockItems();

    if (mounted) {
      setState(() {
        _todaySales = sales;
        _salesData = stats;
        _expenseData = expenses;
        _lowStockCount = lowStockItems.length;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var loc = Provider.of<LocalizationService>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          loc.translate('app_title'),
          style: GoogleFonts.notoSansTamil(
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildDrawer(context, loc),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSummaryHeader(context, loc),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.translate('dashboard'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      letterSpacing: 0.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SalesAnalyticsCard(
                    salesData: _salesData,
                    expenseData: _expenseData,
                  ),
                  const SizedBox(height: 10),
                  _buildQuickActions(context, loc),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, LocalizationService loc) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.translate('welcome'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 28,
                  child: Icon(
                    Icons.trending_up_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('today_sales'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '₹ ${_todaySales.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, LocalizationService loc) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.85,
      children: [
        _ActionCard(
          icon: Icons.receipt_long_rounded,
          label: loc.translate('new_bill'),
          color: Colors.green,
          onTap: () => _navigate(context, TransactionScreen(type: 'INVOICE')),
        ),
        _ActionCard(
          icon: Icons.description_rounded,
          label: loc.translate('new_quote'),
          color: Colors.orange,
          onTap: () => _navigate(context, TransactionScreen(type: 'QUOTE')),
        ),
        _ActionCard(
          icon: Icons.person_add_rounded,
          label: loc.translate('add_customer'),
          color: Colors.blue,
          onTap: () => _navigate(context, CustomerListScreen()),
        ),
        Stack(
          fit: StackFit.expand,
          children: [
            _ActionCard(
              icon: Icons.inventory_2_rounded,
              label: loc.translate('items'),
              color: Colors.deepPurple,
              onTap: () => _navigate(context, ItemMasterScreen()),
            ),
            if (_lowStockCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$_lowStockCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        _ActionCard(
          icon: Icons.payments_rounded,
          label: loc.translate('expenses'),
          color: Colors.redAccent,
          onTap: () => _navigate(context, const ExpenseScreen()),
        ),
        _ActionCard(
          icon: Icons.local_shipping_rounded,
          label: loc.translate('suppliers'),
          color: Colors.indigo,
          onTap: () => _navigate(context, const SupplierScreen()),
        ),
        _ActionCard(
          icon: Icons.shopping_cart_rounded,
          label: loc.translate('purchases'),
          color: Colors.teal,
          onTap: () => _navigate(context, const PurchaseScreen()),
        ),
        _ActionCard(
          icon: Icons.bar_chart_rounded,
          label: loc.translate('reports'),
          color: Colors.blueGrey,
          onTap: () => _navigate(context, const ReportsScreen()),
        ),
        _ActionCard(
          icon: Icons.cloud_upload_rounded,
          label: loc.translate('backup'),
          color: Colors.brown,
          onTap: () => _navigate(context, const BackupScreen()),
        ),
      ],
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _loadStats());
  }

  Widget _buildDrawer(BuildContext context, LocalizationService loc) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text(
              'AMR Enterprises',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: const Text('Billing System'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                'AMR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC62828),
                ),
              ),
            ),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_rounded),
            title: Text(loc.translate('dashboard')),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings_rounded),
            title: Text(loc.translate('settings')),
            onTap: () {
              Navigator.pop(context);
              _navigate(context, SettingsScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: Text(loc.translate('select_language')),
            onTap: () {
              Navigator.pop(context);
              _navigate(context, LanguageSelectionScreen());
            },
          ),
          ListTile(
            leading: Icon(
              Icons.warning_amber_rounded,
              color: _lowStockCount > 0 ? Colors.red : Colors.grey,
            ),
            title: Text(loc.translate('stock_alerts')),
            trailing: _lowStockCount > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_lowStockCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                : null,
            onTap: () {
              Navigator.pop(context);
              _navigate(context, const LowStockScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_rounded, color: Colors.blue),
            title: Text(loc.translate('transaction_history')),
            onTap: () {
              Navigator.pop(context);
              _navigate(context, const TransactionHistoryScreen());
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_sync_rounded, color: Colors.blue),
            title: const Text('Cloud Sync (Supabase)'),
            subtitle: const Text('Sync data with web & other devices'),
            onTap: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Synchronizing with Supabase...'),
                  duration: Duration(seconds: 2),
                ),
              );
              try {
                await SupabaseService().syncAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sync Completed Successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sync Failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: GoogleFonts.notoSansTamil(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
