import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../ui/common.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key, required this.app, required this.go});
  final AppState app;
  final ValueChanged<String> go;
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      PageHeading(
        'Lacak pesanan',
        kicker: 'Pesananmu',
        subtitle: 'Perjalanan merchandise dari pembayaran sampai tujuan.',
        action: FilledButton(
          onPressed: () => go('/store/ruang-karya'),
          child: const Text('Lihat toko kreator'),
        ),
      ),
      RoleGate(
        app: app,
        roles: const {'CUSTOMER'},
        child: AsyncData(
          key: ValueKey(app.user?.id),
          load: () => app.api.get('/api/orders'),
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
                    label: const Text('Perbarui status'),
                  ),
                ),
                if (orders.isEmpty)
                  const EmptyState(
                    'Belum ada pesanan. Pilih merchandise dari toko kreator.',
                  )
                else
                  ...orders.map((order) {
                    final items = rows(order['items']);
                    return Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Kicker(textOf(order['orderNumber'])),
                              StatusBadge(textOf(order['status'])),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            items
                                .map(
                                  (item) =>
                                      '${object(item['product'])['name']}${textOf(item['variantName']).isEmpty ? '' : ' · ${item['variantName']}'} × ${item['quantity']}',
                                )
                                .join(', '),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${dateLabel(order['createdAt'])} · ${money(order['total'])}',
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                          const SizedBox(height: 22),
                          OrderProgress(textOf(order['status'])),
                          const SizedBox(height: 16),
                          Text(
                            'Dikirim ke: ${order['shippingAddress']}',
                            style: const TextStyle(color: muted, fontSize: 11),
                          ),
                          ...rows(order['production']).map(
                            (p) => Text(
                              'Partner: ${object(p['partner'])['businessName'] ?? '—'}',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    ],
  );
}

class OrderProgress extends StatelessWidget {
  const OrderProgress(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (var i = 0; i < orderSteps.length; i++)
          Container(
            width: 78,
            margin: const EdgeInsets.only(right: 5),
            child: Column(
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: i <= orderSteps.indexOf(status) ? green : line,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  orderSteps[i],
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: orderSteps[i] == status
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: i <= orderSteps.indexOf(status) ? green : muted,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
