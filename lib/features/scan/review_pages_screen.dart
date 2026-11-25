import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import 'package:material_ui/material_ui.dart';
import 'package:scanly/l10n/gen/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import 'scan_service.dart';

/// Lets the user reorder, delete and add pages, name the document, then
/// builds the PDF on the phone (no internet, no AI cost).
class ReviewPagesScreen extends ConsumerStatefulWidget {
  const ReviewPagesScreen({super.key, required this.initialPages});

  final List<String> initialPages;

  @override
  ConsumerState<ReviewPagesScreen> createState() => _ReviewPagesScreenState();
}

class _ReviewPagesScreenState extends ConsumerState<ReviewPagesScreen> {
  static const int _maxPages = 20;

  late final List<String> _pages = List.of(widget.initialPages);
  final _nameController = TextEditingController();
  bool _saving = false;
  bool _nameInitialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_nameInitialised) {
      final stamp = DateFormat('d MMM yyyy HH:mm').format(DateTime.now());
      _nameController.text =
          AppLocalizations.of(context).defaultScanName(stamp);
      _nameInitialised = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addPages() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final more = await const ScanService()
          .scan(maxPages: _maxPages - _pages.length);
      if (!mounted || more.isEmpty) return;
      setState(() => _pages.addAll(more.take(_maxPages - _pages.length)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.scanFailed)));
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    if (_pages.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.noPagesLeft)));
      return;
    }

    final storage = ref.read(documentStorageProvider);
    final db = ref.read(databaseProvider);
    final id = const Uuid().v4();
    final name = _nameController.text.trim().isEmpty
        ? l10n.defaultScanName(DateFormat('d MMM yyyy').format(DateTime.now()))
        : _nameController.text.trim();

    setState(() => _saving = true);
    try {
      final saved = await storage.save(id: id, sourceImages: _pages);
      await db.insertDocument(
        DocumentsCompanion.insert(
          id: id,
          title: name,
          pageCount: saved.pageCount,
          pdfPath: saved.pdfPath,
          thumbnailPath: saved.thumbnailPath,
          createdAt: DateTime.now(),
          status: const Value('local'),
        ),
      );
      router.go('/doc/$id');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.saveFailed)));
    }
  }

  Future<bool> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.discardTitle),
        content: Text(l10n.discardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.keepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return PopScope(
      canPop: _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final router = GoRouter.of(context);
        if (await _confirmDiscard()) router.go('/');
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.reviewTitle)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _nameController,
                enabled: !_saving,
                decoration: InputDecoration(
                  labelText: l10n.documentName,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.reviewHint, style: theme.textTheme.bodySmall),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _pages.length,
                onReorderItem: (oldIndex, newIndex) {
                  setState(() {
                    _pages.insert(newIndex, _pages.removeAt(oldIndex));
                  });
                },
                itemBuilder: (context, index) {
                  final path = _pages[index];
                  return Card(
                    key: ValueKey('$path#$index'),
                    child: ListTile(
                      // cacheWidth keeps decoded images small on low-RAM phones.
                      leading: Image.file(
                        File(path),
                        width: 48,
                        height: 64,
                        fit: BoxFit.cover,
                        cacheWidth: 150,
                      ),
                      title: Text(l10n.pageLabel(index + 1)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: l10n.removePage,
                        onPressed: _saving
                            ? null
                            : () => setState(() => _pages.removeAt(index)),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving || _pages.length >= _maxPages
                          ? null
                          : _addPages,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(l10n.addPages),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(_saving ? l10n.saving : l10n.savePdf),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
