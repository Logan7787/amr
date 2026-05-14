import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../data/repository.dart';
import '../models/transaction_model.dart';
import '../models/customer.dart';
import '../core/localization_service.dart';
import '../core/pdf_service.dart';
import '../core/sharing_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final DataRepository _repository = DataRepository();
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterType = 'ALL'; // ALL, INVOICE, QUOTE

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final txns = await _repository.getTransactions();
    setState(() {
      _transactions = txns;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredTransactions = _transactions.where((txn) {
        final matchesSearch = txn.txnNumber.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );
        final matchesType = _filterType == 'ALL' || txn.type == _filterType;
        return matchesSearch && matchesType;
      }).toList();
    });
  }

  Future<void> _handleDownload(
    TransactionModel txn,
    LocalizationService loc,
  ) async {
    // We need customer details for the PDF
    final customers = await _repository.getCustomers();
    final customer = customers.firstWhere(
      (c) => c.id == txn.customerId,
      orElse: () => Customer(id: 0, name: 'Walking Customer', mobile: ''),
    );

    // Also need items
    final items = await _repository.getTransactionItems(txn.id!);
    txn.items = items;

    if (!mounted) return;
    await PdfService.generateAndPrint(txn, customer, txn.type);
  }

  Future<void> _handleShare(TransactionModel txn) async {
    final customers = await _repository.getCustomers();
    final customer = customers.firstWhere(
      (c) => c.id == txn.customerId,
      orElse: () => Customer(id: 0, name: 'Walking Customer', mobile: ''),
    );

    final items = await _repository.getTransactionItems(txn.id!);
    txn.items = items;

    final bytes = await PdfService.generatePdfBytes(txn, customer, txn.type);
    await SharingService.sharePdfFile(
      bytes,
      '${txn.txnNumber}.pdf',
      'Invoice from AMR Enterprises',
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('transaction_history'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: loc.translate('search_invoice'),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (val) {
                    _searchQuery = val;
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(loc.translate('all')),
                        selected: _filterType == 'ALL',
                        onSelected: (val) {
                          setState(() {
                            _filterType = 'ALL';
                            _applyFilters();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(loc.translate('invoice')),
                        selected: _filterType == 'INVOICE',
                        onSelected: (val) {
                          setState(() {
                            _filterType = 'INVOICE';
                            _applyFilters();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(loc.translate('quotation')),
                        selected: _filterType == 'QUOTE',
                        onSelected: (val) {
                          setState(() {
                            _filterType = 'QUOTE';
                            _applyFilters();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                ? const Center(child: Text('No transactions found'))
                : RefreshIndicator(
                    onRefresh: _loadTransactions,
                    child: ListView.builder(
                      itemCount: _filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final txn = _filteredTransactions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            title: Text(
                              txn.txnNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat(
                                'dd MMM yyyy, hh:mm a',
                              ).format(txn.date),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.file_download,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _handleDownload(txn, loc),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.share,
                                    color: Colors.green,
                                  ),
                                  onPressed: () => _handleShare(txn),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
