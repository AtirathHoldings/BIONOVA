import React, { useState, useEffect } from "react";
import {
  FileText,
  Plus,
  Clock,
  CheckCircle2,
  XCircle,
  AlertCircle,
  Building,
  UserCheck,
  Calendar,
  Send,
  Eye,
  X,
  ArrowLeft,
  Save
} from "lucide-react";
import {
  STORAGE_KEYS,
  INITIAL_REQUESTS,
  getStoredData,
  saveStoredData
} from "./visitorData";

const VisitRequest = ({ onNavigate }) => {
  const [requests, setRequests] = useState(() =>
    getStoredData(STORAGE_KEYS.REQUESTS, INITIAL_REQUESTS)
  );

  useEffect(() => {
    const handleUpdate = () => {
      setRequests(getStoredData(STORAGE_KEYS.REQUESTS, INITIAL_REQUESTS));
    };
    window.addEventListener("bionova_visitor_updated", handleUpdate);
    return () => window.removeEventListener("bionova_visitor_updated", handleUpdate);
  }, []);

  const [isNewModalOpen, setIsNewModalOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const [filterStatus, setFilterStatus] = useState("All");

  const [formData, setFormData] = useState({
    requesterName: "",
    organization: "",
    email: "",
    phone: "",
    visitorCategory: "Vendor / OEM Specialist",
    hostName: "Rajesh Kumar (Plant Operations Head)",
    plantLocation: "Plant 1 - Hyderabad East CBG",
    requestedDate: new Date().toISOString().slice(0, 10),
    requestedTime: "11:00 AM",
    purpose: "",
    visitorCount: 1
  });

  const handleStatusChange = (id, newStatus) => {
    const updated = requests.map((r) => (r.id === id ? { ...r, status: newStatus } : r));
    setRequests(updated);
    saveStoredData(STORAGE_KEYS.REQUESTS, updated);
  };

  const handleCreateRequest = (e) => {
    e.preventDefault();
    if (!formData.requesterName.trim() || !formData.organization.trim()) return;

    const newReq = {
      id: `VR-2026-${String(requests.length + 104).padStart(4, "0")}`,
      ...formData,
      status: "Under Review",
      submittedAt: new Date().toLocaleString()
    };

    const updated = [newReq, ...requests];
    setRequests(updated);
    saveStoredData(STORAGE_KEYS.REQUESTS, updated);
    setIsNewModalOpen(false);
    setFormData({
      requesterName: "",
      organization: "",
      email: "",
      phone: "",
      visitorCategory: "Vendor / OEM Specialist",
      hostName: "Rajesh Kumar (Plant Operations Head)",
      plantLocation: "Plant 1 - Hyderabad East CBG",
      requestedDate: new Date().toISOString().slice(0, 10),
      requestedTime: "11:00 AM",
      purpose: "",
      visitorCount: 1
    });
  };

  const filteredRequests = requests.filter((r) => {
    const matchSearch =
      r.requesterName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      r.organization.toLowerCase().includes(searchTerm.toLowerCase()) ||
      r.id.toLowerCase().includes(searchTerm.toLowerCase());
    const matchStatus = filterStatus === "All" || r.status === filterStatus;
    return matchSearch && matchStatus;
  });

  return (
    <div className="vm-submodule-container">
      {/* Header */}
      <div className="vm-section-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="vm-section-desc" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Manage advance plant entry requests submitted by vendors, auditors, and external contractors.
        </p>
        <button onClick={() => setIsNewModalOpen(true)} className="vm-btn-primary text-xs" style={{ flexShrink: 0, marginLeft: "auto" }}>
          <Plus size={16} /> Submit New Visit Request
        </button>
      </div>

      {/* If isNewModalOpen is true, render Full-Page Form Card. Otherwise, render KPIs and Table */}
      {isNewModalOpen ? (
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
                <FileText size={22} color="#2563eb" />
                Submit Plant Visit Request
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Register advance security clearance and plant entry request for external contractors and visitors.
              </p>
            </div>
            <button
              type="button"
              onClick={() => setIsNewModalOpen(false)}
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
              <ArrowLeft size={16} /> Back to Visit Requests
            </button>
          </div>

          {/* Form Body */}
          <form onSubmit={handleCreateRequest} style={{ padding: "28px" }}>
            <div style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))",
              gap: "20px",
              marginBottom: "24px"
            }}>
              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Requester Name *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.requesterName}
                  onChange={(e) => setFormData({ ...formData, requesterName: e.target.value })}
                  placeholder="e.g. S. Radhakrishnan"
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
                  placeholder="e.g. Thermax Instrumentation"
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Official Email
                </label>
                <input
                  type="email"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  placeholder="e.g. s.radha@thermax.com"
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Phone Number
                </label>
                <input
                  type="tel"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  placeholder="e.g. +91 98490 00000"
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Requested Date *
                </label>
                <input
                  type="date"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.requestedDate}
                  onChange={(e) => setFormData({ ...formData, requestedDate: e.target.value })}
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Requested Time
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.requestedTime}
                  onChange={(e) => setFormData({ ...formData, requestedTime: e.target.value })}
                  placeholder="e.g. 11:30 AM"
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Visitor Category
                </label>
                <select
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.visitorCategory}
                  onChange={(e) => setFormData({ ...formData, visitorCategory: e.target.value })}
                >
                  <option value="Vendor / OEM Specialist">Vendor / OEM Specialist</option>
                  <option value="Regulatory Inspector / Auditor">Regulatory Inspector / Auditor</option>
                  <option value="Contractor Team Lead">Contractor Team Lead</option>
                  <option value="Executive Client">Executive Client</option>
                  <option value="General Visitor">General Visitor</option>
                </select>
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Visitor Group Size
                </label>
                <input
                  type="number"
                  min="1"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.visitorCount}
                  onChange={(e) => setFormData({ ...formData, visitorCount: Number(e.target.value) })}
                />
              </div>

              <div style={{ gridColumn: "1 / -1" }}>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Purpose of Visit
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.purpose}
                  onChange={(e) => setFormData({ ...formData, purpose: e.target.value })}
                  placeholder="e.g. Biogas digester mixing nozzle technical inspection"
                />
              </div>
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
                onClick={() => setIsNewModalOpen(false)}
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
                <Send size={15} />
                Submit Visit Request
              </button>
            </div>
          </form>
        </div>
      ) : (
        <>
          {/* KPI Cards */}
          <div className="vm-kpi-grid">
        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#e0e7ff", color: "#4338ca" }}>
            <FileText size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Total Requests</h3>
            <span className="vm-kpi-value">{requests.length}</span>
          </div>
        </div>
        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#fef3c7", color: "#d97706" }}>
            <Clock size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Under Review</h3>
            <span className="vm-kpi-value text-amber-600">
              {requests.filter((r) => r.status === "Under Review" || r.status === "Pending Approval").length}
            </span>
          </div>
        </div>
        <div className="vm-kpi-card">
          <div className="vm-kpi-icon" style={{ backgroundColor: "#d1fae5", color: "#059669" }}>
            <CheckCircle2 size={22} />
          </div>
          <div className="vm-kpi-info">
            <h3>Approved Requests</h3>
            <span className="vm-kpi-value text-emerald-600">
              {requests.filter((r) => r.status === "Approved").length}
            </span>
          </div>
        </div>
      </div>

      {/* Filter Toolbar */}
      <div className="vm-controls-card mb-4">
        <div className="d-flex justify-content-between align-items-center flex-wrap gap-2">
          <input
            type="text"
            placeholder="Search request ID, requester, or organization..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="vm-input-text flex-1"
            style={{ maxWidth: "400px" }}
          />
          <div className="d-flex gap-2">
            {["All", "Under Review", "Approved", "Rejected"].map((st) => (
              <button
                key={st}
                onClick={() => setFilterStatus(st)}
                className={`vm-filter-pill ${filterStatus === st ? "active" : ""}`}
              >
                {st}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Request Table */}
      <div className="vm-table-card">
        <div className="vm-table-responsive">
          <table className="vm-data-table">
            <thead>
              <tr>
                <th>Request ID</th>
                <th>Requester Name</th>
                <th>Organization</th>
                <th>Requested Date & Time</th>
                <th>Host & Plant Site</th>
                <th>Delegates</th>
                <th>Status</th>
                <th style={{ textAlign: "right" }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredRequests.length === 0 ? (
                <tr>
                  <td colSpan="8" className="text-center py-6 text-slate-500">
                    <div className="d-flex flex-column align-items-center justify-content-center py-4">
                      <Clock size={36} className="text-slate-300 mb-2" />
                      <div className="font-semibold text-slate-700">No visit requests found</div>
                      <p className="text-xs text-slate-400 mt-1 mb-0">Use "Submit Visit Request" to log a new visitor request.</p>
                    </div>
                  </td>
                </tr>
              ) : (
                filteredRequests.map((req) => (
                <tr key={req.id}>
                  <td>
                    <span className="font-mono font-bold text-blue-700 text-xs">{req.id}</span>
                  </td>
                  <td>
                    <div className="font-bold text-slate-900">{req.requesterName}</div>
                    <div className="text-xs text-slate-500">{req.email}</div>
                  </td>
                  <td>
                    <div className="text-xs font-semibold text-slate-800">{req.organization}</div>
                    <div className="text-xs text-blue-600">{req.visitorCategory}</div>
                  </td>
                  <td>
                    <div className="text-xs font-semibold text-slate-900">{req.requestedDate}</div>
                    <div className="text-xs text-slate-500">{req.requestedTime}</div>
                  </td>
                  <td>
                    <div className="text-xs font-medium text-slate-900">{req.hostName}</div>
                    <div className="text-xs text-slate-500">{req.plantLocation}</div>
                  </td>
                  <td>
                    <span className="text-xs font-mono font-bold text-slate-700">
                      {req.visitorCount || 1} Person(s)
                    </span>
                  </td>
                  <td>
                    <span
                      className={`vm-status-badge ${
                        req.status === "Approved"
                          ? "badge-cleared"
                          : req.status === "Rejected"
                          ? "badge-danger"
                          : "badge-pending"
                      }`}
                    >
                      {req.status}
                    </span>
                  </td>
                  <td style={{ textAlign: "right" }}>
                    <div className="d-flex justify-content-end gap-1">
                      {req.status !== "Approved" && (
                        <button
                          onClick={() => handleStatusChange(req.id, "Approved")}
                          className="vm-action-btn text-emerald-600"
                          title="Approve Request"
                        >
                          <CheckCircle2 size={15} />
                        </button>
                      )}
                      {req.status !== "Rejected" && (
                        <button
                          onClick={() => handleStatusChange(req.id, "Rejected")}
                          className="vm-action-btn text-red-600"
                          title="Reject Request"
                        >
                          <XCircle size={15} />
                        </button>
                      )}
                    </div>
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

export default VisitRequest;

