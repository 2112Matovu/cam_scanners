import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// One scanned document. File paths are stored RELATIVE to the app's scans
/// folder so they survive app-data moves (iOS can change the absolute path).
class Documents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get pageCount => integer()();
  TextColumn get pdfPath => text()();
  TextColumn get thumbnailPath => text()();
  DateTimeColumn get createdAt => dateTime()();

  /// Filled by AI conversion in Phase 2; used for library search.
  TextColumn get extractedText => text().nullable()();

  /// local | uploading | queued | processing | ready | failed
  TextColumn get status => text().withDefault(const Constant('local'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Documents])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'scanly'));

  /// For tests: pass an in-memory executor.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  /// Newest first. Matches title or extracted text when [query] is given.
  Stream<List<Document>> watchDocuments({String query = ''}) {
    final select = this.select(documents)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final q = query.trim();
    if (q.isNotEmpty) {
      select.where(
        (t) => t.title.contains(q) | t.extractedText.contains(q),
      );
    }
    return select.watch();
  }

  Stream<Document?> watchDocument(String id) =>
      (select(documents)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<void> insertDocument(DocumentsCompanion doc) =>
      into(documents).insert(doc);

  Future<void> renameDocument(String id, String title) =>
      (update(documents)..where((t) => t.id.equals(id)))
          .write(DocumentsCompanion(title: Value(title)));

  Future<void> deleteDocument(String id) =>
      (delete(documents)..where((t) => t.id.equals(id))).go();
}
