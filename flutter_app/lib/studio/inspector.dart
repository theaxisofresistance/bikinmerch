import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/models.dart';
import '../ui/common.dart';
import 'export_file.dart' if (dart.library.js_interop) 'export_file_web.dart';
import 'project.dart';
import 'renderer.dart';

class DesignInspector extends StatefulWidget {
  const DesignInspector({super.key, required this.production});
  final Json production;
  @override
  State<DesignInspector> createState() => _DesignInspectorState();
}

class _DesignInspectorState extends State<DesignInspector> {
  final _renderer = StudioRenderer();
  DesignProject? _project;
  String _side = 'front', _view = 'artwork';
  bool _grid = true, _perspective = false, _loading = true, _busy = false;
  double _zoom = 75;
  String? _error;
  Json get order => object(widget.production['order']);
  Json get item => rows(order['items']).firstOrNull ?? {};
  Json get design => object(object(item['storeProduct'])['design']);
  Json get product => object(item['product']);
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final project = DesignProject.fromJson(object(design['canvas']));
      await _renderer.prepare(project);
      if (mounted) setState(() => _project = project);
    } catch (e) {
      if (mounted) setState(() => _error = 'Data desain tidak tersedia: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _renderer.dispose();
    super.dispose();
  }

  Future<void> _export(String type) async {
    if (_project == null) return;
    setState(() => _busy = true);
    try {
      final bytes = await _renderer.export(
        _project!,
        textOf(product['name']),
        side: type == 'mockup' ? 'front' : _side,
        type: type,
      );
      final slug = textOf(design['name'], 'design')
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
      if (mounted) {
        await exportPng(
          context,
          bytes,
          '$slug-${type == 'artwork' ? '$_side-print' : 'mockup'}.png',
        );
      }
    } catch (e) {
      if (mounted) notify(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Kicker('Production design inspector'),
              Text(
                textOf(design['name'], 'Data desain'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Tutup',
              onPressed: _busy ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _project == null
            ? Center(
                child: ErrorNotice(_error ?? 'Data desain tidak tersedia.'),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 900) {
                    return Column(
                      children: [
                        Expanded(child: _workbench()),
                        SizedBox(
                          height: 220,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(18),
                            child: Column(children: [_metadata(), _exports()]),
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 220,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: _metadata(),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: _workbench()),
                      const VerticalDivider(width: 1),
                      SizedBox(
                        width: 245,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: _exports(),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    ),
  );
  Widget _metadata() {
    final active = _project!.side(_side);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Kicker('Order'),
        const SizedBox(height: 8),
        Text(
          textOf(order['orderNumber']),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        ...{
          'Customer': object(order['customer'])['name'],
          'Produk': product['name'],
          'Varian': textOf(item['variantName'], '—'),
          'Jumlah': '${item['quantity']} pcs',
          'Area cetak': product['printArea'],
          'Status': widget.production['status'],
        }.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Text(
              '${entry.key}: ${entry.value ?? '—'}',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ),
        const Divider(height: 30),
        const Kicker('File check'),
        const SizedBox(height: 12),
        Text(
          active.enabled ? '● Artwork tersedia' : '● Sisi kosong',
          style: TextStyle(
            color: active.enabled ? green : Colors.orange,
            fontSize: 11,
          ),
        ),
        const Text('● Canvas 2400 × 3000 px', style: TextStyle(fontSize: 11)),
        Text(
          active.logo == null
              ? '● Tanpa logo tambahan'
              : '● Logo raster terpasang',
          style: const TextStyle(fontSize: 11),
        ),
        const Text('● Background transparan', style: TextStyle(fontSize: 11)),
        const SizedBox(height: 18),
        Panel(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Alamat kirim',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              Text(
                textOf(order['shippingAddress']),
                style: const TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _exports() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Kicker('Export produksi'),
      const SizedBox(height: 10),
      const Text(
        'File siap cetak',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      Text(
        'Artwork transparan 2400 × 3000 px untuk sisi ${_side == 'front' ? 'depan' : 'belakang'}.',
        style: const TextStyle(color: muted, fontSize: 11),
      ),
      const SizedBox(height: 14),
      FilledButton.icon(
        onPressed: _busy || !_project!.side(_side).enabled
            ? null
            : () => _export('artwork'),
        icon: const Icon(Icons.download, size: 16),
        label: const Text('Export artwork PNG'),
      ),
      const SizedBox(height: 9),
      OutlinedButton.icon(
        onPressed: _busy ? null : () => _export('mockup'),
        icon: const Icon(Icons.download, size: 16),
        label: const Text('Export mockup'),
      ),
      if (_busy)
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: LinearProgressIndicator(),
        ),
      const SizedBox(height: 22),
      const Panel(
        padding: EdgeInsets.all(12),
        child: Text(
          'Periksa resolusi logo, posisi safe area, warna bahan, dan ukuran cetak aktual sebelum produksi.',
          style: TextStyle(fontSize: 11, color: muted),
        ),
      ),
    ],
  );
  Widget _workbench() => ColoredBox(
    color: const Color(0xffe9ece6),
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          color: Colors.white,
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...{
                'artwork': 'Artwork',
                'product': 'Preview Product',
              }.entries.map(
                (entry) => ChoiceChip(
                  label: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 11),
                  ),
                  selected: _view == entry.key,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _view = entry.key),
                ),
              ),
              if (_view == 'artwork')
                ...{'front': 'Depan', 'back': 'Belakang'}.entries.map(
                  (entry) => ChoiceChip(
                    label: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: _side == entry.key,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _side = entry.key),
                  ),
                ),
              IconButton(
                tooltip: 'Grid dan ruler',
                onPressed: _view == 'artwork'
                    ? () => setState(() => _grid = !_grid)
                    : null,
                isSelected: _grid,
                icon: const Icon(Icons.grid_on, size: 18),
              ),
              IconButton(
                tooltip: 'Perspective view',
                onPressed: () => setState(() => _perspective = !_perspective),
                isSelected: _perspective,
                icon: const Icon(Icons.view_in_ar, size: 20),
              ),
              IconButton(
                tooltip: 'Ukuran 100%',
                onPressed: () => setState(() => _zoom = 100),
                icon: const Icon(Icons.open_in_full, size: 18),
              ),
            ],
          ),
        ),
        Expanded(
          child: CustomPaint(
            painter: _GridPainter(_grid && _view == 'artwork'),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final available = math
                    .min(
                      constraints.maxWidth - 50,
                      (constraints.maxHeight - 45) * .8,
                    )
                    .clamp(1.0, 560.0);
                final width = available * _zoom / 100;
                return Center(
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, .001)
                      ..rotateY(_perspective ? -.23 : 0)
                      ..rotateX(_perspective ? .07 : 0),
                    alignment: Alignment.center,
                    child: Container(
                      width: width,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x25253229),
                            offset: Offset(8, 10),
                            blurRadius: 26,
                          ),
                        ],
                      ),
                      child: _view == 'product'
                          ? AppImage(
                              textOf(design['preview']),
                              fit: BoxFit.contain,
                            )
                          : Stack(
                              children: [
                                DesignPreview(
                                  renderer: _renderer,
                                  project: _project!,
                                  productName: textOf(product['name']),
                                  side: _side,
                                  artworkOnly: true,
                                ),
                                if (_grid)
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _SafeAreaPainter(),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('25%', style: TextStyle(fontSize: 10, color: muted)),
                Expanded(
                  child: Slider(
                    value: _zoom,
                    min: 25,
                    max: 100,
                    onChanged: (v) => setState(() => _zoom = v),
                  ),
                ),
                Text(
                  '${_zoom.round()}%',
                  style: const TextStyle(fontSize: 10, color: muted),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.visible);
  final bool visible;
  @override
  void paint(Canvas canvas, Size size) {
    if (!visible) return;
    final paint = Paint()..color = const Color(0xffaab1a8);
    for (double x = 0; x < size.width; x += 18) {
      for (double y = 0; y < size.height; y += 18) {
        canvas.drawCircle(Offset(x, y), .7, paint);
      }
    }
    for (var i = 0; i <= 6; i++) {
      final text = TextPainter(
        text: TextSpan(
          text: '${i * 5}',
          style: const TextStyle(color: muted, fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(6, 20 + (size.height - 40) * i / 6));
      text.paint(canvas, Offset(30 + (size.width - 60) * i / 6, 5));
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.visible != visible;
}

class _SafeAreaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * .07,
      size.height * .07,
      size.width * .86,
      size.height * .86,
    );
    final paint = Paint()
      ..color = const Color(0x997aa257)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    for (double x = rect.left; x < rect.right; x += 8) {
      canvas.drawLine(
        Offset(x, rect.top),
        Offset(math.min(x + 4, rect.right), rect.top),
        paint,
      );
      canvas.drawLine(
        Offset(x, rect.bottom),
        Offset(math.min(x + 4, rect.right), rect.bottom),
        paint,
      );
    }
    for (double y = rect.top; y < rect.bottom; y += 8) {
      canvas.drawLine(
        Offset(rect.left, y),
        Offset(rect.left, math.min(y + 4, rect.bottom)),
        paint,
      );
      canvas.drawLine(
        Offset(rect.right, y),
        Offset(rect.right, math.min(y + 4, rect.bottom)),
        paint,
      );
    }
    final text = TextPainter(
      text: const TextSpan(
        text: 'SAFE AREA',
        style: TextStyle(color: green, fontSize: 6, letterSpacing: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, rect.topLeft + const Offset(4, 4));
  }

  @override
  bool shouldRepaint(covariant _SafeAreaPainter oldDelegate) => false;
}
