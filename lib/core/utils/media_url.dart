/// Paridade com `luditeca-vps/frontend/lib/bookMediaSrc.js` e buckets do backend.
const Set<String> _knownMediaBuckets = {
  'covers',
  'pages',
  'presentations',
  'audios',
  'videos',
  'categories',
  'autores',
  'avatars',
};

class MediaStorageRef {
  final String bucket;
  final String filePath;

  const MediaStorageRef({required this.bucket, required this.filePath});
}

List<String> _splitPathSegments(String value) {
  return value
      .replaceAll('\\', '/')
      .split('/')
      .where((p) => p.isNotEmpty)
      .map(Uri.decodeComponent)
      .toList();
}

MediaStorageRef? _peelBookMediaSegments(List<String> segments) {
  final parts = List<String>.from(segments);
  while (parts.isNotEmpty && parts.first == 'media') {
    parts.removeAt(0);
  }
  if (parts.length >= 2 && _knownMediaBuckets.contains(parts.first)) {
    return MediaStorageRef(
      bucket: parts.first,
      filePath: parts.sublist(1).join('/'),
    );
  }
  return null;
}

MediaStorageRef? _fromMediaPathname(String pathname) {
  const marker = '/media/';
  final idx = pathname.indexOf(marker);
  if (idx < 0) return null;
  final rest = pathname.substring(idx + marker.length);
  return _peelBookMediaSegments(_splitPathSegments(rest));
}

/// Extrai bucket + filePath de URL absoluta, `/media/...` ou caminho relativo.
MediaStorageRef? parseBookMediaStorage(
  String? raw, {
  String defaultBucket = 'pages',
}) {
  final s = (raw ?? '').trim();
  if (s.isEmpty) return null;

  if (s.startsWith('http://') || s.startsWith('https://')) {
    try {
      final parsed = _fromMediaPathname(Uri.parse(s).path);
      if (parsed != null) return parsed;
    } catch (_) {}
  }

  if (s.startsWith('/media/')) {
    final parsed = _fromMediaPathname(s);
    if (parsed != null) return parsed;
  }

  final clean = s.replaceFirst(RegExp(r'^/+'), '');
  if (clean.isNotEmpty && !clean.contains('://')) {
    final peeled = _peelBookMediaSegments(_splitPathSegments(clean));
    if (peeled != null) return peeled;
    if (clean.startsWith('$defaultBucket/')) {
      return MediaStorageRef(
        bucket: defaultBucket,
        filePath: clean.substring(defaultBucket.length + 1),
      );
    }
    return MediaStorageRef(bucket: defaultBucket, filePath: clean);
  }

  return null;
}

String _encodePath(String path) {
  return path
      .split('/')
      .where((s) => s.isNotEmpty)
      .map(Uri.encodeComponent)
      .join('/');
}

/// Monta URL pública `/media/{bucket}/{filePath}`.
String? resolveMediaUrl(
  String? raw,
  String mediaBaseUrl, {
  String defaultBucket = 'pages',
}) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return null;

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }

  final base = mediaBaseUrl.replaceAll(RegExp(r'/+$'), '');
  final storage = parseBookMediaStorage(value, defaultBucket: defaultBucket);
  if (storage != null) {
    final rel = _encodePath(storage.filePath);
    if (rel.isEmpty) return base;
    return '$base/${storage.bucket}/$rel';
  }

  if (value.startsWith('/')) return '$base$value';
  return '$base/$value';
}
