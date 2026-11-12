import React, { useState, useEffect } from "react";
import {
  HardHat,
  ShieldCheck,
  Flame,
  AlertTriangle,
  CheckCircle2,
  Plus,
  Search,
  UserCheck,
  Activity,
  FileCheck2,
  X,
  ArrowLeft,
  Save
} from "lucide-react";
import {
  STORAGE_KEYS,
  INITIAL_SAFETY,
  INITIAL_VISITORS,
  getStoredData,
  saveStoredData
} from "./visitorData";

const SafetyClearance = ({ onNavigate }) => {
  const [safetyLogs, setSafetyLogs] = useState(() =>
    getStoredData(STORAGE_KEYS.SAFETY_CLEARANCE, INITIAL_SAFETY)
  );

  useEffect(() => {
    const handleUpdate = () => {
      setSafetyLogs(getStoredData(STORAGE_KEYS.SAFETY_CLEARANCE, INITIAL_SAFETY));
    };
    window.addEventListener("bionova_visitor_updated", handleUpdate);
    return () => window.removeEventListener("bionova_visitor_updated", handleUpdate);
  }, []);

  const [searchTerm, setSearchTerm] = useState("");
  const [isModalOpen, setIsModalOpen] = useState(false);

  const [formData, setFormData] = useState({
    visitorName: "",
    organization: "",
    inductedBy: "Srinivas Rao (HSE Officer)",
    hazardBriefingCompleted: true,
    ppeChecklist: {
      hardHat: true,
      hiVisVest: true,
      safetyShoes: true,
      gasMonitor: false,
      earPlugs: false
    },
    emergencyBriefed: true
  });

  const handleCreateInduction = (e) => {
    e.preventDefault();
    if (!formData.visitorName.trim()) return;

    const newRec = {
      id: `SC-2026-${String(safetyLogs.length + 94).padStart(3, "0")}`,
      inductionDate: new Date().toISOString().slice(0, 10),
      inductionTime: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }),
      ...formData,
      status: "Cleared"
    };

    const updated = [newRec, ...safetyLogs];
    setSafetyLogs(updated);
    saveStoredData(STORAGE_KEYS.SAFETY_CLEARANCE, updated);
    setIsModalOpen(false);
  };

  const filtered = safetyLogs.filter(
    (item) =>
      item.visitorName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.organization.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.id.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="vm-submodule-container">
      {/* Header */}
      <div className="vm-section-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="vm-section-desc" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Enforce mandatory industrial safety protocols, toxic gas hazards briefing, PPE gear verification, and emergency evacuation clearance.
        </p>
        <button onClick={() => setIsModalOpen(true)} className="vm-btn-primary text-xs" style={{ flexShrink: 0, marginLeft: "auto" }}>
          <Plus size={16} /> Record Safety Induction
        </button>
      </div>

      {/* If isModalOpen is true, render Full-Page Form Card. Otherwise, render Warnings and Table */}
      {isModalOpen ? (
        <div style={{
          backgroundColor: "#ffffff",
          borderRadius: "14px",
          border: "1px solid #e2e8f0",
          boxShadow: "0 1px 3px rgba(0, 0, 0, 0.05)",
          overflow: "hidden",
          marginTop: "10px"
        }}>
          {/* Form Header with Back Button */}
          <div style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            padding: "20px 28px",
            borderBottom: "1px solid #e2e8f0",
            backgroundColor: "#fafbfc"
          }}>
            <div>
              <h2 style={{ fontSize: "20px", fontWeight: "700", color: "#0f172a", margin: 0, display: "flex", alignItems: "center", gap: "10px" }}>
                <HardHat size={22} color="#059669" />
                Record Visitor Safety Induction
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Enforce mandatory industrial safety protocols, toxic gas hazards briefing, PPE gear verification, and emergency evacuation clearance.
              </p>
            </div>
            <button
              type="button"
              onClick={() => setIsModalOpen(false)}
              style={{
                display: "inline-flex",
                alignItems: "center",
                gap: "8px",
                padding: "8px 16px",
                borderRadius: "8px",
                border: "1px solid #cbd5e1",
                backgroundColor: "#ffffff",
                color: "#475569",
                fontSize: "13px",
                fontWeight: "600",
                cursor: "pointer",
                transition: "all 0.2s ease"
              }}
            >
              <ArrowLeft size={16} /> Back to Safety Clearance
            </button>
          </div>

          {/* Form Body */}
          <form onSubmit={handleCreateInduction} style={{ padding: "28px" }}>
            <div style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))",
              gap: "20px",
              marginBottom: "24px"
            }}>
              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Visitor Full Name *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.visitorName}
                  onChange={(e) => setFormData({ ...formData, visitorName: e.target.value })}
                  placeholder="e.g. Ramesh Chandra"
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Organization / Company *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.organization}
                  onChange={(e) => setFormData({ ...formData, organization: e.target.value })}
                  placeholder="e.g. Siemens Automation"
                  required
                />
              </div>

              <div style={{ gridColumn: "1 / -1" }}>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Induction Officer (HSE)
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.inductedBy}
                  onChange={(e) => setFormData({ ...formData, inductedBy: e.target.value })}
                />
              </div>
            </div>

            {/* PPE Kit Verification */}
            <div style={{
              padding: "20px",
              backgroundColor: "#f8fafc",
              border: "1px solid #e2e8f0",
              borderRadius: "10px",
              marginBottom: "20px"
            }}>
              <div style={{ fontWeight: "700", fontSize: "13.5px", color: "#1e293b", marginBottom: "12px", display: "flex", alignItems: "center", gap: "8px" }}>
                <ShieldCheck size={18} color="#059669" /> PPE Safety Kit Verification Checklist
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "12px" }}>
                <label style={{ display: "flex", alignItems: "center", gap: "8px", fontSize: "13px", color: "#334155", cursor: "pointer" }}>
                  <input
                    type="checkbox"
                    checked={formData.ppeChecklist.hardHat}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        ppeChecklist: { ...formData.ppeChecklist, hardHat: e.target.checked }
                      })
                    }
                  />
                  <span>Industrial Hard Hat (Yellow / White)</span>
                </label>
                <label style={{ display: "flex", alignItems: "center", gap: "8px", fontSize: "13px", color: "#334155", cursor: "pointer" }}>
                  <input
                    type="checkbox"
                    checked={formData.ppeChecklist.hiVisVest}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        ppeChecklist: { ...formData.ppeChecklist, hiVisVest: e.target.checked }
                      })
                    }
                  />
                  <span>Fluorescent Reflective Hi-Vis Safety Vest</span>
                </label>
                <label style={{ display: "flex", alignItems: "center", gap: "8px", fontSize: "13px", color: "#334155", cursor: "pointer" }}>
                  <input
                    type="checkbox"
                    checked={formData.ppeChecklist.safetyShoes}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        ppeChecklist: { ...formData.ppeChecklist, safetyShoes: e.target.checked }
                      })
                    }
                  />
                  <span>Anti-static Steel-Toe Safety Boots</span>
                </label>
                <label style={{ display: "flex", alignItems: "center", gap: "8px", fontSize: "13px", color: "#334155", cursor: "pointer" }}>
                  <input
                    type="checkbox"
                    checked={formData.ppeChecklist.gasMonitor}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        ppeChecklist: { ...formData.ppeChecklist, gasMonitor: e.target.checked }
                      })
                    }
                  />
                  <span>Personal H2S & LEL Toxic Gas Monitor Badge</span>
                </label>
              </div>
            </div>

            {/* Emergency Briefing Confirmation */}
            <div style={{
              padding: "16px 20px",
              backgroundColor: "#ecfdf5",
              border: "1px solid #a7f3d0",
              borderRadius: "10px",
              marginBottom: "24px"
            }}>
              <label style={{ display: "flex", alignItems: "center", gap: "10px", cursor: "pointer", fontSize: "13.5px", fontWeight: "600", color: "#065f46" }}>
                <input
                  type="checkbox"
                  checked={formData.hazardBriefingCompleted}
                  onChange={(e) =>
                    setFormData({ ...formData, hazardBriefingCompleted: e.target.checked })
                  }
                />
                <span>Visitor has been verbally briefed on the Plant Emergency Siren & Assembly Point A</span>
              </label>
            </div>

            {/* Bottom Form Actions */}
            <div style={{
              display: "flex",
              justifyContent: "flex-end",
              alignItems: "center",
              gap: "12px",
              paddingTop: "20px",
              borderTop: "1px solid #e2e8f0"
            }}>
              <button
                type="button"
                onClick={() => setIsModalOpen(false)}
                style={{
                  padding: "10px 20px",
                  borderRadius: "8px",
                  border: "1px solid #cbd5e1",
                  backgroundColor: "#ffffff",
                  color: "#475569",
                  fontWeight: "600",
                  cursor: "pointer",
                  fontSize: "13.5px"
                }}
              >
                Cancel
              </button>
              <button
                type="submit"
                style={{
                  padding: "10px 24px",
                  borderRadius: "8px",
                  border: "none",
                  backgroundColor: "#059669",
                  color: "#ffffff",
                  fontWeight: "600",
                  cursor: "pointer",
                  fontSize: "13.5px",
                  display: "inline-flex",
                  alignItems: "center",
                  gap: "8px",
                  boxShadow: "0 2px 6px rgba(5, 150, 105, 0.3)"
                }}
              >
                <Save size={16} />
                Issue Safety Clearance
              </button>
            </div>
          </form>
        </div>
      ) : (
        <>
          {/* Safety Warning Card */}
          <div className="vm-alert-banner alert-warning mb-4">
        <div className="d-flex align-items-center gap-3">
          <Flame size={24} className="text-amber-600 flex-shrink-0" />
          <div>
            <h4 className="m-0 font-bold text-amber-900" style={{ fontSize: "14px" }}>
              Biogas ATEX Zone Mandatory Safety Protocol
            </h4>
            <p className="m-0 text-amber-800 text-xs mt-0.5">
              Strict adherence to IS 15464 standards. Hard Hat, Hi-Vis Vest, and Anti-Static Safety Footwear are compulsory for anyone proceeding beyond the security lobby. Smoking or spark generation inside the digestion perimeter constitutes a criminal violation.
            </p>
          </div>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="vm-kpi-grid">
        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#d1fae5", color: "#059669" }}>
            <FileCheck2 size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Safety Clearances Issued</h3>
            <span className="vm-kpi-value text-emerald-700">{safetyLogs.length}</span>
          </div>
        </div>
        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#dbeafe", color: "#2563eb" }}>
            <ShieldCheck size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>HSE Inducted Rate</h3>
            <span className="vm-kpi-value text-blue-700">
              {safetyLogs.length > 0 ? "100%" : "--"}
            </span>
          </div>
        </div>
        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#fee2e2", color: "#dc2626" }}>
            <Activity size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Gas Detectors Deployed</h3>
            <span className="vm-kpi-value text-red-600">
              {safetyLogs.filter((s) => s.ppeChecklist?.gasMonitor).length} Active Badges
            </span>
          </div>
        </div>
      </div>

      {/* Search Bar */}
      <div className="vm-controls-card mb-4">
        <input
          type="text"
          placeholder="Search safety clearances by visitor name, company, or clearance ID..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="vm-input-text w-100"
        />
      </div>

      {/* Table */}
      <div className="vm-table-card">
        <div className="vm-table-responsive">
          <table className="vm-data-table">
            <thead>
              <tr>
                <th>Clearance ID & Date</th>
                <th>Visitor Name</th>
                <th>Organization</th>
                <th>Induction Officer</th>
                <th>Hazard Briefing</th>
                <th>PPE Issued Checklist</th>
                <th>Emergency Briefing</th>
                <th>Clearance Status</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan="8" className="text-center py-6 text-slate-500">
                    <div className="d-flex flex-column align-items-center justify-content-center py-4">
                      <ShieldCheck size={36} className="text-slate-300 mb-2" />
                      <div className="font-semibold text-slate-700">No safety induction clearances issued</div>
                      <p className="text-xs text-slate-400 mt-1 mb-0">Click "Record Safety Induction" above to issue PPE and sign off clearances.</p>
                    </div>
                  </td>
                </tr>
              ) : (
                filtered.map((log) => (
                <tr key={log.id}>
                  <td>
                    <span className="font-mono font-bold text-emerald-800 text-xs">{log.id}</span>
                    <div className="text-xs text-slate-500">{log.inductionDate} {log.inductionTime}</div>
                  </td>
                  <td>
                    <div className="font-bold text-slate-900 text-xs">{log.visitorName}</div>
                  </td>
                  <td>
                    <div className="text-xs font-semibold text-slate-800">{log.organization}</div>
                  </td>
                  <td>
                    <div className="text-xs font-medium text-slate-700">{log.inductedBy}</div>
                  </td>
                  <td>
                    {log.hazardBriefingCompleted ? (
                      <span className="text-xs text-emerald-700 font-bold d-flex align-items-center gap-1">
                        <CheckCircle2 size={13} /> Completed
                      </span>
                    ) : (
                      <span className="text-xs text-red-600 font-bold">Pending</span>
                    )}
                  </td>
                  <td>
                    <div className="d-flex flex-wrap gap-1">
                      {log.ppeChecklist?.hardHat && <span className="vm-zone-tag">Helmet</span>}
                      {log.ppeChecklist?.hiVisVest && <span className="vm-zone-tag">Hi-Vis</span>}
                      {log.ppeChecklist?.safetyShoes && <span className="vm-zone-tag">Shoes</span>}
                      {log.ppeChecklist?.gasMonitor && (
                        <span className="vm-zone-tag" style={{ backgroundColor: "#fee2e2", color: "#dc2626" }}>
                          H2S Monitor
                        </span>
                      )}
                    </div>
                  </td>
                  <td>
                    {log.emergencyBriefed ? (
                      <span className="text-xs text-slate-700 font-medium">Assembly Point-A</span>
                    ) : (
                      <span className="text-xs text-slate-400">Not Briefed</span>
                    )}
                  </td>
                  <td>
                    <span className="vm-status-badge badge-cleared text-xs">
                      {log.status}
                    </span>
                  </td>
                </tr>
              )))}
            </tbody>
          </table>
        </div>
      </div>
        </>
      )}
    </div>
  );
};

export default SafetyClearance;

