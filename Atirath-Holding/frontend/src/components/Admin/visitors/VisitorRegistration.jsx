import React, { useState } from "react";
import {
  FileBadge,
  UserCheck,
  ShieldCheck,
  AlertTriangle,
  Building,
  Car,
  HardHat,
  Flame,
  CheckCircle2,
  Clock,
  Printer,
  PlusCircle,
  Eye
} from "lucide-react";
import {
  STORAGE_KEYS,
  INITIAL_VISITORS,
  getStoredData,
  saveStoredData,
  apiCreateVisitorRecord
} from "./visitorData";

const HOST_LIST = [
  { name: "Syed Mohammad Johny Basha", dept: "Executive Management", role: "Managing Director" },
  { name: "Rajesh Kumar", dept: "Operations & Maintenance", role: "Plant Operations Head" },
  { name: "Vutukuri Kumar Praveen", dept: "Gas Logistics & Dispatch", role: "Operations Lead" },
  { name: "Srinivas Rao", dept: "Health, Safety & Environment", role: "HSE Officer" },
  { name: "Dr. Ramesh Varma", dept: "Agronomy & Fertilizers", role: "Agronomy Head" },
  { name: "Rameshwar Patil", dept: "Logistics & Weighbridge", role: "Weighbridge Incharge" }
];

const VisitorRegistration = ({ onNavigate }) => {
  const [formData, setFormData] = useState({
    name: "",
    phone: "",
    email: "",
    organization: "",
    visitorType: "Vendor / Contractor",
    plantLocation: "Plant 1 - Hyderabad East CBG",
    hostEmployee: "Rajesh Kumar (Plant Operations Head)",
    department: "Operations & Maintenance",
    purpose: "",
    expectedInTime: "10:00 AM",
    expectedOutTime: "02:00 PM",
    govtIdType: "Aadhaar Card",
    govtId: "",
    vehicleType: "None (Pedestrian)",
    vehicleNo: "",
    carryingLaptop: false,
    laptopSerial: "",
    carryingTools: false,
    toolDetails: "",
    safetyDisclaimerSigned: false,
    ppeIssued: false,
    assignedZones: ["Admin Building", "Weighbridge"],
    remarks: ""
  });

  const [submittedPass, setSubmittedPass] = useState(null);
  const [errorMsg, setErrorMsg] = useState("");

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: type === "checkbox" ? checked : value
    }));
  };

  const handleZoneToggle = (zone) => {
    setFormData((prev) => {
      const exists = prev.assignedZones.includes(zone);
      return {
        ...prev,
        assignedZones: exists
          ? prev.assignedZones.filter((z) => z !== zone)
          : [...prev.assignedZones, zone]
      };
    });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    setErrorMsg("");

    if (!formData.name.trim() || !formData.phone.trim() || !formData.organization.trim()) {
      setErrorMsg("Please fill in the visitor's Full Name, Phone Number, and Organization.");
      return;
    }
    if (!formData.govtId.trim()) {
      setErrorMsg("Government ID Number is mandatory for industrial plant entry.");
      return;
    }
    if (!formData.safetyDisclaimerSigned) {
      setErrorMsg("Safety & Hazardous Zone Declaration must be acknowledged before issuing pass.");
      return;
    }

    const currentVisitors = getStoredData(STORAGE_KEYS.VISITORS, INITIAL_VISITORS);
    const newId = currentVisitors.length > 0 ? Math.max(...currentVisitors.map((v) => v.id || 0)) + 1 : 1;
    const generatedPassNo = `VP-${new Date().getFullYear()}-${String(1001 + (currentVisitors.length || 0))}`;

    const newVisitorRecord = {
      id: newId,
      passNo: generatedPassNo,
      name: formData.name.trim(),
      phone: formData.phone.trim(),
      email: formData.email.trim() || "N/A",
      organization: formData.organization.trim(),
      visitorType: formData.visitorType,
      plantLocation: formData.plantLocation,
      hostEmployee: formData.hostEmployee,
      department: formData.department,
      purpose: formData.purpose.trim() || "Official Business",
      expectedInTime: formData.expectedInTime,
      expectedOutTime: formData.expectedOutTime,
      actualInTime: "Just Registered",
      actualOutTime: null,
      status: formData.visitorType.includes("Statutory") ? "Pending Approval" : "Checked-In",
      govtIdType: formData.govtIdType,
      govtId: `${formData.govtIdType}: ${formData.govtId.trim()}`,
      vehicleType: formData.vehicleType,
      vehicleNo: formData.vehicleNo.trim() || "N/A",
      safetyDisclaimerSigned: formData.safetyDisclaimerSigned,
      ppeIssued: formData.ppeIssued,
      ppeItems: formData.ppeIssued ? ["Safety Helmet", "Hi-Vis Jacket", "Safety Boots"] : [],
      badgeRfid: `RFID-${9020 + newId}`,
      assignedZones: formData.assignedZones,
      carryingLaptop: formData.carryingLaptop,
      laptopSerial: formData.laptopSerial,
      isOverdue: false,
      remarks: formData.remarks.trim() || "Registered at Reception Gate Desk"
    };

    saveStoredData(STORAGE_KEYS.VISITORS, [newVisitorRecord, ...currentVisitors]);
    apiCreateVisitorRecord(newVisitorRecord).catch(() => {});
    setSubmittedPass(newVisitorRecord);
  };

  return (
    <div className="vm-submodule-container">
      {/* Header */}
      <div className="vm-section-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexWrap: "wrap", gap: "16px" }}>
        <p className="vm-section-desc" style={{ margin: 0, color: "#64748b", fontSize: "14px", flex: 1, minWidth: "260px" }}>
          Complete the security intake form to generate verified visitor access credentials and HSE clearance.
        </p>
        <button
          onClick={() => onNavigate("list")}
          className="vm-btn-secondary text-xs"
          style={{ flexShrink: 0, marginLeft: "auto" }}
        >
          View Registered Visitors Directory
        </button>
      </div>

      {submittedPass ? (
        <div className="vm-card p-6 text-center" style={{ maxWidth: "700px", margin: "20px auto" }}>
          <div
            style={{
              width: "68px",
              height: "68px",
              borderRadius: "50%",
              backgroundColor: "#d1fae5",
              color: "#059669",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              margin: "0 auto 16px auto"
            }}
          >
            <CheckCircle2 size={38} />
          </div>
          <h3 className="text-xl font-bold text-slate-900 mb-1">Gate Pass Successfully Generated!</h3>
          <p className="text-sm text-slate-600 mb-4">
            Security credential has been generated and logged into the BioNova Perimeter Register.
          </p>

          <div
            className="p-4 rounded-xl mb-4 text-left border border-slate-200"
            style={{ backgroundColor: "#f8fafc" }}
          >
            <div className="d-flex justify-content-between align-items-center mb-2 pb-2 border-b border-slate-200">
              <span className="text-xs uppercase text-slate-500 font-bold">Pass Number</span>
              <span className="text-sm font-black font-mono text-blue-700">{submittedPass.passNo}</span>
            </div>
            <div className="d-flex justify-content-between mb-1 text-xs">
              <span className="text-slate-500">Visitor Name:</span>
              <span className="font-semibold text-slate-800">{submittedPass.name}</span>
            </div>
            <div className="d-flex justify-content-between mb-1 text-xs">
              <span className="text-slate-500">Organization:</span>
              <span className="font-semibold text-slate-800">{submittedPass.organization}</span>
            </div>
            <div className="d-flex justify-content-between mb-1 text-xs">
              <span className="text-slate-500">Host Employee:</span>
              <span className="font-semibold text-slate-800">{submittedPass.hostEmployee}</span>
            </div>
            <div className="d-flex justify-content-between mb-1 text-xs">
              <span className="text-slate-500">Assigned Badge / RFID:</span>
              <span className="font-mono font-bold text-emerald-700">{submittedPass.badgeRfid}</span>
            </div>
            <div className="d-flex justify-content-between text-xs">
              <span className="text-slate-500">Initial Status:</span>
              <span className="font-semibold text-blue-600">{submittedPass.status}</span>
            </div>
          </div>

          <div className="d-flex justify-content-center gap-3">
            <button
              onClick={() => onNavigate("gate-pass")}
              className="vm-btn-primary text-xs"
            >
              <Printer size={15} /> Print Physical Gate Pass
            </button>
            <button
              onClick={() => {
                setSubmittedPass(null);
                setFormData({
                  name: "",
                  phone: "",
                  email: "",
                  organization: "",
                  visitorType: "Vendor / Contractor",
                  plantLocation: "Plant 1 - Hyderabad East CBG",
                  hostEmployee: "Rajesh Kumar (Plant Operations Head)",
                  department: "Operations & Maintenance",
                  purpose: "",
                  expectedInTime: "10:00 AM",
                  expectedOutTime: "02:00 PM",
                  govtIdType: "Aadhaar Card",
                  govtId: "",
                  vehicleType: "None (Pedestrian)",
                  vehicleNo: "",
                  carryingLaptop: false,
                  laptopSerial: "",
                  carryingTools: false,
                  toolDetails: "",
                  safetyDisclaimerSigned: false,
                  ppeIssued: false,
                  assignedZones: ["Admin Building", "Weighbridge"],
                  remarks: ""
                });
              }}
              className="vm-btn-secondary text-xs"
            >
              Register Another Visitor
            </button>
          </div>
        </div>
      ) : (
        <form onSubmit={handleSubmit} className="vm-form-container">
          {errorMsg && (
            <div className="vm-alert-banner alert-warning mb-4">
              <AlertTriangle size={18} className="text-red-500" />
              <span className="text-xs font-semibold text-red-700">{errorMsg}</span>
            </div>
          )}

          {/* Section 1: Visitor Identification */}
          <div className="vm-form-card mb-4">
            <div className="vm-form-card-title">
              <UserCheck size={18} className="text-blue-600" />
              1. Visitor Identification & Organization
            </div>
            <div className="vm-form-grid">
              <div className="vm-form-group">
                <label>Full Name *</label>
                <input
                  type="text"
                  name="name"
                  value={formData.name}
                  onChange={handleChange}
                  placeholder="e.g. Ramesh Kumar"
                  required
                />
              </div>

              <div className="vm-form-group">
                <label>Contact Mobile Number *</label>
                <input
                  type="tel"
                  name="phone"
                  value={formData.phone}
                  onChange={handleChange}
                  placeholder="+91 98490 00000"
                  required
                />
              </div>

              <div className="vm-form-group">
                <label>Official Email Address</label>
                <input
                  type="email"
                  name="email"
                  value={formData.email}
                  onChange={handleChange}
                  placeholder="name@company.com"
                />
              </div>

              <div className="vm-form-group">
                <label>Company / Organization Name *</label>
                <input
                  type="text"
                  name="organization"
                  value={formData.organization}
                  onChange={handleChange}
                  placeholder="e.g., Thermax Clean Energy Ltd"
                  required
                />
              </div>

              <div className="vm-form-group">
                <label>Government ID Document Type *</label>
                <select name="govtIdType" value={formData.govtIdType} onChange={handleChange}>
                  <option value="Aadhaar Card">Aadhaar Card (UIDAI)</option>
                  <option value="Driving License">Driving License</option>
                  <option value="PAN Card">PAN Card</option>
                  <option value="Passport">Passport</option>
                  <option value="Govt Inspection ID">Govt Inspector ID Badge</option>
                </select>
              </div>

              <div className="vm-form-group">
                <label>Government ID Number *</label>
                <input
                  type="text"
                  name="govtId"
                  value={formData.govtId}
                  onChange={handleChange}
                  placeholder="e.g., 7810-4491-0021"
                  required
                />
              </div>
            </div>
          </div>

          {/* Section 2: Visit Destination & Logistics */}
          <div className="vm-form-card mb-4">
            <div className="vm-form-card-title">
              <Building size={18} className="text-blue-600" />
              2. Plant Site & Host Employee Assignment
            </div>
            <div className="vm-form-grid">
              <div className="vm-form-group">
                <label>Visitor Category *</label>
                <select name="visitorType" value={formData.visitorType} onChange={handleChange}>
                  <option value="Vendor / Contractor">Vendor / Technical Contractor</option>
                  <option value="Statutory / Govt Inspector">Statutory / Govt Inspector (MNRE, PCB, PESO)</option>
                  <option value="Customer / Offtaker">Customer / Offtaker (CBG / FOM)</option>
                  <option value="Transporter / Logistics">Biomass Transporter / Logistics Driver</option>
                  <option value="General Corporate Guest">General Corporate Guest / Investor</option>
                </select>
              </div>

              <div className="vm-form-group">
                <label>Plant Complex Location *</label>
                <select name="plantLocation" value={formData.plantLocation} onChange={handleChange}>
                  <option value="Plant 1 - Hyderabad East CBG">Plant 1 - Hyderabad East CBG Complex</option>
                  <option value="Plant 2 - Medak Agri Hub">Plant 2 - Medak Agri-Feedstock Hub</option>
                  <option value="Plant 3 - Nalgonda Biogas Center">Plant 3 - Nalgonda Biogas Unit</option>
                </select>
              </div>

              <div className="vm-form-group">
                <label>Designated Host Employee *</label>
                <select
                  name="hostEmployee"
                  value={formData.hostEmployee}
                  onChange={(e) => {
                    const host = HOST_LIST.find((h) => `${h.name} (${h.role})` === e.target.value);
                    setFormData((prev) => ({
                      ...prev,
                      hostEmployee: e.target.value,
                      department: host ? host.dept : prev.department
                    }));
                  }}
                >
                  {HOST_LIST.map((h, i) => (
                    <option key={i} value={`${h.name} (${h.role})`}>
                      {h.name} — {h.role} ({h.dept})
                    </option>
                  ))}
                </select>
              </div>

              <div className="vm-form-group">
                <label>Host Department</label>
                <input
                  type="text"
                  name="department"
                  value={formData.department}
                  readOnly
                  className="bg-slate-50 text-slate-700"
                />
              </div>

              <div className="vm-form-group">
                <label>Expected Entry Time</label>
                <input
                  type="text"
                  name="expectedInTime"
                  value={formData.expectedInTime}
                  onChange={handleChange}
                  placeholder="e.g., 10:00 AM"
                />
              </div>

              <div className="vm-form-group">
                <label>Expected Departure Time</label>
                <input
                  type="text"
                  name="expectedOutTime"
                  value={formData.expectedOutTime}
                  onChange={handleChange}
                  placeholder="e.g., 02:00 PM"
                />
              </div>

              <div className="vm-form-group" style={{ gridColumn: "1 / -1" }}>
                <label>Specific Purpose of Visit *</label>
                <input
                  type="text"
                  name="purpose"
                  value={formData.purpose}
                  onChange={handleChange}
                  placeholder="e.g., Inspection of Scrubber column, Pressure meter recalibration"
                  required
                />
              </div>
            </div>
          </div>

          {/* Section 3: Vehicle & Asset Declarations */}
          <div className="vm-form-card mb-4">
            <div className="vm-form-card-title">
              <Car size={18} className="text-blue-600" />
              3. Vehicle Entry & Material Declarations
            </div>
            <div className="vm-form-grid">
              <div className="vm-form-group">
                <label>Vehicle Type</label>
                <select name="vehicleType" value={formData.vehicleType} onChange={handleChange}>
                  <option value="None (Pedestrian)">None (Pedestrian / Walk-in)</option>
                  <option value="Private Car / Sedan">Private Car / Sedan</option>
                  <option value="Maintenance Van / SUV">Maintenance Van / SUV</option>
                  <option value="Heavy Commercial Tipper">Heavy Commercial Tipper (Biomass / Feedstock)</option>
                  <option value="CBG Cascade Transport Trailer">CBG Cascade Transport Trailer</option>
                </select>
              </div>

              <div className="vm-form-group">
                <label>Vehicle Registration Number</label>
                <input
                  type="text"
                  name="vehicleNo"
                  value={formData.vehicleNo}
                  onChange={handleChange}
                  placeholder="e.g., TS 09 EA 4401"
                />
              </div>

              <div className="vm-form-group" style={{ display: "flex", flexDirection: "column", justifyContent: "center" }}>
                <label className="d-flex align-items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    name="carryingLaptop"
                    checked={formData.carryingLaptop}
                    onChange={handleChange}
                  />
                  <span>Carrying Electronic Assets / Laptop</span>
                </label>
                {formData.carryingLaptop && (
                  <input
                    type="text"
                    name="laptopSerial"
                    value={formData.laptopSerial}
                    onChange={handleChange}
                    placeholder="Enter Device Serial No / Make"
                    className="mt-2"
                  />
                )}
              </div>

              <div className="vm-form-group" style={{ display: "flex", flexDirection: "column", justifyContent: "center" }}>
                <label className="d-flex align-items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    name="carryingTools"
                    checked={formData.carryingTools}
                    onChange={handleChange}
                  />
                  <span>Carrying Industrial Tools / Calibration Kits</span>
                </label>
                {formData.carryingTools && (
                  <input
                    type="text"
                    name="toolDetails"
                    value={formData.toolDetails}
                    onChange={handleChange}
                    placeholder="Specify tools (Multimeter, Fluke tester, etc.)"
                    className="mt-2"
                  />
                )}
              </div>
            </div>
          </div>

          {/* Section 4: Zone Access & Safety HSE */}
          <div className="vm-form-card mb-4">
            <div className="vm-form-card-title">
              <HardHat size={18} className="text-emerald-600" />
              4. Zone Access Permissions & Safety Induction
            </div>

            <div className="mb-3">
              <label className="text-xs font-bold text-slate-700 block mb-2">
                Authorized Plant Zones (Select permitted zones for this pass):
              </label>
              <div className="d-flex flex-wrap gap-2">
                {[
                  "Admin Building",
                  "Weighbridge",
                  "Anaerobic Digesters",
                  "Gas Purification Unit",
                  "Cascade Filling Bay"
                ].map((zone) => (
                  <button
                    key={zone}
                    type="button"
                    onClick={() => handleZoneToggle(zone)}
                    className={`vm-zone-pill ${formData.assignedZones.includes(zone) ? "selected" : ""}`}
                  >
                    {zone}
                  </button>
                ))}
              </div>
            </div>

            <div className="p-3 bg-slate-50 rounded-lg border border-slate-200 mb-3">
              <div className="d-flex align-items-start gap-2.5">
                <Flame size={18} className="text-amber-600 flex-shrink-0 mt-0.5" />
                <div className="text-xs text-slate-700">
                  <span className="font-bold text-slate-900">Biogas & ATEX Zone Warning:</span> Compressed
                  Biogas facilities contain flammable gas (Methane) and toxic gas (H2S). Smoking, open flames, and
                  non-certified electrical devices are strictly prohibited beyond the reception lobby.
                </div>
              </div>
            </div>

            <div className="d-flex flex-column gap-2">
              <label className="d-flex align-items-center gap-2 text-xs font-semibold text-slate-800 cursor-pointer">
                <input
                  type="checkbox"
                  name="safetyDisclaimerSigned"
                  checked={formData.safetyDisclaimerSigned}
                  onChange={handleChange}
                  required
                />
                <span>
                  Visitor has read and signed the Plant Safety Guidelines & Emergency Protocol Acknowledgment *
                </span>
              </label>

              <label className="d-flex align-items-center gap-2 text-xs font-semibold text-slate-800 cursor-pointer">
                <input
                  type="checkbox"
                  name="ppeIssued"
                  checked={formData.ppeIssued}
                  onChange={handleChange}
                />
                <span>Mandatory PPE Kit Issued at Gate (Hard Hat, Hi-Vis Vest, Safety Shoes verified)</span>
              </label>
            </div>
          </div>

          {/* Submit Actions */}
          <div className="d-flex justify-content-end gap-3 pt-2">
            <button
              type="button"
              onClick={() => onNavigate("list")}
              className="vm-btn-secondary"
            >
              Cancel
            </button>
            <button type="submit" className="vm-btn-primary">
              <FileBadge size={16} /> Authorize & Issue Gate Pass
            </button>
          </div>
        </form>
      )}
    </div>
  );
};

export default VisitorRegistration;

