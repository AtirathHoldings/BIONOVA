import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_http.dart' as http;

class InventoryStorageKeys {
  static const String items = 'bionova_inventory_items_v1';
  static const String civilBom = 'bionova_civil_materials_bom_v1';
  static const String fasteners = 'bionova_fasteners_hardware_v1';
  static const String piping = 'bionova_piping_instrumentation_v1';
  static const String warranties = 'bionova_equipment_warranty_v1';
  static const String alerts = 'bionova_inventory_alerts_v1';
  static const String weighbridge = 'bionova_weightbridge_portal_v1';
  static const String vendors = 'bionova_vendor_management_v1';
}

class InventoryApiService {
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static String get _baseUrl => dotenv.env['BASE_URL'] ?? '';

  static Future<dynamic> _get(String path) async {
    final headers = await _getHeaders();
    final response = await http
        .get(Uri.parse('$_baseUrl$path'), headers: headers)
        .timeout(const Duration(seconds: 25));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trim().isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw Exception('GET $path failed (${response.statusCode})');
  }

  static Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http
        .post(Uri.parse('$_baseUrl$path'), headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 25));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trim().isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw Exception('POST $path failed (${response.statusCode})');
  }

  static Future<dynamic> _put(String path, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http
        .put(Uri.parse('$_baseUrl$path'), headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 25));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trim().isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw Exception('PUT $path failed (${response.statusCode})');
  }

  static Future<void> _delete(String path) async {
    final headers = await _getHeaders();
    final response = await http
        .delete(Uri.parse('$_baseUrl$path'), headers: headers)
        .timeout(const Duration(seconds: 25));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('DELETE $path failed (${response.statusCode})');
    }
  }

  static List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> loadLocalList(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      return _asList(decoded);
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveLocalList(String key, List<Map<String, dynamic>> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(list));
    } catch (e) {
      debugPrint('Failed to save inventory local list $key: $e');
    }
  }

  // 1. Items
  static Future<List<Map<String, dynamic>>> getInventoryItems() async {
    try {
      return _asList(await _get('/api/inventory/items'));
    } catch (e) {
      debugPrint('getInventoryItems error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> saveInventoryItem(
      Map<String, dynamic> item, {dynamic id}) async {
    final res = id != null
        ? await _put('/api/inventory/items/$id', item)
        : await _post('/api/inventory/items', item);
    return res is Map ? Map<String, dynamic>.from(res) : null;
  }

  static Future<void> deleteInventoryItem(dynamic id) async {
    await _delete('/api/inventory/items/$id');
  }

  // 2. Civil BOM
  static Future<List<Map<String, dynamic>>> getCivilMaterials() async {
    try {
      return _asList(await _get('/api/inventory/civil-bom'));
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> saveCivilMaterial(
      Map<String, dynamic> item, {dynamic id}) async {
    final res = id != null
        ? await _put('/api/inventory/civil-bom/$id', item)
        : await _post('/api/inventory/civil-bom', item);
    return res is Map ? Map<String, dynamic>.from(res) : null;
  }

  static Future<void> deleteCivilMaterial(dynamic id) async {
    await _delete('/api/inventory/civil-bom/$id');
  }

  // 3. Fasteners
  static Future<List<Map<String, dynamic>>> getFasteners() async {
    try {
      return _asList(await _get('/api/inventory/fasteners'));
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> saveFastener(
      Map<String, dynamic> item, {dynamic id}) async {
    final res = id != null
        ? await _put('/api/inventory/fasteners/$id', item)
        : await _post('/api/inventory/fasteners', item);
    return res is Map ? Map<String, dynamic>.from(res) : null;
  }

  static Future<void> deleteFastener(dynamic id) async {
    await _delete('/api/inventory/fasteners/$id');
  }

  // 4. Piping & Instrumentation
  static Future<List<Map<String, dynamic>>> getPipingSpares() async {
    try {
      return _asList(await _get('/api/inventory/piping'));
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> savePipingSpare(
      Map<String, dynamic> item, {dynamic id}) async {
    final res = id != null
        ? await _put('/api/inventory/piping/$id', item)
        : await _post('/api/inventory/piping', item);
    return res is Map ? Map<String, dynamic>.from(res) : null;
  }

  static Future<void> deletePipingSpare(dynamic id) async {
    await _delete('/api/inventory/piping/$id');
  }

  // 5. Equipment Warranty
  static Future<List<Map<String, dynamic>>> getEquipmentWarranties() async {
    try {
      return _asList(await _get('/api/inventory/warranties'));
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> saveEquipmentWarranty(
      Map<String, dynamic> item, {dynamic id}) async {
    final res = id != null
        ? await _put('/api/inventory/warranties/$id', item)
        : await _post('/api/inventory/warranties', item);
    return res is Map ? Map<String, dynamic>.from(res) : null;
  }

  static Future<void> deleteEquipmentWarranty(dynamic id) async {
    await _delete('/api/inventory/warranties/$id');
  }

  // 6. Stock Expiry Alerts
  static Future<List<Map<String, dynamic>>> getStockAlerts() async {
    try {
      return _asList(await _get('/api/inventory/alerts'));
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> saveStockAlert(
      Map<String, dynamic> item, {dynamic id}) async {
    final res = id != null
        ? await _put('/api/inventory/alerts/$id', item)
        : await _post('/api/inventory/alerts', item);
    return res is Map ? Map<String, dynamic>.from(res) : null;
  }

  static Future<void> deleteStockAlert(dynamic id) async {
    await _delete('/api/inventory/alerts/$id');
  }

  // 7. Warehouse Weighbridge
  static Future<List<Map<String, dynamic>>> getWeighbridgeSlips() async {
    try {
      return _asList(await _get('/api/inventory/weighbridge'));
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> saveWeighbridgeSlip(
      Map<String, dynamic> item, {dynamic id}) async {
    final res = id != null
        ? await _put('/api/inventory/weighbridge/$id', item)
        : await _post('/api/inventory/weighbridge', item);
    return res is Map ? Map<String, dynamic>.from(res) : null;
  }

  static Future<void> deleteWeighbridgeSlip(dynamic id) async {
    await _delete('/api/inventory/weighbridge/$id');
  }

  // 8. Multi-Tier Vendors
  static Future<List<Map<String, dynamic>>> getInventoryVendors() async {
    try {
      return _asList(await _get('/api/inventory/vendors'));
    } catch (e) {
      debugPrint('getInventoryVendors error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> saveInventoryVendor(
      Map<String, dynamic> item, {dynamic id}) async {
    final res = id != null
        ? await _put('/api/inventory/vendors/$id', item)
        : await _post('/api/inventory/vendors', item);
    return res is Map ? Map<String, dynamic>.from(res) : null;
  }

  static Future<void> deleteInventoryVendor(dynamic id) async {
    await _delete('/api/inventory/vendors/$id');
  }
}
