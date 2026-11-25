import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../pdf/pdf_builder.dart';

/// Result of saving a scan: relative paths + page count.
class SavedScan {
  const SavedScan({
    required this.pdfPath,
    required this.thumbnailPath,
    required this.pageCount,
  });
  final String pdfPath;
  final String thumbnailPath;
  final int pageCount;
}

/// Keeps every document in `<app documents>/scans/<id>/`:
///   page_1.jpg ... page_N.jpg  (compressed pages, reused for AI upload later)
///   doc.pdf, thumb.jpg
class DocumentStorage {
  /// Page images are scaled so both sides are at least this many px (short
  /// side ~1150 gives a ~1600px long edge on A4). Keeps PDFs small and
  /// uploads cheap on expensive mobile data.
  static const int pageMinSide = 1150;
  static const int jpegQuality = 80;
  static const int thumbMinSide = 360;

  Future<Directory> _root() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'scans'));
    await dir.create(recursive: true);
    return dir;
  }

  /// Turns a stored relative path into an absolute one.
  Future<String> resolve(String relativePath) async =>
      p.join((await _root()).path, relativePath);

  String pageRelativePath(String id, int pageNumber) =>
      p.join(id, 'page_$pageNumber.jpg');

  Future<SavedScan> save({
    required String id,
    required List<String> sourceImages,
  }) async {
    final root = await _root();
    final dir = Directory(p.join(root.path, id));
    await dir.create(recursive: true);

    try {
      final pages = <String>[];
      for (var i = 0; i < sourceImages.length; i++) {
        final target = p.join(dir.path, 'page_${i + 1}.jpg');
        await _compress(sourceImages[i], target, pageMinSide, jpegQuality);
        pages.add(target);
      }

      final pdfFile = p.join(dir.path, 'doc.pdf');
      await buildPdf(imagePaths: pages, outputPath: pdfFile);

      final thumb = p.join(dir.path, 'thumb.jpg');
      await _compress(pages.first, thumb, thumbMinSide, 70);

      return SavedScan(
        pdfPath: p.join(id, 'doc.pdf'),
        thumbnailPath: p.join(id, 'thumb.jpg'),
        pageCount: pages.length,
      );
    } catch (_) {
      // Do not leave half-written folders behind.
      if (await dir.exists()) await dir.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> deleteDocument(String id) async {
    final dir = Directory(p.join((await _root()).path, id));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// Copies the PDF to a temp file with a friendly name for sharing.
  Future<String> pdfForSharing({
    required String pdfRelativePath,
    required String title,
    required DateTime createdAt,
  }) async {
    final src = await resolve(pdfRelativePath);
    final tmp = await getTemporaryDirectory();
    final name = '${sanitizeFileName(title)}_${_ymd(createdAt)}.pdf';
    final out = p.join(tmp.path, name);
    await File(src).copy(out);
    return out;
  }

  Future<void> _compress(
    String source,
    String target,
    int minSide,
    int quality,
  ) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      source,
      target,
      minWidth: minSide,
      minHeight: minSide,
      quality: quality,
      format: CompressFormat.jpeg,
      keepExif: false, // strips EXIF (location etc.) for privacy
    );
    if (result == null) {
      throw FileSystemException('Could not compress image', source);
    }
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Makes a title safe to use as a file name.
/// Example: "Invoice: Kampala/Hardware?" becomes "Invoice_Kampala_Hardware".
String sanitizeFileName(String input) {
  final cleaned = input
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  if (cleaned.isEmpty) return 'document';
  return cleaned.length > 60 ? cleaned.substring(0, 60) : cleaned;
}
