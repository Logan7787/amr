import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/purchase_model.dart';
import '../models/supplier.dart';
import '../models/item.dart';
import '../providers/supplier_provider.dart';
import '../providers/item_provider.dart';
import '../data/repository.dart';
import '../core/localization_service.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final DataRepository _repository = DataRepository();
  Supplier? _selectedSupplier;
  final List<PurchaseItem> _purchaseItems = [];
  final TextEditingController _txnController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController(
    text: '0',
  );

  double get _totalAmount =>
      _purchaseItems.fold(0, (sum, item) => sum + item.amount);
  double get _balanceAmount =>
      _totalAmount - (double.tryParse(_paidAmountController.text) ?? 0);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<SupplierProvider>(context, listen: false).loadSuppliers();
      Provider.of<ItemProvider>(context, listen: false).loadItems();
    });
  }

  void _addItem() {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final loc = Provider.of<LocalizationService>(context, listen: false);
    Item? selectedItem;
    final qtyController = TextEditingController();
    final rateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(loc.translate('items')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Item>(
                initialValue: selectedItem,
                items: itemProvider.items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(
                      (loc.locale.languageCode == 'ta' ||
                              item.nameEn == null ||
                              item.nameEn!.isEmpty)
                          ? item.nameTa
                          : item.nameEn!,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setDialogState(() {
                    selectedItem = val;
                    rateController.text = val?.rate.toString() ?? '';
                  });
                },
              ),
              TextField(
                controller: qtyController,
                decoration: InputDecoration(
                  labelText: loc.translate('stock_quantity'),
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: rateController,
                decoration: InputDecoration(labelText: loc.translate('total')),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedItem == null || qtyController.text.isEmpty) return;
                final qty = double.parse(qtyController.text);
                final rate = double.parse(rateController.text);
                setState(() {
                  _purchaseItems.add(
                    PurchaseItem(
                      itemId: selectedItem!.id,
                      itemName:
                          (loc.locale.languageCode == 'ta' ||
                              selectedItem!.nameEn == null ||
                              selectedItem!.nameEn!.isEmpty)
                          ? selectedItem!.nameTa
                          : selectedItem!.nameEn!,
                      qty: qty,
                      rate: rate,
                      amount: qty * rate,
                    ),
                  );
                });
                Navigator.pop(context);
              },
              child: Text(loc.translate('save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePurchase() async {
    if (_selectedSupplier == null || _purchaseItems.isEmpty) return;

    final loc = Provider.of<LocalizationService>(context, listen: false);
    final purchase = PurchaseModel(
      supplierId: _selectedSupplier!.id,
      txnNumber: _txnController.text,
      date: DateTime.now(),
      totalAmount: _totalAmount,
      paidAmount: double.tryParse(_paidAmountController.text) ?? 0,
      balanceAmount: _balanceAmount,
      notes: _notesController.text,
      items: _purchaseItems,
    );

    await _repository.createPurchase(purchase);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.translate('save_success'))));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final supplierProvider = Provider.of<SupplierProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('new_purchase'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<Supplier>(
              initialValue: _selectedSupplier,
              decoration: InputDecoration(
                labelText: loc.translate('suppliers'),
              ),
              items: supplierProvider.suppliers.map((s) {
                return DropdownMenuItem(value: s, child: Text(s.name));
              }).toList(),
              onChanged: (val) => setState(() => _selectedSupplier = val),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _txnController,
              decoration: InputDecoration(labelText: 'Purchase Ref / Bill No'),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.translate('items'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: Text(loc.translate('items')),
                ),
              ],
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _purchaseItems.length,
              itemBuilder: (context, index) {
                final item = _purchaseItems[index];
                return ListTile(
                  title: Text(item.itemName),
                  subtitle: Text('${item.qty} x ${item.rate}'),
                  trailing: Text('₹ ${item.amount.toStringAsFixed(2)}'),
                  onLongPress: () =>
                      setState(() => _purchaseItems.removeAt(index)),
                );
              },
            ),
            const Divider(height: 32),
            Text(
              '${loc.translate('total')}: ₹ ${_totalAmount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextField(
              controller: _paidAmountController,
              decoration: InputDecoration(
                labelText: loc.translate('paid_amount'),
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) => setState(() {}),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '${loc.translate('balance_amount')}: ₹ ${_balanceAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(labelText: loc.translate('notes')),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _savePurchase,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: Text(loc.translate('save')),
            ),
          ],
        ),
      ),
    );
  }
}
