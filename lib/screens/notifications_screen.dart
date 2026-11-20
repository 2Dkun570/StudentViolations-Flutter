import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/violation_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_components.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _filterIndex = 0; // 0 = All, 1 = Unread

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ViolationProvider>(
        context,
        listen: false,
      ).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.portalSurface(context),
        foregroundColor: AppTheme.portalTextPrimary(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.portalTextPrimary(context),
        ),
        actions: [
          Consumer<ViolationProvider>(
            builder: (context, vp, _) {
              final unread = vp.notifications.where((n) => !n.isRead).length;
              if (unread == 0) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: vp.isLoading
                    ? null
                    : () => vp.markAllNotificationsAsRead(),
                icon: Icon(
                  Icons.done_all_rounded,
                  size: 18,
                  color: AppTheme.portalAccent(context),
                ),
                label: Text(
                  'Mark all read',
                  style: TextStyle(
                    color: AppTheme.portalAccent(context),
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Consumer<ViolationProvider>(
            builder: (context, vp, _) {
              if (vp.isLoading && vp.notifications.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.portalAccent(context),
                  ),
                );
              }

              final allNotifs = vp.notifications;
              final unreadNotifs = allNotifs.where((n) => !n.isRead).toList();
              final displayList = _filterIndex == 1 ? unreadNotifs : allNotifs;

              return RefreshIndicator(
                onRefresh: () => vp.loadNotifications(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: Row(
                        children: [
                          _filterChip(0, 'All (${allNotifs.length})'),
                          const SizedBox(width: 8),
                          _filterChip(1, 'Unread (${unreadNotifs.length})'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: displayList.isEmpty
                          ? EmptyStateWidget(
                              icon: Icons.notifications_none_rounded,
                              title: _filterIndex == 1
                                  ? 'No Unread Notifications'
                                  : 'No Notifications',
                              message: _filterIndex == 1
                                  ? 'You have caught up with all your notifications.'
                                  : 'You do not have any notification records yet.',
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: displayList.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final notif = displayList[index];
                                final isRead = notif.isRead;

                                return AppCard(
                                  padding: const EdgeInsets.all(14),
                                  backgroundColor: isRead
                                      ? AppTheme.portalSurface(context)
                                      : isDark
                                      ? AppColors.darkAccentSurface
                                      : AppColors.navySurface,
                                  onTap: isRead
                                      ? null
                                      : () => Provider.of<ViolationProvider>(
                                          context,
                                          listen: false,
                                        ).markNotificationAsRead(notif.id),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        margin: const EdgeInsets.only(top: 5),
                                        decoration: BoxDecoration(
                                          color: isRead
                                              ? Colors.transparent
                                              : AppColors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              notif.title,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: isRead
                                                    ? FontWeight.w600
                                                    : FontWeight.w700,
                                                color:
                                                    AppTheme.portalTextPrimary(
                                                      context,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              notif.message,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color:
                                                    AppTheme.portalTextSecondary(
                                                      context,
                                                    ),
                                                height: 1.35,
                                              ),
                                            ),
                                            if (notif.createdAt != null) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                _formatDate(notif.createdAt),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      AppTheme.portalTextMuted(
                                                        context,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (!isRead)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 20,
                                          ),
                                          color: AppColors.safeGreen,
                                          tooltip: 'Mark as read',
                                          onPressed: () =>
                                              Provider.of<ViolationProvider>(
                                                context,
                                                listen: false,
                                              ).markNotificationAsRead(
                                                notif.id,
                                              ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _filterChip(int index, String label) {
    final selected = _filterIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filterIndex = index),
      selectedColor: isDark ? AppColors.darkAccentSurface : AppColors.navy,
      backgroundColor: AppTheme.portalCardSurface(context),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? Colors.white : AppTheme.portalTextPrimary(context),
      ),
      side: BorderSide(
        color: selected
            ? (isDark ? AppColors.darkAccentSurface : AppColors.navy)
            : AppTheme.portalBorder(context),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
