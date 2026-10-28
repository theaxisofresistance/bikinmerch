import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../ui/common.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.app});
  final AppState app;
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const PageHeading(
        'Admin dashboard',
        kicker: 'BikinMerch operations',
        subtitle: 'Ringkasan platform dan operasional.',
      ),
      RoleGate(
        app: app,
        roles: const {'ADMIN'},
        child: AsyncData(
          key: ValueKey(app.user?.id),
          load: () => app.api.get('/api/admin'),
          builder: (context, raw, reload) {
            final data = object(raw);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: reload,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Perbarui'),
                  ),
                ),
                FlowGrid(
                  maxColumns: 3,
                  children: [
                    Metric('Pengguna', '${rows(data['users']).length}'),
                    Metric(
                      'Produk katalog',
                      '${rows(data['products']).length}',
                    ),
                    Metric('Pesanan', '${rows(data['orders']).length}'),
                  ],
                ),
                DataPanel(
                  'Produk katalog',
                  columns: const [
                    'Produk',
                    'Kategori',
                    'Harga dasar',
                    'Varian',
                    'Status',
                    'Aksi',
                  ],
                  rows: rows(data['products'])
                      .map(
                        (p) => [
                          Text(textOf(p['name'])),
                          Text(textOf(p['category'])),
                          Text(money(p['basePrice'])),
                          Text('${object(p['_count'])['variants']}'),
                          StatusBadge(
                            p['active'] == true ? 'Aktif' : 'Nonaktif',
                          ),
                          _Toggle(
                            app: app,
                            kind: 'product',
                            record: p,
                            reload: reload,
                          ),
                        ],
                      )
                      .toList(),
                ),
                DataPanel(
                  'Pesanan terbaru',
                  columns: const ['Order', 'Pembeli', 'Nilai', 'Status'],
                  rows: rows(data['orders'])
                      .map(
                        (order) => [
                          Text(textOf(order['orderNumber'])),
                          Text(textOf(object(order['customer'])['name'])),
                          Text(money(order['total'])),
                          StatusBadge(textOf(order['status'])),
                        ],
                      )
                      .toList(),
                ),
                DataPanel(
                  'Print partner',
                  columns: const [
                    'Bisnis',
                    'Kontak',
                    'Kota',
                    'Kapasitas',
                    'Status',
                    'Aksi',
                  ],
                  rows: rows(data['partners'])
                      .map(
                        (p) => [
                          Text(textOf(p['businessName'])),
                          Text(textOf(object(p['user'])['name'])),
                          Text(textOf(p['city'])),
                          Text('${p['capacity']}'),
                          StatusBadge(
                            p['active'] == true ? 'Aktif' : 'Nonaktif',
                          ),
                          _Toggle(
                            app: app,
                            kind: 'partner',
                            record: p,
                            reload: reload,
                          ),
                        ],
                      )
                      .toList(),
                ),
                DataPanel(
                  'Pengguna',
                  columns: const ['Nama', 'Email', 'Role', 'Bergabung'],
                  rows: rows(data['users'])
                      .map(
                        (user) => [
                          Text(textOf(user['name'])),
                          Text(textOf(user['email'])),
                          StatusBadge(textOf(user['role'])),
                          Text(dateLabel(user['createdAt'])),
                        ],
                      )
                      .toList(),
                ),
              ],
            );
          },
        ),
      ),
    ],
  );
}

class _Toggle extends StatefulWidget {
  const _Toggle({
    required this.app,
    required this.kind,
    required this.record,
    required this.reload,
  });
  final AppState app;
  final String kind;
  final Json record;
  final Future<void> Function() reload;
  @override
  State<_Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<_Toggle> {
  bool _busy = false;
  Future<void> toggle() async {
    setState(() => _busy = true);
    try {
      await widget.app.api.patch('/api/admin', {
        'kind': widget.kind,
        'id': widget.record['id'],
        'active': widget.record['active'] != true,
      });
      await widget.reload();
      if (widget.kind == 'product') await widget.app.reloadProducts();
    } catch (e) {
      if (mounted) notify(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: _busy ? null : toggle,
    child: Text(
      _busy
          ? 'Memproses…'
          : widget.record['active'] == true
          ? 'Nonaktifkan'
          : 'Aktifkan',
    ),
  );
}
