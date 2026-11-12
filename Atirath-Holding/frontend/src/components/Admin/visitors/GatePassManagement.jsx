import React, { useState, useEffect } from "react";
import {
  FileBadge,
  Printer,
  Download,
  Search,
  Eye,
  RefreshCw,
  QrCode,
  ShieldCheck,
  CheckCircle2,
  Calendar,
  Building,
  UserCheck
} from "lucide-react";
import {
  STORAGE_KEYS,
  INITIAL_VISITORS,
  getStoredData
} from "./visitorData";

const GatePassManagement = ({ onNavigate }) => {
  const [visitors, setVisitors] = useState(() =>
    getStoredData(STORAGE_KEYS.VISITORS, INITIAL_VISITORS)
  );
  const [selectedPass, setSelectedPass] = useState(null);
  const [searchTerm, setSearchTerm] = useState("");

  useEffect(() => {
    const handleUpdate = () => {
      const data = getStoredData(STORAGE_KEYS.VISITORS, INITIAL_VISITORS);
      setVisitors(data);
      if (selectedPass && !data.some(v => v.id === selectedPass.id)) {
        setSelectedPass(data[0] || null);
      }
    };
    window.addEventListener("bionova_visitor_updated", handleUpdate);
    return () => window.removeEventListener("bionova_visitor_updated", handleUpdate);
  }, [selectedPass]);

  const handlePrint = () => {
    window.print();
  };

  const filteredVisitors = visitors.filter(
    (v) =>
      v.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      v.passNo.toLowerCase().includes(searchTerm.toLowerCase()) ||
      v.organization.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="vm-submodule-container">
      {/* Header */}
      <div className="vm-section-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="vm-section-desc" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Standardized printable plant security passes with encrypted barcodes, zone clearances, and emergency protocol notes.
        </p>
        <div className="d-flex align-items-center gap-2" style={{ flexShrink: 0, marginLeft: "auto" }}>
          <button onClick={handlePrint} className="vm-btn-primary text-xs">
            <Printer size={15} /> Print Active Pass
          </button>
        </div>
      </div>

      <div className="row g-4">
        {/* Pass Selector */}
        <div className="col-12 col-lg-5">
          <div className="vm-card p-4">
            <h3 className="text-base font-bold text-slate-900 mb-2">Select Issued Pass</h3>
            <div className="vm-search-box mb-3">
              <Search size={18} className="text-slate-400" />
              <input
                type="text"
                placeholder="Search pass number or visitor..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>

            <div className="d-flex flex-column gap-2" style={{ maxHeight: "480px", overflowY: "auto" }}>
              {filteredVisitors.length === 0 ? (
                <div className="text-center py-5 text-slate-400 text-xs">
                  No visitor passes available to display.
                </div>
              ) : (
                filteredVisitors.map((v) => (
                <div
                  key={v.id}
                  onClick={() => setSelectedPass(v)}
                  className={`p-3 rounded-xl border cursor-pointer transition-all ${
                    selectedPass?.id === v.id
                      ? "border-blue-500 bg-blue-50"
                      : "border-slate-200 hover:bg-slate-50"
                  }`}
                >
                  <div className="d-flex justify-content-between align-items-center mb-1">
                    <span className="font-bold text-slate-900 text-sm">{v.name}</span>
                    <span className="font-mono text-xs font-bold text-blue-700">{v.passNo}</span>
                  </div>
                  <div className="text-xs text-slate-600 mb-1">{v.organization}</div>
                  <div className="d-flex justify-content-between text-xs text-slate-500">
                    <span>{v.visitorType}</span>
                    <span className="font-mono">{v.badgeRfid || "No RFID"}</span>
                  </div>
                </div>
              )))}
            </div>
          </div>
        </div>

        {/* Visual Pass Badge Preview */}
        <div className="col-12 col-lg-7">
          {selectedPass ? (
            <div className="vm-gatepass-card printable-pass" style={{ margin: "0 auto", maxWidth: "600px" }}>
              <div className="vm-pass-header">
                <div>
                  <div className="vm-pass-brand">BIONOVA CLEAN ENERGY ENTERPRISE</div>
                  <div className="vm-pass-subtitle">PLANT ENTRY PERMIT & SECURITY PASS</div>
                </div>
                <div className="vm-pass-badge-pill">{selectedPass.status}</div>
              </div>

              <div className="vm-pass-body">
                <div className="d-flex gap-3 mb-3">
                  <div className="vm-pass-photo-box">
                    <div className="vm-pass-initials">
                      {selectedPass.name.split(" ").map((n) => n[0]).slice(0, 2).join("")}
                    </div>
                    <div className="vm-pass-rfid">{selectedPass.badgeRfid}</div>
                  </div>
                  <div className="flex-1">
                    <div className="vm-pass-name">{selectedPass.name}</div>
                    <div className="vm-pass-org">{selectedPass.organization}</div>
                    <div className="vm-pass-category">{selectedPass.visitorType}</div>
                    <div className="text-xs text-slate-600 mt-1">
                      Govt ID: <span className="font-mono font-bold">{selectedPass.govtId}</span>
                    </div>
                  </div>
                </div>

                <div className="vm-pass-grid">
                  <div>
                    <span className="label">Pass Number:</span>
                    <span className="val font-mono font-bold text-blue-700">{selectedPass.passNo}</span>
                  </div>
                  <div>
                    <span className="label">Host Employee:</span>
                    <span className="val">{selectedPass.hostEmployee}</span>
                  </div>
                  <div>
                    <span className="label">Plant Site:</span>
                    <span className="val">{selectedPass.plantLocation}</span>
                  </div>
                  <div>
                    <span className="label">Vehicle Plate:</span>
                    <span className="val font-mono">{selectedPass.vehicleNo || "Pedestrian"}</span>
                  </div>
                  <div style={{ gridColumn: "1 / -1" }}>
                    <span className="label">Approved Purpose of Visit:</span>
                    <span className="val">{selectedPass.purpose}</span>
                  </div>
                  <div style={{ gridColumn: "1 / -1" }}>
                    <span className="label">Authorized Safety Zones:</span>
                    <div className="d-flex flex-wrap gap-1 mt-1">
                      {(selectedPass.assignedZones || ["Admin Building"]).map((z, i) => (
                        <span key={i} className="vm-zone-tag">{z}</span>
                      ))}
                    </div>
                  </div>
                </div>

                <div className="p-3 bg-slate-50 border border-slate-200 rounded-lg mt-3 text-xs text-slate-600">
                  <strong className="text-slate-900 block mb-0.5">Safety & Hazard Warning:</strong>
                  Wear required PPE at all times. Smoking, uncertified flash cameras, and non-intrinsically safe devices are strictly forbidden inside Gas Upgradation & Compression Bays.
                </div>

                <div className="vm-pass-footer mt-4">
                  <div className="text-xs text-slate-500 font-mono">
                    VALID: {new Date().toLocaleDateString()} | In: {selectedPass.actualInTime || selectedPass.expectedInTime}
                  </div>
                  <div className="vm-barcode-preview">
                    |||| | |||||| | || ||||| | |||| | |||
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <div className="text-center py-5 text-slate-400">Select a pass from the left to view</div>
          )}
        </div>
      </div>
    </div>
  );
};

export default GatePassManagement;

