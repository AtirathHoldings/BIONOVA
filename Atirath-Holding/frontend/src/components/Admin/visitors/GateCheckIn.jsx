import React, { useState, useEffect } from "react";
import {
  UserCheck,
  Search,
  CheckCircle2,
  AlertTriangle,
  HardHat,
  ShieldCheck,
  Clock,
  Printer,
  FileBadge,
  Sparkles
} from "lucide-react";
import {
  STORAGE_KEYS,
  INITIAL_VISITORS,
  getStoredData,
  saveStoredData,
  apiCheckInVisitor
} from "./visitorData";

const GateCheckIn = ({ onNavigate }) => {
  const [visitors, setVisitors] = useState(() =>
    getStoredData(STORAGE_KEYS.VISITORS, INITIAL_VISITORS)
  );

  useEffect(() => {
    const handleUpdate = () => {
      setVisitors(getStoredData(STORAGE_KEYS.VISITORS, INITIAL_VISITORS));
    };
    window.addEventListener("bionova_visitor_updated", handleUpdate);
    return () => window.removeEventListener("bionova_visitor_updated", handleUpdate);
  }, []);

  const [lookupQuery, setLookupQuery] = useState("");
  const [activeCheckInVisitor, setActiveCheckInVisitor] = useState(null);
  const [assignedRfid, setAssignedRfid] = useState("");
  const [ppeVerified, setPpeVerified] = useState(true);
  const [successBanner, setSuccessBanner] = useState("");

  const pendingOrOutVisitors = visitors.filter((v) => v.status !== "Checked-In");

  const handleSelectVisitor = (v) => {
    setActiveCheckInVisitor(v);
    setAssignedRfid(v.badgeRfid && v.badgeRfid !== "UNASSIGNED" ? v.badgeRfid : `RFID-${Math.floor(1000 + Math.random() * 9000)}`);
    setPpeVerified(v.ppeIssued || true);
  };

  const handlePerformCheckIn = (e) => {
    e.preventDefault();
    if (!activeCheckInVisitor) return;

    const inTime = new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
    const updated = visitors.map((v) => {
      if (v.id === activeCheckInVisitor.id) {
        return {
          ...v,
          status: "Checked-In",
          actualInTime: inTime,
          badgeRfid: assignedRfid,
          ppeIssued: ppeVerified
        };
      }
      return v;
    });

    setVisitors(updated);
    saveStoredData(STORAGE_KEYS.VISITORS, updated);
    if (activeCheckInVisitor.id) {
      apiCheckInVisitor(activeCheckInVisitor.id).catch(() => {});
    }
    setSuccessBanner(`${activeCheckInVisitor.name} (${activeCheckInVisitor.passNo}) successfully Checked-In at ${inTime}. RFID Badge: ${assignedRfid}`);
    setActiveCheckInVisitor(null);
    setLookupQuery("");
  };

  const searchedVisitors = pendingOrOutVisitors.filter((v) =>
    v.name.toLowerCase().includes(lookupQuery.toLowerCase()) ||
    v.passNo.toLowerCase().includes(lookupQuery.toLowerCase()) ||
    v.organization.toLowerCase().includes(lookupQuery.toLowerCase()) ||
    (v.phone && v.phone.includes(lookupQuery))
  );

  return (
    <div className="vm-submodule-container">
      {/* Header */}
      <div className="vm-section-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="vm-section-desc" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Fast-track gate check-in, identity validation, PPE issuing verification, and RFID badge assignment.
        </p>
        <button onClick={() => onNavigate("registration")} className="vm-btn-secondary text-xs" style={{ flexShrink: 0, marginLeft: "auto" }}>
          + New Visitor Intake
        </button>
      </div>

      {successBanner && (
        <div className="vm-alert-banner alert-success mb-4">
          <CheckCircle2 size={20} className="text-emerald-600" />
          <span className="text-xs font-semibold text-emerald-800">{successBanner}</span>
        </div>
      )}

      <div className="row g-4">
        {/* Left Column: Quick Lookup */}
        <div className="col-12 col-lg-5">
          <div className="vm-card p-4">
            <h3 className="text-base font-bold text-slate-900 mb-2">Gate Pass Lookup</h3>
            <p className="text-xs text-slate-500 mb-3">
              Scan pass barcode or search by name, mobile number, or company:
            </p>

            <div className="vm-search-box mb-3">
              <Search size={18} className="text-slate-400" />
              <input
                type="text"
                placeholder="Search pass number or visitor name..."
                value={lookupQuery}
                onChange={(e) => setLookupQuery(e.target.value)}
              />
            </div>

            <div className="text-xs font-bold text-slate-600 uppercase mb-2">
              Awaiting Check-In ({searchedVisitors.length})
            </div>

            <div className="d-flex flex-column gap-2" style={{ maxHeight: "380px", overflowY: "auto" }}>
              {searchedVisitors.length === 0 ? (
                <div className="text-center py-5 text-slate-400 text-xs">
                  No visitors awaiting gate check-in.
                </div>
              ) : (
                searchedVisitors.map((v) => (
                <div
                  key={v.id}
                  onClick={() => handleSelectVisitor(v)}
                  className={`p-3 rounded-xl border cursor-pointer transition-all ${
                    activeCheckInVisitor?.id === v.id
                      ? "border-emerald-500 bg-emerald-50"
                      : "border-slate-200 hover:bg-slate-50"
                  }`}
                >
                  <div className="d-flex justify-content-between align-items-start mb-1">
                    <span className="font-bold text-slate-900 text-sm">{v.name}</span>
                    <span className="font-mono text-xs font-bold text-blue-700">{v.passNo}</span>
                  </div>
                  <div className="text-xs text-slate-600 mb-1">{v.organization}</div>
                  <div className="d-flex justify-content-between text-xs text-slate-500">
                    <span>Host: {v.hostEmployee}</span>
                    <span className="badge-pending text-xs px-1.5 py-0.5 rounded">{v.status}</span>
                  </div>
                </div>
              )))}
            </div>
          </div>
        </div>

        {/* Right Column: Check-in processing */}
        <div className="col-12 col-lg-7">
          <div className="vm-card p-4">
            <h3 className="text-base font-bold text-slate-900 mb-2">Gate Security Check-In Verification</h3>
            <p className="text-xs text-slate-500 mb-4">
              Verify identity credentials and stamp physical turnstile entry.
            </p>

            {activeCheckInVisitor ? (
              <form onSubmit={handlePerformCheckIn}>
                <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 mb-4 text-xs">
                  <div className="d-flex justify-content-between mb-1.5">
                    <span className="text-slate-500">Visitor Full Name:</span>
                    <span className="font-bold text-slate-900">{activeCheckInVisitor.name}</span>
                  </div>
                  <div className="d-flex justify-content-between mb-1.5">
                    <span className="text-slate-500">Organization:</span>
                    <span className="font-semibold text-slate-800">{activeCheckInVisitor.organization}</span>
                  </div>
                  <div className="d-flex justify-content-between mb-1.5">
                    <span className="text-slate-500">Govt ID On File:</span>
                    <span className="font-mono font-semibold text-slate-800">{activeCheckInVisitor.govtId}</span>
                  </div>
                  <div className="d-flex justify-content-between mb-1.5">
                    <span className="text-slate-500">Host Employee:</span>
                    <span className="font-semibold text-slate-800">{activeCheckInVisitor.hostEmployee}</span>
                  </div>
                  <div className="d-flex justify-content-between">
                    <span className="text-slate-500">Authorized Zones:</span>
                    <span className="font-semibold text-emerald-700">
                      {(activeCheckInVisitor.assignedZones || ["Admin Building"]).join(", ")}
                    </span>
                  </div>
                </div>

                <div className="vm-form-group mb-3">
                  <label>Assign Physical RFID Badge / Smart Card Tag *</label>
                  <input
                    type="text"
                    value={assignedRfid}
                    onChange={(e) => setAssignedRfid(e.target.value)}
                    placeholder="e.g. RFID-9022"
                    required
                  />
                </div>

                <div className="p-3 bg-emerald-50 border border-emerald-200 rounded-lg mb-4">
                  <label className="d-flex align-items-center gap-2 cursor-pointer text-xs font-bold text-emerald-900">
                    <input
                      type="checkbox"
                      checked={ppeVerified}
                      onChange={(e) => setPpeVerified(e.target.checked)}
                    />
                    <span>
                      Gate PPE Checklist Passed: Hard Hat & Hi-Vis Safety Jacket Issued & Verified
                    </span>
                  </label>
                </div>

                <div className="d-flex justify-content-end gap-2">
                  <button
                    type="button"
                    onClick={() => setActiveCheckInVisitor(null)}
                    className="vm-btn-secondary text-xs"
                  >
                    Cancel
                  </button>
                  <button type="submit" className="vm-btn-primary text-xs" style={{ background: "#059669" }}>
                    <CheckCircle2 size={15} /> Authorize Turnstile & Check-In
                  </button>
                </div>
              </form>
            ) : (
              <div className="text-center py-5 text-slate-400">
                <FileBadge size={44} className="mb-2 mx-auto text-slate-300" />
                <div className="font-semibold text-slate-600">Select a visitor from the left to process Check-In</div>
                <div className="text-xs text-slate-400">Gate security agent will verify credentials before issuing badge</div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default GateCheckIn;

