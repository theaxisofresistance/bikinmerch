import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../studio/inspector.dart';
import '../ui/common.dart';

class PartnerPage extends StatelessWidget {
  const PartnerPage({super.key, required this.app});
  final AppState app;
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const PageHeading(
        'Antrean produksi',
        kicker: 'Print partner portal',
        subtitle:
            'Periksa file desain, export artwork, dan perbarui tahap produksi.',
      ),
      RoleGate(
        app: app,
        roles: const {'PRINT_PARTNER', 'ADMIN'},
        child: AsyncData(
          key: ValueKey(app.user?.id),
          load: () => app.api.get('/api/production'),
          builder: (context, data, reload) {
            final orders = rows(data);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: reload,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Perbarui antrean'),
                  ),
                ),
                if (orders.isEmpty)
                  const EmptyState('Belum ada order produksi.')
                else
                  DataPanel(
                    'Order produksi',
                    columns: const [
                      'Order',
                      'Customer',
                      'Produk & varian',
                      'Desain',
                      'Status produksi',
                    ],
                    rows: orders.map((production) {
                      final order = object(production['order']);
                      final items = rows(order['items']);
                      final item = items.isEmpty
                          ? <String, dynamic>{}
                          : items.first;
                      return [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(textOf(order['orderNumber'])),
                            Text(
                              '${item['quantity'] ?? 1} pcs',
                              style: const TextStyle(
                                fontSize: 10,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                        Text(textOf(object(order['customer'])['name'])),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(textOf(object(item['product'])['name'])),
                            Text(
                              textOf(item['variantName'], 'Varian standar'),
                              style: const TextStyle(
                                fontSize: 10,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => showDialog<void>(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) =>
                                DesignInspector(production: production),
                          ),
                          child: const Text('View design'),
                        ),
                        ProductionStatus(
                          app: app,
                          production: production,
                          reload: reload,
                        ),
                      ];
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

class ProductionStatus extends StatefulWidget {
  const ProductionStatus({
    super.key,
    required this.app,
    required this.production,
    required this.reload,
  });
  final AppState app;
  final Json production;
  final Future<void> Function() reload;
  @override
  State<ProductionStatus> createState() => _ProductionStatusState();
}

class _ProductionStatusState extends State<ProductionStatus> {
  bool _busy = false;
  Future<void> _change(String? status) async {
    if (status == null) return;
    setState(() => _busy = true);
    try {
      await widget.app.api.patch('/api/production', {
        'id': widget.production['id'],
        'status': status,
      });
      await widget.reload();
    } catch (e) {
      if (mounted) notify(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => DropdownButton<String>(
    value: textOf(widget.production['status']),
    items: productionSteps
        .map(
          (s) => DropdownMenuItem(
            value: s,
            child: Text(s, style: const TextStyle(fontSize: 11)),
          ),
        )
        .toList(),
    onChanged: _busy ? null : _change,
  );
}
