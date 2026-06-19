import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import Sidebar from '../Sidebar';
import Header from '../Header';
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
  Calendar,
  MoreVertical,
  ChevronLeft,
  MapPin,
  Map,
  Upload,
  Image as ImageIcon
} from "lucide-react";
import '../../styles/AgriLandAllocation.css';

const AgriLandAllocation = ({ userRole, onLogout }) => {
  const navigate = useNavigate();

  // ─── No static dropdown data ──────────────────────────────────────────────
  // All fields are text inputs; you can later fetch lists from an API.

  // Local storage – starts with an empty array
  const [allocations, setAllocations] = useState(() => {
    const saved = localStorage.getItem("allocated_lands_data_v2");
    return saved ? JSON.parse(saved) : [];
  });

  useEffect(() => {
    localStorage.setItem("allocated_lands_data_v2", JSON.stringify(allocations));
  }, [allocations]);

  // View toggle – default is "list"
  const [view, setView] = useState("list");
  const [isEditing, setIsEditing] = useState(false);
  const [editingId, setEditingId] = useState(null);

  // Form state – all empty by default
  const [form, setForm] = useState({
    landCode: '',
    plant: '',
    allocationType: '',
    surveyNo: [],
    surveyInput: '',
    landOwnerName: '',
    mobileNo: '',
    state: '',
    zone: '',
    district: '',
    village: '',
    mandal: '',
    pincode: '',
    landArea: '',
    latitude: '',
    longitude: '',
    status: 'Active',
    logo: null
  });

  const [formError, setFormError] = useState("");

  // Search Filter state – text inputs for plant and state
  const [searchInputs, setSearchInputs] = useState({
    plant: '',
    state: '',
    status: ''
  });

  const [activeFilters, setActiveFilters] = useState({
    plant: '',
    state: '',
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

  // Handle standard input changes
  const handleChange = (e) => {
    const { name, value } = e.target;
    let newValue = value;

    if (name === 'landArea') {
      newValue = value.replace(/[^0-9.]/g, '');
      if (newValue && !/^\d{0,10}(\.\d{0,2})?$/.test(newValue)) return;
    } else if (name === 'pincode') {
      newValue = value.replace(/[^0-9]/g, '').slice(0, 6);
    } else if (name === 'mobileNo') {
      newValue = value.replace(/[^0-9]/g, '').slice(0, 10);
    } else if (name === 'latitude') {
      newValue = value.replace(/[^0-9.-]/g, '');
      if (newValue && !/^-?\d{0,2}(\.\d{0,8})?$/.test(newValue)) return;
    } else if (name === 'longitude') {
      newValue = value.replace(/[^0-9.-]/g, '');
      if (newValue && !/^-?\d{0,3}(\.\d{0,8})?$/.test(newValue)) return;
    } else if (name === 'landCode') {
      newValue = value.slice(0, 10);
    } else if (name === 'surveyInput') {
      newValue = value.slice(0, 50);
    } else if (name === 'landOwnerName') {
      newValue = value.slice(0, 100);
    } else if (name === 'village') {
      newValue = value.slice(0, 50);
    } else if (name === 'mandal' || name === 'district') {
      newValue = value.slice(0, 30);
    } else if (name === 'allocationType') {
      newValue = value.slice(0, 3);
    } else if (name === 'state') {
      newValue = value;
      let zoneValue = '';
      const southStates = ['Andhra Pradesh', 'Telangana', 'Karnataka', 'Tamil Nadu', 'Kerala'];
      const northStates = ['Delhi', 'Punjab', 'Haryana', 'Uttar Pradesh'];
      const westStates = ['Maharashtra', 'Gujarat', 'Rajasthan'];
      const eastStates = ['West Bengal', 'Odisha', 'Bihar', 'Jharkhand'];
      const centralStates = ['Madhya Pradesh', 'Chhattisgarh'];
      const northEastStates = ['Assam', 'Meghalaya', 'Tripura', 'Arunachal Pradesh', 'Mizoram', 'Manipur', 'Nagaland', 'Sikkim'];
      
      if (southStates.includes(newValue)) zoneValue = 'South Zone';
      else if (northStates.includes(newValue)) zoneValue = 'North Zone';
      else if (westStates.includes(newValue)) zoneValue = 'West Zone';
      else if (eastStates.includes(newValue)) zoneValue = 'East Zone';
      else if (centralStates.includes(newValue)) zoneValue = 'Central Zone';
      else if (northEastStates.includes(newValue)) zoneValue = 'North East Zone';

      setForm(prev => ({ ...prev, state: newValue, zone: zoneValue }));
      setFormError("");
      return;
    }

    setForm(prev => ({ ...prev, [name]: newValue }));
    setFormError("");
  };

  const handleSurveyKeyDown = (e) => {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault();
      const val = form.surveyInput?.trim();
      if (val && !form.surveyNo.includes(val)) {
        setForm(prev => ({
          ...prev,
          surveyNo: [...(prev.surveyNo || []), val],
          surveyInput: ''
        }));
      }
    }
  };

  const removeSurveyTag = (tagToRemove) => {
    setForm(prev => ({
      ...prev,
      surveyNo: (prev.surveyNo || []).filter(tag => tag !== tagToRemove)
    }));
  };

  const handleToggleStatus = (e) => {
    setForm(prev => ({ ...prev, status: e.target.checked ? "Active" : "Inactive" }));
    setFormError("");
  };

  const handleLogoChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onloadend = () => setForm((prev) => ({ ...prev, logo: reader.result }));
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
    const cleared = { plant: '', state: '', status: '' };
    setSearchInputs(cleared);
    setActiveFilters(cleared);
    setCurrentPage(1);
  };

  const handleResetForm = () => {
    setForm({
      landCode: '',
      plant: '',
      allocationType: '',
      surveyNo: [],
      surveyInput: '',
      landOwnerName: '',
      mobileNo: '',
      state: '',
      zone: '',
      district: '',
      village: '',
      mandal: '',
      pincode: '',
      landArea: '',
      latitude: '',
      longitude: '',
      status: 'Active',
      logo: null
    });
    setFormError("");
  };

  const handleSave = (e) => {
    e.preventDefault();

    // Required fields check – all string fields now require non‑empty values
    if (
      !form.landCode.trim() ||
      !form.plant.trim() ||
      !form.allocationType.trim() ||
      (!form.surveyNo || form.surveyNo.length === 0) ||
      !form.landOwnerName.trim() ||
      !form.mobileNo.trim() ||
      !form.state.trim() ||
      !form.district.trim() ||
      !form.village.trim() ||
      !form.mandal.trim() ||
      !form.pincode.trim() ||
      !form.landArea.trim() ||
      !form.latitude.trim() ||
      !form.longitude.trim() ||
      !form.status
    ) {
      setFormError("Please fill in all required fields marked with *");
      return;
    }

    // Unique Land Code check
    const isDuplicate = allocations.some(
      a => a.landCode.toLowerCase().trim() === form.landCode.toLowerCase().trim() && a.id !== editingId
    );

    if (isDuplicate) {
      setFormError("Land code must be unique. This land code already exists.");
      return;
    }

    if (isEditing) {
      setAllocations(prev =>
        prev.map(a => (a.id === editingId ? { ...a, ...form } : a))
      );
      setIsEditing(false);
      setEditingId(null);
    } else {
      const newLand = {
        id: Date.now(),
        ...form
      };
      setAllocations(prev => [...prev, newLand]);
    }

    handleResetForm();
    setView("list");
  };

  const handleEdit = (land) => {
    setForm({ 
      ...land,
      surveyNo: Array.isArray(land.surveyNo) ? land.surveyNo : (land.surveyNo ? [land.surveyNo] : []),
      surveyInput: ''
    });
    setIsEditing(true);
    setEditingId(land.id);
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
    setAllocations(prev =>
      prev.map(a => (a.id === deactivateTargetId ? { ...a, status: "Inactive" } : a))
    );
    setShowDeactivateModal(false);
    setDeactivateTargetId(null);
  };

  const handleDelete = (id) => {
    if (window.confirm("Are you sure you want to delete this land record?")) {
      setAllocations(prev => prev.filter(a => a.id !== id));
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

  const sortedAllocations = React.useMemo(() => {
    let sortable = [...allocations];
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
  }, [allocations, sortConfig]);

  // Filter calculations – now using simple string inclusion
  const filteredAllocations = sortedAllocations.filter(a => {
    const matchPlant = !activeFilters.plant || 
      a.plant?.toLowerCase().includes(activeFilters.plant.toLowerCase());
    const matchState = !activeFilters.state || 
      a.state?.toLowerCase().includes(activeFilters.state.toLowerCase());
    const matchStatus = !activeFilters.status || a.status === activeFilters.status;
    return matchPlant && matchState && matchStatus;
  });

  // Pagination calculations
  const indexOfLastItem = currentPage * itemsPerPage;
  const indexOfFirstItem = indexOfLastItem - itemsPerPage;
  const currentItems = filteredAllocations.slice(indexOfFirstItem, indexOfLastItem);
  const totalPages = Math.ceil(filteredAllocations.length / itemsPerPage);

  const paginate = (pageNumber) => setCurrentPage(pageNumber);

  const vibrantBlue = "#2563eb";

  return (
    <div className="al-shell-container">
      {/* Sidebar Navigation */}
      <Sidebar userRole={userRole} onLogout={onLogout} />

      {/* Main Container Viewport */}
      <div className="al-shell">
        
        {/* ======================= DYNAMIC HEADER ======================= */}
        <Header 
          title="Land Creation" 
          showSearch={false} 
          userName="Syed Mohammad Johny Basha" 
          userRole="Web Developer" 
          initials="SB" 
        />

        <main className="al-main" style={{ padding: '24px' }}>
          
          

          {view === "form" ? (
            /* ================= VIEW: ADD NEW LAND FORM ================= */
            <>
              <div className="al-content" style={{ paddingBottom: '80px', maxWidth: '1280px', margin: '0 auto' }}>
                
                {/* Form Card */}
                <div className="al-form-card" style={{ 
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
                      {isEditing ? "Edit Land" : "Add New Land"}
                    </h2>
                    <button
                      type="button"
                      className="al-nav-view-btn"
                      onClick={() => {
                        setView("list");
                        handleResetForm();
                        setIsEditing(false);
                        setEditingId(null);
                      }}
                    >
                      <ChevronLeft size={15} /> Back to Land List
                    </button>
                  </div>

                  {/* Form Body */}
                  <div style={{ padding: '24px' }}>
                    {formError && <div className="al-form-error" style={{ color: '#dc2626', marginBottom: '20px', padding: '12px 16px', backgroundColor: '#fef2f2', borderLeft: '4px solid #dc2626', borderRadius: '6px', fontWeight: '500' }}>{formError}</div>}

                    {/* 1. Basic Information */}
                    <section className="al-panel" style={{ backgroundColor: 'white', padding: 0, border: 'none', marginBottom: '32px' }}>
                      
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                        <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', margin: 0 }}>
                          Basic Information
                        </h3>
                        
                        {/* Status Toggle Bar */}
                        <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                          <span style={{ fontSize: "14px", fontWeight: "600", color: "#475569" }}>Status:</span>
                          
                          <label style={{ position: "relative", display: "inline-block", width: "46px", height: "26px", margin: 0 }}>
                            <input 
                              type="checkbox" 
                              checked={form.status === "Active"}
                              onChange={handleToggleStatus}
                              style={{ opacity: 0, width: 0, height: 0 }}
                            />
                            <span style={{
                              position: "absolute", cursor: "pointer", top: 0, left: 0, right: 0, bottom: 0,
                              backgroundColor: form.status === "Active" ? "#10b981" : "#cbd5e1",
                              transition: ".4s", borderRadius: "34px"
                            }}>
                              <span style={{
                                position: "absolute", height: "20px", width: "20px", 
                                left: form.status === "Active" ? "23px" : "3px", bottom: "3px",
                                backgroundColor: "white", transition: ".4s", borderRadius: "50%",
                                boxShadow: "0 2px 4px rgba(0,0,0,0.1)"
                              }}></span>
                            </span>
                          </label>

                          <span style={{ 
                            fontSize: "14px", fontWeight: "600", minWidth: "60px",
                            color: form.status === "Active" ? "#16a34a" : "#dc2626" 
                          }}>
                            {form.status}
                          </span>
                        </div>
                      </div>
                      
                      <div className="al-form-layout-row columns-4">
                        <label className="al-field-item">
                          <span>Land Code <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="landCode" value={form.landCode} onChange={handleChange} placeholder="Enter land code" maxLength={10} />
                          <small style={{ color: '#64748b', fontSize: '12px', marginTop: '4px' }}>Must be unique.</small>
                        </label>
                        <label className="al-field-item">
                          <span>Plant <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="plant" value={form.plant} onChange={handleChange} placeholder="Enter plant name" />
                        </label>
                        <label className="al-field-item" style={{ gridColumn: 'span 2' }}>
                          <span>Land Logo</span>
                          <div className="al-logo-row">
                            <div className="al-logo-box" style={{ width: '48px', height: '48px', border: '1px solid #e2e8f0', borderRadius: '6px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f8fafc', overflow: 'hidden' }}>
                              {form.logo ? <img src={form.logo} alt="Logo" style={{ width: '100%', height: '100%', objectFit: 'cover' }} /> : <ImageIcon size={22} style={{ color: '#94a3b8' }} />}
                            </div>
                            <input id="logoUploadHidden" type="file" accept="image/*" onChange={handleLogoChange} hidden />
                            <button type="button" onClick={() => document.getElementById("logoUploadHidden").click()} style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '8px 12px', background: '#f1f5f9', border: '1px solid #e2e8f0', borderRadius: '6px', fontSize: '13px', color: '#0f172a', cursor: 'pointer' }}>
                              <Upload size={14} /> Upload Logo
                            </button>
                          </div>
                        </label>
                      </div>
                    </section>

                    {/* 2. Mapping Section */}
                    <section className="al-panel" style={{ backgroundColor: 'white', padding: 0, border: 'none', marginBottom: '32px' }}>
                      <h3 className="al-section-title" style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', marginBottom: '20px', borderBottom: '1px solid #e2e8f0', paddingBottom: '12px' }}>Mapping Section</h3>
                      <div className="al-form-layout-row columns-4">
                        <label className="al-field-item">
                          <span>Allocation Type <b style={{color: '#ef4444'}}>*</b></span>
                          <select name="allocationType" value={form.allocationType} onChange={handleChange} style={{ width: '100%', padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '6px', fontSize: '14px', backgroundColor: 'white', boxSizing: 'border-box', outline: 'none', cursor: 'pointer', height: '40px' }}>
                            <option value="">Select Type</option>
                            <option value="AGL">AGL</option>
                            <option value="PLT">PLT</option>
                          </select>
                        </label>
                      </div>
                    </section>

                    {/* 3. Land Details */}
                    <section className="al-panel" style={{ backgroundColor: 'white', padding: 0, border: 'none', marginBottom: '32px' }}>
                      <h3 className="al-section-title" style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', marginBottom: '20px', borderBottom: '1px solid #e2e8f0', paddingBottom: '12px' }}>Land Details</h3>
                      <div className="al-form-layout-row columns-4">
                        <label className="al-field-item">
                          <span>Land Area (Acres) <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="landArea" value={form.landArea} onChange={handleChange} placeholder="Enter land area" />
                        </label>
                        <label className="al-field-item" style={{ gridColumn: 'span 2' }}>
                          <span>Survey Number <b style={{color: '#ef4444'}}>*</b></span>
                          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px', padding: '6px', border: '1px solid #cbd5e1', borderRadius: '6px', minHeight: '40px', boxSizing: 'border-box', backgroundColor: 'white' }}>
                            {Array.isArray(form.surveyNo) && form.surveyNo.map((tag, idx) => (
                              <span key={idx} style={{ backgroundColor: '#f1f5f9', color: '#0f172a', padding: '4px 8px', borderRadius: '4px', fontSize: '13px', display: 'flex', alignItems: 'center', gap: '6px', border: '1px solid #e2e8f0' }}>
                                {tag}
                                <X size={14} style={{ cursor: 'pointer', color: '#64748b' }} onClick={() => removeSurveyTag(tag)} />
                              </span>
                            ))}
                            <input 
                              type="text" 
                              name="surveyInput" 
                              value={form.surveyInput || ''} 
                              onChange={handleChange} 
                              onKeyDown={handleSurveyKeyDown}
                              placeholder={(!form.surveyNo || form.surveyNo.length === 0) ? "Type and press Enter" : ""} 
                              style={{ border: 'none', outline: 'none', flex: 1, minWidth: '150px', fontSize: '14px', background: 'transparent' }} 
                            />
                          </div>
                        </label>
                        <label className="al-field-item">
                          <span>Land Owner Name <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="landOwnerName" value={form.landOwnerName} onChange={handleChange} placeholder="Enter land owner name" maxLength={100} />
                        </label>
                      </div>
                      <div className="al-form-layout-row columns-4" style={{ marginTop: '20px' }}>
                        <label className="al-field-item">
                          <span>Mobile No <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="mobileNo" value={form.mobileNo} onChange={handleChange} placeholder="Enter mobile number" maxLength={10} />
                        </label>
                      </div>
                    </section>

                    {/* 4. Location Information */}
                    <section className="al-panel" style={{ backgroundColor: 'white', padding: 0, border: 'none', marginBottom: '32px' }}>
                      <h3 className="al-section-title" style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', marginBottom: '20px', borderBottom: '1px solid #e2e8f0', paddingBottom: '12px' }}>Location Information</h3>
                      <div className="al-form-layout-row columns-4">
                        <label className="al-field-item">
                          <span>State <b style={{color: '#ef4444'}}>*</b></span>
                          <select name="state" value={form.state} onChange={handleChange} style={{ width: '100%', padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '6px', fontSize: '14px', backgroundColor: 'white', boxSizing: 'border-box', outline: 'none', cursor: 'pointer', height: '40px' }}>
                            <option value="">Select State</option>
                          </select>
                        </label>
                        <label className="al-field-item">
                          <span>Zone</span>
                          <input type="text" name="zone" value={form.zone || ''} readOnly style={{ backgroundColor: '#f1f5f9', cursor: 'not-allowed', color: '#64748b' }} placeholder="Auto-filled Zone" />
                        </label>
                        <label className="al-field-item">
                          <span>District <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="district" value={form.district} onChange={handleChange} placeholder="Enter district" maxLength={30} />
                        </label>
                        <label className="al-field-item">
                          <span>Mandal <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="mandal" value={form.mandal} onChange={handleChange} placeholder="Enter mandal" maxLength={30} />
                        </label>
                      </div>
                      <div className="al-form-layout-row columns-4" style={{ marginTop: '20px' }}>
                        <label className="al-field-item">
                          <span>Village <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="village" value={form.village} onChange={handleChange} placeholder="Enter village" maxLength={50} />
                        </label>
                        <label className="al-field-item">
                          <span>Pincode <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="pincode" value={form.pincode} onChange={handleChange} placeholder="Enter pincode" maxLength={6} />
                        </label>
                      </div>
                    </section>

                    {/* 5. Geo Location */}
                    <section className="al-panel" style={{ backgroundColor: 'white', padding: 0, border: 'none', marginBottom: '32px' }}>
                      <h3 className="al-section-title" style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', marginBottom: '20px', borderBottom: '1px solid #e2e8f0', paddingBottom: '12px' }}>Geo Location</h3>
                      <div className="al-form-layout-row columns-4">
                        <label className="al-field-item">
                          <span>Latitude <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="latitude" value={form.latitude} onChange={handleChange} placeholder="Enter latitude" />
                        </label>
                        <label className="al-field-item">
                          <span>Longitude <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="longitude" value={form.longitude} onChange={handleChange} placeholder="Enter longitude" />
                        </label>
                      </div>
                    </section>
                  </div>

                  {/* Form Footer Buttons */}
                  <div className="al-form-footer" style={{ 
                    display: 'flex', 
                    justifyContent: 'flex-end', 
                    gap: '12px', 
                    padding: '16px 24px',
                    backgroundColor: '#fafbfc',
                    borderTop: '1px solid #e2e8f0'
                  }}>
                    <button type="button" className="al-btn secondary" onClick={() => {
                      setView("list");
                      handleResetForm();
                      setIsEditing(false);
                      setEditingId(null);
                    }}>
                      Cancel
                    </button>
                    <button type="button" className="al-btn tertiary" onClick={handleResetForm}>
                      <RefreshCcw size={14} /> Reset
                    </button>
                    <button type="button" className="al-btn primary" onClick={handleSave}>
                      <Save size={14} /> {isEditing ? "Update Land" : "Save Land"}
                    </button>
                  </div>
                </div>
              </div>
            </>
          ) : (
            /* ================= VIEW: LAND LIST ================= */
            <div className="al-content" style={{ maxWidth: '1280px', margin: '0 auto' }}>
              
              {/* INTEGRATED CARD FOR FILTERS AND TABLE */}
              <div className="al-table-panel" style={{ backgroundColor: 'white', borderRadius: '8px', border: '1px solid #e2e8f0', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
                
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
                      Land List
                    </h2>
                    <p style={{ color: '#64748b', margin: '4px 0 0 0', fontSize: '14px' }}>
                      View and manage all land records
                    </p>
                  </div>
                  <button
                    type="button"
                    className="al-btn-add-new"
                    onClick={() => {
                      handleResetForm();
                      setIsEditing(false);
                      setView("form");
                    }}
                  >
                    <Plus size={16} /> Add New Land
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
                    <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', fontWeight: '600', color: '#475569' }}>Plant</label>
                    <input
                      type="text"
                      name="plant"
                      value={searchInputs.plant}
                      onChange={handleFilterChange}
                      placeholder="Filter by plant"
                      style={{ width: '100%', padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '6px', fontSize: '14px', boxSizing: 'border-box', outline: 'none', height: '40px' }}
                    />
                  </div>

                  <div style={{ flex: 1, minWidth: '200px' }}>
                    <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', fontWeight: '600', color: '#475569' }}>State</label>
                    <input
                      type="text"
                      name="state"
                      value={searchInputs.state}
                      onChange={handleFilterChange}
                      placeholder="Filter by state"
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
                      className="al-filter-btn search"
                      onClick={applySearch}
                    >
                      <Search size={15} /> Search
                    </button>
                    <button
                      type="button"
                      className="al-filter-btn reset"
                      onClick={resetFilters}
                    >
                      <RefreshCcw size={15} /> Reset
                    </button>
                  </div>
                </div>

                {/* Data Table Section Inside the Card */}
                <div className="al-table-container" style={{ overflowX: 'auto' }}>
                  <table className="al-list-table" style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', minWidth: '900px' }}>
                    <thead style={{ backgroundColor: '#f8fafc', borderBottom: '2px solid #e2e8f0' }}>
                      <tr>
                        <th style={{ width: "50px", padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>#</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>LOGO</th>
                        <th
                          className="sortable"
                          onClick={() => handleSort("landCode")}
                          style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', cursor: 'pointer', textTransform: 'uppercase', letterSpacing: '0.5px' }}
                        >
                          LAND CODE{" "}
                          {sortConfig.key === "landCode" &&
                            (sortConfig.direction === "asc" ? "▲" : "▼")}
                        </th>
                        <th
                          className="sortable"
                          onClick={() => handleSort("plant")}
                          style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', cursor: 'pointer', textTransform: 'uppercase', letterSpacing: '0.5px' }}
                        >
                          PLANT{" "}
                          {sortConfig.key === "plant" &&
                            (sortConfig.direction === "asc" ? "▲" : "▼")}
                        </th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>ALLOCATION TYPE</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>SURVEY NO</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>LOCATION</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>AREA</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>STATUS</th>
                        <th style={{ textAlign: "center", width: "100px", padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                          ACTIONS
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {currentItems.length > 0 ? (
                        currentItems.map((land, index) => (
                          <tr key={land.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{indexOfFirstItem + index + 1}</td>
                            <td style={{ padding: '14px 20px' }}>
                              {land.logo ? (
                                <img src={land.logo} alt="Logo" style={{ width: '32px', height: '32px', borderRadius: '4px', objectFit: 'cover', border: '1px solid #e2e8f0' }} />
                              ) : (
                                <div style={{ width: '32px', height: '32px', borderRadius: '4px', background: '#f1f5f9', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px solid #e2e8f0' }}>
                                  <MapPin size={16} style={{ color: '#94a3b8' }} />
                                </div>
                              )}
                            </td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>
                              <span style={{ backgroundColor: '#f1f5f9', padding: '4px 10px', borderRadius: '4px', fontWeight: '600', color: '#0f172a', border: '1px solid #e2e8f0', fontSize: '13px' }}>
                                {land.landCode}
                              </span>
                            </td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}><strong>{land.plant}</strong></td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>
                              <span style={{ backgroundColor: '#dbeafe', padding: '4px 10px', borderRadius: '4px', fontWeight: '500', color: '#1d4ed8', fontSize: '12px' }}>
                                {land.allocationType}
                              </span>
                            </td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{Array.isArray(land.surveyNo) ? land.surveyNo.join(', ') : land.surveyNo}</td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>
                              <div style={{ display: 'flex', flexDirection: 'column' }}>
                                <span>{land.village}</span>
                                <span style={{ color: '#2563eb', fontWeight: '500', fontSize: '13px' }}>{land.district}, {land.state}</span>
                              </div>
                            </td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>
                              <span style={{ fontWeight: '600' }}>{land.landArea}</span>
                            </td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>
                              <span
                                style={{ 
                                  padding: '4px 12px', 
                                  borderRadius: '12px', 
                                  fontSize: '12px', 
                                  fontWeight: '600',
                                  display: 'inline-block',
                                  backgroundColor: land.status === 'Active' ? '#dcfce7' : '#fee2e2',
                                  color: land.status === 'Active' ? '#166534' : '#991b1b'
                                }}
                              >
                                {land.status}
                              </span>
                            </td>
                            <td style={{ position: "relative", padding: '14px 20px', textAlign: 'center' }}>
                              <button
                                type="button"
                                style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#64748b', padding: '4px 8px', borderRadius: '4px' }}
                                onClick={() => toggleDropdown(land.id)}
                                onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f1f5f9'}
                                onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
                              >
                                <MoreVertical size={18} />
                              </button>

                              {/* Actions Dropdown menu */}
                              {activeDropdown === land.id && (
                                <>
                                  <div
                                    className="al-actions-dropdown-backdrop"
                                    onClick={() => setActiveDropdown(null)}
                                    style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, zIndex: 9 }}
                                  />
                                  <div className="al-actions-dropdown-menu" style={{ position: 'absolute', right: '30px', top: '8px', backgroundColor: 'white', border: '1px solid #e2e8f0', borderRadius: '8px', boxShadow: '0 4px 12px rgba(0,0,0,0.15)', zIndex: 10, display: 'flex', flexDirection: 'column', padding: '4px 0', minWidth: '140px' }}>
                                    <button
                                      type="button"
                                      style={{ padding: '10px 16px', textAlign: 'left', background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px', color: '#334155', borderRadius: '4px', margin: '2px 4px' }}
                                      onClick={() => {
                                        alert(
                                          `Land Details:\nCode: ${land.landCode}\nPlant: ${land.plant}\nType: ${land.allocationType}\nOwner: ${land.landOwnerName}\nArea: ${land.landArea} Acres\nLocation: ${land.village}, ${land.mandal}, ${land.state}\nSurvey No: ${Array.isArray(land.surveyNo) ? land.surveyNo.join(', ') : land.surveyNo}`
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
                                      onClick={() => handleEdit(land)}
                                      onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f1f5f9'}
                                      onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
                                    >
                                      <Edit size={15} /> Edit
                                    </button>
                                    <button
                                      type="button"
                                      style={{ padding: '10px 16px', textAlign: 'left', background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px', color: '#ef4444', borderRadius: '4px', margin: '2px 4px' }}
                                      onClick={() => triggerDeactivate(land.id)}
                                      onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#fef2f2'}
                                      onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
                                    >
                                      <Trash2 size={15} /> Deactivate
                                    </button>
                                    <button
                                      type="button"
                                      style={{ padding: '10px 16px', textAlign: 'left', background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px', color: '#ef4444', borderRadius: '4px', margin: '2px 4px' }}
                                      onClick={() => handleDelete(land.id)}
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
                          <td colSpan="10" style={{ textAlign: "center", padding: "60px 20px", color: '#64748b', fontSize: '14px' }}>
                            No land records found. Add a new land using the button above.
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>

                {/* Pagination bar */}
                {totalPages > 0 && (
                  <div className="al-table-pagination-bar" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '14px 24px', borderTop: '1px solid #e2e8f0', backgroundColor: '#fafbfc' }}>
                    <span className="al-pagination-info" style={{ fontSize: '14px', color: '#64748b' }}>
                      Showing {filteredAllocations.length > 0 ? indexOfFirstItem + 1 : 0} to{" "}
                      {Math.min(indexOfLastItem, filteredAllocations.length)} of{" "}
                      {filteredAllocations.length} entries
                    </span>
                    <div className="al-pagination-controls" style={{ display: 'flex', gap: '4px' }}>
                      <button
                        type="button"
                        className="al-pag-btn"
                        onClick={() => paginate(currentPage - 1)}
                        disabled={currentPage === 1}
                      >
                        <ChevronLeft size={16} />
                      </button>
                      {Array.from({ length: totalPages }, (_, i) => (
                        <button
                          key={i + 1}
                          className={`al-pag-btn ${currentPage === i + 1 ? 'active' : ''}`}
                          onClick={() => paginate(i + 1)}
                        >
                          {i + 1}
                        </button>
                      ))}
                      <button
                        type="button"
                        className="al-pag-btn"
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
        <div className="al-modal-overlay" style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.5)', zIndex: 99, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div className="al-modal" style={{ backgroundColor: 'white', borderRadius: '8px', width: '400px', maxWidth: '90%', boxShadow: '0 10px 15px -3px rgba(0,0,0,0.1)' }}>
            <div className="al-modal-header" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 20px', borderBottom: '1px solid #e2e8f0' }}>
              <h3 style={{ margin: 0, fontSize: '16px', fontWeight: '700', color: '#1e293b' }}>Deactivate Land Record</h3>
              <button
                type="button"
                className="al-modal-close"
                onClick={() => setShowDeactivateModal(false)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#64748b' }}
              >
                <X size={18} />
              </button>
            </div>
            <div className="al-modal-body" style={{ padding: '20px' }}>
              <p style={{ margin: '0 0 8px 0', color: '#334155', fontSize: '14px' }}>Are you sure you want to deactivate this land record?</p>
              <p className="al-modal-warning" style={{ margin: 0, color: '#ef4444', fontSize: '13px', fontWeight: '500' }}>
                This will change its status to Inactive.
              </p>
            </div>
            <div className="al-modal-footer" style={{ padding: '16px 20px', borderTop: '1px solid #e2e8f0', display: 'flex', justifyContent: 'flex-end', gap: '10px', backgroundColor: '#f8fafc' }}>
              <button
                type="button"
                className="al-btn-cancel-modal"
                onClick={() => setShowDeactivateModal(false)}
              >
                Cancel
              </button>
              <button
                type="button"
                className="al-btn-delete-modal"
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

export default AgriLandAllocation;