// ==========================================================================
// BioNova Inventory Module - Centralized Live API Service
// Connected to Supabase PostgreSQL & Render/Local Spring Boot Backend
// ==========================================================================
import { apiGet, apiPost, apiPut, apiDelete } from "../../../utils/api";

const SUPABASE_URL = "https://daaoeapbouspxcuprsqx.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhYW9lYXBib3VzcHhjdXByc3F4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MTI1NDI5MCwiZXhwIjoyMDk2ODMwMjkwfQ.h824ASj8U-DhJFY8tDUThMa9DuxSD3lUxdliV3fCDbE";

const supabaseHeaders = {
  apikey: SUPABASE_KEY,
  Authorization: `Bearer ${SUPABASE_KEY}`,
  "Content-Type": "application/json",
  Prefer: "return=representation"
};

// Local storage helpers
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

// Generic Supabase REST caller
async function supabaseFetch(table, method = "GET", query = "", body = null) {
  try {
    const url = `${SUPABASE_URL}/rest/v1/${table}${query ? (query.startsWith("?") ? query : `?${query}`) : ""}`;
    const opts = {
      method,
      headers: supabaseHeaders
    };
    if (body) {
      opts.body = JSON.stringify(body);
    }
    const res = await fetch(url, opts);
    if (!res.ok) {
      const errText = await res.text();
      console.warn(`Supabase ${method} ${table} error (${res.status}):`, errText);
      return null;
    }
    if (method === "DELETE") return true;
    const data = await res.json();
    return data;
  } catch (err) {
    console.warn(`Supabase network error on ${table}:`, err);
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. ITEMS (inventory_items)
// ─────────────────────────────────────────────────────────────────────────────
const STORAGE_KEY_ITEMS = "bionova_inventory_items_v1";

function mapItemFromDb(r) {
  return {
    id: r.id,
    sku: r.sku || "",
    name: r.name || "",
    category: r.category || "Seeds",
    batchNo: r.batch_no || r.batchNo || "",
    currentStock: r.current_stock !== undefined && r.current_stock !== null ? Number(r.current_stock) : (r.currentStock || 0),
    reorderThreshold: r.reorder_threshold !== undefined && r.reorder_threshold !== null ? Number(r.reorder_threshold) : (r.reorderThreshold || 0),
    uom: r.uom || "Kg",
    plantLocation: r.plant_location || r.plantLocation || "Plant 1 - Hyderabad East CBG",
    unitCost: r.unit_cost !== undefined && r.unit_cost !== null ? Number(r.unit_cost) : (r.unitCost || 0),
    expiryDate: r.expiry_date || r.expiryDate || "",
    status: r.status || "In Stock",
    notes: r.remarks || r.notes || "",
    remarks: r.remarks || r.notes || "",
    supplier: r.supplier || "BioNova Registered Vendor"
  };
}

function mapItemToDb(item) {
  return {
    sku: item.sku || `INV-${Date.now().toString().slice(-6)}`,
    name: item.name || "",
    category: item.category || "Seeds",
    batch_no: item.batchNo || item.batch_no || "",
    current_stock: Number(item.currentStock ?? item.current_stock ?? 0),
    reorder_threshold: Number(item.reorderThreshold ?? item.reorder_threshold ?? 0),
    uom: item.uom || "Kg",
    plant_location: item.plantLocation || item.plant_location || "Plant 1 - Hyderabad East CBG",
    unit_cost: Number(item.unitCost ?? item.unit_cost ?? 0),
    expiry_date: item.expiryDate || item.expiry_date || "",
    status: item.status || "In Stock",
    remarks: item.notes || item.remarks || ""
  };
}

export async function getInventoryItems() {
  // 1. Try Supabase direct
  const sbData = await supabaseFetch("inventory_items", "GET", "select=*&order=id.desc");
  if (Array.isArray(sbData) && sbData.length > 0) {
    const mapped = sbData.map(mapItemFromDb);
    setLocal(STORAGE_KEY_ITEMS, mapped);
    return mapped;
  }
  // 2. Try Backend
  try {
    const res = await apiGet("/api/inventory/items");
    if (Array.isArray(res) && res.length > 0) {
      const mapped = res.map(mapItemFromDb);
      setLocal(STORAGE_KEY_ITEMS, mapped);
      return mapped;
    }
  } catch (e) {}
  // 3. Fallback to LocalStorage
  return getLocal(STORAGE_KEY_ITEMS, []);
}

export async function saveInventoryItem(item, id = null) {
  const isUpdate = Boolean(id || (item.id && typeof item.id === "number" && item.id < 1000000000000));
  const recordId = id || (isUpdate ? item.id : null);
  const dbPayload = mapItemToDb(item);

  let savedRecord = null;

  // Supabase save
  if (isUpdate && recordId) {
    const res = await supabaseFetch("inventory_items", "PATCH", `id=eq.${recordId}`, dbPayload);
    if (Array.isArray(res) && res[0]) savedRecord = mapItemFromDb(res[0]);
  } else {
    const res = await supabaseFetch("inventory_items", "POST", "", dbPayload);
    if (Array.isArray(res) && res[0]) savedRecord = mapItemFromDb(res[0]);
  }

  // Backend sync (fire-and-forget / parallel)
  try {
    if (isUpdate && recordId) {
      await apiPut(`/api/inventory/items/${recordId}`, { ...dbPayload, id: recordId });
    } else {
      await apiPost("/api/inventory/items", dbPayload);
    }
  } catch (e) {}

  const finalItem = savedRecord || { ...item, id: recordId || Date.now() };

  // Update local cache
  const current = getLocal(STORAGE_KEY_ITEMS, []);
  let updated;
  if (isUpdate && recordId) {
    updated = current.map(it => (it.id === recordId ? { ...it, ...finalItem } : it));
  } else {
    updated = [finalItem, ...current.filter(it => it.id !== finalItem.id)];
  }
  setLocal(STORAGE_KEY_ITEMS, updated);

  return finalItem;
}

export async function deleteInventoryItem(id) {
  await supabaseFetch("inventory_items", "DELETE", `id=eq.${id}`);
  try {
    await apiDelete(`/api/inventory/items/${id}`);
  } catch (e) {}
  const current = getLocal(STORAGE_KEY_ITEMS, []);
  setLocal(STORAGE_KEY_ITEMS, current.filter(it => it.id !== id));
  return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. CIVIL MATERIALS BOM (inventory_civil_bom)
// ─────────────────────────────────────────────────────────────────────────────
const STORAGE_KEY_CIVIL = "bionova_civil_materials_bom_v1";

function mapCivilFromDb(r) {
  const p = r.planned_qty ?? r.bomRequiredQty ?? 0;
  const i = r.issued_qty ?? r.allocatedQty ?? 0;
  return {
    id: r.id,
    code: r.spec_code || r.code || "",
    specCode: r.spec_code || r.specCode || "",
    name: r.material_name || r.name || "",
    materialName: r.material_name || r.materialName || "",
    stage: r.stage || "",
    category: r.stage || "Structural Steel",
    bomRequiredQty: Number(p),
    plannedQty: Number(p),
    allocatedQty: Number(i),
    issuedQty: Number(i),
    procuredQty: Number(p),
    currentStock: Math.max(0, Number(p) - Number(i)),
    uom: r.uom || "MT",
    supplier: r.supplier || "",
    deliveryStatus: r.delivery_status || r.deliveryStatus || "Stock Available",
    status: r.delivery_status || r.status || "Stock Available",
    unitCost: Number(r.cost_per_unit ?? r.unitCost ?? 0),
    costPerUnit: Number(r.cost_per_unit ?? r.costPerUnit ?? 0),
    inspectionStatus: r.inspection_status || r.inspectionStatus || "Passed 3rd-Party QC",
    gradeSpec: r.grade_spec || r.gradeSpec || "IS Standard Grade",
    targetStructure: r.target_structure || r.targetStructure || "Anaerobic Digester Complex"
  };
}

function mapCivilToDb(item) {
  return {
    spec_code: item.code || item.specCode || item.spec_code || `CIV-${Date.now().toString().slice(-5)}`,
    material_name: item.name || item.materialName || item.material_name || "",
    stage: item.stage || item.category || "Structural Steel",
    planned_qty: Number(item.bomRequiredQty ?? item.plannedQty ?? item.planned_qty ?? 0),
    issued_qty: Number(item.allocatedQty ?? item.issuedQty ?? item.issued_qty ?? 0),
    uom: item.uom || "MT",
    supplier: item.supplier || "",
    delivery_status: item.deliveryStatus || item.status || item.delivery_status || "Stock Available",
    cost_per_unit: Number(item.unitCost ?? item.costPerUnit ?? item.cost_per_unit ?? 0),
    inspection_status: item.inspectionStatus || item.inspection_status || "Passed 3rd-Party QC"
  };
}

export async function getCivilMaterials() {
  const sbData = await supabaseFetch("inventory_civil_bom", "GET", "select=*&order=id.desc");
  if (Array.isArray(sbData) && sbData.length > 0) {
    const mapped = sbData.map(mapCivilFromDb);
    setLocal(STORAGE_KEY_CIVIL, mapped);
    return mapped;
  }
  try {
    const res = await apiGet("/api/inventory/civil-bom");
    if (Array.isArray(res) && res.length > 0) {
      const mapped = res.map(mapCivilFromDb);
      setLocal(STORAGE_KEY_CIVIL, mapped);
      return mapped;
    }
  } catch (e) {}
  return getLocal(STORAGE_KEY_CIVIL, []);
}

export async function saveCivilMaterial(item, id = null) {
  const isUpdate = Boolean(id || (item.id && typeof item.id === "number" && item.id < 1000000000000));
  const recordId = id || (isUpdate ? item.id : null);
  const dbPayload = mapCivilToDb(item);

  let savedRecord = null;
  if (isUpdate && recordId) {
    const res = await supabaseFetch("inventory_civil_bom", "PATCH", `id=eq.${recordId}`, dbPayload);
    if (Array.isArray(res) && res[0]) savedRecord = mapCivilFromDb(res[0]);
  } else {
    const res = await supabaseFetch("inventory_civil_bom", "POST", "", dbPayload);
    if (Array.isArray(res) && res[0]) savedRecord = mapCivilFromDb(res[0]);
  }

  try {
    if (isUpdate && recordId) {
      await apiPut(`/api/inventory/civil-bom/${recordId}`, { ...dbPayload, id: recordId });
    } else {
      await apiPost("/api/inventory/civil-bom", dbPayload);
    }
  } catch (e) {}

  const finalItem = savedRecord || { ...item, id: recordId || Date.now() };
  const current = getLocal(STORAGE_KEY_CIVIL, []);
  let updated;
  if (isUpdate && recordId) {
    updated = current.map(it => (it.id === recordId ? { ...it, ...finalItem } : it));
  } else {
    updated = [finalItem, ...current.filter(it => it.id !== finalItem.id)];
  }
  setLocal(STORAGE_KEY_CIVIL, updated);
  return finalItem;
}

export async function deleteCivilMaterial(id) {
  await supabaseFetch("inventory_civil_bom", "DELETE", `id=eq.${id}`);
  try {
    await apiDelete(`/api/inventory/civil-bom/${id}`);
  } catch (e) {}
  const current = getLocal(STORAGE_KEY_CIVIL, []);
  setLocal(STORAGE_KEY_CIVIL, current.filter(it => it.id !== id));
  return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. FASTENERS & HARDWARE (inventory_fasteners)
// ─────────────────────────────────────────────────────────────────────────────
const STORAGE_KEY_FASTENERS = "bionova_fasteners_inventory_v1";

function mapFastenerFromDb(r) {
  return {
    id: r.id,
    sku: r.item_code || r.sku || "",
    itemCode: r.item_code || r.itemCode || "",
    name: r.description || r.name || "",
    description: r.description || r.name || "",
    category: r.category || "High-Tensile Bolts",
    grade: r.grade || "Grade 10.9",
    threadSpec: r.size || r.threadSpec || "",
    size: r.size || r.threadSpec || "",
    coating: r.coating || "Hot-Dip Galvanized",
    batchNo: r.batch_no || r.batchNo || "BAT-2026-FST01",
    heatNo: r.heat_no || r.heatNo || "HT-77210",
    mtcCertNo: r.standard_cert || r.mtcCertNo || "",
    standardCert: r.standard_cert || r.standardCert || "",
    location: r.bin_location || r.location || "Rack B-04 / Bin 12",
    binLocation: r.bin_location || r.binLocation || "Rack B-04 / Bin 12",
    currentStock: Number(r.in_stock ?? r.currentStock ?? 0),
    inStock: Number(r.in_stock ?? r.inStock ?? 0),
    reorderThreshold: Number(r.reorder_level ?? r.reorderThreshold ?? 0),
    reorderLevel: Number(r.reorder_level ?? r.reorderLevel ?? 0),
    uom: r.uom || "Nos",
    unitCost: Number(r.unit_cost ?? r.unitCost ?? 85),
    supplier: r.supplier || "Sundram Fasteners Ltd",
    application: r.application || "Plant Infrastructure Assembly"
  };
}

function mapFastenerToDb(item) {
  return {
    item_code: item.sku || item.itemCode || item.item_code || `FST-${Date.now().toString().slice(-6)}`,
    description: item.name || item.description || "",
    grade: item.grade || "Grade 10.9",
    size: item.threadSpec || item.size || "",
    in_stock: Number(item.currentStock ?? item.inStock ?? item.in_stock ?? 0),
    reorder_level: Number(item.reorderThreshold ?? item.reorderLevel ?? item.reorder_level ?? 0),
    uom: item.uom || "Nos",
    bin_location: item.location || item.binLocation || item.bin_location || "Rack B-04 / Bin 12",
    supplier: item.supplier || "",
    standard_cert: item.mtcCertNo || item.standardCert || item.standard_cert || ""
  };
}

export async function getFasteners() {
  const sbData = await supabaseFetch("inventory_fasteners", "GET", "select=*&order=id.desc");
  if (Array.isArray(sbData) && sbData.length > 0) {
    const mapped = sbData.map(mapFastenerFromDb);
    setLocal(STORAGE_KEY_FASTENERS, mapped);
    return mapped;
  }
  try {
    const res = await apiGet("/api/inventory/fasteners");
    if (Array.isArray(res) && res.length > 0) {
      const mapped = res.map(mapFastenerFromDb);
      setLocal(STORAGE_KEY_FASTENERS, mapped);
      return mapped;
    }
  } catch (e) {}
  return getLocal(STORAGE_KEY_FASTENERS, []);
}

export async function saveFastener(item, id = null) {
  const isUpdate = Boolean(id || (item.id && typeof item.id === "number" && item.id < 1000000000000));
  const recordId = id || (isUpdate ? item.id : null);
  const dbPayload = mapFastenerToDb(item);

  let savedRecord = null;
  if (isUpdate && recordId) {
    const res = await supabaseFetch("inventory_fasteners", "PATCH", `id=eq.${recordId}`, dbPayload);
    if (Array.isArray(res) && res[0]) savedRecord = mapFastenerFromDb(res[0]);
  } else {
    const res = await supabaseFetch("inventory_fasteners", "POST", "", dbPayload);
    if (Array.isArray(res) && res[0]) savedRecord = mapFastenerFromDb(res[0]);
  }

  try {
    if (isUpdate && recordId) {
      await apiPut(`/api/inventory/fasteners/${recordId}`, { ...dbPayload, id: recordId });
    } else {
      await apiPost("/api/inventory/fasteners", dbPayload);
    }
  } catch (e) {}

  const finalItem = savedRecord || { ...item, id: recordId || Date.now() };
  const current = getLocal(STORAGE_KEY_FASTENERS, []);
  let updated;
  if (isUpdate && recordId) {
    updated = current.map(it => (it.id === recordId ? { ...it, ...finalItem } : it));
  } else {
    updated = [finalItem, ...current.filter(it => it.id !== finalItem.id)];
  }
  setLocal(STORAGE_KEY_FASTENERS, updated);
  return finalItem;
}

export async function deleteFastener(id) {
  await supabaseFetch("inventory_fasteners", "DELETE", `id=eq.${id}`);
  try {
    await apiDelete(`/api/inventory/fasteners/${id}`);
  } catch (e) {}
  const current = getLocal(STORAGE_KEY_FASTENERS, []);
  setLocal(STORAGE_KEY_FASTENERS, current.filter(it => it.id !== id));
  return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. PIPING & INSTRUMENTATION (inventory_piping)
// ─────────────────────────────────────────────────────────────────────────────
const STORAGE_KEY_PIPING = "bionova_piping_spares_v1";

function mapPipingFromDb(r) {
  return {
    id: r.id,
    tagNo: r.tag_no || r.tagNo || "",
    tag_no: r.tag_no || r.tagNo || "",
    name: r.component_name || r.name || "",
    componentName: r.component_name || r.componentName || "",
    pidLineRef: r.pnd_ref || r.pidLineRef || "",
    pndRef: r.pnd_ref || r.pndRef || "",
    sizeRating: r.pressure_rating || r.line_size || r.sizeRating || "DN80 ANSI 150# RF",
    pressureRating: r.pressure_rating || r.pressureRating || "ANSI 150# RF",
    lineSize: r.line_size || r.lineSize || "DN80",
    material: r.material_moc || r.material || "SS 316L",
    materialMoc: r.material_moc || r.materialMoc || "SS 316L",
    currentStock: Number(r.stock_qty ?? r.currentStock ?? 0),
    stockQty: Number(r.stock_qty ?? r.stockQty ?? 0),
    reorderThreshold: Number(r.reorder_point ?? r.reorderThreshold ?? 0),
    reorderPoint: Number(r.reorder_point ?? r.reorderPoint ?? 0),
    category: r.valve_type || r.category || "Manual Valves",
    valveType: r.valve_type || r.valveType || "Manual Valves",
    location: r.plant_location || r.location || "Valves & Actuators Store",
    plantLocation: r.plant_location || r.plantLocation || "Valves & Actuators Store",
    uom: r.uom || "Units",
    unitCost: Number(r.unit_cost ?? r.unitCost ?? 45000),
    supplier: r.supplier || "L&T Valves Limited",
    notes: r.notes || ""
  };
}

function mapPipingToDb(item) {
  return {
    tag_no: item.tagNo || item.tag_no || `PID-${Date.now().toString().slice(-5)}`,
    component_name: item.name || item.componentName || item.component_name || "",
    pnd_ref: item.pidLineRef || item.pndRef || item.pnd_ref || "",
    line_size: (item.lineSize || item.sizeRating || "DN80").slice(0, 50),
    pressure_rating: (item.pressureRating || item.sizeRating || "ANSI 150#").slice(0, 50),
    material_moc: (item.material || item.materialMoc || "SS 316L").slice(0, 50),
    stock_qty: Number(item.currentStock ?? item.stockQty ?? item.stock_qty ?? 0),
    reorder_point: Number(item.reorderThreshold ?? item.reorderPoint ?? item.reorder_point ?? 0),
    valve_type: (item.category || item.valveType || "Manual Valves").slice(0, 50),
    plant_location: (item.location || item.plantLocation || "Valves & Actuators Store").slice(0, 100)
  };
}

export async function getPipingSpares() {
  const sbData = await supabaseFetch("inventory_piping", "GET", "select=*&order=id.desc");
  if (Array.isArray(sbData) && sbData.length > 0) {
    const mapped = sbData.map(mapPipingFromDb);
    setLocal(STORAGE_KEY_PIPING, mapped);
    return mapped;
  }
  try {
    const res = await apiGet("/api/inventory/piping");
    if (Array.isArray(res) && res.length > 0) {
      const mapped = res.map(mapPipingFromDb);
      setLocal(STORAGE_KEY_PIPING, mapped);
      return mapped;
    }
  } catch (e) {}
  return getLocal(STORAGE_KEY_PIPING, []);
}

export async function savePipingSpare(item, id = null) {
  const isUpdate = Boolean(id || (item.id && typeof item.id === "number" && item.id < 1000000000000));
  const recordId = id || (isUpdate ? item.id : null);
  const dbPayload = mapPipingToDb(item);

  let savedRecord = null;
  if (isUpdate && recordId) {
    const res = await supabaseFetch("inventory_piping", "PATCH", `id=eq.${recordId}`, dbPayload);
    if (Array.isArray(res) && res[0]) savedRecord = mapPipingFromDb(res[0]);
  } else {
    const res = await supabaseFetch("inventory_piping", "POST", "", dbPayload);
    if (Array.isArray(res) && res[0]) savedRecord = mapPipingFromDb(res[0]);
  }

  try {
    if (isUpdate && recordId) {
      await apiPut(`/api/inventory/piping/${recordId}`, { ...dbPayload, id: recordId });
    } else {
      await apiPost("/api/inventory/piping", dbPayload);
    }
  } catch (e) {}

  const finalItem = savedRecord || { ...item, id: recordId || Date.now() };
  const current = getLocal(STORAGE_KEY_PIPING, []);
  let updated;
  if (isUpdate && recordId) {
    updated = current.map(it => (it.id === recordId ? { ...it, ...finalItem } : it));
  } else {
    updated = [finalItem, ...current.filter(it => it.id !== finalItem.id)];
  }
  setLocal(STORAGE_KEY_PIPING, updated);
  return finalItem;
}

export async function deletePipingSpare(id) {
  await supabaseFetch("inventory_piping", "DELETE", `id=eq.${id}`);
  try {
    await apiDelete(`/api/inventory/piping/${id}`);
  } catch (e) {}
  const current = getLocal(STORAGE_KEY_PIPING, []);
  setLocal(STORAGE_KEY_PIPING, current.filter(it => it.id !== id));
  return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. EQUIPMENT WARRANTY (inventory_warranty)
// ─────────────────────────────────────────────────────────────────────────────
const STORAGE_KEY_WARRANTY = "bionova_equipment_warranty_v1";

function mapWarrantyFromDb(r) {
  return {
    id: r.id,
    assetTag: r.tag_code || r.assetTag || r.machineTag || "",
    tagCode: r.tag_code || r.tagCode || "",
    machineTag: r.tag_code || r.machineTag || "",
    machineName: r.equipment_name || r.machineName || r.name || "",
    equipmentName: r.equipment_name || r.equipmentName || "",
    name: r.equipment_name || r.name || "",
    oem: r.oem_vendor || r.oem || "",
    oemVendor: r.oem_vendor || r.oemVendor || "",
    plantLocation: r.plant_location || r.plantLocation || "Plant 1 - Hyderabad East CBG",
    purchaseDate: r.purchase_date || r.purchaseDate || "2025-01-15",
    commissionDate: r.commissioning_date || r.commissionDate || "",
    commissioningDate: r.commissioning_date || r.commissioningDate || "",
    warrantyStartDate: r.warranty_start_date || r.warrantyStartDate || r.commissioning_date || "",
    warrantyEndDate: r.warranty_expires_on || r.warrantyEndDate || "",
    warrantyExpiresOn: r.warranty_expires_on || r.warrantyExpiresOn || "",
    contractType: r.contract_type || r.contractType || "Comprehensive OEM AMC",
    slaResponseHours: r.sla_response_hours || r.slaResponseHours || 24,
    serviceContact: r.amc_vendor || r.serviceContact || "",
    amcVendor: r.amc_vendor || r.amcVendor || "",
    amcActive: Boolean(r.amc_active),
    claimHistory: r.claim_history || r.claimHistory || "None",
    status: r.status || "Active",
    serialNo: r.serial_no || r.serialNo || "SN-2026-001"
  };
}

function mapWarrantyToDb(item) {
  return {
    tag_code: item.assetTag || item.machineTag || item.tagCode || item.tag_code || `AST-${Date.now().toString().slice(-6)}`,
    equipment_name: item.machineName || item.equipmentName || item.name || item.equipment_name || "",
    oem_vendor: (item.oem || item.oemVendor || item.oem_vendor || "").slice(0, 100),
    plant_location: (item.plantLocation || item.plant_location || "").slice(0, 100),
    commissioning_date: item.commissionDate || item.commissioningDate || item.commissioning_date || "",
    warranty_expires_on: item.warrantyEndDate || item.warrantyExpiresOn || item.warranty_expires_on || "",
    amc_active: Boolean(item.amcActive !== undefined ? item.amcActive : true),
    amc_vendor: (item.serviceContact || item.amcVendor || item.amc_vendor || "").slice(0, 100),
    claim_history: (item.claimHistory || item.claim_history || "None").slice(0, 255),
    status: (item.status || "Active").slice(0, 50)
  };
}

export async function getEquipmentWarranties() {
  const sbData = await supabaseFetch("inventory_warranty", "GET", "select=*&order=id.desc");
  if (Array.isArray(sbData) && sbData.length > 0) {
    const mapped = sbData.map(mapWarrantyFromDb);
    setLocal(STORAGE_KEY_WARRANTY, mapped);
    return mapped;
  }
  try {
    const res = await apiGet("/api/inventory/warranties");
    if (Array.isArray(res) && res.length > 0) {
      const mapped = res.map(mapWarrantyFromDb);
      setLocal(STORAGE_KEY_WARRANTY, mapped);
      return mapped;
    }
  } catch (e) {}
  return getLocal(STORAGE_KEY_WARRANTY, []);
}

export async function saveEquipmentWarranty(item, id = null) {
  const isUpdate = Boolean(id || (item.id && typeof item.id === "number" && item.id < 1000000000000));
  const recordId = id || (isUpdate ? item.id : null);
  const dbPayload = mapWarrantyToDb(item);

  let savedRecord = null;
  if (isUpdate && recordId) {
    const res = await supabaseFetch("inventory_warranty", "PATCH", `id=eq.${recordId}`, dbPayload);
    if (Array.isArray(res) && res[0]) savedRecord = mapWarrantyFromDb(res[0]);
  } else {
    const res = await supabaseFetch("inventory_warranty", "POST", "", dbPayload);
    if (Array.isArray(res) && res[0]) savedRecord = mapWarrantyFromDb(res[0]);
  }

  try {
    if (isUpdate && recordId) {
      await apiPut(`/api/inventory/warranties/${recordId}`, { ...dbPayload, id: recordId });
    } else {
      await apiPost("/api/inventory/warranties", dbPayload);
    }
  } catch (e) {}

  const finalItem = savedRecord || { ...item, id: recordId || Date.now() };
  const current = getLocal(STORAGE_KEY_WARRANTY, []);
  let updated;
  if (isUpdate && recordId) {
    updated = current.map(it => (it.id === recordId ? { ...it, ...finalItem } : it));
  } else {
    updated = [finalItem, ...current.filter(it => it.id !== finalItem.id)];
  }
  setLocal(STORAGE_KEY_WARRANTY, updated);
  return finalItem;
}

export async function deleteEquipmentWarranty(id) {
  await supabaseFetch("inventory_warranty", "DELETE", `id=eq.${id}`);
  try {
    await apiDelete(`/api/inventory/warranties/${id}`);
  } catch (e) {}
  const current = getLocal(STORAGE_KEY_WARRANTY, []);
  setLocal(STORAGE_KEY_WARRANTY, current.filter(it => it.id !== id));
  return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. STOCK EXPIRY & SYSTEM ALERTS (inventory_alerts)
// ─────────────────────────────────────────────────────────────────────────────
const STORAGE_KEY_ALERTS = "bionova_inventory_alerts_v1";

function mapAlertFromDb(r) {
  return {
    id: r.id,
    title: r.description || r.title || "Inventory Alert",
    description: r.description || r.title || "Inventory Alert",
    type: r.alert_type || r.type || "Low Stock Alert",
    alertType: r.alert_type || r.type || "Low Stock Alert",
    materialName: r.item_ref || r.materialName || "",
    itemRef: r.item_ref || r.itemRef || "",
    batchNo: r.batch_no || r.batchNo || "",
    plantLocation: r.plant_location || r.plantLocation || "Plant 1 - Hyderabad East CBG",
    severity: r.severity || "Medium",
    currentVal: r.current_val || r.currentVal || 0,
    thresholdVal: r.threshold_val || r.thresholdVal || 0,
    expiryDaysRemaining: Number(r.expiry_days_remaining ?? r.expiryDaysRemaining ?? 0),
    actionRequired: r.action_taken || r.actionRequired || "",
    actionTaken: r.action_taken || r.actionTaken || "",
    status: r.status || "Active",
    timestamp: r.timestamp || new Date().toISOString().replace("T", " ").slice(0, 16)
  };
}

function mapAlertToDb(item) {
  return {
    alert_type: (item.type || item.alertType || item.alert_type || "Low Stock Alert").slice(0, 50),
    item_ref: (item.materialName || item.itemRef || item.item_ref || item.batchNo || "Material Ref").slice(0, 50),
    description: (item.title || item.description || "Alert Details").slice(0, 255),
    plant_location: (item.plantLocation || item.plant_location || "Plant 1 - Hyderabad East CBG").slice(0, 100),
    severity: (item.severity || "Medium").slice(0, 30),
    expiry_days_remaining: Number(item.expiryDaysRemaining ?? item.expiry_days_remaining ?? 0),
    action_taken: (item.actionRequired || item.actionTaken || item.action_taken || "Action pending").slice(0, 100),
    timestamp: item.timestamp || new Date().toISOString().replace("T", " ").slice(0, 16)
  };
}

export async function getStockAlerts() {
  const sbData = await supabaseFetch("inventory_alerts", "GET", "select=*&order=id.desc");
  if (Array.isArray(sbData) && sbData.length > 0) {
    const mapped = sbData.map(mapAlertFromDb);
    setLocal(STORAGE_KEY_ALERTS, mapped);
    return mapped;
  }
  try {
    const res = await apiGet("/api/inventory/alerts");
    if (Array.isArray(res) && res.length > 0) {
      const mapped = res.map(mapAlertFromDb);
      setLocal(STORAGE_KEY_ALERTS, mapped);
      return mapped;
    }
  } catch (e) {}
  return getLocal(STORAGE_KEY_ALERTS, []);
}

export async function saveStockAlert(item, id = null) {
  const isUpdate = Boolean(id || (item.id && typeof item.id === "number" && item.id < 1000000000000));
  const recordId = id || (isUpdate ? item.id : null);
  const dbPayload = mapAlertToDb(item);

  let savedRecord = null;
  if (isUpdate && recordId) {
    const res = await supabaseFetch("inventory_alerts", "PATCH", `id=eq.${recordId}`, dbPayload);
    if (Array.isArray(res) && res[0]) savedRecord = mapAlertFromDb(res[0]);
  } else {
    const res = await supabaseFetch("inventory_alerts", "POST", "", dbPayload);
    if (Array.isArray(res) && res[0]) savedRecord = mapAlertFromDb(res[0]);
  }

  try {
    if (isUpdate && recordId) {
      // Backend only defines POST and DELETE for alerts
      await apiPost("/api/inventory/alerts", { ...dbPayload, id: recordId });
    } else {
      await apiPost("/api/inventory/alerts", dbPayload);
    }
  } catch (e) {}

  const finalItem = savedRecord || { ...item, id: recordId || Date.now() };
  const current = getLocal(STORAGE_KEY_ALERTS, []);
  let updated;
  if (isUpdate && recordId) {
    updated = current.map(it => (it.id === recordId ? { ...it, ...finalItem } : it));
  } else {
    updated = [finalItem, ...current.filter(it => it.id !== finalItem.id)];
  }
  setLocal(STORAGE_KEY_ALERTS, updated);
  return finalItem;
}

export async function deleteStockAlert(id) {
  await supabaseFetch("inventory_alerts", "DELETE", `id=eq.${id}`);
  try {
    await apiDelete(`/api/inventory/alerts/${id}`);
  } catch (e) {}
  const current = getLocal(STORAGE_KEY_ALERTS, []);
  setLocal(STORAGE_KEY_ALERTS, current.filter(it => it.id !== id));
  return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. WAREHOUSE & WEIGHBRIDGE (inventory_weighbridge)
// ─────────────────────────────────────────────────────────────────────────────
const STORAGE_KEY_WEIGHBRIDGE = "bionova_weightbridge_portal_v1";

function mapWeighbridgeFromDb(r) {
  return {
    id: r.id,
    slipNo: r.slip_no || r.slipNo || "",
    slip_no: r.slip_no || r.slipNo || "",
    vehicleNo: r.vehicle_no || r.vehicleNo || "",
    vehicle_no: r.vehicle_no || r.vehicleNo || "",
    transporter: r.transporter_name || r.transporter || "",
    transporterName: r.transporter_name || r.transporterName || "",
    driverName: r.driver_name || r.driverName || "",
    materialName: r.material_type || r.materialName || "",
    materialType: r.material_type || r.materialType || "",
    grossWeightKg: Number(r.gross_weight ?? r.grossWeightKg ?? 0),
    grossWeight: Number(r.gross_weight ?? r.grossWeight ?? 0),
    tareWeightKg: r.tare_weight !== null && r.tare_weight !== undefined ? Number(r.tare_weight) : (r.tareWeightKg !== undefined ? Number(r.tareWeightKg) : null),
    tareWeight: r.tare_weight !== null && r.tare_weight !== undefined ? Number(r.tare_weight) : null,
    netWeightKg: r.net_weight !== null && r.net_weight !== undefined ? Number(r.net_weight) : (r.netWeightKg !== undefined ? Number(r.netWeightKg) : null),
    netWeight: r.net_weight !== null && r.net_weight !== undefined ? Number(r.net_weight) : null,
    uom: r.uom || "Kg",
    weighbridgeOperator: r.weighbridge_operator || r.weighbridgeOperator || "M. Ramesh (Gate Scale 1)",
    inTime: r.time_in || r.inTime || "",
    timeIn: r.time_in || r.timeIn || "",
    outTime: r.time_out || r.outTime || "",
    timeOut: r.time_out || r.timeOut || "",
    status: r.status || "Gross Weighed (Pending Tare)",
    warehouseZone: r.warehouse_zone || r.warehouseZone || "Zone 1 - Raw Biomass Yard",
    supplier: r.supplier || "BioNova Registered Vendor",
    notes: r.notes || ""
  };
}

function mapWeighbridgeToDb(item) {
  const g = Number(item.grossWeightKg ?? item.grossWeight ?? item.gross_weight ?? 0);
  const t = item.tareWeightKg !== null && item.tareWeightKg !== undefined ? Number(item.tareWeightKg) : (item.tare_weight !== null && item.tare_weight !== undefined ? Number(item.tare_weight) : null);
  const n = t !== null ? Math.max(0, g - t) : (item.netWeightKg !== null && item.netWeightKg !== undefined ? Number(item.netWeightKg) : null);

  return {
    slip_no: item.slipNo || item.slip_no || `WB-${Date.now().toString().slice(-6)}`,
    vehicle_no: (item.vehicleNo || item.vehicle_no || "").slice(0, 50),
    transporter_name: (item.transporter || item.transporterName || item.transporter_name || "").slice(0, 100),
    driver_name: (item.driverName || item.driver_name || "").slice(0, 100),
    material_type: (item.materialName || item.materialType || item.material_type || "").slice(0, 100),
    gross_weight: g,
    tare_weight: t,
    net_weight: n,
    uom: (item.uom || "Kg").slice(0, 20),
    weighbridge_operator: (item.weighbridgeOperator || item.weighbridge_operator || "Scale Operator").slice(0, 100),
    time_in: (item.inTime || item.timeIn || item.time_in || "").slice(0, 30),
    time_out: (item.outTime || item.timeOut || item.time_out || "").slice(0, 30) || null,
    status: (item.status || (t !== null ? "Completed" : "Gross Weighed (Pending Tare)")).slice(0, 50)
  };
}

export async function getWeighbridgeSlips() {
  const sbData = await supabaseFetch("inventory_weighbridge", "GET", "select=*&order=id.desc");
  if (Array.isArray(sbData) && sbData.length > 0) {
    const mapped = sbData.map(mapWeighbridgeFromDb);
    setLocal(STORAGE_KEY_WEIGHBRIDGE, mapped);
    return mapped;
  }
  try {
    const res = await apiGet("/api/inventory/weighbridge");
    if (Array.isArray(res) && res.length > 0) {
      const mapped = res.map(mapWeighbridgeFromDb);
      setLocal(STORAGE_KEY_WEIGHBRIDGE, mapped);
      return mapped;
    }
  } catch (e) {}
  return getLocal(STORAGE_KEY_WEIGHBRIDGE, []);
}

export async function saveWeighbridgeSlip(item, id = null) {
  const isUpdate = Boolean(id || (item.id && typeof item.id === "number" && item.id < 1000000000000));
  const recordId = id || (isUpdate ? item.id : null);
  const dbPayload = mapWeighbridgeToDb(item);

  let savedRecord = null;
  if (isUpdate && recordId) {
    const res = await supabaseFetch("inventory_weighbridge", "PATCH", `id=eq.${recordId}`, dbPayload);
    if (Array.isArray(res) && res[0]) savedRecord = mapWeighbridgeFromDb(res[0]);
  } else {
    const res = await supabaseFetch("inventory_weighbridge", "POST", "", dbPayload);
    if (Array.isArray(res) && res[0]) savedRecord = mapWeighbridgeFromDb(res[0]);
  }

  try {
    if (isUpdate && recordId) {
      await apiPut(`/api/inventory/weighbridge/${recordId}`, { ...dbPayload, id: recordId });
    } else {
      await apiPost("/api/inventory/weighbridge", dbPayload);
    }
  } catch (e) {}

  const finalItem = savedRecord || { ...item, id: recordId || Date.now() };
  const current = getLocal(STORAGE_KEY_WEIGHBRIDGE, []);
  let updated;
  if (isUpdate && recordId) {
    updated = current.map(it => (it.id === recordId ? { ...it, ...finalItem } : it));
  } else {
    updated = [finalItem, ...current.filter(it => it.id !== finalItem.id)];
  }
  setLocal(STORAGE_KEY_WEIGHBRIDGE, updated);
  return finalItem;
}

export async function deleteWeighbridgeSlip(id) {
  await supabaseFetch("inventory_weighbridge", "DELETE", `id=eq.${id}`);
  try {
    await apiDelete(`/api/inventory/weighbridge/${id}`);
  } catch (e) {}
  const current = getLocal(STORAGE_KEY_WEIGHBRIDGE, []);
  setLocal(STORAGE_KEY_WEIGHBRIDGE, current.filter(it => it.id !== id));
  return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. MULTI-TIER VENDORS (inventory_vendors)
// ─────────────────────────────────────────────────────────────────────────────
const STORAGE_KEY_VENDORS = "bionova_vendor_management_v1";

function mapVendorFromDb(r) {
  return {
    id: r.id,
    vendorCode: r.vendor_code || r.vendorCode || "",
    vendor_code: r.vendor_code || r.vendorCode || "",
    name: r.vendor_name || r.name || "",
    vendorName: r.vendor_name || r.vendorName || "",
    tier: r.tier || "Tier 1 - Strategic EPC / OEM",
    category: r.category || "Plant Construction & Civil",
    plantLocation: r.plant_location || r.plantLocation || "Plant 1 - Hyderabad East CBG",
    contactPerson: r.contact_person || r.contactPerson || "",
    phone: r.phone || "",
    email: r.email || "",
    gstin: r.gstin || "",
    panNo: r.pan || r.panNo || "",
    pan: r.pan || r.panNo || "",
    msmeStatus: r.msme_status || r.msmeStatus || "Small Enterprise",
    ratingStars: Number(r.rating ?? r.ratingStars ?? 4.8),
    rating: Number(r.rating ?? r.rating ?? 4.8),
    paymentTerms: r.payment_terms || r.paymentTerms || "Net 30 Days",
    creditLimit: Number(r.contract_value || 5.0),
    contractValue: r.contract_value || "5000000",
    slaStatus: r.sla_status || "100% Compliant",
    onTimeDeliveryRate: 96.0,
    qualityAcceptanceRate: 98.8,
    performanceGrade: "Grade A+ (Preferred Partner)",
    address: "Industrial Growth Corridor, Telangana",
    activeContractRef: `VND-BN-SLA-2026-0${r.id}`,
    contractStartDate: "2026-01-01",
    contractEndDate: "2027-12-31",
    slaResponseHours: 24,
    notes: "Approved supplier for BioNova industrial supply chain and plant fabrication."
  };
}

function mapVendorToDb(item) {
  return {
    vendor_code: (item.vendorCode || item.vendor_code || `VND-T1-0${Date.now().toString().slice(-3)}`).slice(0, 50),
    vendor_name: (item.name || item.vendorName || item.vendor_name || "").slice(0, 150),
    tier: (item.tier || "Tier 1 - Strategic EPC / OEM").slice(0, 30),
    category: (item.category || "Plant Construction & Civil").slice(0, 100),
    plant_location: (item.plantLocation || item.plant_location || "Plant 1 - Hyderabad East CBG").slice(0, 100),
    contact_person: (item.contactPerson || item.contact_person || "").slice(0, 100),
    phone: (item.phone || "").slice(0, 50),
    email: (item.email || "").slice(0, 100),
    gstin: (item.gstin || "").slice(0, 30),
    pan: (item.panNo || item.pan || "").slice(0, 30),
    msme_status: (item.msmeStatus || item.msme_status || "Small Enterprise").slice(0, 100),
    rating: Number(item.ratingStars ?? item.rating ?? 4.8),
    contract_value: String(item.creditLimit || item.contractValue || "5000000").slice(0, 50),
    payment_terms: (item.paymentTerms || item.payment_terms || "Net 30 Days").slice(0, 50),
    sla_status: (item.slaStatus || item.sla_status || "100% Compliant").slice(0, 50)
  };
}

export async function getInventoryVendors() {
  const sbData = await supabaseFetch("inventory_vendors", "GET", "select=*&order=id.desc");
  if (Array.isArray(sbData) && sbData.length > 0) {
    const mapped = sbData.map(mapVendorFromDb);
    setLocal(STORAGE_KEY_VENDORS, mapped);
    return mapped;
  }
  try {
    const res = await apiGet("/api/inventory/vendors");
    if (Array.isArray(res) && res.length > 0) {
      const mapped = res.map(mapVendorFromDb);
      setLocal(STORAGE_KEY_VENDORS, mapped);
      return mapped;
    }
  } catch (e) {}
  return getLocal(STORAGE_KEY_VENDORS, []);
}

export async function saveInventoryVendor(item, id = null) {
  const isUpdate = Boolean(id || (item.id && typeof item.id === "number" && item.id < 1000000000000));
  const recordId = id || (isUpdate ? item.id : null);
  const dbPayload = mapVendorToDb(item);

  let savedRecord = null;
  if (isUpdate && recordId) {
    const res = await supabaseFetch("inventory_vendors", "PATCH", `id=eq.${recordId}`, dbPayload);
    if (Array.isArray(res) && res[0]) savedRecord = mapVendorFromDb(res[0]);
  } else {
    const res = await supabaseFetch("inventory_vendors", "POST", "", dbPayload);
    if (Array.isArray(res) && res[0]) savedRecord = mapVendorFromDb(res[0]);
  }

  try {
    if (isUpdate && recordId) {
      await apiPut(`/api/inventory/vendors/${recordId}`, { ...dbPayload, id: recordId });
    } else {
      await apiPost("/api/inventory/vendors", dbPayload);
    }
  } catch (e) {}

  const finalItem = savedRecord || { ...item, id: recordId || Date.now() };
  const current = getLocal(STORAGE_KEY_VENDORS, []);
  let updated;
  if (isUpdate && recordId) {
    updated = current.map(it => (it.id === recordId ? { ...it, ...finalItem } : it));
  } else {
    updated = [finalItem, ...current.filter(it => it.id !== finalItem.id)];
  }
  setLocal(STORAGE_KEY_VENDORS, updated);
  return finalItem;
}

export async function deleteInventoryVendor(id) {
  await supabaseFetch("inventory_vendors", "DELETE", `id=eq.${id}`);
  try {
    await apiDelete(`/api/inventory/vendors/${id}`);
  } catch (e) {}
  const current = getLocal(STORAGE_KEY_VENDORS, []);
  setLocal(STORAGE_KEY_VENDORS, current.filter(it => it.id !== id));
  return true;
}
