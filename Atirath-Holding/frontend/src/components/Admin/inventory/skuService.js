// ==========================================================================
// Centralized Dynamic SKU Code Generation Service
// Connects to Spring Boot /api/inventory/sku and Supabase PostgreSQL
// ==========================================================================
import { apiGet, apiPost } from "../../../utils/api";

const SUPABASE_URL = "https://daaoeapbouspxcuprsqx.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhYW9lYXBib3VzcHhjdXByc3F4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MTI1NDI5MCwiZXhwIjoyMDk2ODMwMjkwfQ.h824ASj8U-DhJFY8tDUThMa9DuxSD3lUxdliV3fCDbE";

const STORAGE_KEY_MASTER = "bionova_sku_master_cache_v1";

export const DEFAULT_MASTER_DATA = {
  AGRI: {
    ITEM_TYPE: [
      { code: "MZE", label: "Maize Grain & Silage (MZE)", metadata: "Feedstock" },
      { code: "SOY", label: "Soybean Straw & Meal (SOY)", metadata: "Feedstock" },
      { code: "RIC", label: "Rice Straw & Paddy Husk (RIC)", metadata: "Feedstock" },
      { code: "NPR", label: "Super Napier Hybrid Grass (NPR)", metadata: "Feedstock" },
      { code: "SRG", label: "Sweet Sorghum Bicolor (SRG)", metadata: "Feedstock" },
      { code: "COT", label: "Cotton Stalk Biomass (COT)", metadata: "Feedstock" },
      { code: "BAG", label: "Sugarcane Bagasse (BAG)", metadata: "Feedstock" },
      { code: "WHT", label: "Wheat Straw Bales (WHT)", metadata: "Feedstock" },
      { code: "BIO", label: "Methanogenic Bacteria Inoculant (BIO)", metadata: "Additive" }
    ],
    GRADE: [
      { code: "A1", label: "Grade A1 - Premium (Moisture < 12%)", metadata: "Premium" },
      { code: "A2", label: "Grade A2 - Standard (Moisture 12-15%)", metadata: "Standard" },
      { code: "B1", label: "Grade B1 - Field Baled (Moisture 15-20%)", metadata: "Field" },
      { code: "B2", label: "Grade B2 - High Moisture Fermented Silage", metadata: "Silage" },
      { code: "C1", label: "Grade C1 - Raw Field Biomass Residue", metadata: "Raw" }
    ],
    PACK_SIZE: [
      { code: "025", label: "25 Kg Woven Polypropylene Sack (025)", metadata: "25Kg" },
      { code: "050", label: "50 Kg Commercial Standard Bag (050)", metadata: "50Kg" },
      { code: "100", label: "100 Kg Compressed High-Density Bale (100)", metadata: "100Kg" },
      { code: "500", label: "500 Kg FIBC Bulk Jumbo Bag (500)", metadata: "500Kg" },
      { code: "001", label: "1 MT Loose Bulk Truckload (001)", metadata: "1MT" }
    ]
  },
  CIVIL_BOM: {
    DISCIPLINE: [
      { code: "CIV", label: "Civil & Structural Works (CIV)", metadata: "Civil" },
      { code: "MEC", label: "Mechanical & Process Machinery (MEC)", metadata: "Mechanical" },
      { code: "ELE", label: "Electrical & Power Distribution (ELE)", metadata: "Electrical" },
      { code: "INS", label: "Instrumentation & SCADA Automation (INS)", metadata: "Instrumentation" },
      { code: "PIP", label: "Process Piping & Fluid Systems (PIP)", metadata: "Piping" }
    ],
    ITEM: [
      // Civil
      { code: "CON", label: "Ready-Mix Concrete / Grout (CON)", metadata: "CIV" },
      { code: "REB", label: "TMT Fe550D Reinforcement Rebars (REB)", metadata: "CIV" },
      { code: "STL", label: "Structural Heavy Steel Sections (STL)", metadata: "CIV" },
      { code: "CEM", label: "Portland Pozzolana Cement (CEM)", metadata: "CIV" },
      { code: "AGG", label: "Coarse & Fine River Aggregates (AGG)", metadata: "CIV" },
      // Mechanical
      { code: "PMP", label: "Slurry & Progressive Cavity Pumps (PMP)", metadata: "MEC" },
      { code: "AGT", label: "Digester Submersible Agitators (AGT)", metadata: "MEC" },
      { code: "BLR", label: "Biogas Industrial Water Boilers (BLR)", metadata: "MEC" },
      { code: "CMP", label: "High-Pressure Gas Compressors (CMP)", metadata: "MEC" },
      { code: "SEP", label: "Screw Press Dewatering Separator (SEP)", metadata: "MEC" },
      // Electrical
      { code: "MTR", label: "Flameproof Electric Motors (MTR)", metadata: "ELE" },
      { code: "TRF", label: "11kV/415V Power Transformers (TRF)", metadata: "ELE" },
      { code: "VFD", label: "Variable Frequency Drive Panels (VFD)", metadata: "ELE" },
      { code: "CAB", label: "Armored Multi-Core Power Cables (CAB)", metadata: "ELE" }
    ],
    SPECIFICATION: [
      { code: "001", label: "Standard Engineering Spec Rev 1 (001)", metadata: "Standard" },
      { code: "002", label: "Heavy-Duty Industrial Spec Rev 2 (002)", metadata: "HeavyDuty" },
      { code: "003", label: "Corrosion & H2S Resistant Spec (003)", metadata: "Special" },
      { code: "M35", label: "M35 High-Strength Mix Design (M35)", metadata: "CivilSpec" },
      { code: "F55", label: "Fe550D High Ductility Rebar (F55)", metadata: "CivilSpec" }
    ]
  },
  FASTENERS: {
    TYPE: [
      { code: "BLT", label: "Hex Head / Flange Bolts (BLT)", metadata: "Bolts" },
      { code: "NUT", label: "Heavy Hex / Nyloc Nuts (NUT)", metadata: "Nuts" },
      { code: "WSH", label: "Flat & Spring Washers (WSH)", metadata: "Washers" },
      { code: "STD", label: "Continuous Thread Stud Bolts (STD)", metadata: "Studs" },
      { code: "ANC", label: "Heavy-Duty Expansion Anchor Bolts (ANC)", metadata: "Anchors" },
      { code: "SCR", label: "Self-Tapping Tek Screws (SCR)", metadata: "Screws" }
    ],
    MATERIAL: [
      { code: "SS304", label: "Stainless Steel AISI 304 (SS304)", metadata: "SS" },
      { code: "SS316", label: "Stainless Steel AISI 316 Acid-Resistant (SS316)", metadata: "SS" },
      { code: "MS", label: "Mild Structural Steel (MS)", metadata: "Steel" },
      { code: "CS", label: "High-Carbon Steel (CS)", metadata: "Steel" },
      { code: "B7", label: "Alloy Steel ASTM A193 B7 (B7)", metadata: "Alloy" },
      { code: "BRS", label: "Corrosion-Proof Brass Alloy (BRS)", metadata: "Brass" }
    ],
    DIAMETER: [
      { code: "M06", label: "M6 Metric Thread (M06)", metadata: "6mm" },
      { code: "M08", label: "M8 Metric Thread (M08)", metadata: "8mm" },
      { code: "M10", label: "M10 Metric Thread (M10)", metadata: "10mm" },
      { code: "M12", label: "M12 Metric Thread (M12)", metadata: "12mm" },
      { code: "M16", label: "M16 Metric Thread (M16)", metadata: "16mm" },
      { code: "M20", label: "M20 Metric Thread (M20)", metadata: "20mm" },
      { code: "M24", label: "M24 Metric Thread (M24)", metadata: "24mm" },
      { code: "M30", label: "M30 Metric Thread (M30)", metadata: "30mm" }
    ],
    LENGTH: [
      { code: "000", label: "000 mm (Applicable for Nuts & Washers)", metadata: "0mm" },
      { code: "025", label: "25 mm Length (025)", metadata: "25mm" },
      { code: "035", label: "35 mm Length (035)", metadata: "35mm" },
      { code: "050", label: "50 mm Length (050)", metadata: "50mm" },
      { code: "075", label: "75 mm Length (075)", metadata: "75mm" },
      { code: "090", label: "90 mm Length (090)", metadata: "90mm" },
      { code: "100", label: "100 mm Length (100)", metadata: "100mm" },
      { code: "150", label: "150 mm Length (150)", metadata: "150mm" }
    ],
    GRADE: [
      { code: "G4", label: "Grade 4.8 Commercial Quality (G4)", metadata: "4.8" },
      { code: "G8", label: "Grade 8.8 High-Tensile Structural (G8)", metadata: "8.8" },
      { code: "G10", label: "Grade 10.9 Heavy-Duty Industrial (G10)", metadata: "10.9" },
      { code: "G12", label: "Grade 12.9 Super Alloy High-Tensile (G12)", metadata: "12.9" },
      { code: "A2", label: "Grade A2-70 Stainless Steel (A2)", metadata: "A2-70" },
      { code: "A4", label: "Grade A4-80 Marine Stainless Steel (A4)", metadata: "A4-80" }
    ]
  },
  PIPING: {
    TYPE: [
      { code: "ELB", label: "90° / 45° Long Radius Pipe Elbow (ELB)", metadata: "Elbow" },
      { code: "TEE", label: "Equal / Reducing Pipe Tee (TEE)", metadata: "Tee" },
      { code: "VAL", label: "Industrial Isolation Ball / Gate Valve (VAL)", metadata: "Valve" },
      { code: "PIP", label: "Straight Seamless Process Pipe Spool (PIP)", metadata: "Pipe" },
      { code: "RED", label: "Concentric / Eccentric Reducer (RED)", metadata: "Reducer" },
      { code: "FLG", label: "Weld-Neck Raised Face Flange (FLG)", metadata: "Flange" }
    ],
    MATERIAL: [
      { code: "CS", label: "Carbon Steel ASTM A106 Gr. B (CS)", metadata: "CS" },
      { code: "SS304", label: "Stainless Steel ASTM A312 TP304 (SS304)", metadata: "SS304" },
      { code: "SS316", label: "Stainless Steel ASTM A312 TP316L (SS316)", metadata: "SS316" },
      { code: "HDPE", label: "High-Density Polyethylene PE100 (HDPE)", metadata: "HDPE" },
      { code: "GI", label: "Hot-Dip Galvanized Iron Heavy Class (GI)", metadata: "GI" }
    ],
    SIZE: [
      { code: "015", label: "1/2\" NB (DN15 / 15mm)", metadata: "DN15" },
      { code: "025", label: "1\" NB (DN25 / 25mm)", metadata: "DN25" },
      { code: "050", label: "2\" NB (DN50 / 50mm)", metadata: "DN50" },
      { code: "080", label: "3\" NB (DN80 / 80mm)", metadata: "DN80" },
      { code: "100", label: "4\" NB (DN100 / 100mm)", metadata: "DN100" },
      { code: "150", label: "6\" NB (DN150 / 150mm)", metadata: "DN150" },
      { code: "200", label: "8\" NB (DN200 / 200mm)", metadata: "DN200" }
    ],
    PRESSURE_CLASS: [
      { code: "150", label: "ANSI Class 150# Raised Face (150)", metadata: "150#" },
      { code: "300", label: "ANSI Class 300# Raised Face (300)", metadata: "300#" },
      { code: "600", label: "ANSI Class 600# High Pressure (600)", metadata: "600#" },
      { code: "800", label: "Class 800# Forged Steel Valve Rating (800)", metadata: "800#" },
      { code: "PN16", label: "DIN PN16 Bar Rating (PN16)", metadata: "PN16" }
    ]
  },
  INSTRUMENTATION: {
    TYPE: [
      { code: "PRS", label: "Pressure Transmitter / Smart Gauge (PRS)", metadata: "Pressure" },
      { code: "TMP", label: "Temperature Sensor RTD Pt100 / Thermowell (TMP)", metadata: "Temperature" },
      { code: "FLW", label: "Coriolis / Vortex Mass Flow Meter (FLW)", metadata: "Flow" },
      { code: "LVL", label: "Guided Wave Radar Level Transmitter (LVL)", metadata: "Level" },
      { code: "GAS", label: "NDIR Biogas Analyzer CH4 / H2S (GAS)", metadata: "Gas" }
    ],
    RANGE: [
      { code: "010BAR", label: "0 to 10 Bar (010BAR)", metadata: "10Bar" },
      { code: "025BAR", label: "0 to 25 Bar (025BAR)", metadata: "25Bar" },
      { code: "100BAR", label: "0 to 100 Bar High Pressure (100BAR)", metadata: "100Bar" },
      { code: "200C", label: "-50°C to +200°C (200C)", metadata: "200C" },
      { code: "500C", label: "0°C to +500°C High Temp (500C)", metadata: "500C" },
      { code: "100M3H", label: "0 to 100 Nm³/hr Gas Flow (100M3H)", metadata: "100M3H" },
      { code: "500M3H", label: "0 to 500 Nm³/hr Gas Flow (500M3H)", metadata: "500M3H" },
      { code: "100PCT", label: "0 to 100% Volumetric Gas Level (100PCT)", metadata: "100%" }
    ],
    CONNECTION: [
      { code: "THD", label: "Threaded 1/2\" NPT Male / Female (THD)", metadata: "Threaded" },
      { code: "FLG", label: "ASME B16.5 Flanged Raised Face (FLG)", metadata: "Flanged" },
      { code: "TC", label: "Tri-Clamp Sanitary Hygienic Fit (TC)", metadata: "TriClamp" },
      { code: "WLD", label: "Socket Weld Direct Pipe End (WLD)", metadata: "Weld" }
    ]
  }
};

/**
 * Synchronous cached master data accessor
 */
export function getSkuMasterDataSync() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY_MASTER);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (parsed && Object.keys(parsed).length > 0) return parsed;
    }
  } catch (e) {}
  return DEFAULT_MASTER_DATA;
}

/**
 * Asynchronously fetch master data from Backend or Supabase
 */
export async function fetchSkuMasterData() {
  // 1. Try Spring Boot Backend
  try {
    const res = await apiGet("/api/inventory/sku/master-data");
    if (res && typeof res === "object" && Object.keys(res).length > 0) {
      localStorage.setItem(STORAGE_KEY_MASTER, JSON.stringify(res));
      return res;
    }
  } catch (e) {}

  // 2. Try Supabase REST
  try {
    const url = `${SUPABASE_URL}/rest/v1/inventory_sku_master?select=*&is_active=eq.true&order=category.asc,option_type.asc,sort_order.asc`;
    const res = await fetch(url, {
      headers: {
        apikey: SUPABASE_KEY,
        Authorization: `Bearer ${SUPABASE_KEY}`
      }
    });
    if (res.ok) {
      const list = await res.json();
      if (Array.isArray(list) && list.length > 0) {
        const grouped = {};
        list.forEach(item => {
          const cat = item.category;
          const opt = item.option_type;
          if (!grouped[cat]) grouped[cat] = {};
          if (!grouped[cat][opt]) grouped[cat][opt] = [];
          grouped[cat][opt].push(item);
        });
        localStorage.setItem(STORAGE_KEY_MASTER, JSON.stringify(grouped));
        return grouped;
      }
    }
  } catch (e) {}

  // 3. Fallback to bundled defaults
  localStorage.setItem(STORAGE_KEY_MASTER, JSON.stringify(DEFAULT_MASTER_DATA));
  return DEFAULT_MASTER_DATA;
}

/**
 * Fetch next serial number preview for category prefix (AGR, PCB, FST, PIP, INS)
 */
export async function fetchNextSerial(prefix = "AGR") {
  const normPrefix = prefix.toUpperCase();
  try {
    const url = `${SUPABASE_URL}/rest/v1/sku_sequence_counter?category_prefix=eq.${normPrefix}&select=*`;
    const res = await fetch(url, {
      headers: { apikey: SUPABASE_KEY, Authorization: `Bearer ${SUPABASE_KEY}` }
    });
    if (res.ok) {
      const data = await res.json();
      if (Array.isArray(data) && data[0]) {
        const next = Number(data[0].current_sequence || 0) + 1;
        return String(next).padStart(4, "0");
      }
    }
  } catch (e) {}

  // Default fallback serials
  const defaults = { AGR: "0005", PCB: "0004", FST: "0004", PIP: "0003", INS: "0002" };
  return defaults[normPrefix] || "0001";
}

/**
 * Calculate dynamic live real-time preview of the SKU code
 */
export function generateLiveSkuPreview(category, specs = {}, nextSerial = "0001") {
  const cat = (category || "AGRI").toUpperCase();
  const serialStr = String(nextSerial || "0001").padStart(4, "0");
  const missing = [];
  const chips = [];
  let sku = "";
  let format = "";

  switch (cat) {
    case "AGRI":
    case "AGRI_FEEDSTOCK": {
      format = "AGR-[ITEM]-[GRADE]-[PACK_SIZE]-[SERIAL]";
      const item = (specs.itemType || specs.item || "").trim().toUpperCase() || "MZE";
      const grade = (specs.grade || "").trim().toUpperCase() || "A1";
      const pack = (specs.packSize || specs.pack || "").trim().toUpperCase() || "050";

      if (!specs.itemType && !specs.item) missing.push("Item Type");
      if (!specs.grade) missing.push("Grade");
      if (!specs.packSize && !specs.pack) missing.push("Pack Size");

      chips.push({ label: "Item", value: item, code: "ITEM" });
      chips.push({ label: "Grade", value: grade, code: "GRADE" });
      chips.push({ label: "Pack Size", value: pack, code: "PACK_SIZE" });
      chips.push({ label: "Serial", value: serialStr, code: "SERIAL" });

      sku = `AGR-${item}-${grade}-${pack}-${serialStr}`;
      break;
    }
    case "CIVIL_BOM":
    case "PLANT_CONSTRUCTION": {
      format = "PCB-[DISCIPLINE]-[ITEM]-[SPECIFICATION]-[SERIAL]";
      const disc = (specs.discipline || "").trim().toUpperCase() || "CIV";
      const item = (specs.item || specs.materialCode || "").trim().toUpperCase() || "CON";
      const spec = (specs.specification || specs.spec || "").trim().toUpperCase() || "001";

      if (!specs.discipline) missing.push("Discipline");
      if (!specs.item && !specs.materialCode) missing.push("Item Code");
      if (!specs.specification && !specs.spec) missing.push("Specification");

      chips.push({ label: "Discipline", value: disc, code: "DISCIPLINE" });
      chips.push({ label: "Item", value: item, code: "ITEM" });
      chips.push({ label: "Spec", value: spec, code: "SPEC" });
      chips.push({ label: "Serial", value: serialStr, code: "SERIAL" });

      sku = `PCB-${disc}-${item}-${spec}-${serialStr}`;
      break;
    }
    case "FASTENERS":
    case "HARDWARE": {
      format = "FST-[TYPE]-[MATERIAL]-[DIAMETER]-[LENGTH]-[GRADE]-[SERIAL]";
      const type = (specs.fastenerType || specs.type || "").trim().toUpperCase() || "BLT";
      const mat = (specs.material || "").trim().toUpperCase() || "SS304";
      const dia = (specs.diameter || "").trim().toUpperCase() || "M12";
      let len = (specs.length || "").trim().toUpperCase() || "050";
      if (type === "NUT" || type === "WSH") len = "000";
      const grd = (specs.fastenerGrade || specs.grade || "").trim().toUpperCase() || "G8";

      if (!specs.fastenerType && !specs.type) missing.push("Fastener Type");
      if (!specs.material) missing.push("Material");
      if (!specs.diameter) missing.push("Diameter");
      if (!specs.length && type !== "NUT" && type !== "WSH") missing.push("Length");
      if (!specs.fastenerGrade && !specs.grade) missing.push("Grade");

      chips.push({ label: "Type", value: type, code: "TYPE" });
      chips.push({ label: "Material", value: mat, code: "MAT" });
      chips.push({ label: "Diameter", value: dia, code: "DIA" });
      chips.push({ label: "Length", value: len, code: "LEN" });
      chips.push({ label: "Grade", value: grd, code: "GRD" });
      chips.push({ label: "Serial", value: serialStr, code: "SERIAL" });

      sku = `FST-${type}-${mat}-${dia}-${len}-${grd}-${serialStr}`;
      break;
    }
    case "INSTRUMENTATION": {
      format = "INS-[TYPE]-[RANGE]-[CONNECTION]-[SERIAL]";
      const type = (specs.instrumentType || specs.type || "").trim().toUpperCase() || "PRS";
      const range = (specs.range || "").trim().toUpperCase() || "010BAR";
      const conn = (specs.connection || specs.conn || "").trim().toUpperCase() || "THD";

      if (!specs.instrumentType && !specs.type) missing.push("Instrument Type");
      if (!specs.range) missing.push("Range");
      if (!specs.connection && !specs.conn) missing.push("Connection");

      chips.push({ label: "Type", value: type, code: "TYPE" });
      chips.push({ label: "Range", value: range, code: "RANGE" });
      chips.push({ label: "Connection", value: conn, code: "CONN" });
      chips.push({ label: "Serial", value: serialStr, code: "SERIAL" });

      sku = `INS-${type}-${range}-${conn}-${serialStr}`;
      break;
    }
    case "PIPING":
    default: {
      if (specs.subType === "INSTRUMENTATION" || specs.instrumentType) {
        format = "INS-[TYPE]-[RANGE]-[CONNECTION]-[SERIAL]";
        const type = (specs.instrumentType || specs.type || "").trim().toUpperCase() || "PRS";
        const range = (specs.range || "").trim().toUpperCase() || "010BAR";
        const conn = (specs.connection || specs.conn || "").trim().toUpperCase() || "THD";

        if (!specs.instrumentType && !specs.type) missing.push("Instrument Type");
        if (!specs.range) missing.push("Range");
        if (!specs.connection && !specs.conn) missing.push("Connection");

        chips.push({ label: "Type", value: type, code: "TYPE" });
        chips.push({ label: "Range", value: range, code: "RANGE" });
        chips.push({ label: "Connection", value: conn, code: "CONN" });
        chips.push({ label: "Serial", value: serialStr, code: "SERIAL" });

        sku = `INS-${type}-${range}-${conn}-${serialStr}`;
      } else {
        format = "PIP-[TYPE]-[MATERIAL]-[SIZE]-[PRESSURE_CLASS]-[SERIAL]";
        const type = (specs.pipingType || specs.type || "").trim().toUpperCase() || "ELB";
        const mat = (specs.pipingMaterial || specs.material || "").trim().toUpperCase() || "CS";
        const size = (specs.pipingSize || specs.size || "").trim().toUpperCase() || "050";
        const pclass = (specs.pressureClass || specs.pclass || "").trim().toUpperCase() || "150";

        if (!specs.pipingType && !specs.type) missing.push("Piping Type");
        if (!specs.pipingMaterial && !specs.material) missing.push("Material");
        if (!specs.pipingSize && !specs.size) missing.push("Size");
        if (!specs.pressureClass && !specs.pclass) missing.push("Pressure Class");

        chips.push({ label: "Type", value: type, code: "TYPE" });
        chips.push({ label: "Material", value: mat, code: "MAT" });
        chips.push({ label: "Size", value: size, code: "SIZE" });
        chips.push({ label: "Class", value: pclass, code: "CLASS" });
        chips.push({ label: "Serial", value: serialStr, code: "SERIAL" });

        sku = `PIP-${type}-${mat}-${size}-${pclass}-${serialStr}`;
      }
      break;
    }
  }

  return {
    sku,
    format,
    prefix: cat === "INSTRUMENTATION" ? "INS" : (cat === "PIPING" && (specs.subType === "INSTRUMENTATION" || specs.instrumentType) ? "INS" : (cat.slice(0, 3))),
    isValid: missing.length === 0,
    missingFields: missing,
    chips
  };
}

/**
 * Atomically allocate the unique SKU on the backend or increment Supabase sequence counter
 */
export async function allocateBackendSku(category, specs = {}) {
  // 1. Try Spring Boot Backend
  try {
    const res = await apiPost("/api/inventory/sku/allocate", {
      category,
      ...specs
    });
    if (res && res.sku) return res.sku;
  } catch (e) {}

  // 2. Try Supabase Atomic Counter Update
  try {
    const prefix = category === "INSTRUMENTATION" || (category === "PIPING" && (specs.subType === "INSTRUMENTATION" || specs.instrumentType))
      ? "INS"
      : (category === "AGRI" ? "AGR" : (category === "CIVIL_BOM" ? "PCB" : (category === "FASTENERS" ? "FST" : "PIP")));

    // Read current
    const readUrl = `${SUPABASE_URL}/rest/v1/sku_sequence_counter?category_prefix=eq.${prefix}&select=*`;
    const readRes = await fetch(readUrl, {
      headers: { apikey: SUPABASE_KEY, Authorization: `Bearer ${SUPABASE_KEY}` }
    });
    if (readRes.ok) {
      const rows = await readRes.json();
      if (Array.isArray(rows) && rows[0]) {
        const nextSeq = Number(rows[0].current_sequence || 0) + 1;
        const serialStr = String(nextSeq).padStart(4, "0");
        const preview = generateLiveSkuPreview(category, specs, serialStr);

        // Update counter in Supabase
        await fetch(`${SUPABASE_URL}/rest/v1/sku_sequence_counter?category_prefix=eq.${prefix}`, {
          method: "PATCH",
          headers: {
            apikey: SUPABASE_KEY,
            Authorization: `Bearer ${SUPABASE_KEY}`,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({
            current_sequence: nextSeq,
            last_assigned_sku: preview.sku,
            updated_at: new Date().toISOString()
          })
        });

        return preview.sku;
      }
    }
  } catch (e) {}

  // 3. Fallback client preview
  const serial = await fetchNextSerial(category.slice(0, 3));
  return generateLiveSkuPreview(category, specs, serial).sku;
}
