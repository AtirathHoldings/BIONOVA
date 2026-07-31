import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as original_http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../main.dart'; // To access MyApp.navigatorKey

// Export classes needed by ApiService so it can compile without issues
export 'package:http/http.dart' show Response, StreamedResponse, MultipartFile, Client;

class CustomHttp {
  static bool _isLoggingOut = false;

  static Future<void> checkUnauthorized(int statusCode) async {
    if (statusCode == 401) {
      if (_isLoggingOut) return;
      _isLoggingOut = true;

      debugPrint("Token expired (401 Unauthorized). Automatically logging out...");

      try {
        await ApiService.clearCache(clearAuth: true);
      } catch (e) {
        debugPrint("Error clearing preferences: $e");
      }

      final navigator = MyApp.navigatorKey.currentState;
      final context = MyApp.navigatorKey.currentContext;

      if (navigator != null) {
        // Redirect to sign in and clear route history
        navigator.pushNamedAndRemoveUntil('/signin', (route) => false);

        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please log in again.'),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      // Reset the logout flag after a delay to allow future logins
      Future.delayed(const Duration(seconds: 3), () {
        _isLoggingOut = false;
      });
    }
  }
}

// Wrapper functions for package:http standard methods

Future<original_http.Response> get(Uri url, {Map<String, String>? headers}) async {
  final response = await original_http.get(url, headers: headers);
  await CustomHttp.checkUnauthorized(response.statusCode);
  return response;
}

Future<original_http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final response = await original_http.post(url, headers: headers, body: body, encoding: encoding);
  await CustomHttp.checkUnauthorized(response.statusCode);
  return response;
}

Future<original_http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final response = await original_http.put(url, headers: headers, body: body, encoding: encoding);
  await CustomHttp.checkUnauthorized(response.statusCode);
  return response;
}

Future<original_http.Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final response = await original_http.patch(url, headers: headers, body: body, encoding: encoding);
  await CustomHttp.checkUnauthorized(response.statusCode);
  return response;
}

Future<original_http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final response = await original_http.delete(url, headers: headers, body: body, encoding: encoding);
  await CustomHttp.checkUnauthorized(response.statusCode);
  return response;
}

// Wrapper class for MultipartRequest to intercept send()
class MultipartRequest extends original_http.MultipartRequest {
  MultipartRequest(super.method, super.url);

  @override
  Future<original_http.StreamedResponse> send() async {
    final response = await super.send();
    await CustomHttp.checkUnauthorized(response.statusCode);
    return response;
  }
}
