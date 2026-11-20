import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/violation.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../providers/violation_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/qr_widget.dart';
import '../widgets/ui_components.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final _appealController = TextEditingController();
  final _recordsSearchController = TextEditingController();
  String _recordsSearchQuery = '';
  int _selectedIndex = 0;
  int _recordFilter = 0; // 0 = All, 1 = Eligible, 2 = Appealed, 3 = Cleared
  bool _hasLoadedViolations = false;

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatRelativeTime(DateTime? date) {
    if (date == null) return 'â€”';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vp = Provider.of<ViolationProvider>(context, listen: false);
      vp.loadMyViolations().whenComplete(() {
        if (mounted) {
          setState(() => _hasLoadedViolations = true);
        }
      });
      vp.loadMyProfile();
      vp.loadMyQrCode();
      vp.loadNotifications();
    });
  }

  @override
  void dispose() {
    _appealController.dispose();
    _recordsSearchController.dispose();
    super.dispose();
  }

  void _showPhotoSourcePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: AppTheme.portalSurface(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.portalBorder(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Profile Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.portalTextPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose how you would like to set your profile picture',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.portalTextSecondary(context),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.portalSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkBorder
                      : const Color(0xFFEEEEEE),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.portalAccent(
                          context,
                        ).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: AppTheme.portalAccent(context),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      'Take a Photo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.portalTextPrimary(context),
                      ),
                    ),
                    subtitle: Text(
                      'Use device camera',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.portalTextSecondary(context),
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.portalTextMuted(context),
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _pickAndUploadPhoto(context, ImageSource.camera);
                    },
                  ),
                  Divider(
                    height: 1,
                    indent: 64,
                    color: AppTheme.portalBorder(context),
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.photo_library_outlined,
                        color: Color(0xFF6366F1),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      'Upload from Gallery',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.portalTextPrimary(context),
                      ),
                    ),
                    subtitle: Text(
                      'Choose from your photos',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.portalTextSecondary(context),
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.portalTextMuted(context),
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _pickAndUploadPhoto(context, ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(
    BuildContext context, [
    ImageSource source = ImageSource.gallery,
  ]) async {
    final picker = ImagePicker();
    final messenger = ScaffoldMessenger.maybeOf(context);
    final vp = Provider.of<ViolationProvider>(context, listen: false);
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 800,
    );
    if (picked == null) return;

    final error = await vp.uploadProfilePhoto(File(picked.path));

    if (!mounted || messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'Profile photo updated successfully!'),
        backgroundColor: error != null ? AppColors.red : AppColors.safeGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser;
    final name = currentUser?.name ?? 'Student';

    final pages = [
      _buildDashboardTab(name),
      _buildQrCodeTab(),
      _buildAppealsTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: IndexedStack(index: _selectedIndex, children: pages),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
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
            child: _buildHeaderContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return Row(
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
              child: Image.asset('assets/images/ACLC.png', fit: BoxFit.contain),
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
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.red.withValues(alpha: 0.55),
                  ),
                ),
                child: const Text(
                  'STUDENT PORTAL',
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
        _buildNotificationBell(),
      ],
    );
  }

  Widget _buildNotificationBell() {
    return Consumer<ViolationProvider>(
      builder: (context, vp, _) {
        final unread = vp.notifications.where((n) => !n.isRead).length;
        return PortalHeaderActionButton(
          icon: Icons.notifications_none_rounded,
          tooltip: unread > 0
              ? 'Notifications ($unread unread)'
              : 'Notifications',
          onPressed: _showNotificationsSheet,
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.14),
          badgeCount: unread,
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return PortalNavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.qr_code_scanner_outlined),
          selectedIcon: Icon(Icons.qr_code_scanner_rounded),
          label: 'Digital ID',
        ),
        NavigationDestination(
          icon: Icon(Icons.gavel_outlined),
          selectedIcon: Icon(Icons.gavel_rounded),
          label: 'Records',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }

  // â”€â”€ Home Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildDashboardTab(String name) {
    return Consumer<ViolationProvider>(
      builder: (context, vp, _) {
        final recentViolations = vp.violations.toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        final recentItems = recentViolations.take(3).toList();
        final studentNo =
            vp.studentProfile['student_no']?.toString() ??
            Provider.of<AuthProvider>(
              context,
              listen: false,
            ).currentUser?.studentNo ??
            'â€”';
        final standingLevel = vp.warningLevel.toLowerCase();
        return RefreshIndicator(
          onRefresh: () async {
            await vp.loadMyViolations();
            if (mounted) setState(() => _hasLoadedViolations = true);
            await vp.loadMyProfile();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d').format(DateTime.now()),
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.portalAccent(context)
                              : AppColors.navy,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Welcome, $name',
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
                      Row(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            color: AppTheme.portalTextMuted(context),
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Student no. $studentNo',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppTheme.portalTextSecondary(context)
                                    : AppTheme.portalTextSecondary(context),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Standing Level Card
                if (!_hasLoadedViolations && vp.violations.isEmpty)
                  _buildStandingStatusCard(isLoading: true)
                else if (vp.error != null && vp.violations.isEmpty)
                  _buildStandingStatusCard(
                    error: vp.error,
                    onRetry: () async {
                      await vp.loadMyViolations();
                      if (mounted) {
                        setState(() => _hasLoadedViolations = true);
                      }
                    },
                  )
                else
                  _buildStandingCard(standingLevel),
                const SizedBox(height: 24),

                Text(
                  'Quick access',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                _buildHomeQuickActions(),
                const SizedBox(height: 24),

                // Recent Activity
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recent records',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedIndex = 2),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (vp.isLoading)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(
                        color: AppTheme.portalAccent(context),
                      ),
                    ),
                  )
                else if (vp.error != null && vp.violations.isEmpty)
                  ErrorStateWidget(
                    title: 'Failed to load records',
                    message: vp.error,
                    onRetry: () async {
                      await vp.loadMyViolations();
                      await vp.loadMyProfile();
                    },
                  )
                else if (recentItems.isEmpty && !_hasLoadedViolations)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(
                        color: AppTheme.portalAccent(context),
                      ),
                    ),
                  )
                else if (recentItems.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.safeGreenBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.verified_user_rounded,
                            color: AppColors.safeGreen,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good Disciplinary Standing',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.portalTextPrimary(context),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'No violations recorded. Keep up the good standing!',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.portalTextSecondary(context),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _buildRecentRecords(recentItems),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStandingStatusCard({
    bool isLoading = false,
    String? error,
    VoidCallback? onRetry,
  }) {
    final title = isLoading ? 'Checking your standing' : 'Standing unavailable';
    final message = isLoading
        ? 'Loading your student record. This may take a moment.'
        : 'We could not verify your standing. Please try again.';
    final color = isLoading
        ? AppTheme.portalAccent(context)
        : AppColors.warningAmber;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.cloud_off_outlined, color: color, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.portalTextPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            error == null ? message : '$message ($error)',
            style: TextStyle(
              color: AppTheme.portalTextSecondary(context),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (!isLoading && onRetry != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh_rounded, size: 16),
                label: Text('Try again'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHomeQuickActions() {
    return Container(
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
      child: Column(
        children: [
          _menuOptionTile(
            icon: Icons.qr_code_2_rounded,
            title: 'Digital ID',
            subtitle: 'Show your campus QR',
            onTap: () => setState(() => _selectedIndex = 1),
            isFirst: true,
          ),
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: AppTheme.portalBorder(context),
          ),
          _menuOptionTile(
            icon: Icons.assignment_outlined,
            title: 'Records & appeals',
            subtitle: 'Review or appeal an entry',
            onTap: () => setState(() => _selectedIndex = 2),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStandingCard(String level) {
    Color accentColor;
    String statusTitle;
    String statusDescription;
    IconData icon;

    switch (level) {
      case 'red':
      case 'critical':
        accentColor = AppColors.dangerRed;
        statusTitle = 'Action required';
        statusDescription =
            'Please contact the Student Affairs Office about your record.';
        icon = Icons.error_outline_rounded;
        break;
      case 'yellow':
      case 'warning':
        accentColor = AppColors.warningAmber;
        statusTitle = 'Needs attention';
        statusDescription =
            'Review your records and avoid further infractions.';
        icon = Icons.warning_amber_rounded;
        break;
      default:
        accentColor = AppColors.safeGreen;
        statusTitle = 'Good standing';
        statusDescription = 'No active concerns on your disciplinary record.';
        icon = Icons.check_circle_outline_rounded;
    }

    return Semantics(
      label: 'Standing status: $statusTitle. $statusDescription',
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CAMPUS STANDING',
                        style: TextStyle(
                          color: AppTheme.portalTextMuted(context),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        statusTitle,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.portalTextPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    level.toUpperCase(),
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 15),
              child: Text(
                statusDescription,
                style: TextStyle(
                  color: AppTheme.portalTextSecondary(context),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
            StandingGauge(level: level),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRecords(List<Violation> violations) {
    return Container(
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
      child: Column(
        children: [
          for (int i = 0; i < violations.length; i++) ...[
            _recentViolationTile(
              violations[i],
              isFirst: i == 0,
              isLast: i == violations.length - 1,
            ),
            if (i < violations.length - 1)
              Divider(
                height: 1,
                indent: 56,
                endIndent: 16,
                color: AppTheme.portalBorder(context),
              ),
          ],
        ],
      ),
    );
  }

  Widget _recentViolationTile(
    Violation v, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final title = v.violationName ?? v.violationDescription;
    final date = _formatDate(v.date);
    final status = v.statusDescription;
    final severity = v.severity ?? 'minor';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(20) : Radius.zero,
          bottom: isLast ? const Radius.circular(20) : Radius.zero,
        ),
        onTap: () => _showRecordDetails(v),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.forSeverity(severity).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  AppColors.iconForSeverity(severity),
                  color: AppColors.forSeverity(severity),
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.portalTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.portalTextSecondary(context),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppTheme.portalTextMuted(context),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.forStatus(status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.portalTextMuted(context),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // â”€â”€ Digital ID / QR Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildQrCodeTab() {
    return Consumer<ViolationProvider>(
      builder: (context, vp, _) {
        final currentUser = Provider.of<AuthProvider>(
          context,
          listen: false,
        ).currentUser;
        final studentName =
            vp.studentProfile['name']?.toString() ??
            currentUser?.name ??
            'Student';
        final studentNo =
            vp.studentProfile['student_no']?.toString() ??
            currentUser?.studentNo ??
            'â€”';
        final course = vp.studentProfile['course']?.toString() ?? 'â€”';
        final year = vp.studentProfile['year']?.toString() ?? 'â€”';

        final screenWidth = MediaQuery.of(context).size.width;
        final qrSize = (screenWidth * 0.68).clamp(220.0, 275.0);

        return RefreshIndicator(
          onRefresh: () => vp.loadMyQrCode(),
          color: AppTheme.portalAccent(context),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                // Reference Header: "ÐÐ°ÐºÐ¾Ð¿Ð¸Ñ‚ÑŒ S-ÐºÐ¾Ð¸Ð½Ñ‹" -> Centered bold headline
                Text(
                  'Digital Student ID',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),
                // Reference Subtitle: "ÐŸÐ¾Ð´Ð½ÐµÑÐ¸Ñ‚Ðµ QR-ÐºÐ¾Ð´ Ðº ÑÐºÐ°Ð½ÐµÑ€Ñƒ Ð½Ð° ÐºÐ°ÑÑÐµ, ÑƒÐ´ÐµÑ€Ð¶Ð¸Ð²Ð°Ñ Ñ‚ÐµÐ»ÐµÑ„Ð¾Ð½ Ð½Ð° Ñ€Ð°ÑÑÑ‚Ð¾ÑÐ½Ð¸Ð¸ ~10 ÑÐ¼"
                Text(
                  'Hold your QR code in front of the scanner at the gate,\nkeeping your phone at a distance of ~10 cm',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: AppTheme.portalTextSecondary(context),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 36),

                // QR Presentation matching reference design
                if (vp.isLoading)
                  SizedBox(
                    height: qrSize,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.portalAccent(context),
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Centered large clean QR code
                      MinimalQrCard(
                        data: studentNo != 'â€”' ? studentNo : 'DEMO-STUDENT',
                        base64Image: vp.studentQrCode,
                        size: qrSize,
                        onTap: () => _showFullscreenQr(
                          context,
                          vp.studentQrCode,
                          studentName,
                          studentNo,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Subtle vertical indicator bar from reference screenshot
                      Container(
                        width: 1.5,
                        height: qrSize * 0.76,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E2E2),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 28),

                // Verification status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: Color(0xFF16A34A),
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Ready for Gate Verification',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Student Identity Details
                Text(
                  studentName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Student No: $studentNo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.portalTextSecondary(context)
                        : const Color(0xFF616161),
                  ),
                ),
                if (course != 'â€”' || year != 'â€”') ...[
                  const SizedBox(height: 3),
                  Text(
                    '$course, Year $year',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.portalTextMuted(context),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Action controls: Enlarge & Refresh
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showFullscreenQr(
                        context,
                        vp.studentQrCode,
                        studentName,
                        studentNo,
                      ),
                      icon: Icon(Icons.fullscreen_rounded, size: 18),
                      label: Text(
                        'Enlarge',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.portalAccent(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: vp.isLoading ? null : () => vp.loadMyQrCode(),
                      icon: Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        'Refresh',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.portalTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // â”€â”€ Records & Appeals Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  bool _hasAppeal(Violation violation) {
    final appealStatus = violation.appealStatus?.trim().toLowerCase();
    return appealStatus != null &&
        appealStatus.isNotEmpty &&
        appealStatus != 'none';
  }

  bool _isCleared(Violation violation) =>
      violation.status == ViolationStatus.cleared ||
      violation.appealStatus?.trim().toLowerCase() == 'approved';

  bool _isEligibleForAppeal(Violation violation) =>
      !_hasAppeal(violation) && !_isCleared(violation);

  Widget _buildAppealsTab() {
    return Consumer<ViolationProvider>(
      builder: (context, vp, _) {
        final appealable = vp.violations.where(_isEligibleForAppeal).toList();
        final appealed = vp.violations.where(_hasAppeal).toList();
        final cleared = vp.violations.where(_isCleared).toList();

        List<Violation> filteredList;
        if (_recordFilter == 1) {
          filteredList = appealable;
        } else if (_recordFilter == 2) {
          filteredList = appealed;
        } else if (_recordFilter == 3) {
          filteredList = cleared;
        } else {
          filteredList = vp.violations;
        }

        // Live search filtering
        if (_recordsSearchQuery.trim().isNotEmpty) {
          final query = _recordsSearchQuery.trim().toLowerCase();
          filteredList = filteredList.where((v) {
            final title = (v.violationName ?? v.violationDescription)
                .toLowerCase();
            final remarks = (v.remarks ?? '').toLowerCase();
            final date = _formatDate(v.date).toLowerCase();
            final severity = (v.severity ?? '').toLowerCase();
            final appealStat = (v.appealStatus ?? '').toLowerCase();
            return title.contains(query) ||
                remarks.contains(query) ||
                date.contains(query) ||
                severity.contains(query) ||
                appealStat.contains(query);
          }).toList();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await vp.loadMyViolations();
            if (mounted) setState(() => _hasLoadedViolations = true);
          },
          color: AppTheme.portalAccent(context),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Records & appeals',
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
                        'Review your violations and appeal eligible records.',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.portalTextSecondary(context)
                              : AppTheme.portalTextSecondary(context),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                if (vp.violations.isEmpty &&
                    _hasLoadedViolations &&
                    vp.error == null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.portalCardSurface(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkBorder
                            : const Color(0xFFEEEEEE),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.verified_user_rounded,
                            color: Color(0xFF16A34A),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good Disciplinary Standing',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'No disciplinary infractions on record.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppTheme.portalTextSecondary(context)
                                      : const Color(0xFF757575),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else if (vp.violations.isNotEmpty) ...[
                  Container(
                    key: const ValueKey('student-records-summary'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.portalCardSurface(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkBorder
                            : const Color(0xFFEEEEEE),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _metricStatCard(
                            'Total',
                            '${vp.violations.length}',
                            Icons.receipt_long_rounded,
                            AppColors.navy,
                            _recordFilter == 0,
                            () => setState(() => _recordFilter = 0),
                          ),
                        ),
                        _verticalDivider(),
                        Expanded(
                          child: _metricStatCard(
                            'Eligible for Appeal',
                            '${appealable.length}',
                            Icons.rate_review_outlined,
                            AppColors.warningAmber,
                            _recordFilter == 1,
                            () => setState(() => _recordFilter = 1),
                          ),
                        ),
                        _verticalDivider(),
                        Expanded(
                          child: _metricStatCard(
                            'Appealed',
                            '${appealed.length}',
                            Icons.history_edu_rounded,
                            const Color(0xFF6366F1),
                            _recordFilter == 2,
                            () => setState(() => _recordFilter = 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (vp.violations.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.portalCardSurface(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkBorder
                            : const Color(0xFFEEEEEE),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _recordsSearchController,
                      onChanged: (val) =>
                          setState(() => _recordsSearchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search violations, remarks...',
                        hintStyle: TextStyle(
                          fontSize: 13.5,
                          color: AppTheme.portalTextMuted(context),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppTheme.portalTextMuted(context),
                        ),
                        suffixIcon: _recordsSearchQuery.isNotEmpty
                            ? PortalClearButton(
                                tooltip: 'Clear search',
                                onPressed: () => setState(() {
                                  _recordsSearchController.clear();
                                  _recordsSearchQuery = '';
                                }),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    key: const ValueKey('student-record-filters'),
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _filterChip(0, 'All (${vp.violations.length})'),
                      _filterChip(
                        1,
                        'Eligible for Appeal (${appealable.length})',
                      ),
                      _filterChip(2, 'Appealed (${appealed.length})'),
                      _filterChip(3, 'Cleared (${cleared.length})'),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                // Record List
                if ((!_hasLoadedViolations || vp.isLoading) &&
                    vp.violations.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        color: AppTheme.portalAccent(context),
                      ),
                    ),
                  )
                else if (vp.error != null && vp.violations.isEmpty)
                  ErrorStateWidget(
                    title: 'Unable to retrieve records',
                    message: vp.error,
                    onRetry: () => vp.loadMyViolations(),
                  )
                else if (vp.violations.isEmpty)
                  const SizedBox.shrink()
                else if (filteredList.isEmpty)
                  EmptyStateWidget(
                    icon: _recordsSearchQuery.isNotEmpty
                        ? Icons.search_off_rounded
                        : Icons.assignment_turned_in_outlined,
                    title: _recordsSearchQuery.isNotEmpty
                        ? 'No Matching Records'
                        : 'No Records in this Category',
                    message: _recordsSearchQuery.isNotEmpty
                        ? 'No violations match "$_recordsSearchQuery". Try another keyword or clear search.'
                        : 'There are no violation records matching this category.',
                    actionLabel: 'View all records',
                    onAction: () => setState(() {
                      _recordFilter = 0;
                      _recordsSearchController.clear();
                      _recordsSearchQuery = '';
                    }),
                  )
                else
                  // All record rows in one profile-style white card
                  Container(
                    key: const ValueKey('student-records-list'),
                    decoration: BoxDecoration(
                      color: AppTheme.portalCardSurface(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkBorder
                            : const Color(0xFFEEEEEE),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < filteredList.length; i++) ...[
                          _buildRecordCard(
                            filteredList[i],
                            isFirst: i == 0,
                            isLast: i == filteredList.length - 1,
                          ),
                          if (i < filteredList.length - 1)
                            Divider(
                              height: 1,
                              indent: 56,
                              endIndent: 16,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.darkBorder
                                  : const Color(0xFFF3F4F6),
                            ),
                        ],
                      ],
                    ),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBorder
          : const Color(0xFFF3F4F6),
    );
  }

  Widget _metricStatCard(
    String label,
    String count,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSelected
              ? color.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.18
                      : 0.06,
                )
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? (Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.portalAccent(context)
                          : color)
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? (Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.portalAccent(context)
                          : color)
                    : Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.portalTextSecondary(context)
                    : const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(int index, String label) {
    final selected = _recordFilter == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? AppColors.darkAccentSurface : AppColors.navy;
    return GestureDetector(
      onTap: () => setState(() => _recordFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? selectedColor : AppTheme.portalCardSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? selectedColor
                : (isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE)),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? Colors.white
                : (isDark
                      ? AppTheme.portalTextSecondary(context)
                      : const Color(0xFF4B5563)),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(
    Violation v, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final title = v.violationName ?? v.violationDescription;
    final date = _formatDate(v.date);
    final relativeTime = _formatRelativeTime(v.date);
    final severity = v.severity ?? 'minor';
    final hasAppealed = _hasAppeal(v);
    final isCleared = _isCleared(v);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final severityColor = AppColors.forSeverity(severity);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(20) : Radius.zero,
          bottom: isLast ? const Radius.circular(20) : Radius.zero,
        ),
        onTap: () => _showRecordDetails(v),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Severity dot indicator (matches profile icon column width)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: severityColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Severity badge (pill)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: severityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            severity.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: severityColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$date | $relativeTime',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.portalTextSecondary(context)
                            : AppTheme.portalTextMuted(context),
                      ),
                    ),
                    if ((v.remarks ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        v.remarks!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? AppTheme.portalTextSecondary(context)
                              : const Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Offense count pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBorder
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Offense #${v.offenseCount}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.portalTextPrimary(context)
                                  : const Color(0xFF4B5563),
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (!hasAppealed && !isCleared)
                          GestureDetector(
                            onTap: () => _showAppealDialog(v.id, title),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkAccentSurface
                                    : AppColors.navy,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Appeal',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        else if (hasAppealed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.forWarning(
                                v.appealStatus,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Appeal: ${v.appealStatus}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.forWarning(v.appealStatus),
                              ),
                            ),
                          )
                        else
                          Row(
                            children: [
                              Text(
                                'View Details',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.portalAccent(context),
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: AppTheme.portalAccent(context),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecordDetails(Violation v) {
    final title = v.violationName ?? v.violationDescription;
    final date = _formatDate(v.date);
    final relativeTime = _formatRelativeTime(v.date);
    final severity = v.severity ?? 'minor';
    final hasAppealed = _hasAppeal(v);
    final isCleared = _isCleared(v);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppTheme.portalSurface(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.portalBorder(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.portalAccent(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Recorded on $date - $relativeTime',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.portalTextSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PortalCloseButton(
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1),

              // Details Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Badges Strip
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusBadge(
                          label: 'Offense #${v.offenseCount}',
                          color: AppTheme.portalAccent(context),
                          icon: Icons.tag_rounded,
                        ),
                        StatusBadge(
                          label: severity.toUpperCase(),
                          color: AppColors.forSeverity(severity),
                          icon: AppColors.iconForSeverity(severity),
                        ),
                        StatusBadge(
                          label: v.statusDescription,
                          color: AppColors.forStatus(v.statusDescription),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Incident Information Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.portalCardSurface(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.portalBorder(context),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: AppTheme.portalAccent(context),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Incident Information',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.portalTextPrimary(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _detailRow(
                            'Reported By',
                            v.reportedBy ?? 'Gate Security Personnel',
                          ),
                          const SizedBox(height: 8),
                          _detailRow('Date Logged', date),
                          const SizedBox(height: 8),
                          _detailRow(
                            'Severity Classification',
                            '${severity.toUpperCase()} Infraction',
                          ),
                          if ((v.remarks ?? '').isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Officer Remarks:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.portalTextSecondary(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.portalSurface(context),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.portalBorder(context),
                                ),
                              ),
                              child: Text(
                                v.remarks!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.portalTextPrimary(context),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Student Handbook Policy Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.portalCardSurface(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.portalBorder(context),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 20,
                            color: AppTheme.portalAccent(context),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Student Conduct Handbook Policy',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.portalTextPrimary(context),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'All students are required to observe ACLC campus policies. Infractions are recorded in the central SAO system. Students in good standing retain full eligibility for institutional honors and clearances.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.portalTextSecondary(
                                      context,
                                    ),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Appeal Section
                    if (!hasAppealed && !isCleared) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.portalCardSurface(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.portalBorder(context),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.rate_review_outlined,
                                  size: 18,
                                  color: AppTheme.portalAccent(context),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Eligible for Appeal',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.portalTextPrimary(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'If this infraction was recorded incorrectly or you had an approved exemption (e.g., medical, authorized event), you may submit an appeal to the Student Affairs Office.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.portalTextSecondary(context),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(sheetCtx).pop();
                                  _showAppealDialog(v.id, title);
                                },
                                icon: Icon(Icons.gavel_rounded, size: 18),
                                label: Text('File an Appeal for this Citation'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.navy,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (hasAppealed) ...[
                      // Appeal Progress Stepper
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.portalCardSurface(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.portalBorder(context),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.history_edu_rounded,
                                      size: 18,
                                      color: AppTheme.portalAccent(context),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Appeal Progress',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.portalTextPrimary(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                StatusBadge(
                                  label: v.appealStatus ?? 'In Review',
                                  color: AppColors.forWarning(v.appealStatus),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildAppealStepper(v.appealStatus ?? 'Pending'),
                            if ((v.appealRemarks ?? '').isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(
                                'Appeal Statement / SAO Notes:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.portalTextSecondary(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.portalSurface(context),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.portalBorder(context),
                                  ),
                                ),
                                child: Text(
                                  v.appealRemarks!,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppTheme.portalTextPrimary(context),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppealStepper(String status) {
    final s = status.toLowerCase();
    final isApproved = s == 'approved';
    final isRejected = s == 'rejected';
    final isDone = isApproved || isRejected;

    return Row(
      children: [
        _stepperNode('Submitted', true),
        Expanded(
          child: Container(height: 2, color: AppTheme.portalAccent(context)),
        ),
        _stepperNode('SAO Review', isDone || s == 'pending'),
        Expanded(
          child: Container(
            height: 2,
            color: isDone
                ? (isApproved ? AppColors.safeGreen : AppColors.red)
                : AppTheme.portalTextSecondary(context),
          ),
        ),
        _stepperNode(
          isApproved ? 'Approved' : (isRejected ? 'Rejected' : 'Decision'),
          isDone,
          isApproved
              ? AppColors.safeGreen
              : (isRejected ? AppColors.red : null),
        ),
      ],
    );
  }

  Widget _stepperNode(String label, bool active, [Color? customColor]) {
    final color =
        customColor ??
        (active
            ? AppTheme.portalAccent(context)
            : AppTheme.portalTextMuted(context));
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: active ? color : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(
            active ? Icons.check_rounded : Icons.hourglass_empty_rounded,
            size: 14,
            color: active
                ? (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkBackground
                      : Colors.white)
                : color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.portalTextSecondary(context),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.portalTextPrimary(context),
          ),
        ),
      ],
    );
  }

  // â”€â”€ Profile Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildProfileTab() {
    return Consumer<ViolationProvider>(
      builder: (context, vp, _) {
        final profile = vp.studentProfile;
        final currentUser = Provider.of<AuthProvider>(
          context,
          listen: false,
        ).currentUser;
        final displayName =
            profile['name']?.toString() ?? currentUser?.name ?? 'Student';
        final studentNo =
            profile['student_no']?.toString() ??
            currentUser?.studentNo ??
            'â€”';
        final email =
            profile['email']?.toString() ??
            currentUser?.username ??
            'student@aclc.edu.ph';

        return RefreshIndicator(
          onRefresh: () => vp.loadMyProfile(),
          color: AppTheme.portalAccent(context),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),

                // Centered User Avatar
                GestureDetector(
                  onTap: () => _showPhotoSourcePicker(context),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.portalTextPrimary(context),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFFF3F4F6),
                          backgroundImage:
                              (profile['profile_photo'] != null &&
                                  profile['profile_photo']
                                      .toString()
                                      .isNotEmpty)
                              ? MemoryImage(
                                  base64Decode(profile['profile_photo']),
                                )
                              : null,
                          child:
                              (profile['profile_photo'] == null ||
                                  profile['profile_photo'].toString().isEmpty)
                              ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : 'S',
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.portalAccent(context),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.portalSurface(context),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.portalBorder(context),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 15,
                            color: AppTheme.portalAccent(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // User Name & Subtitle Email
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.portalTextSecondary(context)
                        : AppTheme.portalTextSecondary(context),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 28),

                Column(
                  children: [
                    AppCard(
                      key: const ValueKey('profile-menu-edit'),
                      padding: EdgeInsets.zero,
                      child: _menuOptionTile(
                        icon: Icons.mode_edit_outline_rounded,
                        title: 'Edit Profile',
                        onTap: () => _showEditProfileSheet(
                          profile,
                          displayName,
                          studentNo,
                        ),
                        isFirst: true,
                        isLast: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppCard(
                      key: const ValueKey('profile-menu-account'),
                      padding: EdgeInsets.zero,
                      child: _menuOptionTile(
                        icon: Icons.settings_outlined,
                        title: 'Account Settings',
                        onTap: () =>
                            _showAccountSettingsSheet(profile, studentNo),
                        isFirst: true,
                        isLast: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppCard(
                      key: const ValueKey('profile-menu-notifications'),
                      padding: EdgeInsets.zero,
                      child: _menuOptionTile(
                        icon: Icons.notifications_none_outlined,
                        title: 'Notification Preferences',
                        onTap: _showNotificationPreferencesSheet,
                        isFirst: true,
                        isLast: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppCard(
                      key: const ValueKey('profile-menu-privacy'),
                      padding: EdgeInsets.zero,
                      child: _menuOptionTile(
                        icon: Icons.shield_outlined,
                        title: 'Privacy & Security',
                        onTap: _showPrivacySecuritySheet,
                        isFirst: true,
                        isLast: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppCard(
                      key: const ValueKey('profile-menu-help'),
                      padding: EdgeInsets.zero,
                      child: _menuOptionTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        onTap: _showHelpSupportSheet,
                        isFirst: true,
                        isLast: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                PortalSignOutButton(onPressed: _showLogoutDialog),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    bool isDestructive = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final titleColor = isDestructive
        ? const Color(0xFFEF4444)
        : AppTheme.portalTextPrimary(context);
    final iconColor = isDestructive
        ? const Color(0xFFEF4444)
        : AppTheme.portalTextSecondary(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(20) : Radius.zero,
          bottom: isLast ? const Radius.circular(20) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isDestructive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: titleColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.portalTextSecondary(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isDestructive)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppTheme.portalTextMuted(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // â”€â”€ Profile Sub-sheets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showEditProfileSheet(
    Map<String, dynamic> profile,
    String name,
    String studentNo,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppTheme.portalSurface(sheetCtx),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.portalBorder(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Student Profile Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.portalAccent(context),
                        ),
                      ),
                    ),
                    PortalCloseButton(
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _showPhotoSourcePicker(context),
                        icon: Icon(Icons.camera_alt_outlined, size: 18),
                        label: Text('Update Profile Photo'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _profileInfoCard('Full Name', name, Icons.person_outline),
                    const SizedBox(height: 10),
                    _profileInfoCard(
                      'Student No.',
                      studentNo,
                      Icons.badge_outlined,
                    ),
                    const SizedBox(height: 10),
                    _profileInfoCard(
                      'Program / Course',
                      profile['course'] ?? 'â€”',
                      Icons.school_outlined,
                    ),
                    const SizedBox(height: 10),
                    _profileInfoCard(
                      'Year Level',
                      'Year ${profile['year']?.toString() ?? 'â€”'}',
                      Icons.stairs_outlined,
                    ),
                    const SizedBox(height: 10),
                    _profileInfoCard(
                      'Contact Number',
                      profile['contact_number'] ?? 'â€”',
                      Icons.phone_outlined,
                    ),
                    const SizedBox(height: 10),
                    _profileInfoCard(
                      'Home Address',
                      profile['address'] ?? 'â€”',
                      Icons.home_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountSettingsSheet(
    Map<String, dynamic> profile,
    String studentNo,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: AppTheme.portalSurface(sheetCtx),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Material(
          color: Colors.transparent,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Account Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.portalAccent(context),
                      ),
                    ),
                    PortalCloseButton(
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Dark mode',
                    style: TextStyle(
                      color: AppTheme.portalTextPrimary(context),
                    ),
                  ),
                  subtitle: Text(
                    'Use a darker appearance for the portal',
                    style: TextStyle(
                      color: AppTheme.portalTextSecondary(context),
                    ),
                  ),
                  value: Theme.of(sheetCtx).brightness == Brightness.dark,
                  onChanged: sheetCtx.read<ThemeModeProvider>().setDarkMode,
                ),
                const SizedBox(height: 8),
                _profileInfoCard(
                  'Campus Branch',
                  'ACLC College of Mandaue',
                  Icons.location_on_outlined,
                ),
                const SizedBox(height: 10),
                _profileInfoCard(
                  'Account Status',
                  profile['status'] ?? 'Active Student',
                  Icons.check_circle_outline,
                ),
                const SizedBox(height: 10),
                _profileInfoCard(
                  'Portal Role',
                  'Student User',
                  Icons.verified_user_outlined,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationPreferencesSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: BoxDecoration(
            color: AppTheme.portalSurface(sheetCtx),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notification Preferences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.portalAccent(context),
                    ),
                  ),
                  PortalCloseButton(
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: true,
                onChanged: (val) {},
                title: Text('Disciplinary Infraction Alerts'),
                subtitle: Text(
                  'Instant notification when an infraction is logged',
                ),
                activeThumbColor: AppTheme.portalAccent(context),
              ),
              SwitchListTile(
                value: true,
                onChanged: (val) {},
                title: Text('Appeal Status Updates'),
                subtitle: Text('Receive alerts when SAO reviews an appeal'),
                activeThumbColor: AppTheme.portalAccent(context),
              ),
              SwitchListTile(
                value: true,
                onChanged: (val) {},
                title: Text('Gate Verification Notices'),
                subtitle: Text(
                  'Notifications when scanned at campus turnstiles',
                ),
                activeThumbColor: AppTheme.portalAccent(context),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacySecuritySheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: AppTheme.portalSurface(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Privacy & Security',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.portalAccent(context),
                  ),
                ),
                PortalCloseButton(
                  onPressed: () => Navigator.of(sheetCtx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(
                Icons.lock_outline,
                color: AppTheme.portalAccent(context),
              ),
              title: Text('Change Password'),
              subtitle: Text('Manage portal credentials'),
              trailing: Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _showChangePasswordDialog();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.security,
                color: AppTheme.portalAccent(context),
              ),
              title: Text('Session Protection'),
              subtitle: Text(
                'Token encryption and session authentication active',
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    try {
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Change Password',
                style: TextStyle(
                  color: AppTheme.portalAccent(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: currentPasswordController,
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
                        controller: newPasswordController,
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
                          if (value == currentPasswordController.text) {
                            return 'Choose a password different from the current one';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPasswordController,
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
                        validator: (value) =>
                            value != newPasswordController.text
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
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() {
                            isSubmitting = true;
                            errorMessage = null;
                          });

                          final authProvider = Provider.of<AuthProvider>(
                            dialogContext,
                            listen: false,
                          );
                          final error = await authProvider.changePassword(
                            currentPassword: currentPasswordController.text,
                            newPassword: newPasswordController.text,
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
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Password changed successfully.'),
                              backgroundColor: AppColors.safeGreen,
                            ),
                          );
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Change Password'),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    }
  }

  void _showHelpSupportSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: AppTheme.portalSurface(sheetCtx),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Help & Support',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.portalAccent(context),
                  ),
                ),
                PortalCloseButton(
                  onPressed: () => Navigator.of(sheetCtx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _profileInfoCard(
              'Student Affairs Office',
              'ACLC Mandaue Campus, 2nd Floor',
              Icons.business_outlined,
            ),
            const SizedBox(height: 10),
            _profileInfoCard(
              'Inquiries / Support Email',
              'sao.mandaue@aclc.edu.ph',
              Icons.mail_outline,
            ),
            const SizedBox(height: 10),
            _profileInfoCard(
              'Office Hours',
              'Monday - Friday | 8:00 AM - 5:00 PM',
              Icons.access_time_outlined,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _profileInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.portalSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.portalBorder(context)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.portalAccent(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.portalTextSecondary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.portalTextPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullscreenQr(
    BuildContext context,
    String? qrBase64,
    String name,
    String studentNo,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: AppTheme.portalSurface(dialogCtx),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Campus Gate Pass',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.portalAccent(context),
                    ),
                  ),
                  PortalCloseButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              MinimalQrCard(
                data: studentNo != 'â€”' ? studentNo : 'DEMO-STUDENT',
                base64Image: qrBase64,
                size: 240,
              ),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.portalAccent(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Student No: $studentNo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.portalTextSecondary(context),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.safeGreenBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.safeGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 14,
                      color: AppColors.safeGreen,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Ready for Scanner Verification',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.safeGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // â”€â”€ Appeal Dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showAppealDialog(String violationId, [String? violationName]) {
    _appealController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final text = _appealController.text.trim();
          final hasMinChars = text.length >= 20;

          final templates = [
            'Authorized off-campus school activity approved by department.',
            'Medical emergency or health condition with clinical excuse slip.',
            'Approved uniform exemption granted by Student Affairs / Dean.',
            'Wrong student number logged; I was in class during this time.',
          ];

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.gavel_rounded,
                  color: AppTheme.portalAccent(context),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submit Disciplinary Appeal',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.portalAccent(context),
                        ),
                      ),
                      if (violationName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          violationName,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.portalTextSecondary(context),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Justification Templates:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.portalTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: Icon(Icons.event_note_rounded, size: 14),
                        label: Text(
                          'School Event',
                          style: TextStyle(fontSize: 11),
                        ),
                        onPressed: () {
                          _appealController.text = templates[0];
                          setDialogState(() {});
                        },
                      ),
                      ActionChip(
                        avatar: Icon(Icons.medical_services_outlined, size: 14),
                        label: Text('Medical', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          _appealController.text = templates[1];
                          setDialogState(() {});
                        },
                      ),
                      ActionChip(
                        avatar: Icon(Icons.check_circle_outline, size: 14),
                        label: Text(
                          'Uniform Exemption',
                          style: TextStyle(fontSize: 11),
                        ),
                        onPressed: () {
                          _appealController.text = templates[2];
                          setDialogState(() {});
                        },
                      ),
                      ActionChip(
                        avatar: Icon(Icons.badge_outlined, size: 14),
                        label: Text('Wrong ID', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          _appealController.text = templates[3];
                          setDialogState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Detailed Statement:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.portalTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _appealController,
                    maxLines: 4,
                    maxLength: 500,
                    style: TextStyle(fontSize: 13.5),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      hintText:
                          'Explain in detail why this citation was issued in error or provide justification...',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        hasMinChars
                            ? Icons.check_circle_outline_rounded
                            : Icons.info_outline_rounded,
                        size: 14,
                        color: hasMinChars
                            ? AppColors.safeGreen
                            : AppColors.warningAmber,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasMinChars
                            ? 'Ready to submit (${text.length}/500 chars)'
                            : 'Minimum 20 characters required (${text.length}/20)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: hasMinChars
                              ? AppColors.safeGreen
                              : AppColors.warningAmber,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Cancel'),
              ),
              Consumer<ViolationProvider>(
                builder: (ctx, vp, _) => ElevatedButton(
                  onPressed: (!hasMinChars || vp.isLoading)
                      ? null
                      : () async {
                          await vp.submitAppeal(violationId, text);
                          if (!mounted || !dialogContext.mounted) return;
                          Navigator.of(dialogContext).pop();
                          _showSnack(
                            vp.error == null
                                ? 'Appeal submitted successfully for SAO review.'
                                : vp.error!,
                            isError: vp.error != null,
                          );
                          if (vp.error == null) vp.loadMyViolations();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: vp.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text('Submit Appeal'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // â”€â”€ Notifications Bottom Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showNotificationsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppTheme.portalSurface(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Notifications',
                          style: TextStyle(
                            color: AppTheme.portalAccent(context),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Consumer<ViolationProvider>(
                        builder: (context, vp, _) {
                          final unread = vp.notifications
                              .where((n) => !n.isRead)
                              .length;
                          if (unread == 0) return const SizedBox.shrink();
                          return TextButton(
                            onPressed: vp.isLoading
                                ? null
                                : vp.markAllNotificationsAsRead,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text('Mark all read'),
                          );
                        },
                      ),
                      PortalCloseButton(
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1),
                Expanded(
                  child: Consumer<ViolationProvider>(
                    builder: (context, vp, _) {
                      if (vp.isLoading && vp.notifications.isEmpty) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.portalAccent(context),
                          ),
                        );
                      }
                      if (vp.notifications.isEmpty) {
                        return const EmptyStateWidget(
                          icon: Icons.notifications_none_rounded,
                          title: 'No Notifications',
                          message: 'You have no recent updates or alerts.',
                        );
                      }
                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: vp.notifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final notif = vp.notifications[index];
                          return AppCard(
                            padding: const EdgeInsets.all(14),
                            backgroundColor: notif.isRead
                                ? AppTheme.portalSurface(context)
                                : Theme.of(context).brightness ==
                                      Brightness.dark
                                ? AppColors.darkAccentSurface
                                : AppColors.navySurface,
                            onTap: () async {
                              if (!notif.isRead) {
                                await vp.markNotificationAsRead(notif.id);
                              }
                              if (!context.mounted) return;
                              _showNotificationDetails(
                                notif.title,
                                notif.message,
                                notif.createdAt,
                              );
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: notif.isRead
                                        ? AppTheme.portalBorder(context)
                                        : AppColors.navy,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.notifications_active_rounded,
                                    size: 16,
                                    color: notif.isRead
                                        ? AppTheme.portalTextSecondary(context)
                                        : Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notif.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: notif.isRead
                                              ? FontWeight.w600
                                              : FontWeight.w700,
                                          color: AppTheme.portalTextPrimary(
                                            context,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif.message,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.portalTextSecondary(
                                            context,
                                          ),
                                          height: 1.35,
                                        ),
                                      ),
                                      if (notif.createdAt != null) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: 12,
                                              color: AppTheme.portalTextMuted(
                                                context,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatRelativeTime(
                                                notif.createdAt,
                                              ),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.portalTextMuted(
                                                  context,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppTheme.portalTextMuted(context),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationDetails(
    String title,
    String message,
    DateTime? createdAt,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: TextStyle(
            color: AppTheme.portalAccent(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: AppTheme.portalTextSecondary(context),
                height: 1.4,
              ),
            ),
            if (createdAt != null) ...[
              const SizedBox(height: 16),
              Text(
                DateFormat('MMM d, yyyy • h:mm a').format(createdAt),
                style: TextStyle(
                  color: AppTheme.portalTextMuted(context),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to log out of your student account?',
      confirmLabel: 'Sign Out',
      confirmColor: AppColors.red,
      icon: Icons.logout_rounded,
    );
    if (confirmed && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.red : AppColors.safeGreen,
      ),
    );
  }
}
