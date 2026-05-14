import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_constants.dart';
import '../models/customer.dart';
import '../models/item.dart';
import '../models/transaction_model.dart';
import '../providers/customer_provider.dart';
import '../providers/item_provider.dart';
import '../providers/transaction_provider.dart';
import '../core/localization_service.dart';
import '../core/pdf_service.dart';
import '../core/sharing_service.dart';
import '../core/thermal_printer_service.dart';

class TransactionScreen extends StatefulWidget {
  final String type; // 'INVOICE' or 'QUOTE'

  const TransactionScreen({super.key, required this.type});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  Customer? _selectedCustomer;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _notesController = TextEditingController();

  // Item entry controllers
  Item? _selectedItem;
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  // Payment controllers
  final TextEditingController _paidAmountController = TextEditingController(
    text: '0',
  );
  String _paymentStatus = 'PAID'; // PAID, UNPAID, PARTIAL

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
      Provider.of<ItemProvider>(context, listen: false).loadItems();
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).clearTransaction();
    });
  }

  void _addItem(BuildContext context) {
    if (_selectedItem == null ||
        _qtyController.text.isEmpty ||
        _rateController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please fill item details')));
      return;
    }

    final qty = double.tryParse(_qtyController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;

    if (qty <= 0 || rate <= 0) {
      // In professional apps, we might allow non-positive but for now let's be strict
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invalid Quantity or Rate')));
      return;
    }

    // Create a temporary item object with the entered rate (could be different from master)
    // IMPORTANT: Include the ID so stock deduction works
    final itemToAdd = Item(
      id: _selectedItem!.id,
      nameTa: _selectedItem!.nameTa,
      nameEn: _selectedItem!.nameEn,
      unit: _selectedItem!.unit,
      rate: rate,
    );

    Provider.of<TransactionProvider>(
      context,
      listen: false,
    ).addItem(itemToAdd, qty);

    // Update paid amount for convenience if it was auto-matching total
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    if (_paymentStatus == 'PAID') {
      _paidAmountController.text = provider.totalAmount.toStringAsFixed(2);
    }

    // Clear item entry
    setState(() {
      _selectedItem = null;
      _qtyController.clear();
      _rateController.clear();
    });
    // Hide keyboard
    FocusScope.of(context).unfocus();
  }

  Future<void> _saveTransaction(BuildContext context) async {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a customer')));
      return;
    }
    if (provider.currentItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please add at least one item')));
      return;
    }

    final total = provider.totalAmount;
    final paid = double.tryParse(_paidAmountController.text) ?? 0;
    final balance = total - paid;
    String status = 'PAID';
    if (paid == 0) {
      status = 'UNPAID';
    } else if (paid < total) {
      status = 'PARTIAL';
    }

    final prefs = await SharedPreferences.getInstance();
    if (!context.mounted) return;
    final prefix =
        prefs.getString(AppConstants.keyInvoicePrefix) ??
        (widget.type == 'INVOICE' ? 'INV' : 'QT');
    final txnNumber = '$prefix-${DateTime.now().millisecondsSinceEpoch}';

    final txn = TransactionModel(
      type: widget.type,
      txnNumber: txnNumber,
      date: _selectedDate,
      customerId: _selectedCustomer!.id,
      totalAmount: total,
      paidAmount: paid,
      balanceAmount: balance,
      status: status,
      notes: _notesController.text,
    );

    // Save to DB
    int txnId = await provider.saveTransaction(txn);
    txn.id = txnId;

    // Clear transaction in provider after save is confirmed
    // provider.clearTransaction(); // Already done inside saveTransaction

    if (!context.mounted) return;

    // Show success dialog with share options
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Transaction Saved'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.print, color: Colors.blue),
              title: Text('Print Receipt'),
              onTap: () async {
                final printerService = ThermalPrinterService();
                final isConnected = await printerService.isConnected();
                if (isConnected == true) {
                  final prefs = await SharedPreferences.getInstance();
                  final companyName =
                      prefs.getString(AppConstants.keyCompanyName) ??
                      'AMR Enterprises';
                  final address =
                      prefs.getString(AppConstants.keyCompanyAddress) ?? '';
                  final mobile =
                      prefs.getString(AppConstants.keyCompanyMobile) ?? '';
                  await printerService.printReceipt(
                    txn,
                    _selectedCustomer!,
                    companyName,
                    address,
                    mobile,
                  );
                } else {
                  await PdfService.generateAndPrint(
                    txn,
                    _selectedCustomer!,
                    widget.type,
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.phone_android, color: Colors.green),
              title: Text('Share via WhatsApp'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                final companyName =
                    prefs.getString(AppConstants.keyCompanyName) ??
                    'AMR Enterprises';
                await SharingService.shareToWhatsApp(
                  txn,
                  _selectedCustomer!,
                  companyName,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.sms, color: Colors.orange),
              title: Text('Share via SMS'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                final companyName =
                    prefs.getString(AppConstants.keyCompanyName) ??
                    'AMR Enterprises';
                await SharingService.shareToSMS(
                  txn,
                  _selectedCustomer!,
                  companyName,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: Colors.purple),
              title: Text('Share PDF File'),
              onTap: () async {
                final bytes = await PdfService.generatePdfBytes(
                  txn,
                  _selectedCustomer!,
                  widget.type,
                );
                await SharingService.sharePdfFile(
                  bytes,
                  '${txn.txnNumber}.pdf',
                  'Invoice from AMR Billing',
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final customers = Provider.of<CustomerProvider>(context).customers;
    final items = Provider.of<ItemProvider>(context).items;
    final txnProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.type == 'INVOICE'
              ? loc.translate('new_bill')
              : loc.translate('new_quote'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () => _saveTransaction(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer & Date
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: loc.translate('customers'),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Customer>(
                        value: _selectedCustomer,
                        isExpanded: true,
                        hint: Text(loc.translate('customers')),
                        items: customers
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() => _selectedCustomer = val);
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                ),
                Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              ],
            ),
            SizedBox(height: 24),

            // Add Item Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: loc.translate('items'),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Item>(
                          value: _selectedItem,
                          isExpanded: true,
                          hint: Text(loc.translate('items')),
                          items: items
                              .map(
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(
                                    (i.nameEn == null || i.nameEn!.isEmpty)
                                        ? i.nameTa
                                        : '${i.nameEn} (${i.nameTa})',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedItem = val;
                              if (val != null) {
                                _rateController.text = val.rate.toString();
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _qtyController,
                            decoration: InputDecoration(labelText: 'Qty'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _rateController,
                            decoration: InputDecoration(labelText: 'Rate'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => _addItem(context),
                          child: Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Items List
            Text(
              'Items / பொருட்கள்',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: txnProvider.currentItems.length,
              itemBuilder: (context, index) {
                final item = txnProvider.currentItems[index];
                return ListTile(
                  title: Text(item.itemName),
                  subtitle: Text('${item.qty} x ${item.rate}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹ ${item.amount.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => txnProvider.removeItem(index),
                      ),
                    ],
                  ),
                );
              },
            ),
            Divider(),

            // Total
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${loc.translate('total')}: ₹ ${txnProvider.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),

            SizedBox(height: 16),
            // Payment Status & Paid Amount (Invoices Only)
            if (widget.type == 'INVOICE') ...[
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: loc.translate('payment_status'),
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _paymentStatus,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(
                              value: 'PAID',
                              child: Text(loc.translate('paid')),
                            ),
                            DropdownMenuItem(
                              value: 'PARTIAL',
                              child: Text(loc.translate('partial')),
                            ),
                            DropdownMenuItem(
                              value: 'UNPAID',
                              child: Text(loc.translate('unpaid')),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _paymentStatus = val!;
                              if (_paymentStatus == 'PAID') {
                                _paidAmountController.text = txnProvider
                                    .totalAmount
                                    .toStringAsFixed(2);
                              } else if (_paymentStatus == 'UNPAID') {
                                _paidAmountController.text = '0';
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _paidAmountController,
                      decoration: InputDecoration(
                        labelText: loc.translate('paid_amount'),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        final paid = double.tryParse(val) ?? 0;
                        setState(() {
                          if (paid <= 0) {
                            _paymentStatus = 'UNPAID';
                          } else if (paid < txnProvider.totalAmount) {
                            _paymentStatus = 'PARTIAL';
                          } else {
                            _paymentStatus = 'PAID';
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${loc.translate('balance_amount')}: ₹ ${(txnProvider.totalAmount - (double.tryParse(_paidAmountController.text) ?? 0)).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(labelText: 'Notes / குறிப்புகள்'),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
