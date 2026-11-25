import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database/app_database.dart';
import 'storage/document_storage.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final documentStorageProvider = Provider<DocumentStorage>(
  (ref) => DocumentStorage(),
);

/// Current search text on the library screen.
class SearchQuery extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final searchQueryProvider =
    NotifierProvider<SearchQuery, String>(SearchQuery.new);

final documentsProvider = StreamProvider<List<Document>>((ref) {
  final query = ref.watch(searchQueryProvider);
  return ref.watch(databaseProvider).watchDocuments(query: query);
});

final documentProvider = StreamProvider.family<Document?, String>(
  (ref, id) => ref.watch(databaseProvider).watchDocument(id),
);
