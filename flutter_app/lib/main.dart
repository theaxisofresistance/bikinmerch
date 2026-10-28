import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/api.dart';
import 'core/app_state.dart';
import 'pages/admin.dart';
import 'pages/catalog.dart';
import 'pages/dashboard.dart';
import 'pages/designs.dart';
import 'pages/orders.dart';
import 'pages/partner.dart';
import 'pages/store.dart';
import 'studio/studio_page.dart';
import 'ui/common.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BikinMerchApp());
}

class BikinMerchApp extends StatefulWidget {
  const BikinMerchApp({super.key, this.state});
  final AppState? state;
  @override
  State<BikinMerchApp> createState() => _BikinMerchAppState();
}

class _BikinMerchAppState extends State<BikinMerchApp> {
  late final app = widget.state ?? AppState(Api());
  @override
  void initState() {
    super.initState();
    if (widget.state == null) app.initialize();
  }

  @override
  void dispose() {
    if (widget.state == null) {
      app.api.dispose();
      app.dispose();
    }
    super.dispose();
  }

  Route<dynamic> _route(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? '/') ?? Uri(path: '/');
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => AppShell(app: app, uri: uri),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BikinMerch',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    locale: const Locale('id', 'ID'),
    supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    onGenerateRoute: _route,
    onGenerateInitialRoutes: (initial) => [
      _route(RouteSettings(name: initial)),
    ],
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.app, required this.uri});
  final AppState app;
  final Uri uri;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _studioKey = GlobalKey<StudioPageState>();
  int _pageRevision = 0;
  AppState get app => widget.app;
  String get path => widget.uri.path;
  Future<void> _go(String route) async {
    if (route == widget.uri.toString()) return;
    if (_studioKey.currentState != null &&
        !await _studioKey.currentState!.allowExit()) {
      return;
    }
    if (!mounted) return;
    if (path == '/studio') {
      await Navigator.pushReplacementNamed(context, route);
    } else {
      await Navigator.pushNamed(context, route);
    }
    if (mounted && path != '/studio') setState(() => _pageRevision++);
  }

  Future<void> _logout() async {
    if (_studioKey.currentState != null &&
        !await _studioKey.currentState!.allowExit()) {
      return;
    }
    try {
      await app.logout();
    } catch (_) {
      if (mounted) notify(context, 'Sesi di perangkat sudah dihapus.');
    }
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  Future<void> _findStore() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Buka toko kreator'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Username atau nama kreator',
            hintText: 'ruang-karya',
          ),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) Navigator.pop(dialog, v.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(dialog, controller.text.trim());
              }
            },
            child: const Text('Buka toko'),
          ),
        ],
      ),
    );
    // Wait for the dialog transition before disposing its text controller.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    if (name != null) _go('/store/${Uri.encodeComponent(name)}');
  }

  List<(String, String, IconData)> get _links => [
    ('/', 'Katalog', Icons.grid_view_outlined),
    if (app.user?.role == 'CUSTOMER')
      ('/orders', 'Pesanan Saya', Icons.local_shipping_outlined)
    else
      ('/studio', 'Studio', Icons.palette_outlined),
    if (app.user?.role == 'CREATOR') ...[
      ('/designs', 'Desain Tersimpan', Icons.folder_outlined),
      ('/dashboard', 'Dashboard', Icons.trending_up),
    ],
    if (app.user?.role == 'PRINT_PARTNER' || app.user?.role == 'ADMIN')
      ('/partner', 'Print Partner', Icons.print_outlined),
    if (app.user?.role == 'ADMIN')
      ('/admin', 'Admin', Icons.admin_panel_settings_outlined),
    ('/store/ruang-karya', 'Toko Kreator', Icons.storefront_outlined),
  ];
  Widget _page() {
    if (path == '/' || path.isEmpty) return CatalogPage(app: app, go: _go);
    if (path == '/studio') {
      return StudioPage(
        key: _studioKey,
        app: app,
        go: _go,
        productId: widget.uri.queryParameters['product'],
        designId: widget.uri.queryParameters['design'],
      );
    }
    if (path == '/designs') return DesignsPage(app: app, go: _go);
    if (path == '/dashboard') return DashboardPage(app: app, go: _go);
    if (path == '/orders') return OrdersPage(app: app, go: _go);
    if (path == '/admin') return AdminPage(app: app);
    if (path == '/partner') return PartnerPage(app: app);
    if (widget.uri.pathSegments.length == 2 &&
        widget.uri.pathSegments.first == 'store') {
      return StorePage(app: app, slug: widget.uri.pathSegments[1], go: _go);
    }
    return PageBody(
      children: [
        EmptyState(
          'Halaman tidak ditemukan.',
          action: FilledButton(
            onPressed: () => _go('/'),
            child: const Text('Kembali ke katalog'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (context, _) {
      final width = MediaQuery.sizeOf(context).width;
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 72,
          titleSpacing: 20,
          title: Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: InkWell(onTap: () => _go('/'), child: const Brand()),
                ),
              ),
              if (width > 1050) ...[
                const SizedBox(width: 28),
                ..._links
                    .take(4)
                    .map(
                      (link) => TextButton(
                        onPressed: () => _go(link.$1),
                        child: Text(
                          link.$2,
                          style: TextStyle(
                            color: path == link.$1 ? green : muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
              ],
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Cari toko kreator',
              onPressed: _findStore,
              icon: const Icon(Icons.search, size: 21),
            ),
            if (app.user == null) ...[
              TextButton(
                onPressed: () => showAuth(context, app),
                child: const Text('Masuk'),
              ),
              if (width > 600)
                FilledButton(
                  onPressed: () => showAuth(context, app, register: true),
                  child: const Text('Mulai gratis'),
                ),
            ] else if (width > 700)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Text(
                    'Halo, ${app.user!.name.split(' ').first}',
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ),
              ),
            PopupMenuButton<String>(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu),
              onSelected: (value) {
                if (value == 'logout') {
                  _logout();
                } else if (value == 'register') {
                  showAuth(context, app, register: true);
                } else {
                  _go(value);
                }
              },
              itemBuilder: (_) => [
                if (app.user != null)
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Text(
                      app.user!.role.replaceAll('_', ' '),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: green,
                      ),
                    ),
                  ),
                ..._links.map(
                  (link) => PopupMenuItem(
                    value: link.$1,
                    child: Row(
                      children: [
                        Icon(link.$3, size: 18, color: green),
                        const SizedBox(width: 12),
                        Text(link.$2),
                      ],
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                if (app.user != null)
                  const PopupMenuItem(value: 'logout', child: Text('Keluar'))
                else
                  const PopupMenuItem(
                    value: 'register',
                    child: Text('Daftar gratis'),
                  ),
              ],
            ),
            const SizedBox(width: 8),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1),
          ),
        ),
        body: SafeArea(
          child: app.loading
              ? const Center(child: CircularProgressIndicator())
              : app.error != null
              ? PageBody(
                  children: [ErrorNotice(app.error!, retry: app.initialize)],
                )
              : KeyedSubtree(key: ValueKey(_pageRevision), child: _page()),
        ),
      );
    },
  );
}
