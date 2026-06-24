import 'package:flutter/material.dart';
import 'package:cbg_app/widgets/footer.dart';
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

  final List<Widget> pages = const [
    DashboardScreen(),
    ProjectsScreen(),
    TasksScreen(),
    CalendarScreen(),
    MenuScreen(),
  ];

  @override
  bool get wantKeepAlive => true;

  // Public method to change tab from anywhere
  void changeTab(int index) {
    if (index >= 0 && index < pages.length) {
      setState(() {
        currentIndex = index;
        _pageController.jumpToPage(index);
      });
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
      canPop: false, // 🔥 FIXED: Prevent app exit on back press
      onPopInvokedWithResult: (didPop, result) {
        // If not on dashboard, go to dashboard
        if (currentIndex != 0) {
          setState(() {
            currentIndex = 0;
            _pageController.jumpToPage(0);
          });
        }
        // If on dashboard, do nothing (app won't exit)
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // 🔥 FIXED: Disable swipe gestures
          onPageChanged: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          children: pages,
        ),
        bottomNavigationBar: CustomFooter(
          currentIndex: currentIndex,
          onTabSelected: (index) {
            setState(() {
              currentIndex = index;
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            });
          },
        ),
      ),
    );
  }
}