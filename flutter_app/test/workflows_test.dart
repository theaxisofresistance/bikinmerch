import 'dart:convert';
import 'package:bikinmerch/core/models.dart';
import 'package:bikinmerch/main.dart';
import 'package:bikinmerch/pages/admin.dart';
import 'package:bikinmerch/pages/checkout.dart';
import 'package:bikinmerch/pages/dashboard.dart';
import 'package:bikinmerch/pages/designs.dart';
import 'package:bikinmerch/pages/orders.dart';
import 'package:bikinmerch/pages/partner.dart';
import 'package:bikinmerch/pages/store.dart';
import 'package:bikinmerch/studio/inspector.dart';
import 'package:bikinmerch/studio/studio_page.dart';
import 'package:bikinmerch/ui/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fixtures.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> page(
  WidgetTester tester,
  Widget child, {
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      theme: appTheme(),
      home: Scaffold(body: child),
    ),
  );
  await settle(tester);
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('login, role navigation, and logout through the app shell', (
    tester,
  ) async {
    final server = FixtureServer();
    final app = server.state();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(BikinMerchApp(state: app));
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Masuk'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'creator@bikinmerch.id',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'bikinmerch123');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await settle(tester);
    expect(app.user?.role, 'CREATOR');
    expect(find.byType(AuthDialog), findsNothing);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desain Tersimpan'));
    await settle(tester);
    expect(find.byType(DesignsPage), findsOneWidget);
    expect(find.text('Weekend Society'), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar'));
    await settle(tester);
    expect(app.user, null);
    expect(find.text('Mulai dari produk favorit'), findsOneWidget);
    expect(tester.takeException(), null);
  });

  testWidgets(
    'registration exposes only Creator and Customer and submits the selected role',
    (tester) async {
      final server = FixtureServer();
      final app = server.state();
      await page(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showAuth(context, app, register: true),
            child: const Text('Daftar'),
          ),
        ),
      );
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Creator Baru');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'baru@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'bikinmerch123');
      await tester.ensureVisible(find.text('Daftar gratis'));
      await tester.tap(find.text('Daftar gratis'));
      await settle(tester);
      final request = server.requests.firstWhere(
        (r) => r.url.path.endsWith('register'),
      );
      expect(object(jsonDecode(request.body))['role'], 'CREATOR');
      expect(app.user?.role, 'CREATOR');
      expect(tester.takeException(), null);
    },
  );

  testWidgets(
    'publish enforces a margin and protects published designs from deletion',
    (tester) async {
      final server = FixtureServer();
      final app = server.state('CREATOR');
      await page(tester, DesignsPage(app: app, go: (_) {}));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.ensureVisible(find.byTooltip('Publikasikan ke storefront'));
      await tester.tap(find.byTooltip('Publikasikan ke storefront'));
      await settle(tester);
      await tester.enterText(find.byType(TextFormField).at(1), '85000');
      await tester.tap(find.widgetWithText(FilledButton, 'Publikasikan'));
      await tester.pumpAndSettle();
      expect(
        find.text('Harga jual harus lebih tinggi dari harga dasar.'),
        findsOneWidget,
      );
      expect(server.requests.where((r) => r.method == 'POST'), isEmpty);
      await tester.enterText(find.byType(TextFormField).at(1), '100000');
      await tester.tap(find.widgetWithText(FilledButton, 'Publikasikan'));
      await settle(tester);
      expect(server.published, true);
      final deleteButton = tester.widget<IconButton>(
        find.byWidgetPredicate(
          (w) => w is IconButton && w.tooltip == 'Hapus desain',
        ),
      );
      expect(deleteButton.onPressed, null);
      expect(tester.takeException(), null);
    },
  );

  testWidgets(
    'customer checkout validates address and sends the listing contract',
    (tester) async {
      final server = FixtureServer();
      final app = server.state('CUSTOMER');
      await page(
        tester,
        CheckoutDialog(
          app: app,
          product: Product.fromJson(productRecord()),
          title: 'Weekend Society',
          price: 100000,
          storeProductId: 'listing1',
        ),
      );
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.tap(find.text('Bayar sekarang · Mock'));
      await tester.pump();
      expect(find.text('Wajib diisi.'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField),
        'Jl. Merdeka 1, Bandung, 40111',
      );
      await tester.tap(find.text('Bayar sekarang · Mock'));
      await settle(tester);
      final request = server.requests.singleWhere(
        (r) => r.url.path == '/api/orders',
      );
      expect(object(jsonDecode(request.body)), {
        'storeProductId': 'listing1',
        'quantity': 1,
        'shippingAddress': 'Jl. Merdeka 1, Bandung, 40111',
      });
      expect(tester.takeException(), null);
    },
  );

  testWidgets(
    'Creator direct order saves the design before checkout with variant and quantity',
    (tester) async {
      final server = FixtureServer();
      final app = server.state('CREATOR');
      var saved = false;
      await page(
        tester,
        CheckoutDialog(
          app: app,
          product: Product.fromJson(productRecord()),
          title: 'Weekend Society',
          price: 85000,
          saveDesign: () async {
            saved = true;
            return 'd1';
          },
        ),
      );
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.enterText(find.byType(TextFormField).at(0), '3');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Jl. Merdeka 1, Bandung, 40111',
      );
      await tester.tap(find.text('Konfirmasi & pesan'));
      await settle(tester);
      expect(saved, true);
      final request = server.requests.singleWhere(
        (r) => r.url.path == '/api/orders',
      );
      expect(object(jsonDecode(request.body))['designId'], 'd1');
      expect(object(jsonDecode(request.body))['variantId'], 'v1');
      expect(object(jsonDecode(request.body))['quantity'], 3);
      expect(tester.takeException(), null);
    },
  );

  testWidgets('mobile pages for each role render without overflow', (
    tester,
  ) async {
    final server = FixtureServer();
    final creator = server.state('CREATOR'),
        customer = server.state('CUSTOMER'),
        admin = server.state('ADMIN'),
        partner = server.state('PRINT_PARTNER');
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final child in [
      DashboardPage(app: creator, go: (_) {}),
      StorePage(app: customer, slug: 'ruang-karya', go: (_) {}),
      OrdersPage(app: customer, go: (_) {}),
      AdminPage(app: admin),
      PartnerPage(app: partner),
    ]) {
      await page(tester, child);
      expect(tester.takeException(), null);
    }
    await page(tester, DesignsPage(app: customer, go: (_) {}));
    expect(
      find.text('Halaman ini tidak tersedia untuk peran akunmu.'),
      findsOneWidget,
    );
    expect(server.requests.where((r) => r.url.path == '/api/designs'), isEmpty);
  });

  testWidgets(
    'production status updates and design inspection work on a phone',
    (tester) async {
      final server = FixtureServer();
      final app = server.state('PRINT_PARTNER');
      await page(tester, PartnerPage(app: app), width: 1200);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PRINTING').last);
      await settle(tester);
      expect(server.productionStatus, 'PRINTING');
      await tester.tap(find.text('View design'));
      await settle(tester);
      expect(find.byType(DesignInspector), findsOneWidget);
      tester.view.physicalSize = const Size(390, 844);
      await settle(tester);
      expect(find.text('Artwork'), findsOneWidget);
      expect(find.text('Export artwork PNG'), findsOneWidget);
      await tester.tap(find.text('Belakang'));
      await settle(tester);
      expect(find.text('● Sisi kosong'), findsOneWidget);
      expect(tester.takeException(), null);
    },
  );

  testWidgets(
    'studio opens a web design, edits text and keeps the project on save',
    (tester) async {
      final server = FixtureServer();
      final app = server.state('CREATOR');
      await page(
        tester,
        StudioPage(app: app, go: (_) {}, designId: 'd1'),
        width: 1280,
      );
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      expect(find.text('Weekend Society'), findsWidgets);
      final mainText = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Tulisan utama',
      );
      await tester.enterText(mainText, 'KARYA BARU');
      await tester.pump();
      await tester.tap(find.byTooltip('Urungkan'));
      await tester.pump();
      expect(find.text('WEEKEND'), findsOneWidget);
      await tester.tap(find.byTooltip('Ulangi'));
      await tester.pump();
      expect(find.text('KARYA BARU'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Simpan'));
      await settle(tester);
      expect(server.savedDesign?['id'], 'd1');
      expect(
        object(
          object(server.savedDesign?['canvas'])['sides'],
        )['front']['title'],
        'KARYA BARU',
      );
      expect(
        server.savedDesign?['preview'],
        startsWith('data:image/png;base64,'),
      );
      expect(tester.takeException(), null);
      tester.view.physicalSize = const Size(390, 844);
      await settle(tester);
      expect(tester.takeException(), null);
    },
  );
}
