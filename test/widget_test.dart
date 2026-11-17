import 'package:clipfolio/design.dart';
import 'package:clipfolio/library.dart';
import 'package:clipfolio/metadata.dart';
import 'package:clipfolio/screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );
  test('Formatgrenzen und Dauer ohne Metadaten', () {
    expect([null, 1, 60, 61, 299, 300, 301].map(VideoFormat.of), [
      VideoFormat.unknown,
      VideoFormat.short,
      VideoFormat.short,
      VideoFormat.medium,
      VideoFormat.medium,
      VideoFormat.medium,
      VideoFormat.long,
    ]);
    expect(parseClock('1:00:03'), 3603);
    expect(parseClock('3:90'), isNull);
  });
  test('Geteilter Text bewahrt Parameter und validiert das Protokoll', () {
    expect(
      videoUrl('Ansehen (https://youtu.be/xyz?t=2).')?.toString(),
      'https://youtu.be/xyz?t=2',
    );
    expect(videoUrl('file:///film.mp4'), isNull);
    expect(platformName(Uri.parse('https://vm.tiktok.com/123')), 'TikTok');
    expect(platformName(Uri.parse('https://nottiktok.com')), 'nottiktok.com');
  });
  test('Videometadaten aus Open Graph und strukturierten Daten', () {
    expect(
      readVideoInfo(
        '<meta property="video:duration" content="60"><title>A &amp; B</title>',
      ),
      (title: 'A & B', seconds: 60),
    );
    expect(
      readVideoInfo(
        '<script type="application/ld+json">{"@graph":[{"@type":"VideoObject","duration":"PT5M1S","name":"Laufen"}]}</script>',
      ),
      (title: 'Laufen', seconds: 301),
    );
    expect(readVideoInfo('<html/>').seconds, isNull);
  });
  testWidgets(
    'Eintrag mit Kommentar und neuem Tag speichern, neu laden und filtern',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1350));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final library = Library();
      await library.load();
      await tester.pumpWidget(
        MaterialApp(
          theme: clipTheme(),
          home: LibraryHome(library: library),
        ),
      );
      await tester.tap(find.text('Video merken'));
      await tester.pumpAndSettle();
      Future<void> fill(String hint, String value) async {
        final field = find.widgetWithText(TextField, hint);
        await tester.ensureVisible(field);
        await tester.enterText(field, value);
        await tester.pumpAndSettle();
      }

      await fill('https://…', 'https://example.org/lauf');
      await fill('Videotitel (optional)', 'Intervalltraining');
      await tester.tap(find.text('Workout'));
      await fill('Eigenen Tag erstellen', 'Technik');
      await fill('Was möchtest du dir merken?', 'Auf die Frequenz achten.');
      await fill('Min:Sek oder Sekunden', '5:00');
      await tester.ensureVisible(find.text('Speichern'));
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      final reloaded = Library();
      await reloaded.load();
      expect(reloaded.clips.single.tags, containsAll(['Workout', 'Technik']));
      expect(reloaded.clips.single.note, 'Auf die Frequenz achten.');
      expect(reloaded.clips.single.format, VideoFormat.medium);
      await tester.ensureVisible(find.text('Technik').first);
      await tester.tap(find.text('Technik').first);
      await tester.pumpAndSettle();
      expect(find.text('Intervalltraining'), findsOneWidget);
      await tester.tap(find.text('Short-Form'));
      await tester.pumpAndSettle();
      expect(find.text('Keine passenden Videos'), findsOneWidget);
      await tester.tap(find.text('Medium-Form'));
      await tester.pumpAndSettle();
      expect(find.text('Auf die Frequenz achten.'), findsOneWidget);
    },
  );
}
