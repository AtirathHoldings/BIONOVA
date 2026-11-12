import React, { useState, useEffect } from "react";
import {
  CheckCircle2,
  XCircle,
  Clock,
  ShieldAlert,
  ShieldCheck,
  AlertTriangle,
  UserCheck,
  FileBadge,
  Eye,
  X,
  ArrowLeft,
  Save
} from "lucide-react";
import {
  STORAGE_KEYS,
  INITIAL_VISITORS,
  getStoredData,
  saveStoredData
} from "./visitorData";

const VisitorApproval = ({ onNavigate }) => {
  const [visitors, setVisitors] = useState(() =>
    getStoredData(STORAGE_KEYS.VISITORS, INITIAL_VISITORS)
  );

  const [selectedVisitor, setSelectedVisitor] = useState(null);
  const [approvalConditions, setApprovalConditions] = useState({
    escortRequired: true,
    escortName: "Srinivas Rao (HSE Officer)",
    zoneRestricted: true,
    ppeMandatory: true,
    remarks: "Approved for plant inspection under certified HSE escort."
  });

  const pendingList = visitors.filter((v) => v.status === "Pending Approval");

  const handleApprove = (v) => {
    const updated = visitors.map((item) => {
      if (item.id === v.id) {
        return {
          ...item,
          status: "Checked-In",
          actualInTime: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }),
          escortRequired: approvalConditions.escortRequired,
          escortName: approvalConditions.escortName,
          ppeIssued: true,
          remarks: approvalConditions.remarks
        };
      }
      return item;
    });

    setVisitors(updated);
    saveStoredData(STORAGE_KEYS.VISITORS, updated);
    setSelectedVisitor(null);
  };

  const handleReject = (id, reason) => {
    const updated = visitors.map((item) => {
      if (item.id === id) {
        return {
          ...item,
          status: "Rejected",
          remarks: reason || "Rejected by Plant Security Desk"
        };
      }
      return item;
    });

    setVisitors(updated);
    saveStoredData(STORAGE_KEYS.VISITORS, updated);
    setSelectedVisitor(null);
  };

  return (
    <div className="vm-submodule-container">
      {/* Header */}
      <div className="vm-section-header" style={{ marginBottom: "20px" }}>
        <p className="vm-section-desc" style={{ margin: 0, color: "#64748b", fontSize: "14px" }}>
          Review, endorse, and grant conditional perimeter clearance for visiting vendors, auditors, and contractors.
        </p>
      </div>

      {/* If selectedVisitor is truthy, render Full-Page Approval Review Form. Otherwise, render Table & KPIs */}
      {selectedVisitor ? (
        <div style={{
          backgroundColor: "#ffffff",
          borderRadius: "14px",
          border: "1px solid #e2e8f0",
          boxShadow: "0 1px 3px rgba(0, 0, 0, 0.05)",
          overflow: "hidden",
          marginTop: "10px"
        }}>
          {/* Header with Back Button */}
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
                <ShieldCheck size={22} color="#2563eb" />
                Authorize Visitor Entry: {selectedVisitor.name}
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Review visitor credentials, specify safety conditions, assign escort officers, and grant or reject plant perimeter access.
              </p>
            </div>
            <button
              type="button"
              onClick={() => setSelectedVisitor(null)}
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
              <ArrowLeft size={16} /> Back to Approval Desk
            </button>
          </div>

          {/* Form Body */}
          <div style={{ padding: "28px" }}>
            {/* Visitor Summary Strip */}
            <div style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
              gap: "16px",
              padding: "18px 20px",
              backgroundColor: "#eff6ff",
              border: "1px solid #bfdbfe",
              borderRadius: "10px",
              marginBottom: "24px"
            }}>
              <div>
                <span style={{ fontSize: "12px", color: "#1e40af", fontWeight: "600", display: "block" }}>Pass Number</span>
                <span style={{ fontFamily: "monospace", fontWeight: "700", fontSize: "15px", color: "#1d4ed8" }}>{selectedVisitor.passNo}</span>
              </div>
              <div>
                <span style={{ fontSize: "12px", color: "#1e40af", fontWeight: "600", display: "block" }}>Visitor Name</span>
                <span style={{ fontWeight: "700", fontSize: "14px", color: "#1e293b" }}>{selectedVisitor.name}</span>
              </div>
              <div>
                <span style={{ fontSize: "12px", color: "#1e40af", fontWeight: "600", display: "block" }}>Organization</span>
                <span style={{ fontWeight: "600", fontSize: "13.5px", color: "#334155" }}>{selectedVisitor.organization}</span>
              </div>
              <div>
                <span style={{ fontSize: "12px", color: "#1e40af", fontWeight: "600", display: "block" }}>Category</span>
                <span style={{ fontWeight: "600", fontSize: "13.5px", color: "#334155" }}>{selectedVisitor.category}</span>
              </div>
              <div>
                <span style={{ fontSize: "12px", color: "#1e40af", fontWeight: "600", display: "block" }}>Host Employee</span>
                <span style={{ fontWeight: "600", fontSize: "13.5px", color: "#334155" }}>{selectedVisitor.hostEmployee}</span>
              </div>
              <div>
                <span style={{ fontSize: "12px", color: "#1e40af", fontWeight: "600", display: "block" }}>Purpose of Visit</span>
                <span style={{ fontWeight: "600", fontSize: "13.5px", color: "#334155" }}>{selectedVisitor.purpose}</span>
              </div>
            </div>

            {/* Approval Conditions */}
            <div style={{
              display: "flex",
              flexDirection: "column",
              gap: "18px",
              marginBottom: "24px"
            }}>
              <div style={{
                padding: "16px 20px",
                backgroundColor: "#f8fafc",
                border: "1px solid #e2e8f0",
                borderRadius: "10px"
              }}>
                <label style={{ display: "flex", alignItems: "center", gap: "10px", cursor: "pointer", fontSize: "13.5px", fontWeight: "700", color: "#1e293b" }}>
                  <input
                    type="checkbox"
                    checked={approvalConditions.escortRequired}
                    onChange={(e) =>
                      setApprovalConditions({ ...approvalConditions, escortRequired: e.target.checked })
                    }
                  />
                  <span>Mandatory Security / HSE Escort Required within Plant Premises</span>
                </label>
                {approvalConditions.escortRequired && (
                  <div style={{ marginTop: "12px", marginLeft: "24px" }}>
                    <label style={{ display: "block", fontSize: "12px", fontWeight: "600", color: "#475569", marginBottom: "4px" }}>
                      Assigned Escort Officer Name:
                    </label>
                    <input
                      type="text"
                      value={approvalConditions.escortName}
                      onChange={(e) =>
                        setApprovalConditions({ ...approvalConditions, escortName: e.target.value })
                      }
                      style={{ width: "100%", maxWidth: "420px", padding: "8px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff" }}
                      placeholder="e.g. Srinivas Rao (HSE Officer)"
                    />
                  </div>
                )}
              </div>

              <div style={{
                padding: "16px 20px",
                backgroundColor: "#f8fafc",
                border: "1px solid #e2e8f0",
                borderRadius: "10px"
              }}>
                <label style={{ display: "flex", alignItems: "center", gap: "10px", cursor: "pointer", fontSize: "13.5px", fontWeight: "700", color: "#1e293b" }}>
                  <input
                    type="checkbox"
                    checked={approvalConditions.ppeMandatory}
                    onChange={(e) =>
                      setApprovalConditions({ ...approvalConditions, ppeMandatory: e.target.checked })
                    }
                  />
                  <span>Mandatory PPE Inspection Complete (Hard Hat, Hi-Vis Vest, Anti-static Footwear)</span>
                </label>
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Approval Endorsement Remarks / Directives
                </label>
                <textarea
                  rows="3"
                  value={approvalConditions.remarks}
                  onChange={(e) =>
                    setApprovalConditions({ ...approvalConditions, remarks: e.target.value })
                  }
                  style={{ width: "100%", padding: "10px 14px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  placeholder="Enter endorsement details, safety restrictions, or justification notes..."
                />
              </div>
            </div>

            {/* Bottom Actions */}
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
                onClick={() => setSelectedVisitor(null)}
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
                type="button"
                onClick={() => handleReject(selectedVisitor.id, "Rejected by security supervisor")}
                style={{
                  padding: "10px 22px",
                  borderRadius: "8px",
                  border: "none",
                  backgroundColor: "#dc2626",
                  color: "#ffffff",
                  fontWeight: "600",
                  cursor: "pointer",
                  fontSize: "13.5px",
                  display: "inline-flex",
                  alignItems: "center",
                  gap: "8px"
                }}
              >
                <XCircle size={16} />
                Reject Entry
              </button>
              <button
                type="button"
                onClick={() => handleApprove(selectedVisitor)}
                style={{
                  padding: "10px 24px",
                  borderRadius: "8px",
                  border: "none",
                  backgroundColor: "#2563eb",
                  color: "#ffffff",
                  fontWeight: "600",
                  cursor: "pointer",
                  fontSize: "13.5px",
                  display: "inline-flex",
                  alignItems: "center",
                  gap: "8px",
                  boxShadow: "0 2px 6px rgba(37, 99, 235, 0.3)"
                }}
              >
                <CheckCircle2 size={16} />
                Grant Entry & Check-In
              </button>
            </div>
          </div>
        </div>
      ) : (
        <>
          {/* Pending Banner */}
          <div className="vm-kpi-grid mb-4">
        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#fef3c7", color: "#d97706" }}>
            <Clock size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Pending Clearances</h3>
            <span className="vm-kpi-value text-amber-600">{pendingList.length}</span>
          </div>
        </div>
        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#d1fae5", color: "#059669" }}>
            <CheckCircle2 size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Approved Today</h3>
            <span className="vm-kpi-value text-emerald-600">
              {visitors.filter((v) => v.status === "Checked-In" || v.status === "Checked-Out").length}
            </span>
          </div>
        </div>
        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#fee2e2", color: "#dc2626" }}>
            <ShieldAlert size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Rejected / Flagged</h3>
            <span className="vm-kpi-value text-red-600">
              {visitors.filter((v) => v.status === "Rejected").length}
            </span>
          </div>
        </div>
      </div>

      {/* Pending Table */}
      <div className="vm-table-card">
        <div className="vm-table-header-row">
          <div>
            <h3 className="vm-table-title">Visitors Awaiting Entry Approval</h3>
            <p className="vm-table-subtitle">Mandatory authorization required before Gate turnstile admission</p>
          </div>
        </div>

        <div className="vm-table-responsive">
          <table className="vm-data-table">
            <thead>
              <tr>
                <th>Pass No & Visitor</th>
                <th>Organization</th>
                <th>Category</th>
                <th>Host Employee</th>
                <th>Purpose of Visit</th>
                <th>Govt ID Verification</th>
                <th style={{ textAlign: "right" }}>Review & Actions</th>
              </tr>
            </thead>
            <tbody>
              {pendingList.length === 0 ? (
                <tr>
                  <td colSpan="7" className="text-center py-5 text-slate-500">
                    <CheckCircle2 size={32} className="text-emerald-500 mb-2 mx-auto" />
                    <div className="font-bold text-slate-800">All Visitor Clearances Up-to-Date</div>
                    <div className="text-xs text-slate-500">No visitors currently pending approval in the queue.</div>
                  </td>
                </tr>
              ) : (
                pendingList.map((v) => (
                  <tr key={v.id}>
                    <td>
                      <div className="font-bold text-slate-900">{v.name}</div>
                      <div className="font-mono text-xs text-blue-600 font-semibold">{v.passNo}</div>
                    </td>
                    <td>
                      <div className="text-xs font-semibold text-slate-800">{v.organization}</div>
                      <div className="text-xs text-slate-500">{v.phone}</div>
                    </td>
                    <td>
                      <span className="vm-badge-category">{v.visitorType}</span>
                    </td>
                    <td>
                      <div className="text-xs font-semibold text-slate-900">{v.hostEmployee}</div>
                      <div className="text-xs text-slate-500">{v.plantLocation}</div>
                    </td>
                    <td>
                      <div className="text-xs text-slate-700 max-w-xs">{v.purpose}</div>
                    </td>
                    <td>
                      <span className="text-xs font-mono font-semibold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">
                        {v.govtId}
                      </span>
                    </td>
                    <td style={{ textAlign: "right" }}>
                      <div className="d-flex justify-content-end gap-1">
                        <button
                          onClick={() => setSelectedVisitor(v)}
                          className="vm-btn-primary text-xs"
                          style={{ padding: "6px 12px" }}
                        >
                          Review & Authorize
                        </button>
                        <button
                          onClick={() => handleReject(v.id, "Security criteria not met")}
                          className="vm-action-btn text-red-600"
                          title="Quick Reject"
                        >
                          <XCircle size={16} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
        </>
      )}
    </div>
  );
};

export default VisitorApproval;

