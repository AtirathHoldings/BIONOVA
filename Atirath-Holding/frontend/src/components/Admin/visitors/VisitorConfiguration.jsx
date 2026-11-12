import React, { useState } from "react";
import {
  Settings,
  ShieldAlert,
  Clock,
  Save,
  Plus,
  Trash2,
  CheckCircle2,
  UserX,
  Building,
  Lock
} from "lucide-react";
import {
  STORAGE_KEYS,
  INITIAL_CONFIG,
  getStoredData,
  saveStoredData
} from "./visitorData";

const VisitorConfiguration = ({ onNavigate }) => {
  const [config, setConfig] = useState(() =>
    getStoredData(STORAGE_KEYS.CONFIG, INITIAL_CONFIG)
  );

  const [saveSuccess, setSaveSuccess] = useState(false);
  const [newBlacklist, setNewBlacklist] = useState({
    name: "",
    reason: "",
    date: new Date().toISOString().slice(0, 10),
    idType: ""
  });

  const handleConfigChange = (field, value) => {
    setConfig((prev) => ({ ...prev, [field]: value }));
  };

  const handleSaveSettings = (e) => {
    e.preventDefault();
    saveStoredData(STORAGE_KEYS.CONFIG, config);
    setSaveSuccess(true);
    setTimeout(() => setSaveSuccess(false), 4000);
  };

  const handleAddBlacklist = (e) => {
    e.preventDefault();
    if (!newBlacklist.name.trim() || !newBlacklist.reason.trim()) return;

    const updated = {
      ...config,
      blacklistedVisitors: [...(config.blacklistedVisitors || []), newBlacklist]
    };
    setConfig(updated);
    saveStoredData(STORAGE_KEYS.CONFIG, updated);
    setNewBlacklist({
      name: "",
      reason: "",
      date: new Date().toISOString().slice(0, 10),
      idType: ""
    });
  };

  const handleRemoveBlacklist = (index) => {
    const updated = {
      ...config,
      blacklistedVisitors: config.blacklistedVisitors.filter((_, i) => i !== index)
    };
    setConfig(updated);
    saveStoredData(STORAGE_KEYS.CONFIG, updated);
  };

  return (
    <div className="vm-submodule-container">
      {/* Header */}
      <div className="vm-section-header" style={{ marginBottom: "20px" }}>
        <p className="vm-section-desc" style={{ margin: 0, color: "#64748b", fontSize: "14px" }}>
          Define system-wide perimeter rules, maximum pass validity limits, visiting hours, and barred individuals.
        </p>
      </div>

      {saveSuccess && (
        <div className="vm-alert-banner alert-success mb-4">
          <CheckCircle2 size={18} className="text-emerald-600" />
          <span className="text-xs font-semibold text-emerald-800">
            Perimeter security configuration successfully updated and saved!
          </span>
        </div>
      )}

      <form onSubmit={handleSaveSettings}>
        {/* General Policy Settings */}
        <div className="vm-form-card mb-4">
          <div className="vm-form-card-title">
            <Clock size={18} className="text-blue-600" />
            1. Pass Duration & Gate Timing Policies
          </div>
          <div className="vm-form-grid">
            <div className="vm-form-group">
              <label>Maximum Allowed Pass Duration (Hours)</label>
              <input
                type="number"
                min="1"
                max="24"
                value={config.maxPassDurationHours}
                onChange={(e) => handleConfigChange("maxPassDurationHours", Number(e.target.value))}
              />
            </div>

            <div className="vm-form-group">
              <label>Auto-Overdue Trigger Threshold (Minutes after expiry)</label>
              <input
                type="number"
                min="5"
                max="120"
                value={config.autoOverdueThresholdMinutes}
                onChange={(e) => handleConfigChange("autoOverdueThresholdMinutes", Number(e.target.value))}
              />
            </div>

            <div className="vm-form-group">
              <label>Security Gate Opening Time</label>
              <input
                type="text"
                value={config.gateOpeningTime}
                onChange={(e) => handleConfigChange("gateOpeningTime", e.target.value)}
              />
            </div>

            <div className="vm-form-group">
              <label>Security Gate Curfew Closing Time</label>
              <input
                type="text"
                value={config.gateClosingTime}
                onChange={(e) => handleConfigChange("gateClosingTime", e.target.value)}
              />
            </div>
          </div>
        </div>

        {/* Security Compliance Enforcements */}
        <div className="vm-form-card mb-4">
          <div className="vm-form-card-title">
            <Lock size={18} className="text-emerald-600" />
            2. Mandatory Intake Verification Enforcements
          </div>
          <div className="d-flex flex-column gap-3 p-2">
            <label className="d-flex align-items-center gap-2 cursor-pointer text-xs font-bold text-slate-800">
              <input
                type="checkbox"
                checked={config.requireGovtId}
                onChange={(e) => handleConfigChange("requireGovtId", e.target.checked)}
              />
              <span>Enforce Mandatory Government Photo ID (Aadhaar / DL / Passport) for all entries</span>
            </label>

            <label className="d-flex align-items-center gap-2 cursor-pointer text-xs font-bold text-slate-800">
              <input
                type="checkbox"
                checked={config.requireSafetyInduction}
                onChange={(e) => handleConfigChange("requireSafetyInduction", e.target.checked)}
              />
              <span>Mandate Verbal HSE Safety Induction & Sign-off before turnstile release</span>
            </label>

            <label className="d-flex align-items-center gap-2 cursor-pointer text-xs font-bold text-slate-800">
              <input
                type="checkbox"
                checked={config.requireHostApprovalForVendors}
                onChange={(e) => handleConfigChange("requireHostApprovalForVendors", e.target.checked)}
              />
              <span>Require Host Employee Direct Approval for all Vendor & Technical Contractor Passes</span>
            </label>
          </div>
        </div>

        <div className="d-flex justify-content-end mb-4">
          <button type="submit" className="vm-btn-primary text-xs">
            <Save size={15} /> Save Policy Configuration
          </button>
        </div>
      </form>

      {/* Blacklist / Barred Personnel Management */}
      <div className="vm-form-card">
        <div className="vm-form-card-title text-red-700">
          <UserX size={18} className="text-red-600" />
          3. Barred & Blacklisted Individuals Registry
        </div>
        <p className="text-xs text-slate-500 mb-3">
          Individuals in this register are automatically blocked at Gate Check-In desks with security breach alerts.
        </p>

        <form onSubmit={handleAddBlacklist} className="p-3 bg-red-50 border border-red-200 rounded-xl mb-4">
          <div className="vm-form-grid mb-3">
            <div className="vm-form-group">
              <label>Individual Full Name *</label>
              <input
                type="text"
                value={newBlacklist.name}
                onChange={(e) => setNewBlacklist({ ...newBlacklist, name: e.target.value })}
                placeholder="e.g. Sunil Rawat"
                required
              />
            </div>
            <div className="vm-form-group">
              <label>Govt ID Number (If Known)</label>
              <input
                type="text"
                value={newBlacklist.idType}
                onChange={(e) => setNewBlacklist({ ...newBlacklist, idType: e.target.value })}
                placeholder="Aadhaar: XXXX-4910"
              />
            </div>
            <div className="vm-form-group" style={{ gridColumn: "1 / -1" }}>
              <label>Violation / Incident Reason *</label>
              <input
                type="text"
                value={newBlacklist.reason}
                onChange={(e) => setNewBlacklist({ ...newBlacklist, reason: e.target.value })}
                placeholder="e.g. Severe safety infraction - Unauthorized smoking in ATEX zone"
                required
              />
            </div>
          </div>
          <div className="d-flex justify-content-end">
            <button type="submit" className="vm-btn-primary text-xs" style={{ background: "#dc2626" }}>
              <Plus size={14} /> Add to Blacklist
            </button>
          </div>
        </form>

        <div className="vm-table-responsive">
          <table className="vm-data-table">
            <thead>
              <tr>
                <th>Individual Name</th>
                <th>Known ID</th>
                <th>Incident Reason</th>
                <th>Incident Date</th>
                <th style={{ textAlign: "right" }}>Action</th>
              </tr>
            </thead>
            <tbody>
              {(config.blacklistedVisitors || []).map((b, i) => (
                <tr key={i}>
                  <td>
                    <span className="font-bold text-red-900 text-xs">{b.name}</span>
                  </td>
                  <td>
                    <span className="font-mono text-xs text-slate-600">{b.idType || "N/A"}</span>
                  </td>
                  <td>
                    <span className="text-xs text-slate-700">{b.reason}</span>
                  </td>
                  <td>
                    <span className="text-xs text-slate-500">{b.date}</span>
                  </td>
                  <td style={{ textAlign: "right" }}>
                    <button
                      onClick={() => handleRemoveBlacklist(i)}
                      className="vm-action-btn text-red-600"
                      title="Remove from Blacklist"
                    >
                      <Trash2 size={14} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default VisitorConfiguration;

