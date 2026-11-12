import React, { useState, useEffect } from "react";
import {
  LogOut,
  Search,
  CheckCircle2,
  Clock,
  HardHat,
  Package,
  AlertTriangle,
  UserCheck
} from "lucide-react";
import {
  STORAGE_KEYS,
  INITIAL_VISITORS,
  getStoredData,
  saveStoredData,
  apiCheckOutVisitor
} from "./visitorData";

const GateCheckOut = ({ onNavigate }) => {
  const [visitors, setVisitors] = useState(() =>
    getStoredData(STORAGE_KEYS.VISITORS, INITIAL_VISITORS)
  );

  const [searchQuery, setSearchQuery] = useState("");
  const [selectedVisitor, setSelectedVisitor] = useState(null);
  const [ppeReturned, setPpeReturned] = useState(true);
  const [rfidCardReturned, setRfidCardReturned] = useState(true);
  const [outwardMaterialVerified, setOutwardMaterialVerified] = useState(true);
  const [successBanner, setSuccessBanner] = useState("");

  const insideVisitors = visitors.filter((v) => v.status === "Checked-In");

  const handleSelectVisitor = (v) => {
    setSelectedVisitor(v);
    setPpeReturned(true);
    setRfidCardReturned(true);
    setOutwardMaterialVerified(true);
  };

  const handleProcessCheckOut = (e) => {
    e.preventDefault();
    if (!selectedVisitor) return;

    const outTime = new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
    const updated = visitors.map((v) => {
      if (v.id === selectedVisitor.id) {
        return {
          ...v,
          status: "Checked-Out",
          actualOutTime: outTime,
          isOverdue: false,
          overdueMinutes: 0
        };
      }
      return v;
    });

    setVisitors(updated);
    saveStoredData(STORAGE_KEYS.VISITORS, updated);
    if (selectedVisitor.id) {
      apiCheckOutVisitor(selectedVisitor.id).catch(() => {});
    }
    setSuccessBanner(`${selectedVisitor.name} (${selectedVisitor.passNo}) successfully Checked-Out at ${outTime}. Dwell time recorded.`);
    setSelectedVisitor(null);
    setSearchQuery("");
  };

  const filteredInside = insideVisitors.filter(
    (v) =>
      v.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      v.passNo.toLowerCase().includes(searchQuery.toLowerCase()) ||
      v.badgeRfid?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      v.organization.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="vm-submodule-container">
      {/* Header */}
      <div className="vm-section-header" style={{ marginBottom: "20px" }}>
        <p className="vm-section-desc" style={{ margin: 0, color: "#64748b", fontSize: "14px" }}>
          Process perimeter departure, calculate total dwell time, verify PPE return, and finalize pass records.
        </p>
      </div>

      {successBanner && (
        <div className="vm-alert-banner alert-success mb-4">
          <CheckCircle2 size={20} className="text-emerald-600" />
          <span className="text-xs font-semibold text-emerald-800">{successBanner}</span>
        </div>
      )}

      <div className="row g-4">
        {/* Left Column: Active Visitors Inside */}
        <div className="col-12 col-lg-5">
          <div className="vm-card p-4">
            <h3 className="text-base font-bold text-slate-900 mb-2">Personnel Inside Premises</h3>
            <p className="text-xs text-slate-500 mb-3">
              Search by visitor name, pass number, or RFID badge to check-out:
            </p>

            <div className="vm-search-box mb-3">
              <Search size={18} className="text-slate-400" />
              <input
                type="text"
                placeholder="Search active visitor or RFID tag..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>

            <div className="d-flex flex-column gap-2" style={{ maxHeight: "400px", overflowY: "auto" }}>
              {filteredInside.length === 0 ? (
                <div className="text-center py-4 text-xs text-slate-400">
                  No active checked-in visitors match search.
                </div>
              ) : (
                filteredInside.map((v) => (
                  <div
                    key={v.id}
                    onClick={() => handleSelectVisitor(v)}
                    className={`p-3 rounded-xl border cursor-pointer transition-all ${
                      selectedVisitor?.id === v.id
                        ? "border-amber-500 bg-amber-50"
                        : "border-slate-200 hover:bg-slate-50"
                    }`}
                  >
                    <div className="d-flex justify-content-between align-items-start mb-1">
                      <span className="font-bold text-slate-900 text-sm">{v.name}</span>
                      <span className="font-mono text-xs font-bold text-blue-700">{v.passNo}</span>
                    </div>
                    <div className="text-xs text-slate-600 mb-1.5">{v.organization}</div>
                    <div className="d-flex justify-content-between align-items-center text-xs">
                      <span className="font-mono text-slate-500">
                        In: <strong className="text-slate-800">{v.actualInTime || v.expectedInTime}</strong>
                      </span>
                      <span className="font-mono font-bold text-indigo-700 bg-indigo-50 px-2 py-0.5 rounded">
                        {v.badgeRfid || "No RFID"}
                      </span>
                    </div>
                    {v.isOverdue && (
                      <div className="mt-2 text-xs font-bold text-red-600 bg-red-50 p-1 rounded d-flex align-items-center gap-1">
                        <AlertTriangle size={12} /> Exceeded expected departure ({v.overdueMinutes || 30} mins overdue)
                      </div>
                    )}
                  </div>
                ))
              )}
            </div>
          </div>
        </div>

        {/* Right Column: Checkout Processing Desk */}
        <div className="col-12 col-lg-7">
          <div className="vm-card p-4">
            <h3 className="text-base font-bold text-slate-900 mb-2">Gate Security Exit Protocol</h3>
            <p className="text-xs text-slate-500 mb-4">
              Return safety kit, verify tool/laptop serial numbers, and close gate pass.
            </p>

            {selectedVisitor ? (
              <form onSubmit={handleProcessCheckOut}>
                <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 mb-4 text-xs">
                  <div className="d-flex justify-content-between mb-1.5">
                    <span className="text-slate-500">Visitor:</span>
                    <span className="font-bold text-slate-900">{selectedVisitor.name}</span>
                  </div>
                  <div className="d-flex justify-content-between mb-1.5">
                    <span className="text-slate-500">Organization:</span>
                    <span className="font-semibold text-slate-800">{selectedVisitor.organization}</span>
                  </div>
                  <div className="d-flex justify-content-between mb-1.5">
                    <span className="text-slate-500">Check-In Timestamp:</span>
                    <span className="font-mono font-bold text-emerald-700">{selectedVisitor.actualInTime}</span>
                  </div>
                  <div className="d-flex justify-content-between mb-1.5">
                    <span className="text-slate-500">Host Employee:</span>
                    <span className="font-semibold text-slate-800">{selectedVisitor.hostEmployee}</span>
                  </div>
                  <div className="d-flex justify-content-between">
                    <span className="text-slate-500">Vehicle Registered:</span>
                    <span className="font-mono font-semibold text-slate-800">
                      {selectedVisitor.vehicleNo || "Pedestrian (Walk-out)"}
                    </span>
                  </div>
                </div>

                <div className="p-3 bg-amber-50 border border-amber-200 rounded-lg mb-3">
                  <div className="d-flex flex-column gap-2 text-xs font-semibold text-slate-800">
                    <label className="d-flex align-items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={rfidCardReturned}
                        onChange={(e) => setRfidCardReturned(e.target.checked)}
                        required
                      />
                      <span>Physical RFID Smart Card / Badge Tag Returned and Checked-In</span>
                    </label>

                    <label className="d-flex align-items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={ppeReturned}
                        onChange={(e) => setPpeReturned(e.target.checked)}
                        required
                      />
                      <span>All Issued PPE Gear (Helmet, Hi-Vis Vest, Gas Detector) Returned</span>
                    </label>

                    <label className="d-flex align-items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={outwardMaterialVerified}
                        onChange={(e) => setOutwardMaterialVerified(e.target.checked)}
                      />
                      <span>Materials / Toolkits verified against entry declarations (No unauthorized assets)</span>
                    </label>
                  </div>
                </div>

                <div className="d-flex justify-content-end gap-2">
                  <button
                    type="button"
                    onClick={() => setSelectedVisitor(null)}
                    className="vm-btn-secondary text-xs"
                  >
                    Cancel
                  </button>
                  <button type="submit" className="vm-btn-primary text-xs" style={{ background: "#d97706" }}>
                    <LogOut size={15} /> Confirm Departure & Close Pass
                  </button>
                </div>
              </form>
            ) : (
              <div className="text-center py-5 text-slate-400">
                <Clock size={44} className="mb-2 mx-auto text-slate-300" />
                <div className="font-semibold text-slate-600">Select an active visitor from the left to process exit</div>
                <div className="text-xs text-slate-400">Dwell duration will be logged and visitor marked Checked-Out</div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default GateCheckOut;

