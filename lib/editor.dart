import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design.dart';
import 'library.dart';
import 'metadata.dart';

class ClipEditor extends StatefulWidget {
  const ClipEditor({
    super.key,
    required this.library,
    this.clip,
    this.sharedText = '',
    this.folder,
    this.shareId,
  });
  final Library library;
  final Clip? clip;
  final String sharedText;
  final String? folder, shareId;
  @override
  State<ClipEditor> createState() => _ClipEditorState();
}

class _ClipEditorState extends State<ClipEditor> {
  late final url = TextEditingController(
    text:
        widget.clip?.url ??
        videoUrl(widget.sharedText)?.toString() ??
        widget.sharedText,
  );
  late final title = TextEditingController(text: widget.clip?.title ?? '');
  late final note = TextEditingController(text: widget.clip?.note ?? '');
  late final duration = TextEditingController(
    text: widget.clip?.seconds == null ? '' : clockTime(widget.clip!.seconds!),
  );
  final tag = TextEditingController();
  late final selected = <String>{...?widget.clip?.tags, ?widget.folder};
  bool saving = false, loadingInfo = false;
  String? urlError, durationError;
  String? previousUrlText;
  Uri? requested;
  Future<VideoInfo>? request;
  Timer? debounce;
  String automaticTitle = '', automaticDuration = '';

  @override
  void initState() {
    super.initState();
    url.addListener(urlChanged);
    if (widget.clip == null && url.text.isNotEmpty) urlChanged();
  }

  void urlChanged() {
    if (url.text == previousUrlText) return;
    previousUrlText = url.text;
    debounce?.cancel();
    requested = null;
    request = null;
    if (automaticTitle.isNotEmpty && title.text == automaticTitle) {
      title.clear();
    }
    if (automaticDuration.isNotEmpty && duration.text == automaticDuration) {
      duration.clear();
    }
    automaticTitle = '';
    automaticDuration = '';
    setState(() {
      urlError = null;
      loadingInfo = false;
    });
    final uri = videoUrl(url.text);
    if (uri != null) {
      debounce = Timer(const Duration(milliseconds: 700), () => getInfo(uri));
    }
  }

  Future<void> getInfo(Uri uri) async {
    if (requested != uri) {
      requested = uri;
      request = lookupVideo(uri);
    }
    final active = request!;
    setState(() => loadingInfo = true);
    final info = await active;
    if (!mounted || active != request) return;
    if (title.text.trim().isEmpty && info.title.isNotEmpty) {
      title.text = automaticTitle = info.title;
    }
    if (duration.text.trim().isEmpty && info.seconds != null) {
      duration.text = automaticDuration = clockTime(info.seconds!);
    }
    setState(() => loadingInfo = false);
  }

  void addTag() {
    final value = tag.text.trim();
    if (value.isEmpty) return;
    final names = mergeTags([...widget.library.tags, ...selected, value]);
    setState(
      () => selected.add(
        names.firstWhere((s) => s.toLowerCase() == value.toLowerCase()),
      ),
    );
    tag.clear();
  }

  Future<void> save() async {
    if (saving) return;
    final uri = videoUrl(url.text);
    final raw = duration.text.trim();
    setState(() {
      urlError = uri == null
          ? 'Bitte einen vollständigen http- oder https-Link eingeben.'
          : null;
      durationError = raw.isNotEmpty && parseClock(raw) == null
          ? 'Beispiel: 2:30 oder 150 Sekunden.'
          : null;
    });
    if (uri == null || durationError != null) return;
    FocusScope.of(context).unfocus();
    debounce?.cancel();
    addTag();
    setState(() => saving = true);
    try {
      if (widget.clip?.url != uri.toString() &&
          (title.text.trim().isEmpty || duration.text.trim().isEmpty)) {
        await getInfo(uri);
      }
      if (!mounted) return;
      final now = DateTime.now();
      await widget.library.save(
        Clip(
          id:
              widget.clip?.id ??
              widget.shareId ??
              now.microsecondsSinceEpoch.toString(),
          url: uri.toString(),
          title: title.text.trim(),
          note: note.text.trim(),
          tags: selected.toList(),
          seconds: parseClock(duration.text),
          created: widget.clip?.created ?? now.millisecondsSinceEpoch,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speichern fehlgeschlagen. Bitte erneut versuchen.'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    for (final c in [url, title, note, duration, tag]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget label(String text) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 9),
    child: Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final tags = mergeTags([...widget.library.tags, ...selected]);
    final format = VideoFormat.of(parseClock(duration.text));
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Schließen',
            onPressed: saving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
          title: Text(
            widget.clip == null ? 'Video merken' : 'Eintrag bearbeiten',
            style: headline(21),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 30),
                children: [
                  label('Videolink'),
                  TextField(
                    controller: url,
                    enabled: !saving,
                    autocorrect: false,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      hintText: 'https://…',
                      errorText: urlError,
                      prefixIcon: const Icon(Icons.link_rounded),
                      suffixIcon: IconButton(
                        tooltip: 'Link einfügen',
                        icon: const Icon(Icons.content_paste_rounded),
                        onPressed: saving
                            ? null
                            : () async {
                                final data = await Clipboard.getData(
                                  Clipboard.kTextPlain,
                                );
                                if (mounted && data?.text != null) {
                                  url.text = data!.text!;
                                }
                              },
                      ),
                    ),
                  ),
                  if (loadingInfo)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Titel und Dauer werden abgerufen …',
                        style: TextStyle(color: muted),
                      ),
                    ),
                  label('Titel'),
                  TextField(
                    controller: title,
                    enabled: !saving,
                    decoration: const InputDecoration(
                      hintText: 'Videotitel (optional)',
                    ),
                  ),
                  label('Tags'),
                  Wrap(
                    spacing: 7,
                    runSpacing: 3,
                    children: [
                      for (final t in tags)
                        FilterChip(
                          label: Text(t),
                          selected: selected.contains(t),
                          onSelected: saving
                              ? null
                              : (v) => setState(() {
                                  if (v) {
                                    selected.add(t);
                                  } else {
                                    selected.remove(t);
                                  }
                                }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: tag,
                    enabled: !saving,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => addTag(),
                    decoration: InputDecoration(
                      hintText: 'Eigenen Tag erstellen',
                      suffixIcon: IconButton(
                        tooltip: 'Tag hinzufügen',
                        icon: const Icon(Icons.add),
                        onPressed: saving ? null : addTag,
                      ),
                    ),
                  ),
                  label('Kommentar'),
                  TextField(
                    controller: note,
                    enabled: !saving,
                    minLines: 2,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'Was möchtest du dir merken?',
                    ),
                  ),
                  label('Videodauer'),
                  TextField(
                    controller: duration,
                    enabled: !saving,
                    onChanged: (_) => setState(() => durationError = null),
                    keyboardType: TextInputType.datetime,
                    decoration: InputDecoration(
                      hintText: 'Min:Sek oder Sekunden',
                      errorText: durationError,
                      helperText: format == VideoFormat.unknown
                          ? 'Optional, falls die Plattform keine Dauer liefert.'
                          : format.label,
                      prefixIcon: const Icon(Icons.schedule_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: saving ? null : save,
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: Text(saving ? 'Wird gespeichert …' : 'Speichern'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
