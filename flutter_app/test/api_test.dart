import 'dart:convert';
import 'package:bikinmerch/core/api.dart';
import 'package:bikinmerch/core/app_state.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'native login stores token and restores it for protected API calls',
    () async {
      final requests = <http.Request>[];
      http.Client client() => MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('login')) {
          return http.Response(
            jsonEncode({
              'token': 'signed-session',
              'user': {
                'id': 'u1',
                'name': 'Creator',
                'email': 'creator@bikinmerch.id',
                'role': 'CREATOR',
              },
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });
      final first = Api(
        baseUrl: 'https://api.bikinmerch.id/',
        client: client(),
      );
      final app = AppState(first);
      await app.authenticate({
        'email': 'creator@bikinmerch.id',
        'password': 'password',
      }, register: false);
      expect(app.user?.role, 'CREATOR');
      expect(requests.first.headers['X-Bikinmerch-Client'], 'flutter-native');
      final restored = Api(
        baseUrl: 'https://api.bikinmerch.id',
        client: client(),
      );
      await restored.restoreSession();
      await restored.get('/api/designs');
      expect(requests.last.headers['Authorization'], 'Bearer signed-session');
      await restored.clearSession();
      await restored.get('/api/auth/me');
      expect(requests.last.headers.containsKey('Authorization'), false);
      first.dispose();
      restored.dispose();
      app.dispose();
    },
  );
  test(
    'API preserves server validation errors and handles invalid responses',
    () async {
      final denied = Api(
        baseUrl: 'http://localhost',
        client: MockClient(
          (_) async => http.Response(
            '{"error":"Harga jual harus lebih tinggi dari harga dasar."}',
            400,
          ),
        ),
      );
      await expectLater(
        denied.post('/api/store', {}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Harga jual'),
          ),
        ),
      );
      denied.dispose();
      final invalid = Api(
        baseUrl: 'http://localhost',
        client: MockClient(
          (_) async => http.Response('<html>Bad gateway</html>', 502),
        ),
      );
      await expectLater(
        invalid.get('/api/products'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 502)),
      );
      invalid.dispose();
    },
  );
  test('initial load failure is reported and can be retried', () async {
    var fails = true;
    final api = Api(
      baseUrl: 'http://localhost',
      client: MockClient((request) async {
        if (fails) throw http.ClientException('offline');
        return http.Response(
          request.url.path.endsWith('me') ? '{"user":null}' : '[]',
          200,
        );
      }),
    );
    final app = AppState(api);
    await app.initialize();
    expect(app.loading, false);
    expect(app.error, contains('Tidak dapat terhubung'));
    fails = false;
    await app.initialize();
    expect(app.error, null);
    expect(app.products, isEmpty);
    api.dispose();
    app.dispose();
  });
}
