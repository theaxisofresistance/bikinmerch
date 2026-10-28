import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'project.dart';

Color hex(String value) => Color(
  int.tryParse(value.replaceFirst('#', ''), radix: 16) == null
      ? 0xff294f36
      : 0xff000000 | int.parse(value.replaceFirst('#', ''), radix: 16),
);

class StudioRenderer {
  ui.Image? front, back;
  final Map<String, ui.Image> _logos = {};
  Future<void>? _loading;
  bool _disposed = false;
  Future<void> load() => _loading ??= _loadAssets();
  Future<void> _loadAssets() async {
    final images = await Future.wait(
      ['shirt.png', 'shirt-back.png'].map((name) async {
        final bytes = await rootBundle.load('assets/studio/$name');
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
        );
        final frame = await codec.getNextFrame();
        codec.dispose();
        return frame.image;
      }),
    );
    if (_disposed) {
      for (final image in images) {
        image.dispose();
      }
      return;
    }
    front = images[0];
    back = images[1];
  }

  Future<void> prepare(DesignProject project) async {
    await load();
    for (final design in [project.front, project.back]) {
      final source = design.logo;
      if (source == null || _logos.containsKey(source)) continue;
      final data = UriData.parse(source).contentAsBytes();
      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (_disposed) {
        frame.image.dispose();
        return;
      }
      _logos[source] = frame.image;
    }
  }

  void _text(
    Canvas canvas,
    String value,
    double y,
    double fontSize,
    double maxWidth,
    String family,
    Color color, {
    FontWeight weight = FontWeight.w800,
  }) {
    final text = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: family,
          fontFamilyFallback: family == 'Georgia'
              ? const ['Times New Roman', 'serif']
              : const ['Arial', 'sans-serif'],
          fontSize: fontSize,
          color: color,
          fontWeight: weight,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final scale = text.width > maxWidth ? maxWidth / text.width : 1.0;
    canvas.save();
    canvas.translate(0, y);
    canvas.scale(scale);
    text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
    canvas.restore();
  }

  void artwork(Canvas canvas, Size size, DesignSide design) {
    if (!design.enabled) return;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final factor = math.min(size.width / 600, size.height / 750);
    canvas.scale(factor);
    final ink = hex(design.ink), accent = hex(design.accent);
    final paint = Paint()..color = ink;
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final family = design.font == 'serif'
        ? 'Georgia'
        : design.font == 'sans'
        ? 'Arial'
        : 'Arial Narrow';
    void text(
      String value,
      double y,
      double fontSize,
      double maxWidth, {
      String? font,
      FontWeight weight = FontWeight.w800,
    }) => _text(
      canvas,
      value,
      y,
      fontSize,
      maxWidth,
      font ?? family,
      ink,
      weight: weight,
    );
    switch (design.template) {
      case 'afterhours':
        canvas.save();
        canvas.rotate(-.06);
        canvas.drawRect(
          const Rect.fromLTWH(-246, -183, 492, 122),
          Paint()..color = accent,
        );
        canvas.restore();
        text(design.title, -127, 126, 470);
        text(design.subtitle, 0, 136, 520);
        text(
          design.detail,
          127,
          21,
          475,
          font: 'Arial',
          weight: FontWeight.w600,
        );
        canvas.drawRect(const Rect.fromLTWH(-215, 79, 430, 3), paint);
      case 'ordinary':
        text(
          design.title,
          -50,
          98,
          510,
          font: design.font == 'condensed' ? 'Georgia' : family,
          weight: FontWeight.w400,
        );
        canvas.drawRect(const Rect.fromLTWH(-27, 36, 54, 3), paint);
        text(
          design.subtitle,
          95,
          23,
          470,
          font: 'Arial',
          weight: FontWeight.w600,
        );
        text(
          design.detail,
          142,
          17,
          440,
          font: 'Arial',
          weight: FontWeight.w400,
        );
      case 'running':
        canvas.drawRect(
          const Rect.fromLTWH(-244, -193, 488, 370),
          stroke..strokeWidth = 5,
        );
        canvas.save();
        canvas.skew(-.14, 0);
        text(design.title, -102, 112, 420);
        text(design.subtitle, 0, 94, 420);
        canvas.restore();
        canvas.drawRect(
          const Rect.fromLTWH(-244, 76, 488, 101),
          Paint()..color = accent,
        );
        text(
          design.detail,
          127,
          20,
          447,
          font: 'Arial',
          weight: FontWeight.w700,
        );
      case 'bloom':
        canvas.save();
        canvas.translate(0, -26);
        canvas.rotate(-.2);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 472, height: 386),
          stroke..color = accent,
        );
        canvas.restore();
        text(
          design.title,
          -55,
          107,
          510,
          font: design.font == 'condensed' ? 'Georgia' : family,
          weight: FontWeight.w600,
        );
        text(
          design.subtitle,
          63,
          24,
          460,
          font: 'Arial',
          weight: FontWeight.w600,
        );
        text(
          design.detail,
          203,
          19,
          450,
          font: 'Arial',
          weight: FontWeight.w400,
        );
      case 'good':
        canvas.drawCircle(const Offset(0, -25), 215, Paint()..color = accent);
        text(design.title, -74, 139, 430);
        text(design.subtitle, 37, 41, 415);
        canvas.drawRect(const Rect.fromLTWH(-110, 90, 220, 3), paint);
        text(
          design.detail,
          137,
          15,
          340,
          font: 'Arial',
          weight: FontWeight.w600,
        );
      default:
        canvas.drawArc(
          const Rect.fromLTWH(-188, -228, 376, 376),
          math.pi * 1.06,
          math.pi * .88,
          false,
          stroke,
        );
        text(design.title, -95, 103, 530);
        text(design.subtitle, 10, 110, 490);
        canvas.drawRect(
          const Rect.fromLTWH(-165, 83, 330, 8),
          Paint()..color = accent,
        );
        text(
          design.detail,
          142,
          20,
          470,
          font: 'Arial',
          weight: FontWeight.w600,
        );
    }
    final logo = _logos[design.logo];
    if (logo != null) {
      final ratio = logo.width / logo.height;
      final width = math.min(170.0, 110 * ratio);
      canvas.drawImageRect(
        logo,
        Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()),
        Rect.fromLTWH(-width / 2, 235, width, width / ratio),
        Paint()..filterQuality = FilterQuality.high,
      );
    }
    canvas.restore();
  }

  void mockup(
    Canvas canvas,
    Size size,
    DesignProject project,
    String side,
    String productName, {
    bool background = false,
  }) {
    canvas.save();
    canvas.scale(size.width / 1000, size.height / 1100);
    if (background) {
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1000, 1100),
        Paint()..color = const Color(0xfff1f2ee),
      );
    }
    final kind = productName.toLowerCase(), regular = project.fit == 'regular';
    double dx = 500, dy = 440, dw = regular ? 285 : 330;
    final paint = Paint()..color = hex(project.shirt);
    final stroke = Paint()
      ..color = const Color(0x2b1d271c)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;
    void box(Rect rect, double radius) {
      final rounded = RRect.fromRectAndRadius(rect, Radius.circular(radius));
      canvas.drawRRect(rounded, paint);
      canvas.drawRRect(rounded, stroke);
    }

    if (kind.contains('t-shirt')) {
      final photo = side == 'front' ? front : back;
      final mask = front;
      if (photo != null && mask != null) {
        final w = regular ? 790.0 : 930.0;
        final rect = Rect.fromLTWH((1000 - w) / 2, 40, w, 930);
        final source = Rect.fromLTWH(
          0,
          0,
          mask.width.toDouble(),
          mask.height.toDouble(),
        );
        canvas.saveLayer(const Rect.fromLTWH(0, 0, 1000, 1100), Paint());
        canvas.drawImageRect(
          mask,
          source,
          rect,
          Paint()..filterQuality = FilterQuality.high,
        );
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 1000, 1100),
          Paint()
            ..color = hex(project.shirt)
            ..blendMode = BlendMode.srcIn,
        );
        canvas.drawImageRect(
          photo,
          Rect.fromLTWH(0, 0, photo.width.toDouble(), photo.height.toDouble()),
          rect,
          Paint()
            ..blendMode = BlendMode.multiply
            ..filterQuality = FilterQuality.high,
        );
        canvas.drawImageRect(
          mask,
          source,
          rect,
          Paint()
            ..blendMode = BlendMode.dstIn
            ..filterQuality = FilterQuality.high,
        );
        canvas.restore();
      }
    } else if (kind.contains('hoodie')) {
      box(const Rect.fromLTWH(245, 245, 510, 690), 70);
      final hood = Path()
        ..moveTo(330, 300)
        ..quadraticBezierTo(500, 45, 670, 300)
        ..quadraticBezierTo(585, 390, 500, 390)
        ..quadraticBezierTo(415, 390, 330, 300);
      canvas.drawPath(hood, paint);
      canvas.drawPath(hood, stroke);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(338, 720, 324, 145),
          const Radius.circular(30),
        ),
        stroke,
      );
      dy = 540;
      dw = 310;
    } else if (kind.contains('tote')) {
      box(const Rect.fromLTWH(255, 310, 490, 610), 32);
      canvas.drawArc(
        const Rect.fromLTWH(355, 195, 290, 290),
        math.pi,
        math.pi,
        false,
        stroke..strokeWidth = 28,
      );
      dy = 570;
      dw = 315;
    } else if (kind.contains('mug')) {
      box(const Rect.fromLTWH(230, 320, 470, 520), 72);
      canvas.drawArc(
        const Rect.fromLTWH(565, 420, 290, 290),
        -math.pi / 2,
        math.pi,
        false,
        stroke..strokeWidth = 55,
      );
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(465, 335), width: 450, height: 90),
        Paint()..color = const Color(0x55ffffff),
      );
      dy = 575;
      dw = 280;
    } else {
      box(const Rect.fromLTWH(280, 160, 440, 780), 30);
      canvas.drawRect(
        const Rect.fromLTWH(305, 185, 18, 730),
        Paint()..color = const Color(0x24ffffff),
      );
      for (double y = 220; y < 900; y += 36) {
        canvas.drawLine(
          Offset(350, y),
          Offset(680, y),
          Paint()
            ..color = const Color(0x55ffffff)
            ..strokeWidth = 2,
        );
      }
      dy = 535;
      dw = 265;
    }
    final design = project.side(side);
    if (design.position == 'chest') {
      dw *= .45;
      dx = kind.contains('t-shirt') && side == 'front' ? 610 : 500;
      dy = kind.contains('notebook') ? 350 : 360;
    }
    if (design.position == 'large') dw *= 1.25;
    dw *= design.scale / 100;
    final dh = dw * 1.25;
    canvas.save();
    canvas.translate(dx - dw / 2, dy - dh / 2);
    artwork(canvas, Size(dw, dh), design);
    canvas.restore();
    canvas.restore();
  }

  Future<Uint8List> export(
    DesignProject project,
    String productName, {
    String side = 'front',
    String type = 'artwork',
  }) async {
    await prepare(project);
    final width = type == 'artwork'
        ? 2400
        : type == 'combined'
        ? 2000
        : 1000;
    final height = type == 'artwork' ? 3000 : 1100;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    if (type == 'artwork') {
      artwork(
        canvas,
        Size(width.toDouble(), height.toDouble()),
        project.side(side),
      );
    } else {
      mockup(
        canvas,
        const Size(1000, 1100),
        project,
        type == 'combined' ? 'front' : side,
        productName,
        background: true,
      );
      if (type == 'combined') {
        canvas.save();
        canvas.translate(1000, 0);
        mockup(
          canvas,
          const Size(1000, 1100),
          project,
          'back',
          productName,
          background: true,
        );
        canvas.restore();
      }
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    if (bytes == null) throw StateError('Ekspor PNG gagal.');
    return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
  }

  Future<String> preview(DesignProject project, String productName) async =>
      'data:image/png;base64,${base64Encode(await export(project, productName, type: 'mockup'))}';
  void dispose() {
    _disposed = true;
    front?.dispose();
    back?.dispose();
    for (final logo in _logos.values) {
      logo.dispose();
    }
    _logos.clear();
  }
}

class DesignPreview extends StatelessWidget {
  const DesignPreview({
    super.key,
    required this.renderer,
    required this.project,
    required this.productName,
    this.side,
    this.artworkOnly = false,
    this.background = false,
  });
  final StudioRenderer renderer;
  final DesignProject project;
  final String productName;
  final String? side;
  final bool artworkOnly, background;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: artworkOnly ? .8 : 1000 / 1100,
    child: CustomPaint(
      painter: _PreviewPainter(
        renderer,
        project.copy(),
        side ?? project.activeSide,
        productName,
        artworkOnly,
        background,
      ),
    ),
  );
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter(
    this.renderer,
    this.project,
    this.side,
    this.name,
    this.onlyArtwork,
    this.background,
  );
  final StudioRenderer renderer;
  final DesignProject project;
  final String side, name;
  final bool onlyArtwork, background;
  @override
  void paint(Canvas canvas, Size size) {
    if (onlyArtwork) {
      renderer.artwork(canvas, size, project.side(side));
    } else {
      renderer.mockup(
        canvas,
        size,
        project,
        side,
        name,
        background: background,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter oldDelegate) => true;
}
