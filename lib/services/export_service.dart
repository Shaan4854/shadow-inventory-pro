import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import '../utils/app_constants.dart';

class ExportService {
  static Future<void> exportTransactionsToPdf(
    List<Transaction> transactions,
    String title,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        header: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())),
          ],
        ),
        build: (context) => [
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['ID', 'Type', 'Entity', 'Date', 'Amount'],
            data: transactions
                .map((tx) => [
                      tx.id.substring(0, 8).toUpperCase(),
                      tx.type.name.toUpperCase(),
                      tx.entityName,
                      DateFormat('dd/MM/yyyy').format(tx.createdAt),
                      '${AppConstants.currencySymbol}${tx.grandTotal.toStringAsFixed(2)}',
                    ],)
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static Future<void> exportTransactionsToCsv(
    List<Transaction> transactions,
    String fileName,
  ) async {
    List<List<dynamic>> rows = [];
    rows.add(
      [
        'ID',
        'Type',
        'Entity',
        'Date',
        'Amount',
        'Discount',
        'Payment Method',
        'Notes',
      ],
    );

    for (var tx in transactions) {
      rows.add([
        tx.id,
        tx.type.name,
        tx.entityName,
        tx.createdAt.toIso8601String(),
        tx.totalAmount,
        tx.discount,
        tx.paymentMethod,
        tx.notes,
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Exported CSV');
  }

  static Future<void> exportTransactionsToExcel(
    List<Transaction> transactions,
    String fileName,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Transactions'];

    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Type'),
      TextCellValue('Entity'),
      TextCellValue('Date'),
      TextCellValue('Amount'),
      TextCellValue('Discount'),
      TextCellValue('Payment Method'),
      TextCellValue('Notes'),
    ]);

    for (var tx in transactions) {
      sheet.appendRow([
        TextCellValue(tx.id),
        TextCellValue(tx.type.name),
        TextCellValue(tx.entityName),
        TextCellValue(tx.createdAt.toIso8601String()),
        DoubleCellValue(tx.totalAmount),
        DoubleCellValue(tx.discount),
        TextCellValue(tx.paymentMethod),
        TextCellValue(tx.notes),
      ]);
    }

    var bytes = excel.save();
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName.xlsx');
    await file.writeAsBytes(bytes!);
    await Share.shareXFiles([XFile(file.path)], text: 'Exported Excel');
  }
}
