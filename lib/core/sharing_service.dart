import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/transaction_model.dart';
import '../models/customer.dart';

class SharingService {
  static Future<void> shareToWhatsApp(
    TransactionModel txn,
    Customer customer,
    String companyName,
  ) async {
    final message = _generateMessage(txn, customer, companyName);
    final phone = customer.mobile ?? '';

    // Clean phone number (remove spaces, +, etc if needed, but WhatsApp usually handles it)
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

    final url =
        'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> shareToSMS(
    TransactionModel txn,
    Customer customer,
    String companyName,
  ) async {
    final message = _generateMessage(txn, customer, companyName);
    final phone = customer.mobile ?? '';

    final Uri smsLaunchUri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: <String, String>{'body': message},
    );

    if (await canLaunchUrl(smsLaunchUri)) {
      await launchUrl(smsLaunchUri);
    }
  }

  static Future<void> sharePdfFile(
    List<int> bytes,
    String filename,
    String text,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/$filename').create();
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: text);
  }

  static String _generateMessage(
    TransactionModel txn,
    Customer customer,
    String companyName,
  ) {
    final type = txn.type == 'INVOICE' ? 'Bill' : 'Quotation';
    var msg = 'Hello ${customer.name},\n\n';
    msg += 'Your $type from $companyName is ready.\n';
    msg += 'No: ${txn.txnNumber}\n';
    msg += 'Date: ${txn.date.toString().split(' ')[0]}\n';
    msg += 'Total Amount: ₹ ${txn.totalAmount.toStringAsFixed(2)}\n';

    if (txn.type == 'INVOICE') {
      msg += 'Status: ${txn.status}\n';
      if (txn.balanceAmount > 0) {
        msg += 'Balance Due: ₹ ${txn.balanceAmount.toStringAsFixed(2)}\n';
      }
    }

    msg += '\nThank you for your business!';
    return msg;
  }
}
