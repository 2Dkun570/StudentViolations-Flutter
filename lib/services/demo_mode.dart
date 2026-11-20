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

  // Guard Demo Account
  static const String guardEmail = 'guard@gmail.com';
  static const String guardUsername = 'guard';
  static final User guardUser = User(
    id: 'demo-guard',
    username: guardEmail,
    password: '',
    name: 'Officer Ramirez (Guard)',
    role: UserRole.guard,
    contactNumber: '09129876543',
    status: 'Active',
  );

  /// Authenticate against demo accounts.
  /// Matches student and guard demo credentials.
  /// Also preserves backward compatibility with legacy demo credentials.
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

    // Guard Check
    if ((cleanId == guardEmail ||
            cleanId == guardUsername ||
            cleanId == 'demo_guard') &&
        (cleanPass == demoPassword || cleanPass == 'GuardDemo123!')) {
      _runtimeDemoActive = true;
      return guardUser;
    }

    return null;
  }
}
