import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/violation.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../providers/violation_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_components.dart';

class GuardDashboard extends StatefulWidget {
  const GuardDashboard({super.key});

  @override
  State<GuardDashboard> createState() => _GuardDashboardState();
}

class _GuardDashboardState extends State<GuardDashboard> {
  int _currentIndex = 0;
  int _flowStep = 1;

  final _remarksController = TextEditingController();
  final _studentSearchController = TextEditingController();

  // QR / Validate state
  String? _scannedStudentNo;
  Map<String, dynamic> _scannedStudentData = {};
  bool _scannerActive = true;
  bool _isLookingUp = false;
  String? _lookupError;
  int _lookupRequestId = 0;

  // Selected violation type
  String? _selectedViolationType;
  String _selectedSeverity = 'minor';

  final List<String> _violationPresets = [
    'No ID',
    'No Uniform',
    'Piercing',
    'Colored Hair',
    'Disruptive Behavior',
    'Vandalism',
    'Prohibited Items',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vp = Provider.of<ViolationProvider>(context, listen: false);
      vp.loadStudents();
      vp.loadGuardProfile();
    });
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _studentSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _buildContent(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(88),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.navyDark, AppColors.navy],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Image.asset(
                        'assets/images/ACLC.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACLC College of Mandaue',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.red.withValues(alpha: 0.55),
                          ),
                        ),
                        child: const Text(
                          'GUARD PORTAL',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PortalHeaderActionButton(
                  icon: _currentIndex == 1
                      ? Icons.arrow_back_rounded
                      : Icons.settings_outlined,
                  tooltip: _currentIndex == 1 ? 'Back to scan' : 'Settings',
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  onPressed: () {
                    setState(() {
                      _currentIndex = _currentIndex == 1 ? 0 : 1;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentIndex) {
      case 0:
        return _buildScanAndRecordTab();
      case 1:
        return _buildSettingsPage();
      default:
        return _buildScanAndRecordTab();
    }
  }

  Widget _buildSettingsPage() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final guardName = user?.name ?? 'Officer';
    final username = user?.username ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPageIntro(
            title: 'Settings',
            subtitle: 'Manage your guard account and session.',
          ),
          _guardCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.portalCardSurface(context),
                  child: Text(
                    guardName.isNotEmpty ? guardName[0].toUpperCase() : 'G',
                    style: TextStyle(
                      color: AppTheme.portalAccent(context),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guardName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.portalTextPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Guard account',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.portalTextSecondary(context),
                        ),
                      ),
                      if (username.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          '@$username',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.portalTextMuted(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _guardCard(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppTheme.portalCardSurface(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: AppTheme.portalAccent(context),
                  ),
                ),
                title: Text(
                  'Change password',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.portalTextPrimary(context),
                  ),
                ),
                subtitle: Text('Update your account password'),
                trailing: Icon(Icons.chevron_right_rounded),
                onTap: _showChangePasswordDialog,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _guardCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              secondary: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                color: AppTheme.portalAccent(context),
              ),
              title: Text(
                'Dark mode',
                style: TextStyle(color: AppTheme.portalTextPrimary(context)),
              ),
              subtitle: Text(
                'Use a darker appearance for the portal',
                style: TextStyle(color: AppTheme.portalTextSecondary(context)),
              ),
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: context.read<ThemeModeProvider>().setDarkMode,
            ),
          ),
          const SizedBox(height: 16),
          PortalSignOutButton(onPressed: () => _showLogoutDialog(context)),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    var currentPassword = '';
    var newPassword = '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var isSubmitting = false;
        var obscureCurrentPassword = true;
        var obscureNewPassword = true;
        var obscureConfirmPassword = true;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            title: Text(
              'Change password',
              style: TextStyle(
                color: AppTheme.portalTextPrimary(context),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      onChanged: (value) => currentPassword = value,
                      obscureText: obscureCurrentPassword,
                      decoration: InputDecoration(
                        labelText: 'Current password',
                        suffixIcon: IconButton(
                          tooltip: obscureCurrentPassword
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            obscureCurrentPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setDialogState(
                            () => obscureCurrentPassword =
                                !obscureCurrentPassword,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter your current password'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      onChanged: (value) => newPassword = value,
                      obscureText: obscureNewPassword,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        helperText: 'Use at least 8 characters',
                        suffixIcon: IconButton(
                          tooltip: obscureNewPassword
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            obscureNewPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setDialogState(
                            () => obscureNewPassword = !obscureNewPassword,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        if (value == currentPassword) {
                          return 'Choose a different password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      obscureText: obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm new password',
                        suffixIcon: IconButton(
                          tooltip: obscureConfirmPassword
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setDialogState(
                            () => obscureConfirmPassword =
                                !obscureConfirmPassword,
                          ),
                        ),
                      ),
                      validator: (value) => value != newPassword
                          ? 'Passwords do not match'
                          : null,
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: AppColors.dangerRed,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSubmitting
                          ? null
                          : () => Navigator.of(dialogContext).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.portalTextSecondary(context),
                        minimumSize: const Size(0, 48),
                        side: BorderSide(color: AppTheme.portalBorder(context)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setDialogState(() {
                                isSubmitting = true;
                                errorMessage = null;
                              });

                              final error =
                                  await Provider.of<AuthProvider>(
                                    dialogContext,
                                    listen: false,
                                  ).changePassword(
                                    currentPassword: currentPassword,
                                    newPassword: newPassword,
                                  );

                              if (!mounted || !dialogContext.mounted) return;
                              if (error != null) {
                                setDialogState(() {
                                  isSubmitting = false;
                                  errorMessage = error;
                                });
                                return;
                              }

                              Navigator.of(dialogContext).pop();
                              _showSnack('Password changed successfully.');
                            },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Change password'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageIntro({required String title, required String subtitle}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.start,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.start,
            style: TextStyle(
              color: isDark
                  ? AppTheme.portalTextSecondary(context)
                  : AppTheme.portalTextSecondary(context),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _guardCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppTheme.portalSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.portalBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Padding(padding: padding, child: child),
      ),
    );
  }

  Widget _buildWorkflowProgress() {
    const steps = ['Scan', 'Verify', 'Record'];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: AppTheme.portalSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.portalBorder(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWorkflowStep(steps[0], 1),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.fromLTRB(8, 15, 8, 0),
              decoration: BoxDecoration(
                color: _flowStep > 1
                    ? AppTheme.portalAccent(context)
                    : AppTheme.portalBorder(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          _buildWorkflowStep(steps[1], 2),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.fromLTRB(8, 15, 8, 0),
              decoration: BoxDecoration(
                color: _flowStep > 2
                    ? AppTheme.portalAccent(context)
                    : AppTheme.portalBorder(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          _buildWorkflowStep(steps[2], 3),
        ],
      ),
    );
  }

  Widget _buildWorkflowStep(String label, int step) {
    final isCurrent = _flowStep == step;
    final isComplete = _flowStep > step;
    final isActive = _flowStep >= step;

    return SizedBox(
      width: 54,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.portalAccent(context)
                  : AppTheme.portalCardSurface(context),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? AppTheme.portalAccent(context)
                    : AppTheme.portalBorder(context),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: isComplete
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : AppTheme.portalTextSecondary(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
              color: isCurrent
                  ? AppTheme.portalAccent(context)
                  : AppTheme.portalTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 0: Scan & Record ───────────────────────────────────────────────────
  Widget _buildScanAndRecordTab() {
    final guardName =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.name ??
        'Officer';
    final screenWidth = MediaQuery.of(context).size.width;
    final scanFrameSize = (screenWidth * 0.68).clamp(220.0, 275.0);

    return Consumer<ViolationProvider>(
      builder: (context, vp, _) {
        final studentQuery = _studentSearchController.text.trim().toLowerCase();
        final matchingStudents = studentQuery.isEmpty
            ? <User>[]
            : vp.students
                  .where(
                    (student) =>
                        student.name.toLowerCase().contains(studentQuery) ||
                        (student.studentNo?.toLowerCase().contains(
                              studentQuery,
                            ) ??
                            false),
                  )
                  .take(5)
                  .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: TextStyle(
                        color: AppTheme.portalAccent(context),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Welcome, $guardName',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 25,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Scan a student ID or enter a student number to verify and record an incident.',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.portalTextSecondary(context)
                            : AppTheme.portalTextSecondary(context),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              _buildWorkflowProgress(),

              // Student lookup
              if (_flowStep == 1) ...[
                _guardCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.qr_code_scanner_rounded,
                                  size: 20,
                                  color: AppTheme.portalAccent(context),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Step 1: Scan QR code or search',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.portalTextPrimary(
                                        context,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_scannerActive)
                            IconButton(
                              tooltip: _isLookingUp
                                  ? 'Cancel student lookup'
                                  : 'Scan another student',
                              onPressed: _resetStudentLookup,
                              icon: Icon(Icons.qr_code_scanner_rounded),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Container(
                        height: _scannerActive ? scanFrameSize + 24 : 150,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _scannerActive
                              ? Stack(
                                  children: [
                                    MobileScanner(
                                      onDetect: (capture) {
                                        if (capture.barcodes.isEmpty) return;
                                        final value =
                                            capture.barcodes.first.rawValue;
                                        if (value != null &&
                                            value != _scannedStudentNo) {
                                          _beginStudentLookup(value, vp);
                                        }
                                      },
                                    ),
                                    Center(
                                      child: Container(
                                        key: const ValueKey(
                                          'guard-scan-target',
                                        ),
                                        width: scanFrameSize,
                                        height: scanFrameSize,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Container(
                                  color: AppColors.navyDark,
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_isLookingUp)
                                            const SizedBox(
                                              width: 30,
                                              height: 30,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          else
                                            Icon(
                                              _scannedStudentData.isNotEmpty
                                                  ? Icons.check_circle_rounded
                                                  : Icons.error_outline_rounded,
                                              color:
                                                  _scannedStudentData.isNotEmpty
                                                  ? AppColors.safeGreen
                                                  : AppColors.dangerRed,
                                              size: 42,
                                            ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _isLookingUp
                                                ? 'Checking student record…'
                                                : _scannedStudentData.isNotEmpty
                                                ? 'Student verified'
                                                : 'Could not verify student',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (_scannedStudentData.isNotEmpty)
                                            Text(
                                              _scannedStudentData['name']
                                                      ?.toString() ??
                                                  _scannedStudentNo ??
                                                  '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            )
                                          else if (!_isLookingUp)
                                            Text(
                                              _lookupError ??
                                                  'No matching student record was found.',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      if (_scannerActive) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Align the student QR code within the frame',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.portalTextSecondary(context),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      if (_scannerActive || _scannedStudentData.isEmpty) ...[
                        TextFormField(
                          controller: _studentSearchController,
                          style: const TextStyle(fontSize: 14),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search by student name or number',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                            ),
                            suffixIcon: _studentSearchController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () {
                                      _studentSearchController.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                        if (studentQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          if (matchingStudents.isNotEmpty)
                            _guardCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  for (
                                    var index = 0;
                                    index < matchingStudents.length;
                                    index++
                                  ) ...[
                                    if (index > 0)
                                      Divider(
                                        height: 1,
                                        color: AppTheme.portalBorder(context),
                                      ),
                                    ListTile(
                                      key: ValueKey(
                                        'guard-student-match-${matchingStudents[index].studentNo ?? matchingStudents[index].id}',
                                      ),
                                      leading: CircleAvatar(
                                        backgroundColor: AppColors.navySurface,
                                        foregroundColor: AppColors.navy,
                                        child: Text(
                                          matchingStudents[index]
                                                  .name
                                                  .isNotEmpty
                                              ? matchingStudents[index].name[0]
                                                    .toUpperCase()
                                              : 'S',
                                        ),
                                      ),
                                      title: Text(
                                        matchingStudents[index].name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.portalTextPrimary(
                                            context,
                                          ),
                                        ),
                                      ),
                                      subtitle: Text(
                                        matchingStudents[index].studentNo ??
                                            'Student number unavailable',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Icon(
                                        Icons.arrow_forward_rounded,
                                        color: AppTheme.portalAccent(context),
                                      ),
                                      onTap: () {
                                        final studentNo =
                                            matchingStudents[index].studentNo;
                                        if (studentNo != null &&
                                            studentNo.isNotEmpty) {
                                          _beginStudentLookup(studentNo, vp);
                                        }
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            )
                          else if (vp.isLoading && vp.students.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: LinearProgressIndicator(),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 10,
                              ),
                              child: Text(
                                vp.error != null && vp.students.isEmpty
                                    ? 'Student list could not be loaded: ${vp.error}'
                                    : 'No students match "$studentQuery".',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.portalTextSecondary(context),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
              if (_flowStep == 2 && _scannedStudentData.isNotEmpty) ...[
                _buildPageIntro(
                  title: 'Step 2: Confirm student match',
                  subtitle:
                      "Check this student's name and number before continuing to record a violation.",
                ),
                const SizedBox(height: 16),
                _buildStudentVerifiedCard(_scannedStudentData),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextButton.icon(
                      onPressed: _resetStudentLookup,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Change student'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        alignment: Alignment.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => setState(() => _flowStep = 3),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Continue to violation'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (_flowStep == 3 && _scannedStudentData.isNotEmpty) ...[
                _guardCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _scannedStudentData['name']?.toString() ??
                                  'Verified student',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.portalTextPrimary(context),
                              ),
                            ),
                            Text(
                              _scannedStudentData['student_no']?.toString() ??
                                  _scannedStudentNo ??
                                  '',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.portalTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _flowStep = 2),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(64, 48),
                        ),
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Record Infraction Card
                _guardCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.report_problem_rounded,
                            color: AppColors.red,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Step 3: Record violation',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.portalTextPrimary(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'Select Violation Type:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.portalTextSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Quick Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _violationPresets.map((type) {
                          final isSelected = _selectedViolationType == type;
                          return ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
                            visualDensity: const VisualDensity(
                              horizontal: 1,
                              vertical: 1,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            onSelected: (val) => setState(
                              () => _selectedViolationType = val ? type : null,
                            ),
                            selectedColor: AppColors.red,
                            backgroundColor: AppTheme.portalSurface(context),
                            labelStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.portalTextPrimary(context),
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.red
                                  : AppTheme.portalBorder(context),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Severity:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.portalTextSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const ['minor', 'major', 'critical'].map((
                          severity,
                        ) {
                          final isSelected = _selectedSeverity == severity;
                          final color = AppColors.forSeverity(severity);
                          return ChoiceChip(
                            label: Text(severity.toUpperCase()),
                            selected: isSelected,
                            visualDensity: const VisualDensity(
                              horizontal: 1,
                              vertical: 1,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            onSelected: (selected) {
                              if (!selected) return;
                              setState(() => _selectedSeverity = severity);
                            },
                            selectedColor: color,
                            backgroundColor: AppTheme.portalSurface(context),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.portalTextPrimary(context),
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? color
                                  : AppTheme.portalBorder(context),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _remarksController,
                        maxLines: 2,
                        style: TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Additional Remarks (Optional)',
                          hintText:
                              'e.g., Student refused inspection at Main Gate',
                          prefixIcon: Icon(Icons.notes_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: vp.isLoading ? null : _submitViolation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: vp.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(Icons.send_rounded, size: 18),
                          label: Text(
                            vp.isLoading
                                ? 'Submitting...'
                                : 'Log Violation Incident',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  bool _isResolvedViolation(dynamic violation) {
    if (violation is! Map) return false;

    const resolvedStatuses = {
      'approved',
      'cleared',
      'resolved',
      'settled',
      'closed',
      'dismissed',
      'rejected',
      'expired',
    };
    final statusValues = [
      violation['status'],
      violation['appeal_status'],
      violation['appealStatus'],
    ];
    return statusValues.any(
      (value) => resolvedStatuses.contains(
        value?.toString().trim().toLowerCase() ?? '',
      ),
    );
  }

  int _activeWarningCount(Map<String, dynamic> data) {
    final violations = (data['violations'] as List?) ?? const [];
    if (violations.isEmpty) {
      final count = int.tryParse(data['violation_count']?.toString() ?? '0');
      return count ?? 0;
    }

    return violations.where((violation) {
      if (violation is! Map) return false;
      return !_isResolvedViolation(violation);
    }).length;
  }

  bool _hasActiveCriticalViolation(Map<String, dynamic> data) {
    final violations = (data['violations'] as List?) ?? const [];
    return violations.any((violation) {
      if (violation is! Map) return false;
      final severity = (violation['severity'] ?? '').toString().toLowerCase();
      return severity == 'critical' && !_isResolvedViolation(violation);
    });
  }

  Widget _buildStudentVerifiedCard(Map<String, dynamic> data) {
    final level = data['warning_level']?.toString() ?? 'green';
    final violations = (data['violations'] as List?) ?? [];
    final name = data['name'] ?? 'Student';
    final studentNo = data['student_no'] ?? '—';
    final activeWarningCount = _activeWarningCount(data);
    final hasActiveCritical = _hasActiveCriticalViolation(data);
    final isProhibited =
        activeWarningCount >= 3 ||
        hasActiveCritical ||
        level.toLowerCase() == 'red' ||
        level.toLowerCase() == 'critical';

    return _guardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isProhibited
                  ? AppColors.dangerRed.withValues(alpha: 0.10)
                  : AppColors.safeGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isProhibited
                    ? AppColors.dangerRed.withValues(alpha: 0.45)
                    : AppColors.safeGreen.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isProhibited
                      ? Icons.block_rounded
                      : Icons.check_circle_rounded,
                  color: isProhibited
                      ? AppColors.dangerRed
                      : AppColors.safeGreen,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isProhibited
                            ? 'PROHIBITED FROM CAMPUS ENTRY'
                            : 'ALLOWED TO ENTER CAMPUS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isProhibited
                              ? AppColors.dangerRed
                              : AppColors.safeGreen,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isProhibited
                            ? hasActiveCritical
                                  ? 'Active critical violation. Requires settlement or an approved appeal.'
                                  : 'Three active warnings reached. Requires settlement, an approved appeal, or semester reset.'
                            : 'No critical violation or 3-warning limit',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppTheme.portalTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.forWarningBg(level),
                backgroundImage:
                    (data['profile_photo'] != null &&
                        data['profile_photo'].toString().isNotEmpty)
                    ? MemoryImage(
                        base64Decode(
                          data['profile_photo']
                              .toString()
                              .replaceAll('\n', '')
                              .replaceAll('\r', '')
                              .trim(),
                        ),
                      )
                    : null,
                child:
                    (data['profile_photo'] == null ||
                        data['profile_photo'].toString().isEmpty)
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: TextStyle(
                          color: AppColors.forWarning(level),
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.portalTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      studentNo,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.portalTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: level.toUpperCase(),
                color: AppColors.forWarning(level),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.portalCardSurface(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Active Warnings:',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.portalAccent(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '$activeWarningCount / 3',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.portalAccent(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (violations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Past Infractions:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.portalTextSecondary(context),
              ),
            ),
            const SizedBox(height: 6),
            ...violations
                .take(2)
                .map(
                  (v) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 6, color: AppColors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${v['type'] ?? 'Violation'} (${v['date']?.toString().substring(0, 10) ?? ''})',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.portalTextPrimary(context),
                            ),
                          ),
                        ),
                        StatusBadge(
                          label: v['status'] ?? 'Pending',
                          color: AppColors.forStatus(v['status']),
                          fontSize: 10,
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  void _beginStudentLookup(String studentNo, ViolationProvider vp) {
    final normalizedStudentNo = studentNo.trim().toUpperCase();
    if (normalizedStudentNo.isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();
    final requestId = ++_lookupRequestId;
    setState(() {
      _currentIndex = 0;
      _flowStep = 1;
      _scannedStudentNo = normalizedStudentNo;
      _studentSearchController.text = normalizedStudentNo;
      _scannerActive = false;
      _scannedStudentData = {};
      _selectedViolationType = null;
      _selectedSeverity = 'minor';
      _remarksController.clear();
      _isLookingUp = true;
      _lookupError = null;
    });
    _loadScannedStudent(normalizedStudentNo, vp, requestId);
  }

  void _resetStudentLookup() {
    _lookupRequestId++;
    setState(() {
      _flowStep = 1;
      _scannerActive = true;
      _scannedStudentNo = null;
      _scannedStudentData = {};
      _selectedViolationType = null;
      _selectedSeverity = 'minor';
      _remarksController.clear();
      _studentSearchController.clear();
      _isLookingUp = false;
      _lookupError = null;
    });
  }

  Future<void> _loadScannedStudent(
    String studentNo,
    ViolationProvider vp,
    int requestId,
  ) async {
    await vp.validateStudent(studentNo);
    if (!mounted || requestId != _lookupRequestId) return;
    setState(() {
      _scannedStudentData = vp.validatedStudent;
      _lookupError = vp.error;
      _isLookingUp = false;
      if (_scannedStudentData.isNotEmpty) {
        _flowStep = 2;
      }
    });
  }

  Future<void> _submitViolation() async {
    if (_scannedStudentNo == null || _scannedStudentData.isEmpty) {
      _showSnack('Please scan or lookup a student first', isError: true);
      return;
    }
    if (_selectedViolationType == null) {
      _showSnack(
        'Please select a violation type from the presets',
        isError: true,
      );
      return;
    }
    if (_selectedSeverity == 'critical') {
      final confirmed = await ConfirmationDialog.show(
        context,
        title: 'Record Critical Violation',
        message:
            'This violation will prohibit the student from entering campus until it is settled or the appeal is approved.',
        confirmLabel: 'Record Critical Violation',
        confirmColor: AppColors.red,
        icon: Icons.block_rounded,
      );
      if (!confirmed) return;
    }

    if (!mounted) return;
    final vp = Provider.of<ViolationProvider>(context, listen: false);
    final guardName =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.name ??
        'Officer';

    await vp.recordViolation(
      studentId: _scannedStudentNo!,
      type: _parseViolationType(_selectedViolationType!),
      reportedBy: guardName,
      remarks: _remarksController.text.trim(),
      severity: _selectedSeverity,
      violationName: _selectedViolationType!,
    );

    if (!mounted) return;
    if (vp.error == null) {
      _showSnack('Violation recorded successfully! ✓');
      _resetStudentLookup();
    } else {
      _showSnack(vp.error!, isError: true);
    }
  }

  ViolationType _parseViolationType(String type) {
    final t = type.toLowerCase();
    if (t.contains('uniform')) return ViolationType.noUniform;
    if (t.contains('piercing')) return ViolationType.piercing;
    if (t.contains('hair') || t.contains('color')) {
      return ViolationType.coloredHair;
    }
    return ViolationType.noId;
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.red : AppColors.safeGreen,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Officer Sign Out',
      message: 'Are you sure you want to end your shift and sign out?',
      confirmLabel: 'Sign Out',
      confirmColor: AppColors.red,
      icon: Icons.logout_rounded,
    );
    if (confirmed && context.mounted) {
      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }
}
