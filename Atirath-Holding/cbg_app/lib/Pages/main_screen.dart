import 'package:flutter/material.dart';
import 'package:cbg_app/widgets/footer.dart';
import 'package:cbg_app/widgets/header.dart';
import 'package:cbg_app/services/api_service.dart';
import 'dashboard_screen.dart';
import 'projects_screen.dart';
import 'task_screen.dart';
import 'calendar_screen.dart';
import 'menu_screen.dart';

class MainScreen extends StatefulWidget {
  static final GlobalKey<_MainScreenState> navigatorKey = 
      GlobalKey<_MainScreenState>();

  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with AutomaticKeepAliveClientMixin {
  int currentIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);
  int _unreadNotificationCount = 0;
  final List<int> _navigationHistory = [0];

  final List<Widget> pages = const [
    DashboardScreen(),
    ProjectsScreen(),
    TasksScreen(),
    CalendarScreen(),
    MenuScreen(),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    ApiService.preloadAllData();
    _fetchNotificationCount();
    _fetchProfilePhoto();
  }

  Future<void> _fetchProfilePhoto() async {
    try {
      await ApiService.getProfile();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error pre-fetching profile: $e');
    }
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final unreadNotifications = await ApiService.getUnreadNotifications();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = unreadNotifications.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notification count: $e');
    }
  }

  // Public method to change tab from anywhere
  void changeTab(int index) {
    if (index >= 0 && index < pages.length) {
      if (currentIndex != index) {
        _navigationHistory.remove(index);
        _navigationHistory.add(index);
        _pageController.jumpToPage(index);
      }
    }
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Projects';
      case 2:
        return 'Tasks';
      case 3:
        return 'Calendar';
      case 4:
        return 'Menu';
      default:
        return 'Home';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: false, // Prevent app exit on back press
      onPopInvokedWithResult: (didPop, result) {
        if (_navigationHistory.length > 1) {
          _navigationHistory.removeLast();
          final prevIndex = _navigationHistory.last;
          _pageController.jumpToPage(prevIndex);
          setState(() {
            currentIndex = prevIndex;
          });
        }
      },
      child: Scaffold(
        appBar: CustomHeader(
          title: _getTabTitle(currentIndex),
          automaticallyImplyLeading: false,
          notificationCount: _unreadNotificationCount,
          onNotificationTap: () async {
            await Navigator.pushNamed(context, '/notifications');
            _fetchNotificationCount();
          },
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Disable swipe gestures
          onPageChanged: (index) {
            setState(() {
              currentIndex = index;
            });
            _fetchNotificationCount();
          },
          children: pages,
        ),
        bottomNavigationBar: CustomFooter(
          currentIndex: currentIndex,
          onTabSelected: (index) {
            if (currentIndex != index) {
              _navigationHistory.remove(index);
              _navigationHistory.add(index);
              _pageController.jumpToPage(index);
            }
          },
        ),
      ),
    );
  }
}