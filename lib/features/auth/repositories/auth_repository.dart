import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/user_model.dart';

class LoginResult {
  const LoginResult({
    required this.accessToken,
    this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String? refreshToken;
  final User user;
}

class AuthRepository {
  const AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    final json = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.login,
      data: {'username': username, 'password': password},
    );

    final token = json['accessToken'] ?? json['token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException(
        'Unexpected response format.',
        type: ApiErrorType.unexpectedResponse,
      );
    }

    return LoginResult(
      accessToken: token,
      refreshToken: json['refreshToken'] as String?,
      user: User.fromJson(json),
    );
  }


  Future<User> getCurrentUser() async {
    final json = await _apiClient.get<Map<String, dynamic>>(ApiConstants.me);
    return User.fromJson(json);
  }
}