import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../services/demo_mode.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _pendingAuthenticator;
  String? _pendingUsername;
  List<String> _recoveryCodes = [];
  bool _rememberMeForPendingLogin = true;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  Map<String, dynamic>? get pendingAuthenticator => _pendingAuthenticator;
  List<String> consumeRecoveryCodes() {
    final codes = _recoveryCodes;
    _recoveryCodes = [];
    return codes;
  }

  //LOGIN
  Future<void> login(
    String username,
    String password, {
    bool rememberMe = true,
  }) async {
    _setLoading(true);
    _error = null;
    _pendingAuthenticator = null;
    _pendingUsername = null;
    _recoveryCodes = [];
    _rememberMeForPendingLogin = rememberMe;

    try {
      final demoUser = DemoMode.authenticate(username.trim(), password);
      if (demoUser != null) {
        _currentUser = demoUser;
        await _saveSession(_currentUser!, rememberMe: rememberMe);
        notifyListeners();
        return;
      }

      if (const bool.fromEnvironment('DEMO_MODE')) {
        _error =
            'Invalid demo credentials. Use student@gmail.com or guard@gmail.com.';
        notifyListeners();
        return;
      }

      final result = await DatabaseService.login(
        username,
        password,
        rememberMe: rememberMe,
      );

      if (result != null && result['user'] != null) {
        final user = result['user'] as User;
        if (user.role == UserRole.sao) {
          _currentUser = null;
          await DatabaseService.clearToken();
          await _clearSession();
          _error = 'SAO accounts are no longer supported in this app.';
        } else {
          _currentUser = user;
          await _saveSession(user, rememberMe: rememberMe);
        }
        notifyListeners();
      } else if (result?['authenticator'] is Map<String, dynamic>) {
        _pendingAuthenticator =
            result!['authenticator'] as Map<String, dynamic>;
        _pendingUsername = username;
        notifyListeners();
      } else {
        _error = result?['error'] ?? 'Invalid username or password';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyAuthenticatorCode(String code) async {
    final challengeId = _pendingAuthenticator?['challengeId']?.toString();
    final username = _pendingUsername;
    if (challengeId == null || challengeId.isEmpty || username == null) {
      _error = 'Sign-in challenge is missing. Please sign in again.';
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      final result = await DatabaseService.verifyAuthenticatorCode(
        username: username,
        challengeId: challengeId,
        code: code,
        rememberMe: _rememberMeForPendingLogin,
      );
      if (result['user'] is User) {
        final user = result['user'] as User;
        if (user.role == UserRole.sao) {
          _currentUser = null;
          _pendingAuthenticator = null;
          _pendingUsername = null;
          await DatabaseService.clearToken();
          await _clearSession();
          _error = 'SAO accounts are no longer supported in this app.';
        } else {
          _currentUser = user;
          _recoveryCodes = (result['recoveryCodes'] as List)
              .map((code) => code.toString())
              .toList();
          _pendingAuthenticator = null;
          _pendingUsername = null;
          await _saveSession(user, rememberMe: _rememberMeForPendingLogin);
        }
      } else {
        _error =
            result['error']?.toString() ?? 'Authenticator verification failed.';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // REGISTER
  Future<void> register({
    required String username,
    required String password,
    required String name,
    required UserRole role,
    String? email,
    String? address,
    String? contactNumber,
    String? studentNo,
    String? gender,
    String? dateOfBirth,
    String? course,
    String? year,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await DatabaseService.register(
        username: username,
        password: password,
        name: name,
        role: role,
        email: email,
        address: address,
        contactNumber: contactNumber,
        studentNo: studentNo,
        gender: gender,
        dateOfBirth: dateOfBirth,
        course: course,
        year: year,
      );

      if (result['success'] == true) {
        _currentUser = result['user'] as User;
        _error = null;
      } else {
        _currentUser = null;
        _error = result['message'];
      }
    } catch (e) {
      _currentUser = null;
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // LOGOUT
  Future<void> logout() async {
    _currentUser = null;
    DemoMode.setDemoActive(false);
    await DatabaseService.clearToken();
    await _clearSession();
    notifyListeners();
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (DemoMode.enabled) {
      return 'Password changes are unavailable in demo mode.';
    }

    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return _error;
    } finally {
      _setLoading(false);
    }
  }

  //CHECK AUTH STATUS
  Future<void> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userRole = prefs.getString('user_role');
      final userName = prefs.getString('user_name');

      if (userId != null && userRole != null) {
        if (userRole == UserRole.sao.name) {
          await DatabaseService.clearToken();
          await _clearSession();
          DemoMode.setDemoActive(false);
          _currentUser = null;
          notifyListeners();
          return;
        }
        if (userId.startsWith('demo-')) {
          DemoMode.setDemoActive(true);
        }
        _currentUser = User(
          id: userId,
          username: prefs.getString('user_username') ?? '',
          password: '',
          name: userName ?? '',
          role: UserRole.values.firstWhere(
            (r) => r.name == userRole,
            orElse: () => UserRole.student,
          ),
          studentNo:
              prefs.getString('student_no') ??
              (userId == 'demo-student' ? 'C26-01-0001-MAN121' : null),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
    }
  }

  Future<void> _saveSession(User user, {required bool rememberMe}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!rememberMe) {
      await _clearSession();
      return;
    }
    await prefs.setString('user_id', user.id);
    await prefs.setString('user_role', user.role.name);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_username', user.username);
    if (user.studentNo != null) {
      await prefs.setString('student_no', user.studentNo!);
    }
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
    await prefs.remove('user_username');
    await prefs.remove('student_no');
    await prefs.remove('jwt_token');
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
