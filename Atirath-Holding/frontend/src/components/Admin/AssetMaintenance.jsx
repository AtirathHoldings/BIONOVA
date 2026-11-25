import React, { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import Sidebar from "../Sidebar.jsx";
import Header from "../Header.jsx";
import {
  Wrench,
  Plus,
  Search,
  Filter,
  Download,
  Eye,
  Trash2,
  CheckCircle2,
  AlertTriangle,
  Clock,
  Building,
  DollarSign,
  Calendar,
  Layers,
  Activity,
  X,
  Save,
  ChevronRight,
  Flame,
  FileText,
  Lock,
  Cpu,
  Edit2,
  Printer
} from "lucide-react";
import "../../styles/SupplyChainOperations.css";
import { getScreenPermission } from "../../utils/permissions";
import {
  getMachineryAssets,
  saveMachineryAsset,
  deleteMachineryAsset,
  getMaintenanceSchedules,
  saveMaintenanceSchedule,
  deleteMaintenanceSchedule,
  getBreakdownIncidents,
  saveBreakdownIncident,
  deleteBreakdownIncident,
  getServicingCostLogs,
  saveServicingCostLog,
  deleteServicingCostLog
} from "../../utils/supplyChainApi";

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;

// Utility: Format any date representation strictly into DD-MM-YYYY format across all devices
export const formatToDDMMYYYY = (val) => {
  if (!val) return "";
  const str = String(val).trim();
  if (/^\d{2}-\d{2}-\d{4}$/.test(str)) return str;
  if (/^\d{4}-\d{2}-\d{2}/.test(str)) {
    const parts = str.split("T")[0].split("-");
    if (parts.length === 3) {
      return `${parts[2]}-${parts[1]}-${parts[0]}`;
    }
  }
  const d = new Date(val);
  if (!isNaN(d.getTime())) {
    const day = String(d.getDate()).padStart(2, "0");
    const month = String(d.getMonth() + 1).padStart(2, "0");
    const year = d.getFullYear();
    return `${day}-${month}-${year}`;
  }
  return str;
};

// Utility: Convert DD-MM-YYYY to YYYY-MM-DD for native HTML5 date picker sync
export const parseDDMMYYYYToISO = (val) => {
  if (!val) return "";
  const str = String(val).trim();
  if (/^\d{2}-\d{2}-\d{4}$/.test(str)) {
    const [d, m, y] = str.split("-");
    return `${y}-${m}-${d}`;
  }
  if (/^\d{4}-\d{2}-\d{2}/.test(str)) {
    return str.split("T")[0];
  }
  return str;
};

// CustomDateInput: Guaranteed DD-MM-YYYY display on every device/OS/browser
const CustomDateInput = ({ value, onChange, required, placeholder = "DD-MM-YYYY" }) => {
  const hiddenInputRef = React.useRef(null);
  const displayVal = formatToDDMMYYYY(value);
  const isoVal = parseDDMMYYYYToISO(value);

  const handlePickerChange = (e) => {
    const pickedIso = e.target.value;
    if (pickedIso) {
      onChange(formatToDDMMYYYY(pickedIso));
    }
  };

  const handleManualInput = (e) => {
    onChange(e.target.value);
  };

  const openCalendar = () => {
    if (hiddenInputRef.current) {
      try {
        if (hiddenInputRef.current.showPicker) {
          hiddenInputRef.current.showPicker();
        } else {
          hiddenInputRef.current.focus();
          hiddenInputRef.current.click();
        }
      } catch (err) {
        hiddenInputRef.current.click();
      }
    }
  };

  return (
    <div style={{ position: "relative", width: "100%", display: "flex", alignItems: "center" }}>
      <input
        type="text"
        required={required}
        value={displayVal}
        onChange={handleManualInput}
        placeholder={placeholder}
        style={{
          width: "100%",
          paddingRight: "40px",
          fontFamily: "inherit",
          fontSize: "14px"
        }}
        onClick={openCalendar}
      />
      <input
        ref={hiddenInputRef}
        type="date"
        tabIndex={-1}
        value={isoVal}
        onChange={handlePickerChange}
        style={{
          position: "absolute",
          right: "10px",
          top: "50%",
          transform: "translateY(-50%)",
          opacity: 0,
          width: "24px",
          height: "24px",
          cursor: "pointer",
          pointerEvents: "none"
        }}
      />
      <button
        type="button"
        onClick={openCalendar}
        style={{
          position: "absolute",
          right: "10px",
          top: "50%",
          transform: "translateY(-50%)",
          background: "none",
          border: "none",
          cursor: "pointer",
          padding: "4px",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          color: "#64748B"
        }}
        title="Select Date (DD-MM-YYYY)"
      >
        <Calendar size={18} />
      </button>
    </div>
  );
};

export const getCriticalityBadge = (crit) => {
  const c = crit || "";
  if (c.startsWith("A") || c.toLowerCase().includes("critical")) {
    return { label: "Critical Asset", cls: "badge-red" };
  }
  if (c.startsWith("B") || c.toLowerCase().includes("essential")) {
    return { label: "Essential Asset", cls: "badge-amber" };
  }
  if (c.startsWith("C") || c.toLowerCase().includes("standard") || c.toLowerCase().includes("auxiliary")) {
    return { label: "Standard Auxiliary", cls: "badge-blue" };
  }
  return { label: c || "Standard Auxiliary", cls: "badge-blue" };
};

const AssetMaintenance = ({ onLogout, userRole }) => {
  const screenPerm = getScreenPermission("ASSET_MAINTENANCE");
  const { tab } = useParams();
  const navigate = useNavigate();

  const [activeTab, setActiveTab] = useState(tab || "assets");
  const [plants, setPlants] = useState([]);

  // Data states
  const [assets, setAssets] = useState([]);
  const [schedules, setSchedules] = useState([]);
  const [incidents, setIncidents] = useState([]);
  const [costLogs, setCostLogs] = useState([]);

  // Filter / Search states
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("All");

  // Custom UI Dialog & Modal States
  const [assetErrors, setAssetErrors] = useState({});
  const [scheduleErrors, setScheduleErrors] = useState({});
  const [deleteConfirm, setDeleteConfirm] = useState({ isOpen: false, title: "", message: "", onConfirm: null });
  const [viewingItem, setViewingItem] = useState(null);

  // Form View States (Full Page Form)
  const [formMode, setFormMode] = useState(null); // 'create_asset' | 'create_schedule' | 'create_incident' | 'create_cost' | null
  const [editingItem, setEditingItem] = useState(null);

  // Form States
  const [assetForm, setAssetForm] = useState({
    assetCode: "",
    name: "",
    category: "Anaerobic Digester & Agitators",
    facility: "",
    oemManufacturer: "",
    modelSerial: "",
    commissionDate: formatToDDMMYYYY(new Date()),
    criticality: "Critical Asset",
    operatingStatus: "Operational"
  });

  const [scheduleForm, setScheduleForm] = useState({
    scheduleCode: "",
    assetName: "",
    facility: "",
    frequency: "",
    nextDueDate: "",
    meterThresholdHrs: 500,
    checklistItems: "",
    leadTechnician: "",
    status: "Upcoming"
  });

  const [incidentForm, setIncidentForm] = useState({
    ticketNumber: "",
    facility: "",
    assetName: "",
    reportedTime: new Date().toISOString().slice(0, 16),
    severity: "Critical (Plant Trip Risk)",
    symptomDescription: "",
    downtimeHours: 0,
    rootCause: "",
    correctiveAction: "",
    status: "Open / Under Repair"
  });

  const [costForm, setCostForm] = useState({
    logNumber: "",
    assetName: "",
    facility: "",
    serviceDate: new Date().toISOString().split("T")[0],
    serviceNature: "Preventive Routine Service",
    sparesConsumed: "Mechanical Gaskets & Synthetic Compressor Oil",
    sparesCost: 0,
    laborCost: 0,
    externalVendorFee: 0,
    servicingVendor: "Apex Industrial Engineering Services",
    invoiceRef: "",
    warrantyCovered: false
  });

  // Load Initial Data
  useEffect(() => {
    loadAllData();
    fetchPlants();
  }, []);

  useEffect(() => {
    if (tab && ["assets", "schedules", "incidents", "costs"].includes(tab)) {
      setActiveTab(tab);
      setFormMode(null);
    }
  }, [tab]);

  const fetchPlants = async () => {
    try {
      const res = await fetch(`${apiBaseUrl}/api/plants`, {
        headers: {
          "Authorization": `Bearer ${sessionStorage.getItem("authToken") || ""}`
        }
      });
      if (res.ok) {
        const data = await res.json();
        setPlants(data || []);
      }
    } catch (e) {}
  };

  const loadAllData = async () => {
    const [asts, schs, incs, costs] = await Promise.all([
      getMachineryAssets(),
      getMaintenanceSchedules(),
      getBreakdownIncidents(),
      getServicingCostLogs()
    ]);
    setAssets(asts);
    setSchedules(schs);
    setIncidents(incs);
    setCostLogs(costs);
  };

  const handleTabChange = (newTab) => {
    setActiveTab(newTab);
    setFormMode(null);
    setEditingItem(null);
    setSearchQuery("");
    setStatusFilter("All");
    navigate(`/asset-maintenance/${newTab}`);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  // --- Asset Operations ---
  const generateNextAssetTag = (assetList = assets) => {
    const currentYear = new Date().getFullYear();
    const prefix = `AST-${currentYear}-`;
    let maxSeq = 0;
    (assetList || []).forEach((a) => {
      const code = a.assetCode || a.asset_code || "";
      if (code.startsWith(prefix)) {
        const digits = code.substring(prefix.length).replace(/[^0-9]/g, "");
        if (digits) {
          const val = parseInt(digits, 10);
          if (!isNaN(val) && val > maxSeq) {
            maxSeq = val;
          }
        }
      }
    });
    return `AST-${currentYear}-${String(maxSeq + 1).padStart(4, "0")}`;
  };

  const handleOpenCreateAsset = () => {
    setAssetErrors({});
    const nextTag = generateNextAssetTag(assets);
    setAssetForm({
      assetCode: nextTag,
      name: "",
      category: "Anaerobic Digester & Agitators",
      facility: plants[0]?.pltNm || plants[0]?.plantNm || "20 TPD CBG Plant (Rangareddy)",
      oemManufacturer: "",
      modelSerial: "",
      commissionDate: formatToDDMMYYYY(new Date()),
      criticality: "Critical Asset",
      operatingStatus: "Operational"
    });
    setEditingItem(null);
    setFormMode("create_asset");
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleOpenEditAsset = (asset) => {
    setAssetErrors({});
    setEditingItem(asset);
    setAssetForm({
      assetCode: asset.assetCode || asset.asset_code || "",
      name: asset.name || "",
      category: asset.category || "Anaerobic Digester & Agitators",
      facility: asset.facility || "",
      oemManufacturer: asset.oemManufacturer || "",
      modelSerial: asset.modelSerial || "",
      commissionDate: formatToDDMMYYYY(asset.commissionDate || new Date()),
      criticality: asset.criticality || "Critical Asset",
      operatingStatus: asset.operatingStatus || "Operational"
    });
    setFormMode("create_asset");
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleSaveAsset = async (e) => {
    e.preventDefault();
    const errors = {};

    // 1. Machine / Asset Name (no numbers)
    if (!assetForm.name || !assetForm.name.trim()) {
      errors.name = "Machine / Asset Name is required";
    } else if (/[0-9]/.test(assetForm.name)) {
      errors.name = "Machine / Asset Name cannot contain numbers";
    }

    // 2. OEM Manufacturer (no numbers)
    if (assetForm.oemManufacturer && /[0-9]/.test(assetForm.oemManufacturer)) {
      errors.oemManufacturer = "OEM Manufacturer cannot contain numbers";
    }

    // 3. Model & Serial Number (mandatory)
    if (!assetForm.modelSerial || !assetForm.modelSerial.trim()) {
      errors.modelSerial = "Model & Serial Number is mandatory";
    }

    // 4. Commissioning Date
    if (!assetForm.commissionDate || !assetForm.commissionDate.trim()) {
      errors.commissionDate = "Commissioning Date is required";
    }

    if (Object.keys(errors).length > 0) {
      setAssetErrors(errors);
      window.scrollTo({ top: 0, behavior: "smooth" });
      return;
    }

    setAssetErrors({});
    const payload = {
      ...assetForm,
      id: editingItem ? editingItem.id : undefined,
      name: assetForm.name.trim(),
      oemManufacturer: (assetForm.oemManufacturer || "").trim(),
      modelSerial: assetForm.modelSerial.trim(),
      commissionDate: formatToDDMMYYYY(assetForm.commissionDate)
    };
    await saveMachineryAsset(payload);
    await loadAllData();
    setFormMode(null);
    setEditingItem(null);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  // --- Schedule Operations ---
  const generateNextScheduleCode = (scheduleList = schedules) => {
    const currentYear = new Date().getFullYear();
    const prefix = `PMS-${currentYear}-`;
    let maxSeq = 0;
    (scheduleList || []).forEach((s) => {
      const code = s.scheduleCode || s.schedule_code || "";
      if (code.startsWith(prefix)) {
        const digits = code.substring(prefix.length).replace(/[^0-9]/g, "");
        if (digits) {
          const val = parseInt(digits, 10);
          if (!isNaN(val) && val > maxSeq) {
            maxSeq = val;
          }
        }
      }
    });
    return `PMS-${currentYear}-${String(maxSeq + 1).padStart(4, "0")}`;
  };

  const handleOpenCreateSchedule = () => {
    setScheduleErrors({});
    const nextCode = generateNextScheduleCode(schedules);
    setScheduleForm({
      scheduleCode: nextCode,
      assetName: "",
      facility: plants[0]?.pltNm || plants[0]?.plantNm || "20 TPD CBG Plant (Rangareddy)",
      frequency: "",
      nextDueDate: "",
      meterThresholdHrs: 500,
      checklistItems: "",
      leadTechnician: "",
      status: "Upcoming"
    });
    setEditingItem(null);
    setFormMode("create_schedule");
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleOpenEditSchedule = (schedule) => {
    setScheduleErrors({});
    setEditingItem(schedule);
    setScheduleForm({
      scheduleCode: schedule.scheduleCode || schedule.schedule_code || "",
      assetName: schedule.assetName || "",
      facility: schedule.facility || "",
      frequency: schedule.frequency || "",
      nextDueDate: formatToDDMMYYYY(schedule.nextDueDate || ""),
      meterThresholdHrs: schedule.meterThresholdHrs || 500,
      checklistItems: schedule.checklistItems || "",
      leadTechnician: schedule.leadTechnician || "",
      status: schedule.status || "Upcoming"
    });
    setFormMode("create_schedule");
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleSaveSchedule = async (e) => {
    e.preventDefault();
    const errors = {};

    // 1. Schedule Code
    if (!scheduleForm.scheduleCode || !scheduleForm.scheduleCode.trim()) {
      errors.scheduleCode = "PM Schedule Code is required";
    }

    // 2. Select Machinery Asset
    if (!scheduleForm.assetName || !scheduleForm.assetName.trim()) {
      errors.assetName = "Please select a Machinery Asset";
    }

    // 3. Inspection Frequency
    if (!scheduleForm.frequency || !scheduleForm.frequency.trim()) {
      errors.frequency = "Please select an Inspection Frequency";
    }

    // 4. Next Scheduled Due Date
    if (!scheduleForm.nextDueDate || !scheduleForm.nextDueDate.trim()) {
      errors.nextDueDate = "Next Scheduled Due Date is required";
    }

    if (Object.keys(errors).length > 0) {
      setScheduleErrors(errors);
      window.scrollTo({ top: 0, behavior: "smooth" });
      return;
    }

    setScheduleErrors({});
    const payload = {
      ...scheduleForm,
      id: editingItem ? editingItem.id : undefined,
      nextDueDate: formatToDDMMYYYY(scheduleForm.nextDueDate)
    };
    await saveMaintenanceSchedule(payload);
    await loadAllData();
    setFormMode(null);
    setEditingItem(null);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  // --- Incident Operations ---
  const handleOpenCreateIncident = () => {
    const nextSeq = String(incidents.length + 1).padStart(4, "0");
    setIncidentForm({
      ticketNumber: `INC-2026-${nextSeq}`,
      facility: plants[0]?.pltNm || plants[0]?.plantNm || "20 TPD CBG Plant",
      assetName: assets[0]?.name || "Primary CSTR Biogas Digester Agitator #2",
      reportedTime: new Date().toISOString().slice(0, 16),
      severity: "Major (Process Bottleneck)",
      symptomDescription: "High mechanical vibration detected on agitator gear unit.",
      downtimeHours: 2.5,
      rootCause: "Bearing lubrication deterioration due to continuous heavy solids loading.",
      correctiveAction: "Flushed gearbox, installed high-temp synthetic gear oil, and re-torqued motor bolts.",
      status: "In Progress / Under Repair"
    });
    setEditingItem(null);
    setFormMode("create_incident");
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleSaveIncident = async (e) => {
    e.preventDefault();
    const payload = {
      ...incidentForm,
      id: editingItem ? editingItem.id : undefined
    };
    await saveBreakdownIncident(payload);
    await loadAllData();
    setFormMode(null);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  // --- Cost Log Operations ---
  const handleOpenCreateCost = () => {
    const nextSeq = String(costLogs.length + 1).padStart(4, "0");
    setCostForm({
      logNumber: `CST-2026-${nextSeq}`,
      assetName: assets[0]?.name || "Heavy-Duty Harvesting Biomass Tractor",
      facility: plants[0]?.pltNm || plants[0]?.plantNm || "20 TPD CBG Plant",
      serviceDate: new Date().toISOString().split("T")[0],
      serviceNature: "Emergency Breakdown Repair",
      sparesConsumed: "High-Pressure Hydraulic Hose & Coupling O-Rings",
      sparesCost: 18500,
      laborCost: 4500,
      externalVendorFee: 7000,
      servicingVendor: "Mahindra & Mahindra Authorized Heavy Farm Service Center",
      invoiceRef: "INV-MM-8849",
      warrantyCovered: false
    });
    setEditingItem(null);
    setFormMode("create_cost");
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleSaveCost = async (e) => {
    e.preventDefault();
    const totalCost = Number(costForm.sparesCost || 0) + Number(costForm.laborCost || 0) + Number(costForm.externalVendorFee || 0);
    const payload = {
      ...costForm,
      id: editingItem ? editingItem.id : undefined,
      totalCost
    };
    await saveServicingCostLog(payload);
    await loadAllData();
    setFormMode(null);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  // Export to CSV
  const exportToCSV = (data, filename) => {
    if (!data.length) return;
    const headers = Object.keys(data[0]).filter(k => typeof data[0][k] !== "object").join(",");
    const rows = data.map(obj =>
      Object.keys(obj)
        .filter(k => typeof obj[k] !== "object")
        .map(k => `"${String(obj[k] || "").replace(/"/g, '""')}"`)
        .join(",")
    );
    const csvContent = "data:text/csv;charset=utf-8," + [headers, ...rows].join("\n");
    const link = document.createElement("a");
    link.href = encodeURI(csvContent);
    link.download = `${filename}_${Date.now()}.csv`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  // KPI Computations
  const totalAssetsCount = assets.length;
  const activeBreakdownsCount = incidents.filter(i => i.status !== "Closed" && i.status !== "Resolved").length;
  const upcomingPmCount = schedules.filter(s => s.status === "Upcoming" || s.status === "Due").length;
  const totalMaintenanceCost = costLogs.reduce((acc, c) => acc + Number(c.totalCost || 0), 0);

  if (!screenPerm.canView) {
    return (
      <div className="sco-container">
        <Sidebar onLogout={onLogout} />
        <div className="sco-main" style={{ display: "flex", flexDirection: "column", minHeight: "100vh" }}>
          <Header title="Equipment & Asset Maintenance (CMMS)" onLogout={onLogout} />
          <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "40px", textAlign: "center" }}>
            <div style={{ width: "80px", height: "80px", borderRadius: "50%", background: "#fee2e2", display: "flex", alignItems: "center", justifyContent: "center", marginBottom: "20px" }}>
              <Lock size={36} color="#dc2626" />
            </div>
            <h2 style={{ fontSize: "22px", fontWeight: "700", color: "#1e293b", marginBottom: "8px" }}>Access Restricted</h2>
            <p style={{ fontSize: "14px", color: "#64748b", maxWidth: "420px", margin: "0 auto" }}>
              You do not have view permissions for the Equipment & Asset Maintenance module. Please contact your administrator.
            </p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="sco-container">
      <Sidebar onLogout={onLogout} />
      <div className="sco-main">
        <Header title="Equipment & Asset Maintenance (CMMS)" onLogout={onLogout} />

        <div className="sco-content">
          {/* Header Row: Tagline on Left, Buttons on Right Edge */}
          <div className="sco-header-row">
            <p className="sco-tagline">
              Track physical infrastructure across facilities created in PlantMaster, enforce preventive maintenance schedules, log emergency breakdown incidents, and monitor servicing cost ledgers.
            </p>
            <div className="d-flex align-items-center gap-2" style={{ flexShrink: 0, marginLeft: "auto" }}>
              {activeTab === "assets" && (
                <button onClick={handleOpenCreateAsset} className="sco-btn-primary">
                  <Plus size={16} /> Register Machinery Asset
                </button>
              )}
              {activeTab === "schedules" && (
                <button onClick={handleOpenCreateSchedule} className="sco-btn-primary">
                  <Plus size={16} /> New PM Schedule
                </button>
              )}
              {activeTab === "incidents" && (
                <button onClick={handleOpenCreateIncident} className="sco-btn-primary" style={{ background: "#dc2626" }}>
                  <Flame size={16} /> Log Breakdown Incident
                </button>
              )}
              {activeTab === "costs" && (
                <button onClick={handleOpenCreateCost} className="sco-btn-primary">
                  <Plus size={16} /> Record Servicing Cost
                </button>
              )}
            </div>
          </div>

          {/* KPI Summary Cards */}
          <div className="sco-kpi-grid">
            <div className="sco-kpi-card">
              <div className="sco-kpi-icon" style={{ backgroundColor: "#eff6ff", color: "#2563eb" }}>
                <Cpu size={24} />
              </div>
              <div className="sco-kpi-info">
                <span className="sco-kpi-val">{totalAssetsCount}</span>
                <span className="sco-kpi-label">Machinery Assets Registered</span>
              </div>
            </div>

            <div className="sco-kpi-card">
              <div className="sco-kpi-icon" style={{ backgroundColor: "#fee2e2", color: "#dc2626" }}>
                <AlertTriangle size={24} />
              </div>
              <div className="sco-kpi-info">
                <span className="sco-kpi-val">{activeBreakdownsCount}</span>
                <span className="sco-kpi-label">Active Breakdown Incidents</span>
              </div>
            </div>

            <div className="sco-kpi-card">
              <div className="sco-kpi-icon" style={{ backgroundColor: "#fef3c7", color: "#d97706" }}>
                <Clock size={24} />
              </div>
              <div className="sco-kpi-info">
                <span className="sco-kpi-val">{upcomingPmCount}</span>
                <span className="sco-kpi-label">Scheduled PMs Due</span>
              </div>
            </div>

            <div className="sco-kpi-card">
              <div className="sco-kpi-icon" style={{ backgroundColor: "#f0fdf4", color: "#16a34a" }}>
                <DollarSign size={24} />
              </div>
              <div className="sco-kpi-info">
                <span className="sco-kpi-val">₹{totalMaintenanceCost.toLocaleString("en-IN")}</span>
                <span className="sco-kpi-label">Cumulative Servicing Cost</span>
              </div>
            </div>
          </div>

          {/* Submodule Navigation Tabs */}
          <div className="sco-tabs-nav">
            <button
              className={`sco-tab-btn ${activeTab === "assets" ? "active" : ""}`}
              onClick={() => handleTabChange("assets")}
            >
              <Cpu size={16} /> Machinery & Assets Registry
              <span className="badge-count">{assets.length}</span>
            </button>

            <button
              className={`sco-tab-btn ${activeTab === "schedules" ? "active" : ""}`}
              onClick={() => handleTabChange("schedules")}
            >
              <Clock size={16} /> Preventive Maintenance (PM)
              <span className="badge-count">{schedules.length}</span>
            </button>

            <button
              className={`sco-tab-btn ${activeTab === "incidents" ? "active" : ""}`}
              onClick={() => handleTabChange("incidents")}
            >
              <AlertTriangle size={16} /> Breakdown Incidents
              <span className="badge-count">{incidents.length}</span>
            </button>

            <button
              className={`sco-tab-btn ${activeTab === "costs" ? "active" : ""}`}
              onClick={() => handleTabChange("costs")}
            >
              <DollarSign size={16} /> Servicing Cost & Spares Log
              <span className="badge-count">{costLogs.length}</span>
            </button>
          </div>

          {/* ────────────────────────────────────────────────────────────── */}
          {/* FULL PAGE FORM: REGISTER / EDIT MACHINERY ASSET                 */}
          {/* ────────────────────────────────────────────────────────────── */}
          {formMode === "create_asset" && (
            <div className="sco-form-card">
              <div className="sco-form-title">
                <span>{editingItem ? "Edit Plant Machinery & Infrastructure" : "Register Plant Machinery & Physical Infrastructure"}</span>
                <button onClick={() => { setFormMode(null); setEditingItem(null); setAssetErrors({}); }} className="sco-btn-icon"><X size={18} /></button>
              </div>

              {Object.keys(assetErrors).length > 0 && (
                <div style={{
                  background: "#fef2f2",
                  border: "1px solid #fca5a5",
                  borderRadius: "8px",
                  padding: "12px 16px",
                  marginBottom: "16px",
                  display: "flex",
                  alignItems: "flex-start",
                  gap: "10px",
                  color: "#991b1b",
                  fontSize: "13.5px"
                }}>
                  <AlertTriangle size={18} style={{ color: "#dc2626", marginTop: "2px", flexShrink: 0 }} />
                  <div>
                    <span style={{ fontWeight: "700" }}>Please review and fix the following errors:</span>
                    <ul style={{ margin: "6px 0 0 16px", padding: 0 }}>
                      {Object.entries(assetErrors).map(([field, msg]) => (
                        <li key={field}>{msg}</li>
                      ))}
                    </ul>
                  </div>
                </div>
              )}

              <form onSubmit={handleSaveAsset}>
                <div className="sco-form-grid">
                  <div className="sco-form-group">
                    <label>Asset Identification Tag <span className="required">*</span></label>
                    <input
                      type="text"
                      readOnly
                      value={assetForm.assetCode}
                      style={{ backgroundColor: "#f8fafc", cursor: "not-allowed", color: "#334155", fontWeight: "600" }}
                      title="Auto-generated sequential Asset Identification Tag"
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Machine / Asset Name <span className="required">*</span></label>
                    <input
                      type="text"
                      required
                      value={assetForm.name}
                      onChange={(e) => {
                        const cleaned = e.target.value.replace(/[0-9]/g, "");
                        setAssetForm({ ...assetForm, name: cleaned });
                        if (assetErrors.name) setAssetErrors({ ...assetErrors, name: null });
                      }}
                      placeholder="e.g. Primary Bio-Gas CSTR Digester Agitator"
                      style={assetErrors.name ? { borderColor: "#dc2626" } : {}}
                    />
                    {assetErrors.name && (
                      <span style={{ color: "#dc2626", fontSize: "11.5px", marginTop: "3px", display: "block" }}>
                        {assetErrors.name}
                      </span>
                    )}
                  </div>

                  <div className="sco-form-group">
                    <label>Asset Category <span className="required">*</span></label>
                    <select
                      value={assetForm.category}
                      onChange={(e) => setAssetForm({ ...assetForm, category: e.target.value })}
                    >
                      <option value="Harvesting Tractors & Farm Machinery">Harvesting Tractors & Farm Machinery</option>
                      <option value="Anaerobic Digester & Agitators">Anaerobic Digester & Agitators</option>
                      <option value="Gas Upgradation & Compressors">Gas Upgradation & Compressors</option>
                      <option value="Cold Storages & Chilling Plants">Cold Storages & Chilling Plants</option>
                      <option value="Power Generators & Cogeneration">Power Generators & Cogeneration</option>
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>Plant Facility (From PlantMaster) <span className="required">*</span></label>
                    <select
                      required
                      value={assetForm.facility}
                      onChange={(e) => setAssetForm({ ...assetForm, facility: e.target.value })}
                    >
                      <option value="">-- Choose Plant / Facility --</option>
                      {plants.map(p => {
                        const name = p.pltNm || p.plantNm || p.name;
                        const id = p.pltId || p.plantId || p.id;
                        return (
                          <option key={id} value={name} style={{ color: "#0f172a", backgroundColor: "#ffffff" }}>
                            {name} ({p.dist || p.location || "On-Site"})
                          </option>
                        );
                      })}
                      {!plants.length && (
                        <>
                          <option value="20 TPD CBG Plant (Rangareddy)" style={{ color: "#0f172a", backgroundColor: "#ffffff" }}>20 TPD CBG Plant (Rangareddy)</option>
                          <option value="Atirath Holdings (Mumbai)" style={{ color: "#0f172a", backgroundColor: "#ffffff" }}>Atirath Holdings (Mumbai)</option>
                          <option value="Atirath CBG (Banglore)" style={{ color: "#0f172a", backgroundColor: "#ffffff" }}>Atirath CBG (Banglore)</option>
                          <option value="Sivaram Industries (Rangareddy)" style={{ color: "#0f172a", backgroundColor: "#ffffff" }}>Sivaram Industries (Rangareddy)</option>
                          <option value="Main Processing Plant - Unit 1 (Rangareddy)" style={{ color: "#0f172a", backgroundColor: "#ffffff" }}>Main Processing Plant - Unit 1 (Rangareddy)</option>
                        </>
                      )}
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>OEM Manufacturer</label>
                    <input
                      type="text"
                      value={assetForm.oemManufacturer}
                      onChange={(e) => {
                        const cleaned = e.target.value.replace(/[0-9]/g, "");
                        setAssetForm({ ...assetForm, oemManufacturer: cleaned });
                        if (assetErrors.oemManufacturer) setAssetErrors({ ...assetErrors, oemManufacturer: null });
                      }}
                      placeholder="e.g. Linde / Neuman & Esser"
                      style={assetErrors.oemManufacturer ? { borderColor: "#dc2626" } : {}}
                    />
                    {assetErrors.oemManufacturer && (
                      <span style={{ color: "#dc2626", fontSize: "11.5px", marginTop: "3px", display: "block" }}>
                        {assetErrors.oemManufacturer}
                      </span>
                    )}
                  </div>

                  <div className="sco-form-group">
                    <label>Model & Serial Number <span className="required">*</span></label>
                    <input
                      type="text"
                      required
                      value={assetForm.modelSerial}
                      onChange={(e) => {
                        setAssetForm({ ...assetForm, modelSerial: e.target.value });
                        if (assetErrors.modelSerial) setAssetErrors({ ...assetErrors, modelSerial: null });
                      }}
                      placeholder="e.g. NEA-CBG-450"
                      style={assetErrors.modelSerial ? { borderColor: "#dc2626" } : {}}
                    />
                    {assetErrors.modelSerial && (
                      <span style={{ color: "#dc2626", fontSize: "11.5px", marginTop: "3px", display: "block" }}>
                        {assetErrors.modelSerial}
                      </span>
                    )}
                  </div>

                  <div className="sco-form-group">
                    <label>Commissioning Date <span className="required">*</span></label>
                    <CustomDateInput
                      value={assetForm.commissionDate}
                      onChange={(val) => {
                        setAssetForm({ ...assetForm, commissionDate: val });
                        if (assetErrors.commissionDate) setAssetErrors({ ...assetErrors, commissionDate: null });
                      }}
                      required
                    />
                    {assetErrors.commissionDate && (
                      <span style={{ color: "#dc2626", fontSize: "11.5px", marginTop: "3px", display: "block" }}>
                        {assetErrors.commissionDate}
                      </span>
                    )}
                  </div>

                  <div className="sco-form-group">
                    <label>Operational Criticality</label>
                    <select
                      value={
                        assetForm.criticality?.startsWith("A") || assetForm.criticality?.toLowerCase().includes("critical") ? "Critical Asset" :
                        assetForm.criticality?.startsWith("B") || assetForm.criticality?.toLowerCase().includes("essential") ? "Essential Asset" :
                        assetForm.criticality?.startsWith("C") || assetForm.criticality?.toLowerCase().includes("standard") || assetForm.criticality?.toLowerCase().includes("auxiliary") ? "Standard Auxiliary" :
                        assetForm.criticality || "Critical Asset"
                      }
                      onChange={(e) => setAssetForm({ ...assetForm, criticality: e.target.value })}
                    >
                      <option value="Critical Asset">Critical Asset (Downtime Shuts Facility)</option>
                      <option value="Essential Asset">Essential Asset (Process Degraded)</option>
                      <option value="Standard Auxiliary">Standard Auxiliary Equipment</option>
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>Current Status</label>
                    <select
                      value={assetForm.operatingStatus}
                      onChange={(e) => setAssetForm({ ...assetForm, operatingStatus: e.target.value })}
                    >
                      <option value="Operational">Operational</option>
                      <option value="Maintenance Due">Maintenance Due</option>
                      <option value="Under Breakdown">Under Breakdown</option>
                      <option value="Decommissioned">Decommissioned</option>
                    </select>
                  </div>
                </div>

                <div className="sco-form-actions">
                  <button type="button" onClick={() => { setFormMode(null); setEditingItem(null); setAssetErrors({}); }} className="sco-btn-secondary">
                    Cancel
                  </button>
                  <button type="submit" className="sco-btn-primary">
                    <Save size={16} /> {editingItem ? "Update Machinery Record" : "Save Machinery Record"}
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* FULL PAGE FORM: CREATE / EDIT PREVENTIVE MAINTENANCE SCHEDULE   */}
          {/* ────────────────────────────────────────────────────────────── */}
          {formMode === "create_schedule" && (
            <div className="sco-form-card">
              <div className="sco-form-title">
                <span>{editingItem ? "Edit Preventive Maintenance (PM) Schedule" : "Configure Preventive Maintenance (PM) Schedule"}</span>
                <button onClick={() => { setFormMode(null); setEditingItem(null); setScheduleErrors({}); }} className="sco-btn-icon"><X size={18} /></button>
              </div>

              {Object.keys(scheduleErrors).length > 0 && (
                <div style={{
                  background: "#fef2f2",
                  border: "1px solid #fca5a5",
                  borderRadius: "8px",
                  padding: "12px 16px",
                  marginBottom: "16px",
                  display: "flex",
                  alignItems: "flex-start",
                  gap: "10px",
                  color: "#991b1b",
                  fontSize: "13.5px"
                }}>
                  <AlertTriangle size={18} style={{ color: "#dc2626", marginTop: "2px", flexShrink: 0 }} />
                  <div>
                    <span style={{ fontWeight: "700" }}>Please review and fix the following errors:</span>
                    <ul style={{ margin: "6px 0 0 16px", padding: 0 }}>
                      {Object.entries(scheduleErrors).map(([field, msg]) => (
                        <li key={field}>{msg}</li>
                      ))}
                    </ul>
                  </div>
                </div>
              )}

              <form onSubmit={handleSaveSchedule}>
                <div className="sco-form-grid">
                  <div className="sco-form-group">
                    <label>PM Schedule Code <span className="required">*</span></label>
                    <input
                      type="text"
                      readOnly
                      value={scheduleForm.scheduleCode}
                      style={{ backgroundColor: "#f8fafc", cursor: "not-allowed", color: "#334155", fontWeight: "600" }}
                      title="Auto-generated sequential PM Schedule Code"
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Select Machinery Asset <span className="required">*</span></label>
                    <select
                      required
                      value={scheduleForm.assetName}
                      onChange={(e) => {
                        setScheduleForm({ ...scheduleForm, assetName: e.target.value });
                        if (scheduleErrors.assetName) setScheduleErrors({ ...scheduleErrors, assetName: null });
                      }}
                      style={scheduleErrors.assetName ? { borderColor: "#dc2626" } : {}}
                    >
                      <option value="">-- Choose Machinery Asset --</option>
                      {assets.map(a => <option key={a.id} value={a.name}>{a.name} ({a.assetCode})</option>)}
                    </select>
                    {scheduleErrors.assetName && (
                      <span style={{ color: "#dc2626", fontSize: "11.5px", marginTop: "3px", display: "block" }}>
                        {scheduleErrors.assetName}
                      </span>
                    )}
                  </div>

                  <div className="sco-form-group">
                    <label>Inspection Frequency <span className="required">*</span></label>
                    <select
                      required
                      value={scheduleForm.frequency}
                      onChange={(e) => {
                        setScheduleForm({ ...scheduleForm, frequency: e.target.value });
                        if (scheduleErrors.frequency) setScheduleErrors({ ...scheduleErrors, frequency: null });
                      }}
                      style={scheduleErrors.frequency ? { borderColor: "#dc2626" } : {}}
                    >
                      <option value="">-- Choose Inspection Frequency --</option>
                      <option value="Daily Inspection">Daily Operator Inspection</option>
                      <option value="Weekly Lubrication">Weekly Lubrication & Seals</option>
                      <option value="Monthly Overhaul & Calibration">Monthly Overhaul & Calibration</option>
                      <option value="Running Meter: 500 Hrs">Running Meter: 500 Hours</option>
                      <option value="Running Meter: 2000 Hrs">Running Meter: 2,000 Hours Major AMC</option>
                    </select>
                    {scheduleErrors.frequency && (
                      <span style={{ color: "#dc2626", fontSize: "11.5px", marginTop: "3px", display: "block" }}>
                        {scheduleErrors.frequency}
                      </span>
                    )}
                  </div>

                  <div className="sco-form-group">
                    <label>Next Scheduled Due Date <span className="required">*</span></label>
                    <CustomDateInput
                      value={scheduleForm.nextDueDate}
                      onChange={(val) => {
                        setScheduleForm({ ...scheduleForm, nextDueDate: val });
                        if (scheduleErrors.nextDueDate) setScheduleErrors({ ...scheduleErrors, nextDueDate: null });
                      }}
                      required
                    />
                    {scheduleErrors.nextDueDate && (
                      <span style={{ color: "#dc2626", fontSize: "11.5px", marginTop: "3px", display: "block" }}>
                        {scheduleErrors.nextDueDate}
                      </span>
                    )}
                  </div>

                  <div className="sco-form-group">
                    <label>Lead Technician / Engineer</label>
                    <input
                      type="text"
                      value={scheduleForm.leadTechnician}
                      onChange={(e) => setScheduleForm({ ...scheduleForm, leadTechnician: e.target.value })}
                      placeholder="e.g. Suresh Reddy (Lead Reliability Engineer)"
                    />
                  </div>

                  <div className="sco-form-group col-span-full">
                    <label>Mandatory Checklist Steps (SOP)</label>
                    <textarea
                      rows="3"
                      value={scheduleForm.checklistItems}
                      onChange={(e) => setScheduleForm({ ...scheduleForm, checklistItems: e.target.value })}
                      placeholder="1. Inspect oil seals & lubricant levels&#10;2. Calibrate pressure transducer transmitters&#10;3. Check gas sensor alarms & valves"
                    ></textarea>
                  </div>
                </div>

                <div className="sco-form-actions">
                  <button type="button" onClick={() => { setFormMode(null); setEditingItem(null); setScheduleErrors({}); }} className="sco-btn-secondary">
                    Cancel
                  </button>
                  <button type="submit" className="sco-btn-primary">
                    <Save size={16} /> {editingItem ? "Update PM Schedule" : "Save PM Schedule"}
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* FULL PAGE FORM: LOG BREAKDOWN INCIDENT                         */}
          {/* ────────────────────────────────────────────────────────────── */}
          {formMode === "create_incident" && (
            <div className="sco-form-card" style={{ borderColor: "#fca5a5" }}>
              <div className="sco-form-title" style={{ color: "#dc2626" }}>
                <span>Log Unscheduled Breakdown Incident</span>
                <button onClick={() => setFormMode(null)} className="sco-btn-icon"><X size={18} /></button>
              </div>

              <form onSubmit={handleSaveIncident}>
                <div className="sco-form-grid">
                  <div className="sco-form-group">
                    <label>Incident Ticket # <span className="required">*</span></label>
                    <input
                      type="text"
                      required
                      value={incidentForm.ticketNumber}
                      onChange={(e) => setIncidentForm({ ...incidentForm, ticketNumber: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Affected Machinery Asset <span className="required">*</span></label>
                    <select
                      required
                      value={incidentForm.assetName}
                      onChange={(e) => setIncidentForm({ ...incidentForm, assetName: e.target.value })}
                    >
                      {assets.map(a => <option key={a.id} value={a.name}>{a.name}</option>)}
                      {!assets.length && <option value="Primary CSTR Biogas Digester Agitator #2">Primary CSTR Biogas Digester Agitator #2</option>}
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>Incident Timestamp</label>
                    <input
                      type="datetime-local"
                      value={incidentForm.reportedTime}
                      onChange={(e) => setIncidentForm({ ...incidentForm, reportedTime: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Severity Level <span className="required">*</span></label>
                    <select
                      value={incidentForm.severity}
                      onChange={(e) => setIncidentForm({ ...incidentForm, severity: e.target.value })}
                    >
                      <option value="Critical (Plant Trip Risk)">Critical (Plant Trip Risk)</option>
                      <option value="Major (Process Bottleneck)">Major (Process Bottleneck)</option>
                      <option value="Minor (Auxiliary Fault)">Minor (Auxiliary Fault)</option>
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>Downtime Logged (Hours)</label>
                    <input
                      type="number"
                      step="0.5"
                      min="0"
                      value={incidentForm.downtimeHours}
                      onChange={(e) => setIncidentForm({ ...incidentForm, downtimeHours: parseFloat(e.target.value) || 0 })}
                    />
                  </div>

                  <div className="sco-form-group col-span-full">
                    <label>Failure Symptom & Breakdown Details</label>
                    <textarea
                      rows="2"
                      required
                      value={incidentForm.symptomDescription}
                      onChange={(e) => setIncidentForm({ ...incidentForm, symptomDescription: e.target.value })}
                      placeholder="Describe what occurred, warning alarms triggered, and visual observations..."
                    ></textarea>
                  </div>

                  <div className="sco-form-group col-span-full">
                    <label>Root Cause Analysis (RCA) & Corrective Action Taken</label>
                    <textarea
                      rows="2"
                      value={incidentForm.correctiveAction}
                      onChange={(e) => setIncidentForm({ ...incidentForm, correctiveAction: e.target.value })}
                      placeholder="State identified failure mechanism and replacement parts fitted..."
                    ></textarea>
                  </div>
                </div>

                <div className="sco-form-actions">
                  <button type="button" onClick={() => setFormMode(null)} className="sco-btn-secondary">
                    Cancel
                  </button>
                  <button type="submit" className="sco-btn-primary" style={{ background: "#dc2626" }}>
                    <Save size={16} /> Log Incident & Notify Team
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* FULL PAGE FORM: RECORD SERVICING COST LOG                      */}
          {/* ────────────────────────────────────────────────────────────── */}
          {formMode === "create_cost" && (
            <div className="sco-form-card">
              <div className="sco-form-title">
                <span>Record Servicing Cost & Consumed Spares</span>
                <button onClick={() => setFormMode(null)} className="sco-btn-icon"><X size={18} /></button>
              </div>

              <form onSubmit={handleSaveCost}>
                <div className="sco-form-grid">
                  <div className="sco-form-group">
                    <label>Service Log # <span className="required">*</span></label>
                    <input
                      type="text"
                      required
                      value={costForm.logNumber}
                      onChange={(e) => setCostForm({ ...costForm, logNumber: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Serviced Machinery Asset <span className="required">*</span></label>
                    <select
                      required
                      value={costForm.assetName}
                      onChange={(e) => setCostForm({ ...costForm, assetName: e.target.value })}
                    >
                      {assets.map(a => <option key={a.id} value={a.name}>{a.name}</option>)}
                      {!assets.length && <option value="Heavy-Duty Harvesting Biomass Tractor">Heavy-Duty Harvesting Biomass Tractor</option>}
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>Nature of Service</label>
                    <select
                      value={costForm.serviceNature}
                      onChange={(e) => setCostForm({ ...costForm, serviceNature: e.target.value })}
                    >
                      <option value="Preventive Routine Service">Preventive Routine Service</option>
                      <option value="Emergency Breakdown Repair">Emergency Breakdown Repair</option>
                      <option value="Annual Overhaul AMC">Annual Overhaul AMC</option>
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>Service Date</label>
                    <input
                      type="date"
                      value={costForm.serviceDate}
                      onChange={(e) => setCostForm({ ...costForm, serviceDate: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Spares Consumed Cost (₹)</label>
                    <input
                      type="number"
                      min="0"
                      value={costForm.sparesCost}
                      onChange={(e) => setCostForm({ ...costForm, sparesCost: parseFloat(e.target.value) || 0 })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Internal Labor Charges (₹)</label>
                    <input
                      type="number"
                      min="0"
                      value={costForm.laborCost}
                      onChange={(e) => setCostForm({ ...costForm, laborCost: parseFloat(e.target.value) || 0 })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>External Vendor Charges (₹)</label>
                    <input
                      type="number"
                      min="0"
                      value={costForm.externalVendorFee}
                      onChange={(e) => setCostForm({ ...costForm, externalVendorFee: parseFloat(e.target.value) || 0 })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>External Service Provider / Agency</label>
                    <input
                      type="text"
                      value={costForm.servicingVendor}
                      onChange={(e) => setCostForm({ ...costForm, servicingVendor: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group col-span-full">
                    <label>Spare Parts Description</label>
                    <input
                      type="text"
                      value={costForm.sparesConsumed}
                      onChange={(e) => setCostForm({ ...costForm, sparesConsumed: e.target.value })}
                      placeholder="e.g. Mechanical seals, high-pressure synthetic lubricant, air filters"
                    />
                  </div>
                </div>

                <div className="sco-form-actions">
                  <button type="button" onClick={() => setFormMode(null)} className="sco-btn-secondary">
                    Cancel
                  </button>
                  <button type="submit" className="sco-btn-primary">
                    <Save size={16} /> Save Cost Ledger Entry
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* TAB 1: MACHINERY ASSETS TABLE                                  */}
          {/* ────────────────────────────────────────────────────────────── */}
          {activeTab === "assets" && !formMode && (
            <div className="sco-card">
              <div className="sco-card-header">
                <h3 className="sco-card-title">
                  <Cpu size={18} className="text-blue-600" />
                  Facility Machinery & Plant Infrastructure Directory
                </h3>
                <div className="d-flex align-items-center gap-2">
                  <button onClick={() => exportToCSV(assets, "Plant_Machinery_Assets")} className="sco-btn-secondary">
                    <Download size={14} /> Export CSV
                  </button>
                </div>
              </div>

              <div className="sco-card-body">
                {assets.length === 0 ? (
                  <div className="sco-empty-state">
                    <div className="icon"><Cpu size={40} /></div>
                    <h3>No Machinery Registered Yet</h3>
                    <p>Track plant tractors, bio-digesters, and cold storages by registering your first asset.</p>
                    <button onClick={handleOpenCreateAsset} className="sco-btn-primary">
                      <Plus size={16} /> Register First Asset
                    </button>
                  </div>
                ) : (
                  <div className="sco-table-wrapper">
                    <table className="sco-table">
                      <thead>
                        <tr>
                          <th>Asset Tag</th>
                          <th>Equipment Name</th>
                          <th>Category</th>
                          <th>Plant Facility</th>
                          <th>OEM / Serial</th>
                          <th>Criticality</th>
                          <th>Status</th>
                          <th style={{ textAlign: "right" }}>Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {assets.map((a) => (
                          <tr key={a.id}>
                            <td style={{ fontWeight: "700" }}>{a.assetCode}</td>
                            <td>{a.name}</td>
                            <td>{a.category}</td>
                            <td>{a.facility}</td>
                            <td>{a.oemManufacturer || "—"} ({a.modelSerial || "—"})</td>
                            <td>
                              {(() => {
                                const badge = getCriticalityBadge(a.criticality);
                                return <span className={`sco-badge ${badge.cls}`}>{badge.label}</span>;
                              })()}
                            </td>
                            <td>
                              <span className={`sco-badge ${a.operatingStatus === "Operational" ? "badge-green" : "badge-red"}`}>
                                {a.operatingStatus || "—"}
                              </span>
                            </td>
                            <td style={{ textAlign: "right" }}>
                              <div style={{ display: "inline-flex", alignItems: "center", gap: "6px" }}>
                                <button
                                  onClick={() => setViewingItem({ type: "asset", data: a })}
                                  className="sco-btn-icon"
                                  title="View Asset Details"
                                >
                                  <Eye size={15} />
                                </button>
                                <button
                                  onClick={() => handleOpenEditAsset(a)}
                                  className="sco-btn-icon"
                                  title="Edit Machinery Details"
                                >
                                  <Edit2 size={15} />
                                </button>
                                <button
                                  onClick={() =>
                                    setDeleteConfirm({
                                      isOpen: true,
                                      title: "Delete Machinery Asset",
                                      message: `Are you sure you want to delete "${a.name}" (${a.assetCode})? This action cannot be undone.`,
                                      onConfirm: async () => {
                                        await deleteMachineryAsset(a.id);
                                        await loadAllData();
                                      }
                                    })
                                  }
                                  className="sco-btn-icon danger"
                                  title="Delete Asset"
                                >
                                  <Trash2 size={15} />
                                </button>
                              </div>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* TAB 2: PREVENTIVE MAINTENANCE SCHEDULES TABLE                  */}
          {/* ────────────────────────────────────────────────────────────── */}
          {activeTab === "schedules" && !formMode && (
            <div className="sco-card">
              <div className="sco-card-header">
                <h3 className="sco-card-title">
                  <Clock size={18} className="text-amber-600" />
                  Preventive Maintenance (PM) Inspection Schedules
                </h3>
                <div className="d-flex align-items-center gap-2">
                  <button onClick={() => exportToCSV(schedules, "PM_Schedules")} className="sco-btn-secondary">
                    <Download size={14} /> Export CSV
                  </button>
                </div>
              </div>

              <div className="sco-card-body">
                {schedules.length === 0 ? (
                  <div className="sco-empty-state">
                    <div className="icon"><Clock size={40} /></div>
                    <h3>No PM Schedules Configured</h3>
                    <p>Establish automated routine servicing intervals to prevent costly un-planned outages.</p>
                    <button onClick={handleOpenCreateSchedule} className="sco-btn-primary">
                      <Plus size={16} /> Create Schedule
                    </button>
                  </div>
                ) : (
                  <div className="sco-table-wrapper">
                    <table className="sco-table">
                      <thead>
                        <tr>
                          <th>Schedule Code</th>
                          <th>Machinery Asset</th>
                          <th>Inspection Frequency</th>
                          <th>Next Scheduled Due Date</th>
                          <th>Lead Engineer</th>
                          <th>Status</th>
                          <th style={{ textAlign: "right" }}>Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {schedules.map((s) => (
                          <tr key={s.id}>
                            <td style={{ fontWeight: "700" }}>{s.scheduleCode}</td>
                            <td>{s.assetName}</td>
                            <td>{s.frequency}</td>
                            <td>{formatToDDMMYYYY(s.nextDueDate)}</td>
                            <td>{s.leadTechnician || "—"}</td>
                            <td><span className="sco-badge badge-blue">{s.status || "Upcoming"}</span></td>
                            <td style={{ textAlign: "right" }}>
                              <div style={{ display: "inline-flex", alignItems: "center", gap: "6px" }}>
                                <button
                                  onClick={() => setViewingItem({ type: "schedule", data: s })}
                                  className="sco-btn-icon"
                                  title="View Schedule Details"
                                >
                                  <Eye size={15} />
                                </button>
                                <button
                                  onClick={() => handleOpenEditSchedule(s)}
                                  className="sco-btn-icon"
                                  title="Edit PM Schedule"
                                >
                                  <Edit2 size={15} />
                                </button>
                                <button
                                  onClick={() =>
                                    setDeleteConfirm({
                                      isOpen: true,
                                      title: "Delete PM Schedule",
                                      message: `Are you sure you want to delete PM schedule "${s.scheduleCode}" for ${s.assetName}? This action cannot be undone.`,
                                      onConfirm: async () => {
                                        await deleteMaintenanceSchedule(s.id);
                                        await loadAllData();
                                      }
                                    })
                                  }
                                  className="sco-btn-icon danger"
                                  title="Delete Schedule"
                                >
                                  <Trash2 size={15} />
                                </button>
                              </div>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* TAB 3: BREAKDOWN INCIDENTS TABLE                               */}
          {/* ────────────────────────────────────────────────────────────── */}
          {activeTab === "incidents" && !formMode && (
            <div className="sco-card">
              <div className="sco-card-header">
                <h3 className="sco-card-title">
                  <AlertTriangle size={18} className="text-red-600" />
                  Breakdown Incident Log & Downtime Tracking
                </h3>
                <div className="d-flex align-items-center gap-2">
                  <button onClick={() => exportToCSV(incidents, "Breakdown_Incidents")} className="sco-btn-secondary">
                    <Download size={14} /> Export CSV
                  </button>
                </div>
              </div>

              <div className="sco-card-body">
                {incidents.length === 0 ? (
                  <div className="sco-empty-state">
                    <div className="icon"><AlertTriangle size={40} /></div>
                    <h3>No Breakdowns Reported</h3>
                    <p>All machinery is currently operating within acceptable parameters without downtime incidents.</p>
                    <button onClick={handleOpenCreateIncident} className="sco-btn-primary" style={{ background: "#dc2626" }}>
                      <Flame size={16} /> Log Incident
                    </button>
                  </div>
                ) : (
                  <div className="sco-table-wrapper">
                    <table className="sco-table">
                      <thead>
                        <tr>
                          <th>Ticket #</th>
                          <th>Asset Name</th>
                          <th>Severity</th>
                          <th>Reported Date</th>
                          <th>Downtime (Hrs)</th>
                          <th>Symptom Summary</th>
                          <th>Status</th>
                          <th style={{ textAlign: "right" }}>Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {incidents.map((i) => (
                          <tr key={i.id}>
                            <td style={{ fontWeight: "700" }}>{i.ticketNumber}</td>
                            <td>{i.assetName}</td>
                            <td>
                              <span className={`sco-badge ${(i.severity || "").startsWith("Critical") ? "badge-red" : "badge-amber"}`}>
                                {(i.severity || "—").split(" ")[0]}
                              </span>
                            </td>
                            <td>{i.reportedTime?.replace("T", " ")}</td>
                            <td style={{ fontWeight: "700", color: "#dc2626" }}>{i.downtimeHours}h</td>
                            <td>{i.symptomDescription?.slice(0, 45)}...</td>
                            <td><span className="sco-badge badge-amber">{i.status}</span></td>
                            <td style={{ textAlign: "right" }}>
                              <button
                                onClick={() =>
                                  setDeleteConfirm({
                                    isOpen: true,
                                    title: "Delete Incident Log",
                                    message: `Are you sure you want to delete incident ticket "${i.ticketNumber}"? This action cannot be undone.`,
                                    onConfirm: async () => {
                                      await deleteBreakdownIncident(i.id);
                                      await loadAllData();
                                    }
                                  })
                                }
                                className="sco-btn-icon danger"
                                title="Delete Incident Log"
                              >
                                <Trash2 size={15} />
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* TAB 4: SERVICING COST LEDGER TABLE                             */}
          {/* ────────────────────────────────────────────────────────────── */}
          {activeTab === "costs" && !formMode && (
            <div className="sco-card">
              <div className="sco-card-header">
                <h3 className="sco-card-title">
                  <DollarSign size={18} className="text-emerald-600" />
                  Machinery Servicing Costs & Consumed Spare Parts Ledger
                </h3>
                <div className="d-flex align-items-center gap-2">
                  <button onClick={() => exportToCSV(costLogs, "Servicing_Costs")} className="sco-btn-secondary">
                    <Download size={14} /> Export CSV
                  </button>
                </div>
              </div>

              <div className="sco-card-body">
                {costLogs.length === 0 ? (
                  <div className="sco-empty-state">
                    <div className="icon"><DollarSign size={40} /></div>
                    <h3>No Cost Entries Found</h3>
                    <p>Track cumulative repair expenses, spare part usage, and technician service fees.</p>
                    <button onClick={handleOpenCreateCost} className="sco-btn-primary">
                      <Plus size={16} /> Record Servicing Cost
                    </button>
                  </div>
                ) : (
                  <div className="sco-table-wrapper">
                    <table className="sco-table">
                      <thead>
                        <tr>
                          <th>Log #</th>
                          <th>Asset Serviced</th>
                          <th>Service Nature</th>
                          <th>Service Date</th>
                          <th>Spares (₹)</th>
                          <th>Labor (₹)</th>
                          <th>Total Cost (₹)</th>
                          <th>Service Vendor</th>
                          <th style={{ textAlign: "right" }}>Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {costLogs.map((c) => (
                          <tr key={c.id}>
                            <td style={{ fontWeight: "700" }}>{c.logNumber}</td>
                            <td>{c.assetName}</td>
                            <td>{c.serviceNature}</td>
                            <td>{c.serviceDate}</td>
                            <td>₹{Number(c.sparesCost || 0).toLocaleString("en-IN")}</td>
                            <td>₹{Number(c.laborCost || 0).toLocaleString("en-IN")}</td>
                            <td style={{ fontWeight: "700", color: "#0f172a" }}>
                              ₹{Number(c.totalCost || 0).toLocaleString("en-IN")}
                            </td>
                            <td>{c.servicingVendor || "In-House Team"}</td>
                            <td style={{ textAlign: "right" }}>
                              <button
                                onClick={() =>
                                  setDeleteConfirm({
                                    isOpen: true,
                                    title: "Delete Servicing Cost Log",
                                    message: `Are you sure you want to delete cost ledger log "${c.logNumber}"? This action cannot be undone.`,
                                    onConfirm: async () => {
                                      await deleteServicingCostLog(c.id);
                                      await loadAllData();
                                    }
                                  })
                                }
                                className="sco-btn-icon danger"
                                title="Delete Cost Log"
                              >
                                <Trash2 size={15} />
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            </div>
          )}
          {/* ────────────────────────────────────────────────────────────── */}
          {/* VIEW ASSET DETAILS MODAL                                        */}
          {/* ────────────────────────────────────────────────────────────── */}
          {viewingItem && viewingItem.type === "asset" && (
            <div
              className="sco-modal-overlay"
              style={{
                position: "fixed",
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                backgroundColor: "rgba(15, 23, 42, 0.6)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                zIndex: 1050,
                padding: "20px"
              }}
            >
              <div
                className="sco-modal-card"
                style={{
                  background: "#ffffff",
                  borderRadius: "14px",
                  width: "100%",
                  maxWidth: "680px",
                  maxHeight: "90vh",
                  overflowY: "auto",
                  padding: "28px",
                  boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.25)"
                }}
              >
                <div
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    borderBottom: "2px solid #e2e8f0",
                    paddingBottom: "16px",
                    marginBottom: "20px"
                  }}
                >
                  <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                    <div
                      style={{
                        width: "44px",
                        height: "44px",
                        borderRadius: "10px",
                        background: "#eff6ff",
                        color: "#2563eb",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center"
                      }}
                    >
                      <Cpu size={22} />
                    </div>
                    <div>
                      <h2 style={{ fontSize: "20px", fontWeight: "800", color: "#0f172a", margin: 0 }}>
                        {viewingItem.data.assetCode}
                      </h2>
                      <p style={{ fontSize: "13px", color: "#64748b", margin: "2px 0 0 0" }}>
                        Plant Machinery & Physical Infrastructure Profile
                      </p>
                    </div>
                  </div>
                  <button onClick={() => setViewingItem(null)} className="sco-btn-icon">
                    <X size={20} />
                  </button>
                </div>

                <div
                  style={{
                    display: "grid",
                    gridTemplateColumns: "1fr 1fr",
                    gap: "14px",
                    marginBottom: "20px"
                  }}
                >
                  <div style={{ background: "#f8fafc", padding: "12px 14px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                    <p style={{ fontSize: "12px", color: "#64748b", margin: "0 0 4px 0", fontWeight: "600", textTransform: "uppercase" }}>Machine / Asset Name</p>
                    <p style={{ fontSize: "14px", fontWeight: "700", color: "#0f172a", margin: 0 }}>{viewingItem.data.name || "—"}</p>
                  </div>

                  <div style={{ background: "#f8fafc", padding: "12px 14px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                    <p style={{ fontSize: "12px", color: "#64748b", margin: "0 0 4px 0", fontWeight: "600", textTransform: "uppercase" }}>Asset Category</p>
                    <p style={{ fontSize: "13.5px", fontWeight: "600", color: "#0f172a", margin: 0 }}>{viewingItem.data.category || "—"}</p>
                  </div>

                  <div style={{ background: "#f8fafc", padding: "12px 14px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                    <p style={{ fontSize: "12px", color: "#64748b", margin: "0 0 4px 0", fontWeight: "600", textTransform: "uppercase" }}>Plant Facility</p>
                    <p style={{ fontSize: "13.5px", fontWeight: "600", color: "#0f172a", margin: 0 }}>{viewingItem.data.facility || "—"}</p>
                  </div>

                  <div style={{ background: "#f8fafc", padding: "12px 14px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                    <p style={{ fontSize: "12px", color: "#64748b", margin: "0 0 4px 0", fontWeight: "600", textTransform: "uppercase" }}>OEM Manufacturer</p>
                    <p style={{ fontSize: "13.5px", fontWeight: "600", color: "#0f172a", margin: 0 }}>{viewingItem.data.oemManufacturer || "—"}</p>
                  </div>

                  <div style={{ background: "#f8fafc", padding: "12px 14px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                    <p style={{ fontSize: "12px", color: "#64748b", margin: "0 0 4px 0", fontWeight: "600", textTransform: "uppercase" }}>Model & Serial Number</p>
                    <p style={{ fontSize: "13.5px", fontWeight: "600", color: "#0f172a", margin: 0 }}>{viewingItem.data.modelSerial || "—"}</p>
                  </div>

                  <div style={{ background: "#f8fafc", padding: "12px 14px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                    <p style={{ fontSize: "12px", color: "#64748b", margin: "0 0 4px 0", fontWeight: "600", textTransform: "uppercase" }}>Commissioning Date</p>
                    <p style={{ fontSize: "13.5px", fontWeight: "700", color: "#2563eb", margin: 0 }}>{formatToDDMMYYYY(viewingItem.data.commissionDate)}</p>
                  </div>

                  <div style={{ background: "#f8fafc", padding: "12px 14px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                    <p style={{ fontSize: "12px", color: "#64748b", margin: "0 0 4px 0", fontWeight: "600", textTransform: "uppercase" }}>Operational Criticality</p>
                    <p style={{ margin: 0 }}>
                      {(() => {
                        const badge = getCriticalityBadge(viewingItem.data.criticality);
                        return <span className={`sco-badge ${badge.cls}`}>{badge.label}</span>;
                      })()}
                    </p>
                  </div>

                  <div style={{ background: "#f8fafc", padding: "12px 14px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                    <p style={{ fontSize: "12px", color: "#64748b", margin: "0 0 4px 0", fontWeight: "600", textTransform: "uppercase" }}>Operating Status</p>
                    <p style={{ margin: 0 }}>
                      <span className={`sco-badge ${viewingItem.data.operatingStatus === "Operational" ? "badge-green" : "badge-red"}`}>
                        {viewingItem.data.operatingStatus || "—"}
                      </span>
                    </p>
                  </div>
                </div>

                <div style={{ display: "flex", justifyContent: "flex-end", gap: "10px" }}>
                  <button onClick={() => window.print()} className="sco-btn-secondary">
                    <Printer size={16} /> Print Record
                  </button>
                  <button onClick={() => setViewingItem(null)} className="sco-btn-primary">
                    Close
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* VIEW PM SCHEDULE DETAILS MODAL                                  */}
          {/* ────────────────────────────────────────────────────────────── */}
          {viewingItem && viewingItem.type === "schedule" && (
            <div
              className="sco-modal-overlay"
              style={{
                position: "fixed",
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                backgroundColor: "rgba(15, 23, 42, 0.6)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                zIndex: 1050,
                padding: "20px"
              }}
            >
              <div
                className="sco-modal-card"
                style={{
                  background: "#ffffff",
                  borderRadius: "14px",
                  width: "100%",
                  maxWidth: "680px",
                  maxHeight: "90vh",
                  overflowY: "auto",
                  padding: "28px",
                  boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.25)"
                }}
              >
                <div
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    borderBottom: "2px solid #e2e8f0",
                    paddingBottom: "16px",
                    marginBottom: "20px"
                  }}
                >
                  <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                    <div
                      style={{
                        width: "44px",
                        height: "44px",
                        borderRadius: "10px",
                        background: "#fef3c7",
                        color: "#d97706",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center"
                      }}
                    >
                      <Clock size={22} />
                    </div>
                    <div>
                      <h2 style={{ fontSize: "20px", fontWeight: "800", color: "#0f172a", margin: 0 }}>
                        {viewingItem.data.scheduleCode}
                      </h2>
                      <p style={{ fontSize: "13px", color: "#64748b", margin: "2px 0 0 0" }}>
                        Preventive Maintenance (PM) Inspection Schedule
                      </p>
                    </div>
                  </div>
                  <button onClick={() => setViewingItem(null)} className="sco-btn-icon">
                    <X size={20} />
                  </button>
                </div>

                <div
                  style={{
                    display: "grid",
                    gridTemplateColumns: "1fr 1fr",
                    gap: "14px",
                    marginBottom: "20px"
                  }}
                >
                  <div style={{ background: "#f8fafc", padding: "12px 14px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                    <p style={{ fontSize: "12px", color: "#64748b", margin: "0 0 4px 0", fontWeight: "600", textTransform: "uppercase" }}>Machinery Asset</p>
                    <p style={{ fontSize: "14px", fontWeight: "700", color: "#0f172a", margin: 0 }}>{viewingItem.data.assetName || "—"}</p>
                  </div>

                  <div style={{ background: "#f8fafc", padding: "12px 14px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                    <p style={{ fontSize: "12px", color: "#64748b", margin: "0 0 4px 0", fontWeight: "600", textTransform: "uppercase" }}>Inspection Frequency</p>
                    <p style={{ fontSize: "13.5px", fontWeight: "600", color: "#0f172a", margin: 0 }}>{viewingItem.data.frequency || "—"}</p>
                  </div>

                  <div style={{ background: "#f8fafc", padding: "12px 14px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                    <p style={{ fontSize: "12px", color: "#64748b", margin: "0 0 4px 0", fontWeight: "600", textTransform: "uppercase" }}>Next Scheduled Due Date</p>
                    <p style={{ fontSize: "13.5px", fontWeight: "700", color: "#2563eb", margin: 0 }}>{formatToDDMMYYYY(viewingItem.data.nextDueDate)}</p>
                  </div>

                  <div style={{ background: "#f8fafc", padding: "12px 14px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                    <p style={{ fontSize: "12px", color: "#64748b", margin: "0 0 4px 0", fontWeight: "600", textTransform: "uppercase" }}>Lead Engineer / Technician</p>
                    <p style={{ fontSize: "13.5px", fontWeight: "600", color: "#0f172a", margin: 0 }}>{viewingItem.data.leadTechnician || "—"}</p>
                  </div>

                  <div style={{ background: "#f8fafc", padding: "12px 14px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                    <p style={{ fontSize: "12px", color: "#64748b", margin: "0 0 4px 0", fontWeight: "600", textTransform: "uppercase" }}>Operating Status</p>
                    <p style={{ margin: 0 }}>
                      <span className="sco-badge badge-blue">{viewingItem.data.status || "Upcoming"}</span>
                    </p>
                  </div>

                  <div style={{ background: "#f8fafc", padding: "12px 14px", borderRadius: "8px", border: "1px solid #e2e8f0" }}>
                    <p style={{ fontSize: "12px", color: "#64748b", margin: "0 0 4px 0", fontWeight: "600", textTransform: "uppercase" }}>Running Meter Threshold</p>
                    <p style={{ fontSize: "13.5px", fontWeight: "600", color: "#0f172a", margin: 0 }}>{viewingItem.data.meterThresholdHrs || 500} Hours</p>
                  </div>

                  <div style={{ background: "#f8fafc", padding: "12px 14px", borderRadius: "8px", border: "1px solid #e2e8f0", gridColumn: "span 2" }}>
                    <p style={{ fontSize: "12px", color: "#64748b", margin: "0 0 4px 0", fontWeight: "600", textTransform: "uppercase" }}>Mandatory Checklist Steps (SOP)</p>
                    <pre style={{ fontSize: "13px", color: "#334155", margin: 0, whiteSpace: "pre-wrap", fontFamily: "inherit", lineHeight: "1.6" }}>
                      {viewingItem.data.checklistItems || "No checklist SOP recorded."}
                    </pre>
                  </div>
                </div>

                <div style={{ display: "flex", justifyContent: "flex-end", gap: "10px" }}>
                  <button onClick={() => window.print()} className="sco-btn-secondary">
                    <Printer size={16} /> Print Schedule
                  </button>
                  <button onClick={() => setViewingItem(null)} className="sco-btn-primary">
                    Close
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* CUSTOM WEB CONFIRMATION MODAL (NO BROWSER POPUPS)             */}
          {/* ────────────────────────────────────────────────────────────── */}
          {deleteConfirm.isOpen && (
            <div
              className="sco-modal-overlay"
              style={{
                position: "fixed",
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                backgroundColor: "rgba(15, 23, 42, 0.6)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                zIndex: 1100,
                padding: "20px"
              }}
            >
              <div
                className="sco-modal-card"
                style={{
                  background: "#ffffff",
                  borderRadius: "14px",
                  width: "100%",
                  maxWidth: "440px",
                  padding: "26px",
                  boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.25)",
                  textAlign: "center"
                }}
              >
                <div
                  style={{
                    width: "52px",
                    height: "52px",
                    borderRadius: "50%",
                    background: "#fee2e2",
                    color: "#dc2626",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    margin: "0 auto 16px auto"
                  }}
                >
                  <Trash2 size={26} />
                </div>

                <h3 style={{ fontSize: "18px", fontWeight: "800", color: "#0f172a", marginBottom: "8px" }}>
                  {deleteConfirm.title || "Confirm Deletion"}
                </h3>
                <p style={{ fontSize: "14px", color: "#64748b", margin: "0 0 24px 0", lineHeight: "1.5" }}>
                  {deleteConfirm.message}
                </p>

                <div style={{ display: "flex", gap: "12px", justifyContent: "center" }}>
                  <button
                    type="button"
                    onClick={() => setDeleteConfirm({ isOpen: false, title: "", message: "", onConfirm: null })}
                    className="sco-btn-secondary"
                    style={{ minWidth: "110px" }}
                  >
                    Cancel
                  </button>
                  <button
                    type="button"
                    onClick={async () => {
                      if (deleteConfirm.onConfirm) {
                        await deleteConfirm.onConfirm();
                      }
                      setDeleteConfirm({ isOpen: false, title: "", message: "", onConfirm: null });
                    }}
                    className="sco-btn-primary"
                    style={{ background: "#dc2626", borderColor: "#dc2626", minWidth: "110px" }}
                  >
                    Delete
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default AssetMaintenance;

