import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Top-level dispatcher function required by Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // 1. Load env variables if not loaded
      try {
        await dotenv.load(fileName: ".env");
      } catch (_) {
        // Fallback or ignore if already loaded or not found
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8080';

      if (token == null || token == 'offline_mock_token') {
        return Future.value(true);
      }

      // 2. Fetch unread notifications from the backend
      final response = await http.get(
        Uri.parse("$baseUrl/api/notifications/unread"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final List<String> shownIds = prefs.getStringList('shown_notification_ids') ?? [];
          final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

          const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
          const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
          await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);

          const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
            'bionova_notification_channel',
            'BIONOVA Notifications',
            channelDescription: 'Alerts and updates for BIONOVA tasks and projects',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          );
          const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

          List<String> newShownIds = List.from(shownIds);

          for (final n in data) {
            final String id = (n['id'] ?? n['notificationId'] ?? '').toString();
            final String title = n['title'] ?? 'BIONOVA Update';
            final String message = n['message'] ?? n['msg'] ?? '';

            if (id.isNotEmpty && !shownIds.contains(id)) {
              await flutterLocalNotificationsPlugin.show(
                id: int.tryParse(id) ?? id.hashCode,
                title: title,
                body: message,
                notificationDetails: platformChannelSpecifics,
              );
              newShownIds.add(id);
            }
          }

          await prefs.setStringList('shown_notification_ids', newShownIds);
        }
      }
    } catch (e) {
      debugPrint("Error in background notification task: $e");
    }
    return Future.value(true);
  });
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification click if needed (e.g. navigate to screen)
      },
    );

    // Request permissions for Android 13+
    final androidImplementation = _localNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    // 2. Initialize Workmanager for background tasks
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  static Future<void> startBackgroundSync() async {
    // Register periodic task (runs roughly every 15 minutes - Android minimum)
    await Workmanager().registerPeriodicTask(
      "1",
      "notificationFetcherTask",
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static Future<void> triggerImmediateCheck() async {
    // Register a one-off task for testing or immediate check on app launch
    await Workmanager().registerOneOffTask(
      "immediate_check",
      "notificationFetcherTask",
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
