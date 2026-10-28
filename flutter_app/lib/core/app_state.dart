import 'package:flutter/foundation.dart';
import 'api.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  AppState(this.api);
  final Api api;
  AppUser? user;
  List<Product> products = [];
  bool loading = true;
  String? error;
  Future<void> initialize() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await api.restoreSession();
      final result = await Future.wait([
        api.get('/api/auth/me'),
        api.get('/api/products'),
      ]);
      final me = object(result[0])['user'];
      user = me == null ? null : AppUser.fromJson(object(me));
      products = rows(result[1]).map(Product.fromJson).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> authenticate(Json credentials, {required bool register}) async {
    final response = object(
      await api.post(
        '/api/auth/${register ? 'register' : 'login'}',
        credentials,
      ),
    );
    await api.rememberSession(response);
    user = AppUser.fromJson(object(response['user']));
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.delete('/api/auth/me');
    } finally {
      await api.clearSession();
      user = null;
      notifyListeners();
    }
  }

  Future<void> reloadProducts() async {
    products = rows(
      await api.get('/api/products'),
    ).map(Product.fromJson).toList();
    notifyListeners();
  }
}
