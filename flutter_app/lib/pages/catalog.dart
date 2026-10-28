import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../ui/common.dart';

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key, required this.app, required this.go});
  final AppState app;
  final ValueChanged<String> go;
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      Container(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 650 ? 25 : 55,
        ),
        decoration: BoxDecoration(
          color: const Color(0xffeaf1e7),
          borderRadius: BorderRadius.circular(25),
        ),
        child: LayoutBuilder(
          builder: (context, size) => Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Kicker(
                      'Platform kreator lokal · dibuat di Indonesia',
                    ),
                    const SizedBox(height: 20),
                    Text.rich(
                      const TextSpan(
                        text: 'Karyamu,\njadi ',
                        children: [
                          TextSpan(
                            text: 'merchandise.',
                            style: TextStyle(color: Color(0xff26734e)),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: size.maxWidth < 600 ? 37 : 52,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                        height: 1.06,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Bikin produk custom, buka toko online, dan biarkan kami mengurus produksinya. Tanpa stok, tanpa ribet.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xff58645b),
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: lime,
                            foregroundColor: ink,
                          ),
                          onPressed: () => go('/studio'),
                          label: const Text('Mulai mendesain'),
                          icon: const Icon(Icons.arrow_forward, size: 16),
                        ),
                        OutlinedButton(
                          onPressed: () => go('/store/ruang-karya'),
                          child: const Text('Jelajahi toko kreator'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '✓ Tanpa minimum order     ✓ Produksi lokal',
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              ),
              if (size.maxWidth > 750)
                Expanded(
                  flex: 2,
                  child: Transform.rotate(
                    angle: -.12,
                    child: Container(
                      margin: const EdgeInsets.only(left: 35),
                      decoration: BoxDecoration(
                        color: const Color(0xffd5e9c5),
                        borderRadius: BorderRadius.circular(120),
                      ),
                      child: Image.asset(
                        'assets/studio/shirt.png',
                        height: 280,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 38),
      PageHeading(
        'Mulai dari produk favorit',
        kicker: 'Katalog pilihan',
        subtitle: '${app.products.length} produk · siap kamu kreasikan',
      ),
      if (app.products.isEmpty)
        const EmptyState('Belum ada produk aktif di katalog.')
      else
        FlowGrid(
          minWidth: 210,
          maxColumns: 5,
          children: app.products
              .map((product) => ProductCard(product: product, app: app, go: go))
              .toList(),
        ),
      const SizedBox(height: 40),
      FlowGrid(
        minWidth: 250,
        maxColumns: 3,
        children: const [
          _Feature(
            Icons.palette_outlined,
            '01',
            'Desain sesukamu',
            'Editor simpel untuk bikin artwork, coba komposisi, dan lihat hasilnya.',
          ),
          _Feature(
            Icons.storefront_outlined,
            '02',
            'Buka tokomu',
            'Tentukan margin dan bagikan storefront-mu ke komunitas.',
          ),
          _Feature(
            Icons.local_shipping_outlined,
            '03',
            'Kami produksi',
            'Partner lokal mencetak, cek kualitas, dan kirim ke pembeli.',
          ),
        ],
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: const Color(0xff1d5f43),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Kicker('Untuk kreator Indonesia', color: lime),
            const SizedBox(height: 12),
            const Text(
              'Satu ide, banyak kemungkinan.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Mulai toko tanpa modal stok di muka.',
              style: TextStyle(color: Color(0xffd5e4d9)),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: lime,
                foregroundColor: ink,
              ),
              onPressed: () {
                if (app.user?.role == 'CREATOR') {
                  go('/dashboard');
                } else {
                  showAuth(context, app, register: true);
                }
              },
              child: const Text('Buka tokomu →'),
            ),
          ],
        ),
      ),
    ],
  );
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.app,
    required this.go,
  });
  final Product product;
  final AppState app;
  final ValueChanged<String> go;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: line),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppImage(app.api.imageUrl(product.image), height: 200),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusBadge(product.category),
              const SizedBox(height: 10),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 58,
                child: Text(
                  product.description,
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  Text(
                    money(product.basePrice),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  FilledButton(
                    onPressed: () => go(
                      '/studio?product=${Uri.encodeQueryComponent(product.id)}',
                    ),
                    child: const Text('Desain'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.step, this.title, this.description);
  final IconData icon;
  final String step, title, description;
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: green),
        const SizedBox(height: 15),
        Kicker('Langkah $step'),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(description, style: const TextStyle(color: muted, fontSize: 13)),
      ],
    ),
  );
}
