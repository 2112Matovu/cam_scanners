import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:scanly/l10n/gen/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';

/// Shows a saved document: PDF is ready instantly, with share, rename, delete.
class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({super.key, required this.id});
  final String id;

  Future<void> _share(BuildContext context, WidgetRef ref, Document doc) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await ref.read(documentStorageProvider).pdfForSharing(
            pdfRelativePath: doc.pdfPath,
            title: doc.title,
            createdAt: doc.createdAt,
          );
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], subject: doc.title),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
    }
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, Document doc) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: doc.title);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.renameTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.documentName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName != null && newName.isNotEmpty) {
      await ref.read(databaseProvider).renameDocument(doc.id, newName);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Document doc) async {
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteTitle),
        content: Text(l10n.deleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(documentStorageProvider).deleteDocument(doc.id);
    await ref.read(databaseProvider).deleteDocument(doc.id);
    router.go('/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(documentProvider(id));

    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.documentNotFound)),
      ),
      data: (doc) {
        if (doc == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.documentNotFound)),
          );
        }
        final storage = ref.read(documentStorageProvider);
        return Scaffold(
          appBar: AppBar(
            // Back goes to the library even after the review screen was replaced.
            leading: BackButton(onPressed: () => context.go('/')),
            title: Text(doc.title, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n.rename,
                onPressed: () => _rename(context, ref, doc),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.delete,
                onPressed: () => _delete(context, ref, doc),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l10n.pdfReady)),
                    Text(l10n.pagesCount(doc.pageCount)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: doc.pageCount,
                  itemBuilder: (context, i) {
                    return FutureBuilder<String>(
                      future: storage.resolve(
                        storage.pageRelativePath(doc.id, i + 1),
                      ),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const SizedBox(height: 200);
                        }
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Image.file(
                            File(snap.data!),
                            fit: BoxFit.fitWidth,
                            cacheWidth: 800,
                            semanticLabel: l10n.pageLabel(i + 1),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _share(context, ref, doc),
                          icon: const Icon(Icons.share_outlined),
                          label: Text(l10n.sharePdf),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: null, // Phase 2
                          icon: const Icon(Icons.auto_awesome_outlined),
                          label: Text(l10n.convertSoon),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
