// ==========================================================================
// BioNova Visitor Management - Centralized Live Data Service (Zero Dummy Data)
// ==========================================================================
import { apiGet, apiPost, apiPut, apiDelete } from "../../../utils/api";

export const STORAGE_KEYS = {
  VISITORS: "bionova_visitors_log_v4",
  REQUESTS: "bionova_visit_requests_v4",
  APPOINTMENTS: "bionova_appointments_v4",
  VEHICLES: "bionova_vehicles_log_v4",
  MATERIAL_INWARD: "bionova_material_inward_v4",
  MATERIAL_OUTWARD: "bionova_material_outward_v4",
  SAFETY_CLEARANCE: "bionova_safety_clearance_v4",
  ZONE_ACCESS: "bionova_zone_access_v4",
  CONFIG: "bionova_visitor_config_v4"
};

// All static dummy data completely removed. Zero initial dummy records.
export const INITIAL_VISITORS = [];
export const INITIAL_REQUESTS = [];
export const INITIAL_APPOINTMENTS = [];
export const INITIAL_VEHICLES = [];
export const INITIAL_INWARD = [];
export const INITIAL_OUTWARD = [];
export const INITIAL_SAFETY = [];

// Clean up any legacy dummy data from browser storage on load
export function isDummyRecord(item) {
  if (!item) return false;
  const str = typeof item === "string" ? item : JSON.stringify(item);
  return (
    str.includes("Murthy") ||
    str.includes("Mahesh Chandra") ||
    str.includes("Arvind Reddy") ||
    str.includes("Vikram Malhotra") ||
    str.includes("G. Venkatesh") ||
    str.includes("Priya Deshmukh") ||
    str.includes("Devi Prasad") ||
    str.includes("Anand Verma") ||
    str.includes("Amitabh Sen") ||
    str.includes("Ritu Singhal") ||
    str.includes("Mohan Das") ||
    str.includes("GP-2026-0814") ||
    str.includes("GP-2026-0815") ||
    str.includes("GP-2026-0816") ||
    str.includes("GP-2026-0817") ||
    str.includes("GP-2026-0818") ||
    str.includes("GP-2026-0819") ||
    str.includes("VR-2026-010") ||
    str.includes("APT-2026-44") ||
    str.includes("MI-2026-04") ||
    str.includes("MO-2026-019") ||
    str.includes("MO-2026-020") ||
    str.includes("SC-2026-09") ||
    str.includes("TS 08 UB 7712") ||
    str.includes("TS 09 EA 4401") ||
    str.includes("TS 07 HK 9081") ||
    str.includes("TS 09 AB 1234") ||
    str.includes("Pressmud Sugar Mill") ||
    str.includes("Novozymes") ||
    str.includes("Digital Fluke") ||
    str.includes("Thermax Clean") ||
    str.includes("Coromandel Agrotech") ||
    str.includes("TUV Rheinland") ||
    str.includes("IGL Commercial") ||
    str.includes("Sri Lakshmi Transports")
  );
}

try {
  const legacyPrefixes = [
    "bionova_visitors",
    "bionova_visit_",
    "bionova_appointment",
    "bionova_vehicle",
    "bionova_material",
    "bionova_safety",
    "bionova_zone",
    "bionova_weightbridge"
  ];
  const keysToRemove = [];
  for (let i = 0; i < localStorage.length; i++) {
    const k = localStorage.key(i);
    if (k && legacyPrefixes.some(p => k.startsWith(p)) && !k.endsWith("_v4")) {
      keysToRemove.push(k);
    }
  }
  keysToRemove.forEach(k => localStorage.removeItem(k));
} catch (e) {}

export const INITIAL_ZONES = [
  {
    id: "Z1",
    code: "ZONE-ADM",
    name: "Administrative Building & Reception",
    riskLevel: "Low Risk",
    color: "#10b981",
    description: "Offices, meeting rooms, cafeteria, and main reception area.",
    ppeMandatory: ["Normal Footwear"]
  },
  {
    id: "Z2",
    code: "ZONE-WGB",
    name: "Weighbridge & Feedstock Unloading Yard",
    riskLevel: "Medium Risk",
    color: "#f59e0b",
    description: "Heavy trucks, biomass tipping, front-loader operations.",
    ppeMandatory: ["Hard Hat", "Hi-Vis Vest", "Safety Shoes"]
  },
  {
    id: "Z3",
    code: "ZONE-DIG",
    name: "Anaerobic Digesters & Digestate Area",
    riskLevel: "High Risk (Gas & Confined Space)",
    color: "#f97316",
    description: "Biological digestion tanks, slurry pumps, primary biogas generation dome.",
    ppeMandatory: ["Hard Hat", "Hi-Vis Vest", "Safety Shoes", "Multi-Gas Detector Badge"]
  },
  {
    id: "Z4",
    code: "ZONE-GAS",
    name: "Gas Scrubbing, Upgradation & ATEX Compression",
    riskLevel: "Critical Risk (Explosive Atmosphere - Zone 1)",
    color: "#ef4444",
    description: "H2S biological scrubbers, PSA gas enrichment, 250-bar compressors.",
    ppeMandatory: ["Hard Hat", "Anti-static Attire", "Safety Shoes", "Personal H2S & LEL Detector"]
  },
  {
    id: "Z5",
    code: "ZONE-CAS",
    name: "CBG Cascade Filling Bay",
    riskLevel: "Critical Risk (Flammable Gas Under Pressure)",
    color: "#dc2626",
    description: "Gas bottling manifolds, high pressure cascade trailer parking.",
    ppeMandatory: ["Hard Hat", "Flame-Resistant Overall", "Safety Shoes"]
  }
];

export const INITIAL_CONFIG = {
  plantName: "BioNova Biogas Complex",
  maxPassDurationHours: 8,
  gateOpeningTime: "06:00 AM",
  gateClosingTime: "10:00 PM",
  autoOverdueThresholdMinutes: 30,
  requireGovtId: true,
  requireSafetyInduction: true,
  requireHostApprovalForVendors: true,
  blacklistedVisitors: []
};

const ENDPOINT_MAP = {
  [STORAGE_KEYS.VISITORS]: "/api/visitors/records",
  [STORAGE_KEYS.REQUESTS]: "/api/visitors/requests",
  [STORAGE_KEYS.APPOINTMENTS]: "/api/visitors/appointments",
  [STORAGE_KEYS.VEHICLES]: "/api/visitors/vehicles",
  [STORAGE_KEYS.MATERIAL_INWARD]: "/api/visitors/material-inward",
  [STORAGE_KEYS.MATERIAL_OUTWARD]: "/api/visitors/material-outward",
  [STORAGE_KEYS.SAFETY_CLEARANCE]: "/api/visitors/safety-clearances",
  [STORAGE_KEYS.CONFIG]: "/api/visitors/config"
};

export function getStoredData(key, fallback = []) {
  try {
    const item = localStorage.getItem(key);
    fetchLiveVisitorData(key).catch(() => {});
    if (!item) return fallback;
    const parsed = JSON.parse(item);
    if (!Array.isArray(parsed)) return parsed || fallback;
    
    // Purge ANY dummy item strictly
    const cleanList = parsed.filter(entry => !isDummyRecord(entry));
    if (cleanList.length !== parsed.length) {
      localStorage.setItem(key, JSON.stringify(cleanList));
    }
    return cleanList;
  } catch (e) {
    return fallback;
  }
}

export function saveStoredData(key, data) {
  try {
    localStorage.setItem(key, JSON.stringify(data));
    window.dispatchEvent(new CustomEvent("bionova_visitor_updated", { detail: { key, data } }));
  } catch (e) {
    console.warn(`Failed to save storage item ${key}:`, e);
  }
}

export async function fetchLiveVisitorData(key) {
  const endpoint = ENDPOINT_MAP[key];
  if (!endpoint) return null;
  try {
    const remoteData = await apiGet(endpoint);
    if (remoteData !== null && remoteData !== undefined) {
      localStorage.setItem(key, JSON.stringify(remoteData));
      window.dispatchEvent(new CustomEvent("bionova_visitor_updated", { detail: { key, data: remoteData } }));
      return remoteData;
    }
  } catch (err) {
    console.warn(`Live fetch failed for ${key}:`, err);
  }
  return null;
}

export async function apiCreateVisitorRecord(record) {
  const created = await apiPost("/api/visitors/records", record);
  await fetchLiveVisitorData(STORAGE_KEYS.VISITORS);
  return created;
}

export async function apiUpdateVisitorRecord(id, record) {
  const updated = await apiPut(`/api/visitors/records/${id}`, record);
  await fetchLiveVisitorData(STORAGE_KEYS.VISITORS);
  return updated;
}

export async function apiDeleteVisitorRecord(id) {
  const deleted = await apiDelete(`/api/visitors/records/${id}`);
  await fetchLiveVisitorData(STORAGE_KEYS.VISITORS);
  return deleted;
}

export async function apiCheckInVisitor(id) {
  const res = await apiPut(`/api/visitors/records/${id}/check-in`, {});
  await fetchLiveVisitorData(STORAGE_KEYS.VISITORS);
  return res;
}

export async function apiCheckOutVisitor(id) {
  const res = await apiPut(`/api/visitors/records/${id}/check-out`, {});
  await fetchLiveVisitorData(STORAGE_KEYS.VISITORS);
  return res;
}
