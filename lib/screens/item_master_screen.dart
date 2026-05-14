import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../core/localization_service.dart';

class ItemMasterScreen extends StatefulWidget {
  const ItemMasterScreen({super.key});

  @override
  State<ItemMasterScreen> createState() => _ItemMasterScreenState();
}

class _ItemMasterScreenState extends State<ItemMasterScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<ItemProvider>(context, listen: false).loadItems();
    });
  }

  void _showItemDialog(BuildContext context, {Item? item}) {
    final nameTaController = TextEditingController(text: item?.nameTa);
    final nameEnController = TextEditingController(text: item?.nameEn);
    final unitController = TextEditingController(text: item?.unit);
    final rateController = TextEditingController(
      text: item != null ? item.rate.toString() : '',
    );
    final stockController = TextEditingController(
      text: item != null ? item.stockQuantity.toString() : '0',
    );
    final thresholdController = TextEditingController(
      text: item != null ? item.lowStockThreshold.toString() : '0',
    );
    final formKey = GlobalKey<FormState>();
    final loc = Provider.of<LocalizationService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            item == null
                ? 'Add Item / பொருள் சேர்'
                : 'Edit Item / பொருள் திருத்து',
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameTaController,
                    decoration: InputDecoration(
                      labelText: 'Tamil Name / தமிழ் பெயர்',
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: nameEnController,
                    decoration: InputDecoration(
                      labelText: 'English Name (Optional)',
                    ),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: unitController,
                    decoration: InputDecoration(
                      labelText: 'Unit / அழகு (kg, nos)',
                    ),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: rateController,
                    decoration: InputDecoration(labelText: 'Rate / விலை'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid Number';
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: stockController,
                          decoration: InputDecoration(
                            labelText: loc.translate('stock'),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => double.tryParse(v ?? '') == null
                              ? 'Invalid'
                              : null,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: thresholdController,
                          decoration: InputDecoration(
                            labelText: loc.translate('low_stock'),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => double.tryParse(v ?? '') == null
                              ? 'Invalid'
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newItem = Item(
                    id: item?.id,
                    nameTa: nameTaController.text,
                    nameEn: nameEnController.text,
                    unit: unitController.text,
                    rate: double.parse(rateController.text),
                    stockQuantity: double.parse(stockController.text),
                    lowStockThreshold: double.parse(thresholdController.text),
                  );

                  if (item == null) {
                    Provider.of<ItemProvider>(
                      context,
                      listen: false,
                    ).addItem(newItem);
                  } else {
                    Provider.of<ItemProvider>(
                      context,
                      listen: false,
                    ).updateItem(newItem);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(loc.translate('save')),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Item item,
    LocalizationService loc,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Item?'),
        content: Text(
          'Delete ${item.nameTa}${(item.nameEn != null && item.nameEn!.isNotEmpty) ? " (${item.nameEn})" : ""}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Provider.of<ItemProvider>(
                context,
                listen: false,
              ).deleteItem(item.id!);
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var loc = Provider.of<LocalizationService>(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('items'))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(context),
        child: Icon(Icons.add),
      ),
      body: Consumer<ItemProvider>(
        builder: (context, provider, child) {
          if (provider.items.isEmpty) {
            return Center(child: Text('No Items Found / பொருட்கள் இல்லை'));
          }
          return ListView.builder(
            itemCount: provider.items.length,
            itemBuilder: (context, index) {
              final item = provider.items[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    item.nameTa,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    '${(item.nameEn != null && item.nameEn!.isNotEmpty) ? item.nameEn : "No English Name"} - ${item.unit}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹ ${item.rate.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  item.stockQuantity <= item.lowStockThreshold
                                  ? Colors.red.shade100
                                  : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${loc.translate('stock')}: ${item.stockQuantity}',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    item.stockQuantity <= item.lowStockThreshold
                                    ? Colors.red
                                    : Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showItemDialog(context, item: item),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _showDeleteConfirmation(context, item, loc),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
