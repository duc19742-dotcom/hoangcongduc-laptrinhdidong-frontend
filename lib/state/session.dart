import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class Session extends ChangeNotifier {
  final http.Client? client;
  Session({this.client});
  String? token;
  UserProfile? user;
  bool initializing = true;
  bool rememberLogin = false;
  String? rememberedUsername;
  Future<void> readRemembered() async {
    rememberedUsername = await auth.storage.read(key: 'remembered_username');
  }

  Future<void> resumeRemembered() async {
    final device = await auth.storage.read(key: 'device_token');
    if (device == null) throw const ApiException('Hãy đăng nhập lại.');
    try {
      final r = await api.post('/auth/devices/resume', {'token': device});
      await auth.storage.write(key: 'device_token', value: r['deviceToken']);
      rememberLogin = false;
      await accept(Map<String, dynamic>.from(r['session']));
    } on ApiException catch (e) {
      if (e.status == 401 || e.status == 403) await forgetRemembered();
      rethrow;
    }
  }

  Future<void> forgetRemembered() async {
    final device = await auth.storage.read(key: 'device_token');
    if (device != null) {
      await api.post('/auth/devices/forget', {'token': device});
    }
    await auth.storage.delete(key: 'device_token');
    await auth.storage.delete(key: 'remembered_username');
    rememberedUsername = null;
    notifyListeners();
  }

  late final ApiService api = ApiService(
    () => token,
    () => clear(),
    client: client,
  );
  late final AuthService auth = AuthService(api);
  Future<void> restore() async {
    try {
      await readRemembered();
      token = await auth.storage.read(key: 'access_token');
      if (token != null) user = UserProfile.fromJson(await api.get('/auth/me'));
    } catch (_) {
      token = null;
      user = null;
    } finally {
      initializing = false;
      notifyListeners();
    }
  }

  Future<void> accept(Json response) async {
    token = response['accessToken'];
    user = UserProfile.fromJson(Map<String, dynamic>.from(response['user']));
    await auth.storage.write(key: 'access_token', value: token);
    if (rememberLogin) {
      final saved = await api.post('/auth/devices', {});
      await auth.storage.write(key: 'device_token', value: saved['token']);
      await auth.storage.write(
        key: 'remembered_username',
        value: saved['username'],
      );
      rememberedUsername = saved['username'];
      rememberLogin = false;
    }
    notifyListeners();
  }

  Future<void> clear() async {
    token = null;
    user = null;
    await auth.storage.delete(key: 'access_token');
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.post('/auth/logout', {});
    } finally {
      await clear();
    }
  }
}
