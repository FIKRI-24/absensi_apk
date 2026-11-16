import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/app_exception.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final UserModel? user;
  final String? token;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.token,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserModel? user,
    String? token,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
    bool clearToken = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      token: clearToken ? null : (token ?? this.token),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final DioClient _dioClient;
  final FlutterSecureStorage _storage;

  AuthNotifier({
    required DioClient dioClient,
    required FlutterSecureStorage storage,
  })  : _dioClient = dioClient,
        _storage = storage,
        super(const AuthState()) {
    _checkInitialAuthState();
  }

  Future<void> _checkInitialAuthState() async {
    final token = await _storage.read(key: ApiConstants.tokenKey);
    if (token != null && token.isNotEmpty) {
      state = state.copyWith(isAuthenticated: true, token: token);
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final loginResponse = await _dioClient.login(username, password);
      await _storage.write(
        key: ApiConstants.tokenKey,
        value: loginResponse.token,
      );
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: loginResponse.user,
        token: loginResponse.token,
        clearError: true,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: 'Terjadi kesalahan. Silakan coba lagi.',
      );
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: ApiConstants.tokenKey);
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    dioClient: DioClient(),
    storage: const FlutterSecureStorage(),
  );
});
