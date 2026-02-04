import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/utils/image_url_helper.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/services/company_config_service.dart';

class ReceiptVoucherPdf {
  ReceiptVoucherPdf._();

  static Future<Uint8List> generate(Map<String, dynamic> data) async {
    final doc = pw.Document();
    final currency = NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 2);
    final dateFmt = DateFormat('dd-MMM-yyyy');

    final buyer = data['buyer'] as Map<String, dynamic>?;
    final receivedBy = data['received_by'] as Map<String, dynamic>?;
    
    // Try to load company logo
    late pw.MemoryImage companyLogo;
    var _companyLogoLoadedFromApi = false;
    try {
      final logoUrl = await CompanyConfigService.getLogoUrl();
      if (logoUrl != null && logoUrl.isNotEmpty) {
        final lower = logoUrl.toLowerCase();
        if (!lower.endsWith('.svg')) {
          final fixedUrl = ImageUrlHelper.fixUrl(logoUrl);
          final response = await http.get(Uri.parse(fixedUrl));
          if (response.statusCode == 200) {
            companyLogo = pw.MemoryImage(response.bodyBytes);
            _companyLogoLoadedFromApi = true;
          }
        }
      }
    } catch (_) {}

    if (!_companyLogoLoadedFromApi) {
      try {
        final companyLogoData = await rootBundle.load('assets/images/secureism_logo.png');
        companyLogo = pw.MemoryImage(companyLogoData.buffer.asUint8List());
      } catch (_) {
        final companyLogoData = await rootBundle.load('assets/images/tax-bridge-logo.png');
        companyLogo = pw.MemoryImage(companyLogoData.buffer.asUint8List());
      }
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.copyWith(
          height: 16.5 * PdfPageFormat.cm,
        ),
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Container(
            height: double.infinity,
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'SECUREISM PVT LTD',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 24,
                                color: PdfColor.fromInt(0xFF2C3E50),
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text('F3 Center of Technology, Zaraj Society, Islamabad Pakistan', style: const pw.TextStyle(fontSize: 9)),
                            pw.Text('NTN: 8923980 | Reg No: 0119999', style: const pw.TextStyle(fontSize: 9)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.grey),
                                color: PdfColors.grey200,
                              ),
                              child: pw.Text(
                                'RECEIPT VOUCHER',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              'No: ${data['payment_no'] ?? '-'}',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                            ),
                            pw.Text(
                              'Date: ${data['payment_date'] != null ? dateFmt.format(DateTime.parse(data['payment_date'])) : '-'}',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 10),
                    pw.Divider(thickness: 1.5),
                    pw.SizedBox(height: 25),

                    // Main Content with Amount Box
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Column(
                            children: [
                              // Received From
                              pw.Row(
                                children: [
                                  pw.Text('Received From:  ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                                  pw.Expanded(
                                    child: pw.Container(
                                      padding: const pw.EdgeInsets.only(bottom: 2),
                                      decoration: const pw.BoxDecoration(
                                        border: pw.Border(bottom: pw.BorderSide(style: pw.BorderStyle.dotted)),
                                      ),
                                      child: pw.Text(buyer?['byr_name'] ?? '-', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 15),
                              // Sum of
                              pw.Row(
                                children: [
                                  pw.Text('The Sum of:  ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                                  pw.Expanded(
                                    child: pw.Container(
                                      padding: const pw.EdgeInsets.only(bottom: 2),
                                      decoration: const pw.BoxDecoration(
                                        border: pw.Border(bottom: pw.BorderSide(style: pw.BorderStyle.dotted)),
                                      ),
                                      child: pw.Text(
                                        _numberToWords(double.tryParse(data['payment_amount']?.toString() ?? '0') ?? 0),
                                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        // Amount Box
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColor.fromInt(0xFF2C3E50), width: 2),
                            color: PdfColors.white,
                          ),
                          child: pw.Text(
                            currency.format(double.tryParse(data['payment_amount']?.toString() ?? '0') ?? 0),
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 30),

                    // Payment Mode Border box
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Payment Mode:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.SizedBox(height: 8),
                          pw.Row(
                            children: [
                              _checkbox('Cash', data['payment_method'] == 'cash'),
                              pw.SizedBox(width: 20),
                              _checkbox('Cheque', data['payment_method'] == 'cheque'),
                              pw.SizedBox(width: 20),
                              _checkbox('Bank Transfer', data['payment_method'] == 'bank_transfer'),
                              pw.SizedBox(width: 20),
                              _checkbox('Online', data['payment_method'] == 'online'),
                            ],
                          ),
                          pw.SizedBox(height: 12),
                          pw.Row(
                            children: [
                              pw.Text('Bank: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                              pw.Text(data['bank_name'] ?? '-', style: const pw.TextStyle(fontSize: 9)),
                              pw.SizedBox(width: 25),
                              pw.Text('Cheque No: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                              pw.Text(data['cheque_no'] ?? '-', style: const pw.TextStyle(fontSize: 9)),
                              pw.SizedBox(width: 25),
                              pw.Text('Cheque Date: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                              pw.Text(
                                data['cheque_date'] != null ? dateFmt.format(DateTime.parse(data['cheque_date'])) : '-',
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.Column(
                  children: [
                    // Bottom Signature Section
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          children: [
                            pw.Container(
                              width: 200,
                              decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide())),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(receivedBy?['name'] ?? '-', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                            pw.Text('Received By', style: const pw.TextStyle(fontSize: 9)),
                          ],
                        ),
                        pw.Column(
                          children: [
                            pw.Container(
                              width: 200,
                              decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide())),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 9)),
                          ],
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 15),

                    pw.Center(
                      child: pw.Text(
                        'This is a computer generated receipt.',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _checkbox(String label, bool checked) {
    return pw.Row(
      children: [
        pw.Container(
          width: 12,
          height: 12,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black),
            color: checked ? PdfColors.black : null,
          ),
          child: checked ? pw.Center(child: pw.Icon(const pw.IconData(0xe5ca), color: PdfColors.white, size: 10)) : null,
        ),
        pw.SizedBox(width: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static String _numberToWords(double amount) {
    if (amount == 0) return 'Zero Rupees Only';

    final int integerPart = amount.toInt();
    final int paisaPart = ((amount - integerPart) * 100).round();

    String result = _convert(integerPart) + ' Rupees';
    if (paisaPart > 0) {
      result += ' and ' + _convert(paisaPart) + ' Paisa';
    }
    return result + ' Only';
  }

  static String _convert(int n) {
    if (n < 0) return 'minus ' + _convert(-n);
    if (n <= 19) return _units[n];
    if (n <= 99) return _tens[n ~/ 10] + (n % 10 != 0 ? ' ' + _units[n % 10] : '');
    if (n <= 999) return _units[n ~/ 100] + ' Hundred' + (n % 100 != 0 ? ' and ' + _convert(n % 100) : '');
    if (n <= 99999) return _convert(n ~/ 1000) + ' Thousand' + (n % 1000 != 0 ? ' ' + _convert(n % 1000) : '');
    if (n <= 9999999) return _convert(n ~/ 100000) + ' Lakh' + (n % 100000 != 0 ? ' ' + _convert(n % 100000) : '');
    return _convert(n ~/ 10000000) + ' Crore' + (n % 10000000 != 0 ? ' ' + _convert(n % 10000000) : '');
  }

  static const _units = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen'
  ];

  static const _tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];
}
