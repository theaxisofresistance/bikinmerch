import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../ui/common.dart';
import 'checkout.dart';

class StorePage extends StatelessWidget {
  const StorePage({
    super.key,
    required this.app,
    required this.slug,
    required this.go,
  });
  final AppState app;
  final String slug;
  final ValueChanged<String> go;
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      AsyncData(
        key: ValueKey('store-$slug-${app.user?.id}'),
        load: () => app.api.get(
          '/api/store?username=${Uri.encodeQueryComponent(slug)}',
        ),
        builder: (context, data, reload) {
          final store = object(data);
          final products = rows(store['products']);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  color: const Color(0xffeaf1e7),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Kicker('Storefront kreator'),
                    const SizedBox(height: 14),
                    Text(
                      textOf(store['name']),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      textOf(store['bio']).isEmpty
                          ? 'Koleksi pilihan dari kreator lokal.'
                          : textOf(store['bio']),
                      style: const TextStyle(color: muted),
                    ),
                    const SizedBox(height: 14),
                    SelectableText(
                      'bikinmerch.id/store/${store['slug']}',
                      style: const TextStyle(color: green, fontSize: 12),
                    ),
                    if (object(store['user'])['name'] != null)
                      Text(
                        'Dibuat oleh ${object(store['user'])['name']}',
                        style: const TextStyle(color: muted),
                      ),
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(
                            text: '${app.api.baseUrl}/store/${store['slug']}',
                          ),
                        );
                        if (context.mounted) {
                          notify(context, 'Tautan toko disalin.');
                        }
                      },
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('Salin tautan toko'),
                    ),
                  ],
                ),
              ),
              const PageHeading('Produk dari toko ini', kicker: 'Koleksi'),
              if (products.isEmpty)
                const EmptyState('Toko ini belum mempublikasikan produk.')
              else
                FlowGrid(
                  children: products.map((listing) {
                    final product = Product.fromJson(
                      object(listing['product']),
                    );
                    final preview = textOf(
                      object(listing['design'])['preview'],
                    );
                    return Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppImage(
                            app.api.imageUrl(
                              preview.isEmpty ? product.image : preview,
                            ),
                            height: 240,
                            fit: BoxFit.contain,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StatusBadge(product.name),
                                const SizedBox(height: 10),
                                Text(
                                  textOf(listing['title']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  money(listing['price']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                FilledButton(
                                  onPressed:
                                      app.user != null &&
                                          app.user?.role != 'CUSTOMER'
                                      ? null
                                      : () async {
                                          if (app.user == null &&
                                              !await showAuth(context, app)) {
                                            return;
                                          }
                                          if (!context.mounted) return;
                                          if (app.user?.role != 'CUSTOMER') {
                                            notify(
                                              context,
                                              'Checkout storefront menggunakan akun Customer.',
                                            );
                                            return;
                                          }
                                          final result = await showCheckout(
                                            context,
                                            app,
                                            product: product,
                                            title: textOf(listing['title']),
                                            price: number(listing['price']),
                                            storeProductId: textOf(
                                              listing['id'],
                                            ),
                                          );
                                          if (result != null) go('/orders');
                                        },
                                  child: Text(
                                    app.user != null &&
                                            app.user?.role != 'CUSTOMER'
                                        ? 'Khusus Customer'
                                        : 'Beli sekarang',
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
    ],
  );
}
