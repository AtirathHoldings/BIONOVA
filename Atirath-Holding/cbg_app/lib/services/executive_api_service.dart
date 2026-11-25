import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_http.dart' as http;

class ExecutiveApiService {
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

  // 1. Expansion Pipeline
  static Future<List<Map<String, dynamic>>> getPipelineProjects() async {
    try {
      return _asList(await _get('/api/executive/pipeline'));
    } catch (e) {
      debugPrint('getPipelineProjects error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> savePipelineProject(
      Map<String, dynamic> project, {String? id}) async {
    final res = id != null && id.isNotEmpty
        ? await _put('/api/executive/pipeline/$id', project)
        : await _post('/api/executive/pipeline', project);
    return res is Map ? Map<String, dynamic>.from(res) : null;
  }

  static Future<void> deletePipelineProject(String id) async {
    await _delete('/api/executive/pipeline/$id');
  }

  // 2. Budget Variance Items
  static Future<List<Map<String, dynamic>>> getBudgetItems() async {
    try {
      return _asList(await _get('/api/executive/budget'));
    } catch (e) {
      debugPrint('getBudgetItems error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> saveBudgetItem(
      Map<String, dynamic> item, {String? id}) async {
    final res = id != null && id.isNotEmpty
        ? await _put('/api/executive/budget/$id', item)
        : await _post('/api/executive/budget', item);
    return res is Map ? Map<String, dynamic>.from(res) : null;
  }

  static Future<void> deleteBudgetItem(String id) async {
    await _delete('/api/executive/budget/$id');
  }

  // 3. Multi-Stream Revenue
  static Future<List<Map<String, dynamic>>> getRevenueRecords() async {
    try {
      return _asList(await _get('/api/executive/revenue'));
    } catch (e) {
      debugPrint('getRevenueRecords error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> saveRevenueRecord(
      Map<String, dynamic> record, {String? id}) async {
    final res = id != null && id.isNotEmpty
        ? await _put('/api/executive/revenue/$id', record)
        : await _post('/api/executive/revenue', record);
    return res is Map ? Map<String, dynamic>.from(res) : null;
  }

  static Future<void> deleteRevenueRecord(String id) async {
    await _delete('/api/executive/revenue/$id');
  }

  // 4. Compliance & ESG Registry
  static Future<List<Map<String, dynamic>>> getComplianceRecords() async {
    try {
      return _asList(await _get('/api/executive/compliance'));
    } catch (e) {
      debugPrint('getComplianceRecords error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> saveComplianceRecord(
      Map<String, dynamic> record, {String? id}) async {
    final res = id != null && id.isNotEmpty
        ? await _put('/api/executive/compliance/$id', record)
        : await _post('/api/executive/compliance', record);
    return res is Map ? Map<String, dynamic>.from(res) : null;
  }

  static Future<void> deleteComplianceRecord(String id) async {
    await _delete('/api/executive/compliance/$id');
  }

  // 5. Treasury Sourcing / Facilities
  static Future<List<Map<String, dynamic>>> getFundingSources() async {
    try {
      return _asList(await _get('/api/executive/treasury'));
    } catch (e) {
      debugPrint('getFundingSources error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> saveFundingSource(
      Map<String, dynamic> source, {String? id}) async {
    final res = id != null && id.isNotEmpty
        ? await _put('/api/executive/treasury/$id', source)
        : await _post('/api/executive/treasury', source);
    return res is Map ? Map<String, dynamic>.from(res) : null;
  }

  static Future<void> deleteFundingSource(String id) async {
    await _delete('/api/executive/treasury/$id');
  }

  // 6. Escrow Financing Accounts
  static Future<List<Map<String, dynamic>>> getEscrowAccounts() async {
    try {
      return _asList(await _get('/api/executive/escrow'));
    } catch (e) {
      debugPrint('getEscrowAccounts error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> saveEscrowAccount(
      Map<String, dynamic> account, {String? id}) async {
    final res = id != null && id.isNotEmpty
        ? await _put('/api/executive/escrow/$id', account)
        : await _post('/api/executive/escrow', account);
    return res is Map ? Map<String, dynamic>.from(res) : null;
  }

  static Future<void> deleteEscrowAccount(String id) async {
    await _delete('/api/executive/escrow/$id');
  }

  // 7. Executive Alerts Feed
  static Future<List<Map<String, dynamic>>> getExecutiveAlerts() async {
    try {
      return _asList(await _get('/api/executive/alerts'));
    } catch (e) {
      debugPrint('getExecutiveAlerts error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> saveExecutiveAlert(
      Map<String, dynamic> alert, {String? id}) async {
    final res = id != null && id.isNotEmpty
        ? await _put('/api/executive/alerts/$id', alert)
        : await _post('/api/executive/alerts', alert);
    return res is Map ? Map<String, dynamic>.from(res) : null;
  }

  static Future<void> resolveExecutiveAlert(String id) async {
    await _put('/api/executive/alerts/$id/resolve', {});
  }

  static Future<void> deleteExecutiveAlert(String id) async {
    await _delete('/api/executive/alerts/$id');
  }

  // 8. Cockpit KPIs
  static Future<Map<String, dynamic>> getCockpitKpis() async {
    try {
      final res = await _get('/api/executive/cockpit-kpis');
      if (res is Map) return Map<String, dynamic>.from(res);
      return {};
    } catch (e) {
      debugPrint('getCockpitKpis error: $e');
      return {};
    }
  }
}
