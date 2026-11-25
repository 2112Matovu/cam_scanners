import 'package:cunning_document_scanner/cunning_document_scanner.dart';

/// Thin wrapper around the native document scanner (ML Kit on Android,
/// VisionKit on iOS). The native UI does edge detection, crop, perspective
/// fix and enhancement, and lets the user import from the gallery.
class ScanService {
  const ScanService();

  /// Returns file paths of scanned pages, or an empty list if cancelled.
  Future<List<String>> scan({int maxPages = 20}) async {
    final result = await CunningDocumentScanner.scanDocuments(
      noOfPages: maxPages,
      scannerSource: ScannerSource.cameraAndGallery,
    );
    return result?.images ?? const <String>[];
  }
}
