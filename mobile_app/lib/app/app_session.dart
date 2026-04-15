import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/models/app_models.dart';

class AppSession extends ChangeNotifier {
  AppSession(this.apiClient);

  final ApiClient apiClient;

  String? _accessToken;
  UserProfile? _profile;

  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;
  UserProfile? get profile => _profile;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final result = await apiClient.login(username: username, password: password);
    _accessToken = result.token;
    apiClient.accessToken = result.token;
    _profile = result.profile;
    notifyListeners();
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
  }) async {
    final result = await apiClient.register(
      username: username,
      email: email,
      password: password,
      fullName: fullName,
    );
    _accessToken = result.token;
    apiClient.accessToken = result.token;
    _profile = result.profile;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    _profile = await apiClient.fetchProfile();
    notifyListeners();
  }

  Future<void> updateProfile({
    required String fullName,
    required String email,
    required String university,
    required String bio,
  }) async {
    _profile = await apiClient.updateProfile(
      fullName: fullName,
      email: email,
      university: university,
      bio: bio,
    );
    notifyListeners();
  }

  void logout() {
    _accessToken = null;
    _profile = null;
    apiClient.accessToken = null;
    notifyListeners();
  }
}

class AuthPayload {
  const AuthPayload({required this.token, required this.profile});

  final String token;
  final UserProfile profile;
}
