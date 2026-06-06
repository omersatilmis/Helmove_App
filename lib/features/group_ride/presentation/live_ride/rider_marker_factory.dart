import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Diğer sürücüler için harita marker bitmap'leri üretir:
/// - dairesel profil fotoğrafı (foto yoksa baş harf) + renkli çerçeve
/// - yön oku (tek bitmap, iconRotate ile döndürülür)
///
/// Avatarlar userId+url+renk anahtarıyla cache'lenir (her konum güncellemesinde
/// yeniden üretilmez). Heading değişimi iconRotate ile yapıldığından avatar
/// yeniden çizilmez.
class RiderMarkerFactory {
  const RiderMarkerFactory._();

  static final Map<String, Uint8List> _avatarCache = {};
  static final Map<String, Uint8List> _arrowCache = {};
  static final Map<String, ui.Image> _imageCache = {};

  static const double _logicalSize = 54.0;
  static const double _dpr = 3.0;

  /// Bir sürücü için dairesel avatar bitmap'i (PNG bytes).
  static Future<Uint8List> buildAvatar({
    required int userId,
    String? photoUrl,
    required String displayName,
    required Color ringColor,
  }) async {
    final key = '$userId|${photoUrl ?? ''}|${ringColor.value}';
    final cached = _avatarCache[key];
    if (cached != null) return cached;

    final px = (_logicalSize * _dpr);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final radius = px / 2;
    final center = Offset(radius, radius);
    final ringWidth = px * 0.085;
    final innerRadius = radius - ringWidth;

    // Gölge
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Dış çerçeve
    canvas.drawCircle(center, radius, Paint()..color = ringColor);
    // İç beyaz ayraç
    canvas.drawCircle(
      center,
      innerRadius + ringWidth * 0.35,
      Paint()..color = Colors.white,
    );

    ui.Image? image;
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      image = await _loadImage(photoUrl);
    }

    if (image != null) {
      canvas.save();
      final clip = Path()
        ..addOval(Rect.fromCircle(center: center, radius: innerRadius));
      canvas.clipPath(clip);
      final src = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final dst = Rect.fromCircle(center: center, radius: innerRadius);
      canvas.drawImageRect(image, src, _fitCover(src, dst), Paint());
      canvas.restore();
    } else {
      // Baş harf fallback — isimden türetilmiş arka plan rengi
      final bg = _colorFromName(displayName);
      canvas.drawCircle(center, innerRadius, Paint()..color = bg);
      final initials = _initials(displayName);
      final tp = TextPainter(
        text: TextSpan(
          text: initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: innerRadius * 0.9,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(px.round(), px.round());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    final result = bytes!.buffer.asUint8List();
    _avatarCache[key] = result;
    return result;
  }

  /// Yön oku bitmap'i (yukarı bakar; iconRotate ile döndürülür).
  static Future<Uint8List> buildArrow({required Color color}) async {
    final key = '${color.value}';
    final cached = _arrowCache[key];
    if (cached != null) return cached;

    final px = 20.0 * _dpr;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final path = Path()
      ..moveTo(px / 2, px * 0.12)
      ..lineTo(px * 0.80, px * 0.86)
      ..lineTo(px / 2, px * 0.66)
      ..lineTo(px * 0.20, px * 0.86)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = px * 0.10
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(path, Paint()..color = color);

    final picture = recorder.endRecording();
    final img = await picture.toImage(px.round(), px.round());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    final result = bytes!.buffer.asUint8List();
    _arrowCache[key] = result;
    return result;
  }

  // ── helpers ──────────────────────────────────────────────────────────────────

  static Future<ui.Image?> _loadImage(String url) async {
    final cached = _imageCache[url];
    if (cached != null) return cached;
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        client.close();
        return null;
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      client.close();
      final codec = await ui.instantiateImageCodec(builder.toBytes());
      final frame = await codec.getNextFrame();
      _imageCache[url] = frame.image;
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  /// Kaynağı hedef daireyi kaplayacak şekilde merkezden kırpar (cover).
  static Rect _fitCover(Rect src, Rect dst) {
    final srcRatio = src.width / src.height;
    final dstRatio = dst.width / dst.height;
    if (srcRatio > dstRatio) {
      // kaynak daha geniş → yatay kırp
      final newWidth = src.height * dstRatio;
      final dx = (src.width - newWidth) / 2;
      return Rect.fromLTWH(src.left + dx, src.top, newWidth, src.height);
    } else {
      final newHeight = src.width / dstRatio;
      final dy = (src.height - newHeight) / 2;
      return Rect.fromLTWH(src.left, src.top + dy, src.width, newHeight);
    }
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  static Color _colorFromName(String name) {
    const palette = [
      Color(0xFF1565C0),
      Color(0xFF2E7D32),
      Color(0xFFC62828),
      Color(0xFF6A1B9A),
      Color(0xFFEF6C00),
      Color(0xFF00838F),
      Color(0xFF4527A0),
    ];
    final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
    return palette[hash % palette.length];
  }
}
