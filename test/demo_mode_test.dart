import 'package:flutter_test/flutter_test.dart';
import 'package:violation/models/user.dart';
import 'package:violation/services/demo_mode.dart';

void main() {
  group('DemoMode Account Authentication Tests', () {
    test('authenticates student demo account by email and username', () {
      final userByEmail = DemoMode.authenticate(
        'student@gmail.com',
        'Password123!',
      );
      expect(userByEmail, isNotNull);
      expect(userByEmail!.role, UserRole.student);
      expect(userByEmail.studentNo, 'C26-01-0001-MAN121');
      expect(userByEmail.name, contains('Juan Dela Cruz'));

      final userByUsername = DemoMode.authenticate('student', 'Password123!');
      expect(userByUsername, isNotNull);
      expect(userByUsername!.role, UserRole.student);
    });

    test('rejects removed guard demo credentials', () {
      expect(DemoMode.authenticate('guard@gmail.com', 'Password123!'), isNull);
      expect(DemoMode.authenticate('guard', 'Password123!'), isNull);
      expect(DemoMode.authenticate('demo_guard', 'GuardDemo123!'), isNull);
      expect(DemoMode.authenticate('demo_guard', 'StudentDemo123!'), isNull);
    });

    test('authenticates SAO demo account', () {
      final saoByEmail = DemoMode.authenticate('sao@gmail.com', 'Password123!');
      expect(saoByEmail, isNotNull);
      expect(saoByEmail!.role, UserRole.sao);

      final saoByUsername = DemoMode.authenticate('sao', 'Password123!');
      expect(saoByUsername, isNotNull);
      expect(saoByUsername!.role, UserRole.sao);
    });

    test('rejects invalid passwords or unknown users', () {
      expect(DemoMode.authenticate('student@gmail.com', 'WrongPass'), isNull);
      expect(
        DemoMode.authenticate('unknown@gmail.com', 'Password123!'),
        isNull,
      );
    });

    test(
      'preserves backward compatibility with legacy student credentials',
      () {
        final legacyStudent = DemoMode.authenticate(
          'demo_student',
          'StudentDemo123!',
        );
        expect(legacyStudent, isNotNull);
        expect(legacyStudent!.role, UserRole.student);
      },
    );
  });
}
