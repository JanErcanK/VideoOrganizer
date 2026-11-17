import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const initialTags = ['Workout', 'Rezepte', 'Laufen', 'Inspiration'];

enum VideoFormat {
  short('Short-Form'),
  medium('Medium-Form'),
  long('Long-Form'),
  unknown('Dauer offen');

  const VideoFormat(this.label);
  final String label;
  static VideoFormat of(int? seconds) {
    if (seconds == null || seconds <= 0) return unknown;
    if (seconds <= 60) return short;
    if (seconds <= 300) return medium;
    return long;
  }
}

Uri? videoUrl(String input) {
  final match = RegExp(
    r'''https?://[^\s<>"']+''',
    caseSensitive: false,
  ).firstMatch(input.trim());
  if (match == null) return null;
  var url = match.group(0)!;
  // Share captions frequently wrap a URL in parentheses or append punctuation.
  if (input.trim() != url) {
    url = url.replaceFirst(RegExp(r'[.,;!?…]+$'), '');
    while (url.endsWith(')') &&
        '('.allMatches(url).length < ')'.allMatches(url).length) {
      url = url.substring(0, url.length - 1);
    }
  }
  final uri = Uri.tryParse(url);
  if (uri == null ||
      !uri.hasAuthority ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return uri;
}

String platformName(Uri uri) {
  final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
  const names = {
    'youtube.com': 'YouTube',
    'youtu.be': 'YouTube',
    'instagram.com': 'Instagram',
    'tiktok.com': 'TikTok',
    'snapchat.com': 'Snapchat',
    'vimeo.com': 'Vimeo',
    'facebook.com': 'Facebook',
    'twitch.tv': 'Twitch',
    'x.com': 'X',
  };
  for (final entry in names.entries) {
    if (host == entry.key || host.endsWith('.${entry.key}')) return entry.value;
  }
  return host;
}

String clockTime(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

int? parseClock(String input) {
  final value = input.trim();
  if (!RegExp(r'^\d{1,7}(:[0-5]\d){0,2}$').hasMatch(value)) return null;
  final seconds = value
      .split(':')
      .fold(0, (total, part) => total * 60 + int.parse(part));
  return seconds > 0 ? seconds : null;
}

List<String> mergeTags(Iterable<String> names) {
  final seen = <String>{};
  return [
    for (final s in names.map((v) => v.trim()))
      if (s.isNotEmpty && seen.add(s.toLowerCase())) s,
  ];
}

class Clip {
  const Clip({
    required this.id,
    required this.url,
    required this.title,
    required this.tags,
    required this.note,
    required this.created,
    this.seconds,
  });
  final String id, url, title, note;
  final int created;
  final List<String> tags;
  final int? seconds;
  VideoFormat get format => VideoFormat.of(seconds);
  String get platform => platformName(Uri.parse(url));
  String get displayTitle => title.isEmpty ? '$platform-Video' : title;
  Map<String, Object?> toJson() => {
    'id': id,
    'url': url,
    'title': title,
    'tags': tags,
    'note': note,
    'created': created,
    'seconds': seconds,
  };
  factory Clip.fromJson(Map<String, dynamic> json) => Clip(
    id: json['id'],
    url: json['url'],
    title: json['title'] ?? '',
    tags: List<String>.from(json['tags'] ?? []),
    note: json['note'] ?? '',
    created: json['created'],
    seconds: json['seconds'],
  );
}

class Library extends ChangeNotifier {
  List<String> tags = [...initialTags];
  List<Clip> clips = [];
  final _storage = SharedPreferencesAsync();
  Future<void> _tail = Future.value();

  Future<void> load() async {
    final data = await _storage.getString('library.v1');
    if (data != null) {
      final json = jsonDecode(data) as Map<String, dynamic>;
      tags = List<String>.from(json['tags']);
      clips = [for (final clip in json['clips']) Clip.fromJson(clip)];
    }
    notifyListeners();
  }

  // Derive each update from the last successfully persisted state.
  Future<void> _change(
    ({List<String> tags, List<Clip> clips}) Function() update,
  ) {
    final operation = _tail.then((_) async {
      final next = update();
      await _storage.setString(
        'library.v1',
        jsonEncode({
          'tags': next.tags,
          'clips': next.clips.map((c) => c.toJson()).toList(),
        }),
      );
      tags = next.tags;
      clips = next.clips;
      notifyListeners();
    });
    _tail = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> addTag(String name) =>
      _change(() => (tags: mergeTags([...tags, name]), clips: clips));
  Future<void> save(Clip clip) => _change(() {
    final names = mergeTags([...tags, ...clip.tags]);
    final keys = clip.tags.map((t) => t.trim().toLowerCase()).toSet();
    final normalized = Clip.fromJson({
      ...clip.toJson(),
      'tags': names.where((t) => keys.contains(t.toLowerCase())).toList(),
    });
    return (
      tags: names,
      clips: [normalized, ...clips.where((c) => c.id != clip.id)]
        ..sort((a, b) => b.created.compareTo(a.created)),
    );
  });
  Future<void> remove(String id) => _change(
    () => (tags: tags, clips: clips.where((c) => c.id != id).toList()),
  );
}
