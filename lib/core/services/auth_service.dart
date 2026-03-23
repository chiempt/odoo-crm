import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _urlKey = 'server_url';
  static const String _dbKey = 'database_name';
  static const String _uidKey = 'user_id';
  static const String _nameKey = 'user_name';
  static const String _usernameKey = 'user_username';

  Future<void> saveAuthData({
    required String token,
    required String url,
    required String database,
    int? uid,
    String? name,
    String? username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_urlKey, url);
    await prefs.setString(_dbKey, database);

    if (uid != null) {
      await prefs.setInt(_uidKey, uid);
    }
    if (name != null) {
      await prefs.setString(_nameKey, name);
    }
    if (username != null) {
      await prefs.setString(_usernameKey, username);
    }
  }

  Future<void> saveServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, url);
  }

  Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_urlKey);
  }

  Future<String?> getDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dbKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<int?> getUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_uidKey);
  }

  Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<void> removeAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_uidKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_usernameKey);
    // Keep the default URL and Database so they don't have to be entered next time
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
