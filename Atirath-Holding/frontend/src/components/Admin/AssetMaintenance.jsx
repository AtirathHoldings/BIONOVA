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
  Cpu
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
    commissionDate: new Date().toISOString().split("T")[0],
    criticality: "A - Critical Asset",
    operatingStatus: "Operational"
  });

  const [scheduleForm, setScheduleForm] = useState({
    scheduleCode: "",
    assetName: "",
    facility: "",
    frequency: "Monthly Overhaul & Calibration",
    nextDueDate: "",
    meterThresholdHrs: 500,
    checklistItems: "1. Inspect oil seals & lubricant levels\n2. Calibrate pressure transducer transmitters\n3. Check gas sensor alarms & valves",
    leadTechnician: "Chief Mechanical Engineer",
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
  const handleOpenCreateAsset = () => {
    const nextSeq = String(assets.length + 1).padStart(4, "0");
    setAssetForm({
      assetCode: `AST-2026-${nextSeq}`,
      name: "",
      category: "Anaerobic Digester & Agitators",
      facility: plants[0]?.plantNm || "Plant 1 - Hyderabad East CBG",
      oemManufacturer: "Linde / Neuman & Esser",
      modelSerial: "NEA-CBG-450",
      commissionDate: new Date().toISOString().split("T")[0],
      criticality: "A - Critical Asset",
      operatingStatus: "Operational"
    });
    setEditingItem(null);
    setFormMode("create_asset");
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleSaveAsset = async (e) => {
    e.preventDefault();
    const payload = {
      ...assetForm,
      id: editingItem ? editingItem.id : undefined
    };
    await saveMachineryAsset(payload);
    await loadAllData();
    setFormMode(null);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  // --- Schedule Operations ---
  const handleOpenCreateSchedule = () => {
    const nextSeq = String(schedules.length + 1).padStart(4, "0");
    setScheduleForm({
      scheduleCode: `PMS-2026-${nextSeq}`,
      assetName: assets[0]?.name || "High-Pressure CBG Compressor Train 1",
      facility: plants[0]?.plantNm || "Plant 1 - Hyderabad East CBG",
      frequency: "Monthly Overhaul & Calibration",
      nextDueDate: new Date(Date.now() + 10 * 86400000).toISOString().split("T")[0],
      meterThresholdHrs: 500,
      checklistItems: "1. Inspect oil seals & lubricant levels\n2. Calibrate pressure transducer transmitters\n3. Check gas sensor alarms & valves",
      leadTechnician: "Suresh Reddy (Lead Reliability Engineer)",
      status: "Upcoming"
    });
    setEditingItem(null);
    setFormMode("create_schedule");
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleSaveSchedule = async (e) => {
    e.preventDefault();
    const payload = {
      ...scheduleForm,
      id: editingItem ? editingItem.id : undefined
    };
    await saveMaintenanceSchedule(payload);
    await loadAllData();
    setFormMode(null);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  // --- Incident Operations ---
  const handleOpenCreateIncident = () => {
    const nextSeq = String(incidents.length + 1).padStart(4, "0");
    setIncidentForm({
      ticketNumber: `INC-2026-${nextSeq}`,
      facility: plants[0]?.plantNm || "Plant 1 - Hyderabad East CBG",
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
      facility: plants[0]?.plantNm || "Plant 1 - Hyderabad East CBG",
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
          {/* FULL PAGE FORM: REGISTER MACHINERY ASSET                       */}
          {/* ────────────────────────────────────────────────────────────── */}
          {formMode === "create_asset" && (
            <div className="sco-form-card">
              <div className="sco-form-title">
                <span>Register Plant Machinery & Physical Infrastructure</span>
                <button onClick={() => setFormMode(null)} className="sco-btn-icon"><X size={18} /></button>
              </div>

              <form onSubmit={handleSaveAsset}>
                <div className="sco-form-grid">
                  <div className="sco-form-group">
                    <label>Asset Identification Tag <span className="required">*</span></label>
                    <input
                      type="text"
                      required
                      value={assetForm.assetCode}
                      onChange={(e) => setAssetForm({ ...assetForm, assetCode: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Machine / Asset Name <span className="required">*</span></label>
                    <input
                      type="text"
                      required
                      value={assetForm.name}
                      onChange={(e) => setAssetForm({ ...assetForm, name: e.target.value })}
                      placeholder="e.g. Primary Bio-Gas CSTR Digester Agitator 1"
                    />
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
                      {plants.map(p => <option key={p.plantId} value={p.plantNm}>{p.plantNm} ({p.location || "On-Site"})</option>)}
                      {!plants.length && <option value="Plant 1 - Hyderabad East CBG">Plant 1 - Hyderabad East CBG</option>}
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>OEM Manufacturer</label>
                    <input
                      type="text"
                      value={assetForm.oemManufacturer}
                      onChange={(e) => setAssetForm({ ...assetForm, oemManufacturer: e.target.value })}
                      placeholder="e.g. John Deere / Neuman & Esser"
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Model & Serial Number</label>
                    <input
                      type="text"
                      value={assetForm.modelSerial}
                      onChange={(e) => setAssetForm({ ...assetForm, modelSerial: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Commissioning Date</label>
                    <input
                      type="date"
                      value={assetForm.commissionDate}
                      onChange={(e) => setAssetForm({ ...assetForm, commissionDate: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Operational Criticality</label>
                    <select
                      value={assetForm.criticality}
                      onChange={(e) => setAssetForm({ ...assetForm, criticality: e.target.value })}
                    >
                      <option value="A - Critical Asset">A - Critical Asset (Downtime Shuts Facility)</option>
                      <option value="B - Essential Asset">B - Essential Asset (Process Degraded)</option>
                      <option value="C - Standard Asset">C - Standard Auxiliary Equipment</option>
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
                  <button type="button" onClick={() => setFormMode(null)} className="sco-btn-secondary">
                    Cancel
                  </button>
                  <button type="submit" className="sco-btn-primary">
                    <Save size={16} /> Save Machinery Record
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* ────────────────────────────────────────────────────────────── */}
          {/* FULL PAGE FORM: CREATE PREVENTIVE MAINTENANCE SCHEDULE         */}
          {/* ────────────────────────────────────────────────────────────── */}
          {formMode === "create_schedule" && (
            <div className="sco-form-card">
              <div className="sco-form-title">
                <span>Configure Preventive Maintenance (PM) Schedule</span>
                <button onClick={() => setFormMode(null)} className="sco-btn-icon"><X size={18} /></button>
              </div>

              <form onSubmit={handleSaveSchedule}>
                <div className="sco-form-grid">
                  <div className="sco-form-group">
                    <label>PM Schedule Code <span className="required">*</span></label>
                    <input
                      type="text"
                      required
                      value={scheduleForm.scheduleCode}
                      onChange={(e) => setScheduleForm({ ...scheduleForm, scheduleCode: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Select Machinery Asset <span className="required">*</span></label>
                    <select
                      required
                      value={scheduleForm.assetName}
                      onChange={(e) => setScheduleForm({ ...scheduleForm, assetName: e.target.value })}
                    >
                      {assets.map(a => <option key={a.id} value={a.name}>{a.name} ({a.assetCode})</option>)}
                      {!assets.length && <option value="High-Pressure CBG Compressor Train 1">High-Pressure CBG Compressor Train 1</option>}
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>Inspection Frequency <span className="required">*</span></label>
                    <select
                      value={scheduleForm.frequency}
                      onChange={(e) => setScheduleForm({ ...scheduleForm, frequency: e.target.value })}
                    >
                      <option value="Daily Inspection">Daily Operator Inspection</option>
                      <option value="Weekly Lubrication">Weekly Lubrication & Seals</option>
                      <option value="Monthly Overhaul & Calibration">Monthly Overhaul & Calibration</option>
                      <option value="Running Meter: 500 Hrs">Running Meter: 500 Hours</option>
                      <option value="Running Meter: 2000 Hrs">Running Meter: 2,000 Hours Major AMC</option>
                    </select>
                  </div>

                  <div className="sco-form-group">
                    <label>Next Scheduled Due Date <span className="required">*</span></label>
                    <input
                      type="date"
                      required
                      value={scheduleForm.nextDueDate}
                      onChange={(e) => setScheduleForm({ ...scheduleForm, nextDueDate: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group">
                    <label>Lead Technician / Engineer</label>
                    <input
                      type="text"
                      value={scheduleForm.leadTechnician}
                      onChange={(e) => setScheduleForm({ ...scheduleForm, leadTechnician: e.target.value })}
                    />
                  </div>

                  <div className="sco-form-group col-span-full">
                    <label>Mandatory Checklist Steps (SOP)</label>
                    <textarea
                      rows="3"
                      value={scheduleForm.checklistItems}
                      onChange={(e) => setScheduleForm({ ...scheduleForm, checklistItems: e.target.value })}
                    ></textarea>
                  </div>
                </div>

                <div className="sco-form-actions">
                  <button type="button" onClick={() => setFormMode(null)} className="sco-btn-secondary">
                    Cancel
                  </button>
                  <button type="submit" className="sco-btn-primary">
                    <Save size={16} /> Save PM Schedule
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
                            <td>{a.oemManufacturer} ({a.modelSerial})</td>
                            <td>
                              <span className={`sco-badge ${a.criticality.startsWith("A") ? "badge-red" : "badge-amber"}`}>
                                {a.criticality.split(" ")[0]}
                              </span>
                            </td>
                            <td>
                              <span className={`sco-badge ${a.operatingStatus === "Operational" ? "badge-green" : "badge-red"}`}>
                                {a.operatingStatus}
                              </span>
                            </td>
                            <td style={{ textAlign: "right" }}>
                              <button
                                onClick={async () => {
                                  if (window.confirm(`Delete ${a.name}?`)) {
                                    await deleteMachineryAsset(a.id);
                                    await loadAllData();
                                  }
                                }}
                                className="sco-btn-icon danger"
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
                          <th>Target Asset</th>
                          <th>Frequency</th>
                          <th>Next Due Date</th>
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
                            <td>{s.nextDueDate}</td>
                            <td>{s.leadTechnician}</td>
                            <td><span className="sco-badge badge-blue">{s.status}</span></td>
                            <td style={{ textAlign: "right" }}>
                              <button
                                onClick={async () => {
                                  if (window.confirm(`Delete ${s.scheduleCode}?`)) {
                                    await deleteMaintenanceSchedule(s.id);
                                    await loadAllData();
                                  }
                                }}
                                className="sco-btn-icon danger"
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
                              <span className={`sco-badge ${i.severity.startsWith("Critical") ? "badge-red" : "badge-amber"}`}>
                                {i.severity.split(" ")[0]}
                              </span>
                            </td>
                            <td>{i.reportedTime?.replace("T", " ")}</td>
                            <td style={{ fontWeight: "700", color: "#dc2626" }}>{i.downtimeHours}h</td>
                            <td>{i.symptomDescription?.slice(0, 45)}...</td>
                            <td><span className="sco-badge badge-amber">{i.status}</span></td>
                            <td style={{ textAlign: "right" }}>
                              <button
                                onClick={async () => {
                                  if (window.confirm(`Delete ${i.ticketNumber}?`)) {
                                    await deleteBreakdownIncident(i.id);
                                    await loadAllData();
                                  }
                                }}
                                className="sco-btn-icon danger"
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
                                onClick={async () => {
                                  if (window.confirm(`Delete ${c.logNumber}?`)) {
                                    await deleteServicingCostLog(c.id);
                                    await loadAllData();
                                  }
                                }}
                                className="sco-btn-icon danger"
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
        </div>
      </div>
    </div>
  );
};

export default AssetMaintenance;

