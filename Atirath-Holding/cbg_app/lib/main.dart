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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

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

class MyApp extends StatelessWidget {
  final bool hasToken;
  const MyApp({super.key, required this.hasToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CBG App',
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
      home: hasToken
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
      },
    );
  }
}