import 'dart:convert';
import 'package:bikinmerch/core/api.dart';
import 'package:bikinmerch/core/app_state.dart';
import 'package:bikinmerch/core/models.dart';
import 'package:bikinmerch/studio/project.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const pixel =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGM4cefEfwAISANsAThpPgAAAABJRU5ErkJggg==';
Json account(String role) => {
  'id': role.toLowerCase(),
  'name': 'Nadia Putri',
  'email': '${role.toLowerCase()}@bikinmerch.id',
  'role': role,
};
Json productRecord([String id = 'p1', String name = 'Classic T-shirt']) => {
  'id': id,
  'name': name,
  'slug': id,
  'category': 'Apparel',
  'description': 'Cotton combed 24s, nyaman untuk harian.',
  'image': pixel,
  'basePrice': 85000,
  'printArea': '28 × 35 cm',
  'active': true,
  'variants': [
    {
      'id': 'v1',
      'name': 'S / Putih',
      'color': '#f4f1eb',
      'size': 'S',
      'stock': 100,
    },
  ],
  '_count': {'variants': 1, 'storeProducts': 1},
};
Json designRecord({bool published = false}) => {
  'id': 'd1',
  'userId': 'creator',
  'productId': 'p1',
  'name': 'Weekend Society',
  'canvas': DesignProject().toJson(),
  'preview': pixel,
  'product': productRecord(),
  'createdAt': '2026-10-28T03:00:00.000Z',
  'updatedAt': '2026-10-28T03:00:00.000Z',
  'storeProducts': published
      ? [
          {
            'id': 'listing1',
            'active': true,
            'title': 'Weekend Society',
            'price': 100000,
          },
        ]
      : [],
};
Json listingRecord() => {
  'id': 'listing1',
  'title': 'Weekend Society',
  'price': 100000,
  'active': true,
  'product': productRecord(),
  'design': designRecord(published: true),
  'storefront': {'slug': 'ruang-karya'},
};
Json storeRecord() => {
  'id': 's1',
  'slug': 'ruang-karya',
  'name': 'Ruang Karya',
  'bio': 'Merch kecil dengan cerita besar.',
  'user': {'name': 'Nadia Putri'},
  'products': [listingRecord()],
};
Json orderRecord([String status = 'PAID']) => {
  'id': 'o1',
  'orderNumber': 'BM-123456789',
  'status': status,
  'total': 100000,
  'shippingAddress': 'Jl. Merdeka 1, Bandung, 40111',
  'createdAt': '2026-10-28T03:00:00.000Z',
  'customer': {'name': 'Dimas Pembeli', 'email': 'customer@bikinmerch.id'},
  'items': [
    {
      'id': 'i1',
      'quantity': 1,
      'unitPrice': 100000,
      'baseCost': 85000,
      'variantName': 'S / Putih',
      'product': productRecord(),
      'storeProduct': listingRecord(),
    },
  ],
  'production': [
    {
      'id': 'po1',
      'status': 'QUEUED',
      'partner': {'businessName': 'Cetak Bandung Studio'},
    },
  ],
};
Json productionRecord() => {
  'id': 'po1',
  'status': 'QUEUED',
  'order': orderRecord(),
  'partner': {'id': 'partner1', 'businessName': 'Cetak Bandung Studio'},
};

class FixtureServer {
  final requests = <http.Request>[];
  bool published = false;
  String productionStatus = 'QUEUED';
  Json? savedDesign;
  late final client = MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    final body = request.body.isEmpty
        ? <String, dynamic>{}
        : object(jsonDecode(request.body));
    dynamic result;
    if (path == '/api/auth/me') {
      result = {'user': null};
    } else if (path == '/api/auth/login' || path == '/api/auth/register') {
      if (body['password'] == 'wrong') {
        return http.Response(
          jsonEncode({'error': 'Email atau kata sandi salah.'}),
          401,
        );
      }
      result = {
        'user': account(body['role'] ?? 'CREATOR'),
        'token': 'test-session',
      };
    } else if (path == '/api/products') {
      result = [productRecord()];
    } else if (path == '/api/designs') {
      if (request.method == 'POST') {
        savedDesign = body;
        result = {'id': 'd1', ...body};
      } else if (request.method == 'DELETE') {
        result = {'ok': true};
      } else {
        result = request.url.queryParameters['id'] == null
            ? [designRecord(published: published)]
            : designRecord();
      }
    } else if (path == '/api/store') {
      if (request.method == 'POST') {
        published = true;
        result = {
          'item': listingRecord(),
          'storefrontUrl': '/store/ruang-karya',
        };
      } else {
        result = storeRecord();
      }
    } else if (path == '/api/orders') {
      result = request.method == 'POST' ? orderRecord() : [orderRecord()];
    } else if (path == '/api/production') {
      if (request.method == 'PATCH') {
        productionStatus = body['status'];
        result = {'id': 'po1', 'status': productionStatus};
      } else {
        result = [
          {...productionRecord(), 'status': productionStatus},
        ];
      }
    } else if (path == '/api/dashboard') {
      result = {
        'orders': 1,
        'revenue': 100000,
        'profit': 15000,
        'store': {'slug': 'ruang-karya'},
        'best': [
          {'product': 'Classic T-shirt', 'sales': 1},
        ],
        'chart': [
          {'date': '2026-10-28', 'revenue': 100000, 'profit': 15000},
        ],
        'recent': [orderRecord()],
      };
    } else if (path == '/api/admin') {
      result = request.method == 'PATCH'
          ? {'ok': true}
          : {
              'users': [account('CREATOR')],
              'products': [productRecord()],
              'orders': [orderRecord()],
              'partners': [
                {
                  'id': 'partner1',
                  'businessName': 'Cetak Bandung Studio',
                  'city': 'Bandung',
                  'capacity': 250,
                  'active': true,
                  'user': {'name': 'Cetak Bandung'},
                },
              ],
            };
    } else {
      return http.Response(
        jsonEncode({'error': 'Endpoint tidak dikenal: $path'}),
        404,
      );
    }
    return http.Response(
      jsonEncode(result),
      200,
      headers: {'content-type': 'application/json'},
    );
  });
  AppState state([String? role]) =>
      AppState(Api(baseUrl: 'http://localhost:3000', client: client))
        ..loading = false
        ..products = [Product.fromJson(productRecord())]
        ..user = role == null ? null : AppUser.fromJson(account(role));
}
