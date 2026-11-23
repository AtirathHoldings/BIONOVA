// ==========================================================================
// harvestingApi.js - Centralized API Service for Biomass Harvesting Module
// ==========================================================================
import { apiGet, apiPost, apiPut, apiDelete } from "./api";

const STORAGE_KEY = "bioNovaHarvestBatches";

const getLocal = (defaultVal = []) => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : defaultVal;
  } catch (e) {
    return defaultVal;
  }
};

const setLocal = (data) => {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
  } catch (e) {}
};

export async function getHarvestBatches() {
  try {
    const res = await apiGet("/api/harvesting/batches");
    if (res && Array.isArray(res) && res.length > 0) {
      setLocal(res);
      return res;
    }
  } catch (e) {}
  return getLocal([]);
}

export async function saveHarvestBatch(batch) {
  const current = getLocal([]);
  const exists = current.some(b => b.id === batch.id);
  const updated = exists
    ? current.map(b => (b.id === batch.id ? { ...b, ...batch } : b))
    : [batch, ...current];
  setLocal(updated);

  try {
    if (exists) {
      await apiPut(`/api/harvesting/batches/${batch.id}`, batch);
    } else {
      await apiPost("/api/harvesting/batches", batch);
    }
  } catch (e) {
    console.warn("Harvest batch backend sync failed, local copy preserved:", e);
  }
  return batch;
}

export async function deleteHarvestBatch(id) {
  const current = getLocal([]);
  const updated = current.filter(b => b.id !== id);
  setLocal(updated);

  try {
    await apiDelete(`/api/harvesting/batches/${id}`);
  } catch (e) {
    console.warn("Harvest batch backend delete failed:", e);
  }
  return true;
}
