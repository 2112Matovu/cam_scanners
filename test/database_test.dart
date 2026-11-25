import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanly/core/database/app_database.dart';
import 'package:scanly/core/storage/document_storage.dart';

DocumentsCompanion _doc(String id, String title, DateTime at,
        {String? text}) =>
    DocumentsCompanion.insert(
      id: id,
      title: title,
      pageCount: 1,
      pdfPath: '$id/doc.pdf',
      thumbnailPath: '$id/thumb.jpg',
      createdAt: at,
      extractedText: Value(text),
    );

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('lists newest first', () async {
    await db.insertDocument(_doc('a', 'Old', DateTime(2026, 1, 1)));
    await db.insertDocument(_doc('b', 'New', DateTime(2026, 6, 1)));
    final list = await db.watchDocuments().first;
    expect(list.map((d) => d.id), ['b', 'a']);
  });

  test('search matches title and extracted text', () async {
    await db.insertDocument(_doc('a', 'Kampala Hardware invoice', DateTime(2026, 1, 1)));
    await db.insertDocument(
        _doc('b', 'Scan 2', DateTime(2026, 2, 1), text: 'Total UGX 45,000'));
    expect((await db.watchDocuments(query: 'hardware').first).single.id, 'a');
    expect((await db.watchDocuments(query: 'UGX').first).single.id, 'b');
    expect(await db.watchDocuments(query: 'nothing').first, isEmpty);
  });

  test('rename and delete', () async {
    await db.insertDocument(_doc('a', 'Before', DateTime(2026, 1, 1)));
    await db.renameDocument('a', 'After');
    expect((await db.watchDocument('a').first)!.title, 'After');
    await db.deleteDocument('a');
    expect(await db.watchDocument('a').first, isNull);
  });

  test('new documents default to local status', () async {
    await db.insertDocument(_doc('a', 'x', DateTime(2026, 1, 1)));
    expect((await db.watchDocument('a').first)!.status, 'local');
  });

  group('sanitizeFileName', () {
    test('removes illegal characters and spaces', () {
      expect(sanitizeFileName('Invoice: Kampala/Hardware?'),
          'Invoice_Kampala_Hardware');
    });
    test('falls back when empty', () {
      expect(sanitizeFileName('???'), 'document');
    });
    test('caps length', () {
      expect(sanitizeFileName('a' * 200).length, 60);
    });
  });
}
