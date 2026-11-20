import '../models/user.dart';

class DemoMode {
  static bool _runtimeDemoActive = false;
  static const bool _envDemoEnabled = bool.fromEnvironment('DEMO_MODE');

  /// Active if compile-time DEMO_MODE is set or if any demo user logs in
  static bool get enabled => _runtimeDemoActive || _envDemoEnabled;

  static void setDemoActive(bool active) {
    _runtimeDemoActive = active;
  }

  // Common Demo Password
  static const String demoPassword = 'Password123!';

  // Student Demo Account
  static const String studentEmail = 'student@gmail.com';
  static const String studentUsername = 'student';
  static final User studentUser = User(
    id: 'demo-student',
    username: studentEmail,
    password: '',
    name: 'Juan Dela Cruz (Student)',
    role: UserRole.student,
    studentNo: 'C26-01-0001-MAN121',
    gradeSection: 'BSIT-3A',
    contactNumber: '09123456789',
    status: 'Active',
  );

  /// Authenticate against demo accounts.
  /// Matches the student demo credentials and legacy student login.
  static User? authenticate(String identifier, String password) {
    final cleanId = identifier.trim().toLowerCase();
    final cleanPass = password.trim();

    // Student Check
    if ((cleanId == studentEmail ||
            cleanId == studentUsername ||
            cleanId == 'demo_student') &&
        (cleanPass == demoPassword || cleanPass == 'StudentDemo123!')) {
      _runtimeDemoActive = true;
      return studentUser;
    }

    return null;
  }
}
