import React, { useState, useEffect } from "react";
import {
  Calendar,
  Clock,
  Plus,
  CheckCircle2,
  XCircle,
  Building,
  UserCheck,
  MapPin,
  Bell,
  Search,
  X,
  ArrowLeft,
  Save
} from "lucide-react";
import {
  STORAGE_KEYS,
  INITIAL_APPOINTMENTS,
  getStoredData,
  saveStoredData
} from "./visitorData";

const AppointmentManagement = ({ onNavigate }) => {
  const [appointments, setAppointments] = useState(() =>
    getStoredData(STORAGE_KEYS.APPOINTMENTS, INITIAL_APPOINTMENTS)
  );

  useEffect(() => {
    const handleUpdate = () => {
      setAppointments(getStoredData(STORAGE_KEYS.APPOINTMENTS, INITIAL_APPOINTMENTS));
    };
    window.addEventListener("bionova_visitor_updated", handleUpdate);
    return () => window.removeEventListener("bionova_visitor_updated", handleUpdate);
  }, []);

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");

  const [formData, setFormData] = useState({
    visitorName: "",
    organization: "",
    phone: "",
    hostEmployee: "Rajesh Kumar (Plant Operations Head)",
    plantLocation: "Plant 1 - Hyderabad East CBG",
    scheduledDate: new Date().toISOString().slice(0, 10),
    scheduledTime: "11:00 AM - 01:00 PM",
    venue: "Main Conference Room",
    type: "Technical Meeting",
    status: "Confirmed",
    sendNotification: true
  });

  const handleCreateAppointment = (e) => {
    e.preventDefault();
    if (!formData.visitorName.trim()) return;

    const newApt = {
      id: `APT-2026-${440 + appointments.length + 1}`,
      ...formData
    };

    const updated = [newApt, ...appointments];
    setAppointments(updated);
    saveStoredData(STORAGE_KEYS.APPOINTMENTS, updated);
    setIsModalOpen(false);
  };

  const handleStatusChange = (id, newStatus) => {
    const updated = appointments.map((a) => (a.id === id ? { ...a, status: newStatus } : a));
    setAppointments(updated);
    saveStoredData(STORAGE_KEYS.APPOINTMENTS, updated);
  };

  const filtered = appointments.filter(
    (a) =>
      a.visitorName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      a.organization.toLowerCase().includes(searchTerm.toLowerCase()) ||
      a.hostEmployee.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="vm-submodule-container">
      {/* Header */}
      <div className="vm-section-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="vm-section-desc" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Coordinate plant site visits, executive meetings, conference room bookings, and security passes.
        </p>
        <button onClick={() => setIsModalOpen(true)} className="vm-btn-primary text-xs" style={{ flexShrink: 0, marginLeft: "auto" }}>
          <Plus size={16} /> Schedule New Appointment
        </button>
      </div>

      {/* If isModalOpen is true, render Full-Page Form Card. Otherwise, render cards */}
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
                <Calendar size={22} color="#2563eb" />
                Schedule Visitor Appointment
              </h2>
              <p style={{ margin: "4px 0 0 0", fontSize: "13.5px", color: "#64748b" }}>
                Coordinate plant site visits, executive meetings, conference room bookings, and security passes.
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
              <ArrowLeft size={16} /> Back to Appointments
            </button>
          </div>

          {/* Form Body */}
          <form onSubmit={handleCreateAppointment} style={{ padding: "28px" }}>
            <div style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))",
              gap: "20px",
              marginBottom: "24px"
            }}>
              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Visitor Name *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.visitorName}
                  onChange={(e) => setFormData({ ...formData, visitorName: e.target.value })}
                  placeholder="e.g. Ritu Singhal"
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
                  placeholder="e.g. State Bank of India"
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Visitor Phone Number
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  placeholder="e.g. +91 98765 43210"
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Host Employee *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.hostEmployee}
                  onChange={(e) => setFormData({ ...formData, hostEmployee: e.target.value })}
                  placeholder="e.g. Rajesh Kumar"
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Scheduled Date *
                </label>
                <input
                  type="date"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.scheduledDate}
                  onChange={(e) => setFormData({ ...formData, scheduledDate: e.target.value })}
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Time Slot *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.scheduledTime}
                  onChange={(e) => setFormData({ ...formData, scheduledTime: e.target.value })}
                  placeholder="e.g. 11:00 AM - 01:00 PM"
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Meeting Venue / Room *
                </label>
                <input
                  type="text"
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.venue}
                  onChange={(e) => setFormData({ ...formData, venue: e.target.value })}
                  placeholder="e.g. Main Conference Room"
                  required
                />
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Appointment Purpose / Type
                </label>
                <select
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.type}
                  onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                >
                  <option value="Technical Meeting">Technical Meeting</option>
                  <option value="Vendor Discussion">Vendor Discussion</option>
                  <option value="Executive Review">Executive Review</option>
                  <option value="Safety Inspection">Safety Inspection</option>
                  <option value="General Visit">General Visit</option>
                </select>
              </div>

              <div>
                <label style={{ display: "block", fontSize: "12.5px", fontWeight: "600", color: "#334155", marginBottom: "6px" }}>
                  Plant Facility
                </label>
                <select
                  style={{ width: "100%", padding: "9px 12px", borderRadius: "8px", border: "1px solid #cbd5e1", fontSize: "13.5px", backgroundColor: "#ffffff", boxSizing: "border-box" }}
                  value={formData.plantLocation}
                  onChange={(e) => setFormData({ ...formData, plantLocation: e.target.value })}
                >
                  <option value="Plant 1 - Hyderabad East CBG">Plant 1 - Hyderabad East CBG</option>
                  <option value="Plant 2 - Medak Agri Hub">Plant 2 - Medak Agri Hub</option>
                  <option value="Plant 3 - Nalgonda Biomass Facility">Plant 3 - Nalgonda Biomass Facility</option>
                </select>
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
                <Save size={16} />
                Confirm & Schedule Appointment
              </button>
            </div>
          </form>
        </div>
      ) : (
        <>
          {/* Appointment Cards Grid */}
          <div className="vm-controls-card mb-4">
        <div className="d-flex justify-content-between align-items-center">
          <input
            type="text"
            placeholder="Search scheduled visitor appointments..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="vm-input-text flex-1"
            style={{ maxWidth: "380px" }}
          />
          <div className="text-xs text-slate-500 font-semibold">
            Showing {filtered.length} Scheduled Appointment(s)
          </div>
        </div>
      </div>

      <div className="row g-3">
        {filtered.length === 0 ? (
          <div className="col-12">
            <div className="vm-card p-5 text-center text-slate-500">
              <Calendar size={36} className="text-slate-300 mb-2 mx-auto" />
              <div className="font-semibold text-slate-700">No scheduled appointments</div>
              <p className="text-xs text-slate-400 mt-1 mb-0">Use "Book Appointment" above to schedule a visit.</p>
            </div>
          </div>
        ) : (
          filtered.map((apt) => (
          <div key={apt.id} className="col-12 col-md-6 col-lg-4">
            <div className="vm-card h-100 p-4 d-flex flex-column justify-content-between">
              <div>
                <div className="d-flex justify-content-between align-items-start mb-2">
                  <span className="font-mono text-xs font-bold text-blue-700 bg-blue-50 px-2 py-0.5 rounded">
                    {apt.id}
                  </span>
                  <span
                    className={`vm-status-badge ${
                      apt.status === "Confirmed" ? "badge-cleared" : "badge-pending"
                    }`}
                  >
                    {apt.status}
                  </span>
                </div>

                <h4 className="font-bold text-slate-900 m-0 mb-1" style={{ fontSize: "15px" }}>
                  {apt.visitorName}
                </h4>
                <div className="text-xs text-slate-600 mb-3">{apt.organization}</div>

                <div className="d-flex flex-column gap-1.5 text-xs text-slate-700 pt-2 border-t border-slate-100">
                  <div className="d-flex align-items-center gap-2">
                    <Calendar size={13} className="text-blue-500 flex-shrink-0" />
                    <span>{apt.scheduledDate}</span>
                  </div>
                  <div className="d-flex align-items-center gap-2">
                    <Clock size={13} className="text-amber-500 flex-shrink-0" />
                    <span>{apt.scheduledTime}</span>
                  </div>
                  <div className="d-flex align-items-center gap-2">
                    <MapPin size={13} className="text-emerald-500 flex-shrink-0" />
                    <span>{apt.venue}</span>
                  </div>
                  <div className="d-flex align-items-center gap-2">
                    <UserCheck size={13} className="text-indigo-500 flex-shrink-0" />
                    <span>Host: {apt.hostEmployee}</span>
                  </div>
                </div>
              </div>

              <div className="d-flex justify-content-between align-items-center pt-3 mt-3 border-t border-slate-100">
                <span className="text-xs font-semibold text-slate-500">{apt.type}</span>
                <div className="d-flex gap-1">
                  {apt.status !== "Confirmed" && (
                    <button
                      onClick={() => handleStatusChange(apt.id, "Confirmed")}
                      className="vm-btn-secondary text-xs"
                      style={{ padding: "4px 8px", borderColor: "#10b981", color: "#047857" }}
                    >
                      Confirm
                    </button>
                  )}
                  {apt.status !== "Cancelled" && (
                    <button
                      onClick={() => handleStatusChange(apt.id, "Cancelled")}
                      className="vm-btn-secondary text-xs"
                      style={{ padding: "4px 8px", color: "#dc2626" }}
                    >
                      Cancel
                    </button>
                  )}
                </div>
              </div>
            </div>
          </div>
        )))}
      </div>
        </>
      )}
    </div>
  );
};

export default AppointmentManagement;

