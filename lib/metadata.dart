import 'dart:convert';
import 'dart:typed_data';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

typedef VideoInfo = ({String title, int? seconds});

int? _duration(String? raw) {
  if (raw == null) return null;
  final number = num.tryParse(raw);
  if (number != null && number.isFinite && number > 0) return number.ceil();
  final m = RegExp(
    r'^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?$',
    caseSensitive: false,
  ).firstMatch(raw);
  if (m == null) return null;
  final total =
      (int.tryParse(m[1] ?? '') ?? 0) * 3600 +
      (int.tryParse(m[2] ?? '') ?? 0) * 60 +
      (double.tryParse(m[3] ?? '') ?? 0).ceil();
  return total > 0 ? total : null;
}

VideoInfo readVideoInfo(String source) {
  final doc = html.parse(source);
  String? meta(String key) => doc
      .querySelector(
        'meta[property="$key"],meta[itemprop="$key"],meta[name="$key"]',
      )
      ?.attributes['content'];
  var title = meta('og:title') ?? doc.querySelector('title')?.text ?? '';
  var seconds =
      _duration(meta('video:duration')) ??
      _duration(meta('og:video:duration')) ??
      _duration(meta('duration'));
  void visit(dynamic node) {
    if (node is List) {
      for (final item in node) {
        visit(item);
      }
    } else if (node is Map) {
      final type = node['@type'];
      if (type == 'VideoObject' ||
          type is List && type.contains('VideoObject')) {
        seconds ??= _duration(node['duration']?.toString());
        if (title.isEmpty && node['name'] is String) title = node['name'];
      }
      for (final child in node.values) {
        if (child is List || child is Map) visit(child);
      }
    }
  }

  for (final script in doc.querySelectorAll(
    'script[type="application/ld+json"]',
  )) {
    try {
      visit(jsonDecode(script.text));
    } on FormatException {
      continue;
    }
  }
  return (title: title.trim(), seconds: seconds);
}

// Only read a bounded prefix of HTML. Never consume a video response body.
Future<VideoInfo> lookupVideo(Uri url) async {
  final client = http.Client();
  Future<VideoInfo> fetch() async {
    final response = await client.send(
      http.Request('GET', url)
        ..headers['Accept'] = 'text/html,application/xhtml+xml',
    );
    final type = response.headers['content-type']?.toLowerCase() ?? '';
    if (response.statusCode != 200 || !type.contains('html')) {
      return (title: '', seconds: null);
    }
    const limit = 512 * 1024;
    final buffer = BytesBuilder(copy: false);
    await for (final chunk in response.stream) {
      final remaining = limit - buffer.length;
      buffer.add(
        chunk.length > remaining ? chunk.sublist(0, remaining) : chunk,
      );
      if (buffer.length == limit) break;
    }
    return readVideoInfo(utf8.decode(buffer.takeBytes(), allowMalformed: true));
  }

  try {
    return await fetch().timeout(const Duration(seconds: 6));
  } catch (_) {
    return (title: '', seconds: null);
  } finally {
    client.close();
  }
}
