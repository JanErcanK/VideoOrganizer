import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'design.dart';
import 'editor.dart';
import 'library.dart';
import 'metadata.dart';
import 'screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClipfolioApp());
}

class ClipfolioApp extends StatefulWidget {
  const ClipfolioApp({super.key});
  @override
  State<ClipfolioApp> createState() => _ClipfolioAppState();
}

class _ClipfolioAppState extends State<ClipfolioApp>
    with WidgetsBindingObserver {
  final library = Library();
  final nav = GlobalKey<NavigatorState>();
  final messenger = GlobalKey<ScaffoldMessengerState>();
  static const bridge = MethodChannel('clipfolio/share');
  bool ready = false, failed = false, draining = false, again = false;
  bool get ios => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  bool get mobile =>
      ios || !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (mobile) {
      bridge.setMethodCallHandler((call) async {
        if (call.method == 'incoming') unawaited(drain());
      });
    }
    library.addListener(syncTags);
    load();
  }

  Future<void> load() async {
    setState(() => failed = false);
    try {
      await library.load();
      if (!mounted) return;
      setState(() => ready = true);
      WidgetsBinding.instance.addPostFrameCallback((_) => drain());
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  void syncTags() {
    if (ios) {
      unawaited(
        bridge.invokeMethod<void>('tags', library.tags).catchError((Object _) {
          message('Tag-Liste im Teilen-Menü konnte nicht aktualisiert werden.');
        }),
      );
    }
  }

  void message(String text) =>
      messenger.currentState?.showSnackBar(SnackBar(content: Text(text)));
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) drain();
  }

  Future<void> drain() async {
    if (!ready || !mobile || nav.currentState == null) return;
    if (draining) {
      again = true;
      return;
    }
    draining = true;
    try {
      do {
        again = false;
        final pending = await bridge.invokeListMethod<String>('pending') ?? [];
        final items =
            pending
                .map((raw) => jsonDecode(raw) as Map<String, dynamic>)
                .toList()
              ..sort(
                (a, b) => (a['created'] as int).compareTo(b['created'] as int),
              );
        for (final item in items) {
          final id = item['id'] as String;
          if (!library.clips.any((c) => c.id == id)) {
            if (ios) {
              final uri = videoUrl(item['url'] as String);
              if (uri == null) throw const FormatException('Invalid share');
              final supplied = Clip.fromJson(item);
              final info = await lookupVideo(uri);
              await library.save(
                Clip.fromJson({
                  ...supplied.toJson(),
                  'title': supplied.title.isEmpty ? info.title : supplied.title,
                  'seconds': supplied.seconds ?? info.seconds,
                }),
              );
            } else {
              if (!mounted) return;
              await nav.currentState!.push<bool>(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => ClipEditor(
                    library: library,
                    sharedText: item['text'] as String,
                    shareId: id,
                  ),
                ),
              );
            }
          }
          await bridge.invokeMethod<void>('ack', id);
        }
      } while (again);
    } catch (_) {
      message(
        'Geteilte Links konnten nicht geladen werden. Beim nächsten Öffnen wird es erneut versucht.',
      );
    } finally {
      draining = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (mobile) bridge.setMethodCallHandler(null);
    library.removeListener(syncTags);
    library.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: nav,
    scaffoldMessengerKey: messenger,
    title: 'Clipfolio',
    debugShowCheckedModeBanner: false,
    theme: clipTheme(),
    locale: const Locale('de'),
    supportedLocales: const [Locale('de')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: ready
        ? LibraryHome(library: library)
        : Scaffold(
            body: Center(
              child: failed
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Mediathek konnte nicht geladen werden.'),
                        TextButton(
                          onPressed: load,
                          child: const Text('Erneut versuchen'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
  );
}
