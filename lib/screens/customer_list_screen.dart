import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../core/localization_service.dart';
import 'customer_ledger_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
    });
  }

  void _showCustomerDialog(BuildContext context, {Customer? customer}) {
    final nameController = TextEditingController(text: customer?.name);
    final mobileController = TextEditingController(text: customer?.mobile);
    final addressController = TextEditingController(text: customer?.address);
    final gstController = TextEditingController(text: customer?.gstNo);
    final formKey = GlobalKey<FormState>();
    final loc = Provider.of<LocalizationService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            customer == null
                ? loc.translate('add_customer')
                : loc.translate('customers'),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Name / பெயர்'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: mobileController,
                    decoration: InputDecoration(labelText: 'Mobile / கைப்பேசி'),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(labelText: 'Address / முகவரி'),
                    maxLines: 2,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: gstController,
                    decoration: InputDecoration(labelText: 'GST No (Optional)'),
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
                  final newCustomer = Customer(
                    id: customer?.id,
                    name: nameController.text,
                    mobile: mobileController.text,
                    address: addressController.text,
                    gstNo: gstController.text,
                  );

                  if (customer == null) {
                    Provider.of<CustomerProvider>(
                      context,
                      listen: false,
                    ).addCustomer(newCustomer);
                  } else {
                    Provider.of<CustomerProvider>(
                      context,
                      listen: false,
                    ).updateCustomer(newCustomer);
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

  @override
  Widget build(BuildContext context) {
    var loc = Provider.of<LocalizationService>(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('customers'))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCustomerDialog(context),
        child: Icon(Icons.add),
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, child) {
          if (provider.customers.isEmpty) {
            return Center(
              child: Text('No Customers Found / வாடிக்கையாளர்கள் இல்லை'),
            );
          }
          return ListView.builder(
            itemCount: provider.customers.length,
            itemBuilder: (context, index) {
              final customer = provider.customers[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    child: Text(customer.name.characters.first.toUpperCase()),
                  ),
                  title: Text(
                    customer.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(customer.mobile ?? 'No Mobile'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.history, color: Colors.blue),
                        tooltip: loc.translate('view_ledger'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CustomerLedgerScreen(customer: customer),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.grey),
                        onPressed: () {
                          _showDeleteConfirmation(context, customer, loc);
                        },
                      ),
                    ],
                  ),
                  onTap: () => _showCustomerDialog(context, customer: customer),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Customer customer,
    LocalizationService loc,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Customer?'),
        content: Text('Are you sure you want to delete ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Provider.of<CustomerProvider>(
                context,
                listen: false,
              ).deleteCustomer(customer.id!);
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
