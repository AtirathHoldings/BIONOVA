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
import "../../styles/CompanyCreation.css";

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

const CompanyCreation = ({ onLogout, userRole }) => {
  const navigate = useNavigate();

  // ─── Local storage – starts with an empty array ──────────────────────────
  const [companies, setCompanies] = useState(() => {
    const saved = localStorage.getItem("companies");
    return saved ? JSON.parse(saved) : [];
  });

  useEffect(() => {
    localStorage.setItem("companies", JSON.stringify(companies));
  }, [companies]);

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

  const [formError, setFormError] = useState("");

  // Search Filter state
  const [searchInputs, setSearchInputs] = useState({
    companyName: '',
    companyCode: '',
    status: ''
  });

  const [activeFilters, setActiveFilters] = useState({
    companyName: '',
    companyCode: '',
    status: ''
  });

  // Table action dropdown trigger state
  const [activeDropdown, setActiveDropdown] = useState(null);

  // Deactivation confirmation modal state
  const [showDeactivateModal, setShowDeactivateModal] = useState(false);
  const [deactivateTargetId, setDeactivateTargetId] = useState(null);

  // Sorting state
  const [sortConfig, setSortConfig] = useState({ key: null, direction: 'asc' });

  // Pagination state
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 8;

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
    }

    setFormData(prev => ({ ...prev, [name]: newValue }));
    setFormError("");
  };

  const handleToggleStatus = (e) => {
    setFormData(prev => ({ ...prev, status: e.target.checked ? "Active" : "Inactive" }));
    setFormError("");
  };

  const handleStateChange = (e) => {
    const selectedState = e.target.value;
    const mappedZone = stateToZoneMap[selectedState] || "";
    setFormData(prev => ({ 
      ...prev, 
      state: selectedState, 
      zone: mappedZone 
    }));
    setFormError("");
  };

  const handleLogoChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onloadend = () => setFormData((prev) => ({ ...prev, logo: reader.result }));
    reader.readAsDataURL(file);
  };

  // Filter input change handler
  const handleFilterChange = (e) => {
    const { name, value } = e.target;
    setSearchInputs(prev => ({ ...prev, [name]: value }));
  };

  const applySearch = () => {
    setActiveFilters({ ...searchInputs });
    setCurrentPage(1);
  };

  const resetFilters = () => {
    const cleared = { companyName: '', companyCode: '', status: '' };
    setSearchInputs(cleared);
    setActiveFilters(cleared);
    setCurrentPage(1);
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
    setFormError("");
  };

  const handleSave = () => {
    // Required fields check
    if (
      !formData.companyName.trim() ||
      !formData.companyCode.trim() ||
      !formData.panNumber.trim() ||
      !formData.tanNumber.trim() ||
      !formData.incorporationDate.trim() ||
      !formData.city.trim() ||
      !formData.district.trim() ||
      !formData.state.trim() ||
      !formData.pincode.trim() ||
      !formData.email.trim()
    ) {
      setFormError("Please fill in all required fields marked with *");
      return;
    }

    // Unique Company Code check
    const isDuplicate = companies.some(
      c => c.companyCode.toLowerCase().trim() === formData.companyCode.toLowerCase().trim() && c.id !== editingId
    );

    if (isDuplicate) {
      setFormError("Company code must be unique. This code already exists.");
      return;
    }

    if (isEditing) {
      setCompanies(prev =>
        prev.map(c => (c.id === editingId ? { ...formData, id: editingId } : c))
      );
      setIsEditing(false);
      setEditingId(null);
    } else {
      const newCompany = {
        id: Date.now(),
        ...formData
      };
      setCompanies(prev => [...prev, newCompany]);
    }

    handleResetForm();
    setView("list");
  };

  const handleEdit = (company) => {
    setFormData({ ...company });
    setIsEditing(true);
    setEditingId(company.id);
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

  const confirmDeactivate = () => {
    setCompanies(prev =>
      prev.map(c => (c.id === deactivateTargetId ? { ...c, status: "Inactive" } : c))
    );
    setShowDeactivateModal(false);
    setDeactivateTargetId(null);
  };

  const handleDelete = (id) => {
    if (window.confirm("Are you sure you want to delete this company?")) {
      setCompanies(prev => prev.filter(c => c.id !== id));
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
        const valA = (a[sortConfig.key] || "").toString().toLowerCase();
        const valB = (b[sortConfig.key] || "").toString().toLowerCase();
        if (valA < valB) return sortConfig.direction === 'asc' ? -1 : 1;
        if (valA > valB) return sortConfig.direction === 'asc' ? 1 : -1;
        return 0;
      });
    }
    return sortable;
  }, [companies, sortConfig]);

  // Filter calculations
  const filteredCompanies = sortedCompanies.filter(c => {
    const matchName = !activeFilters.companyName || 
      c.companyName?.toLowerCase().includes(activeFilters.companyName.toLowerCase());
    const matchCode = !activeFilters.companyCode || 
      c.companyCode?.toLowerCase().includes(activeFilters.companyCode.toLowerCase());
    const matchStatus = !activeFilters.status || c.status === activeFilters.status;
    return matchName && matchCode && matchStatus;
  });

  // Pagination calculations
  const indexOfLastItem = currentPage * itemsPerPage;
  const indexOfFirstItem = indexOfLastItem - itemsPerPage;
  const currentItems = filteredCompanies.slice(indexOfFirstItem, indexOfLastItem);
  const totalPages = Math.ceil(filteredCompanies.length / itemsPerPage);

  const paginate = (pageNumber) => setCurrentPage(pageNumber);

  return (
    <div className="cc-shell-container">
      {/* Sidebar Navigation */}
      <Sidebar userRole={userRole} onLogout={onLogout} />

      {/* Main Container Viewport */}
      <div className="cc-shell">
        
        {/* ======================= DYNAMIC HEADER ======================= */}
        <Header 
          title="Company Creation" 
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
                    {formError && <div className="cc-form-error" style={{ color: '#dc2626', marginBottom: '20px', padding: '12px 16px', backgroundColor: '#fef2f2', borderLeft: '4px solid #dc2626', borderRadius: '6px', fontWeight: '500' }}>{formError}</div>}

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
                          <span>Company Name <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="companyName" value={formData.companyName} onChange={handleInputChange} placeholder="Enter company name" maxLength={100} />
                        </label>
                        <label className="cc-field-item">
                          <span>Company Code <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="companyCode" value={formData.companyCode} onChange={handleInputChange} placeholder="Enter code" maxLength={10} />
                          <small style={{ color: '#64748b', fontSize: '12px', marginTop: '4px' }}>Must be unique.</small>
                        </label>
                        <label className="cc-field-item">
                          <span>Under / Subsidiary <b style={{color: '#ef4444'}}>*</b></span>
                          <select name="under" value={formData.under} onChange={handleInputChange} style={{ backgroundColor: 'white' }}>
                            <option value="" disabled hidden>Select Parent Company</option>
                            {companies.map((c) => (
                              <option key={c.id} value={c.companyName}>{c.companyName}</option>
                            ))}
                            <option value="Independent" style={{ fontWeight: "bold" }}>Independent (No Parent)</option>
                          </select>
                        </label>
                        <label className="cc-field-item">
                          <span>CIN Number <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="cinNumber" value={formData.cinNumber} onChange={handleInputChange} placeholder="Enter CIN number" maxLength={25} />
                        </label>
                      </div>

                      <div className="cc-form-layout-row columns-4" style={{ marginTop: '20px' }}>
                        <label className="cc-field-item">
                          <span>GST Number</span>
                          <input type="text" name="gstNumber" value={formData.gstNumber} onChange={handleInputChange} placeholder="Enter GST number" maxLength={20} />
                        </label>
                        <label className="cc-field-item">
                          <span>PAN Number <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="panNumber" value={formData.panNumber} onChange={handleInputChange} placeholder="Enter PAN number" maxLength={15} />
                        </label>
                        <label className="cc-field-item">
                          <span>TAN Number <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="tanNumber" value={formData.tanNumber} onChange={handleInputChange} placeholder="Enter TAN number" maxLength={15} />
                        </label>
                        <label className="cc-field-item">
                          <span>Incorporation Date <b style={{color: '#ef4444'}}>*</b></span>
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
                          <span>Flat/Plot/Door No</span>
                          <input type="text" name="flatPlotDoor" value={formData.flatPlotDoor} onChange={handleInputChange} placeholder="Enter flat/plot/door number" maxLength={50} />
                        </label>
                        <label className="cc-field-item">
                          <span>Street Address <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="streetAddress" value={formData.streetAddress} onChange={handleInputChange} placeholder="Enter street address" maxLength={50} />
                        </label>
                        <label className="cc-field-item">
                          <span>Land Mark</span>
                          <input type="text" name="landMark" value={formData.landMark} onChange={handleInputChange} placeholder="Enter landmark" maxLength={50} />
                        </label>
                      </div>

                      <div className="cc-form-layout-row columns-4" style={{ marginTop: '20px' }}>
                        <label className="cc-field-item">
                          <span>City/Village <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="city" value={formData.city} onChange={handleInputChange} placeholder="Enter city/village" maxLength={30} />
                        </label>
                        <label className="cc-field-item">
                          <span>District <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="district" value={formData.district} onChange={handleInputChange} placeholder="Enter district" maxLength={30} />
                        </label>
                        <label className="cc-field-item">
                          <span>State <b style={{color: '#ef4444'}}>*</b></span>
                          <select name="state" value={formData.state} onChange={handleStateChange} style={{ backgroundColor: 'white' }}>
                            <option value="" disabled hidden>Select State</option>
                            <option value="Andhra Pradesh">Andhra Pradesh</option>
                            <option value="Delhi">Delhi</option>
                            <option value="Gujarat">Gujarat</option>
                            <option value="Karnataka">Karnataka</option>
                            <option value="Kerala">Kerala</option>
                            <option value="Madhya Pradesh">Madhya Pradesh</option>
                            <option value="Maharashtra">Maharashtra</option>
                            <option value="Odisha">Odisha</option>
                            <option value="Punjab">Punjab</option>
                            <option value="Tamil Nadu">Tamil Nadu</option>
                            <option value="Telangana">Telangana</option>
                            <option value="West Bengal">West Bengal</option>
                          </select>
                        </label>
                        <label className="cc-field-item">
                          <span>Zone <b style={{color: '#ef4444'}}>*</b></span>
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
                          <span>Pincode <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="pincode" value={formData.pincode} onChange={handleInputChange} placeholder="Enter 6-digit pincode" maxLength={6} />
                        </label>
                      </div>
                    </section>

                    {/* 3. Contact Information */}
                    <section className="cc-panel" style={{ backgroundColor: 'white', padding: 0, border: 'none', marginBottom: '32px' }}>
                      <h3 className="cc-section-title" style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', marginBottom: '20px', borderBottom: '1px solid #e2e8f0', paddingBottom: '12px' }}>Contact Information</h3>
                      <div className="cc-form-layout-row columns-2">
                        <label className="cc-field-item">
                          <span>Email <b style={{color: '#ef4444'}}>*</b></span>
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

                {/* Filters Section Inside the Card */}
                <div style={{ 
                  display: 'flex', 
                  alignItems: 'flex-end', 
                  gap: '16px', 
                  flexWrap: 'wrap', 
                  padding: '20px 24px',
                  borderBottom: '1px solid #e2e8f0',
                  backgroundColor: '#fafbfc'
                }}>
                  
                  <div style={{ flex: 1, minWidth: '200px' }}>
                    <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', fontWeight: '600', color: '#475569' }}>Company Name</label>
                    <input
                      type="text"
                      name="companyName"
                      value={searchInputs.companyName}
                      onChange={handleFilterChange}
                      placeholder="Filter by company name"
                      style={{ width: '100%', padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '6px', fontSize: '14px', boxSizing: 'border-box', outline: 'none', height: '40px' }}
                    />
                  </div>

                  <div style={{ flex: 1, minWidth: '200px' }}>
                    <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', fontWeight: '600', color: '#475569' }}>Company Code</label>
                    <input
                      type="text"
                      name="companyCode"
                      value={searchInputs.companyCode}
                      onChange={handleFilterChange}
                      placeholder="Filter by company code"
                      style={{ width: '100%', padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '6px', fontSize: '14px', boxSizing: 'border-box', outline: 'none', height: '40px' }}
                    />
                  </div>

                  <div style={{ flex: 1, minWidth: '200px' }}>
                    <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', fontWeight: '600', color: '#475569' }}>Status</label>
                    <select
                      name="status"
                      value={searchInputs.status}
                      onChange={handleFilterChange}
                      style={{ width: '100%', padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '6px', fontSize: '14px', backgroundColor: 'white', boxSizing: 'border-box', outline: 'none', cursor: 'pointer', height: '40px' }}
                    >
                      <option value="">Select status</option>
                      <option value="Active">Active</option>
                      <option value="Inactive">Inactive</option>
                    </select>
                  </div>

                  {/* Filter & Reset Buttons */}
                  <div style={{ display: 'flex', gap: '10px', height: '40px' }}>
                    <button
                      type="button"
                      className="cc-filter-btn search"
                      onClick={applySearch}
                    >
                      <Search size={15} /> Search
                    </button>
                    <button
                      type="button"
                      className="cc-filter-btn reset"
                      onClick={resetFilters}
                    >
                      <RefreshCcw size={15} /> Reset
                    </button>
                  </div>
                </div>

                {/* Data Table Section Inside the Card */}
                <div className="cc-table-container" style={{ overflowX: 'auto' }}>
                  <table className="cc-list-table" style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', minWidth: '900px' }}>
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
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>GST / PAN</th>
                        <th
                          className="sortable"
                          onClick={() => handleSort("state")}
                          style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', cursor: 'pointer', textTransform: 'uppercase', letterSpacing: '0.5px' }}
                        >
                          STATE / ZONE{" "}
                          {sortConfig.key === "state" &&
                            (sortConfig.direction === "asc" ? "▲" : "▼")}
                        </th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>STATUS</th>
                        <th style={{ textAlign: "center", width: "100px", padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                          ACTIONS
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {currentItems.length > 0 ? (
                        currentItems.map((company, index) => (
                          <tr key={company.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{indexOfFirstItem + index + 1}</td>
                            <td style={{ padding: '14px 20px' }}>
                              {company.logo ? (
                                <img src={company.logo} alt="Logo" style={{ width: '32px', height: '32px', borderRadius: '4px', objectFit: 'cover', border: '1px solid #e2e8f0' }} />
                              ) : (
                                <div style={{ width: '32px', height: '32px', borderRadius: '4px', background: '#f1f5f9', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px solid #e2e8f0' }}>
                                  <Building2 size={16} style={{ color: '#94a3b8' }} />
                                </div>
                              )}
                            </td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}><strong>{company.companyName}</strong></td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>
                              <span style={{ backgroundColor: '#f1f5f9', padding: '4px 10px', borderRadius: '4px', fontWeight: '600', color: '#0f172a', border: '1px solid #e2e8f0', fontSize: '13px' }}>
                                {company.companyCode}
                              </span>
                            </td>
                            <td style={{ padding: '14px 20px', fontSize: '13px', color: '#475569', lineHeight: '1.6' }}>
                              <div style={{ display: 'flex', flexDirection: 'column' }}>
                                <span><span style={{ color: '#94a3b8' }}>GST:</span> {company.gstNumber || "N/A"}</span>
                                <span><span style={{ color: '#94a3b8' }}>PAN:</span> <span style={{ fontWeight: '500', color: '#334155' }}>{company.panNumber}</span></span>
                              </div>
                            </td>
                            <td style={{ padding: '14px 20px', fontSize: '13px', color: '#475569', lineHeight: '1.6' }}>
                              <div style={{ display: 'flex', flexDirection: 'column' }}>
                                <span>{company.state}</span>
                                <span style={{ color: '#2563eb', fontWeight: '600' }}>{company.zone || "N/A"}</span>
                              </div>
                            </td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>
                              <span
                                style={{ 
                                  padding: '4px 12px', 
                                  borderRadius: '12px', 
                                  fontSize: '12px', 
                                  fontWeight: '600',
                                  display: 'inline-block',
                                  backgroundColor: company.status === 'Active' ? '#dcfce7' : '#fee2e2',
                                  color: company.status === 'Active' ? '#166534' : '#991b1b'
                                }}
                              >
                                {company.status}
                              </span>
                            </td>
                            <td style={{ position: "relative", padding: '14px 20px', textAlign: 'center' }}>
                              <button
                                type="button"
                                style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#64748b', padding: '4px 8px', borderRadius: '4px' }}
                                onClick={() => toggleDropdown(company.id)}
                                onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f1f5f9'}
                                onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
                              >
                                <MoreVertical size={18} />
                              </button>

                              {/* Actions Dropdown menu */}
                              {activeDropdown === company.id && (
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
                                        alert(
                                          `Company Details:\nName: ${company.companyName}\nCode: ${company.companyCode}\nCIN: ${company.cinNumber || 'N/A'}\nGST: ${company.gstNumber || 'N/A'}\nPAN: ${company.panNumber}\nState: ${company.state}\nZone: ${company.zone}\nEmail: ${company.email}\nStatus: ${company.status}`
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
                                      onClick={() => triggerDeactivate(company.id)}
                                      onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#fef2f2'}
                                      onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
                                    >
                                      <Trash2 size={15} /> Deactivate
                                    </button>
                                    <button
                                      type="button"
                                      style={{ padding: '10px 16px', textAlign: 'left', background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px', color: '#ef4444', borderRadius: '4px', margin: '2px 4px' }}
                                      onClick={() => handleDelete(company.id)}
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
                          <td colSpan="8" style={{ textAlign: "center", padding: "60px 20px", color: '#64748b', fontSize: '14px' }}>
                            No company records found. Add a new company using the button above.
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>

                {/* Pagination bar */}
                {totalPages > 0 && (
                  <div className="cc-table-pagination-bar" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '14px 24px', borderTop: '1px solid #e2e8f0', backgroundColor: '#fafbfc' }}>
                    <span className="cc-pagination-info" style={{ fontSize: '14px', color: '#64748b' }}>
                      Showing {filteredCompanies.length > 0 ? indexOfFirstItem + 1 : 0} to{" "}
                      {Math.min(indexOfLastItem, filteredCompanies.length)} of{" "}
                      {filteredCompanies.length} entries
                    </span>
                    <div className="cc-pagination-controls" style={{ display: 'flex', gap: '4px' }}>
                      <button
                        type="button"
                        className="cc-pag-btn"
                        onClick={() => paginate(currentPage - 1)}
                        disabled={currentPage === 1}
                      >
                        <ChevronLeft size={16} />
                      </button>
                      {Array.from({ length: totalPages }, (_, i) => (
                        <button
                          key={i + 1}
                          className={`cc-pag-btn ${currentPage === i + 1 ? 'active' : ''}`}
                          onClick={() => paginate(i + 1)}
                        >
                          {i + 1}
                        </button>
                      ))}
                      <button
                        type="button"
                        className="cc-pag-btn"
                        onClick={() => paginate(currentPage + 1)}
                        disabled={currentPage === totalPages}
                      >
                        <ChevronRight size={16} />
                      </button>
                    </div>
                  </div>
                )}
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
    </div>
  );
};

export default CompanyCreation;