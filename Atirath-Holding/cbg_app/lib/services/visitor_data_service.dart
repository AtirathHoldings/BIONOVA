import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_http.dart' as http;

class VisitorStorageKeys {
  static const String visitors = 'bionova_visitors_log_v4';
  static const String requests = 'bionova_visit_requests_v4';
  static const String appointments = 'bionova_appointments_v4';
  static const String vehicles = 'bionova_vehicles_log_v4';
  static const String materialInward = 'bionova_material_inward_v4';
  static const String materialOutward = 'bionova_material_outward_v4';
  static const String safetyClearance = 'bionova_safety_clearance_v4';
  static const String zoneAccess = 'bionova_zone_access_v4';
  static const String config = 'bionova_visitor_config_v4';
}

class VisitorZone {
  final String id;
  final String code;
  final String name;
  final String riskLevel;
  final int colorHex;
  final String description;
  final List<String> ppeMandatory;

  const VisitorZone({
    required this.id,
    required this.code,
    required this.name,
    required this.riskLevel,
    required this.colorHex,
    required this.description,
    required this.ppeMandatory,
  });
}

class VisitorDataService extends ChangeNotifier {
  VisitorDataService._();
  static final VisitorDataService instance = VisitorDataService._();

  static const List<VisitorZone> initialZones = [
    VisitorZone(
      id: 'Z1',
      code: 'ZONE-ADM',
      name: 'Administrative Building & Reception',
      riskLevel: 'Low Risk',
      colorHex: 0xFF10B981,
      description: 'Offices, meeting rooms, cafeteria, and main reception area.',
      ppeMandatory: ['Normal Footwear'],
    ),
    VisitorZone(
      id: 'Z2',
      code: 'ZONE-WGB',
      name: 'Weighbridge & Feedstock Unloading Yard',
      riskLevel: 'Medium Risk',
      colorHex: 0xFFF59E0B,
      description: 'Heavy trucks, biomass tipping, front-loader operations.',
      ppeMandatory: ['Hard Hat', 'Hi-Vis Vest', 'Safety Shoes'],
    ),
    VisitorZone(
      id: 'Z3',
      code: 'ZONE-DIG',
      name: 'Anaerobic Digesters & Digestate Area',
      riskLevel: 'High Risk (Gas & Confined Space)',
      colorHex: 0xFFF97316,
      description: 'Biological digestion tanks, slurry pumps, primary biogas generation dome.',
      ppeMandatory: ['Hard Hat', 'Hi-Vis Vest', 'Safety Shoes', 'Multi-Gas Detector Badge'],
    ),
    VisitorZone(
      id: 'Z4',
      code: 'ZONE-GAS',
      name: 'Gas Scrubbing, Upgradation & ATEX Compression',
      riskLevel: 'Critical Risk (Explosive Atmosphere - Zone 1)',
      colorHex: 0xFFEF4444,
      description: 'H2S biological scrubbers, PSA gas enrichment, 250-bar compressors.',
      ppeMandatory: ['Hard Hat', 'Anti-static Attire', 'Safety Shoes', 'Personal H2S & LEL Detector'],
    ),
    VisitorZone(
      id: 'Z5',
      code: 'ZONE-CAS',
      name: 'CBG Cascade Filling Bay',
      riskLevel: 'Critical Risk (Flammable Gas Under Pressure)',
      colorHex: 0xFFDC2626,
      description: 'Gas bottling manifolds, high pressure cascade trailer parking.',
      ppeMandatory: ['Hard Hat', 'Flame-Resistant Overall', 'Safety Shoes'],
    ),
  ];

  static Map<String, dynamic> initialConfig() => {
        'plantName': 'BioNova Biogas Complex',
        'maxPassDurationHours': 8,
        'gateOpeningTime': '06:00 AM',
        'gateClosingTime': '10:00 PM',
        'autoOverdueThresholdMinutes': 30,
        'requireGovtId': true,
        'requireSafetyInduction': true,
        'requireHostApprovalForVendors': true,
        'blacklistedVisitors': <Map<String, dynamic>>[],
      };

  static const Map<String, String> _endpointMap = {
    VisitorStorageKeys.visitors: '/api/visitors/records',
    VisitorStorageKeys.requests: '/api/visitors/requests',
    VisitorStorageKeys.appointments: '/api/visitors/appointments',
    VisitorStorageKeys.vehicles: '/api/visitors/vehicles',
    VisitorStorageKeys.materialInward: '/api/visitors/material-inward',
    VisitorStorageKeys.materialOutward: '/api/visitors/material-outward',
    VisitorStorageKeys.safetyClearance: '/api/visitors/safety-clearances',
    VisitorStorageKeys.config: '/api/visitors/config',
  };

  static const List<String> _dummyTokens = [
    'Murthy',
    'Mahesh Chandra',
    'Arvind Reddy',
    'Vikram Malhotra',
    'G. Venkatesh',
    'Priya Deshmukh',
    'Devi Prasad',
    'Anand Verma',
    'Amitabh Sen',
    'Ritu Singhal',
    'Mohan Das',
    'GP-2026-0814',
    'GP-2026-0815',
    'GP-2026-0816',
    'GP-2026-0817',
    'GP-2026-0818',
    'GP-2026-0819',
    'VR-2026-010',
    'APT-2026-44',
    'MI-2026-04',
    'MO-2026-019',
    'MO-2026-020',
    'SC-2026-09',
    'TS 08 UB 7712',
    'TS 09 EA 4401',
    'TS 07 HK 9081',
    'TS 09 AB 1234',
    'Pressmud Sugar Mill',
    'Novozymes',
    'Digital Fluke',
    'Thermax Clean',
    'Coromandel Agrotech',
    'TUV Rheinland',
    'IGL Commercial',
    'Sri Lakshmi Transports',
  ];

  static bool isDummyRecord(dynamic item) {
    if (item == null) return false;
    final str = item is String ? item : jsonEncode(item);
    return _dummyTokens.any((tok) => str.contains(tok));
  }

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

  Future<List<Map<String, dynamic>>> getStoredList(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final item = prefs.getString(key);
      // Trigger live fetch in background
      fetchLiveVisitorData(key);
      if (item == null || item.isEmpty) return [];
      final decoded = jsonDecode(item);
      if (decoded is! List) return [];
      final cleanList = decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((entry) => !isDummyRecord(entry))
          .toList();
      if (cleanList.length != decoded.length) {
        await prefs.setString(key, jsonEncode(cleanList));
      }
      return cleanList;
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getStoredConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final item = prefs.getString(VisitorStorageKeys.config);
      fetchLiveVisitorData(VisitorStorageKeys.config);
      if (item == null || item.isEmpty) return initialConfig();
      final decoded = jsonDecode(item);
      if (decoded is Map) {
        return {...initialConfig(), ...Map<String, dynamic>.from(decoded)};
      }
      return initialConfig();
    } catch (_) {
      return initialConfig();
    }
  }

  Future<void> saveStoredData(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save visitor storage item $key: $e');
    }
  }

  Future<dynamic> fetchLiveVisitorData(String key) async {
    final endpoint = _endpointMap[key];
    if (endpoint == null || _baseUrl.isEmpty) return null;
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$_baseUrl$endpoint'), headers: headers)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.trim().isEmpty) return null;
        final remoteData = jsonDecode(response.body);
        if (remoteData != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(key, jsonEncode(remoteData));
          notifyListeners();
          return remoteData;
        }
      }
    } catch (e) {
      debugPrint('Live fetch failed for $key: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> apiCreateVisitorRecord(Map<String, dynamic> record) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/visitors/records'),
            headers: headers,
            body: jsonEncode(record),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await fetchLiveVisitorData(VisitorStorageKeys.visitors);
        if (response.body.trim().isNotEmpty) {
          final res = jsonDecode(response.body);
          if (res is Map) return Map<String, dynamic>.from(res);
        }
      }
    } catch (e) {
      debugPrint('apiCreateVisitorRecord error: $e');
    }
    return null;
  }

  Future<void> apiUpdateVisitorRecord(dynamic id, Map<String, dynamic> record) async {
    try {
      final headers = await _getHeaders();
      await http
          .put(
            Uri.parse('$_baseUrl/api/visitors/records/$id'),
            headers: headers,
            body: jsonEncode(record),
          )
          .timeout(const Duration(seconds: 20));
      await fetchLiveVisitorData(VisitorStorageKeys.visitors);
    } catch (e) {
      debugPrint('apiUpdateVisitorRecord error: $e');
    }
  }

  Future<void> apiDeleteVisitorRecord(dynamic id) async {
    try {
      final headers = await _getHeaders();
      await http
          .delete(Uri.parse('$_baseUrl/api/visitors/records/$id'), headers: headers)
          .timeout(const Duration(seconds: 20));
      await fetchLiveVisitorData(VisitorStorageKeys.visitors);
    } catch (e) {
      debugPrint('apiDeleteVisitorRecord error: $e');
    }
  }

  Future<void> apiCheckInVisitor(dynamic id) async {
    try {
      final headers = await _getHeaders();
      await http
          .put(
            Uri.parse('$_baseUrl/api/visitors/records/$id/check-in'),
            headers: headers,
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 20));
      await fetchLiveVisitorData(VisitorStorageKeys.visitors);
    } catch (e) {
      debugPrint('apiCheckInVisitor error: $e');
    }
  }

  Future<void> apiCheckOutVisitor(dynamic id) async {
    try {
      final headers = await _getHeaders();
      await http
          .put(
            Uri.parse('$_baseUrl/api/visitors/records/$id/check-out'),
            headers: headers,
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 20));
      await fetchLiveVisitorData(VisitorStorageKeys.visitors);
    } catch (e) {
      debugPrint('apiCheckOutVisitor error: $e');
    }
  }
}
