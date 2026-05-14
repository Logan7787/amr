import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../data/repository.dart';
import '../core/localization_service.dart';

class LowStockScreen extends StatefulWidget {
  const LowStockScreen({super.key});

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  final DataRepository _repository = DataRepository();
  List<Item> _lowStockItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLowStock();
  }

  Future<void> _loadLowStock() async {
    final items = await _repository.getLowStockItems();
    setState(() {
      _lowStockItems = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final isTamil = loc.locale.languageCode == 'ta';

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('stock_alerts'))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lowStockItems.isEmpty
          ? const Center(child: Text('All stock levels are healthy!'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _lowStockItems.length,
              itemBuilder: (context, index) {
                final item = _lowStockItems[index];
                return Card(
                  color: Colors.red.shade50,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red,
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      isTamil ? item.nameTa : (item.nameEn ?? item.nameTa),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${loc.translate('stock')}: ${item.stockQuantity} ${item.unit ?? ""}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Limit',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red.shade700,
                          ),
                        ),
                        Text(
                          '${item.lowStockThreshold}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
