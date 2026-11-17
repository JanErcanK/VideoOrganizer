import 'dart:ui' as ui show Clip;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'design.dart';
import 'editor.dart';
import 'library.dart';

String countVideos(int count) => count == 1 ? '1 Video' : '$count Videos';

Future<void> openEditor(
  BuildContext context,
  Library library, {
  Clip? clip,
  String? folder,
}) async {
  final saved = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ClipEditor(library: library, clip: clip, folder: folder),
    ),
  );
  if (context.mounted && saved == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eintrag gespeichert.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class LibraryHome extends StatelessWidget {
  const LibraryHome({super.key, required this.library});
  final Library library;
  void collection(BuildContext context, {String? folder, bool search = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CollectionPage(library: library, folder: folder, search: search),
      ),
    );
  }

  Future<void> newFolder(BuildContext context) async {
    String name = '';
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Neuer Ordner'),
        content: TextField(
          autofocus: true,
          maxLength: 60,
          onChanged: (v) => name = v.trim(),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) Navigator.pop(ctx, v.trim());
          },
          decoration: const InputDecoration(labelText: 'Tag-Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              if (name.isNotEmpty) Navigator.pop(ctx, name);
            },
            child: const Text('Anlegen'),
          ),
        ],
      ),
    );
    if (value != null && context.mounted) {
      final existing = library.tags.any(
        (t) => t.toLowerCase() == value.toLowerCase(),
      );
      try {
        await library.addTag(value);
        if (context.mounted && existing) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dieser Ordner ist bereits vorhanden.'),
            ),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ordner konnte nicht gespeichert werden.'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, screen) {
            final wide = screen.maxWidth >= 720;
            final margin = wide ? 44.0 : 20.0;
            return Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: line)),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1160),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: margin,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Brand(),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Mediathek durchsuchen',
                              icon: const Icon(Icons.search_rounded),
                              onPressed: () =>
                                  collection(context, search: true),
                            ),
                            const SizedBox(width: 7),
                            if (screen.maxWidth < 365 ||
                                MediaQuery.textScalerOf(context).scale(14) > 19)
                              IconButton.filled(
                                tooltip: 'Video merken',
                                onPressed: () => openEditor(context, library),
                                icon: const Icon(Icons.add_rounded),
                              )
                            else
                              FilledButton.icon(
                                onPressed: () => openEditor(context, library),
                                icon: const Icon(Icons.add, size: 19),
                                label: const Text('Video merken'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1160),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            margin,
                            wide ? 40 : 27,
                            margin,
                            32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Meine Mediathek',
                                style: headline(wide ? 46 : 35),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${countVideos(library.clips.length)}   ·   ${library.tags.length} Ordner',
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 21),
                              Semantics(
                                button: true,
                                child: Material(
                                  color: pine,
                                  borderRadius: BorderRadius.circular(22),
                                  clipBehavior: ui.Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () => collection(context),
                                    child: SizedBox(
                                      height: wide ? 190 : 158,
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            right: wide ? 36 : -13,
                                            top: -1,
                                            bottom: -4,
                                            width: wide ? 262 : 173,
                                            child: CustomPaint(
                                              painter: ArchiveArt(),
                                            ),
                                          ),
                                          Positioned(
                                            left: wide ? 30 : 21,
                                            top: wide ? 28 : 22,
                                            child: const Icon(
                                              Icons.video_library_outlined,
                                              size: 23,
                                              color: Color(0xffDAE8CB),
                                            ),
                                          ),
                                          Positioned(
                                            left: wide ? 30 : 21,
                                            bottom: 22,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Alle Videos',
                                                  style:
                                                      headline(
                                                        wide ? 38 : 30,
                                                      ).copyWith(
                                                        color: Colors.white,
                                                      ),
                                                ),
                                                const SizedBox(height: 6),
                                                const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Sammlung öffnen',
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xffE0EBD6,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    SizedBox(width: 7),
                                                    Icon(
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      size: 16,
                                                      color: Color(0xffE0EBD6),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 25),
                              SectionHeading(
                                'Meine Ordner',
                                action: TextButton.icon(
                                  onPressed: () => newFolder(context),
                                  icon: const Icon(
                                    Icons.create_new_folder_outlined,
                                    size: 19,
                                  ),
                                  label: Text(wide ? 'Neuer Ordner' : 'Neu'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              LayoutBuilder(
                                builder: (context, area) {
                                  final n = area.maxWidth < 270
                                      ? 1
                                      : area.maxWidth < 620
                                      ? 2
                                      : area.maxWidth < 850
                                      ? 3
                                      : 4;
                                  const gap = 12.0;
                                  return Wrap(
                                    spacing: gap,
                                    runSpacing: gap,
                                    children: [
                                      for (
                                        var i = 0;
                                        i < library.tags.length;
                                        i++
                                      )
                                        SizedBox(
                                          width:
                                              (area.maxWidth - (n - 1) * gap) /
                                              n,
                                          child: _FolderCard(
                                            index: i,
                                            name: library.tags[i],
                                            count: library.clips
                                                .where(
                                                  (c) => c.tags.contains(
                                                    library.tags[i],
                                                  ),
                                                )
                                                .length,
                                            onTap: () => collection(
                                              context,
                                              folder: library.tags[i],
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 28),
                              SectionHeading(
                                'Zuletzt gemerkt',
                                action: library.clips.length > 4
                                    ? TextButton(
                                        onPressed: () => collection(context),
                                        child: const Text('Alle ansehen'),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              if (library.clips.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffEFF2EB),
                                    borderRadius: BorderRadius.circular(17),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.bookmark_add_outlined,
                                        color: pine,
                                        size: 25,
                                      ),
                                      SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Dein erster Videolink',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Teile ein Video mit Clipfolio oder füge oben einen Link ein.',
                                              style: TextStyle(
                                                color: muted,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                for (final clip in library.clips.take(4))
                                  ClipTile(clip: clip, library: library),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.index,
    required this.name,
    required this.count,
    required this.onTap,
  });
  final int index, count;
  final String name;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: const BorderSide(color: line),
    ),
    clipBehavior: ui.Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 13, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FolderGlyph(index),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: muted, size: 17),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: headline(18),
            ),
            const SizedBox(height: 3),
            Text(
              countVideos(count),
              style: const TextStyle(color: muted, fontSize: 13),
            ),
          ],
        ),
      ),
    ),
  );
}

class CollectionPage extends StatefulWidget {
  const CollectionPage({
    super.key,
    required this.library,
    this.folder,
    this.search = false,
  });
  final Library library;
  final String? folder;
  final bool search;
  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  VideoFormat? filter;
  String query = '';
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.folder ?? (widget.search ? 'Suche' : 'Alle Videos'),
        style: headline(23),
      ),
      actions: [
        IconButton(
          tooltip: 'Video merken',
          onPressed: () =>
              openEditor(context, widget.library, folder: widget.folder),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    ),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: ListenableBuilder(
            listenable: widget.library,
            builder: (context, _) {
              final entries = widget.library.clips
                  .where(
                    (c) =>
                        (widget.folder == null ||
                            c.tags.contains(widget.folder)) &&
                        (filter == null || c.format == filter) &&
                        [
                          c.displayTitle,
                          c.url,
                          c.platform,
                          c.note,
                          ...c.tags,
                        ].any((v) => v.toLowerCase().contains(query)),
                  )
                  .toList();
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverList.list(
                      children: [
                        TextField(
                          autofocus: widget.search,
                          onChanged: (v) =>
                              setState(() => query = v.trim().toLowerCase()),
                          decoration: const InputDecoration(
                            hintText: 'Titel, Tags oder Kommentare suchen',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final f in <VideoFormat?>[
                                null,
                                ...VideoFormat.values,
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(right: 7),
                                  child: ChoiceChip(
                                    label: Text(f?.label ?? 'Alle'),
                                    selected: filter == f,
                                    onSelected: (_) =>
                                        setState(() => filter = f),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 19),
                        Text(
                          countVideos(entries.length),
                          style: const TextStyle(color: muted),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  if (entries.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.video_library_outlined,
                              color: muted,
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              query.isNotEmpty || filter != null
                                  ? 'Keine passenden Videos'
                                  : 'Hier ist noch Platz für Videos',
                              textAlign: TextAlign.center,
                              style: headline(19),
                            ),
                            const SizedBox(height: 9),
                            if (query.isEmpty && filter == null)
                              TextButton(
                                onPressed: () => openEditor(
                                  context,
                                  widget.library,
                                  folder: widget.folder,
                                ),
                                child: const Text('Video merken'),
                              ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverList.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, i) =>
                            ClipTile(clip: entries[i], library: widget.library),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

class ClipTile extends StatelessWidget {
  const ClipTile({super.key, required this.clip, required this.library});
  final Clip clip;
  final Library library;
  Future<void> open(BuildContext context) async {
    try {
      if (await launchUrl(
        Uri.parse(clip.url),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Der Link konnte nicht geöffnet werden.')),
      );
    }
  }

  Future<void> action(BuildContext context, String value) async {
    if (value == 'edit') {
      await openEditor(context, library, clip: clip);
      return;
    }
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eintrag löschen?'),
        content: Text(clip.displayTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (yes == true) {
      try {
        await library.remove(clip.id);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Löschen fehlgeschlagen.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: line),
      ),
      clipBehavior: ui.Clip.antiAlias,
      child: InkWell(
        onTap: () => open(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 4, 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xffE9EFE4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: pine,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clip.platform,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(clip.displayTitle, style: headline(18)),
                    if (clip.title.isEmpty)
                      Text(
                        clip.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                    if (clip.note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text(
                          clip.note,
                          style: const TextStyle(height: 1.4),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        for (final tag in [
                          clip.seconds == null
                              ? clip.format.label
                              : '${clip.format.label} · ${clockTime(clip.seconds!)}',
                          ...clip.tags,
                        ])
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 3,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: paper,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Eintragsoptionen',
                onSelected: (v) => action(context, v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                  PopupMenuItem(value: 'delete', child: Text('Löschen')),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
