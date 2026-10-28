import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../ui/common.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.app, required this.go});
  final AppState app;
  final ValueChanged<String> go;
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      PageHeading(
        'Ringkasan tokomu',
        kicker: 'Creator studio',
        subtitle: 'Pantau performa dan kelola pesanan.',
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
          load: () => app.api.get('/api/dashboard'),
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
                    Metric('Total pesanan', '${data['orders']}'),
                    Metric('Total penjualan', money(data['revenue'])),
                    Metric('Estimasi profit', money(data['profit'])),
                  ],
                ),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Penjualan & profit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 15),
                      SalesChart(rows(data['chart'])),
                    ],
                  ),
                ),
                DataPanel(
                  'Produk terlaris',
                  columns: const ['Produk', 'Terjual'],
                  action: TextButton(
                    onPressed: () => go(
                      '/store/${object(data['store'])['slug'] ?? 'ruang-karya'}',
                    ),
                    child: const Text('Lihat tokomu →'),
                  ),
                  rows: rows(data['best'])
                      .map(
                        (b) => [
                          Text(textOf(b['product'])),
                          Text('${b['sales']}'),
                        ],
                      )
                      .toList(),
                ),
                DataPanel(
                  'Pesanan terbaru',
                  columns: const [
                    'Pesanan',
                    'Tanggal',
                    'Produk',
                    'Status',
                    'Profit',
                  ],
                  rows: rows(data['recent']).map((order) {
                    final items = rows(order['items']);
                    final profit = items.fold<int>(
                      0,
                      (total, item) =>
                          total +
                          (number(item['unitPrice']) -
                                  number(item['baseCost'])) *
                              number(item['quantity']),
                    );
                    return [
                      Text(textOf(order['orderNumber'])),
                      Text(dateLabel(order['createdAt'])),
                      Text(
                        items
                            .map((i) => textOf(object(i['product'])['name']))
                            .join(', '),
                      ),
                      StatusBadge(textOf(order['status'])),
                      Text(money(profit)),
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

class SalesChart extends StatefulWidget {
  const SalesChart(this.data, {super.key});
  final List<Json> data;
  @override
  State<SalesChart> createState() => _SalesChartState();
}

class _SalesChartState extends State<SalesChart> {
  int? _hover;
  @override
  Widget build(BuildContext context) {
    final data = widget.data.toList()
      ..sort((a, b) => textOf(a['date']).compareTo(textOf(b['date'])));
    if (data.isEmpty) {
      return const SizedBox(
        height: 245,
        child: Center(
          child: Text(
            'Grafik akan muncul setelah ada penjualan.',
            style: TextStyle(color: muted),
          ),
        ),
      );
    }
    final index = (_hover ?? data.length - 1).clamp(0, data.length - 1);
    final point = data[index];
    return Column(
      children: [
        Text(
          '${dateLabel(point['date'])}  ·  Penjualan ${money(point['revenue'])}  ·  Profit ${money(point['profit'])}',
          style: const TextStyle(fontSize: 11, color: muted),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 235,
          child: LayoutBuilder(
            builder: (context, size) {
              void select(double x) => setState(
                () => _hover =
                    (((x - 58) / math.max(1, size.maxWidth - 76)) *
                            (data.length - 1))
                        .round()
                        .clamp(0, data.length - 1),
              );
              return Semantics(
                label:
                    'Grafik penjualan dan profit. ${data.length} hari penjualan.',
                child: MouseRegion(
                  onHover: (e) => select(e.localPosition.dx),
                  child: GestureDetector(
                    onTapDown: (e) => select(e.localPosition.dx),
                    onHorizontalDragUpdate: (e) => select(e.localPosition.dx),
                    child: CustomPaint(
                      size: Size(size.maxWidth, 235),
                      painter: _ChartPainter(data, index),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.circle, color: green, size: 9),
            SizedBox(width: 5),
            Text('Penjualan', style: TextStyle(fontSize: 11)),
            SizedBox(width: 18),
            Icon(Icons.circle, color: Color(0xffa5c93d), size: 9),
            SizedBox(width: 5),
            Text('Profit', style: TextStyle(fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.data, this.selected);
  final List<Json> data;
  final int selected;
  void label(
    Canvas canvas,
    String text,
    Offset offset, {
    bool centered = false,
  }) {
    final p = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: muted, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    p.paint(canvas, offset - Offset(centered ? p.width / 2 : 0, 0));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = data
        .fold<int>(
          1,
          (v, r) =>
              math.max(v, math.max(number(r['revenue']), number(r['profit']))),
        )
        .toDouble();
    final area = Rect.fromLTRB(58, 8, size.width - 18, size.height - 28);
    for (var i = 0; i <= 4; i++) {
      final y = area.top + area.height * i / 4;
      canvas.drawLine(
        Offset(area.left, y),
        Offset(area.right, y),
        Paint()..color = line,
      );
      final value = maxValue * (4 - i) / 4;
      label(
        canvas,
        value >= 1000000
            ? '${(value / 1000000).toStringAsFixed(1)}jt'
            : value >= 1000
            ? '${(value / 1000).round()}rb'
            : '${value.round()}',
        Offset(0, y - 5),
      );
    }
    double x(int i) => data.length == 1
        ? area.center.dx
        : area.left + area.width * i / (data.length - 1);
    for (final field in ['revenue', 'profit']) {
      final color = field == 'revenue' ? green : const Color(0xffa5c93d);
      final path = Path();
      for (var i = 0; i < data.length; i++) {
        final point = Offset(
          x(i),
          area.bottom - number(data[i][field]) / maxValue * area.height,
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawCircle(point, i == selected ? 5 : 3, Paint()..color = color);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = color,
      );
    }
    for (var i = 0; i < data.length; i++) {
      if (i == 0 ||
          i == data.length - 1 ||
          i % math.max(1, (data.length / 4).ceil()) == 0) {
        label(
          canvas,
          textOf(data[i]['date']).substring(5),
          Offset(x(i), area.bottom + 9),
          centered: true,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}
