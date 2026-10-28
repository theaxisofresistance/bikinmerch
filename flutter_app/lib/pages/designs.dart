import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../ui/common.dart';

class DesignsPage extends StatelessWidget {
  const DesignsPage({super.key, required this.app, required this.go});
  final AppState app;
  final ValueChanged<String> go;
  Future<void> _publish(
    BuildContext context,
    Json design,
    Future<void> Function() reload,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => PublishDialog(app: app, design: design),
    );
    if (result == true) {
      await reload();
      if (context.mounted) {
        notify(context, 'Produk berhasil dipublikasikan ke storefront.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      PageHeading(
        'Desain tersimpan',
        kicker: 'Creator studio',
        subtitle: 'Edit, lanjutkan, atau hapus desainmu.',
        action: FilledButton.icon(
          onPressed: () => go('/studio'),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Buat desain baru'),
        ),
      ),
      RoleGate(
        app: app,
        roles: const {'CREATOR'},
        child: AsyncData(
          key: ValueKey(app.user?.id),
          load: () => Future.wait([
            app.api.get('/api/designs'),
            app.api.get('/api/store'),
          ]),
          builder: (context, data, reload) {
            final designs = rows(data[0]);
            final store = object(data[1]);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (store['slug'] != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => go('/store/${store['slug']}'),
                      icon: const Icon(Icons.storefront_outlined, size: 16),
                      label: Text(
                        'Lihat toko: bikinmerch.id/@${store['slug']} →',
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                if (designs.isEmpty)
                  EmptyState(
                    'Belum ada desain tersimpan.',
                    action: FilledButton(
                      onPressed: () => go('/studio'),
                      child: const Text('Buat desain pertama'),
                    ),
                  )
                else
                  FlowGrid(
                    maxColumns: 3,
                    children: designs.map((design) {
                      final product = object(design['product']);
                      final listings = rows(design['storeProducts']);
                      final published = listings.isNotEmpty;
                      return Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(color: line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Stack(
                              children: [
                                AppImage(
                                  app.api.imageUrl(
                                    textOf(
                                      design['preview'],
                                      textOf(product['image']),
                                    ),
                                  ),
                                  height: 250,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: StatusBadge(
                                    published ? 'Dipublikasikan' : 'Draft',
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Kicker(textOf(product['name'])),
                                  const SizedBox(height: 8),
                                  Text(
                                    textOf(design['name']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    'Diperbarui ${dateLabel(design['updatedAt'])}',
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 5,
                                    runSpacing: 5,
                                    children: [
                                      IconButton.filledTonal(
                                        tooltip: 'Edit desain',
                                        onPressed: () => go(
                                          '/studio?product=${design['productId']}&design=${design['id']}',
                                        ),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                        ),
                                      ),
                                      IconButton.filledTonal(
                                        tooltip: published
                                            ? 'Perbarui produk'
                                            : 'Publikasikan ke storefront',
                                        onPressed: () =>
                                            _publish(context, design, reload),
                                        icon: const Icon(
                                          Icons.publish_outlined,
                                          size: 18,
                                        ),
                                      ),
                                      IconButton.filledTonal(
                                        tooltip: 'Hapus desain',
                                        onPressed: published
                                            ? null
                                            : () async {
                                                if (!await confirm(
                                                  context,
                                                  'Hapus desain?',
                                                  'Desain “${design['name']}” akan dihapus permanen.',
                                                  label: 'Hapus',
                                                )) {
                                                  return;
                                                }
                                                try {
                                                  await app.api.delete(
                                                    '/api/designs?id=${Uri.encodeQueryComponent(textOf(design['id']))}',
                                                  );
                                                  await reload();
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    notify(
                                                      context,
                                                      e.toString(),
                                                    );
                                                  }
                                                }
                                              },
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Color(0xffb43f3f),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (published)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Desain yang sudah dipublikasikan tidak dapat dihapus.',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: muted,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            );
          },
        ),
      ),
    ],
  );
}

class PublishDialog extends StatefulWidget {
  const PublishDialog({super.key, required this.app, required this.design});
  final AppState app;
  final Json design;
  @override
  State<PublishDialog> createState() => _PublishDialogState();
}

class _PublishDialogState extends State<PublishDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(
    text: textOf(widget.design['name']),
  );
  late final _price = TextEditingController(
    text:
        '${rows(widget.design['storeProducts']).isEmpty ? basePrice + 15000 : rows(widget.design['storeProducts']).first['price']}',
  );
  int get basePrice => number(object(widget.design['product'])['basePrice']);
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.app.api.post('/api/store', {
        'designId': widget.design['id'],
        'title': _title.text.trim(),
        'price': int.parse(_price.text),
      });
      if (mounted) Navigator.pop(context, true);
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
      title: const Text('Publikasikan produk'),
      content: SizedBox(
        width: 390,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Harga dasar ${money(basePrice)}',
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _title,
                  maxLength: 80,
                  enabled: !_busy,
                  validator: requiredText,
                  decoration: const InputDecoration(labelText: 'Nama produk'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _price,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga jual (Rp)',
                  ),
                  validator: (v) => (int.tryParse(v ?? '') ?? 0) > basePrice
                      ? null
                      : 'Harga jual harus lebih tinggi dari harga dasar.',
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder(
                  valueListenable: _price,
                  builder: (_, value, _) => Text(
                    'Estimasi profit: ${money((int.tryParse(value.text) ?? 0) - basePrice)}',
                    style: const TextStyle(color: green),
                  ),
                ),
                if (_error != null) ErrorNotice(_error!),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _busy ? null : submit,
          child: Text(_busy ? 'Memproses…' : 'Publikasikan'),
        ),
      ],
    ),
  );
}
