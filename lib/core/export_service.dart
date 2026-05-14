import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';
import '../models/item.dart';
import '../core/localization_service.dart';

class ExportService {
  static Future<void> exportSalesToExcel(
    List<TransactionModel> transactions,
    LocalizationService loc,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sales Report'];
    excel.delete('Sheet1');

    // Headers
    sheetObject.appendRow([
      TextCellValue('Date'),
      TextCellValue('Invoice No'),
      TextCellValue('Customer'),
      TextCellValue('Total Amount'),
      TextCellValue('Paid Amount'),
      TextCellValue('Status'),
    ]);

    for (var txn in transactions) {
      sheetObject.appendRow([
        TextCellValue(txn.date.toIso8601String().split('T')[0]),
        TextCellValue(txn.txnNumber),
        TextCellValue('ID: ${txn.customerId ?? "Walk-in"}'),
        DoubleCellValue(txn.totalAmount),
        DoubleCellValue(txn.paidAmount),
        TextCellValue(txn.status),
      ]);
    }

    await _saveAndShare(excel, 'Sales_Report.xlsx');
  }

  static Future<void> exportInventoryToExcel(
    List<Item> items,
    LocalizationService loc,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Inventory'];
    excel.delete('Sheet1');

    // Headers
    sheetObject.appendRow([
      TextCellValue('Item Name (TA)'),
      TextCellValue('Item Name (EN)'),
      TextCellValue('Rate'),
      TextCellValue('Current Stock'),
      TextCellValue('Unit'),
    ]);

    for (var item in items) {
      sheetObject.appendRow([
        TextCellValue(item.nameTa),
        TextCellValue(item.nameEn ?? ''),
        DoubleCellValue(item.rate),
        DoubleCellValue(item.stockQuantity),
        TextCellValue(item.unit ?? ''),
      ]);
    }

    await _saveAndShare(excel, 'Inventory_Report.xlsx');
  }

  static Future<void> _saveAndShare(Excel excel, String fileName) async {
    var fileBytes = excel.save();
    if (fileBytes == null) return;

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(fileBytes);

    await Share.shareXFiles([XFile(file.path)], text: 'Exported Report');
  }
}
