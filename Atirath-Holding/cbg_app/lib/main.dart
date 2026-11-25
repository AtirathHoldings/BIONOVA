import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:cbg_app/Pages/reset_password_screen.dart';
import 'package:cbg_app/Pages/project_details_screen.dart';
import 'package:cbg_app/Pages/sign_in_screen.dart';
import 'package:cbg_app/Pages/main_screen.dart';
import 'package:cbg_app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cbg_app/Pages/task_details_screen.dart';
import 'package:cbg_app/Pages/profile_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cbg_app/Pages/notification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbg_app/services/notification_service.dart';
import 'package:cbg_app/Pages/individual_task_screen.dart';
import 'package:cbg_app/Pages/assign_tasks_screen.dart';
import 'package:cbg_app/Pages/raise_request_screen.dart';
import 'package:cbg_app/Pages/external_task_screen.dart';
import 'package:cbg_app/Pages/executive/executive_module_screen.dart';
import 'package:cbg_app/Pages/inventory/inventory_management_screen.dart';
import 'package:cbg_app/Pages/visitors/visitor_management_screen.dart';
import 'package:cbg_app/Pages/supply_chain/procurement_management_screen.dart';
import 'package:cbg_app/Pages/supply_chain/asset_maintenance_screen.dart';
import 'package:cbg_app/Pages/supply_chain/dispatch_logistics_screen.dart';
import 'package:cbg_app/Pages/harvesting/harvesting_module_screen.dart';
import 'package:cbg_app/Pages/dpr/dpr_management_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  debugPrint('APP BASE_URL => ${dotenv.env['BASE_URL']}');

  // Initialize Notification Service and Background Sync
  try {
    await NotificationService.initialize();
    await NotificationService.startBackgroundSync();
    await NotificationService.triggerImmediateCheck(); // <-- ఇమ్మీడియట్ చెక్ యాడ్ చేశాం
  } catch (e) {
    debugPrint("Failed to initialize Notification Service: $e");
  }
  
  final prefs = await SharedPreferences.getInstance();
  final authToken = prefs.getString('authToken');
  final hasToken = authToken != null && authToken.trim().isNotEmpty;
  final savedLandingRoute = prefs.getString('landingRoute');
  final savedDefaultScreen = prefs.getString('defaultScreen');
  
  runApp(MyApp(
    hasToken: hasToken,
    savedLandingRoute: savedLandingRoute,
    savedDefaultScreen: savedDefaultScreen,
  ));
}

class MyApp extends StatefulWidget {
  final bool hasToken;
  final String? savedLandingRoute;
  final String? savedDefaultScreen;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  const MyApp({
    super.key,
    required this.hasToken,
    this.savedLandingRoute,
    this.savedDefaultScreen,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint("Failed to get initial deep link: $e");
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint("Deep link error: $err");
    });
  }

  void _navigateToWhenReady(Widget screen) {
    void tryPush(int attemptsLeft) {
      final nav = MyApp.navigatorKey.currentState;
      if (nav != null) {
        nav.push(MaterialPageRoute(builder: (context) => screen));
      } else if (attemptsLeft > 0) {
        Future.delayed(const Duration(milliseconds: 300), () => tryPush(attemptsLeft - 1));
      } else {
        debugPrint("⚠️ Navigator not ready for deep link navigation.");
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      tryPush(10);
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint("🔗 Received Deep Link: $uri (scheme: ${uri.scheme}, host: ${uri.host}, path: ${uri.path})");
    final uriString = uri.toString();
    if (uriString.contains('reset-password') ||
        uri.host.contains('reset-password') ||
        uri.path.contains('reset-password') ||
        uri.path.contains('open-reset')) {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        debugPrint("🔑 Found reset token: $token. Navigating to ResetPasswordScreen...");
        _navigateToWhenReady(ResetPasswordScreen(token: token));
      }
    } else if (uriString.contains('external-task') ||
        uri.host.contains('external-task') ||
        uri.path.contains('external-task')) {
      String? token = uri.queryParameters['token'];
      if (token == null || token.isEmpty) {
        final segments = uri.pathSegments;
        final idx = segments.indexOf('external-task');
        if (idx != -1 && idx + 1 < segments.length) {
          token = segments[idx + 1];
        } else if (segments.isNotEmpty) {
          token = segments.last;
        }
      }
      if (token != null && token.isNotEmpty && token != 'external-task') {
        debugPrint("🔑 Found external task token: $token. Navigating to ExternalTaskScreen...");
        _navigateToWhenReady(ExternalTaskScreen(token: token!));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CBG App',
      navigatorKey: MyApp.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: widget.hasToken
          ? _getInitialHomeScreen(widget.savedLandingRoute, widget.savedDefaultScreen)
          : const SignInPage(),
      routes: {
        '/signin': (context) => const SignInPage(),
        '/main': (context) => MainScreen(
          key: MainScreen.navigatorKey,
        ),
        '/project-details': (context) => const ProjectDetailsScreen(),
        '/task-details': (context) => const TaskDetailsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/individual-task': (context) => const IndividualTaskScreen(),
        '/individual-tasks-list': (context) => const IndividualTaskListScreen(),
        '/raise-request': (context) => const RaiseRequestScreen(),
        '/external-task': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final String token = (args is String) ? args : '';
          return ExternalTaskScreen(token: token);
        },
        '/executive': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final String sub = (args is String && args.isNotEmpty) ? args : 'cockpit';
          return ExecutiveModuleScreen(initialSubmodule: sub);
        },
        '/inventory': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final String sub = (args is String && args.isNotEmpty) ? args : 'overview';
          return InventoryManagementScreen(initialSubmodule: sub);
        },
        '/visitor-management': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final String sub = (args is String && args.isNotEmpty) ? args : 'dashboard';
          return VisitorManagementScreen(initialSubmodule: sub);
        },
        '/procurement': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final String tab = (args is String && args.isNotEmpty) ? args : 'pos';
          return ProcurementManagementScreen(initialTab: tab);
        },
        '/asset-maintenance': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final String tab = (args is String && args.isNotEmpty) ? args : 'assets';
          return AssetMaintenanceScreen(initialTab: tab);
        },
        '/dispatch-logistics': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final String tab = (args is String && args.isNotEmpty) ? args : 'trips';
          return DispatchLogisticsScreen(initialTab: tab);
        },
        '/harvesting': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final String tab = (args is String && args.isNotEmpty) ? args : 'cycles';
          return HarvestingModuleScreen(initialSubmodule: tab);
        },
        '/dpr': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final String tab = (args is String && args.isNotEmpty) ? args : 'reports';
          return DprManagementScreen(initialSubmodule: tab);
        },
      },
    );
  }

  Widget _getInitialHomeScreen(String? landingRoute, String? defaultScreen) {
    if (landingRoute == '/inventory' || defaultScreen == 'INVENTORY_MANAGEMENT') {
      return const InventoryManagementScreen();
    } else if (landingRoute == '/visitor-management' || landingRoute == '/visitors' || defaultScreen == 'VISITOR_MANAGEMENT') {
      return const VisitorManagementScreen();
    } else if (landingRoute == '/executive' || defaultScreen == 'EXECUTIVE_MODULE') {
      return const ExecutiveModuleScreen();
    } else if (landingRoute == '/procurement' || defaultScreen == 'PROCUREMENT_MANAGEMENT') {
      return const ProcurementManagementScreen();
    } else if (landingRoute == '/asset-maintenance' || defaultScreen == 'ASSET_MAINTENANCE') {
      return const AssetMaintenanceScreen();
    } else if (landingRoute == '/dispatch-logistics' || defaultScreen == 'FLEET_DISPATCH') {
      return const DispatchLogisticsScreen();
    } else if (landingRoute == '/harvesting' || defaultScreen == 'HARVESTING_MODULE' || defaultScreen == 'HARVESTING') {
      return const HarvestingModuleScreen();
    } else if (landingRoute == '/dpr' || defaultScreen == 'DPR_MANAGEMENT' || defaultScreen == 'DPR') {
      return const DprManagementScreen();
    }
    return MainScreen(key: MainScreen.navigatorKey);
  }
}