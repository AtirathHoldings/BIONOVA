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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  print('APP BASE_URL => ${dotenv.env['BASE_URL']}');

  // Initialize Notification Service and Background Sync
  try {
    await NotificationService.initialize();
    await NotificationService.startBackgroundSync();
    await NotificationService.triggerImmediateCheck(); // <-- ఇమ్మీడియట్ చెక్ యాడ్ చేశాం
  } catch (e) {
    debugPrint("Failed to initialize Notification Service: $e");
  }
  
  final prefs = await SharedPreferences.getInstance();
  final hasToken = prefs.containsKey('authToken') && prefs.getString('authToken') != null;
  
  runApp(MyApp(hasToken: hasToken));
}

class MyApp extends StatefulWidget {
  final bool hasToken;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  const MyApp({super.key, required this.hasToken});

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

  void _handleDeepLink(Uri uri) {
    if (uri.path.contains('reset-password')) {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          MyApp.navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(token: token),
            ),
          );
        });
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
          ? MainScreen(key: MainScreen.navigatorKey)
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
      },
    );
  }
}