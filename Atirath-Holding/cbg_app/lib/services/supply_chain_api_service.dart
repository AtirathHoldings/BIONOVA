import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_http.dart' as http;

class SupplyChainStorageKeys {
  static const String suppliers = 'bionova_procurement_suppliers';
  static const String prs = 'bionova_procurement_prs';
  static const String pos = 'bionova_procurement_pos';
  static const String deliveryNotes = 'bionova_procurement_delivery_notes';

  static const String cmmsAssets = 'bionova_cmms_assets';
  static const String cmmsSchedules = 'bionova_cmms_schedules';
  static const String cmmsIncidents = 'bionova_cmms_incidents';
  static const String cmmsCosts = 'bionova_cmms_costs';

  static const String fleetTrips = 'bionova_fleet_trips';
  static const String fleetDrivers = 'bionova_fleet_drivers';
  static const String fleetWeighbridge = 'bionova_fleet_weighbridge_slips';
  static const String fleetTempLogs = 'bionova_fleet_temp_logs';
}

class SupplyChainApiService {
  static String get _baseUrl => dotenv.env['BASE_URL'] ?? '';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> _getLocal(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return [];
      return _asList(jsonDecode(raw));
    } catch (_) {
      return [];
    }
  }

  static Future<void> _setLocal(String key, List<Map<String, dynamic>> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(list));
    } catch (e) {
      debugPrint('SupplyChain local save error ($key): $e');
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchWithFallback(
    String path,
    String localKey,
  ) async {
    if (_baseUrl.isNotEmpty) {
      try {
        final headers = await _getHeaders();
        final res = await http
            .get(Uri.parse('$_baseUrl$path'), headers: headers)
            .timeout(const Duration(seconds: 20));
        if (res.statusCode >= 200 && res.statusCode < 300 && res.body.trim().isNotEmpty) {
          final parsed = _asList(jsonDecode(res.body));
          await _setLocal(localKey, parsed);
          return parsed;
        }
      } catch (_) {}
    }
    return _getLocal(localKey);
  }

  static Future<Map<String, dynamic>> _saveWithFallback(
    String path,
    String localKey,
    Map<String, dynamic> item,
  ) async {
    final current = await _getLocal(localKey);
    final hasId = item['id'] != null && item['id'].toString().isNotEmpty;
    final payload = Map<String, dynamic>.from(item);

    List<Map<String, dynamic>> updated;
    if (hasId) {
      updated = current.map((e) => e['id'].toString() == item['id'].toString() ? {...e, ...payload} : e).toList();
    } else {
      payload['id'] = DateTime.now().millisecondsSinceEpoch;
      updated = [payload, ...current];
    }
    await _setLocal(localKey, updated);

    if (_baseUrl.isNotEmpty) {
      try {
        final headers = await _getHeaders();
        if (hasId) {
          await http
              .put(Uri.parse('$_baseUrl$path/${item['id']}'), headers: headers, body: jsonEncode(item))
              .timeout(const Duration(seconds: 20));
        } else {
          await http
              .post(Uri.parse('$_baseUrl$path'), headers: headers, body: jsonEncode(item))
              .timeout(const Duration(seconds: 20));
        }
      } catch (_) {}
    }
    return payload;
  }

  static Future<void> _deleteWithFallback(
    String path,
    String localKey,
    dynamic id,
  ) async {
    final current = await _getLocal(localKey);
    final updated = current.where((e) => e['id'].toString() != id.toString()).toList();
    await _setLocal(localKey, updated);

    if (_baseUrl.isNotEmpty) {
      try {
        final headers = await _getHeaders();
        await http
            .delete(Uri.parse('$_baseUrl$path/$id'), headers: headers)
            .timeout(const Duration(seconds: 20));
      } catch (_) {}
    }
  }

  // Master Lookups
  static Future<List<Map<String, dynamic>>> getPlants() async {
    if (_baseUrl.isEmpty) return [];
    try {
      final headers = await _getHeaders();
      final res = await http
          .get(Uri.parse('$_baseUrl/api/plants'), headers: headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode >= 200 && res.statusCode < 300 && res.body.trim().isNotEmpty) {
        return _asList(jsonDecode(res.body));
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Map<String, dynamic>>> getLands() async {
    if (_baseUrl.isEmpty) return [];
    try {
      final headers = await _getHeaders();
      final res = await http
          .get(Uri.parse('$_baseUrl/api/lands'), headers: headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode >= 200 && res.statusCode < 300 && res.body.trim().isNotEmpty) {
        return _asList(jsonDecode(res.body));
      }
    } catch (_) {}
    return [];
  }

  // 1. PROCUREMENT & PO MANAGEMENT
  static Future<List<Map<String, dynamic>>> getProcurementSuppliers() =>
      _fetchWithFallback('/api/procurement/suppliers', SupplyChainStorageKeys.suppliers);
  static Future<Map<String, dynamic>> saveProcurementSupplier(Map<String, dynamic> s) =>
      _saveWithFallback('/api/procurement/suppliers', SupplyChainStorageKeys.suppliers, s);
  static Future<void> deleteProcurementSupplier(dynamic id) =>
      _deleteWithFallback('/api/procurement/suppliers', SupplyChainStorageKeys.suppliers, id);

  static Future<List<Map<String, dynamic>>> getPurchaseRequisitions() =>
      _fetchWithFallback('/api/procurement/requisitions', SupplyChainStorageKeys.prs);
  static Future<Map<String, dynamic>> savePurchaseRequisition(Map<String, dynamic> pr) =>
      _saveWithFallback('/api/procurement/requisitions', SupplyChainStorageKeys.prs, pr);
  static Future<void> deletePurchaseRequisition(dynamic id) =>
      _deleteWithFallback('/api/procurement/requisitions', SupplyChainStorageKeys.prs, id);

  static Future<List<Map<String, dynamic>>> getPurchaseOrders() =>
      _fetchWithFallback('/api/procurement/purchase-orders', SupplyChainStorageKeys.pos);
  static Future<Map<String, dynamic>> savePurchaseOrder(Map<String, dynamic> po) =>
      _saveWithFallback('/api/procurement/purchase-orders', SupplyChainStorageKeys.pos, po);
  static Future<void> deletePurchaseOrder(dynamic id) =>
      _deleteWithFallback('/api/procurement/purchase-orders', SupplyChainStorageKeys.pos, id);

  static Future<List<Map<String, dynamic>>> getDeliveryNotes() =>
      _fetchWithFallback('/api/procurement/delivery-notes', SupplyChainStorageKeys.deliveryNotes);
  static Future<Map<String, dynamic>> saveDeliveryNote(Map<String, dynamic> note) =>
      _saveWithFallback('/api/procurement/delivery-notes', SupplyChainStorageKeys.deliveryNotes, note);
  static Future<void> deleteDeliveryNote(dynamic id) =>
      _deleteWithFallback('/api/procurement/delivery-notes', SupplyChainStorageKeys.deliveryNotes, id);

  // 2. ASSET MAINTENANCE (CMMS)
  static Future<List<Map<String, dynamic>>> getMachineryAssets() =>
      _fetchWithFallback('/api/asset-maintenance/assets', SupplyChainStorageKeys.cmmsAssets);
  static Future<Map<String, dynamic>> saveMachineryAsset(Map<String, dynamic> a) =>
      _saveWithFallback('/api/asset-maintenance/assets', SupplyChainStorageKeys.cmmsAssets, a);
  static Future<void> deleteMachineryAsset(dynamic id) =>
      _deleteWithFallback('/api/asset-maintenance/assets', SupplyChainStorageKeys.cmmsAssets, id);

  static Future<List<Map<String, dynamic>>> getMaintenanceSchedules() =>
      _fetchWithFallback('/api/asset-maintenance/schedules', SupplyChainStorageKeys.cmmsSchedules);
  static Future<Map<String, dynamic>> saveMaintenanceSchedule(Map<String, dynamic> s) =>
      _saveWithFallback('/api/asset-maintenance/schedules', SupplyChainStorageKeys.cmmsSchedules, s);
  static Future<void> deleteMaintenanceSchedule(dynamic id) =>
      _deleteWithFallback('/api/asset-maintenance/schedules', SupplyChainStorageKeys.cmmsSchedules, id);

  static Future<List<Map<String, dynamic>>> getBreakdownIncidents() =>
      _fetchWithFallback('/api/asset-maintenance/incidents', SupplyChainStorageKeys.cmmsIncidents);
  static Future<Map<String, dynamic>> saveBreakdownIncident(Map<String, dynamic> i) =>
      _saveWithFallback('/api/asset-maintenance/incidents', SupplyChainStorageKeys.cmmsIncidents, i);
  static Future<void> deleteBreakdownIncident(dynamic id) =>
      _deleteWithFallback('/api/asset-maintenance/incidents', SupplyChainStorageKeys.cmmsIncidents, id);

  static Future<List<Map<String, dynamic>>> getServicingCostLogs() =>
      _fetchWithFallback('/api/asset-maintenance/servicing-costs', SupplyChainStorageKeys.cmmsCosts);
  static Future<Map<String, dynamic>> saveServicingCostLog(Map<String, dynamic> c) =>
      _saveWithFallback('/api/asset-maintenance/servicing-costs', SupplyChainStorageKeys.cmmsCosts, c);
  static Future<void> deleteServicingCostLog(dynamic id) =>
      _deleteWithFallback('/api/asset-maintenance/servicing-costs', SupplyChainStorageKeys.cmmsCosts, id);

  // 3. FLEET & DISPATCH LOGISTICS
  static Future<List<Map<String, dynamic>>> getVehicleTripSheets() =>
      _fetchWithFallback('/api/dispatch-logistics/trip-sheets', SupplyChainStorageKeys.fleetTrips);
  static Future<Map<String, dynamic>> saveVehicleTripSheet(Map<String, dynamic> t) =>
      _saveWithFallback('/api/dispatch-logistics/trip-sheets', SupplyChainStorageKeys.fleetTrips, t);
  static Future<void> deleteVehicleTripSheet(dynamic id) =>
      _deleteWithFallback('/api/dispatch-logistics/trip-sheets', SupplyChainStorageKeys.fleetTrips, id);

  static Future<List<Map<String, dynamic>>> getDrivers() =>
      _fetchWithFallback('/api/dispatch-logistics/drivers', SupplyChainStorageKeys.fleetDrivers);
  static Future<Map<String, dynamic>> saveDriver(Map<String, dynamic> d) =>
      _saveWithFallback('/api/dispatch-logistics/drivers', SupplyChainStorageKeys.fleetDrivers, d);
  static Future<void> deleteDriver(dynamic id) =>
      _deleteWithFallback('/api/dispatch-logistics/drivers', SupplyChainStorageKeys.fleetDrivers, id);

  static Future<List<Map<String, dynamic>>> getLogisticsWeighbridgeSlips() =>
      _fetchWithFallback('/api/dispatch-logistics/weighbridge-slips', SupplyChainStorageKeys.fleetWeighbridge);
  static Future<Map<String, dynamic>> saveLogisticsWeighbridgeSlip(Map<String, dynamic> w) =>
      _saveWithFallback('/api/dispatch-logistics/weighbridge-slips', SupplyChainStorageKeys.fleetWeighbridge, w);
  static Future<void> deleteLogisticsWeighbridgeSlip(dynamic id) =>
      _deleteWithFallback('/api/dispatch-logistics/weighbridge-slips', SupplyChainStorageKeys.fleetWeighbridge, id);

  static Future<List<Map<String, dynamic>>> getTransitTemperatureLogs() =>
      _fetchWithFallback('/api/dispatch-logistics/temperature-logs', SupplyChainStorageKeys.fleetTempLogs);
  static Future<Map<String, dynamic>> saveTransitTemperatureLog(Map<String, dynamic> l) =>
      _saveWithFallback('/api/dispatch-logistics/temperature-logs', SupplyChainStorageKeys.fleetTempLogs, l);
  static Future<void> deleteTransitTemperatureLog(dynamic id) =>
      _deleteWithFallback('/api/dispatch-logistics/temperature-logs', SupplyChainStorageKeys.fleetTempLogs, id);
}
