import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// On-disk cache for composed marker PNGs, keyed by a stable id. Survives app
/// restarts, so a marker photo is downloaded + composed at most once per device
/// — the per-fetch cost of the private Storage bucket (~0.6-1s) is paid once.
class MarkerCache {
  Directory? _dir;

  Future<Directory> _ensureDir() async {
    final existing = _dir;
    if (existing != null) return existing;
    final base = await getApplicationCacheDirectory();
    final dir = Directory('${base.path}/markers');
    if (!await dir.exists()) await dir.create(recursive: true);
    _dir = dir;
    return dir;
  }

  File _fileFor(Directory dir, String key) {
    final safe = key.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    return File('${dir.path}/$safe.png');
  }

  Future<Uint8List?> read(String key) async {
    try {
      final f = _fileFor(await _ensureDir(), key);
      if (await f.exists()) return await f.readAsBytes();
    } catch (_) {}
    return null;
  }

  Future<void> write(String key, Uint8List bytes) async {
    try {
      await (_fileFor(await _ensureDir(), key)).writeAsBytes(bytes);
    } catch (_) {}
  }
}
