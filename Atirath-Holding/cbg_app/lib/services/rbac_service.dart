import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'custom_http.dart' as http;

class ScreenPermission {
  final bool canView;
  final bool canCreate;
  final bool canEdit;
  final bool canDelete;

  const ScreenPermission({
    this.canView = true,
    this.canCreate = true,
    this.canEdit = true,
    this.canDelete = true,
  });

  static const full = ScreenPermission(
    canView: true,
    canCreate: true,
    canEdit: true,
    canDelete: true,
  );

  static const none = ScreenPermission(
    canView: false,
    canCreate: false,
    canEdit: false,
    canDelete: false,
  );
}

class RbacService {
  static List<Map<String, dynamic>>? _cachedPermissions;
  static bool _hasRbac = false;

  static Future<bool> isAdminUser() async {
    final prefs = await SharedPreferences.getInstance();
    final role = (prefs.getString('userRole') ?? '').toLowerCase().trim();
    return role == 'admin' || role == 'super_admin' || role == 'full_access';
  }

  static Future<void> loadPermissions({bool forceRefresh = false}) async {
    if (_cachedPermissions != null && !forceRefresh) return;

    final prefs = await SharedPreferences.getInstance();
    if (!forceRefresh) {
      final raw = prefs.getString('userPermissions');
      if (raw != null && raw.isNotEmpty) {
        try {
          final List<dynamic> parsed = jsonDecode(raw);
          _cachedPermissions = parsed
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _hasRbac = prefs.getBool('hasRbacFlag') ?? false;
        } catch (_) {}
      }
    }

    try {
      final token = prefs.getString('authToken');
      final empId = await ApiService.getCurrentEmployeeId();
      final baseUrl = dotenv.env['BASE_URL'];
      if (token == null || empId == null || baseUrl == null || baseUrl.isEmpty) {
        return;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final hasRbacRes = await http
          .get(Uri.parse('$baseUrl/api/rbac/employees/$empId/has-rbac'), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (hasRbacRes.statusCode == 200) {
        final rbacData = jsonDecode(hasRbacRes.body);
        if (rbacData is Map) {
          _hasRbac = rbacData['hasRbac'] == true;
          await prefs.setBool('hasRbacFlag', _hasRbac);
        }
      }

      final permsRes = await http
          .get(Uri.parse('$baseUrl/api/rbac/employees/$empId/permissions'), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (permsRes.statusCode == 200) {
        final decoded = jsonDecode(permsRes.body);
        if (decoded is List) {
          _cachedPermissions = decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          await prefs.setString('userPermissions', jsonEncode(_cachedPermissions));
        }
      }
    } catch (e) {
      debugPrint('RbacService.loadPermissions error: $e');
    }
  }

  static Future<ScreenPermission> getScreenPermission(String screenCode) async {
    if (await isAdminUser()) {
      return ScreenPermission.full;
    }

    await loadPermissions();

    if (_cachedPermissions == null) {
      return ScreenPermission.full;
    }

    final match = _cachedPermissions!.cast<Map<String, dynamic>?>().firstWhere(
          (p) => p?['screenCode']?.toString() == screenCode,
          orElse: () => null,
        );

    if (match == null) {
      // Matches frontend/src/utils/permissions.js: if cached permissions exist and screen not found, deny.
      // Unless RBAC is not enforced and list is empty.
      if (_cachedPermissions!.isEmpty && !_hasRbac) {
        return ScreenPermission.full;
      }
      return ScreenPermission.none;
    }

    bool flag(dynamic v) => v == true || v == 'true' || v == 1;

    return ScreenPermission(
      canView: flag(match['viewFlg'] ?? match['view_flg']),
      canCreate: flag(match['addFlg'] ?? match['add_flg']),
      canEdit: flag(match['editFlg'] ?? match['edit_flg']),
      canDelete: flag(match['deleteFlg'] ?? match['delete_flg']),
    );
  }

  static Future<bool> hasModuleSidebarAccess(String screenCode) async {
    if (await isAdminUser()) return true;
    await loadPermissions();
    if (_cachedPermissions == null) return true;

    if (!_hasRbac) {
      // Matches Sidebar.jsx: if !hasRbac, allowedScreens = [...permissions]
      return _cachedPermissions!.isEmpty ||
          _cachedPermissions!.any(
            (s) => s['screenCode']?.toString() == screenCode && (s['viewFlg'] != false),
          );
    }

    return _cachedPermissions!.any(
      (s) => s['screenCode']?.toString() == screenCode && (s['viewFlg'] == true),
    );
  }

  static void clearMemoryCache() {
    _cachedPermissions = null;
    _hasRbac = false;
  }
}
