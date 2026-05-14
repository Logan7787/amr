import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../models/transaction_model.dart';
import '../models/customer.dart';

class ThermalPrinterService {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  Future<List<BluetoothDevice>> getDevices() async {
    return await _bluetooth.getBondedDevices();
  }

  Future<void> connect(BluetoothDevice device) async {
    await _bluetooth.connect(device);
  }

  Future<void> disconnect() async {
    await _bluetooth.disconnect();
  }

  Future<bool?> isConnected() async {
    return await _bluetooth.isConnected;
  }

  Future<void> printReceipt(
    TransactionModel txn,
    Customer customer,
    String companyName,
    String address,
    String mobile,
  ) async {
    bool? connected = await _bluetooth.isConnected;
    if (connected == true) {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      // Header
      bytes += generator.text(
        companyName,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      if (address.isNotEmpty) {
        bytes += generator.text(
          address,
          styles: const PosStyles(align: PosAlign.center),
        );
      }
      if (mobile.isNotEmpty) {
        bytes += generator.text(
          'Mobile: $mobile',
          styles: const PosStyles(align: PosAlign.center),
        );
      }
      bytes += generator.feed(1);

      // Transaction Info
      bytes += generator.text('Date: ${txn.date.toString().split(' ')[0]}');
      bytes += generator.text('No: ${txn.txnNumber}');
      bytes += generator.text('To: ${customer.name}');
      bytes += generator.hr();

      // Items Table
      bytes += generator.row([
        PosColumn(text: 'Item', width: 6),
        PosColumn(
          text: 'Qty',
          width: 2,
          styles: const PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          text: 'Total',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      for (var item in txn.items ?? []) {
        bytes += generator.row([
          PosColumn(text: item.itemName, width: 6),
          PosColumn(
            text: item.qty.toString(),
            width: 2,
            styles: const PosStyles(align: PosAlign.right),
          ),
          PosColumn(
            text: item.amount.toStringAsFixed(0),
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }
      bytes += generator.hr();

      // Total
      bytes += generator.row([
        PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
          text: 'Rs. ${txn.totalAmount.toStringAsFixed(2)}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);

      if (txn.type == 'INVOICE') {
        bytes += generator.row([
          PosColumn(text: 'Paid', width: 6),
          PosColumn(
            text: 'Rs. ${txn.paidAmount.toStringAsFixed(2)}',
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
        bytes += generator.row([
          PosColumn(
            text: 'Balance',
            width: 6,
            styles: const PosStyles(bold: true),
          ),
          PosColumn(
            text: 'Rs. ${txn.balanceAmount.toStringAsFixed(2)}',
            width: 6,
            styles: const PosStyles(align: PosAlign.right, bold: true),
          ),
        ]);
      }

      bytes += generator.feed(2);
      bytes += generator.text(
        'Thank you for your business!',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(3);
      bytes += generator.cut();

      await _bluetooth.writeBytes(Uint8List.fromList(bytes));
    }
  }
}
