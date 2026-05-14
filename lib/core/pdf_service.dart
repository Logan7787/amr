import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamil_pdf_shaper/tamil_pdf_shaper.dart';
import '../core/app_constants.dart';
import '../models/transaction_model.dart';
import '../models/customer.dart';

class PdfService {
  static Future<pw.Document> _buildDocument(
    TransactionModel txn,
    Customer customer,
    String title,
  ) async {
    final pdf = pw.Document();

    // Load Tamil Font optimized for PDF shaping
    final font = await TamilPdfFont.load();
    final fontBold = font; // Use same font if bold is not explicitly provided by package

    final prefs = await SharedPreferences.getInstance();
    final companyName =
        prefs.getString(AppConstants.keyCompanyName) ?? 'AMR Enterprises';
    final companyAddress =
        prefs.getString(AppConstants.keyCompanyAddress) ?? '';
    final companyMobile = prefs.getString(AppConstants.keyCompanyMobile) ?? '';
    final logoPath = prefs.getString(AppConstants.keyLogoPath);
    final terms = prefs.getString(AppConstants.keyTermsConditions) ?? '';

    pw.MemoryImage? logoImage;
    if (!kIsWeb && logoPath != null && File(logoPath).existsSync()) {
      logoImage = pw.MemoryImage(File(logoPath).readAsBytesSync());
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        if (logoImage != null)
                          pw.Container(
                            width: 60,
                            height: 60,
                            margin: const pw.EdgeInsets.only(right: 10),
                            child: pw.Image(logoImage),
                          ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              companyName.toTamilPdf,
                              style: pw.TextStyle(font: fontBold, fontSize: 24),
                            ),
                            if (companyAddress.isNotEmpty)
                              pw.Text(
                                companyAddress.toTamilPdf,
                                style: pw.TextStyle(font: font, fontSize: 10),
                              ),
                            if (companyMobile.isNotEmpty)
                              pw.Text(
                                'Mobile: $companyMobile',
                                style: pw.TextStyle(font: font, fontSize: 10),
                              ),
                          ],
                        ),
                      ],
                    ),
                    pw.Text(
                      title,
                      style: pw.TextStyle(font: font, fontSize: 18),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                        pw.Text('To:', style: pw.TextStyle(font: fontBold)),
                        pw.Text(
                          customer.name.toTamilPdf,
                          style: pw.TextStyle(font: font),
                        ),
                        pw.Text(
                          customer.mobile ?? '',
                          style: pw.TextStyle(font: font),
                        ),
                    ],
                  ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Date: ${txn.date.toString().split(' ')[0]}',
                          style: pw.TextStyle(font: font),
                        ),
                        pw.Text(
                          'No: ${txn.txnNumber}',
                          style: pw.TextStyle(font: font),
                        ),
                      if (txn.type == 'INVOICE')
                        pw.Text(
                          'Status: ${txn.status}',
                          style: pw.TextStyle(
                            font: fontBold,
                            color: txn.status == 'PAID'
                                ? PdfColors.green
                                : PdfColors.red,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Table
              pw.TableHelper.fromTextArray(
                context: context,
                border: null,
                headerStyle: pw.TextStyle(
                  font: fontBold,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: pw.TextStyle(font: font),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                  headers: <String>['Item', 'Qty', 'Rate', 'Amount'],
                  data:
                      txn.items
                          ?.map(
                            (item) => [
                              item.itemName.toTamilPdf,
                              item.qty.toString(),
                              item.rate.toString(),
                              item.amount.toStringAsFixed(2),
                            ],
                          )
                          .toList() ??
                      [],
              ),
              pw.Divider(),

              // Sums
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Total: ${txn.totalAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(font: fontBold, fontSize: 14),
                    ),
                    if (txn.type == 'INVOICE') ...[
                      pw.Text(
                        'Paid: ${txn.paidAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.Text(
                        'Balance: ${txn.balanceAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 14,
                          color: PdfColors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // UPI QR Code Section
              if (prefs.getString(AppConstants.keyUpiId) != null &&
                  prefs.getString(AppConstants.keyUpiId)!.isNotEmpty)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Scan to Pay / பணம் செலுத்த ஸ்கேன் செய்யவும்'.toTamilPdf,
                          style: pw.TextStyle(font: fontBold, fontSize: 10),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Container(
                          width: 100,
                          height: 100,
                          child: pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data:
                                'upi://pay?pa=${prefs.getString(AppConstants.keyUpiId)}&pn=${prefs.getString(AppConstants.keyMerchantName) ?? companyName}&am=${txn.balanceAmount}&cu=INR',
                            width: 100,
                            height: 100,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        if (txn.balanceAmount > 0)
                          pw.Text(
                            'Please pay ₹${txn.balanceAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(font: font, fontSize: 10),
                          ),
                      ],
                    ),
                  ],
                ),

              pw.SizedBox(height: 40),
              if (terms.isNotEmpty) ...[
                pw.Text(
                  'Terms & Conditions:',
                  style: pw.TextStyle(font: fontBold, fontSize: 12),
                ),
                pw.Text(
                  terms.toTamilPdf,
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
                pw.SizedBox(height: 20),
              ],
              pw.Text(
                'Thank you for your business!'.toTamilPdf,
                style: pw.TextStyle(font: font),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  static Future<void> generateAndPrint(
    TransactionModel txn,
    Customer customer,
    String title,
  ) async {
    final pdf = await _buildDocument(txn, customer, title);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${txn.txnNumber}.pdf',
    );
  }

  static Future<List<int>> generatePdfBytes(
    TransactionModel txn,
    Customer customer,
    String title,
  ) async {
    final pdf = await _buildDocument(txn, customer, title);
    return await pdf.save();
  }
}
