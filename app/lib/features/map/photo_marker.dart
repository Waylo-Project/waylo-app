import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

// Photo marker geometry (px): a sky-blue rounded square framing the photo.
const int _markerSize = 170;
const double _border = 7;
const double _radius = 8;

/// Composes the waylo photo marker — a square center-cropped photo with rounded
/// corners and a sky-blue border — into PNG bytes for a Mapbox point
/// annotation. When [count] > 1 the marker is a cluster: the same thumbnail
/// with a count badge in the top-right corner. On the recent map a friend badge
/// (their [avatarBytes], else their [initial]) sits bottom-left. Cached by the
/// caller.
Future<Uint8List> composePhotoMarker(
  Uint8List photoBytes, {
  int count = 1,
  String? initial,
  Uint8List? avatarBytes,
}) async {
  final src = await _decode(photoBytes);
  final recorder = ui.PictureRecorder();
  const s = _markerSize * 1.0;
  final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, s, s));

  // Photo, center-cropped to a square, clipped to the frame's inner rect.
  final inner = _drawFrame(canvas);
  canvas.save();
  canvas.clipRRect(inner);
  canvas.drawImageRect(src, _centerSquare(src), inner.outerRect, ui.Paint());
  canvas.restore();
  src.dispose();

  const badgeR = s * 0.17;
  if (count > 1) {
    _circleBadge(
      canvas,
      const ui.Offset(s - badgeR - 2, badgeR + 2),
      badgeR,
      '$count',
    );
  }
  const badgeCenter = ui.Offset(badgeR + 2, s - badgeR - 2);
  if (avatarBytes != null) {
    await _avatarBadge(canvas, badgeCenter, badgeR, avatarBytes);
  } else if (initial != null && initial.isNotEmpty) {
    _circleBadge(
      canvas,
      badgeCenter,
      badgeR,
      initial.substring(0, 1).toUpperCase(),
    );
  }

  return _toPng(recorder, _markerSize, _markerSize);
}

/// A neutral placeholder marker (same frame, light-grey center, no photo),
/// shown instantly while the real thumbnail loads. Composed once and reused.
Future<Uint8List> composePlaceholderMarker() async {
  final recorder = ui.PictureRecorder();
  const s = _markerSize * 1.0;
  final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, s, s));
  canvas.drawRRect(
    _drawFrame(canvas),
    ui.Paint()..color = const Color(0xFFE3E3E3),
  );
  return _toPng(recorder, _markerSize, _markerSize);
}

/// Composes a flag marker for the zoomed-out tier: the country flag on a white
/// rounded card (flag aspect preserved). Deliberately no post-count badge.
Future<Uint8List> composeFlagMarker(Uint8List flagBytes) async {
  const cardHeight = 96.0;
  const pad = 8.0;
  final flag = await _decode(flagBytes);

  const flagH = cardHeight - pad * 2;
  final flagW = flagH * (flag.width / flag.height);
  final w = (flagW + pad * 2).round();
  final h = cardHeight.round();

  final recorder = ui.PictureRecorder();
  final bounds = ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
  final canvas = ui.Canvas(recorder, bounds);

  final card = ui.RRect.fromRectAndRadius(bounds, const ui.Radius.circular(10));
  canvas.drawRRect(card, ui.Paint()..color = Colors.white);

  final flagRect = ui.Rect.fromLTWH(pad, pad, flagW, flagH);
  canvas.save();
  canvas.clipRRect(
    ui.RRect.fromRectAndRadius(flagRect, const ui.Radius.circular(4)),
  );
  canvas.drawImageRect(
    flag,
    ui.Rect.fromLTWH(0, 0, flag.width.toDouble(), flag.height.toDouble()),
    flagRect,
    ui.Paint(),
  );
  canvas.restore();
  flag.dispose();

  canvas.drawRRect(
    card,
    ui.Paint()
      ..color = const Color(0x22000000)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1,
  );

  return _toPng(recorder, w, h);
}

/// Draws the sky-blue rounded-square frame and returns the inner rounded rect
/// the photo (or placeholder) fills.
ui.RRect _drawFrame(ui.Canvas canvas) {
  const s = _markerSize * 1.0;
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(
      const ui.Rect.fromLTWH(0, 0, s, s),
      const ui.Radius.circular(_radius),
    ),
    ui.Paint()..color = AppColors.primary,
  );
  return ui.RRect.fromRectAndRadius(
    const ui.Rect.fromLTWH(_border, _border, s - 2 * _border, s - 2 * _border),
    const ui.Radius.circular(_radius - _border / 2),
  );
}

/// A dark circular corner badge with a white outline and centered white text
/// (cluster count, or a friend's initial on the recent map).
void _circleBadge(ui.Canvas canvas, ui.Offset center, double r, String text) {
  canvas.drawCircle(center, r, ui.Paint()..color = const Color(0xFF1E1E1E));
  _whiteRing(canvas, center, r);
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.white,
        fontSize: r * 1.1,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - ui.Offset(tp.width / 2, tp.height / 2));
}

/// A circular avatar badge (the author's photo, center-cropped into the circle)
/// with a white ring — same position/size as the initial badge.
Future<void> _avatarBadge(
  ui.Canvas canvas,
  ui.Offset center,
  double r,
  Uint8List avatarBytes,
) async {
  final img = await _decode(avatarBytes);
  final circle = ui.Rect.fromCircle(center: center, radius: r);
  canvas.save();
  canvas.clipPath(ui.Path()..addOval(circle));
  canvas.drawImageRect(img, _centerSquare(img), circle, ui.Paint());
  canvas.restore();
  img.dispose();
  _whiteRing(canvas, center, r);
}

void _whiteRing(ui.Canvas canvas, ui.Offset center, double r) {
  canvas.drawCircle(
    center,
    r,
    ui.Paint()
      ..color = Colors.white
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2,
  );
}

/// The largest centered square of [img], for a cover-style square crop.
ui.Rect _centerSquare(ui.Image img) {
  final w = img.width.toDouble();
  final h = img.height.toDouble();
  return w > h
      ? ui.Rect.fromLTWH((w - h) / 2, 0, h, h)
      : ui.Rect.fromLTWH(0, (h - w) / 2, w, w);
}

Future<ui.Image> _decode(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  return (await codec.getNextFrame()).image;
}

Future<Uint8List> _toPng(ui.PictureRecorder recorder, int w, int h) async {
  final image = await recorder.endRecording().toImage(w, h);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List();
}
