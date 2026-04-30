import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import 'home_tab.dart';
import 'exams_tab.dart';
import 'results_tab.dart';
import 'violations_tab.dart';
import 'profile_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  int _examsTabKey = 0; // increment to force ExamsTab reload
  List<AppNotification> _notifications = [];
  bool _notifLoading = false;

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _notifLoading = true);
    final data = await NotificationService.fetchNotifications();
    setState(() {
      _notifications = data;
      _notifLoading = false;
    });
  }

  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationPanel(
        notifications: _notifications,
        loading: _notifLoading,
        onRefresh: _loadNotifications,
        onMarkAllRead: () {
          setState(() {
            for (final n in _notifications) {
              n.isRead = true;
            }
          });
          Navigator.pop(context);
        },
      ),
    );
    // Mark all read after opening
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: const Text(
          'Invigilo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                onPressed: _openNotifications,
                tooltip: 'Notifications',
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeTab(),
          ExamsTab(key: ValueKey(_examsTabKey)),
          const ResultsTab(),
          const ViolationsTab(),
          const ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            // Reload exams every time the Exams tab is tapped
            if (index == 1) _examsTabKey++;
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF4FC3F7),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Exams',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Results',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber_outlined),
            activeIcon: Icon(Icons.warning_amber_rounded),
            label: 'Violations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Notification Panel (bottom sheet) ─────────────────────────────────────────

class _NotificationPanel extends StatelessWidget {
  final List<AppNotification> notifications;
  final bool loading;
  final VoidCallback onRefresh;
  final VoidCallback onMarkAllRead;

  const _NotificationPanel({
    required this.notifications,
    required this.loading,
    required this.onRefresh,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      if (notifications.isNotEmpty)
                        TextButton(
                          onPressed: onMarkAllRead,
                          child: const Text(
                            'Mark all read',
                            style: TextStyle(color: Color(0xFF4FC3F7), fontSize: 13),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Color(0xFF4FC3F7)),
                        onPressed: onRefresh,
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Body
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4FC3F7)))
                  : notifications.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none, size: 56, color: Colors.black26),
                              SizedBox(height: 12),
                              Text('No notifications yet', style: TextStyle(color: Colors.black45)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, indent: 68),
                          itemBuilder: (_, index) {
                            final n = notifications[index];
                            return _NotificationTile(notification: n);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.exam:
        return Icons.assignment;
      case NotificationType.result:
        return Icons.bar_chart;
      case NotificationType.violation:
        return Icons.warning_amber_rounded;
    }
  }

  Color get _color {
    switch (notification.type) {
      case NotificationType.exam:
        return const Color(0xFF4FC3F7);
      case NotificationType.result:
        return const Color(0xFF26C6DA);
      case NotificationType.violation:
        return const Color(0xFFFF7043);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: _color.withOpacity(0.15),
        child: Icon(_icon, color: _color, size: 22),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        notification.body,
        style: const TextStyle(fontSize: 13, color: Colors.black54),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: notification.isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF4FC3F7),
                shape: BoxShape.circle,
              ),
            ),
    );
  }
}
