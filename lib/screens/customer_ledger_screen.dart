import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../models/transaction_model.dart';
import '../data/repository.dart';
import '../core/localization_service.dart';
import '../core/pdf_service.dart';
import '../core/sharing_service.dart';

class CustomerLedgerScreen extends StatefulWidget {
  final Customer customer;
  const CustomerLedgerScreen({super.key, required this.customer});

  @override
  State<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends State<CustomerLedgerScreen> {
  final DataRepository _repository = DataRepository();
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  double _totalSales = 0.0;
  double _totalPaid = 0.0;
  double _totalDue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final txns = await _repository.getCustomerTransactions(widget.customer.id!);
    double sales = 0;
    double paid = 0;
    for (var t in txns) {
      if (t.type == 'INVOICE') {
        sales += t.totalAmount;
        paid += t.paidAmount;
      }
    }
    setState(() {
      _transactions = txns;
      _totalSales = sales;
      _totalPaid = paid;
      _totalDue = sales - paid;
      _isLoading = false;
    });
  }

  Future<void> _handleDownload(TransactionModel txn) async {
    final items = await _repository.getTransactionItems(txn.id!);
    txn.items = items;
    if (!mounted) return;
    await PdfService.generateAndPrint(txn, widget.customer, txn.type);
  }

  Future<void> _handleShare(TransactionModel txn) async {
    final items = await _repository.getTransactionItems(txn.id!);
    txn.items = items;
    final bytes = await PdfService.generatePdfBytes(
      txn,
      widget.customer,
      txn.type,
    );
    await SharingService.sharePdfFile(
      bytes,
      '${txn.txnNumber}.pdf',
      'Invoice from AMR Enterprises',
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('customer_ledger')),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Statement PDF coming soon!')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryHeader(loc, theme),
                Expanded(
                  child: _transactions.isEmpty
                      ? Center(child: Text(loc.translate('no_data')))
                      : ListView.builder(
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final txn = _transactions[index];
                            return _buildTransactionItem(txn, loc);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryHeader(LocalizationService loc, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.05),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.customer.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _totalDue > 0
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${loc.translate('total_due')}: ₹${_totalDue.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: _totalDue > 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric(loc, 'total', _totalSales, Colors.blue),
              _buildMetric(loc, 'paid_amount', _totalPaid, Colors.green),
              _buildMetric(loc, 'balance_amount', _totalDue, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
    LocalizationService loc,
    String labelKey,
    double value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          loc.translate(labelKey),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel txn, LocalizationService loc) {
    bool isCredit = txn.status != 'PAID';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Inv #${txn.id ?? "N/A"}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '₹${txn.totalAmount}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('dd MMM yyyy, hh:mm a').format(txn.date)),
                Text(
                  'Paid: ₹${txn.paidAmount}',
                  style: TextStyle(color: isCredit ? Colors.red : Colors.green),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.file_download, color: Colors.blue),
              onPressed: () => _handleDownload(txn),
            ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.green),
              onPressed: () => _handleShare(txn),
            ),
          ],
        ),
        onTap: () {
          // Future: Navigate to transaction detail
        },
      ),
    );
  }
}
