// ==========================================================================
// BioNova Inventory Module - Centralized Live API Service
// ==========================================================================
import { apiGet, apiPost, apiPut, apiDelete } from "../../../utils/api";

// 1. Items
export async function getInventoryItems() {
  return await apiGet("/api/inventory/items") || [];
}
export async function saveInventoryItem(item, id = null) {
  return id ? await apiPut(`/api/inventory/items/${id}`, item) : await apiPost("/api/inventory/items", item);
}
export async function deleteInventoryItem(id) {
  return await apiDelete(`/api/inventory/items/${id}`);
}

// 2. Civil BOM
export async function getCivilMaterials() {
  return await apiGet("/api/inventory/civil-bom") || [];
}
export async function saveCivilMaterial(item, id = null) {
  return id ? await apiPut(`/api/inventory/civil-bom/${id}`, item) : await apiPost("/api/inventory/civil-bom", item);
}
export async function deleteCivilMaterial(id) {
  return await apiDelete(`/api/inventory/civil-bom/${id}`);
}

// 3. Fasteners
export async function getFasteners() {
  return await apiGet("/api/inventory/fasteners") || [];
}
export async function saveFastener(item, id = null) {
  return id ? await apiPut(`/api/inventory/fasteners/${id}`, item) : await apiPost("/api/inventory/fasteners", item);
}
export async function deleteFastener(id) {
  return await apiDelete(`/api/inventory/fasteners/${id}`);
}

// 4. Piping & Instrumentation
export async function getPipingSpares() {
  return await apiGet("/api/inventory/piping") || [];
}
export async function savePipingSpare(item, id = null) {
  return id ? await apiPut(`/api/inventory/piping/${id}`, item) : await apiPost("/api/inventory/piping", item);
}
export async function deletePipingSpare(id) {
  return await apiDelete(`/api/inventory/piping/${id}`);
}

// 5. Equipment Warranty
export async function getEquipmentWarranties() {
  return await apiGet("/api/inventory/warranties") || [];
}
export async function saveEquipmentWarranty(item, id = null) {
  return id ? await apiPut(`/api/inventory/warranties/${id}`, item) : await apiPost("/api/inventory/warranties", item);
}
export async function deleteEquipmentWarranty(id) {
  return await apiDelete(`/api/inventory/warranties/${id}`);
}

// 6. Stock Expiry Alerts
export async function getStockAlerts() {
  return await apiGet("/api/inventory/alerts") || [];
}
export async function saveStockAlert(item, id = null) {
  return id ? await apiPut(`/api/inventory/alerts/${id}`, item) : await apiPost("/api/inventory/alerts", item);
}
export async function deleteStockAlert(id) {
  return await apiDelete(`/api/inventory/alerts/${id}`);
}

// 7. Warehouse Weighbridge
export async function getWeighbridgeSlips() {
  return await apiGet("/api/inventory/weighbridge") || [];
}
export async function saveWeighbridgeSlip(item, id = null) {
  return id ? await apiPut(`/api/inventory/weighbridge/${id}`, item) : await apiPost("/api/inventory/weighbridge", item);
}
export async function deleteWeighbridgeSlip(id) {
  return await apiDelete(`/api/inventory/weighbridge/${id}`);
}

// 8. Multi-Tier Vendors
export async function getInventoryVendors() {
  return await apiGet("/api/inventory/vendors") || [];
}
export async function saveInventoryVendor(item, id = null) {
  return id ? await apiPut(`/api/inventory/vendors/${id}`, item) : await apiPost("/api/inventory/vendors", item);
}
export async function deleteInventoryVendor(id) {
  return await apiDelete(`/api/inventory/vendors/${id}`);
}

