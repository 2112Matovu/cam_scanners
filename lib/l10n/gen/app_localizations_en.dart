// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Scanly';

  @override
  String get libraryTitle => 'My documents';

  @override
  String get emptyLibraryTitle => 'No documents yet';

  @override
  String get emptyLibraryBody =>
      'Tap Scan to capture your first document. It works without internet.';

  @override
  String get noResults => 'Nothing matches your search';

  @override
  String get scanButton => 'Scan';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get searchHint => 'Search documents';

  @override
  String pagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get scanFailed =>
      'Could not open the scanner. Please check camera permission and try again.';

  @override
  String get reviewTitle => 'Review pages';

  @override
  String get reviewHint => 'Drag to reorder. Tap the bin to remove a page.';

  @override
  String get addPages => 'Add pages';

  @override
  String get removePage => 'Remove page';

  @override
  String pageLabel(int number) {
    return 'Page $number';
  }

  @override
  String get documentName => 'Document name';

  @override
  String get savePdf => 'Save as PDF';

  @override
  String get saving => 'Saving your PDF...';

  @override
  String get saveFailed => 'Could not save the document. Please try again.';

  @override
  String get noPagesLeft => 'Add at least one page to save.';

  @override
  String get discardTitle => 'Discard this scan?';

  @override
  String get discardBody => 'The pages you scanned will be lost.';

  @override
  String get discard => 'Discard';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String defaultScanName(String date) {
    return 'Scan $date';
  }

  @override
  String get detailTitle => 'Document';

  @override
  String get sharePdf => 'Share PDF';

  @override
  String get shareFailed => 'Could not share the file.';

  @override
  String get rename => 'Rename';

  @override
  String get renameTitle => 'Rename document';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deleteTitle => 'Delete this document?';

  @override
  String get deleteBody =>
      'The PDF and its pages will be removed from this phone.';

  @override
  String get convertSoon => 'Convert to Word/Excel (coming soon)';

  @override
  String get pdfReady => 'PDF ready - works offline';

  @override
  String get documentNotFound => 'This document no longer exists.';
}
