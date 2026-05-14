import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/supplier.dart';
import '../providers/supplier_provider.dart';
import '../core/localization_service.dart';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<SupplierProvider>(context, listen: false).loadSuppliers();
    });
  }

  void _showSupplierDialog([Supplier? supplier]) {
    final bool isEditing = supplier != null;
    final nameController = TextEditingController(text: supplier?.name ?? '');
    final mobileController = TextEditingController(
      text: supplier?.mobile ?? '',
    );
    final addressController = TextEditingController(
      text: supplier?.address ?? '',
    );
    final gstController = TextEditingController(text: supplier?.gstNo ?? '');
    final loc = Provider.of<LocalizationService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isEditing ? loc.translate('edit') : loc.translate('add_supplier'),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: loc.translate('name')),
              ),
              TextField(
                controller: mobileController,
                decoration: InputDecoration(labelText: loc.translate('mobile')),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: loc.translate('address'),
                ),
              ),
              TextField(
                controller: gstController,
                decoration: InputDecoration(labelText: loc.translate('gst_no')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              final newSupplier = Supplier(
                id: supplier?.id,
                name: nameController.text,
                mobile: mobileController.text,
                address: addressController.text,
                gstNo: gstController.text,
              );
              final provider = Provider.of<SupplierProvider>(
                context,
                listen: false,
              );
              if (isEditing) {
                provider.updateSupplier(newSupplier);
              } else {
                provider.addSupplier(newSupplier);
              }
              Navigator.pop(context);
            },
            child: Text(loc.translate('save')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final provider = Provider.of<SupplierProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('suppliers'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: loc.translate('search'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (val) => setState(() {}),
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: provider.suppliers.length,
                    itemBuilder: (context, index) {
                      final s = provider.suppliers[index];
                      if (_searchController.text.isNotEmpty &&
                          !s.name.toLowerCase().contains(
                            _searchController.text.toLowerCase(),
                          )) {
                        return const SizedBox.shrink();
                      }
                      return ListTile(
                        leading: CircleAvatar(child: Text(s.name[0])),
                        title: Text(s.name),
                        subtitle: Text(s.mobile ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showSupplierDialog(s),
                        ),
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(loc.translate('delete')),
                              content: Text(loc.translate('confirm_delete')),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(loc.translate('cancel')),
                                ),
                                TextButton(
                                  onPressed: () {
                                    provider.deleteSupplier(s.id!);
                                    Navigator.pop(ctx);
                                  },
                                  child: Text(loc.translate('delete')),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupplierDialog(),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
