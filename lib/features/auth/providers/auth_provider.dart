import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository, this._tokenStorage);

  final AuthRepository _repository;
  final TokenStorage _tokenStorage;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _disposed = false;


  VoidCallback? onLoggedOut;

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;


  Future<void> initSession() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      _user = await _repository.getCurrentUser();
      _status = AuthStatus.authenticated;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _clearSession();
        return;
      }

      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _repository.login(
        username: username,
        password: password,
      );
      await _tokenStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      _user = await _repository.getCurrentUser();
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      await _tokenStorage.clear();
      _errorMessage = e.message;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> loadProfile() async {
    try {
      _user = await _repository.getCurrentUser();
      _errorMessage = '';
    } on ApiException catch (e) {
      _errorMessage = e.message;
    }
    notifyListeners();
  }

  Future<void> logout() => _clearSession();

  Future<void> handleSessionExpired() => _clearSession();

  Future<void> _clearSession() async {
    await _tokenStorage.clear();
    _user = null;
    _errorMessage = '';
    _status = AuthStatus.unauthenticated;
    onLoggedOut?.call();
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}