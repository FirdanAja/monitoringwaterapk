import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/sensor_data.dart';

class PdfService {
  static Future<File> generateMonthlyReport(MonthlyReport report) async {
    final pdf = pw.Document();

    // Load logo if exists
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/icons/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // Ignore if logo not found
    }

    final headers = ['Tanggal', 'pH', 'Turbidity (NTU)', 'Suhu (°C)', 'Skor', 'Status'];
    
    final data = report.dailyData.map((d) => [
      DateFormat('dd/MM/yyyy HH:mm').format(d.timestamp),
      d.ph.toStringAsFixed(2),
      d.turbidity.toStringAsFixed(1),
      d.temperature.toStringAsFixed(1),
      d.qualityScore.toStringAsFixed(1),
      d.status.label,
    ]).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('TirtaSmart Monitoring Report',
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Laporan Kualitas Air Bulanan',
                      style: const pw.TextStyle(fontSize: 16)),
                  pw.SizedBox(height: 8),
                  pw.Text('Periode: ${DateFormat('MMMM yyyy').format(DateTime(report.year, report.month))}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              if (logoImage != null)
                pw.Image(logoImage, width: 60, height: 60),
            ],
          ),
          pw.Divider(thickness: 2, height: 32),

          // Summary Section
          pw.Text('Ringkasan Statistik',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatBox('Rata-rata pH', report.avgPh.toStringAsFixed(2)),
              _buildStatBox('Rata-rata NTU', report.avgTurbidity.toStringAsFixed(1)),
              _buildStatBox('Rata-rata Suhu', report.avgTemperature.toStringAsFixed(1)),
              _buildStatBox('Skor Kualitas', report.avgQualityScore.toStringAsFixed(1)),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatBox('Total Data', report.totalReadings.toString()),
              _buildStatBox('Status Umum', report.overallStatus.label),
            ],
          ),
          pw.SizedBox(height: 32),

          // Table Section
          pw.Text('Detail Data Harian',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            border: pw.TableBorder.all(width: 1, color: PdfColors.grey400),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellHeight: 25,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.center,
            },
          ),
          
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              'Dicetak pada: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Laporan_Kualitas_Air_${DateFormat('MMMM_yyyy').format(DateTime(report.year, report.month))}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildStatBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
