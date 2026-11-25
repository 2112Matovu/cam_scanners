import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:scanly/l10n/gen/app_localizations.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import '../scan/scan_service.dart';

/// Home screen: searchable list of documents plus the big Scan button.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  Future<void> _scan(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final pages = await const ScanService().scan();
      if (pages.isEmpty) return; // user cancelled
      router.push('/review', extra: pages);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.scanFailed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final docs = ref.watch(documentsProvider);
    final searching = ref.watch(searchQueryProvider).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.libraryTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTooltip,
            onPressed: () {}, // Settings arrive in a later phase.
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: ref.read(searchQueryProvider.notifier).set,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: docs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(l10n.saveFailed)),
              data: (list) {
                if (list.isEmpty) {
                  return _EmptyState(searching: searching);
                }
                // ListView.builder builds rows lazily: cheap on low-RAM phones.
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _DocumentTile(doc: list[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _scan(context),
        icon: const Icon(Icons.camera_alt_outlined),
        label: Text(l10n.scanButton),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searching});
  final bool searching;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searching ? Icons.search_off : Icons.document_scanner_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              searching ? l10n.noResults : l10n.emptyLibraryTitle,
              style: theme.textTheme.titleLarge,
            ),
            if (!searching) ...[
              const SizedBox(height: 8),
              Text(
                l10n.emptyLibraryBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DocumentTile extends ConsumerWidget {
  const _DocumentTile({required this.doc});
  final Document doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final storage = ref.read(documentStorageProvider);
    final date = DateFormat('d MMM yyyy, HH:mm').format(doc.createdAt);

    return ListTile(
      leading: FutureBuilder<String>(
        future: storage.resolve(doc.thumbnailPath),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const SizedBox(width: 48, height: 64);
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              File(snap.data!),
              width: 48,
              height: 64,
              fit: BoxFit.cover,
              cacheWidth: 150,
              errorBuilder: (_, _, _) => const SizedBox(
                width: 48,
                height: 64,
                child: Icon(Icons.description_outlined),
              ),
            ),
          );
        },
      ),
      title: Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('PDF - ${l10n.pagesCount(doc.pageCount)} - $date'),
      onTap: () => context.push('/doc/${doc.id}'),
    );
  }
}
