import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mechanix_music/features/browse_music/presentation/screens/folder_contents_screen.dart';
import 'package:mechanix_music/features/browse_music/presentation/widgets/browse_folder_tile.dart';
import 'package:mechanix_music/features/browse_music/presentation/widgets/folder_contents_screen/folder_audio_tile.dart';
import 'package:mechanix_music/features/browse_music/presentation/widgets/folder_contents_screen/folder_content_body.dart';
import 'package:mechanix_music/features/browse_music/presentation/widgets/folder_contents_screen/selection_header.dart';

import 'test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Browse tab', () {
    testWidgets('full browse flow', (tester) async {
      // ── Launch & open Browse tab ──────────────────────────────────────────
      await TestHelper.launchApp(tester);
      await TestHelper.tapTab(tester, TestHelper.browseTab);
      await TestHelper.pumpUntil(
        tester,
        () => find.byType(BrowseFolderTile).evaluate().isNotEmpty,
        reason: 'browse folder list to appear',
      );

      // --- Quick-access folders ---
      expect(find.text('Browse music folders'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Recents'), findsOneWidget);
      expect(find.text('Downloads'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);

      // ── Open Home folder ──────────────────────────────────────────────────
      await tester.tap(find.text('Home'));
      await TestHelper.pumpUntil(
        tester,
        () => find.byType(FolderContentsScreen).evaluate().isNotEmpty,
        reason: 'folder contents screen to open',
      );
      await TestHelper.pumpUntil(
        tester,
        () => find
            .descendant(
              of: find.byType(FolderContentsScreen),
              matching: find.byType(CircularProgressIndicator),
            )
            .evaluate()
            .isEmpty,
        reason: 'folder load to finish',
      );

      // --- Breadcrumb header visible ---
      expect(find.byType(FolderContentsScreen), findsOneWidget);
      expect(find.text('Browse music'), findsOneWidget);
      expect(find.byType(FolderContentsBody), findsOneWidget);

      // ── Breadcrumb navigates back ─────────────────────────────────────────
      await tester.tap(find.text('Browse music'));
      await TestHelper.pumpUntil(
        tester,
        () => find.byType(FolderContentsScreen).evaluate().isEmpty,
        reason: 'to pop back to the browse list',
      );

      expect(find.byType(FolderContentsScreen), findsNothing);
      expect(find.text('Browse music folders'), findsOneWidget);

      // ── Selection flow (only when audio files are present) ────────────────
      // Re-open Home for the selection steps.
      await tester.tap(find.text('Home'));
      await TestHelper.pumpUntil(
        tester,
        () => find.byType(FolderContentsScreen).evaluate().isNotEmpty,
        reason: 'folder contents screen to open (second time)',
      );
      await TestHelper.pumpUntil(
        tester,
        () => find
            .descendant(
              of: find.byType(FolderContentsScreen),
              matching: find.byType(CircularProgressIndicator),
            )
            .evaluate()
            .isEmpty,
        reason: 'folder load to finish (second time)',
      );

      final audioTiles = find.byType(FolderAudioTile);
      if (audioTiles.evaluate().isEmpty) {
        // No audio files on this device — skip selection assertions.
        return;
      }

      // --- Long-press enters selection mode ---
      await tester.longPress(audioTiles.first);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SelectionHeader), findsOneWidget);
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byTooltip('Select all'), findsOneWidget);
      expect(find.byTooltip('Save to library'), findsOneWidget);

      // --- Cancel restores breadcrumb header ---
      await tester.tap(find.byTooltip('Cancel selection'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SelectionHeader), findsNothing);
      expect(find.text('Browse music'), findsOneWidget);
    });
  });
}