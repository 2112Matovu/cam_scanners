import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/library/document_detail_screen.dart';
import '../features/library/library_screen.dart';
import '../features/scan/review_pages_screen.dart';

/// App-wide router. Later phases add convert, review/edit, settings routes.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) => ReviewPagesScreen(
          initialPages: (state.extra as List<String>?) ?? const <String>[],
        ),
      ),
      GoRoute(
        path: '/doc/:id',
        builder: (context, state) =>
            DocumentDetailScreen(id: state.pathParameters['id']!),
      ),
    ],
  );
});
