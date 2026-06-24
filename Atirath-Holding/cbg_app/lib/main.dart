import 'package:cbg_app/Pages/project_details_screen.dart';
import 'package:cbg_app/Pages/sign_in_screen.dart';
import 'package:cbg_app/Pages/main_screen.dart';
import 'package:cbg_app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cbg_app/Pages/task_details_screen.dart';
import 'package:cbg_app/Pages/profile_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cbg_app/Pages/notification_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: const SignInPage(),
      routes: {
        '/signin': (context) => const SignInPage(),
        // ✅ CHANGE: Added key
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