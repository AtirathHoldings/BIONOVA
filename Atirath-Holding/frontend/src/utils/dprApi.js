// ==========================================================================
// dprApi.js - Centralized API & Local Persistence Service for DPR Module
// ==========================================================================
import { apiGet, apiPost, apiPut, apiDelete } from "./api";

const STORAGE_KEY = "bionova_dpr_records_v1";

const getLocal = (key, defaultVal = []) => {
  try {
    const raw = localStorage.getItem(key);
    return raw ? JSON.parse(raw) : defaultVal;
  } catch {
    return defaultVal;
  }
};

const setLocal = (key, data) => {
  try {
    localStorage.setItem(key, JSON.stringify(data));
  } catch (e) {
    console.warn("Unable to save DPR data locally:", e);
  }
};

const INITIAL_DPRS = [
  {
    id: "DPR-2026-1112-01",
    date: "2026-11-12",
    shift: "Day Shift (08:00 - 18:00)",
    projectName: "Kurnool 20 TPD CBG Plant",
    contractor: "Sri Sai EPC Infra Pvt Ltd",
    engineer: "R. Ramesh (Site Engineer)",
    weather: "Clear / Sunny (31°C)",
    workableDay: true,
    status: "Pending Approval",
    submittedAt: "2026-11-12 18:10",
    approvedBy: "",
    approvedAt: "",
    pmRemarks: "",
    activities: [
      {
        id: "act-1",
        taskName: "CSTR Digester #2 Ring Wall Concrete (M35)",
        uom: "m³",
        targetQty: 120,
        prevQty: 36,
        todayQty: 45
      },
      {
        id: "act-2",
        taskName: "Agitator Base Plate & Anchor Alignment",
        uom: "Nos",
        targetQty: 4,
        prevQty: 2,
        todayQty: 1
      }
    ],
    manpower: [
      { id: "mp-1", trade: "Site Engineers & QA", planned: 4, present: 4 },
      { id: "mp-2", trade: "Welders & Pipe Fitters", planned: 18, present: 16 },
      { id: "mp-3", trade: "Civil Masons & Helpers", planned: 45, present: 44 }
    ],
    equipment: [
      { id: "eq-1", name: "Hydra Crane 14T", runHrs: 7.5, idleHrs: 0.5, fuelLiters: 28 },
      { id: "eq-2", name: "Concrete Boom Pump", runHrs: 6.0, idleHrs: 2.0, fuelLiters: 42 },
      { id: "eq-3", name: "DG Set 125 kVA", runHrs: 8.0, idleHrs: 0, fuelLiters: 55 }
    ],
    materials: [
      { id: "mat-1", name: "OPC 53 Grade Cement", unit: "Bags", consumedToday: 180, closingStock: 640 },
      { id: "mat-2", name: "Fe-550D TMT Rebar (16mm)", unit: "MT", consumedToday: 2.4, closingStock: 14.1 }
    ],
    hse: {
      toolboxTalk: true,
      ppeCompliancePercent: 100,
      incidentsCount: 0,
      nearMissCount: 0,
      hindranceCategory: "None",
      lostHours: 0,
      remarks: "All work-at-height harnesses and concrete slump tests verified."
    },
    tomorrowPlan: "1. Cure Digester #2 ring wall and strip outer shuttering.\n2. Complete Biogas Flare Stack guy-wire tensioning.\n3. Inspect 20 MT HDPE piping delivery at plant gate.",
    photos: [],
    auditTrail: [
      { step: "Created", by: "R. Ramesh", at: "2026-11-12 17:45", note: "Initial site log captured" },
      { step: "Submitted", by: "R. Ramesh", at: "2026-11-12 18:10", note: "Sent to PM for quantity verification" }
    ]
  },
  {
    id: "DPR-2026-1111-02",
    date: "2026-11-11",
    shift: "Day Shift (08:00 - 18:00)",
    projectName: "Nandyal Feedstock & Silage Hub",
    contractor: "Atirath Civil Works Team",
    engineer: "K. Somanna (Field Engineer)",
    weather: "Light Evening Rain (27°C)",
    workableDay: true,
    status: "Approved",
    submittedAt: "2026-11-11 18:20",
    approvedBy: "Project Manager",
    approvedAt: "2026-11-11 20:05",
    pmRemarks: "Concrete cube test & bunker floor level verified. Approved.",
    activities: [
      {
        id: "act-3",
        taskName: "60 MT Weighbridge Pit Reinforcement",
        uom: "MT",
        targetQty: 14,
        prevQty: 8.5,
        todayQty: 3.0
      },
      {
        id: "act-4",
        taskName: "Silage Bunker #02 Floor PCC Screeding",
        uom: "m²",
        targetQty: 800,
        prevQty: 420,
        todayQty: 230
      }
    ],
    manpower: [
      { id: "mp-4", trade: "Site Supervisors", planned: 3, present: 3 },
      { id: "mp-5", trade: "Bar Benders & Masons", planned: 20, present: 19 },
      { id: "mp-6", trade: "Unskilled Helpers", planned: 18, present: 16 }
    ],
    equipment: [
      { id: "eq-4", name: "Transit Mixer TM-02", runHrs: 6.5, idleHrs: 1.5, fuelLiters: 38 },
      { id: "eq-5", name: "Plate Compactor", runHrs: 7.5, idleHrs: 0.5, fuelLiters: 12 }
    ],
    materials: [
      { id: "mat-3", name: "Fe-500 Steel Bars (12mm)", unit: "MT", consumedToday: 3.0, closingStock: 9.5 },
      { id: "mat-4", name: "20mm Crushed Aggregate", unit: "MT", consumedToday: 26, closingStock: 112 }
    ],
    hse: {
      toolboxTalk: true,
      ppeCompliancePercent: 98,
      incidentsCount: 0,
      nearMissCount: 0,
      hindranceCategory: "Weather / Rain",
      lostHours: 2.0,
      remarks: "Concreting paused 2 hours due to rain; tarpaulin covers applied."
    },
    tomorrowPlan: "1. Complete balance 150 m² bunker screeding.\n2. Begin weighbridge load-cell pedestal formwork.",
    photos: [],
    auditTrail: [
      { step: "Created", by: "K. Somanna", at: "2026-11-11 18:00", note: "Field log recorded" },
      { step: "Submitted", by: "K. Somanna", at: "2026-11-11 18:20", note: "Submitted with rain delay log" },
      { step: "Approved", by: "Project Manager", at: "2026-11-11 20:05", note: "Verified and locked" }
    ]
  },
  {
    id: "DPR-2026-1111-01",
    date: "2026-11-11",
    shift: "Night Shift (20:00 - 06:00)",
    projectName: "Kurnool 20 TPD CBG Plant",
    contractor: "Apex Piping & Gas Skids",
    engineer: "M. Venkat (Mechanical Lead)",
    weather: "Clear Night (24°C)",
    workableDay: true,
    status: "Returned",
    submittedAt: "2026-11-12 06:15",
    approvedBy: "",
    approvedAt: "",
    pmRemarks: "Please attach weld NDT / hydro-test manifold pressure reading before approval.",
    activities: [
      {
        id: "act-5",
        taskName: "H2S Scrubber SS316 Header Piping Fit-up",
        uom: "Rmt",
        targetQty: 180,
        prevQty: 84,
        todayQty: 14
      }
    ],
    manpower: [
      { id: "mp-7", trade: "TIG Welders (SS316)", planned: 8, present: 8 },
      { id: "mp-8", trade: "Pipe Fitters & Riggers", planned: 18, present: 18 }
    ],
    equipment: [
      { id: "eq-6", name: "Inverter TIG Welding Sets (4x)", runHrs: 8.5, idleHrs: 0.5, fuelLiters: 0 },
      { id: "eq-7", name: "Tower Floodlight DG", runHrs: 10.0, idleHrs: 0, fuelLiters: 30 }
    ],
    materials: [
      { id: "mat-5", name: "SS316L Seamless Pipe 4-inch", unit: "Rmt", consumedToday: 14, closingStock: 82 },
      { id: "mat-6", name: "Argon Purging Cylinders", unit: "Nos", consumedToday: 3, closingStock: 11 }
    ],
    hse: {
      toolboxTalk: true,
      ppeCompliancePercent: 100,
      incidentsCount: 0,
      nearMissCount: 1,
      hindranceCategory: "Drawing / Clarification",
      lostHours: 1.5,
      remarks: "Waiting on revised isometric flange rating drawing for Valve V-204."
    },
    tomorrowPlan: "1. Complete radiographic check on joints J12-J20.\n2. Resume V-204 spool welding once isometric Rev-3 arrives.",
    photos: [],
    auditTrail: [
      { step: "Submitted", by: "M. Venkat", at: "2026-11-12 06:15", note: "Night shift piping log" },
      { step: "Returned", by: "Project Manager", at: "2026-11-12 09:30", note: "Attach hydro-test / NDT reading" }
    ]
  },
  {
    id: "DPR-2026-1110-01",
    date: "2026-11-10",
    shift: "Day Shift (08:00 - 18:00)",
    projectName: "Guntur Biomass Bottling Expansion",
    contractor: "Atirath Mechanical Erection",
    engineer: "S. Ramakrishna (Site Lead)",
    weather: "Cloudy (29°C)",
    workableDay: true,
    status: "Draft",
    submittedAt: "",
    approvedBy: "",
    approvedAt: "",
    pmRemarks: "",
    activities: [
      {
        id: "act-6",
        taskName: "High-Pressure CBG Cascade Pad Foundation",
        uom: "m³",
        targetQty: 60,
        prevQty: 20,
        todayQty: 18
      }
    ],
    manpower: [
      { id: "mp-9", trade: "Engineers & Safety", planned: 3, present: 3 },
      { id: "mp-10", trade: "Civil & Formwork Crew", planned: 25, present: 22 }
    ],
    equipment: [
      { id: "eq-8", name: "JCB 3DX Backhoe", runHrs: 7.0, idleHrs: 1.0, fuelLiters: 36 }
    ],
    materials: [
      { id: "mat-7", name: "Ready-Mix Concrete M30", unit: "m³", consumedToday: 18, closingStock: 0 }
    ],
    hse: {
      toolboxTalk: true,
      ppeCompliancePercent: 96,
      incidentsCount: 0,
      nearMissCount: 0,
      hindranceCategory: "None",
      lostHours: 0,
      remarks: "Draft pending final batching slip verification."
    },
    tomorrowPlan: "1. Pour remaining 22 m³ cascade pad concrete.",
    photos: [],
    auditTrail: [
      { step: "Draft Saved", by: "S. Ramakrishna", at: "2026-11-10 17:15", note: "Saved as draft" }
    ]
  }
];

const DEFAULT_PROJECTS = [
  "Kurnool 20 TPD CBG Plant",
  "Nandyal Feedstock & Silage Hub",
  "Guntur Biomass Bottling Expansion",
  "Anantapur Compressed Biogas Unit"
];

export async function getDPRProjectOptions() {
  const names = new Set(DEFAULT_PROJECTS);
  try {
    const [projectsRes, plantsRes] = await Promise.all([
      apiGet("/api/projects").catch(() => []),
      apiGet("/api/plants").catch(() => [])
    ]);
    if (Array.isArray(projectsRes)) {
      projectsRes.forEach(p => {
        const label = p.prjNm || p.projectName || p.name;
        if (label) names.add(label);
      });
    }
    if (Array.isArray(plantsRes)) {
      plantsRes.forEach(pl => {
        const label = pl.pltNm || pl.plantName || pl.name;
        if (label) names.add(label);
      });
    }
  } catch {
    // fallback to defaults cleanly
  }
  return Array.from(names);
}

export async function getDPRRecords() {
  try {
    const res = await apiGet("/api/dpr");
    if (res && Array.isArray(res) && res.length > 0) {
      setLocal(STORAGE_KEY, res);
      return res;
    }
  } catch {
    // fallback to localStorage / seeded baseline
  }

  const local = getLocal(STORAGE_KEY, null);
  if (local && Array.isArray(local)) {
    return local;
  }
  setLocal(STORAGE_KEY, INITIAL_DPRS);
  return INITIAL_DPRS;
}

export async function saveDPRRecord(record, mode = "Draft", actorName = "Site Engineer") {
  const current = await getDPRRecords();
  const nowStr = new Date().toISOString().slice(0, 16).replace("T", " ");
  const nextStatus = mode === "Submit" ? "Pending Approval" : "Draft";
  const exists = current.some(r => r.id === record.id);

  const dprId =
    record.id ||
    `DPR-${(record.date || new Date().toISOString().slice(0, 10)).replace(/-/g, "")}-${String(
      current.length + 1
    ).padStart(2, "0")}`;

  const auditEntry = {
    step: mode === "Submit" ? "Submitted" : exists ? "Draft Updated" : "Created",
    by: actorName,
    at: nowStr,
    note:
      mode === "Submit"
        ? "Submitted to PM for review & approval"
        : "Saved as editable draft"
  };

  const payload = {
    ...record,
    id: dprId,
    status: nextStatus,
    submittedAt: mode === "Submit" ? nowStr : record.submittedAt || "",
    auditTrail: [...(record.auditTrail || []), auditEntry]
  };

  const updated = exists
    ? current.map(r => (r.id === dprId ? payload : r))
    : [payload, ...current];

  setLocal(STORAGE_KEY, updated);

  try {
    if (exists) await apiPut(`/api/dpr/${dprId}`, payload);
    else await apiPost("/api/dpr", payload);
  } catch {
    // localStorage fallback active
  }

  return payload;
}

export async function updateDPRApproval(dprId, decision, remarks, actorName = "Project Manager") {
  const current = await getDPRRecords();
  const nowStr = new Date().toISOString().slice(0, 16).replace("T", " ");
  const isApprove = decision === "Approved";

  let updatedItem = null;
  const updated = current.map(item => {
    if (item.id !== dprId) return item;
    updatedItem = {
      ...item,
      status: isApprove ? "Approved" : "Returned",
      approvedBy: isApprove ? actorName : "",
      approvedAt: isApprove ? nowStr : "",
      pmRemarks: remarks || item.pmRemarks || "",
      auditTrail: [
        ...(item.auditTrail || []),
        {
          step: isApprove ? "Approved & Locked" : "Returned for Correction",
          by: actorName,
          at: nowStr,
          note: remarks || (isApprove ? "Verified and locked by PM" : "Returned to engineer")
        }
      ]
    };
    return updatedItem;
  });

  setLocal(STORAGE_KEY, updated);

  try {
    await apiPut(`/api/dpr/${dprId}/${isApprove ? "approve" : "return"}`, {
      remarks,
      actorName
    });
  } catch {
    // localStorage fallback active
  }

  return updatedItem;
}

export async function deleteDPRRecord(dprId) {
  const current = await getDPRRecords();
  const updated = current.filter(item => item.id !== dprId);
  setLocal(STORAGE_KEY, updated);
  try {
    await apiDelete(`/api/dpr/${dprId}`);
  } catch {
    // localStorage fallback active
  }
  return true;
}
