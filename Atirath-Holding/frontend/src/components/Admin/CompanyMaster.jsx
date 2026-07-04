import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import Sidebar from "../Sidebar";
import Header from "../Header";
import {
  Search,
  Bell,
  X,
  Menu,
  ChevronRight,
  RefreshCcw,
  Save,
  Edit,
  Trash2,
  Eye,
  Plus,
  MoreVertical,
  ChevronLeft,
  Building2,
  Upload,
  Image as ImageIcon
} from "lucide-react";
import "../../styles/CompanyMaster.css";
import AlertModal from "../AlertModal";

// Logic for State to Zone mapping
const stateToZoneMap = {
  "Telangana": "South Zone",
  "Andhra Pradesh": "South Zone",
  "Karnataka": "South Zone",
  "Tamil Nadu": "South Zone",
  "Kerala": "South Zone",
  "Maharashtra": "West Zone",
  "Gujarat": "West Zone",
  "Delhi": "North Zone",
  "Punjab": "North Zone",
  "West Bengal": "East Zone",
  "Odisha": "East Zone",
  "Madhya Pradesh": "Central Zone"
};

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || "http://localhost:8080";

const getAuthHeaders = () => ({
  "Content-Type": "application/json",
  "Authorization": `Bearer ${sessionStorage.getItem("authToken") || ""}`
});

const CompanyCreation = ({ onLogout, userRole }) => {
  const navigate = useNavigate();

  const [companies, setCompanies] = useState([]);
  const [states, setStates] = useState([]);
  const [loading, setLoading] = useState(false);

  const fetchCompanies = async () => {
    setLoading(true);
    try {
      const response = await fetch(`${apiBaseUrl}/api/companies`, { headers: getAuthHeaders() });
      if (response.ok) {
        const data = await response.json();
        setCompanies(data);
      }
    } catch (error) {
      console.error("Error fetching companies:", error);
    } finally {
      setLoading(false);
    }
  };

  const fetchStates = async () => {
    try {
      const response = await fetch(`${apiBaseUrl}/api/states`, { headers: getAuthHeaders() });
      if (response.ok) {
        const data = await response.json();
        setStates(data);
      }
    } catch (error) {
      console.error("Error fetching states:", error);
    }
  };

  useEffect(() => {
    fetchCompanies();
    fetchStates();
  }, []);

  // View toggle – default is "list"
  const [view, setView] = useState("list");
  const [isEditing, setIsEditing] = useState(false);
  const [editingId, setEditingId] = useState(null);

  // Form state – all empty by default
  const [formData, setFormData] = useState({
    companyName: "",
    companyCode: "",
    under: "",
    cinNumber: "",
    gstNumber: "",
    panNumber: "",
    tanNumber: "",
    incorporationDate: "",
    flatPlotDoor: "",
    streetAddress: "",
    landMark: "",
    city: "",
    district: "",
    state: "",
    zone: "",
    pincode: "",
    email: "",
    remarks: "",
    website: "",
    logo: null,
    status: "Active"
  });

  // Table action dropdown trigger state
  const [activeDropdown, setActiveDropdown] = useState(null);

  // Deactivation confirmation modal state
  const [showDeactivateModal, setShowDeactivateModal] = useState(false);
  const [deactivateTargetId, setDeactivateTargetId] = useState(null);

  const [alertConfig, setAlertConfig] = useState({
    isOpen: false,
    type: "info",
    title: "",
    message: ""
  });

  const triggerAlert = (type, title, message) => {
    setAlertConfig({ isOpen: true, type, title, message });
  };

  // Sorting state
  const [sortConfig, setSortConfig] = useState({ key: null, direction: 'asc' });

  // Handle input changes
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    let newValue = value;

    if (name === "pincode") {
      newValue = value.replace(/[^0-9]/g, '').slice(0, 6);
    } else if (name === "companyCode") {
      newValue = value.slice(0, 10);
    } else if (name === "companyName") {
      newValue = value.slice(0, 100);
    } else if (name === "cinNumber") {
      newValue = value.slice(0, 25);
    } else if (name === "panNumber" || name === "tanNumber") {
      newValue = value.slice(0, 15);
    } else if (name === "streetAddress") {
      newValue = value.slice(0, 50);
    } else if (name === "city" || name === "district") {
      newValue = value.slice(0, 30);
    } else if (name === "email" || name === "website") {
      newValue = value.slice(0, 100);
    } else if (name === "remarks") {
      newValue = value.slice(0, 255);
    } else if (name === "gstNumber") {
      newValue = value.slice(0, 20);
    } else if (name === "flatPlotDoor" || name === "landMark") {
      newValue = value.slice(0, 50);
    }

    setFormData(prev => ({ ...prev, [name]: newValue }));
  };

  const handleToggleStatus = (e) => {
    setFormData(prev => ({ ...prev, status: e.target.checked ? "Active" : "Inactive" }));
  };

  const handleStateChange = (e) => {
    const selectedStateId = e.target.value;
    const selectedStateObj = states.find(s => s.stId.toString() === selectedStateId.toString());
    const mappedZone = selectedStateObj ? selectedStateObj.znNm : "";
    setFormData(prev => ({
      ...prev,
      state: selectedStateId,
      zone: mappedZone
    }));
  };

  const handleLogoChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onloadend = () => setFormData((prev) => ({ ...prev, logo: reader.result }));
    reader.readAsDataURL(file);
  };



  const handleResetForm = () => {
    setFormData({
      companyName: "",
      companyCode: "",
      under: "",
      cinNumber: "",
      gstNumber: "",
      panNumber: "",
      tanNumber: "",
      incorporationDate: "",
      flatPlotDoor: "",
      streetAddress: "",
      landMark: "",
      city: "",
      district: "",
      state: "",
      zone: "",
      pincode: "",
      email: "",
      remarks: "",
      website: "",
      logo: null,
      status: "Active"
    });
  };

  const handleSave = () => {
    // 1. Company Name check
    if (!formData.companyName.trim()) {
      triggerAlert("error", "Validation Error", "Company Name is required.");
      return;
    }
    if (formData.companyName.length > 100) {
      triggerAlert("error", "Validation Error", "Company Name cannot exceed 100 characters.");
      return;
    }

    // 2. Company Code check
    if (!formData.companyCode.trim()) {
      triggerAlert("error", "Validation Error", "Company Code is required.");
      return;
    }
    if (formData.companyCode.length > 10) {
      triggerAlert("error", "Validation Error", "Company Code cannot exceed 10 characters.");
      return;
    }

    // 3. Parent Company ID (Under / Subsidiary) check
    if (!formData.under) {
      triggerAlert("error", "Validation Error", "Parent Company selection is required.");
      return;
    }

    // 4. Company CIN Number check
    if (!formData.cinNumber.trim()) {
      triggerAlert("error", "Validation Error", "Company CIN Number is required.");
      return;
    }
    if (formData.cinNumber.length > 21) {
      triggerAlert("error", "Validation Error", "Company CIN Number cannot exceed 21 characters.");
      return;
    }

    // 5. GST Number check
    if (formData.gstNumber.trim() && formData.gstNumber.length > 20) {
      triggerAlert("error", "Validation Error", "GST Number cannot exceed 20 characters.");
      return;
    }

    // 6. PAN Number check
    if (!formData.panNumber.trim()) {
      triggerAlert("error", "Validation Error", "PAN Number is required.");
      return;
    }
    if (formData.panNumber.length > 10) {
      triggerAlert("error", "Validation Error", "PAN Number cannot exceed 10 characters.");
      return;
    }

    // 7. TAN Number check
    if (!formData.tanNumber.trim()) {
      triggerAlert("error", "Validation Error", "TAN Number is required.");
      return;
    }
    if (formData.tanNumber.length > 15) {
      triggerAlert("error", "Validation Error", "TAN Number cannot exceed 15 characters.");
      return;
    }

    // 8. Incorporation Date check
    if (!formData.incorporationDate.trim()) {
      triggerAlert("error", "Validation Error", "Incorporation Date is required.");
      return;
    }

    // 9. Flat/Plot/Door No check (NEW mandatory check)
    if (!formData.flatPlotDoor.trim()) {
      triggerAlert("error", "Validation Error", "Flat/Plot/Door No is required.");
      return;
    }
    if (formData.flatPlotDoor.length > 50) {
      triggerAlert("error", "Validation Error", "Flat/Plot/Door No cannot exceed 50 characters.");
      return;
    }

    // 10. Street Address check
    if (!formData.streetAddress.trim()) {
      triggerAlert("error", "Validation Error", "Street Name is required.");
      return;
    }
    if (formData.streetAddress.length > 50) {
      triggerAlert("error", "Validation Error", "Street Name cannot exceed 50 characters.");
      return;
    }

    // 11. City/Village check
    if (!formData.city.trim()) {
      triggerAlert("error", "Validation Error", "City/Village is required.");
      return;
    }
    if (formData.city.length > 30) {
      triggerAlert("error", "Validation Error", "City/Village cannot exceed 30 characters.");
      return;
    }

    // 12. District Name check
    if (!formData.district.trim()) {
      triggerAlert("error", "Validation Error", "District Name is required.");
      return;
    }
    if (formData.district.length > 30) {
      triggerAlert("error", "Validation Error", "District Name cannot exceed 30 characters.");
      return;
    }

    // 13. State Reference check
    if (!formData.state) {
      triggerAlert("error", "Validation Error", "State Reference selection is required.");
      return;
    }

    // 14. Postal Code (Pincode) check
    if (!formData.pincode.trim()) {
      triggerAlert("error", "Validation Error", "Postal Code (Pincode) is required.");
      return;
    }
    const pincodeRegex = /^\d{6}$/;
    if (!pincodeRegex.test(formData.pincode.trim())) {
      triggerAlert("error", "Validation Error", "Postal Code must be exactly 6 numeric digits.");
      return;
    }

    // 15. Company Email check
    if (!formData.email.trim()) {
      triggerAlert("error", "Validation Error", "Company Email is required.");
      return;
    }
    if (formData.email.length > 100) {
      triggerAlert("error", "Validation Error", "Company Email cannot exceed 100 characters.");
      return;
    }
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(formData.email.trim())) {
      triggerAlert("error", "Validation Error", "Please enter a valid Company Email address.");
      return;
    }

    // 16. Company Website URL check
    if (formData.website.trim()) {
      if (formData.website.length > 100) {
        triggerAlert("error", "Validation Error", "Company Website URL cannot exceed 100 characters.");
        return;
      }
      const urlPattern = /^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([/\w .-]*)*\/?$/;
      if (!urlPattern.test(formData.website.trim())) {
        triggerAlert("error", "Validation Error", "Please enter a valid Company Website URL.");
        return;
      }
    }

    // 17. Additional Remarks check
    if (formData.remarks.trim() && formData.remarks.length > 255) {
      triggerAlert("error", "Validation Error", "Additional Remarks cannot exceed 255 characters.");
      return;
    }

    // 18. Active / Inactive Status check (boolean represented by string "Active" / "Inactive")
    if (!formData.status) {
      triggerAlert("error", "Validation Error", "Status selection is required.");
      return;
    }

    // Unique Data checks
    const isDuplicateCode = companies.some(
      c => c.coyCd?.toLowerCase().trim() === formData.companyCode.toLowerCase().trim() && c.coyId !== editingId
    );
    if (isDuplicateCode) {
      triggerAlert("error", "Duplicate Error", "Company code must be unique. This code already exists.");
      return;
    }

    const isDuplicateCIN = companies.some(
      c => c.cin?.toLowerCase().trim() === formData.cinNumber.toLowerCase().trim() && c.coyId !== editingId
    );
    if (isDuplicateCIN) {
      triggerAlert("error", "Duplicate Error", "CIN Number must be unique. This CIN already exists.");
      return;
    }

    const isDuplicatePAN = companies.some(
      c => c.panNum?.toLowerCase().trim() === formData.panNumber.toLowerCase().trim() && c.coyId !== editingId
    );
    if (isDuplicatePAN) {
      triggerAlert("error", "Duplicate Error", "PAN Number must be unique. This PAN already exists.");
      return;
    }

    const isDuplicateTAN = companies.some(
      c => c.tanNum?.toLowerCase().trim() === formData.tanNumber.toLowerCase().trim() && c.coyId !== editingId
    );
    if (isDuplicateTAN) {
      triggerAlert("error", "Duplicate Error", "TAN Number must be unique. This TAN already exists.");
      return;
    }

    if (formData.gstNumber?.trim()) {
      const isDuplicateGST = companies.some(
        c => c.gstNum?.toLowerCase().trim() === formData.gstNumber.toLowerCase().trim() && c.coyId !== editingId
      );
      if (isDuplicateGST) {
        triggerAlert("error", "Duplicate Error", "GST Number must be unique. This GST already exists.");
        return;
      }
    }

    const companyPayload = {
      coyCd: formData.companyCode.trim(),
      coyNm: formData.companyName.trim(),
      prntCoyId: formData.under && formData.under !== "Independent" ? Number(formData.under) : null,
      email: formData.email.trim(),
      gstNum: formData.gstNumber ? formData.gstNumber.trim() : null,
      tanNum: formData.tanNumber.trim(),
      panNum: formData.panNumber.trim(),
      incDt: formData.incorporationDate,
      cin: formData.cinNumber.trim(),
      webUrl: formData.website ? formData.website.trim() : null,
      logo: formData.logo ? formData.logo.slice(0, 255) : null,
      str: formData.streetAddress.trim(),
      ctVlg: formData.city.trim(),
      dist: formData.district.trim(),
      stId: formData.state ? Number(formData.state) : null,
      znNm: formData.zone,
      pin: formData.pincode.trim(),
      flatPlotDoor: formData.flatPlotDoor.trim(),        // now included in payload
      landMark: formData.landMark ? formData.landMark.trim() : null,
      addlRem: formData.remarks ? formData.remarks.trim() : null,
      sts: formData.status === "Active"
    };

    setLoading(true);
    fetch(isEditing ? `${apiBaseUrl}/api/companies/${editingId}` : `${apiBaseUrl}/api/companies`, {
      method: isEditing ? "PUT" : "POST",
      headers: getAuthHeaders(),
      body: JSON.stringify(companyPayload)
    })
    .then(async (response) => {
      if (!response.ok) {
        const errorText = await response.text();
        let errorMsg = "Failed to save company";
        try {
          const parsed = JSON.parse(errorText);
          if (parsed.message) errorMsg = parsed.message;
          else if (parsed.error && parsed.status) {
            errorMsg = `Server Error (${parsed.status}): ${parsed.error}. Please check the data constraints or duplicate values.`;
          }
        } catch(e) {
          errorMsg = errorText || errorMsg;
        }
        throw new Error(errorMsg);
      }
      triggerAlert("success", "Success", isEditing ? "Company updated successfully!" : "Company created successfully!");
      fetchCompanies();
      handleResetForm();
      setIsEditing(false);
      setEditingId(null);
      setView("list");
    })
    .catch((err) => {
      console.error("Save company failed:", err);
      triggerAlert("error", "Error", err.message || "Could not connect to server or save company.");
    })
    .finally(() => setLoading(false));
  };

  const handleEdit = (company) => {
    setFormData({
      companyName: company.coyNm || "",
      companyCode: company.coyCd || "",
      under: company.prntCoyId ? company.prntCoyId.toString() : "Independent",
      cinNumber: company.cin || "",
      gstNumber: company.gstNum || "",
      panNumber: company.panNum || "",
      tanNumber: company.tanNum || "",
      incorporationDate: company.incDt || "",
      flatPlotDoor: company.flatPlotDoor || "",
      streetAddress: company.str || "",
      landMark: company.landMark || "",
      city: company.ctVlg || "",
      district: company.dist || "",
      state: company.stId ? company.stId.toString() : "",
      zone: company.znNm || "",
      pincode: company.pin || "",
      email: company.email || "",
      remarks: company.addlRem || "",
      website: company.webUrl || "",
      logo: company.logo || null,
      status: company.sts ? "Active" : "Inactive"
    });
    setIsEditing(true);
    setEditingId(company.coyId);
    setActiveDropdown(null);
    setView("form");
  };

  const toggleDropdown = (id) => {
    setActiveDropdown(prev => (prev === id ? null : id));
  };

  const triggerDeactivate = (id) => {
    setDeactivateTargetId(id);
    setShowDeactivateModal(true);
    setActiveDropdown(null);
  };

  const confirmDeactivate = async () => {
    const company = companies.find(c => c.coyId === deactivateTargetId);
    if (!company) return;

    const companyPayload = {
      ...company,
      sts: false
    };

    setLoading(true);
    try {
      const response = await fetch(`${apiBaseUrl}/api/companies/${deactivateTargetId}`, {
        method: "PUT",
        headers: getAuthHeaders(),
        body: JSON.stringify(companyPayload)
      });
      if (!response.ok) throw new Error("Failed to deactivate company");
      triggerAlert("success", "Success", "Company deactivated successfully!");
      fetchCompanies();
    } catch (err) {
      console.error("Deactivate company failed:", err);
      triggerAlert("error", "Error", "Could not deactivate company.");
    } finally {
      setLoading(false);
    }

    setShowDeactivateModal(false);
    setDeactivateTargetId(null);
  };

  const handleDelete = async (id) => {
    if (window.confirm("Are you sure you want to delete this company?")) {
      setLoading(true);
      try {
        const response = await fetch(`${apiBaseUrl}/api/companies/${id}`, {
          method: "DELETE",
          headers: getAuthHeaders()
        });
        if (!response.ok) {
          const errorText = await response.text();
          let errorMsg = "Could not delete company.";
          try {
            const parsed = JSON.parse(errorText);
            if (parsed.message) errorMsg = parsed.message;
            else if (parsed.error && parsed.status === 500) {
              errorMsg = "Cannot delete this company because it is currently linked to other records (like a subsidiary company or a plant). Please remove those links first or deactivate the company instead.";
            } else if (parsed.error) {
              errorMsg = parsed.error;
            }
          } catch(e) {
            errorMsg = errorText || errorMsg;
          }
          throw new Error(errorMsg);
        }
        triggerAlert("success", "Success", "Company deleted successfully!");
        fetchCompanies();
      } catch (err) {
        console.error("Delete company failed:", err);
        triggerAlert("error", "Error", err.message || "Could not delete company.");
      } finally {
        setLoading(false);
      }
      setActiveDropdown(null);
    }
  };

  // Sorting calculation
  const handleSort = (key) => {
    let direction = 'asc';
    if (sortConfig.key === key && sortConfig.direction === 'asc') {
      direction = 'desc';
    }
    setSortConfig({ key, direction });
  };

  const sortedCompanies = React.useMemo(() => {
    let sortable = [...companies];
    if (sortConfig.key !== null) {
      sortable.sort((a, b) => {
        let valA = "";
        let valB = "";
        if (sortConfig.key === "companyName") {
          valA = (a.coyNm || "").toString().toLowerCase();
          valB = (b.coyNm || "").toString().toLowerCase();
        } else if (sortConfig.key === "companyCode") {
          valA = (a.coyCd || "").toString().toLowerCase();
          valB = (b.coyCd || "").toString().toLowerCase();
        } else if (sortConfig.key === "state") {
          const stateAObj = states.find(s => s.stId === a.stId);
          const stateBObj = states.find(s => s.stId === b.stId);
          valA = (stateAObj ? stateAObj.stNm : "").toString().toLowerCase();
          valB = (stateBObj ? stateBObj.stNm : "").toString().toLowerCase();
        } else {
          valA = (a[sortConfig.key] || "").toString().toLowerCase();
          valB = (b[sortConfig.key] || "").toString().toLowerCase();
        }
        if (valA < valB) return sortConfig.direction === 'asc' ? -1 : 1;
        if (valA > valB) return sortConfig.direction === 'asc' ? 1 : -1;
        return 0;
      });
    }
    return sortable;
  }, [companies, sortConfig, states]);

  const currentItems = sortedCompanies;

  return (
    <div className="cc-shell-container">
      {/* Sidebar Navigation */}
      <Sidebar userRole={userRole} onLogout={onLogout} />

      {/* Main Container Viewport */}
      <div className="cc-shell">

        {/* ======================= DYNAMIC HEADER ======================= */}
        <Header
          title="Company Master"
          showSearch={false}
          userName="Syed Mohammad Johny Basha"
          userRole="Web Developer"
          initials="SB"
        />

        <main className="cc-main" style={{ padding: '24px' }}>

          {/* Breadcrumb Navigation */}


          {view === "form" ? (
            /* ================= VIEW: ADD NEW COMPANY FORM ================= */
            <>
              <div className="cc-content" style={{ paddingBottom: '80px', maxWidth: '1280px', margin: '0 auto' }}>

                {/* Form Card */}
                <div className="cc-form-card" style={{
                  backgroundColor: 'white',
                  borderRadius: '8px',
                  border: '1px solid #e2e8f0',
                  overflow: 'hidden',
                  boxShadow: '0 1px 3px rgba(0,0,0,0.05)'
                }}>

                  {/* Form Header with Title and Back Button */}
                  <div style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    padding: '20px 24px',
                    borderBottom: '1px solid #e2e8f0',
                    backgroundColor: '#fafbfc'
                  }}>
                    <h2 style={{
                      fontSize: '20px',
                      fontWeight: '700',
                      color: '#0f172a',
                      margin: 0
                    }}>
                      {isEditing ? "Edit Company" : "Add New Company"}
                    </h2>
                    <button
                      type="button"
                      className="cc-nav-view-btn"
                      onClick={() => {
                        setView("list");
                        handleResetForm();
                        setIsEditing(false);
                        setEditingId(null);
                      }}
                    >
                      <ChevronLeft size={15} /> Back to Company List
                    </button>
                  </div>

                  {/* Form Body */}
                  <div style={{ padding: '24px' }}>

                    {/* 1. Company Details */}
                    <section className="cc-panel" style={{ backgroundColor: 'white', padding: 0, border: 'none', marginBottom: '32px' }}>

                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                        <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', margin: 0 }}>
                          Company Details
                        </h3>

                        {/* Status Toggle Bar */}
                        <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                          <span style={{ fontSize: "14px", fontWeight: "600", color: "#475569" }}>Status:</span>

                          <label style={{ position: "relative", display: "inline-block", width: "46px", height: "26px", margin: 0 }}>
                            <input
                              type="checkbox"
                              checked={formData.status === "Active"}
                              onChange={handleToggleStatus}
                              style={{ opacity: 0, width: 0, height: 0 }}
                            />
                            <span style={{
                              position: "absolute", cursor: "pointer", top: 0, left: 0, right: 0, bottom: 0,
                              backgroundColor: formData.status === "Active" ? "#10b981" : "#cbd5e1",
                              transition: ".4s", borderRadius: "34px"
                            }}>
                              <span style={{
                                position: "absolute", height: "20px", width: "20px",
                                left: formData.status === "Active" ? "23px" : "3px", bottom: "3px",
                                backgroundColor: "white", transition: ".4s", borderRadius: "50%",
                                boxShadow: "0 2px 4px rgba(0,0,0,0.1)"
                              }}></span>
                            </span>
                          </label>

                          <span style={{
                            fontSize: "14px", fontWeight: "600", minWidth: "60px",
                            color: formData.status === "Active" ? "#16a34a" : "#dc2626"
                          }}>
                            {formData.status}
                          </span>
                        </div>
                      </div>

                      <div className="cc-form-layout-row columns-4">
                        <label className="cc-field-item">
                          <span>Company Name <b style={{ color: '#ef4444' }}>*</b></span>
                          <input type="text" name="companyName" value={formData.companyName} onChange={handleInputChange} placeholder="Enter company name" maxLength={100} />
                        </label>
                        <label className="cc-field-item">
                          <span>Company Code <b style={{ color: '#ef4444' }}>*</b></span>
                          <input type="text" name="companyCode" value={formData.companyCode} onChange={handleInputChange} placeholder="Enter code" maxLength={10} />
                          <small style={{ color: '#64748b', fontSize: '12px', marginTop: '4px' }}>Must be unique.</small>
                        </label>
                        <label className="cc-field-item">
                          <span>Under / Subsidiary <b style={{ color: '#ef4444' }}>*</b></span>
                          <select name="under" value={formData.under} onChange={handleInputChange} style={{ backgroundColor: 'white' }}>
                            <option value="" disabled hidden>Select Parent Company</option>
                            {companies.map((c) => (
                              <option key={c.coyId} value={c.coyId}>{c.coyNm}</option>
                            ))}
                            <option value="Independent" style={{ fontWeight: "bold" }}>Independent (No Parent)</option>
                          </select>
                        </label>
                        <label className="cc-field-item">
                          <span>CIN Number <b style={{ color: '#ef4444' }}>*</b></span>
                          <input type="text" name="cinNumber" value={formData.cinNumber} onChange={handleInputChange} placeholder="Enter CIN number" maxLength={21} />
                        </label>
                      </div>

                      <div className="cc-form-layout-row columns-4" style={{ marginTop: '20px' }}>
                        <label className="cc-field-item">
                          <span>GST Number</span>
                          <input type="text" name="gstNumber" value={formData.gstNumber} onChange={handleInputChange} placeholder="Enter GST number" maxLength={20} />
                        </label>
                        <label className="cc-field-item">
                          <span>PAN Number <b style={{ color: '#ef4444' }}>*</b></span>
                          <input type="text" name="panNumber" value={formData.panNumber} onChange={handleInputChange} placeholder="Enter PAN number" maxLength={10} />
                        </label>
                        <label className="cc-field-item">
                          <span>TAN Number <b style={{ color: '#ef4444' }}>*</b></span>
                          <input type="text" name="tanNumber" value={formData.tanNumber} onChange={handleInputChange} placeholder="Enter TAN number" maxLength={15} />
                        </label>
                        <label className="cc-field-item">
                          <span>Incorporation Date <b style={{ color: '#ef4444' }}>*</b></span>
                          <input type="date" name="incorporationDate" value={formData.incorporationDate} onChange={handleInputChange} />
                        </label>
                      </div>

                      <div className="cc-form-layout-row columns-4" style={{ marginTop: '20px' }}>
                        <label className="cc-field-item">
                          <span>Company Logo</span>
                          <div className="cc-logo-row">
                            <div className="cc-logo-box" style={{ width: '48px', height: '48px', border: '1px solid #e2e8f0', borderRadius: '6px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f8fafc', overflow: 'hidden' }}>
                              {formData.logo ? <img src={formData.logo} alt="Logo" style={{ width: '100%', height: '100%', objectFit: 'cover' }} /> : <ImageIcon size={22} style={{ color: '#94a3b8' }} />}
                            </div>
                            <input id="logoUploadHidden" type="file" accept="image/*" onChange={handleLogoChange} hidden />
                            <button type="button" onClick={() => document.getElementById("logoUploadHidden").click()} style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '8px 12px', background: '#f1f5f9', border: '1px solid #e2e8f0', borderRadius: '6px', fontSize: '13px', color: '#0f172a', cursor: 'pointer' }}>
                              <Upload size={14} /> Upload Logo
                            </button>
                          </div>
                        </label>
                      </div>
                    </section>

                    {/* 2. Address Information */}
                    <section className="cc-panel" style={{ backgroundColor: 'white', padding: 0, border: 'none', marginBottom: '32px' }}>
                      <h3 className="cc-section-title" style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', marginBottom: '20px', borderBottom: '1px solid #e2e8f0', paddingBottom: '12px' }}>Address Information</h3>
                      <div className="cc-form-layout-row columns-3">
                        <label className="cc-field-item">
                          <span>Flat/Plot/Door No <b style={{ color: '#ef4444' }}>*</b></span>  {/* MANDATORY INDICATOR ADDED */}
                          <input type="text" name="flatPlotDoor" value={formData.flatPlotDoor} onChange={handleInputChange} placeholder="Enter flat/plot/door number" maxLength={50} />
                        </label>
                        <label className="cc-field-item">
                          <span>Street Address <b style={{ color: '#ef4444' }}>*</b></span>
                          <input type="text" name="streetAddress" value={formData.streetAddress} onChange={handleInputChange} placeholder="Enter street address" maxLength={50} />
                        </label>
                        <label className="cc-field-item">
                          <span>Land Mark</span>
                          <input type="text" name="landMark" value={formData.landMark} onChange={handleInputChange} placeholder="Enter landmark" maxLength={50} />
                        </label>
                      </div>

                      <div className="cc-form-layout-row columns-4" style={{ marginTop: '20px' }}>
                        <label className="cc-field-item">
                          <span>City/Village <b style={{ color: '#ef4444' }}>*</b></span>
                          <input type="text" name="city" value={formData.city} onChange={handleInputChange} placeholder="Enter city/village" maxLength={30} />
                        </label>
                        <label className="cc-field-item">
                          <span>District <b style={{ color: '#ef4444' }}>*</b></span>
                          <input type="text" name="district" value={formData.district} onChange={handleInputChange} placeholder="Enter district" maxLength={30} />
                        </label>
                        <label className="cc-field-item">
                          <span>State <b style={{ color: '#ef4444' }}>*</b></span>
                          <select name="state" value={formData.state} onChange={handleStateChange} style={{ backgroundColor: 'white' }}>
                            <option value="" disabled hidden>Select State</option>
                            {states.map((s) => (
                              <option key={s.stId} value={s.stId}>{s.stNm}</option>
                            ))}
                          </select>
                        </label>
                        <label className="cc-field-item">
                          <span>Zone <b style={{ color: '#ef4444' }}>*</b></span>
                          <input
                            type="text"
                            name="zone"
                            value={formData.zone}
                            readOnly
                            className="cc-readonly-input"
                            placeholder="Auto-fills from State"
                          />
                        </label>
                      </div>

                      <div className="cc-form-layout-row columns-4" style={{ marginTop: '20px' }}>
                        <label className="cc-field-item">
                          <span>Pincode <b style={{ color: '#ef4444' }}>*</b></span>
                          <input type="text" name="pincode" value={formData.pincode} onChange={handleInputChange} placeholder="Enter 6-digit pincode" maxLength={6} />
                        </label>
                      </div>
                    </section>

                    {/* 3. Contact Information */}
                    <section className="cc-panel" style={{ backgroundColor: 'white', padding: 0, border: 'none', marginBottom: '32px' }}>
                      <h3 className="cc-section-title" style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', marginBottom: '20px', borderBottom: '1px solid #e2e8f0', paddingBottom: '12px' }}>Contact Information</h3>
                      <div className="cc-form-layout-row columns-2">
                        <label className="cc-field-item">
                          <span>Email <b style={{ color: '#ef4444' }}>*</b></span>
                          <input type="email" name="email" value={formData.email} onChange={handleInputChange} placeholder="Enter email address" maxLength={100} />
                        </label>
                        <label className="cc-field-item">
                          <span>Website URL</span>
                          <input type="url" name="website" value={formData.website} onChange={handleInputChange} placeholder="https://www.example.com" maxLength={100} />
                        </label>
                      </div>

                      <div className="cc-form-layout-row columns-1" style={{ marginTop: '20px' }}>
                        <label className="cc-field-item">
                          <span>Additional Remarks</span>
                          <textarea name="remarks" value={formData.remarks} onChange={handleInputChange} placeholder="Enter additional remarks" rows={3} maxLength={255} />
                        </label>
                      </div>
                    </section>
                  </div>

                  {/* Form Footer Buttons */}
                  <div className="cc-form-footer" style={{
                    display: 'flex',
                    justifyContent: 'flex-end',
                    gap: '12px',
                    padding: '16px 24px',
                    backgroundColor: '#fafbfc',
                    borderTop: '1px solid #e2e8f0'
                  }}>
                    <button type="button" className="cc-btn secondary" onClick={() => {
                      setView("list");
                      handleResetForm();
                      setIsEditing(false);
                      setEditingId(null);
                    }}>
                      Cancel
                    </button>
                    <button type="button" className="cc-btn tertiary" onClick={handleResetForm}>
                      <RefreshCcw size={14} /> Reset
                    </button>
                    <button type="button" className="cc-btn primary" onClick={handleSave}>
                      <Save size={14} /> {isEditing ? "Update Company" : "Save Company"}
                    </button>
                  </div>
                </div>
              </div>
            </>
          ) : (
            /* ================= VIEW: COMPANY LIST ================= */
            <div className="cc-content" style={{ maxWidth: '1280px', margin: '0 auto' }}>

              {/* INTEGRATED CARD FOR FILTERS, ADD BUTTON AND TABLE - Matching Screenshot Layout */}
              <div className="cc-table-panel" style={{ backgroundColor: 'white', borderRadius: '8px', border: '1px solid #e2e8f0', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>

                {/* Header with Title and Add New Button - Inside Card */}
                <div style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  padding: '20px 24px',
                  borderBottom: '1px solid #e2e8f0'
                }}>
                  <div>
                    <h2 style={{ fontSize: '18px', fontWeight: '700', color: '#0f172a', margin: 0 }}>
                      Company List
                    </h2>
                    <p style={{ color: '#64748b', margin: '4px 0 0 0', fontSize: '14px' }}>
                      View and manage all company records
                    </p>
                  </div>
                  <button
                    type="button"
                    className="cc-btn-add-new"
                    onClick={() => {
                      handleResetForm();
                      setIsEditing(false);
                      setView("form");
                    }}
                  >
                    <Plus size={16} /> Add New Company
                  </button>
                </div>

                {/* Data Table Section Inside the Card */}
                <div className="cc-table-container" style={{ overflowX: 'auto' }}>
                  <table className="cc-list-table" style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', minWidth: '2200px' }}>
                    <thead style={{ backgroundColor: '#f8fafc', borderBottom: '2px solid #e2e8f0' }}>
                      <tr>
                        <th style={{ width: "50px", padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>#</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>LOGO</th>
                        <th
                          className="sortable"
                          onClick={() => handleSort("companyName")}
                          style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', cursor: 'pointer', textTransform: 'uppercase', letterSpacing: '0.5px' }}
                        >
                          COMPANY NAME{" "}
                          {sortConfig.key === "companyName" &&
                            (sortConfig.direction === "asc" ? "▲" : "▼")}
                        </th>
                        <th
                          className="sortable"
                          onClick={() => handleSort("companyCode")}
                          style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', cursor: 'pointer', textTransform: 'uppercase', letterSpacing: '0.5px' }}
                        >
                          CODE{" "}
                          {sortConfig.key === "companyCode" &&
                            (sortConfig.direction === "asc" ? "▲" : "▼")}
                        </th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>UNDER</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>CIN NUMBER</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>GST NUMBER</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>PAN NUMBER</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>TAN NUMBER</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>INCORPORATION DATE</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>FLAT/PLOT/DOOR</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>STREET ADDRESS</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>LANDMARK</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>CITY</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>DISTRICT</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>STATE</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>ZONE</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>PINCODE</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>EMAIL</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>REMARKS</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>WEBSITE</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>STATUS</th>
                        <th style={{ textAlign: "center", width: "100px", padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                          ACTIONS
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {currentItems.length > 0 ? (
                        currentItems.map((company, index) => (
                          <tr key={company.coyId} style={{ borderBottom: '1px solid #f1f5f9' }}>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{index + 1}</td>
                            <td style={{ padding: '14px 20px' }}>
                              {company.logo ? (
                                <img src={company.logo} alt="Logo" style={{ width: '32px', height: '32px', borderRadius: '4px', objectFit: 'cover', border: '1px solid #e2e8f0' }} />
                              ) : (
                                <div style={{ width: '32px', height: '32px', borderRadius: '4px', background: '#f1f5f9', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px solid #e2e8f0' }}>
                                  <Building2 size={16} style={{ color: '#94a3b8' }} />
                                </div>
                              )}
                            </td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}><strong>{company.coyNm}</strong></td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>
                              <span style={{ backgroundColor: '#f1f5f9', padding: '4px 10px', borderRadius: '4px', fontWeight: '600', color: '#0f172a', border: '1px solid #e2e8f0', fontSize: '13px' }}>
                                {company.coyCd}
                              </span>
                            </td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{companies.find(c => c.coyId === company.prntCoyId)?.coyNm || "Independent"}</td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{company.cin || "N/A"}</td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{company.gstNum || "N/A"}</td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{company.panNum}</td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{company.tanNum || "N/A"}</td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{company.incDt || "N/A"}</td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{company.flatPlotDoor || "N/A"}</td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{company.str || "N/A"}</td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{company.landMark || "N/A"}</td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{company.ctVlg || "N/A"}</td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{company.dist || "N/A"}</td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{states.find(s => Number(s.stId) === Number(company.stId))?.stNm || "N/A"}</td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{company.znNm || "N/A"}</td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{company.pin || "N/A"}</td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{company.email}</td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{company.addlRem || "N/A"}</td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{company.webUrl || "N/A"}</td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>
                              <span
                                style={{
                                  padding: '4px 12px',
                                  borderRadius: '12px',
                                  fontSize: '12px',
                                  fontWeight: '600',
                                  display: 'inline-block',
                                  backgroundColor: company.sts ? '#dcfce7' : '#fee2e2',
                                  color: company.sts ? '#166534' : '#991b1b'
                                }}
                              >
                                {company.sts ? 'Active' : 'Inactive'}
                              </span>
                            </td>
                            <td style={{ position: "relative", padding: '14px 20px', textAlign: 'center' }}>
                              <button
                                type="button"
                                style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#64748b', padding: '4px 8px', borderRadius: '4px' }}
                                onClick={() => toggleDropdown(company.coyId)}
                                onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f1f5f9'}
                                onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
                              >
                                <MoreVertical size={18} />
                              </button>

                              {/* Actions Dropdown menu */}
                              {activeDropdown === company.coyId && (
                                <>
                                  <div
                                    className="cc-actions-dropdown-backdrop"
                                    onClick={() => setActiveDropdown(null)}
                                    style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, zIndex: 9 }}
                                  />
                                  <div className="cc-actions-dropdown-menu" style={{ position: 'absolute', right: '30px', top: '8px', backgroundColor: 'white', border: '1px solid #e2e8f0', borderRadius: '8px', boxShadow: '0 4px 12px rgba(0,0,0,0.15)', zIndex: 10, display: 'flex', flexDirection: 'column', padding: '4px 0', minWidth: '140px' }}>
                                    <button
                                      type="button"
                                      style={{ padding: '10px 16px', textAlign: 'left', background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px', color: '#334155', borderRadius: '4px', margin: '2px 4px' }}
                                      onClick={() => {
                                        triggerAlert(
                                          "info",
                                          "Company Details",
                                          `Company Details:\nName: ${company.coyNm}\nCode: ${company.coyCd}\nCIN: ${company.cin || 'N/A'}\nGST: ${company.gstNum || 'N/A'}\nPAN: ${company.panNum}\nState: ${states.find(s => Number(s.stId) === Number(company.stId))?.stNm || "N/A"}\nZone: ${company.znNm}\nEmail: ${company.email}\nStatus: ${company.sts ? "Active" : "Inactive"}`
                                        );
                                        setActiveDropdown(null);
                                      }}
                                      onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f1f5f9'}
                                      onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
                                    >
                                      <Eye size={15} /> View
                                    </button>
                                    <button
                                      type="button"
                                      style={{ padding: '10px 16px', textAlign: 'left', background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px', color: '#334155', borderRadius: '4px', margin: '2px 4px' }}
                                      onClick={() => handleEdit(company)}
                                      onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f1f5f9'}
                                      onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
                                    >
                                      <Edit size={15} /> Edit
                                    </button>
                                    <button
                                      type="button"
                                      style={{ padding: '10px 16px', textAlign: 'left', background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px', color: '#ef4444', borderRadius: '4px', margin: '2px 4px' }}
                                      onClick={() => triggerDeactivate(company.coyId)}
                                      onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#fef2f2'}
                                      onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
                                    >
                                      <Trash2 size={15} /> Deactivate
                                    </button>
                                    <button
                                      type="button"
                                      style={{ padding: '10px 16px', textAlign: 'left', background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px', color: '#ef4444', borderRadius: '4px', margin: '2px 4px' }}
                                      onClick={() => handleDelete(company.coyId)}
                                      onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#fef2f2'}
                                      onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
                                    >
                                      <Trash2 size={15} /> Delete
                                    </button>
                                  </div>
                                </>
                              )}
                            </td>
                          </tr>
                        ))
                      ) : (
                        <tr>
                          <td colSpan="23" style={{ textAlign: "center", padding: "60px 20px", color: '#64748b', fontSize: '14px' }}>
                            No company records found. Add a new company using the button above.
                          </td>
                        </tr>
                      )}
</tbody>
                  </table>
                </div>


              </div>
            </div>
          )}
        </main>
      </div>

      {/* Deactivation Confirmation Modal */}
      {showDeactivateModal && (
        <div className="cc-modal-overlay" style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.5)', zIndex: 99, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div className="cc-modal" style={{ backgroundColor: 'white', borderRadius: '8px', width: '400px', maxWidth: '90%', boxShadow: '0 10px 15px -3px rgba(0,0,0,0.1)' }}>
            <div className="cc-modal-header" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 20px', borderBottom: '1px solid #e2e8f0' }}>
              <h3 style={{ margin: 0, fontSize: '16px', fontWeight: '700', color: '#1e293b' }}>Deactivate Company Record</h3>
              <button
                type="button"
                className="cc-modal-close"
                onClick={() => setShowDeactivateModal(false)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#64748b' }}
              >
                <X size={18} />
              </button>
            </div>
            <div className="cc-modal-body" style={{ padding: '20px' }}>
              <p style={{ margin: '0 0 8px 0', color: '#334155', fontSize: '14px' }}>Are you sure you want to deactivate this company record?</p>
              <p className="cc-modal-warning" style={{ margin: 0, color: '#ef4444', fontSize: '13px', fontWeight: '500' }}>
                This will change its status to Inactive.
              </p>
            </div>
            <div className="cc-modal-footer" style={{ padding: '16px 20px', borderTop: '1px solid #e2e8f0', display: 'flex', justifyContent: 'flex-end', gap: '10px', backgroundColor: '#f8fafc' }}>
              <button
                type="button"
                className="cc-btn-cancel-modal"
                onClick={() => setShowDeactivateModal(false)}
              >
                Cancel
              </button>
              <button
                type="button"
                className="cc-btn-delete-modal"
                onClick={confirmDeactivate}
              >
                <Trash2 size={14} /> Deactivate
              </button>
            </div>
          </div>
        </div>
      )}

      <AlertModal
        isOpen={alertConfig.isOpen}
        type={alertConfig.type}
        title={alertConfig.title}
        message={alertConfig.message}
        onClose={() => setAlertConfig(prev => ({ ...prev, isOpen: false }))}
      />
    </div>
  );
};

export default CompanyCreation;