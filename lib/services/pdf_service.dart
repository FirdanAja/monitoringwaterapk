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

    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/icons/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      // Abaikan jika logo tidak ditemukan
    }

    final headers = ['Tanggal', 'pH', 'Turbidity (NTU)', 'Suhu (°C)', 'Skor', 'Status'];
    
    // Kelompokkan data berdasarkan hari agar tidak terlalu panjang
    Map<String, List<SensorData>> groupedByDay = {};
    for (var d in report.dailyData) {
      String dayKey = DateFormat('yyyy-MM-dd').format(d.timestamp);
      if (!groupedByDay.containsKey(dayKey)) {
        groupedByDay[dayKey] = [];
      }
      groupedByDay[dayKey]!.add(d);
    }

    // Urutkan dari tanggal terlama ke terbaru
    final sortedKeys = groupedByDay.keys.toList()..sort();

    final data = sortedKeys.map((key) {
      final list = groupedByDay[key]!;
      final avgPh = list.map((d) => d.ph).reduce((a, b) => a + b) / list.length;
      final avgTurb = list.map((d) => d.turbidity).reduce((a, b) => a + b) / list.length;
      final avgTemp = list.map((d) => d.temperature).reduce((a, b) => a + b) / list.length;
      final avgScore = list.map((d) => d.qualityScore).reduce((a, b) => a + b) / list.length;
      
      String statusStr = 'Aman';
      if (avgScore < 35 || avgTurb > 25.0) {
        statusStr = 'Bahaya';
      } else if (avgScore < 70 || avgTurb > 5.0) {
        statusStr = 'Waspada';
      }

      return [
        DateFormat('dd/MM/yyyy').format(list.first.timestamp),
        avgPh.toStringAsFixed(2),
        avgTurb.toStringAsFixed(1),
        avgTemp.toStringAsFixed(1),
        avgScore.toStringAsFixed(1),
        statusStr,
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
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

    Directory? directory;
    if (Platform.isAndroid) {
      // Simpan di folder External App (Android/data/com.xxx/files) agar tidak kena Permission Denied
      directory = await getExternalStorageDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    
    // Fallback jika null
    directory ??= await getApplicationDocumentsDirectory();

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
