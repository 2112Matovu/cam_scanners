import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds an A4 PDF from page images, one image per page, fitted to the page.
/// Runs in a background isolate so the UI never freezes on a budget phone.
Future<void> buildPdf({
  required List<String> imagePaths,
  required String outputPath,
}) {
  return compute(
    _buildPdfSync,
    _PdfJob(imagePaths: imagePaths, outputPath: outputPath),
  );
}

class _PdfJob {
  const _PdfJob({required this.imagePaths, required this.outputPath});
  final List<String> imagePaths;
  final String outputPath;
}

Future<void> _buildPdfSync(_PdfJob job) async {
  final doc = pw.Document(compress: true);
  for (final path in job.imagePaths) {
    final image = pw.MemoryImage(await File(path).readAsBytes());
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ),
    );
  }
  await File(job.outputPath).writeAsBytes(await doc.save());
}
