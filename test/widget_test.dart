import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanly/app.dart';
import 'package:scanly/core/database/app_database.dart';
import 'package:scanly/core/providers.dart';

void main() {
  testWidgets('empty library shows empty state and Scan button',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const ScanlyApp(),
      ),
    );
    // Drift streams use real async work, so let it run outside fake time.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();

    expect(find.text('No documents yet'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);

    // Tear down so no drift timers are left pending.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
