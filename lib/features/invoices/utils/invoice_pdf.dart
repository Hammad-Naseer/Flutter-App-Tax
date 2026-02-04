import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/services/company_config_service.dart';
import '../../../data/models/invoice_model.dart';

class InvoicePdf {
  InvoicePdf._();

  static Future<Uint8List> generate(InvoiceModel invoice) async {
    final doc = pw.Document();
    final currency = NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 2);
    final dateFmt = DateFormat('dd MMM yyyy');

    final details = invoice.details ?? [];
    final seller = invoice.seller;
    final buyer = invoice.buyer;

    // Try to load company logo from API, fallback to asset
    late pw.MemoryImage companyLogo;
    var _companyLogoLoadedFromApi = false;
    try {
      final logoUrl = await CompanyConfigService.getLogoUrl();
      if (logoUrl != null && logoUrl.isNotEmpty) {
        // pdf package CANNOT decode SVG images; skip SVG URLs and use asset fallback instead
        final lower = logoUrl.toLowerCase();
        if (lower.endsWith('.svg')) {
          print('⚠️ Company logo URL is SVG, skipping network load and using asset fallback');
        } else {
          final fixedUrl = ImageUrlHelper.fixUrl(logoUrl);
          print('📸 Loading company logo from: $fixedUrl');
          
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          final headers = {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          };

          final response = await http.get(Uri.parse(fixedUrl), headers: headers);
          if (response.statusCode == 200) {
            companyLogo = pw.MemoryImage(response.bodyBytes);
            _companyLogoLoadedFromApi = true;
            print('✅ Company logo loaded from API');
          } else {
            print('⚠️ Company logo HTTP error: ${response.statusCode}');
          }
        }
      }
    } catch (e) {
      print('⚠️ Failed to load company logo from API: $e');
    }

    // Fallback to asset logo if API logo not available or failed (including SVG case)
    if (!_companyLogoLoadedFromApi) {
      try {
        // Primary fallback: Secureism logo
        final companyLogoData = await rootBundle.load('assets/images/secureism_logo.png');
        companyLogo = pw.MemoryImage(companyLogoData.buffer.asUint8List());
        print('📸 Using fallback company logo from secureism_logo.png');
      } catch (e) {
        print('⚠️ Failed to load secureism_logo.png: $e');
        try {
          // Secondary fallback: Tax Bridge logo
          final companyLogoData = await rootBundle.load('assets/images/tax-bridge-logo.png');
          companyLogo = pw.MemoryImage(companyLogoData.buffer.asUint8List());
          print('📸 Using fallback company logo from tax-bridge-logo.png');
        } catch (e2) {
          print('❌ Failed to load all fallback company logos: $e2');
          rethrow;
        }
      }
    }

    final fbrLogoData = await rootBundle.load('assets/images/fbr-digital-invoicing-logo.png');
    final fbrLogo = pw.MemoryImage(fbrLogoData.buffer.asUint8List());

    // Declaring qrImage as nullable pw.MemoryImage
    pw.MemoryImage? qrImage;

    // Check if the invoice's qrCode is not null and not empty
    if (invoice.qrCode != null && invoice.qrCode!.isNotEmpty) {
      final rawQr = invoice.qrCode!;
      // Try multiple strategies to load the QR code
      print('📸 ═══════════════════════════════════════');
      print('📸 Starting QR code load attempts');
      // Apply fixUrl to handle Android emulator localhost/127.0.0.1 issues
      final fixedRawQr = ImageUrlHelper.fixUrl(rawQr);
      print('📸 Fixed Raw QR value: $fixedRawQr');
      
      // Strategy 1: Try as-is if it's a full URL (S3 signed URL)
      if (fixedRawQr.startsWith('http://') || fixedRawQr.startsWith('https://')) {
        print('📸 Strategy 1: Trying full URL without auth headers');
        try {
          final response = await http.get(
            Uri.parse(fixedRawQr),
            headers: {'Accept': 'image/*'},
          ).timeout(const Duration(seconds: 10));
          
          print('📸 Strategy 1 - Status: ${response.statusCode}');
          
          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            qrImage = pw.MemoryImage(response.bodyBytes);
            print('✅ Strategy 1 SUCCESS - QR loaded (${response.bodyBytes.length} bytes)');
          } else {
            print('❌ Strategy 1 FAILED - Status ${response.statusCode}, body length: ${response.bodyBytes.length}');
          }
        } catch (e) {
          print('❌ Strategy 1 EXCEPTION: $e');
        }
      }
      
      // Strategy 2: If Strategy 1 failed and it's a full URL, try with Bearer token
      if (qrImage == null && (fixedRawQr.startsWith('http://') || fixedRawQr.startsWith('https://'))) {
        print('📸 Strategy 2: Trying full URL WITH Bearer token');
        try {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          
          final headers = <String, String>{
            'Accept': 'image/*',
            if (token != null) 'Authorization': 'Bearer $token',
          };
          
          print('📸 Strategy 2 - Using auth: ${token != null}');
          
          final response = await http.get(
            Uri.parse(fixedRawQr),
            headers: headers,
          ).timeout(const Duration(seconds: 10));
          
          print('📸 Strategy 2 - Status: ${response.statusCode}');
          
          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            qrImage = pw.MemoryImage(response.bodyBytes);
            print('✅ Strategy 2 SUCCESS - QR loaded (${response.bodyBytes.length} bytes)');
          } else {
            print('❌ Strategy 2 FAILED - Status ${response.statusCode}');
          }
        } catch (e) {
          print('❌ Strategy 2 EXCEPTION: $e');
        }
      }
      
      // Strategy 3: Try building storage URL from relative path
      if (qrImage == null && !rawQr.startsWith('http')) {
        print('📸 Strategy 3: Building storage URL from relative path');
        try {
          final storageUrl = ImageUrlHelper.buildStorageUrl(rawQr, ApiEndpoints.baseUrl);
          print('📸 Strategy 3 - Built URL: $storageUrl');
          
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          
          final headers = <String, String>{
            'Accept': 'image/*',
            if (token != null) 'Authorization': 'Bearer $token',
          };
          
          final response = await http.get(
            Uri.parse(storageUrl),
            headers: headers,
          ).timeout(const Duration(seconds: 10));
          
          print('📸 Strategy 3 - Status: ${response.statusCode}');
          
          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            qrImage = pw.MemoryImage(response.bodyBytes);
            print('✅ Strategy 3 SUCCESS - QR loaded (${response.bodyBytes.length} bytes)');
          } else {
            print('❌ Strategy 3 FAILED - Status ${response.statusCode}');
            if (response.statusCode != 200) {
              print('❌ Response preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
            }
          }
        } catch (e) {
          print('❌ Strategy 3 EXCEPTION: $e');
        }
      }
      
      if (qrImage == null) {
        print('❌ ALL STRATEGIES FAILED - QR code will not be displayed');
        print('📸 ═══════════════════════════════════════');
      } else {
        print('✅ QR CODE LOADED SUCCESSFULLY');
        print('📸 ═══════════════════════════════════════');
      }
    }

    // Calculate totals
    double subtotal = invoice.totalAmountExcludingTax ?? 0;
    double salesTax = invoice.totalSalesTax ?? 0;
    double grandTotal = invoice.totalAmount ?? subtotal + salesTax;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        header: (context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        height: 40,
                        width: 120,
                        child: pw.Image(companyLogo, fit: pw.BoxFit.contain),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        seller?.busName ?? 'Secureism Pvt Ltd',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        seller?.busName ?? 'Tax Bridge',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(seller?.busAddress ?? '', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right),
                      if (seller?.busRegNum != null)
                        pw.Text('Reg No: ${seller?.busRegNum}', style: const pw.TextStyle(fontSize: 10)),
                      if (seller?.busNtnCnic != null)
                        pw.Text('NTN: ${seller?.busNtnCnic}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
            ],
          );
        },

        build: (context) {
          return [
            // ═══════════════════════════════════════════════════════════
            // TITLE
            // ═══════════════════════════════════════════════════════════
            pw.Center(
              child: pw.Text(
                'SALE TAX INVOICE',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
            ),

            pw.SizedBox(height: 10),

            // ═══════════════════════════════════════════════════════════
            // SELLER & INVOICE INFO
            // ═══════════════════════════════════════════════════════════
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left: Buyer Info (Customer)
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        buyer?.byrName ?? 'Walking Customer',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        buyer?.byrAddress ?? '',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                // Right: Invoice Details
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _infoRow('Invoice Date:', invoice.invoiceDate != null ? dateFmt.format(invoice.invoiceDate!) : '—'),
                    _infoRow('Invoice #:', invoice.invoiceNo ?? 'INV-${invoice.invoiceId.toString().padLeft(6, '0')}'),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 10),

            // ═══════════════════════════════════════════════════════════
            // ITEMS TABLE
            // ═══════════════════════════════════════════════════════════
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 1.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3.5),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(1.8),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1.8),
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _tableHeader('Description'),
                    _tableHeader('Quantity'),
                    _tableHeader('Unit Price'),
                    _tableHeader('Tax'),
                    _tableHeader('Amount'),
                  ],
                ),
                // Data Rows
                for (final d in details)
                  pw.TableRow(
                    children: [
                      _tableCell(d.item?.itemDescription ?? '-', align: pw.TextAlign.left),
                      _tableCell((d.quantity ?? 0).toString(), align: pw.TextAlign.center),
                      _tableCell(NumberFormat('#,##0.00').format(d.item?.itemPrice ?? 0), align: pw.TextAlign.right),
                      _tableCell('${d.item?.itemTaxRate ?? '0'}%', align: pw.TextAlign.center),
                      _tableCell(NumberFormat('#,##0.00').format(_lineAmount(d)), align: pw.TextAlign.right),
                    ],
                  ),
              ],
            ),

            pw.SizedBox(height: 10),

            // ═══════════════════════════════════════════════════════════
            // DUE DATE & TOTALS
            // ═══════════════════════════════════════════════════════════
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left: Due Date
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Due Date: ${invoice.dueDate != null ? dateFmt.format(invoice.dueDate!) : '—'}',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                // Right: Totals
                pw.Container(
                  width: 200,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      _totalRow('Subtotal', NumberFormat('#,##0.00').format(subtotal)),
                      _totalRow('Sales Tax', NumberFormat('#,##0.00').format(salesTax)),
                      pw.Divider(color: PdfColors.black, thickness: 1.5),
                      _totalRow('Grand Total', NumberFormat('#,##0.00').format(grandTotal), bold: true),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // ═══════════════════════════════════════════════════════════
            // BANK & FBR SECTION (at the end of items)
            // ═══════════════════════════════════════════════════════════
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Left: Bank Details
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Bank Details', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    if (seller?.busAccountTitle != null)
                      pw.Text('Title: ${seller?.busAccountTitle}', style: const pw.TextStyle(fontSize: 10)),
                    if (seller?.busAccountNumber != null)
                      pw.Text('Account No: ${seller?.busAccountNumber}', style: const pw.TextStyle(fontSize: 10)),
                    if (seller?.busIBAN != null)
                      pw.Text('IBAN: ${seller?.busIBAN}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('SWIFT CODE: ${seller?.busSwiftCode ?? '-'}', style: const pw.TextStyle(fontSize: 10)),
                    if (seller?.busAccBranchCode != null)
                      pw.Text('Branch CODE: ${seller?.busAccBranchCode}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                // FBR Logo and QR Code
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                      pw.Container(
                        width: 60,
                        height: 40,
                        child: pw.Image(fbrLogo, fit: pw.BoxFit.contain),
                      ),
                      pw.SizedBox(width: 10),
                      if (qrImage != null)
                        pw.Container(
                          width: 65,
                          height: 65,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.black, width: 1),
                          ),
                          child: pw.Image(qrImage!, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.Container(
                          width: 65,
                          height: 65,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.black, width: 1),
                          ),
                          child: pw.Center(
                            child: pw.Text('QR', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ),
                        ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 12),

            // FBR Invoice Number
            if (invoice.fbrInvoiceNumber != null)
              pw.Center(
                child: pw.Text(
                  'FBR Invoice #: ${invoice.fbrInvoiceNumber}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),

            pw.SizedBox(height: 15),

            // ═══════════════════════════════════════════════════════════
            // PAYMENT ADVICE SECTION
            // ═══════════════════════════════════════════════════════════
            pw.Container(
              height: 1,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black, width: 1, style: pw.BorderStyle.dashed),
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey700, style: pw.BorderStyle.dashed, width: 1),
              ),
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text(
                      'PAYMENT ADVICE',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('To: ${seller?.busName ?? 'Secureism Pvt Ltd'}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 2),
                            pw.Text(seller?.busAddress ?? '', style: const pw.TextStyle(fontSize: 10)),
                            if (seller?.busRegNum != null)
                              pw.Text('Reg No: ${seller?.busRegNum}', style: const pw.TextStyle(fontSize: 10)),
                            if (seller?.busNtnCnic != null)
                              pw.Text('NTN: ${seller?.busNtnCnic}', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Customer', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 2),
                            pw.Text(buyer?.byrName ?? 'Walking Customer', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 4),
                            pw.Text('Invoice No.  ${invoice.invoiceNo ?? 'INV-${invoice.invoiceId.toString().padLeft(6, '0')}'}', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text('Amount Due  ${NumberFormat('#,##0.00').format(grandTotal)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                            pw.Text('Due Date  ${invoice.dueDate != null ? dateFmt.format(invoice.dueDate!) : '—'}', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 6),
                            pw.Text('Amount', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text('Enclosed', style: const pw.TextStyle(fontSize: 10)),
                            pw.SizedBox(height: 8),
                            pw.Container(
                              width: 150,
                              height: 30,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.grey600),
                              ),
                              child: pw.Center(
                                child: pw.Text('Enter the amount you are paying above', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Center(
                    child: pw.Text(
                      'Office: ${seller?.busAddress ?? ''}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  // ═══════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        children: [
          pw.Container(
            width: 90,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          ),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _tableCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 11),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static double _lineAmount(InvoiceDetailModel d) {
    final qty = (d.quantity ?? 0).toDouble();
    final price = (d.item?.itemPrice ?? 0).toDouble();
    final base = qty * price;
    final taxRate = double.tryParse(d.item?.itemTaxRate ?? '0') ?? 0;
    final sales = (base * taxRate) / 100;
    return base + sales;
  }
}
