import 'package:flutter/foundation.dart';
import '../models/violation.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../models/notification_model.dart';
import 'dart:io';
import 'dart:convert';
import '../services/demo_mode.dart';

class ViolationProvider with ChangeNotifier {
  List<Violation> _violations = [];
  List<NotificationModel> _notifications = [];
  List<User> _students = [];
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  // Student-specific data
  String _warningLevel = 'green';
  int _pendingCount = 0;
  int _approvedCount = 0;
  int _rejectedCount = 0;
  int _totalCount = 0;
  String? _studentQrCode;
  Map<String, dynamic> _studentProfile = {};
  Map<String, dynamic> _validatedStudent = {};
  Map<String, dynamic> _violationSummary = {};
  Map<String, dynamic> _saoSummary = {};
  Map<String, dynamic> _studentReport = {};
  Map<String, dynamic> _guardProfile = {};

  // Getters
  List<Violation> get violations => _violations;
  List<User> get students => _students;
  List<User> get users => _users;
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get warningLevel => _warningLevel;
  int get pendingCount => _pendingCount;
  int get approvedCount => _approvedCount;
  int get rejectedCount => _rejectedCount;
  int get totalCount => _totalCount;
  String? get studentQrCode => _studentQrCode;
  Map<String, dynamic> get studentProfile => _studentProfile;
  Map<String, dynamic> get validatedStudent => _validatedStudent;
  Map<String, dynamic> get violationSummary => _violationSummary;
  Map<String, dynamic> get saoSummary => _saoSummary;
  Map<String, dynamic> get studentReport => _studentReport;
  Map<String, dynamic> get guardProfile => _guardProfile;
  List<Map<String, dynamic>> _pendingDismissals = [];
  List<Map<String, dynamic>> get pendingDismissals => _pendingDismissals;
  List<Map<String, dynamic>> _dismissedStudents = [];
  List<Map<String, dynamic>> get dismissedStudents => _dismissedStudents;

  //STUDENTS METHOD
  // GET /api/student/violations
  Future<void> loadMyViolations() async {
    if (DemoMode.enabled) {
      _violations = [
        Violation(
          id: 'demo-violation-1',
          studentId: 'C26-01-0001-MAN121',
          type: ViolationType.noId,
          date: DateTime.now().subtract(const Duration(hours: 3)),
          remarks: 'Forgot ID at home, recorded at gate.',
          status: ViolationStatus.pending,
          offenseCount: 1,
          reportedBy: 'Officer Ramirez',
          violationName: 'No School ID',
          severity: 'minor',
        ),
        Violation(
          id: 'demo-violation-2',
          studentId: 'C26-01-0001-MAN121',
          type: ViolationType.noUniform,
          date: DateTime.now().subtract(const Duration(days: 2)),
          remarks: 'Civilian attire on uniform day.',
          status: ViolationStatus.referredToSAO,
          offenseCount: 1,
          reportedBy: 'Officer Ramirez',
          violationName: 'Improper Uniform',
          severity: 'minor',
        ),
      ];
      _pendingCount = 1;
      _approvedCount = 1;
      _rejectedCount = 0;
      _totalCount = 2;
      _warningLevel = 'green';
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      final result = await DatabaseService.getMyViolations();
      if (result.isNotEmpty) {
        _violations = List<Violation>.from(result['violations'] ?? []);
        _pendingCount = result['pending'] ?? 0;
        _approvedCount = result['approved'] ?? 0;
        _rejectedCount = result['rejected'] ?? 0;
        _totalCount = result['total_violations'] ?? 0;
        _warningLevel = result['warning_level'] ?? 'green';
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load violations: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/student/profile
  Future<void> loadMyProfile() async {
    if (DemoMode.enabled) {
      _studentProfile = _demoStudentProfile;
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      _studentProfile = await DatabaseService.getMyProfile();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load profile: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> uploadProfilePhoto(File imageFile) async {
    if (DemoMode.enabled) return _demoReadOnlyMessage;
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      await DatabaseService.uploadProfilePhoto(base64String);
      await loadMyProfile();
      return null;
    } catch (e) {
      return 'Upload failed. Try again.';
    }
  }

  Future<void> loadGuardProfile() async {
    if (DemoMode.enabled) {
      _guardProfile = {'name': 'Officer Ramirez (Guard)', 'role': 'Guard'};
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      _guardProfile = await DatabaseService.getMyProfile();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load profile: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/student/qrcode
  Future<void> loadMyQrCode() async {
    if (DemoMode.enabled) {
      _studentQrCode = null;
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      _studentQrCode = await DatabaseService.getMyQrCode();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load QR code: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadStudentViolations(String studentId) async {
    await loadMyViolations();
  }

  // GUARD METHODS
  // GET /api/guard/students
  Future<void> loadStudents() async {
    if (DemoMode.enabled) {
      _students = [
        DemoMode.studentUser,
        User(
          id: 'demo-student-2',
          username: 'maria.santos@gmail.com',
          password: '',
          name: 'Maria Santos (Student)',
          role: UserRole.student,
          studentNo: 'C26-01-0002-MAN122',
          gradeSection: 'BSCS-2A',
          contactNumber: '09187654321',
          status: 'Active',
        ),
      ];
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      _students = await DatabaseService.getAllStudents();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load students: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/guard/students/{studentNo}
  // Search specific student by StudentNo
  Future<Map<String, dynamic>?> searchStudent(String studentNo) async {
    if (DemoMode.enabled) {
      final result = _demoStudentResult(studentNo);
      if (result == null) {
        _error = 'Student not found in demo data.';
      }
      notifyListeners();
      return result;
    }

    _setLoading(true);
    _error = null;
    try {
      final result = await DatabaseService.validateStudent(studentNo);
      notifyListeners();
      return result;
    } catch (e) {
      _error = 'Student not found: ${e.toString()}';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/guard/student/validate?studentNo=xxx
  // Validate student by QR code scan
  Future<void> validateStudent(String studentNo) async {
    _validatedStudent = {};
    _error = null;
    if (DemoMode.enabled) {
      _validatedStudent = _demoStudentResult(studentNo) ?? {};
      if (_validatedStudent.isEmpty) {
        _error = 'Student not found in demo data.';
      }
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      final result = await DatabaseService.validateStudent(studentNo);
      _validatedStudent = result ?? {};
      notifyListeners();
    } catch (e) {
      _error = 'Failed to validate student: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // POST /api/guard/student/violation
  // Record a new violation
  Future<void> recordViolation({
    required String studentId,
    required ViolationType type,
    required String reportedBy,
    String? remarks,
    String? severity,
    String? violationName,
  }) async {
    if (_blockDemoWrite()) return;
    _setLoading(true);
    _error = null;
    try {
      final violation = Violation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        studentId: studentId,
        type: type,
        date: DateTime.now(),
        remarks: remarks,
        status: ViolationStatus.warning,
        offenseCount: 1,
        reportedBy: reportedBy,
        violationName: violationName ?? _violationTypeToString(type),
        severity: severity ?? 'minor',
      );
      await DatabaseService.addViolation(violation);
      await loadStudents();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to record violation: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/guard/violations/student?studentNo=xxx
  // View all violations of a specific student
  Future<void> loadViolationsByStudent(String studentNo) async {
    if (DemoMode.enabled) {
      final clean = studentNo.trim().toUpperCase();
      if (clean == 'C26-01-0002-MAN122') {
        _violations = [
          Violation(
            id: 'demo-v-3',
            studentId: 'C26-01-0002-MAN122',
            type: ViolationType.coloredHair,
            date: DateTime.now().subtract(const Duration(days: 4)),
            remarks: 'Bright neon hair color without clinic/sao permit.',
            status: ViolationStatus.warning,
            offenseCount: 2,
            reportedBy: 'Officer Ramirez',
            violationName: 'Unprescribed Hair Color',
            severity: 'moderate',
          ),
        ];
      } else {
        _violations = [
          Violation(
            id: 'demo-violation-1',
            studentId: 'C26-01-0001-MAN121',
            type: ViolationType.noId,
            date: DateTime.now().subtract(const Duration(hours: 3)),
            remarks: 'Forgot ID at home, recorded at gate.',
            status: ViolationStatus.pending,
            offenseCount: 1,
            reportedBy: 'Officer Ramirez',
            violationName: 'No School ID',
            severity: 'minor',
          ),
          Violation(
            id: 'demo-violation-2',
            studentId: 'C26-01-0001-MAN121',
            type: ViolationType.noUniform,
            date: DateTime.now().subtract(const Duration(days: 2)),
            remarks: 'Civilian attire on uniform day.',
            status: ViolationStatus.referredToSAO,
            offenseCount: 1,
            reportedBy: 'Officer Ramirez',
            violationName: 'Improper Uniform',
            severity: 'minor',
          ),
        ];
      }
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      _violations = await DatabaseService.getViolationsByStudent(studentNo);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load violations: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/guard/violations/summary?StartDate=xxx&EndDate=xxx
  // Get violation summary for a date range
  Future<void> loadViolationSummary(String startDate, String endDate) async {
    _error = null;
    if (DemoMode.enabled) {
      _violationSummary = {
        'totalViolations': 1,
        'topViolation': 'No School ID',
      };
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      _violationSummary = await DatabaseService.getViolationSummary(
        startDate,
        endDate,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load summary: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // SAO METHODS
  // SAO METHODS

  // GET /api/sao/violations
  // Load all violations for SAO
  Future<void> loadSaoViolations() async {
    if (DemoMode.enabled) {
      _violations = List.from(_demoSaoViolations);
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      _violations = await DatabaseService.getSaoViolations();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load SAO violations: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/sao/violations/by-status/{status}
  // Filter violations by status: pending / approved / rejected
  Future<void> loadSaoViolationsByStatus(String status) async {
    if (DemoMode.enabled) {
      if (status.toLowerCase() == 'all') {
        _violations = List.from(_demoSaoViolations);
      } else {
        _violations = _demoSaoViolations
            .where((v) => v.status.name.toLowerCase() == status.toLowerCase())
            .toList();
      }
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      _violations = await DatabaseService.getSaoViolationsByStatus(status);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load violations by status: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/sao/violations/summary
  // Load SAO summary stats
  Future<void> loadSaoSummary() async {
    if (DemoMode.enabled) {
      _saoSummary = {
        'totalViolations': 15,
        'pendingViolations': 3,
        'approvedViolations': 10,
        'rejectedViolations': 2,
        'topViolation': 'No School ID',
        'recentCount': 5,
        'byType': {
          'No ID': 8,
          'No Uniform': 4,
          'Colored Hair': 2,
          'Piercing': 1,
        },
      };
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      _saoSummary = await DatabaseService.getSaoSummary();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load SAO summary: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // PUT /api/sao/violations/{id}/approve
  Future<void> approveViolation(String violationId) async {
    if (DemoMode.enabled) {
      final idx = _demoSaoViolations.indexWhere((v) => v.id == violationId);
      if (idx != -1) {
        final current = _demoSaoViolations[idx];
        _demoSaoViolations[idx] = Violation(
          id: current.id,
          studentId: current.studentId,
          type: current.type,
          date: current.date,
          remarks: current.remarks,
          status: ViolationStatus.disciplinaryAction,
          offenseCount: current.offenseCount,
          reportedBy: current.reportedBy,
          violationName: current.violationName,
          severity: current.severity,
        );
      }
      await loadSaoViolations();
      return;
    }

    if (_blockDemoWrite()) return;
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.approveViolation(violationId);
      await loadSaoViolations();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to approve violation: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // PUT /api/sao/violations/{id}/reject
  Future<void> rejectViolation(String violationId) async {
    if (DemoMode.enabled) {
      final idx = _demoSaoViolations.indexWhere((v) => v.id == violationId);
      if (idx != -1) {
        final current = _demoSaoViolations[idx];
        _demoSaoViolations[idx] = Violation(
          id: current.id,
          studentId: current.studentId,
          type: current.type,
          date: current.date,
          remarks: current.remarks,
          status: ViolationStatus.cleared,
          offenseCount: current.offenseCount,
          reportedBy: current.reportedBy,
          violationName: current.violationName,
          severity: current.severity,
        );
      }
      await loadSaoViolations();
      return;
    }

    if (_blockDemoWrite()) return;
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.rejectViolation(violationId);
      await loadSaoViolations();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to reject violation: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // DELETE /api/sao/violations/{id}
  Future<void> deleteSaoViolation(String violationId) async {
    if (DemoMode.enabled) {
      _demoSaoViolations.removeWhere((v) => v.id == violationId);
      await loadSaoViolations();
      return;
    }

    if (_blockDemoWrite()) return;
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.deleteSaoViolation(violationId);
      await loadSaoViolations();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete violation: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/sao/students/{studentNo}/report
  Future<void> loadStudentReport(String studentNo) async {
    if (DemoMode.enabled) {
      final clean = studentNo.trim().toUpperCase();
      if (clean == 'C26-01-0002-MAN122') {
        _studentReport = {
          'name': 'Maria Santos',
          'student_no': 'C26-01-0002-MAN122',
          'course': 'BSCS',
          'year': '2nd Year',
          'email': 'maria.santos@gmail.com',
          'gender': 'Female',
          'contact_number': '09187654321',
          'status': 'Active',
          'address': 'Cebu City',
        };
      } else {
        _studentReport = _demoStudentProfile;
      }
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      _studentReport = await DatabaseService.getStudentReport(studentNo) ?? {};
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load student report: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/sao/users
  Future<void> loadAllUsers() async {
    if (DemoMode.enabled) {
      _users = [
        DemoMode.studentUser,
        User(
          id: 'demo-student-2',
          username: 'maria.santos@gmail.com',
          password: '',
          name: 'Maria Santos (Student)',
          role: UserRole.student,
          studentNo: 'C26-01-0002-MAN122',
          gradeSection: 'BSCS-2A',
          contactNumber: '09187654321',
          status: 'Active',
        ),
        DemoMode.guardUser,
      ];
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      _users = await DatabaseService.getAllUsers();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load users: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // PUT /api/sao/users/{id}
  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    if (_blockDemoWrite()) return;
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.updateUser(userId, userData);
      await loadAllUsers();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update user: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // DELETE /api/sao/users/{id}
  Future<void> deleteUser(String userId) async {
    if (_blockDemoWrite()) return;
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.deleteUser(userId);
      await loadAllUsers();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete user: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateViolationStatus(
    String violationId,
    ViolationStatus status,
  ) async {
    if (status == ViolationStatus.referredToSAO) {
      await approveViolation(violationId);
    } else if (status == ViolationStatus.cleared) {
      await rejectViolation(violationId);
    } else {
      await rejectViolation(violationId);
    }
  }

  Future<void> warnStudent(String studentNo) async {
    if (_blockDemoWrite()) return;
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.updateStudentWarning(studentNo);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to warn student: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPendingDismissals() async {
    if (DemoMode.enabled) {
      _pendingDismissals = [
        {
          'id': 'd-1',
          'student_no': 'C26-01-0005-MAN125',
          'name': 'Carlos Mendoza',
          'violation_count': 5,
          'reason':
              'Accumulated 5 major offenses (cutting classes, uniform defiance)',
          'date': '2026-03-10',
        },
      ];
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      _pendingDismissals = await DatabaseService.getPendingDismissals();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load dismissals: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/sao/students/dismissed
  Future<void> loadDismissedStudents() async {
    if (DemoMode.enabled) {
      _dismissedStudents = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      _dismissedStudents = await DatabaseService.getDismissedStudents();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load dismissed students: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // PUT /api/sao/students/{studentNo}/recommend-dismiss
  Future<void> recommendDismiss(String studentNo) async {
    if (DemoMode.enabled) {
      _pendingDismissals.removeWhere((d) => d['student_no'] == studentNo);
      notifyListeners();
      return;
    }

    if (_blockDemoWrite()) return;
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.recommendDismiss(studentNo);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to recommend dismissal: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // PUT /api/sao/violations/{id}/appeal/review
  Future<void> saoReviewAppeal(
    String violationId,
    String appealStatus,
    String appealRemarks,
  ) async {
    if (DemoMode.enabled) {
      _demoSaoAppeals.removeWhere(
        (a) => a['violation_id']?.toString() == violationId,
      );
      notifyListeners();
      return;
    }

    if (_blockDemoWrite()) return;
    _setLoading(true);
    _error = null;
    try {
      final reviewed = await DatabaseService.saoReviewAppeal(
        violationId,
        appealStatus,
        appealRemarks,
      );
      if (!reviewed) {
        throw Exception('The appeal decision was not saved.');
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to review appeal: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // GET /api/sao/violations/appeals
  Future<List<Map<String, dynamic>>> loadSaoAppeals() async {
    if (DemoMode.enabled) {
      return List<Map<String, dynamic>>.from(_demoSaoAppeals);
    }
    _error = null;
    try {
      return await DatabaseService.getSaoAppeals();
    } catch (e) {
      _error = 'Failed to load appeals: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }

  // PUT /api/sao/students/{studentNo}/dismiss
  Future<void> dismissStudent(String studentNo) async {
    if (_blockDemoWrite()) return;
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.dismissStudent(studentNo);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to dismiss student: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // PUT /api/sao/students/{studentNo}/cancel-dismiss
  Future<void> cancelDismiss(String studentNo) async {
    if (_blockDemoWrite()) return;
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.cancelDismiss(studentNo);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to cancel dismissal: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submitAppeal(String violationId, String appealText) async {
    if (_blockDemoWrite()) return;
    _setLoading(true);
    _error = null;
    try {
      await DatabaseService.submitAppeal(violationId, appealText);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to submit appeal: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markNotificationAsRead(int id) async {
    if (_blockDemoWrite()) return;
    try {
      await DatabaseService.markNotificationAsRead(id);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          targetUsername: _notifications[index].targetUsername,
          targetRole: _notifications[index].targetRole,
          title: _notifications[index].title,
          message: _notifications[index].message,
          isRead: true,
          createdAt: _notifications[index].createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to mark as read: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    if (_blockDemoWrite()) return;
    try {
      await DatabaseService.markAllNotificationsAsRead();
      _notifications = _notifications
          .map(
            (n) => NotificationModel(
              id: n.id,
              targetUsername: n.targetUsername,
              targetRole: n.targetRole,
              title: n.title,
              message: n.message,
              isRead: true,
              createdAt: n.createdAt,
            ),
          )
          .toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to mark all as read: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> loadNotifications() async {
    if (DemoMode.enabled) {
      _notifications = [
        NotificationModel(
          id: 1,
          targetUsername: 'student@gmail.com',
          targetRole: 'student',
          title: 'Violation Notice Logged',
          message:
              'A violation (No School ID) was reported at the main entrance gate.',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        NotificationModel(
          id: 2,
          targetUsername: 'student@gmail.com',
          targetRole: 'student',
          title: 'Welcome to ACLC Demo Mode',
          message: 'Explore student, guard, and SAO roles with full demo data.',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      _notifications = await DatabaseService.getNotifications();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load notifications: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // HELPERS
  static const String _demoReadOnlyMessage =
      'Demo mode is read-only. Changes are not saved.';

  bool _blockDemoWrite() {
    if (!DemoMode.enabled) return false;
    _error = _demoReadOnlyMessage;
    notifyListeners();
    return true;
  }

  static final List<Violation> _demoSaoViolations = [
    Violation(
      id: 'demo-v-1',
      studentId: 'C26-01-0001-MAN121',
      type: ViolationType.noId,
      date: DateTime.now().subtract(const Duration(hours: 3)),
      remarks: 'Forgot ID at home, recorded at gate.',
      status: ViolationStatus.pending,
      offenseCount: 1,
      reportedBy: 'Officer Ramirez',
      violationName: 'No School ID',
      severity: 'minor',
    ),
    Violation(
      id: 'demo-v-2',
      studentId: 'C26-01-0001-MAN121',
      type: ViolationType.noUniform,
      date: DateTime.now().subtract(const Duration(days: 2)),
      remarks: 'Civilian attire on uniform day.',
      status: ViolationStatus.referredToSAO,
      offenseCount: 1,
      reportedBy: 'Officer Ramirez',
      violationName: 'Improper Uniform',
      severity: 'minor',
    ),
    Violation(
      id: 'demo-v-3',
      studentId: 'C26-01-0002-MAN122',
      type: ViolationType.coloredHair,
      date: DateTime.now().subtract(const Duration(days: 4)),
      remarks: 'Bright neon hair color without permit.',
      status: ViolationStatus.warning,
      offenseCount: 2,
      reportedBy: 'Officer Ramirez',
      violationName: 'Unprescribed Hair Color',
      severity: 'moderate',
    ),
  ];

  static final List<Map<String, dynamic>> _demoSaoAppeals = [
    {
      'id': 'demo-appeal-1',
      'violation_id': 'demo-v-1',
      'student_no': 'C26-01-0001-MAN121',
      'student_name': 'Juan Dela Cruz',
      'violation_name': 'No School ID',
      'date_reported': '2026-03-14',
      'appeal_reason':
          'ID was temporarily left on desk during rush morning commute. ID presented to SAO office in afternoon.',
      'status': 'Pending',
    },
  ];

  static final Map<String, dynamic> _demoStudentProfile = {
    'name': 'Juan Dela Cruz (Student)',
    'student_no': 'C26-01-0001-MAN121',
    'course': 'BSIT',
    'year': '3rd Year',
    'email': 'student@gmail.com',
    'gender': 'Male',
    'contact_number': '09123456789',
    'status': 'Active',
    'address': 'ACLC Mandaue Campus, Subangdaku, Mandaue City',
  };

  static Map<String, dynamic>? _demoStudentResult(String studentNo) {
    final clean = studentNo.trim().toUpperCase();
    if (clean == 'C26-01-0002-MAN122' || clean.contains('MARIA')) {
      return {
        'name': 'Maria Santos (Student)',
        'student_no': 'C26-01-0002-MAN122',
        'course': 'BSCS',
        'year': '2nd Year',
        'email': 'maria.santos@gmail.com',
        'gender': 'Female',
        'contact_number': '09187654321',
        'status': 'Active',
        'address': 'Cebu City',
        'warning_level': 'yellow',
        'violation_count': 1,
        'profile_photo': null,
        'violations': [
          {
            'id': 'demo-v-3',
            'violation_name': 'Unprescribed Hair Color',
            'type': 'Colored Hair',
            'date': DateTime.now()
                .subtract(const Duration(days: 4))
                .toIso8601String(),
            'severity': 'moderate',
            'status': 'Warning',
          },
        ],
      };
    }

    // Default to Juan Dela Cruz for demo
    return {
      ..._demoStudentProfile,
      'warning_level': 'green',
      'violation_count': 2,
      'profile_photo': null,
      'violations': [
        {
          'id': 'demo-violation-1',
          'violation_name': 'No School ID',
          'type': 'No School ID',
          'date': DateTime.now()
              .subtract(const Duration(hours: 3))
              .toIso8601String(),
          'severity': 'minor',
          'status': 'Pending',
        },
        {
          'id': 'demo-violation-2',
          'violation_name': 'Improper Uniform',
          'type': 'Improper Uniform',
          'date': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String(),
          'severity': 'minor',
          'status': 'Approved',
        },
      ],
    };
  }

  String _violationTypeToString(ViolationType type) {
    switch (type) {
      case ViolationType.noId:
        return 'No ID';
      case ViolationType.noUniform:
        return 'No Uniform';
      case ViolationType.piercing:
        return 'Piercing';
      case ViolationType.coloredHair:
        return 'Colored Hair';
    }
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
