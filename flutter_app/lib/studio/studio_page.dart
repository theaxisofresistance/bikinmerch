import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../pages/checkout.dart';
import '../ui/common.dart';
import 'export_file.dart' if (dart.library.js_interop) 'export_file_web.dart';
import 'project.dart';
import 'renderer.dart';
import 'unsaved_guard.dart'
    if (dart.library.js_interop) 'unsaved_guard_web.dart';

class StudioPage extends StatefulWidget {
  const StudioPage({
    super.key,
    required this.app,
    required this.go,
    this.productId,
    this.designId,
  });
  final AppState app;
  final ValueChanged<String> go;
  final String? productId, designId;
  @override
  State<StudioPage> createState() => StudioPageState();
}

class StudioPageState extends State<StudioPage> {
  final _editor = StudioController();
  final _renderer = StudioRenderer();
  late final VoidCallback _removeGuard;
  Product? _product;
  String _category = 'Semua';
  String? _error;
  bool _loading = true, _busy = false, _ready = false;
  bool _popAllowed = false;
  String? _loadedForUser;
  AppState get app => widget.app;
  DesignProject get project => _editor.project;
  DesignSide get side => project.active;
  @override
  void initState() {
    super.initState();
    _product = _findProduct(widget.productId);
    _editor.addListener(_changed);
    _removeGuard = watchUnsavedChanges(() => _editor.dirty);
    _initialize();
  }

  Product? _findProduct(String? id) {
    for (final product in app.products) {
      if (product.id == id) return product;
    }
    for (final product in app.products) {
      if (product.name.toLowerCase().contains('t-shirt')) return product;
    }
    return app.products.isEmpty ? null : app.products.first;
  }

  @override
  void didUpdateWidget(covariant StudioPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.designId != null && app.user?.id != _loadedForUser) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _renderer.load();
      if (widget.designId != null && app.user != null) {
        final data = object(
          await app.api.get(
            '/api/designs?id=${Uri.encodeQueryComponent(widget.designId!)}',
          ),
        );
        final loaded = DesignProject.fromJson(object(data['canvas']));
        await _renderer.prepare(loaded);
        if (!mounted) return;
        _product =
            app.products.where((p) => p.id == data['productId']).firstOrNull ??
            Product.fromJson(object(data['product']));
        _editor.load(
          loaded,
          id: textOf(data['id']),
          title: textOf(data['name']),
        );
        _loadedForUser = app.user?.id;
      }
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _removeGuard();
    _editor.removeListener(_changed);
    _editor.dispose();
    _renderer.dispose();
    super.dispose();
  }

  Future<bool> allowExit() async {
    if (_busy) return false;
    if (!_editor.dirty) return true;
    return confirm(
      context,
      'Tinggalkan studio?',
      'Perubahan desain belum disimpan.',
      label: 'Tinggalkan',
    );
  }

  void _mutate(void Function(DesignProject) change) => _editor.mutate(change);
  String get _localKey =>
      'merch-studio-project-${app.user?.id ?? 'guest'}-${_product?.id}';
  Future<String?> save() async {
    if (app.user == null) {
      if (!await showAuth(context, app)) return null;
      if (!mounted) return null;
    }
    if (app.user?.role != 'CREATOR') {
      notify(context, 'Masuk dengan akun Creator untuk menyimpan desain.');
      return null;
    }
    if (_product == null) {
      notify(context, 'Produk belum tersedia.');
      return null;
    }
    if (_editor.name.trim().isEmpty || _editor.name.trim().length > 80) {
      notify(context, 'Nama desain wajib diisi dan maksimal 80 karakter.');
      return null;
    }
    final snapshot = project.copy(), revision = _editor.revision;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview = await _renderer.preview(snapshot, _product!.name);
      final response = object(
        await app.api.post('/api/designs', {
          if (_editor.savedId != null) 'id': _editor.savedId,
          'productId': _product!.id,
          'name': _editor.name.trim(),
          'canvas': snapshot.toJson(),
          'preview': preview,
        }),
      );
      _editor.markSaved(textOf(response['id']), revision);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_localKey, jsonEncode(snapshot.toJson()));
      if (mounted) notify(context, '${_editor.name} berhasil disimpan.');
      return textOf(response['id']);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        notify(context, e.toString());
      }
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openLocal() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_localKey);
      if (raw == null) {
        if (mounted) {
          notify(
            context,
            'Belum ada desain produk ini tersimpan di perangkat.',
          );
        }
        return;
      }
      final loaded = DesignProject.fromJson(object(jsonDecode(raw)));
      await _renderer.prepare(loaded);
      if (!mounted) return;
      _mutate((p) {
        p.fit = loaded.fit;
        p.shirt = loaded.shirt;
        p.activeSide = loaded.activeSide;
        p.front = loaded.front;
        p.back = loaded.back;
      });
      notify(context, 'Versi perangkat berhasil dibuka.');
    } catch (e) {
      if (mounted) notify(context, 'Desain tersimpan tidak dapat dibuka: $e');
    }
  }

  Future<void> _upload() async {
    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Gambar',
            extensions: ['png', 'jpg', 'jpeg', 'webp'],
            mimeTypes: ['image/png', 'image/jpeg', 'image/webp'],
            uniformTypeIdentifiers: [
              'public.png',
              'public.jpeg',
              'org.webmproject.webp',
            ],
          ),
        ],
      );
      if (file == null) return;
      final extension = file.name.split('.').last.toLowerCase();
      if (!['png', 'jpg', 'jpeg', 'webp'].contains(extension) ||
          await file.length() > 4 * 1024 * 1024) {
        if (mounted) {
          notify(context, 'Pilih PNG, JPG, atau WebP maksimal 4 MB.');
        }
        return;
      }
      final bytes = await file.readAsBytes();
      final source =
          'data:image/${extension == 'jpg' ? 'jpeg' : extension};base64,${base64Encode(bytes)}';
      final candidate = project.copy()..active.logo = source;
      await _renderer.prepare(candidate);
      if (mounted) _mutate((p) => p.active.logo = source);
    } catch (e) {
      if (mounted) {
        notify(context, 'Gambar gagal dibuka. Pilih berkas gambar yang valid.');
      }
    }
  }

  Future<void> _order() async {
    if (_product == null) return;
    if (app.user == null && !await showAuth(context, app)) return;
    if (!mounted) return;
    if (app.user?.role != 'CREATOR') {
      notify(context, 'Pemesanan dari Studio khusus akun Creator.');
      return;
    }
    final order = await showCheckout(
      context,
      app,
      product: _product!,
      title: _editor.name,
      price: _product!.basePrice,
      saveDesign: save,
    );
    if (order != null && mounted) {
      notify(context, 'Pesanan masuk ke antrean produksi.');
      widget.go('/dashboard');
    }
  }

  Future<void> _downloads() async {
    if (_product == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => ExportDialog(
        renderer: _renderer,
        project: project.copy(),
        productName: _product!.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (app.user?.role == 'CUSTOMER') {
      return PageBody(
        children: [
          EmptyState(
            'Studio hanya dapat diakses oleh Creator. Pilih merchandise dari toko kreator.',
            action: FilledButton(
              onPressed: () => widget.go('/store/ruang-karya'),
              child: const Text('Lihat toko kreator'),
            ),
          ),
        ],
      );
    }
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (!_ready || _product == null) {
      return PageBody(
        children: [
          ErrorNotice(_error ?? 'Produk belum tersedia.', retry: _initialize),
        ],
      );
    }
    return PopScope(
      canPop: !_editor.dirty || _popAllowed,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && await allowExit() && mounted) {
          setState(() => _popAllowed = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pop(context);
          });
        }
      },
      child: Column(
        children: [
          if (_error != null) ErrorNotice(_error!),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: AbsorbPointer(
              absorbing: _busy,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 900) {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _workspace(mobile: true),
                          Padding(
                            padding: const EdgeInsets.all(22),
                            child: _sidebar(),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(22),
                            child: _controls(),
                          ),
                        ],
                      ),
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: constraints.maxWidth > 1200 ? 280 : 240,
                        child: ColoredBox(
                          color: Colors.white,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(22),
                            child: _sidebar(),
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: _workspace()),
                      const VerticalDivider(width: 1),
                      SizedBox(
                        width: constraints.maxWidth > 1200 ? 300 : 260,
                        child: ColoredBox(
                          color: Colors.white,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(22),
                            child: _controls(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebar() {
    final colors = <String, String>{};
    for (final variant in _product!.variants) {
      colors[textOf(variant['color'])] = textOf(
        variant['name'],
      ).split('/').last.trim();
    }
    if (colors.isEmpty) {
      for (final color in shirtColors) {
        colors[color[0]] = color[1];
      }
    }
    final filtered = templates.where(
      (t) => _category == 'Semua' || t.category == _category,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Kicker('Mulai dari yang lo suka'),
        const SizedBox(height: 10),
        const Text(
          'Ide lo. Kaos lo.',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        const Text(
          'Pilih desain, bikin jadi punya lo.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 28),
        const Kicker('01 / Produk'),
        const SizedBox(height: 10),
        const Text(
          'Pilih merchandise',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...app.products.map(
          (p) => Container(
            margin: const EdgeInsets.only(bottom: 7),
            decoration: BoxDecoration(
              color: p.id == _product?.id ? const Color(0xfff0f6e2) : paper,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: p.id == _product?.id
                    ? const Color(0xff7e9e3e)
                    : Colors.transparent,
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 7),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: AppImage(
                    app.api.imageUrl(p.image),
                    width: 42,
                    height: 42,
                  ),
                ),
                title: Text(
                  p.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${p.category} · ${money(p.basePrice)}',
                  style: const TextStyle(fontSize: 9, color: muted),
                ),
                onTap: () async {
                  if (p.id == _product?.id) return;
                  if (!await allowExit() || !mounted) return;
                  setState(() {
                    _product = p;
                    _editor.savedId = null;
                  });
                  _editor.rename('Desain ${p.name}');
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Kicker('02 / Varian'),
        const SizedBox(height: 10),
        Text(
          _product!.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        if (_product!.name.toLowerCase().contains('t-shirt')) ...[
          const SizedBox(height: 12),
          _segments(
            {'regular': 'Regular', 'oversized': 'Oversized'},
            project.fit,
            (value) => _mutate((p) => p.fit = value),
          ),
        ],
        const SizedBox(height: 15),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.entries
              .map(
                (color) => _swatch(
                  color.key,
                  color.value,
                  project.shirt == color.key,
                  () => _mutate((p) => p.shirt = color.key),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        Text(
          'Area cetak: ${_product!.printArea}',
          style: const TextStyle(fontSize: 11, color: muted),
        ),
        const Text(
          'Warna berlaku untuk sisi depan dan belakang.',
          style: TextStyle(fontSize: 10, color: muted),
        ),
        const SizedBox(height: 28),
        const Kicker('03 / Template desain'),
        const SizedBox(height: 10),
        const Text(
          'Pilih gaya lo',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
        Text(
          'Untuk sisi ${project.activeSide == 'front' ? 'depan' : 'belakang'}',
          style: const TextStyle(color: muted, fontSize: 11),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 5,
          children: ['Semua', 'Komunitas', 'Event', 'Brand', 'Personal']
              .map(
                (category) => ChoiceChip(
                  label: Text(category, style: const TextStyle(fontSize: 10)),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        FlowGrid(
          minWidth: 95,
          maxColumns: 3,
          children: filtered
              .map(
                (template) => InkWell(
                  onTap: () => _mutate((p) => p.active.apply(template)),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: side.enabled && side.template == template.id
                            ? green
                            : line,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ColoredBox(
                          color: hex(template.background),
                          child: DesignPreview(
                            renderer: _renderer,
                            project: DesignProject(
                              front: DesignSide()..apply(template),
                            ),
                            productName: _product!.name,
                            side: 'front',
                            artworkOnly: true,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          template.name,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          template.category,
                          style: const TextStyle(fontSize: 9, color: muted),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _openLocal,
          icon: const Icon(Icons.history, size: 15),
          label: Text(kIsWeb ? 'Buka versi browser' : 'Buka versi perangkat'),
        ),
        TextButton(
          onPressed: () => widget.go('/designs'),
          child: const Text(
            'Lihat semua desain tersimpan →',
            style: TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _workspace({bool mobile = false}) {
    final preview = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: mobile ? 420 : 600,
          maxHeight: mobile ? 420 : double.infinity,
        ),
        child: DesignPreview(
          renderer: _renderer,
          project: project,
          productName: _product!.name,
        ),
      ),
    );
    final toolbar = Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: line)),
      ),
      child: Column(
        children: [
          DesignTextField(
            value: _editor.name,
            label: 'Nama desain',
            maxLength: 80,
            onChanged: _editor.rename,
            compact: true,
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 3,
            runSpacing: 5,
            children: [
              IconButton(
                tooltip: 'Urungkan',
                onPressed: _editor.canUndo ? _editor.undo : null,
                icon: const Icon(Icons.undo, size: 19),
              ),
              IconButton(
                tooltip: 'Ulangi',
                onPressed: _editor.canRedo ? _editor.redo : null,
                icon: const Icon(Icons.redo, size: 19),
              ),
              TextButton.icon(
                onPressed: save,
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('Simpan'),
              ),
              TextButton.icon(
                onPressed: _order,
                icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                label: const Text('Pesan'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: lime,
                  foregroundColor: ink,
                ),
                onPressed: _downloads,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Download'),
              ),
            ],
          ),
        ],
      ),
    );
    final content = [
      toolbar,
      const SizedBox(height: 15),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: _segments(
          {
            'front':
                'Depan${project.front.enabled ? ' · Ada desain' : ' · Kosong'}',
            'back':
                'Belakang${project.back.enabled ? ' · Ada desain' : ' · Kosong'}',
          },
          project.activeSide,
          _editor.selectSide,
        ),
      ),
      if (mobile)
        preview
      else
        Expanded(
          child: Padding(padding: const EdgeInsets.all(20), child: preview),
        ),
      Padding(
        padding: const EdgeInsets.all(15),
        child: Text(
          '${project.activeSide == 'front' ? 'DEPAN' : 'BELAKANG'} · MOCKUP\n${_editor.dirty
              ? 'Ada perubahan'
              : _editor.savedId == null
              ? 'Belum disimpan'
              : 'Tersimpan di akun'}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: muted, height: 1.8),
        ),
      ),
    ];
    return ColoredBox(
      color: const Color(0xfff0f2ea),
      child: Column(
        mainAxisSize: mobile ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: content,
      ),
    );
  }

  Widget _controls() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Kicker('Bikin jadi punya lo'),
      const SizedBox(height: 10),
      Text(
        'Desain ${project.activeSide == 'front' ? 'depan' : 'belakang'}',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: side.enabled
              ? () => _mutate((p) => p.active.enabled = false)
              : null,
          child: const Text(
            'Kosongkan sisi ini',
            style: TextStyle(fontSize: 11),
          ),
        ),
      ),
      if (!side.enabled)
        const EmptyState(
          'Sisi ini masih kosong. Pilih template desain di galeri untuk mulai.',
          icon: Icons.add,
        )
      else ...[
        const Divider(height: 30),
        const Text(
          '② Tulis cerita lo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 15),
        DesignTextField(
          value: side.title,
          label: 'Tulisan utama',
          maxLength: 30,
          onChanged: (v) => _mutate((p) => p.active.title = v),
        ),
        const SizedBox(height: 14),
        DesignTextField(
          value: side.subtitle,
          label: 'Tulisan kedua',
          maxLength: 40,
          onChanged: (v) => _mutate((p) => p.active.subtitle = v),
        ),
        const SizedBox(height: 14),
        DesignTextField(
          value: side.detail,
          label: 'Detail kecil',
          maxLength: 65,
          onChanged: (v) => _mutate((p) => p.active.detail = v),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          key: ValueKey('${project.activeSide}-${side.font}'),
          initialValue: side.font,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Gaya huruf'),
          items: const [
            DropdownMenuItem(value: 'condensed', child: Text('Bold & compact')),
            DropdownMenuItem(value: 'sans', child: Text('Clean & modern')),
            DropdownMenuItem(
              value: 'serif',
              child: Text('Classic & editorial'),
            ),
          ],
          onChanged: (v) {
            if (v != null) _mutate((p) => p.active.font = v);
          },
        ),
        const SizedBox(height: 18),
        const Text('Warna desain', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: palettes
              .map(
                (palette) => Tooltip(
                  message: '${palette[0]} / ${palette[1]}',
                  child: InkWell(
                    onTap: () => _mutate((p) {
                      p.active.ink = palette[0];
                      p.active.accent = palette[1];
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: side.ink == palette[0] ? green : line,
                        ),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 18,
                            height: 24,
                            color: hex(palette[0]),
                          ),
                          Container(
                            width: 18,
                            height: 24,
                            color: hex(palette[1]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const Divider(height: 38),
        const Text(
          '③ Atur tampilannya',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 15),
        _segments(
          {'chest': 'Dada kecil', 'center': 'Tengah', 'large': 'Besar'},
          side.position,
          (v) => _mutate((p) => p.active.position = v),
        ),
        const SizedBox(height: 18),
        Text(
          'Ukuran desain    ${side.scale}%',
          style: const TextStyle(fontSize: 12),
        ),
        Slider(
          value: side.scale.toDouble(),
          min: 60,
          max: 120,
          divisions: 12,
          label: '${side.scale}%',
          onChanged: (v) => _mutate((p) => p.active.scale = v.round()),
        ),
        OutlinedButton.icon(
          onPressed: _upload,
          icon: const Icon(Icons.add_photo_alternate_outlined, size: 17),
          label: Text(
            side.logo == null
                ? 'Tambahkan gambar / logo'
                : 'Ganti gambar / logo',
            style: const TextStyle(fontSize: 11),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'PNG, JPG, atau WebP · maks. 4 MB.\nPNG transparan cocok untuk logo.',
          style: TextStyle(color: muted, fontSize: 10),
        ),
        if (side.logo != null)
          TextButton(
            onPressed: () => _mutate((p) => p.active.logo = null),
            child: const Text('Hapus gambar'),
          ),
      ],
    ],
  );
  Widget _segments(
    Map<String, String> values,
    String selected,
    ValueChanged<String> changed,
  ) => Wrap(
    spacing: 5,
    runSpacing: 5,
    children: values.entries
        .map(
          (value) => ChoiceChip(
            label: Text(value.value, style: const TextStyle(fontSize: 11)),
            selected: selected == value.key,
            showCheckmark: false,
            onSelected: (_) => changed(value.key),
          ),
        )
        .toList(),
  );
  Widget _swatch(String color, String label, bool selected, VoidCallback tap) =>
      Tooltip(
        message: label,
        child: Semantics(
          label: label,
          selected: selected,
          child: InkWell(
            onTap: tap,
            borderRadius: BorderRadius.circular(25),
            child: Container(
              width: 33,
              height: 33,
              decoration: BoxDecoration(
                color: hex(color),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? green : line,
                  width: selected ? 3 : 1,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 16, color: green)
                  : null,
            ),
          ),
        ),
      );
}

class DesignTextField extends StatefulWidget {
  const DesignTextField({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.maxLength,
    this.compact = false,
  });
  final String value, label;
  final ValueChanged<String> onChanged;
  final int? maxLength;
  final bool compact;
  @override
  State<DesignTextField> createState() => _DesignTextFieldState();
}

class _DesignTextFieldState extends State<DesignTextField> {
  late final _controller = TextEditingController(text: widget.value);
  @override
  void didUpdateWidget(covariant DesignTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    maxLength: widget.maxLength,
    onChanged: widget.onChanged,
    style: const TextStyle(fontSize: 13),
    decoration: InputDecoration(
      labelText: widget.label,
      counterText: '',
      contentPadding: EdgeInsets.all(widget.compact ? 10 : 14),
    ),
  );
}

class ExportDialog extends StatefulWidget {
  const ExportDialog({
    super.key,
    required this.renderer,
    required this.project,
    required this.productName,
  });
  final StudioRenderer renderer;
  final DesignProject project;
  final String productName;
  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  late String _side = widget.project.activeSide;
  bool _busy = false;
  String? _error;
  Future<void> _export(String type) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes = await widget.renderer.export(
        widget.project,
        widget.productName,
        side: _side,
        type: type,
      );
      if (mounted) {
        await exportPng(
          context,
          bytes,
          'bikinmerch-${type == 'artwork' ? 'desain' : 'mockup'}-${type == 'combined' ? 'depan-belakang' : _side}.png',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Download desain')),
          IconButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Download desain per sisi atau satu produk lengkap.',
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _side,
                decoration: const InputDecoration(
                  labelText: 'Sisi yang diunduh',
                ),
                items: const [
                  DropdownMenuItem(value: 'front', child: Text('Depan')),
                  DropdownMenuItem(value: 'back', child: Text('Belakang')),
                ],
                onChanged: _busy ? null : (v) => setState(() => _side = v!),
              ),
              const SizedBox(height: 16),
              _option(
                'Desain transparan ↗',
                'PNG · 2400 × 3000 px · tanpa produk',
                'artwork',
                enabled: widget.project.side(_side).enabled,
              ),
              _option(
                'Mockup produk ↗',
                'PNG · 1000 × 1100 px · preview',
                'mockup',
              ),
              _option(
                'Mockup depan + belakang ↗',
                'PNG · 2000 × 1100 px · dua sisi',
                'combined',
              ),
              const SizedBox(height: 16),
              const Text(
                'Untuk produksi, konfirmasi ukuran dan resolusi ke vendor cetak. Mockup hanya perkiraan tampilan.',
                style: TextStyle(color: muted, fontSize: 11),
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: LinearProgressIndicator(),
                ),
              if (_error != null) ErrorNotice(_error!),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _option(
    String title,
    String subtitle,
    String type, {
    bool enabled = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: OutlinedButton(
      onPressed: _busy || !enabled ? null : () => _export(type),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(subtitle, style: const TextStyle(color: muted, fontSize: 10)),
          ],
        ),
      ),
    ),
  );
}
