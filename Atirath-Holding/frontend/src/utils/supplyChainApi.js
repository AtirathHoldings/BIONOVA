// ==========================================================================
// supplyChainApi.js - Centralized API Service for Supply Chain & Operations
// ==========================================================================
import { apiGet, apiPost, apiPut, apiDelete } from "./api";

// Helper for localStorage fallback
const getLocal = (key, defaultVal = []) => {
  try {
    const raw = localStorage.getItem(key);
    return raw ? JSON.parse(raw) : defaultVal;
  } catch (e) {
    return defaultVal;
  }
};

const setLocal = (key, data) => {
  try {
    localStorage.setItem(key, JSON.stringify(data));
  } catch (e) {}
};

// ─── 1. PROCUREMENT & PO MANAGEMENT ────────────────────────────────────────

export async function getProcurementSuppliers() {
  try {
    const res = await apiGet("/api/procurement/suppliers");
    if (res && Array.isArray(res)) return res;
  } catch (e) {}
  return getLocal("bionova_procurement_suppliers", []);
}

export async function saveProcurementSupplier(supplier) {
  const current = getLocal("bionova_procurement_suppliers", []);
  let updated;
  if (supplier.id) {
    updated = current.map(s => (s.id === supplier.id ? { ...s, ...supplier } : s));
  } else {
    const newId = Date.now();
    updated = [{ ...supplier, id: newId }, ...current];
  }
  setLocal("bionova_procurement_suppliers", updated);
  try {
    if (supplier.id) await apiPut(`/api/procurement/suppliers/${supplier.id}`, supplier);
    else await apiPost("/api/procurement/suppliers", supplier);
  } catch (e) {}
  return supplier;
}

export async function deleteProcurementSupplier(id) {
  const current = getLocal("bionova_procurement_suppliers", []);
  const updated = current.filter(s => s.id !== id);
  setLocal("bionova_procurement_suppliers", updated);
  try {
    await apiDelete(`/api/procurement/suppliers/${id}`);
  } catch (e) {}
  return true;
}

export async function getPurchaseRequisitions() {
  try {
    const res = await apiGet("/api/procurement/requisitions");
    if (res && Array.isArray(res)) return res;
  } catch (e) {}
  return getLocal("bionova_procurement_prs", []);
}

export async function savePurchaseRequisition(pr) {
  const current = getLocal("bionova_procurement_prs", []);
  let updated;
  if (pr.id) {
    updated = current.map(p => (p.id === pr.id ? { ...p, ...pr } : p));
  } else {
    const newId = Date.now();
    updated = [{ ...pr, id: newId }, ...current];
  }
  setLocal("bionova_procurement_prs", updated);
  try {
    if (pr.id) await apiPut(`/api/procurement/requisitions/${pr.id}`, pr);
    else await apiPost("/api/procurement/requisitions", pr);
  } catch (e) {}
  return pr;
}

export async function deletePurchaseRequisition(id) {
  const current = getLocal("bionova_procurement_prs", []);
  const updated = current.filter(p => p.id !== id);
  setLocal("bionova_procurement_prs", updated);
  try {
    await apiDelete(`/api/procurement/requisitions/${id}`);
  } catch (e) {}
  return true;
}

export async function getPurchaseOrders() {
  try {
    const res = await apiGet("/api/procurement/purchase-orders");
    if (res && Array.isArray(res)) return res;
  } catch (e) {}
  return getLocal("bionova_procurement_pos", []);
}

export async function savePurchaseOrder(po) {
  const current = getLocal("bionova_procurement_pos", []);
  let updated;
  if (po.id) {
    updated = current.map(p => (p.id === po.id ? { ...p, ...po } : p));
  } else {
    const newId = Date.now();
    updated = [{ ...po, id: newId }, ...current];
  }
  setLocal("bionova_procurement_pos", updated);
  try {
    if (po.id) await apiPut(`/api/procurement/purchase-orders/${po.id}`, po);
    else await apiPost("/api/procurement/purchase-orders", po);
  } catch (e) {}
  return po;
}

export async function deletePurchaseOrder(id) {
  const current = getLocal("bionova_procurement_pos", []);
  const updated = current.filter(p => p.id !== id);
  setLocal("bionova_procurement_pos", updated);
  try {
    await apiDelete(`/api/procurement/purchase-orders/${id}`);
  } catch (e) {}
  return true;
}

export async function getDeliveryNotes() {
  try {
    const res = await apiGet("/api/procurement/delivery-notes");
    if (res && Array.isArray(res)) return res;
  } catch (e) {}
  return getLocal("bionova_procurement_delivery_notes", []);
}

export async function saveDeliveryNote(note) {
  const current = getLocal("bionova_procurement_delivery_notes", []);
  let updated;
  if (note.id) {
    updated = current.map(n => (n.id === note.id ? { ...n, ...note } : n));
  } else {
    const newId = Date.now();
    updated = [{ ...note, id: newId }, ...current];
  }
  setLocal("bionova_procurement_delivery_notes", updated);
  try {
    if (note.id) await apiPut(`/api/procurement/delivery-notes/${note.id}`, note);
    else await apiPost("/api/procurement/delivery-notes", note);
  } catch (e) {}
  return note;
}

export async function deleteDeliveryNote(id) {
  const current = getLocal("bionova_procurement_delivery_notes", []);
  const updated = current.filter(n => n.id !== id);
  setLocal("bionova_procurement_delivery_notes", updated);
  try {
    await apiDelete(`/api/procurement/delivery-notes/${id}`);
  } catch (e) {}
  return true;
}

// ─── 2. ASSET MAINTENANCE (CMMS) ───────────────────────────────────────────

export async function getMachineryAssets() {
  try {
    const res = await apiGet("/api/asset-maintenance/assets");
    if (res && Array.isArray(res)) return res;
  } catch (e) {}
  return getLocal("bionova_cmms_assets", []);
}

export async function saveMachineryAsset(asset) {
  const current = getLocal("bionova_cmms_assets", []);
  let updated;
  if (asset.id) {
    updated = current.map(a => (a.id === asset.id ? { ...a, ...asset } : a));
  } else {
    const newId = Date.now();
    updated = [{ ...asset, id: newId }, ...current];
  }
  setLocal("bionova_cmms_assets", updated);
  try {
    if (asset.id) await apiPut(`/api/asset-maintenance/assets/${asset.id}`, asset);
    else await apiPost("/api/asset-maintenance/assets", asset);
  } catch (e) {}
  return asset;
}

export async function deleteMachineryAsset(id) {
  const current = getLocal("bionova_cmms_assets", []);
  const updated = current.filter(a => a.id !== id);
  setLocal("bionova_cmms_assets", updated);
  try {
    await apiDelete(`/api/asset-maintenance/assets/${id}`);
  } catch (e) {}
  return true;
}

export async function getMaintenanceSchedules() {
  try {
    const res = await apiGet("/api/asset-maintenance/schedules");
    if (res && Array.isArray(res)) return res;
  } catch (e) {}
  return getLocal("bionova_cmms_schedules", []);
}

export async function saveMaintenanceSchedule(schedule) {
  const current = getLocal("bionova_cmms_schedules", []);
  let updated;
  if (schedule.id) {
    updated = current.map(s => (s.id === schedule.id ? { ...s, ...schedule } : s));
  } else {
    const newId = Date.now();
    updated = [{ ...schedule, id: newId }, ...current];
  }
  setLocal("bionova_cmms_schedules", updated);
  try {
    if (schedule.id) await apiPut(`/api/asset-maintenance/schedules/${schedule.id}`, schedule);
    else await apiPost("/api/asset-maintenance/schedules", schedule);
  } catch (e) {}
  return schedule;
}

export async function deleteMaintenanceSchedule(id) {
  const current = getLocal("bionova_cmms_schedules", []);
  const updated = current.filter(s => s.id !== id);
  setLocal("bionova_cmms_schedules", updated);
  try {
    await apiDelete(`/api/asset-maintenance/schedules/${id}`);
  } catch (e) {}
  return true;
}

export async function getBreakdownIncidents() {
  try {
    const res = await apiGet("/api/asset-maintenance/incidents");
    if (res && Array.isArray(res)) return res;
  } catch (e) {}
  return getLocal("bionova_cmms_incidents", []);
}

export async function saveBreakdownIncident(incident) {
  const current = getLocal("bionova_cmms_incidents", []);
  let updated;
  if (incident.id) {
    updated = current.map(i => (i.id === incident.id ? { ...i, ...incident } : i));
  } else {
    const newId = Date.now();
    updated = [{ ...incident, id: newId }, ...current];
  }
  setLocal("bionova_cmms_incidents", updated);
  try {
    if (incident.id) await apiPut(`/api/asset-maintenance/incidents/${incident.id}`, incident);
    else await apiPost("/api/asset-maintenance/incidents", incident);
  } catch (e) {}
  return incident;
}

export async function deleteBreakdownIncident(id) {
  const current = getLocal("bionova_cmms_incidents", []);
  const updated = current.filter(i => i.id !== id);
  setLocal("bionova_cmms_incidents", updated);
  try {
    await apiDelete(`/api/asset-maintenance/incidents/${id}`);
  } catch (e) {}
  return true;
}

export async function getServicingCostLogs() {
  try {
    const res = await apiGet("/api/asset-maintenance/servicing-costs");
    if (res && Array.isArray(res)) return res;
  } catch (e) {}
  return getLocal("bionova_cmms_costs", []);
}

export async function saveServicingCostLog(log) {
  const current = getLocal("bionova_cmms_costs", []);
  let updated;
  if (log.id) {
    updated = current.map(l => (l.id === log.id ? { ...l, ...log } : l));
  } else {
    const newId = Date.now();
    updated = [{ ...log, id: newId }, ...current];
  }
  setLocal("bionova_cmms_costs", updated);
  try {
    if (log.id) await apiPut(`/api/asset-maintenance/servicing-costs/${log.id}`, log);
    else await apiPost("/api/asset-maintenance/servicing-costs", log);
  } catch (e) {}
  return log;
}

export async function deleteServicingCostLog(id) {
  const current = getLocal("bionova_cmms_costs", []);
  const updated = current.filter(l => l.id !== id);
  setLocal("bionova_cmms_costs", updated);
  try {
    await apiDelete(`/api/asset-maintenance/servicing-costs/${id}`);
  } catch (e) {}
  return true;
}

// ─── 3. FLEET & DISPATCH LOGISTICS ─────────────────────────────────────────

export async function getVehicleTripSheets() {
  try {
    const res = await apiGet("/api/dispatch-logistics/trip-sheets");
    if (res && Array.isArray(res)) return res;
  } catch (e) {}
  return getLocal("bionova_fleet_trips", []);
}

export async function saveVehicleTripSheet(trip) {
  const current = getLocal("bionova_fleet_trips", []);
  let updated;
  if (trip.id) {
    updated = current.map(t => (t.id === trip.id ? { ...t, ...trip } : t));
  } else {
    const newId = Date.now();
    updated = [{ ...trip, id: newId }, ...current];
  }
  setLocal("bionova_fleet_trips", updated);
  try {
    if (trip.id) await apiPut(`/api/dispatch-logistics/trip-sheets/${trip.id}`, trip);
    else await apiPost("/api/dispatch-logistics/trip-sheets", trip);
  } catch (e) {}
  return trip;
}

export async function deleteVehicleTripSheet(id) {
  const current = getLocal("bionova_fleet_trips", []);
  const updated = current.filter(t => t.id !== id);
  setLocal("bionova_fleet_trips", updated);
  try {
    await apiDelete(`/api/dispatch-logistics/trip-sheets/${id}`);
  } catch (e) {}
  return true;
}

export async function getDrivers() {
  try {
    const res = await apiGet("/api/dispatch-logistics/drivers");
    if (res && Array.isArray(res)) return res;
  } catch (e) {}
  return getLocal("bionova_fleet_drivers", []);
}

export async function saveDriver(driver) {
  const current = getLocal("bionova_fleet_drivers", []);
  let updated;
  if (driver.id) {
    updated = current.map(d => (d.id === driver.id ? { ...d, ...driver } : d));
  } else {
    const newId = Date.now();
    updated = [{ ...driver, id: newId }, ...current];
  }
  setLocal("bionova_fleet_drivers", updated);
  try {
    if (driver.id) await apiPut(`/api/dispatch-logistics/drivers/${driver.id}`, driver);
    else await apiPost("/api/dispatch-logistics/drivers", driver);
  } catch (e) {}
  return driver;
}

export async function deleteDriver(id) {
  const current = getLocal("bionova_fleet_drivers", []);
  const updated = current.filter(d => d.id !== id);
  setLocal("bionova_fleet_drivers", updated);
  try {
    await apiDelete(`/api/dispatch-logistics/drivers/${id}`);
  } catch (e) {}
  return true;
}

export async function getLogisticsWeighbridgeSlips() {
  try {
    const res = await apiGet("/api/dispatch-logistics/weighbridge-slips");
    if (res && Array.isArray(res)) return res;
  } catch (e) {}
  return getLocal("bionova_fleet_weighbridge_slips", []);
}

export async function saveLogisticsWeighbridgeSlip(slip) {
  const current = getLocal("bionova_fleet_weighbridge_slips", []);
  let updated;
  if (slip.id) {
    updated = current.map(s => (s.id === slip.id ? { ...s, ...slip } : s));
  } else {
    const newId = Date.now();
    updated = [{ ...slip, id: newId }, ...current];
  }
  setLocal("bionova_fleet_weighbridge_slips", updated);
  try {
    if (slip.id) await apiPut(`/api/dispatch-logistics/weighbridge-slips/${slip.id}`, slip);
    else await apiPost("/api/dispatch-logistics/weighbridge-slips", slip);
  } catch (e) {}
  return slip;
}

export async function deleteLogisticsWeighbridgeSlip(id) {
  const current = getLocal("bionova_fleet_weighbridge_slips", []);
  const updated = current.filter(s => s.id !== id);
  setLocal("bionova_fleet_weighbridge_slips", updated);
  try {
    await apiDelete(`/api/dispatch-logistics/weighbridge-slips/${id}`);
  } catch (e) {}
  return true;
}

export async function getTransitTemperatureLogs() {
  try {
    const res = await apiGet("/api/dispatch-logistics/temperature-logs");
    if (res && Array.isArray(res)) return res;
  } catch (e) {}
  return getLocal("bionova_fleet_temp_logs", []);
}

export async function saveTransitTemperatureLog(log) {
  const current = getLocal("bionova_fleet_temp_logs", []);
  let updated;
  if (log.id) {
    updated = current.map(l => (l.id === log.id ? { ...l, ...log } : l));
  } else {
    const newId = Date.now();
    updated = [{ ...log, id: newId }, ...current];
  }
  setLocal("bionova_fleet_temp_logs", updated);
  try {
    if (log.id) await apiPut(`/api/dispatch-logistics/temperature-logs/${log.id}`, log);
    else await apiPost("/api/dispatch-logistics/temperature-logs", log);
  } catch (e) {}
  return log;
}

export async function deleteTransitTemperatureLog(id) {
  const current = getLocal("bionova_fleet_temp_logs", []);
  const updated = current.filter(l => l.id !== id);
  setLocal("bionova_fleet_temp_logs", updated);
  try {
    await apiDelete(`/api/dispatch-logistics/temperature-logs/${id}`);
  } catch (e) {}
  return true;
}

