import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Composes the original waylo photo marker — a square center-cropped photo with
/// rounded corners and a sky-blue border — into PNG bytes for a Mapbox point
/// annotation. When [count] > 1 the marker is a cluster: the same thumbnail with
/// a small count badge in the top-left corner (Apple Photos style). Built once
/// per (photo, count) and cached by the caller.
Future<Uint8List> composePhotoMarker(
  Uint8List photoBytes, {
  int count = 1,
  String? initial, // friend initial badge (recent merged map only)
  Uint8List? avatarBytes, // friend avatar badge; falls back to [initial]
  int size = 170, // matches old waylo marker proportions
  double border = 7,
  double radius = 8,
}) async {
  final codec = await ui.instantiateImageCodec(photoBytes);
  final frame = await codec.getNextFrame();
  final src = frame.image;

  final recorder = ui.PictureRecorder();
  final s = size.toDouble();
  final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, s, s));

  // Sky-blue rounded-square (the border).
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(0, 0, s, s),
      ui.Radius.circular(radius),
    ),
    ui.Paint()..color = AppColors.primary,
  );

  // Photo, center-cropped to a square, clipped to the inner rounded rect.
  final inner = ui.Rect.fromLTWH(border, border, s - 2 * border, s - 2 * border);
  canvas.save();
  canvas.clipRRect(
    ui.RRect.fromRectAndRadius(inner, ui.Radius.circular(radius - border / 2)),
  );
  final sw = src.width.toDouble();
  final sh = src.height.toDouble();
  double sx = 0, sy = 0, side = sw;
  if (sw > sh) {
    side = sh;
    sx = (sw - sh) / 2;
  } else {
    side = sw;
    sy = (sh - sw) / 2;
  }
  canvas.drawImageRect(
    src,
    ui.Rect.fromLTWH(sx, sy, side, side),
    inner,
    ui.Paint(),
  );
  canvas.restore();
  src.dispose();

  final badgeR = s * 0.17;
  // Cluster count badge, top-right corner.
  if (count > 1) {
    _circleBadge(canvas, ui.Offset(s - badgeR - 2, badgeR + 2), badgeR, '$count');
  }
  // Friend badge (recent merged map), bottom-left corner: the author's avatar
  // photo when they have one, otherwise their initial.
  final badgeCenter = ui.Offset(badgeR + 2, s - badgeR - 2);
  if (avatarBytes != null) {
    await _avatarBadge(canvas, badgeCenter, badgeR, avatarBytes);
  } else if (initial != null && initial.isNotEmpty) {
    _circleBadge(canvas, badgeCenter, badgeR, initial.substring(0, 1).toUpperCase());
  }

  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List();
}

/// A dark circular corner badge with a white outline and centered white text
/// (cluster count, or a friend's initial on the recent map).
void _circleBadge(ui.Canvas canvas, ui.Offset center, double r, String text) {
  canvas.drawCircle(center, r, ui.Paint()..color = const Color(0xFF1E1E1E));
  canvas.drawCircle(
    center,
    r,
    ui.Paint()
      ..color = Colors.white
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2,
  );
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
    ui.Canvas canvas, ui.Offset center, double r, Uint8List avatarBytes) async {
  final codec = await ui.instantiateImageCodec(avatarBytes);
  final frame = await codec.getNextFrame();
  final img = frame.image;

  final circle = ui.Rect.fromCircle(center: center, radius: r);
  canvas.save();
  canvas.clipPath(ui.Path()..addOval(circle));
  final sw = img.width.toDouble();
  final sh = img.height.toDouble();
  double sx = 0, sy = 0, side = sw;
  if (sw > sh) {
    side = sh;
    sx = (sw - sh) / 2;
  } else {
    side = sw;
    sy = (sh - sw) / 2;
  }
  canvas.drawImageRect(
    img,
    ui.Rect.fromLTWH(sx, sy, side, side),
    circle,
    ui.Paint(),
  );
  canvas.restore();
  img.dispose();

  canvas.drawCircle(
    center,
    r,
    ui.Paint()
      ..color = Colors.white
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2,
  );
}

/// A neutral placeholder marker (same frame, light-grey center, no photo),
/// shown instantly while the real thumbnail loads. Composed once and reused.
Future<Uint8List> composePlaceholderMarker({
  int size = 170,
  double border = 7,
  double radius = 8,
}) async {
  final recorder = ui.PictureRecorder();
  final s = size.toDouble();
  final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, s, s));
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(0, 0, s, s),
      ui.Radius.circular(radius),
    ),
    ui.Paint()..color = AppColors.primary,
  );
  final inner = ui.Rect.fromLTWH(border, border, s - 2 * border, s - 2 * border);
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(inner, ui.Radius.circular(radius - border / 2)),
    ui.Paint()..color = const Color(0xFFE3E3E3),
  );
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List();
}

/// Composes a flag marker for the zoomed-out tier: the country flag on a white
/// rounded card (flag aspect preserved), with a count badge when [count] > 1.
Future<Uint8List> composeFlagMarker(
  Uint8List flagBytes, {
  int count = 1,
  double cardHeight = 96,
  double pad = 8,
  double radius = 10,
}) async {
  final codec = await ui.instantiateImageCodec(flagBytes);
  final frame = await codec.getNextFrame();
  final flag = frame.image;

  final flagH = cardHeight - pad * 2;
  final flagW = flagH * (flag.width / flag.height);
  final w = (flagW + pad * 2).round();
  final h = cardHeight.round();

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(
    recorder,
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
  );

  final card = ui.RRect.fromRectAndRadius(
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    ui.Radius.circular(radius),
  );
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

  // No count badge on flag markers — the owner finds the number unsightly. The
  // [count] param is kept (callers still pass it) but is no longer drawn.

  final image = await recorder.endRecording().toImage(w, h);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List();
}

