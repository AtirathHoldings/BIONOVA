// ==========================================================================
// BioNova Executive Overview Module - Centralized Live API Service
// ==========================================================================
import { apiGet, apiPost, apiPut, apiDelete } from "../../../utils/api";

// 1. Expansion Pipeline
export async function getPipelineProjects() {
  return await apiGet("/api/executive/pipeline") || [];
}
export async function savePipelineProject(project, id = null) {
  return id ? await apiPut(`/api/executive/pipeline/${id}`, project) : await apiPost("/api/executive/pipeline", project);
}
export async function deletePipelineProject(id) {
  return await apiDelete(`/api/executive/pipeline/${id}`);
}

// 2. Budget Variance Items
export async function getBudgetItems() {
  return await apiGet("/api/executive/budget") || [];
}
export async function saveBudgetItem(item, id = null) {
  return id ? await apiPut(`/api/executive/budget/${id}`, item) : await apiPost("/api/executive/budget", item);
}
export async function deleteBudgetItem(id) {
  return await apiDelete(`/api/executive/budget/${id}`);
}

// 3. Multi-Stream Revenue
export async function getRevenueRecords() {
  return await apiGet("/api/executive/revenue") || [];
}
export async function saveRevenueRecord(record, id = null) {
  return id ? await apiPut(`/api/executive/revenue/${id}`, record) : await apiPost("/api/executive/revenue", record);
}
export async function deleteRevenueRecord(id) {
  return await apiDelete(`/api/executive/revenue/${id}`);
}

// 4. Compliance & ESG Registry
export async function getComplianceRecords() {
  return await apiGet("/api/executive/compliance") || [];
}
export async function saveComplianceRecord(record, id = null) {
  return id ? await apiPut(`/api/executive/compliance/${id}`, record) : await apiPost("/api/executive/compliance", record);
}
export async function deleteComplianceRecord(id) {
  return await apiDelete(`/api/executive/compliance/${id}`);
}

// 5. Treasury Sourcing / Facilities
export async function getFundingSources() {
  return await apiGet("/api/executive/treasury") || [];
}
export async function saveFundingSource(source, id = null) {
  return id ? await apiPut(`/api/executive/treasury/${id}`, source) : await apiPost("/api/executive/treasury", source);
}
export async function deleteFundingSource(id) {
  return await apiDelete(`/api/executive/treasury/${id}`);
}

// 6. Escrow Financing Accounts
export async function getEscrowAccounts() {
  return await apiGet("/api/executive/escrow") || [];
}
export async function saveEscrowAccount(account, id = null) {
  return id ? await apiPut(`/api/executive/escrow/${id}`, account) : await apiPost("/api/executive/escrow", account);
}
export async function deleteEscrowAccount(id) {
  return await apiDelete(`/api/executive/escrow/${id}`);
}

// 7. Executive Alerts Feed
export async function getExecutiveAlerts() {
  return await apiGet("/api/executive/alerts") || [];
}
export async function saveExecutiveAlert(alert, id = null) {
  return id ? await apiPut(`/api/executive/alerts/${id}`, alert) : await apiPost("/api/executive/alerts", alert);
}
export async function resolveExecutiveAlert(id) {
  return await apiPut(`/api/executive/alerts/${id}/resolve`, {});
}
export async function deleteExecutiveAlert(id) {
  return await apiDelete(`/api/executive/alerts/${id}`);
}

// 8. Cockpit & Capex Analytics KPIs
export async function getCockpitKpis() {
  return await apiGet("/api/executive/cockpit-kpis") || {};
}

