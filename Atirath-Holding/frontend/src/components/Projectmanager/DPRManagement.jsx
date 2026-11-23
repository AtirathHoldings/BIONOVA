import { useState, useEffect, useMemo } from "react";
import { useParams, useNavigate } from "react-router-dom";
import {
  ClipboardList,
  Plus,
  Download,
  Search,
  CheckCircle2,
  Clock,
  Users,
  AlertTriangle,
  Eye,
  Edit3,
  Trash2,
  ArrowLeft,
  Send,
  ShieldCheck,
  Wrench,
  Package,
  Camera,
  BookOpen,
  Printer,
  RotateCcw,
  Lock
} from "lucide-react";
import Sidebar from "../Sidebar.jsx";
import Header from "../Header.jsx";
import AlertModal from "../AlertModal.jsx";
import { exportToCSV } from "../../utils/exportUtils";
import { getScreenPermission } from "../../utils/permissions";
import {
  getDPRProjectOptions,
  getDPRRecords,
  saveDPRRecord,
  updateDPRApproval,
  deleteDPRRecord
} from "../../utils/dprApi";
import "../../styles/SupplyChainOperations.css";
import "../../styles/dpr.css";

const getLoggedInActor = () => {
  const stored = sessionStorage.getItem("userName") || localStorage.getItem("userName");
  if (stored) return stored;
  const email = sessionStorage.getItem("userEmail") || localStorage.getItem("userEmail") || "";
  if (email.includes("@")) return email.split("@")[0];
  return "Site Engineer";
};

const calcPercent = (prevQty, todayQty, targetQty) => {
  const target = Number(targetQty) || 0;
  if (target <= 0) return 0;
  const total = (Number(prevQty) || 0) + (Number(todayQty) || 0);
  return Math.min(100, Math.round((total / target) * 1000) / 10);
};

const calcDPROverallProgress = (activities = []) => {
  if (!activities.length) return 0;
  const sum = activities.reduce(
    (acc, a) => acc + calcPercent(a.prevQty, a.todayQty, a.targetQty),
    0
  );
  return Math.round((sum / activities.length) * 10) / 10;
};

const sumManpowerPresent = (manpower = []) =>
  manpower.reduce((acc, m) => acc + (Number(m.present) || 0), 0);

const sumMachineHours = (equipment = []) =>
  equipment.reduce((acc, eq) => acc + (Number(eq.runHrs) || 0), 0);

const getStatusBadgeClass = (status) => {
  switch (status) {
    case "Approved":
      return "dpr-badge-approved";
    case "Pending Approval":
      return "dpr-badge-pending";
    case "Returned":
      return "dpr-badge-returned";
    default:
      return "dpr-badge-draft";
  }
};

const createEmptyDPR = (defaultProject, actorName) => ({
  id: "",
  date: new Date().toISOString().slice(0, 10),
  shift: "Day Shift (08:00 - 18:00)",
  projectName: defaultProject || "Kurnool 20 TPD CBG Plant",
  contractor: "",
  engineer: actorName,
  weather: "Clear / Sunny (30°C)",
  workableDay: true,
  status: "Draft",
  activities: [
    { id: `act-${Date.now()}`, taskName: "", uom: "m³", targetQty: 100, prevQty: 0, todayQty: 0 }
  ],
  manpower: [
    { id: `mp-${Date.now()}-1`, trade: "Site Engineers & QA", planned: 2, present: 2 },
    { id: `mp-${Date.now()}-2`, trade: "Skilled Technicians / Masons", planned: 15, present: 15 }
  ],
  equipment: [
    { id: `eq-${Date.now()}-1`, name: "Excavator / Crane", runHrs: 8, idleHrs: 0, fuelLiters: 30 }
  ],
  materials: [
    { id: `mat-${Date.now()}-1`, name: "OPC 53 Cement", unit: "Bags", consumedToday: 0, closingStock: 0 }
  ],
  hse: {
    toolboxTalk: true,
    ppeCompliancePercent: 100,
    incidentsCount: 0,
    nearMissCount: 0,
    hindranceCategory: "None",
    lostHours: 0,
    remarks: ""
  },
  tomorrowPlan: "",
  photos: [],
  auditTrail: []
});

export default function DPRManagement({ userRole, onLogout }) {
  const { id: routeId } = useParams();
  const navigate = useNavigate();
  const actorName = getLoggedInActor();
  const rawPerm = getScreenPermission("DPR_MANAGEMENT");
  const isAdminOrPM = ["admin", "super_admin", "full_access", "project_manager", "pm", "manager"].includes(
    (userRole || sessionStorage.getItem("userRole") || "").toLowerCase()
  );
  // Site engineers & PMs can create and log daily progress reports
  const screenPerm = {
    canView: rawPerm.canView !== false,
    canCreate: rawPerm.canCreate !== false,
    canEdit: rawPerm.canEdit !== false,
    canDelete: rawPerm.canDelete !== false || isAdminOrPM
  };

  const [records, setRecords] = useState([]);
  const [projectOptions, setProjectOptions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [viewMode, setViewMode] = useState("list"); // 'list' | 'form' | 'detail'
  const [activeRecord, setActiveRecord] = useState(null);
  const [formData, setFormData] = useState(() => createEmptyDPR("", actorName));
  const [pmRemarksInput, setPmRemarksInput] = useState("");
  const [showGuide, setShowGuide] = useState(false);

  // Filters
  const [searchTerm, setSearchTerm] = useState("");
  const [projectFilter, setProjectFilter] = useState("ALL");
  const [shiftFilter, setShiftFilter] = useState("ALL");
  const [statusFilter, setStatusFilter] = useState("ALL");

  // Alert Modal State
  const [alertModal, setAlertModal] = useState({
    isOpen: false,
    type: "info",
    title: "",
    message: "",
    onConfirm: null,
    confirmText: "Confirm"
  });

  const showAlert = (type, title, message, onConfirm = null, confirmText = "Confirm") => {
    setAlertModal({ isOpen: true, type, title, message, onConfirm, confirmText });
  };

  const closeAlert = () => setAlertModal(prev => ({ ...prev, isOpen: false, onConfirm: null }));

  useEffect(() => {
    let mounted = true;
    const load = async () => {
      setLoading(true);
      const [listData, projList] = await Promise.all([getDPRRecords(), getDPRProjectOptions()]);
      if (!mounted) return;
      setRecords(listData);
      setProjectOptions(projList);
      if (routeId) {
        const matched = listData.find(r => r.id === routeId);
        if (matched) {
          setActiveRecord(matched);
          setPmRemarksInput(matched.pmRemarks || "");
          setViewMode("detail");
        }
      }
      setLoading(false);
    };
    load();
    return () => {
      mounted = false;
    };
  }, [routeId]);

  const filteredRecords = useMemo(() => {
    const q = searchTerm.trim().toLowerCase();
    return records.filter(r => {
      const matchesSearch =
        !q ||
        r.id.toLowerCase().includes(q) ||
        (r.projectName || "").toLowerCase().includes(q) ||
        (r.engineer || "").toLowerCase().includes(q) ||
        (r.activities || []).some(a => (a.taskName || "").toLowerCase().includes(q));
      const matchesProject = projectFilter === "ALL" || r.projectName === projectFilter;
      const matchesShift =
        shiftFilter === "ALL" || (r.shift || "").toLowerCase().includes(shiftFilter.toLowerCase());
      const matchesStatus = statusFilter === "ALL" || r.status === statusFilter;
      return matchesSearch && matchesProject && matchesShift && matchesStatus;
    });
  }, [records, searchTerm, projectFilter, shiftFilter, statusFilter]);

  const kpiStats = useMemo(() => {
    const total = records.length;
    const approved = records.filter(r => r.status === "Approved").length;
    const pending = records.filter(r => r.status === "Pending Approval").length;
    const latestWorkers = records[0] ? sumManpowerPresent(records[0].manpower) : 0;
    const totalHindrances = records.filter(
      r => r.hse && r.hse.hindranceCategory && r.hse.hindranceCategory !== "None"
    ).length;
    return { total, approved, pending, latestWorkers, totalHindrances };
  }, [records]);

  const handleOpenCreate = () => {
    setFormData(createEmptyDPR(projectOptions[0] || "Kurnool 20 TPD CBG Plant", actorName));
    setViewMode("form");
  };

  const handleOpenEdit = (rec) => {
    if (rec.status === "Approved") {
      showAlert("warning", "Locked Report", "Approved DPRs cannot be edited for audit integrity.");
      return;
    }
    setFormData(JSON.parse(JSON.stringify(rec)));
    setViewMode("form");
  };

  const handleOpenDetail = (rec) => {
    setActiveRecord(rec);
    setPmRemarksInput(rec.pmRemarks || "");
    setViewMode("detail");
    navigate(`/dpr/${rec.id}`, { replace: true });
  };

  const handleBackToList = () => {
    setViewMode("list");
    setActiveRecord(null);
    navigate("/dpr", { replace: true });
  };

  // Generic table row helpers for Work Executed, Manpower, Equipment, Materials
  const updateListField = (section, idx, field, value) => {
    setFormData(prev => ({
      ...prev,
      [section]: prev[section].map((row, i) => (i === idx ? { ...row, [field]: value } : row))
    }));
  };

  const addListRow = (section, template) => {
    setFormData(prev => ({
      ...prev,
      [section]: [...prev[section], { ...template, id: `${section}-${Date.now()}` }]
    }));
  };

  const removeListRow = (section, idx) => {
    setFormData(prev => {
      if (prev[section].length <= 1) return prev;
      return { ...prev, [section]: prev[section].filter((_, i) => i !== idx) };
    });
  };

  const handlePhotoUpload = (e) => {
    const files = Array.from(e.target.files || []);
    if (!files.length) return;
    files.slice(0, 4).forEach(file => {
      const reader = new FileReader();
      reader.onload = () => {
        setFormData(prev => ({
          ...prev,
          photos: [
            ...(prev.photos || []),
            {
              id: `ph-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
              name: file.name,
              dataUrl: reader.result,
              capturedAt: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
            }
          ]
        }));
      };
      reader.readAsDataURL(file);
    });
    e.target.value = "";
  };

  const handleSaveForm = async (mode) => {
    if (!formData.date || !formData.projectName || !formData.engineer.trim()) {
      showAlert("error", "Missing Required Fields", "Please enter Date, Project/Plant, and Engineer name.");
      return;
    }
    const validActivity = formData.activities.some(a => a.taskName.trim().length > 0);
    if (!validActivity) {
      showAlert("error", "Activity Required", "Add at least one Work Executed activity description.");
      return;
    }

    const saved = await saveDPRRecord(formData, mode, actorName);
    const refreshed = await getDPRRecords();
    setRecords(refreshed);
    setActiveRecord(saved);
    setPmRemarksInput(saved.pmRemarks || "");
    setViewMode("detail");
    showAlert(
      "success",
      mode === "Submit" ? "DPR Submitted" : "Draft Saved",
      mode === "Submit"
        ? `${saved.id} has been submitted for Project Manager approval.`
        : `${saved.id} saved as an editable draft.`
    );
  };

  const handleApprovalAction = async (decision) => {
    if (!activeRecord) return;
    if (decision === "Returned" && !pmRemarksInput.trim()) {
      showAlert("warning", "Remarks Required", "Please enter PM verification remarks before returning a DPR.");
      return;
    }
    const updated = await updateDPRApproval(activeRecord.id, decision, pmRemarksInput.trim(), actorName);
    const refreshed = await getDPRRecords();
    setRecords(refreshed);
    setActiveRecord(updated);
    showAlert(
      decision === "Approved" ? "success" : "info",
      decision === "Approved" ? "DPR Approved & Locked" : "DPR Returned",
      decision === "Approved"
        ? `${activeRecord.id} is verified and locked for audit.`
        : `${activeRecord.id} has been returned to the engineer with remarks.`
    );
  };

  const handleDeleteDPR = (rec) => {
    if (rec.status === "Approved") {
      showAlert("warning", "Cannot Delete", "Approved DPR records are locked for audit.");
      return;
    }
    showAlert(
      "warning",
      "Delete DPR?",
      `Are you sure you want to delete ${rec.id}? This action cannot be undone.`,
      async () => {
        await deleteDPRRecord(rec.id);
        const refreshed = await getDPRRecords();
        setRecords(refreshed);
        closeAlert();
        if (activeRecord?.id === rec.id) handleBackToList();
      },
      "Delete"
    );
  };

  const handleExportCSV = () => {
    const flatRows = filteredRecords.map(r => ({
      id: r.id,
      date: r.date,
      shift: r.shift,
      projectName: r.projectName,
      engineer: r.engineer,
      contractor: r.contractor,
      activitiesCount: (r.activities || []).length,
      summaryWork: (r.activities || []).map(a => a.taskName).join(" | "),
      progressPct: `${calcDPROverallProgress(r.activities)}%`,
      manpowerPresent: sumManpowerPresent(r.manpower),
      machineHrs: sumMachineHours(r.equipment),
      hindrance: r.hse?.hindranceCategory || "None",
      status: r.status
    }));
    exportToCSV("BioNova_DPR_Register", flatRows, [
      { key: "id", label: "DPR ID" },
      { key: "date", label: "Date" },
      { key: "shift", label: "Shift" },
      { key: "projectName", label: "Project / Plant" },
      { key: "engineer", label: "Reporting Engineer" },
      { key: "contractor", label: "Contractor" },
      { key: "summaryWork", label: "Work Executed" },
      { key: "progressPct", label: "Avg % Progress" },
      { key: "manpowerPresent", label: "Manpower" },
      { key: "machineHrs", label: "Machine Run Hrs" },
      { key: "hindrance", label: "Hindrance" },
      { key: "status", label: "Status" }
    ]);
  };

  return (
    <div className="sco-container dpr-shell" style={{ display: "flex", minHeight: "100vh", background: "#f8fafc" }}>
      <Sidebar userRole={userRole} onLogout={onLogout} />
      <div className="sco-main dpr-main" style={{ flex: 1, display: "flex", flexDirection: "column", minWidth: 0, minHeight: "100vh" }}>
        <Header title="Daily Progress Report (DPR)" onLogout={onLogout} />
        <div style={{ flex: 1, width: "100%", overflowY: "auto" }}>
          <div className="dpr-container">
            {/* Hero Banner */}
            <div className="dpr-hero">
              <div className="dpr-hero-header">
                <div>
                  <div className="dpr-pills-row">
                    <span className="dpr-pill-primary">
                      <ClipboardList size={14} />
                      <span>DAILY SITE EXECUTION &amp; PROGRESS LOG</span>
                    </span>
                    <span className="dpr-pill-subtle">Shift-Wise Site Reporting</span>
                    <span className="dpr-pill-subtle">HSE &amp; PM Approval</span>
                  </div>
                  <h1>Daily Progress Report (DPR)</h1>
                  <p>
                    Record daily field quantities executed, site manpower, machinery hours, materials consumed,
                    safety compliance, and hindrances with PM verification.
                  </p>
                </div>

                <div className="dpr-hero-actions">
                  <button
                    type="button"
                    className={`dpr-btn-ghost ${showGuide ? "active" : ""}`}
                    onClick={() => setShowGuide(prev => !prev)}
                  >
                    <BookOpen size={15} />
                    <span>{showGuide ? "Hide DPR Guide" : "How DPR Works"}</span>
                  </button>
                  <button type="button" className="dpr-btn-ghost" onClick={handleExportCSV}>
                    <Download size={15} />
                    <span>Export CSV</span>
                  </button>
                  {viewMode === "list" ? (
                    <button type="button" className="dpr-btn-primary" onClick={handleOpenCreate}>
                      <Plus size={15} />
                      <span>Create Today&apos;s DPR</span>
                    </button>
                  ) : (
                    <button type="button" className="dpr-btn-primary" onClick={handleBackToList}>
                      <ArrowLeft size={15} />
                      <span>Back to Register</span>
                    </button>
                  )}
                </div>
              </div>

              {showGuide && (
                <div className="dpr-guide-card">
                  <div className="dpr-guide-header">
                    <h4>Step-by-Step DPR Workflow (Pin-to-Pin Usage)</h4>
                  </div>
                  <div className="dpr-guide-grid">
                    <div className="dpr-guide-step">
                      <div className="dpr-guide-step-num">Step 1: Log Work</div>
                      <div className="dpr-guide-step-title">Select Shift &amp; Enter Qty</div>
                      <p className="dpr-guide-step-desc">
                        Click &quot;Create Today&apos;s DPR&quot;, select Project/Plant &amp; Shift, and enter Today Executed Qty to auto-calculate % completion.
                      </p>
                    </div>
                    <div className="dpr-guide-step">
                      <div className="dpr-guide-step-num">Step 2: Resources</div>
                      <div className="dpr-guide-step-title">Manpower, Machine &amp; Stock</div>
                      <p className="dpr-guide-step-desc">
                        Record planned vs present workers, machine running/idle hours, diesel fuel, and key materials consumed.
                      </p>
                    </div>
                    <div className="dpr-guide-step">
                      <div className="dpr-guide-step-num">Step 3: HSE &amp; Proof</div>
                      <div className="dpr-guide-step-title">Safety, Delays &amp; Photos</div>
                      <p className="dpr-guide-step-desc">
                        Confirm Toolbox Talk &amp; zero incidents, log rain/drawing delays if any, attach site photos, and Submit.
                      </p>
                    </div>
                    <div className="dpr-guide-step">
                      <div className="dpr-guide-step-num">Step 4: PM Sign-Off</div>
                      <div className="dpr-guide-step-title">Approve &amp; Lock Audit</div>
                      <p className="dpr-guide-step-desc">
                        PM/Admin opens Pending reports to either Approve &amp; Lock for billing or Return for Correction with remarks.
                      </p>
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* ============================================================== */}
            {/* VIEW 1: DPR REGISTER & DASHBOARD                               */}
            {/* ============================================================== */}
            {viewMode === "list" && (
              <>
                <div className="dpr-kpi-grid">
                  <div className="dpr-kpi-card">
                    <div className="dpr-kpi-head">
                      <span>Total DPRs Logged</span>
                      <ClipboardList size={16} className="dpr-text-blue" />
                    </div>
                    <div className="dpr-kpi-value">{kpiStats.total}</div>
                    <span className="dpr-kpi-sub dpr-text-green">{kpiStats.approved} Approved &amp; Locked</span>
                  </div>
                  <div className="dpr-kpi-card">
                    <div className="dpr-kpi-head">
                      <span>Pending PM Approval</span>
                      <Clock size={16} className="dpr-text-amber" />
                    </div>
                    <div className="dpr-kpi-value">{kpiStats.pending}</div>
                    <span className="dpr-kpi-sub dpr-text-amber">Awaiting Manager Review</span>
                  </div>
                  <div className="dpr-kpi-card">
                    <div className="dpr-kpi-head">
                      <span>Latest Shift Manpower</span>
                      <Users size={16} className="dpr-text-blue" />
                    </div>
                    <div className="dpr-kpi-value">{kpiStats.latestWorkers}</div>
                    <span className="dpr-kpi-sub dpr-text-blue">Active Site Workforce</span>
                  </div>
                  <div className="dpr-kpi-card">
                    <div className="dpr-kpi-head">
                      <span>Logged Hindrances / Delays</span>
                      <AlertTriangle size={16} className="dpr-text-red" />
                    </div>
                    <div className="dpr-kpi-value">{kpiStats.totalHindrances}</div>
                    <span className="dpr-kpi-sub dpr-text-red">Weather / Drawing Holds</span>
                  </div>
                </div>

                <div className="dpr-card">
                  <div className="dpr-toolbar">
                    <h3 className="dpr-toolbar-title">
                      <ClipboardList size={16} className="dpr-text-blue" />
                      <span>Daily Progress Reports Register</span>
                    </h3>

                    <div className="dpr-filters">
                      <div className="dpr-search-wrap">
                        <Search size={14} className="dpr-search-icon" />
                        <input
                          type="text"
                          className="dpr-input-sm"
                          placeholder="Search DPR, project, task..."
                          value={searchTerm}
                          onChange={e => setSearchTerm(e.target.value)}
                        />
                      </div>

                      <select
                        className="dpr-select-sm"
                        value={projectFilter}
                        onChange={e => setProjectFilter(e.target.value)}
                      >
                        <option value="ALL">All Projects / Plants</option>
                        {projectOptions.map(name => (
                          <option key={name} value={name}>{name}</option>
                        ))}
                      </select>

                      <select
                        className="dpr-select-sm"
                        value={shiftFilter}
                        onChange={e => setShiftFilter(e.target.value)}
                      >
                        <option value="ALL">All Shifts</option>
                        <option value="Day">Day Shift</option>
                        <option value="Night">Night Shift</option>
                      </select>

                      <select
                        className="dpr-select-sm"
                        value={statusFilter}
                        onChange={e => setStatusFilter(e.target.value)}
                      >
                        <option value="ALL">All Statuses</option>
                        <option value="Draft">Draft</option>
                        <option value="Pending Approval">Pending Approval</option>
                        <option value="Returned">Returned</option>
                        <option value="Approved">Approved</option>
                      </select>

                      <button
                        type="button"
                        className="dpr-btn-primary dpr-btn-toolbar"
                        onClick={handleOpenCreate}
                      >
                        <Plus size={14} />
                        <span>Create DPR</span>
                      </button>
                    </div>
                  </div>

                  <div className="dpr-table-wrap">
                    <table className="dpr-table">
                      <thead>
                        <tr>
                          <th>DPR NO &amp; DATE</th>
                          <th>PROJECT / PLANT</th>
                          <th>KEY WORK EXECUTED</th>
                          <th>PROGRESS</th>
                          <th>MANPOWER &amp; EQUIP</th>
                          <th>HSE &amp; DELAY</th>
                          <th>STATUS &amp; ACTIONS</th>
                        </tr>
                      </thead>
                      <tbody>
                        {loading ? (
                          <tr>
                            <td colSpan="7" className="dpr-empty-cell">
                              Loading Daily Progress Reports...
                            </td>
                          </tr>
                        ) : filteredRecords.length === 0 ? (
                          <tr>
                            <td colSpan="7" className="dpr-empty-cell">
                              <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: "10px", padding: "14px 0" }}>
                                <span>No DPR records match your filter.</span>
                                <button
                                  type="button"
                                  className="dpr-btn-primary"
                                  onClick={handleOpenCreate}
                                >
                                  <Plus size={14} />
                                  <span>Create Today&apos;s DPR</span>
                                </button>
                              </div>
                            </td>
                          </tr>
                        ) : (
                          filteredRecords.map(rec => {
                            const avgPct = calcDPROverallProgress(rec.activities);
                            const workers = sumManpowerPresent(rec.manpower);
                            const hrs = sumMachineHours(rec.equipment);
                            const firstWork = rec.activities?.[0]?.taskName || "No activity logged";
                            const extraCount = (rec.activities?.length || 0) - 1;
                            return (
                              <tr key={rec.id}>
                                <td data-label="DPR No & Date">
                                  <div className="dpr-cell-stack">
                                    <button
                                      type="button"
                                      className="dpr-code-link"
                                      onClick={() => handleOpenDetail(rec)}
                                    >
                                      {rec.id}
                                    </button>
                                    <div className="dpr-sub">
                                      {rec.date} • {(rec.shift || "").split(" ")[0]}
                                    </div>
                                  </div>
                                </td>
                                <td data-label="Project / Plant">
                                  <div className="dpr-cell-stack">
                                    <div className="dpr-strong">{rec.projectName}</div>
                                    <div className="dpr-sub">{rec.engineer}</div>
                                  </div>
                                </td>
                                <td data-label="Key Work Executed">
                                  <div className="dpr-cell-stack">
                                    <div>{firstWork}</div>
                                    {extraCount > 0 && (
                                      <div className="dpr-sub">+{extraCount} more activity item(s)</div>
                                    )}
                                  </div>
                                </td>
                                <td data-label="Progress">
                                  <div className="dpr-cell-stack">
                                    <div className="dpr-strong">{avgPct}% Cum.</div>
                                    <div className="dpr-progress-track">
                                      <div className="dpr-progress-fill" style={{ width: `${avgPct}%` }} />
                                    </div>
                                  </div>
                                </td>
                                <td data-label="Manpower & Equip">
                                  <div className="dpr-cell-stack">
                                    <div className="dpr-strong">{workers} Workers</div>
                                    <div className="dpr-sub">{hrs} Machine Hrs</div>
                                  </div>
                                </td>
                                <td data-label="HSE & Delay">
                                  <div className="dpr-cell-stack">
                                    <div>
                                      {rec.hse?.incidentsCount > 0
                                        ? `${rec.hse.incidentsCount} Incident`
                                        : "Zero Incidents"}
                                    </div>
                                    <div className="dpr-sub">
                                      {rec.hse?.hindranceCategory && rec.hse.hindranceCategory !== "None"
                                        ? `${rec.hse.hindranceCategory} (${rec.hse.lostHours || 0}h)`
                                        : `TBT: ${rec.hse?.toolboxTalk ? "Yes" : "No"}`}
                                    </div>
                                  </div>
                                </td>
                                <td data-label="Status & Actions">
                                  <div className="dpr-cell-stack">
                                    <span className={`dpr-badge ${getStatusBadgeClass(rec.status)}`}>
                                      {rec.status}
                                    </span>
                                    <div className="dpr-action-group">
                                      <button
                                        type="button"
                                        className="dpr-icon-btn"
                                        onClick={() => handleOpenDetail(rec)}
                                        title="View / Approve"
                                      >
                                        <Eye size={12} />
                                        <span>View</span>
                                      </button>
                                      {rec.status !== "Approved" && screenPerm.canEdit && (
                                        <button
                                          type="button"
                                          className="dpr-icon-btn"
                                          onClick={() => handleOpenEdit(rec)}
                                          title="Edit DPR"
                                        >
                                          <Edit3 size={12} />
                                          <span>Edit</span>
                                        </button>
                                      )}
                                      {rec.status !== "Approved" && screenPerm.canDelete && (
                                        <button
                                          type="button"
                                          className="dpr-icon-btn danger"
                                          onClick={() => handleDeleteDPR(rec)}
                                          title="Delete DPR"
                                        >
                                          <Trash2 size={12} />
                                        </button>
                                      )}
                                    </div>
                                  </div>
                                </td>
                              </tr>
                            );
                          })
                        )}
                      </tbody>
                    </table>
                  </div>
                </div>
              </>
            )}

            {/* ============================================================== */}
            {/* VIEW 2: CREATE / EDIT MULTI-SECTION DPR FORM                   */}
            {/* ============================================================== */}
            {viewMode === "form" && (
              <div className="dpr-card">
                <div className="dpr-form-header">
                  <div>
                    <div className="dpr-sub">
                      {formData.id ? `Editing ${formData.id} (${formData.status})` : "New Daily Progress Log"}
                    </div>
                    <h3 style={{ margin: "2px 0 0 0", fontSize: "16px", fontWeight: 800, color: "#0f172a" }}>
                      Daily Site Progress Entry Form
                    </h3>
                  </div>
                  <div className="dpr-action-group">
                    <button type="button" className="dpr-btn-save-draft" onClick={handleBackToList}>
                      Cancel
                    </button>
                    <button type="button" className="dpr-btn-save-draft" onClick={() => handleSaveForm("Draft")}>
                      Save Draft
                    </button>
                    <button type="button" className="dpr-btn-submit" onClick={() => handleSaveForm("Submit")}>
                      <Send size={14} />
                      <span>Submit for PM Approval</span>
                    </button>
                  </div>
                </div>

                <div className="dpr-form-body">
                  {/* Section A */}
                  <div className="dpr-section">
                    <div className="dpr-section-title-row">
                      <h4 className="dpr-section-title">
                        <ClipboardList size={15} />
                        <span>Section A — General Site, Shift &amp; Weather Details</span>
                      </h4>
                    </div>
                    <div className="dpr-grid-3">
                      <div className="dpr-field">
                        <label>DPR Date *</label>
                        <input
                          type="date"
                          value={formData.date}
                          onChange={e => setFormData(prev => ({ ...prev, date: e.target.value }))}
                        />
                      </div>
                      <div className="dpr-field">
                        <label>Project / Plant *</label>
                        <select
                          value={formData.projectName}
                          onChange={e => setFormData(prev => ({ ...prev, projectName: e.target.value }))}
                        >
                          {projectOptions.map(opt => (
                            <option key={opt} value={opt}>{opt}</option>
                          ))}
                        </select>
                      </div>
                      <div className="dpr-field">
                        <label>Shift *</label>
                        <select
                          value={formData.shift}
                          onChange={e => setFormData(prev => ({ ...prev, shift: e.target.value }))}
                        >
                          <option value="Day Shift (08:00 - 18:00)">Day Shift (08:00 - 18:00)</option>
                          <option value="Night Shift (20:00 - 06:00)">Night Shift (20:00 - 06:00)</option>
                          <option value="General Shift (09:00 - 17:30)">General Shift (09:00 - 17:30)</option>
                        </select>
                      </div>
                      <div className="dpr-field">
                        <label>Reporting Site Engineer *</label>
                        <input
                          type="text"
                          value={formData.engineer}
                          onChange={e => setFormData(prev => ({ ...prev, engineer: e.target.value }))}
                          placeholder="Enter site engineer name"
                        />
                      </div>
                      <div className="dpr-field">
                        <label>Contractor / Agency</label>
                        <input
                          type="text"
                          value={formData.contractor}
                          onChange={e => setFormData(prev => ({ ...prev, contractor: e.target.value }))}
                          placeholder="e.g. Sri Sai EPC Infra"
                        />
                      </div>
                      <div className="dpr-field">
                        <label>Weather &amp; Temperature</label>
                        <input
                          type="text"
                          value={formData.weather}
                          onChange={e => setFormData(prev => ({ ...prev, weather: e.target.value }))}
                          placeholder="e.g. Clear / Sunny (31°C)"
                        />
                      </div>
                    </div>
                  </div>

                  {/* Section B: Work Executed */}
                  <div className="dpr-section">
                    <div className="dpr-section-title-row">
                      <h4 className="dpr-section-title">
                        <CheckCircle2 size={15} />
                        <span>Section B — Work Executed Today (BOQ / Milestone Progress)</span>
                      </h4>
                      <button
                        type="button"
                        className="dpr-add-row-btn"
                        onClick={() =>
                          addListRow("activities", {
                            taskName: "",
                            uom: "m³",
                            targetQty: 100,
                            prevQty: 0,
                            todayQty: 0
                          })
                        }
                      >
                        <Plus size={13} /> Add Activity Row
                      </button>
                    </div>
                    <div style={{ overflowX: "auto" }}>
                      <table className="dpr-line-table">
                        <thead>
                          <tr>
                            <th style={{ minWidth: "220px" }}>Activity / Milestone Description *</th>
                            <th style={{ width: "80px" }}>UOM</th>
                            <th style={{ width: "95px" }}>Target Qty</th>
                            <th style={{ width: "95px" }}>Prev Cum.</th>
                            <th style={{ width: "95px" }}>Today Qty</th>
                            <th style={{ width: "85px" }}>Total %</th>
                            <th style={{ width: "44px" }}></th>
                          </tr>
                        </thead>
                        <tbody>
                          {formData.activities.map((act, idx) => (
                            <tr key={act.id || idx}>
                              <td data-label="Activity / Milestone">
                                <input
                                  type="text"
                                  value={act.taskName}
                                  placeholder="e.g. Digester #2 Ring Wall Concrete"
                                  onChange={e => updateListField("activities", idx, "taskName", e.target.value)}
                                />
                              </td>
                              <td data-label="UOM">
                                <input
                                  type="text"
                                  value={act.uom}
                                  onChange={e => updateListField("activities", idx, "uom", e.target.value)}
                                />
                              </td>
                              <td data-label="Target Qty">
                                <input
                                  type="number"
                                  min="0"
                                  value={act.targetQty}
                                  onChange={e => updateListField("activities", idx, "targetQty", e.target.value)}
                                />
                              </td>
                              <td data-label="Prev Cum.">
                                <input
                                  type="number"
                                  min="0"
                                  value={act.prevQty}
                                  onChange={e => updateListField("activities", idx, "prevQty", e.target.value)}
                                />
                              </td>
                              <td data-label="Today Qty">
                                <input
                                  type="number"
                                  min="0"
                                  value={act.todayQty}
                                  onChange={e => updateListField("activities", idx, "todayQty", e.target.value)}
                                />
                              </td>
                              <td data-label="Total %" className="dpr-strong dpr-text-blue">
                                {calcPercent(act.prevQty, act.todayQty, act.targetQty)}%
                              </td>
                              <td className="dpr-line-del-cell">
                                <button
                                  type="button"
                                  className="dpr-icon-btn danger"
                                  aria-label="Remove activity"
                                  onClick={() => removeListRow("activities", idx)}
                                >
                                  <Trash2 size={12} />
                                  <span className="dpr-mobile-btn-label">Remove</span>
                                </button>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>

                  {/* Sections C & D */}
                  <div className="dpr-grid-2">
                    <div className="dpr-section">
                      <div className="dpr-section-title-row">
                        <h4 className="dpr-section-title">
                          <Users size={15} />
                          <span>Section C — Manpower Deployment</span>
                        </h4>
                        <button
                          type="button"
                          className="dpr-add-row-btn"
                          onClick={() => addListRow("manpower", { trade: "", planned: 0, present: 0 })}
                        >
                          <Plus size={13} /> Add Trade
                        </button>
                      </div>
                      <table className="dpr-line-table">
                        <thead>
                          <tr>
                            <th>Trade / Category</th>
                            <th style={{ width: "75px" }}>Planned</th>
                            <th style={{ width: "75px" }}>Present</th>
                            <th style={{ width: "65px" }}>Diff</th>
                            <th style={{ width: "40px" }}></th>
                          </tr>
                        </thead>
                        <tbody>
                          {formData.manpower.map((mp, idx) => {
                            const diff = (Number(mp.present) || 0) - (Number(mp.planned) || 0);
                            return (
                              <tr key={mp.id || idx}>
                                <td data-label="Trade / Category">
                                  <input
                                    type="text"
                                    value={mp.trade}
                                    placeholder="e.g. Welders / Fitters"
                                    onChange={e => updateListField("manpower", idx, "trade", e.target.value)}
                                  />
                                </td>
                                <td data-label="Planned">
                                  <input
                                    type="number"
                                    min="0"
                                    value={mp.planned}
                                    onChange={e => updateListField("manpower", idx, "planned", e.target.value)}
                                  />
                                </td>
                                <td data-label="Present">
                                  <input
                                    type="number"
                                    min="0"
                                    value={mp.present}
                                    onChange={e => updateListField("manpower", idx, "present", e.target.value)}
                                  />
                                </td>
                                <td
                                  data-label="Diff"
                                  className={diff < 0 ? "dpr-text-red dpr-strong" : "dpr-text-green dpr-strong"}
                                >
                                  {diff >= 0 ? `+${diff}` : diff}
                                </td>
                                <td className="dpr-line-del-cell">
                                  <button
                                    type="button"
                                    className="dpr-icon-btn danger"
                                    aria-label="Remove trade"
                                    onClick={() => removeListRow("manpower", idx)}
                                  >
                                    <Trash2 size={12} />
                                    <span className="dpr-mobile-btn-label">Remove</span>
                                  </button>
                                </td>
                              </tr>
                            );
                          })}
                        </tbody>
                      </table>
                    </div>

                    <div className="dpr-section">
                      <div className="dpr-section-title-row">
                        <h4 className="dpr-section-title">
                          <Wrench size={15} />
                          <span>Section D — Machinery &amp; Equipment Log</span>
                        </h4>
                        <button
                          type="button"
                          className="dpr-add-row-btn"
                          onClick={() => addListRow("equipment", { name: "", runHrs: 0, idleHrs: 0, fuelLiters: 0 })}
                        >
                          <Plus size={13} /> Add Machine
                        </button>
                      </div>
                      <table className="dpr-line-table">
                        <thead>
                          <tr>
                            <th>Equipment</th>
                            <th style={{ width: "68px" }}>Run Hr</th>
                            <th style={{ width: "68px" }}>Idle Hr</th>
                            <th style={{ width: "68px" }}>Fuel (L)</th>
                            <th style={{ width: "40px" }}></th>
                          </tr>
                        </thead>
                        <tbody>
                          {formData.equipment.map((eq, idx) => (
                            <tr key={eq.id || idx}>
                              <td data-label="Equipment">
                                <input
                                  type="text"
                                  value={eq.name}
                                  placeholder="e.g. Hydra Crane 14T"
                                  onChange={e => updateListField("equipment", idx, "name", e.target.value)}
                                />
                              </td>
                              <td data-label="Run Hr">
                                <input
                                  type="number"
                                  min="0"
                                  step="0.5"
                                  value={eq.runHrs}
                                  onChange={e => updateListField("equipment", idx, "runHrs", e.target.value)}
                                />
                              </td>
                              <td data-label="Idle Hr">
                                <input
                                  type="number"
                                  min="0"
                                  step="0.5"
                                  value={eq.idleHrs}
                                  onChange={e => updateListField("equipment", idx, "idleHrs", e.target.value)}
                                />
                              </td>
                              <td data-label="Fuel (L)">
                                <input
                                  type="number"
                                  min="0"
                                  value={eq.fuelLiters}
                                  onChange={e => updateListField("equipment", idx, "fuelLiters", e.target.value)}
                                />
                              </td>
                              <td className="dpr-line-del-cell">
                                <button
                                  type="button"
                                  className="dpr-icon-btn danger"
                                  aria-label="Remove equipment"
                                  onClick={() => removeListRow("equipment", idx)}
                                >
                                  <Trash2 size={12} />
                                  <span className="dpr-mobile-btn-label">Remove</span>
                                </button>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>

                  {/* Sections E & F */}
                  <div className="dpr-grid-2">
                    <div className="dpr-section">
                      <div className="dpr-section-title-row">
                        <h4 className="dpr-section-title">
                          <Package size={15} />
                          <span>Section E — Key Materials Consumed</span>
                        </h4>
                        <button
                          type="button"
                          className="dpr-add-row-btn"
                          onClick={() =>
                            addListRow("materials", { name: "", unit: "MT", consumedToday: 0, closingStock: 0 })
                          }
                        >
                          <Plus size={13} /> Add Material
                        </button>
                      </div>
                      <table className="dpr-line-table">
                        <thead>
                          <tr>
                            <th>Material</th>
                            <th style={{ width: "68px" }}>Unit</th>
                            <th style={{ width: "78px" }}>Used</th>
                            <th style={{ width: "78px" }}>Closing</th>
                            <th style={{ width: "40px" }}></th>
                          </tr>
                        </thead>
                        <tbody>
                          {formData.materials.map((mat, idx) => (
                            <tr key={mat.id || idx}>
                              <td data-label="Material">
                                <input
                                  type="text"
                                  value={mat.name}
                                  placeholder="e.g. TMT Rebar 16mm"
                                  onChange={e => updateListField("materials", idx, "name", e.target.value)}
                                />
                              </td>
                              <td data-label="Unit">
                                <input
                                  type="text"
                                  value={mat.unit}
                                  onChange={e => updateListField("materials", idx, "unit", e.target.value)}
                                />
                              </td>
                              <td data-label="Used">
                                <input
                                  type="number"
                                  min="0"
                                  step="0.1"
                                  value={mat.consumedToday}
                                  onChange={e => updateListField("materials", idx, "consumedToday", e.target.value)}
                                />
                              </td>
                              <td data-label="Closing">
                                <input
                                  type="number"
                                  min="0"
                                  step="0.1"
                                  value={mat.closingStock}
                                  onChange={e => updateListField("materials", idx, "closingStock", e.target.value)}
                                />
                              </td>
                              <td className="dpr-line-del-cell">
                                <button
                                  type="button"
                                  className="dpr-icon-btn danger"
                                  aria-label="Remove material"
                                  onClick={() => removeListRow("materials", idx)}
                                >
                                  <Trash2 size={12} />
                                  <span className="dpr-mobile-btn-label">Remove</span>
                                </button>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>

                    <div className="dpr-section">
                      <div className="dpr-section-title-row">
                        <h4 className="dpr-section-title">
                          <ShieldCheck size={15} />
                          <span>Section F — HSE Safety &amp; Hindrances</span>
                        </h4>
                      </div>
                      <div className="dpr-grid-2" style={{ gap: "10px" }}>
                        <div className="dpr-field">
                          <label>Daily Toolbox Talk Done?</label>
                          <select
                            value={formData.hse.toolboxTalk ? "YES" : "NO"}
                            onChange={e =>
                              setFormData(prev => ({
                                ...prev,
                                hse: { ...prev.hse, toolboxTalk: e.target.value === "YES" }
                              }))
                            }
                          >
                            <option value="YES">Yes — Completed</option>
                            <option value="NO">No</option>
                          </select>
                        </div>
                        <div className="dpr-field">
                          <label>PPE Compliance (%)</label>
                          <input
                            type="number"
                            min="0"
                            max="100"
                            value={formData.hse.ppeCompliancePercent}
                            onChange={e =>
                              setFormData(prev => ({
                                ...prev,
                                hse: { ...prev.hse, ppeCompliancePercent: Number(e.target.value) || 0 }
                              }))
                            }
                          />
                        </div>
                        <div className="dpr-field">
                          <label>Hindrance / Delay Type</label>
                          <select
                            value={formData.hse.hindranceCategory}
                            onChange={e =>
                              setFormData(prev => ({
                                ...prev,
                                hse: { ...prev.hse, hindranceCategory: e.target.value }
                              }))
                            }
                          >
                            <option value="None">None</option>
                            <option value="Weather / Rain">Weather / Rain</option>
                            <option value="Material Shortage">Material Shortage</option>
                            <option value="Drawing / Clarification">Drawing / Clarification</option>
                            <option value="Machine Breakdown">Machine Breakdown</option>
                            <option value="Permit / Access Hold">Permit / Access Hold</option>
                          </select>
                        </div>
                        <div className="dpr-field">
                          <label>Lost Hours Due to Delay</label>
                          <input
                            type="number"
                            min="0"
                            step="0.5"
                            value={formData.hse.lostHours}
                            onChange={e =>
                              setFormData(prev => ({
                                ...prev,
                                hse: { ...prev.hse, lostHours: Number(e.target.value) || 0 }
                              }))
                            }
                          />
                        </div>
                      </div>
                      <div className="dpr-field" style={{ marginTop: "10px" }}>
                        <label>Safety Observations / Delay Reason Remarks</label>
                        <textarea
                          rows={2}
                          value={formData.hse.remarks}
                          onChange={e =>
                            setFormData(prev => ({
                              ...prev,
                              hse: { ...prev.hse, remarks: e.target.value }
                            }))
                          }
                          placeholder="Describe any stoppage, safety note, or corrective action..."
                        />
                      </div>
                    </div>
                  </div>

                  {/* Section G: Tomorrow Plan & Photos */}
                  <div className="dpr-section">
                    <div className="dpr-section-title-row">
                      <h4 className="dpr-section-title">
                        <Camera size={15} />
                        <span>Section G — Tomorrow&apos;s Plan &amp; Site Progress Photos</span>
                      </h4>
                    </div>
                    <div className="dpr-grid-2">
                      <div className="dpr-field">
                        <label>Tomorrow&apos;s Planned Work Targets</label>
                        <textarea
                          rows={4}
                          value={formData.tomorrowPlan}
                          onChange={e => setFormData(prev => ({ ...prev, tomorrowPlan: e.target.value }))}
                          placeholder="List tomorrow's target tasks and inspections..."
                        />
                      </div>
                      <div className="dpr-field">
                        <label>Attach Site Progress Photos (Up to 4 per upload)</label>
                        <input type="file" accept="image/*" multiple onChange={handlePhotoUpload} />
                        {formData.photos && formData.photos.length > 0 && (
                          <div className="dpr-photo-grid">
                            {formData.photos.map(ph => (
                              <div key={ph.id} className="dpr-photo-card">
                                <img src={ph.dataUrl} alt={ph.name} />
                                <div className="dpr-photo-caption">
                                  <span style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                                    {ph.name}
                                  </span>
                                  <button
                                    type="button"
                                    className="dpr-icon-btn danger"
                                    onClick={() =>
                                      setFormData(prev => ({
                                        ...prev,
                                        photos: prev.photos.filter(item => item.id !== ph.id)
                                      }))
                                    }
                                  >
                                    <Trash2 size={11} />
                                  </button>
                                </div>
                              </div>
                            ))}
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* ============================================================== */}
            {/* VIEW 3: DPR DETAIL & PM APPROVAL WORKFLOW                      */}
            {/* ============================================================== */}
            {viewMode === "detail" && activeRecord && (
              <div className="dpr-card">
                <div className="dpr-form-header">
                  <div>
                    <div style={{ display: "flex", alignItems: "center", gap: "8px", flexWrap: "wrap" }}>
                      <span className="dpr-code-link">{activeRecord.id}</span>
                      <span className={`dpr-badge ${getStatusBadgeClass(activeRecord.status)}`}>
                        {activeRecord.status}
                      </span>
                      {activeRecord.status === "Approved" && (
                        <span style={{ display: "inline-flex", alignItems: "center", gap: "4px", fontSize: "11px", color: "#15803d", fontWeight: 700 }}>
                          <Lock size={12} /> Locked for Audit
                        </span>
                      )}
                    </div>
                    <h3 style={{ margin: "4px 0 0 0", fontSize: "16.5px", fontWeight: 800, color: "#0f172a" }}>
                      {activeRecord.projectName} — {activeRecord.date} ({activeRecord.shift})
                    </h3>
                    <div className="dpr-sub">
                      Engineer: {activeRecord.engineer} • Contractor: {activeRecord.contractor || "In-House"} • Weather: {activeRecord.weather}
                    </div>
                  </div>

                  <div className="dpr-action-group">
                    <button type="button" className="dpr-icon-btn" onClick={() => window.print()}>
                      <Printer size={13} />
                      <span>Print / Save PDF</span>
                    </button>
                    {activeRecord.status !== "Approved" && screenPerm.canEdit && (
                      <button type="button" className="dpr-icon-btn" onClick={() => handleOpenEdit(activeRecord)}>
                        <Edit3 size={13} />
                        <span>Edit DPR</span>
                      </button>
                    )}
                  </div>
                </div>

                <div className="dpr-form-body">
                  {/* Audit Stepper */}
                  <div className="dpr-stepper">
                    <div className="dpr-step-box done">
                      <div className="dpr-strong" style={{ fontSize: "12px", color: "#15803d" }}>
                        1. Site Report Logged
                      </div>
                      <div className="dpr-sub">By {activeRecord.engineer} on {activeRecord.date}</div>
                    </div>
                    <div
                      className={`dpr-step-box ${
                        activeRecord.status === "Pending Approval"
                          ? "active"
                          : activeRecord.status === "Approved"
                            ? "done"
                            : activeRecord.status === "Returned"
                              ? "returned"
                              : ""
                      }`}
                    >
                      <div className="dpr-strong" style={{ fontSize: "12px" }}>
                        2. PM / Admin Review
                      </div>
                      <div className="dpr-sub">
                        {activeRecord.submittedAt
                          ? `Submitted: ${activeRecord.submittedAt}`
                          : "Currently in Draft"}
                      </div>
                    </div>
                    <div className={`dpr-step-box ${activeRecord.status === "Approved" ? "done" : ""}`}>
                      <div className="dpr-strong" style={{ fontSize: "12px" }}>
                        3. Approved &amp; Locked
                      </div>
                      <div className="dpr-sub">
                        {activeRecord.approvedAt
                          ? `Approved by ${activeRecord.approvedBy} (${activeRecord.approvedAt})`
                          : "Pending final PM approval"}
                      </div>
                    </div>
                  </div>

                  {/* Work Progress Summary */}
                  <div className="dpr-section">
                    <div className="dpr-section-title-row">
                      <h4 className="dpr-section-title">
                        <CheckCircle2 size={15} />
                        <span>Work Executed vs Planned Targets</span>
                      </h4>
                    </div>
                    <table className="dpr-line-table">
                      <thead>
                        <tr>
                          <th>Activity</th>
                          <th>UOM</th>
                          <th>Target</th>
                          <th>Prev Cum.</th>
                          <th>Today Qty</th>
                          <th style={{ width: "180px" }}>Cumulative %</th>
                        </tr>
                      </thead>
                      <tbody>
                        {(activeRecord.activities || []).map((a, i) => {
                          const pct = calcPercent(a.prevQty, a.todayQty, a.targetQty);
                          const newCum = (Number(a.prevQty) || 0) + (Number(a.todayQty) || 0);
                          return (
                            <tr key={a.id || i}>
                              <td data-label="Activity" className="dpr-strong">{a.taskName}</td>
                              <td data-label="UOM">{a.uom}</td>
                              <td data-label="Target">{a.targetQty}</td>
                              <td data-label="Prev Cum.">{a.prevQty}</td>
                              <td data-label="Today Qty" className="dpr-strong dpr-text-blue">+{a.todayQty}</td>
                              <td data-label="Cumulative %">
                                <div className="dpr-cell-stack">
                                  <div style={{ display: "flex", justifyContent: "space-between", fontSize: "11px", fontWeight: 700, gap: "8px" }}>
                                    <span>{newCum} / {a.targetQty}</span>
                                    <span>{pct}%</span>
                                  </div>
                                  <div className="dpr-progress-track">
                                    <div className="dpr-progress-fill" style={{ width: `${pct}%` }} />
                                  </div>
                                </div>
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>

                  {/* Manpower, Machinery, Materials & HSE Summary */}
                  <div className="dpr-grid-2">
                    <div className="dpr-section">
                      <h4 className="dpr-section-title" style={{ marginBottom: "10px" }}>
                        <Users size={15} />
                        <span>Manpower &amp; Machinery Summary</span>
                      </h4>
                      <div className="dpr-sub" style={{ marginBottom: "8px" }}>
                        <strong>Total Workforce Present:</strong> {sumManpowerPresent(activeRecord.manpower)} •{" "}
                        <strong>Total Machine Hours:</strong> {sumMachineHours(activeRecord.equipment)} hrs
                      </div>
                      <ul style={{ margin: 0, paddingLeft: "18px", fontSize: "12px", color: "#334155", lineHeight: 1.7 }}>
                        {(activeRecord.manpower || []).map((m, i) => (
                          <li key={i}>{m.trade}: {m.present} / {m.planned} planned</li>
                        ))}
                        {(activeRecord.equipment || []).map((eq, i) => (
                          <li key={`eq-${i}`}>{eq.name}: {eq.runHrs}h run ({eq.idleHrs}h idle, {eq.fuelLiters}L fuel)</li>
                        ))}
                      </ul>
                    </div>

                    <div className="dpr-section">
                      <h4 className="dpr-section-title" style={{ marginBottom: "10px" }}>
                        <ShieldCheck size={15} />
                        <span>Materials, HSE &amp; Tomorrow&apos;s Plan</span>
                      </h4>
                      <div style={{ fontSize: "12px", color: "#334155", lineHeight: 1.65 }}>
                        <div>
                          <strong>HSE Check:</strong> TBT {activeRecord.hse?.toolboxTalk ? "Completed" : "Pending"} •
                          PPE {activeRecord.hse?.ppeCompliancePercent ?? 100}% •
                          Incidents: {activeRecord.hse?.incidentsCount ?? 0}
                        </div>
                        <div>
                          <strong>Hindrance:</strong> {activeRecord.hse?.hindranceCategory || "None"} ({activeRecord.hse?.lostHours || 0} hrs lost)
                        </div>
                        {activeRecord.hse?.remarks && (
                          <div style={{ marginTop: "4px" }}>
                            <strong>Notes:</strong> {activeRecord.hse.remarks}
                          </div>
                        )}
                        <div style={{ marginTop: "6px" }}>
                          <strong>Materials Consumed:</strong>{" "}
                          {(activeRecord.materials || []).map(mt => `${mt.name} (${mt.consumedToday} ${mt.unit})`).join(", ") || "None"}
                        </div>
                        {activeRecord.tomorrowPlan && (
                          <div style={{ marginTop: "6px", whiteSpace: "pre-line" }}>
                            <strong>Tomorrow&apos;s Plan:</strong>{"\n"}{activeRecord.tomorrowPlan}
                          </div>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Site Photos */}
                  {activeRecord.photos && activeRecord.photos.length > 0 && (
                    <div className="dpr-section">
                      <h4 className="dpr-section-title" style={{ marginBottom: "8px" }}>
                        <Camera size={15} />
                        <span>Site Photo Proofs ({activeRecord.photos.length})</span>
                      </h4>
                      <div className="dpr-photo-grid">
                        {activeRecord.photos.map(ph => (
                          <div key={ph.id} className="dpr-photo-card">
                            <img src={ph.dataUrl} alt={ph.name} />
                            <div className="dpr-photo-caption">
                              <span>{ph.name}</span>
                              <span>{ph.capturedAt}</span>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* PM Approval Controls */}
                  {isAdminOrPM && activeRecord.status === "Pending Approval" && (
                    <div className="dpr-section" style={{ background: "#f8fafc" }}>
                      <h4 className="dpr-section-title" style={{ marginBottom: "8px" }}>
                        <ShieldCheck size={15} />
                        <span>PM Verification &amp; Sign-Off</span>
                      </h4>
                      <div className="dpr-field">
                        <label>PM Verification Remarks (Required if returning)</label>
                        <textarea
                          rows={2}
                          value={pmRemarksInput}
                          onChange={e => setPmRemarksInput(e.target.value)}
                          placeholder="Enter approval note or correction instructions..."
                        />
                      </div>
                      <div className="dpr-action-group" style={{ marginTop: "12px" }}>
                        <button
                          type="button"
                          className="dpr-btn-approve"
                          onClick={() => handleApprovalAction("Approved")}
                        >
                          <CheckCircle2 size={14} />
                          <span>Approve &amp; Lock DPR</span>
                        </button>
                        <button
                          type="button"
                          className="dpr-btn-return"
                          onClick={() => handleApprovalAction("Returned")}
                        >
                          <RotateCcw size={14} />
                          <span>Return for Correction</span>
                        </button>
                      </div>
                    </div>
                  )}

                  {activeRecord.pmRemarks && activeRecord.status !== "Pending Approval" && (
                    <div className="dpr-section">
                      <h4 className="dpr-section-title" style={{ marginBottom: "6px" }}>PM Verification Remarks</h4>
                      <p style={{ margin: 0, fontSize: "12.5px", color: "#334155" }}>{activeRecord.pmRemarks}</p>
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      <AlertModal
        isOpen={alertModal.isOpen}
        type={alertModal.type}
        title={alertModal.title}
        message={alertModal.message}
        onClose={closeAlert}
        onConfirm={alertModal.onConfirm}
        confirmText={alertModal.confirmText}
      />
    </div>
  );
}

