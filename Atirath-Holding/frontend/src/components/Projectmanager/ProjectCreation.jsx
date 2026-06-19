import React, { useState, useEffect } from "react";
import {
  Menu,
  ChevronRight,
  Upload,
  X,
  Bell,
  CheckCircle,
  RefreshCcw,
  Save,
  Plus,
  Eye,
  Edit,
  Trash2,
  MoreVertical,
  ChevronLeft,
  Search,
  Image as ImageIcon
} from "lucide-react";
import Sidebar from "../Sidebar";
import Header from "../Header";
import "../../styles/projectCreation.css";

const ProjectCreation = ({ userRole, onLogout }) => {
  // ─── Local storage ──────────────────────────────────────────────────────────
  const [projects, setProjects] = useState(() => {
    const saved = localStorage.getItem("project_creations");
    return saved ? JSON.parse(saved) : [];
  });

  useEffect(() => {
    localStorage.setItem("project_creations", JSON.stringify(projects));
  }, [projects]);

  // View toggle – default is "list"
  const [view, setView] = useState("list");
  const [isEditing, setIsEditing] = useState(false);
  const [editingId, setEditingId] = useState(null);

  // Form state
  const [form, setForm] = useState({
    projectCode: "",
    projectName: "",
    priority: "MEDIUM",
    status: "Draft",
    projectDescription: "",
    projectObjective: "",
    expectedDeliverables: "",
    companyName: "",
    plantName: "",
    department: "",
    createdBy: "Syed Mohammad Johny Basha",
    startDate: "",
    endDate: "",
    totalProjectDays: "",
    priorityDetails: "",
    budget: "",
    remarks: "",
    uploadImage: null
  });

  const [formError, setFormError] = useState("");
  const [imagePreview, setImagePreview] = useState(null);
  const [isDragging, setIsDragging] = useState(false);
  const [success, setSuccess] = useState(false);

  // Search Filter state
  const [searchInputs, setSearchInputs] = useState({
    projectName: '',
    projectCode: '',
    status: ''
  });

  const [activeFilters, setActiveFilters] = useState({
    projectName: '',
    projectCode: '',
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

  // ─── Input Change Handler ──────────────────────────────────────────────────
  const handleChange = (e) => {
    const { name, value } = e.target;
    let newValue = value;
    
    if (name === 'projectCode') newValue = value.slice(0, 10);
    else if (name === 'projectName') newValue = value.slice(0, 100);
    else if (name === 'projectDescription') newValue = value.slice(0, 250);
    else if (name === 'projectObjective' || name === 'expectedDeliverables' || name === 'remarks') 
      newValue = value.slice(0, 255);
    else if (name === 'totalProjectDays') {
      newValue = value.replace(/[^0-9]/g, '');
    }
    
    setForm((prev) => {
      const nextForm = { ...prev, [name]: newValue };
      
      // Auto-calculate end date if start date and total days are present
      if ((name === 'startDate' || name === 'totalProjectDays') && nextForm.startDate && nextForm.totalProjectDays) {
        const start = new Date(nextForm.startDate);
        start.setDate(start.getDate() + parseInt(nextForm.totalProjectDays, 10));
        nextForm.endDate = start.toISOString().split('T')[0];
      }
      
      // Auto-calculate total days if both start and end dates are present (and totalProjectDays is not currently being edited)
      if ((name === 'startDate' || name === 'endDate') && nextForm.startDate && nextForm.endDate && name !== 'totalProjectDays') {
        const start = new Date(nextForm.startDate);
        const end = new Date(nextForm.endDate);
        const diffTime = end - start;
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        nextForm.totalProjectDays = diffDays >= 0 ? String(diffDays) : "0";
      }

      return nextForm;
    });
    
    if (formError) setFormError("");
  };

  const handleToggleStatus = (e) => {
    setForm(prev => ({ ...prev, status: e.target.checked ? "Live" : "Draft" }));
    setFormError("");
  };

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setForm(prev => ({ ...prev, uploadImage: file }));
      const reader = new FileReader();
      reader.onloadend = () => setImagePreview(reader.result);
      reader.readAsDataURL(file);
    }
  };

  const handleDragOver = (e) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = () => {
    setIsDragging(false);
  };

  const handleDrop = (e) => {
    e.preventDefault();
    setIsDragging(false);
    const file = e.dataTransfer.files[0];
    if (file && file.type.startsWith("image/")) {
      setForm(prev => ({ ...prev, uploadImage: file }));
      const reader = new FileReader();
      reader.onloadend = () => setImagePreview(reader.result);
      reader.readAsDataURL(file);
    }
  };

  const handleBulletKeyDown = (e) => {
    if (e.key === "Enter") {
      e.preventDefault();
      const { name, value, selectionStart, selectionEnd } = e.target;
      
      const before = value.substring(0, selectionStart);
      const after = value.substring(selectionEnd);
      const newValue = before + "\n• " + after;
      setForm((prev) => ({ ...prev, [name]: newValue }));
      
      setTimeout(() => {
        e.target.selectionStart = e.target.selectionEnd = selectionStart + 3;
      }, 0);
    }
  };

  const handleBulletFocus = (e) => {
    const { name, value } = e.target;
    if (!value.trim()) {
      setForm((prev) => ({ ...prev, [name]: "• " }));
    }
  };

  // Date calculations are now handled in handleChange

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
    const cleared = { projectName: '', projectCode: '', status: '' };
    setSearchInputs(cleared);
    setActiveFilters(cleared);
    setCurrentPage(1);
  };

  const handleResetForm = () => {
    setForm({
      projectCode: "",
      projectName: "",
      priority: "MEDIUM",
      status: "Draft",
      projectDescription: "",
      projectObjective: "",
      expectedDeliverables: "",
      companyName: "",
      plantName: "",
      department: "",
      createdBy: "Syed Mohammad Johny Basha",
      startDate: "",
      endDate: "",
      totalProjectDays: "",
      priorityDetails: "",
      budget: "",
      remarks: "",
      uploadImage: null
    });
    setImagePreview(null);
    setFormError("");
  };

  const handleSave = () => {
    // Required fields check
    if (
      !form.projectName.trim() ||
      !form.startDate ||
      !form.endDate ||
      !form.projectDescription.trim() ||
      !form.companyName.trim() ||
      !form.plantName.trim() ||
      !form.department.trim()
    ) {
      setFormError("Please fill in all required fields marked with *");
      return;
    }

    // Unique Project Code check
    const isDuplicate = projects.some(
      p => p.projectCode.toLowerCase().trim() === form.projectCode.toLowerCase().trim() && p.id !== editingId
    );

    if (isDuplicate) {
      setFormError("Project code must be unique. This code already exists.");
      return;
    }

    const newProject = {
      id: editingId || Date.now(),
      projectCode: form.projectCode || `PRJ-${String(projects.length + 1).padStart(4, '0')}`,
      projectName: form.projectName.trim(),
      department: form.department,
      priority: form.priority,
      startDate: form.startDate,
      endDate: form.endDate,
      status: form.status,
      projectDescription: form.projectDescription,
      projectObjective: form.projectObjective,
      expectedDeliverables: form.expectedDeliverables,
      companyName: form.companyName,
      plantName: form.plantName,
      createdBy: form.createdBy,
      totalProjectDays: form.totalProjectDays,
      remarks: form.remarks,
      uploadImage: form.uploadImage,
      logo: imagePreview
    };

    if (isEditing) {
      setProjects(prev =>
        prev.map(p => (p.id === editingId ? newProject : p))
      );
      setIsEditing(false);
      setEditingId(null);
    } else {
      setProjects(prev => [...prev, newProject]);
    }

    setSuccess(true);
    setFormError("");
    setTimeout(() => setSuccess(false), 3000);
    handleResetForm();
    setView("list");
  };

  const handleEdit = (project) => {
    setForm({ ...project });
    if (project.logo) {
      setImagePreview(project.logo);
    }
    setIsEditing(true);
    setEditingId(project.id);
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
    setProjects(prev =>
      prev.map(p => (p.id === deactivateTargetId ? { ...p, status: "Closed" } : p))
    );
    setShowDeactivateModal(false);
    setDeactivateTargetId(null);
  };

  const handleDelete = (id) => {
    if (window.confirm("Are you sure you want to delete this project?")) {
      setProjects(prev => prev.filter(p => p.id !== id));
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

  const sortedProjects = React.useMemo(() => {
    let sortable = [...projects];
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
  }, [projects, sortConfig]);

  // Filter calculations
  const filteredProjects = sortedProjects.filter(p => {
    const matchName = !activeFilters.projectName || 
      p.projectName?.toLowerCase().includes(activeFilters.projectName.toLowerCase());
    const matchCode = !activeFilters.projectCode || 
      p.projectCode?.toLowerCase().includes(activeFilters.projectCode.toLowerCase());
    const matchStatus = !activeFilters.status || p.status === activeFilters.status;
    return matchName && matchCode && matchStatus;
  });

  // Pagination calculations
  const indexOfLastItem = currentPage * itemsPerPage;
  const indexOfFirstItem = indexOfLastItem - itemsPerPage;
  const currentItems = filteredProjects.slice(indexOfFirstItem, indexOfLastItem);
  const totalPages = Math.ceil(filteredProjects.length / itemsPerPage);

  const paginate = (pageNumber) => setCurrentPage(pageNumber);

  const vibrantBlue = "#2563eb";

  return (
    <div className="proj-shell-container">
      {/* Sidebar Navigation */}
      <Sidebar userRole={userRole} onLogout={onLogout} />

      {/* Main Container Viewport */}
      <div className="proj-shell">
        
        {/* ======================= DYNAMIC HEADER ======================= */}
        <Header 
          title="Project Creation" 
          showSearch={false} 
          userName="Syed Mohammad Johny Basha" 
          userRole="Web Developer" 
          initials="SB" 
        />

        <main className="proj-main" style={{ padding: '24px' }}>
        
          

          {view === "form" ? (
            /* ================= VIEW: ADD NEW PROJECT FORM ================= */
            <>
              <div className="proj-content" style={{ paddingBottom: '80px', maxWidth: '1280px', margin: '0 auto' }}>
                
                {/* Form Card */}
                <div className="proj-form-card" style={{ 
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
                      {isEditing ? "Edit Project" : "Add New Project"}
                    </h2>
                    <button
                      type="button"
                      className="proj-nav-view-btn"
                      onClick={() => {
                        setView("list");
                        handleResetForm();
                        setIsEditing(false);
                        setEditingId(null);
                      }}
                    >
                      <ChevronLeft size={15} /> Back to Project List
                    </button>
                  </div>

                  {/* Form Body */}
                  <div style={{ padding: '24px' }}>
                    {success && (
                      <div className="proj-success-alert" style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '12px 16px', backgroundColor: '#dcfce7', borderRadius: '6px', color: '#166534', marginBottom: '20px', border: '1px solid #86efac' }}>
                        <CheckCircle size={18} />
                        <span>Project configured and saved successfully!</span>
                      </div>
                    )}

                    {formError && <div className="proj-form-error" style={{ color: '#dc2626', marginBottom: '20px', padding: '12px 16px', backgroundColor: '#fef2f2', borderLeft: '4px solid #dc2626', borderRadius: '6px', fontWeight: '500' }}>{formError}</div>}

                    {/* 1. Project Information */}
                    <section className="proj-panel" style={{ backgroundColor: 'white', padding: 0, border: 'none', marginBottom: '32px' }}>
                      
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                        <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', margin: 0 }}>
                          Project Information
                        </h3>
                        
                        {/* Status Toggle Bar */}
                        <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                          <span style={{ fontSize: "14px", fontWeight: "600", color: "#475569" }}>Status:</span>
                          
                          <label style={{ position: "relative", display: "inline-block", width: "46px", height: "26px", margin: 0 }}>
                            <input 
                              type="checkbox" 
                              checked={form.status === "Live"}
                              onChange={handleToggleStatus}
                              style={{ opacity: 0, width: 0, height: 0 }}
                            />
                            <span style={{
                              position: "absolute", cursor: "pointer", top: 0, left: 0, right: 0, bottom: 0,
                              backgroundColor: form.status === "Live" ? "#10b981" : "#cbd5e1",
                              transition: ".4s", borderRadius: "34px"
                            }}>
                              <span style={{
                                position: "absolute", height: "20px", width: "20px", 
                                left: form.status === "Live" ? "23px" : "3px", bottom: "3px",
                                backgroundColor: "white", transition: ".4s", borderRadius: "50%",
                                boxShadow: "0 2px 4px rgba(0,0,0,0.1)"
                              }}></span>
                            </span>
                          </label>

                          <span style={{ 
                            fontSize: "14px", fontWeight: "600", minWidth: "60px",
                            color: form.status === "Live" ? "#16a34a" : "#dc2626" 
                          }}>
                            {form.status}
                          </span>
                        </div>
                      </div>
                      
                      <div className="proj-form-layout-row columns-4">
                        <label className="proj-field-item">
                          <span>Project Code <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="projectCode" value={form.projectCode} onChange={handleChange} placeholder="Enter project code" maxLength={10} />
                          <small style={{ color: '#64748b', fontSize: '12px', marginTop: '4px' }}>Must be unique.</small>
                        </label>
                        <label className="proj-field-item">
                          <span>Project Name <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="projectName" value={form.projectName} onChange={handleChange} placeholder="Enter project name" maxLength={100} />
                        </label>
                        <label className="proj-field-item">
                          <span>Project Priority <b style={{color: '#ef4444'}}>*</b></span>
                          <select name="priority" value={form.priority} onChange={handleChange}>
                            <option value="HIGH">🔴 HIGH</option>
                            <option value="NORMAL">🔵 NORMAL</option>
                            <option value="MEDIUM">🟡 MEDIUM</option>
                            <option value="LOW">🟢 LOW</option>
                          </select>
                        </label>
                        <label className="proj-field-item">
                          <span>Project Logo</span>
                          <div className="proj-logo-row">
                            <div className="proj-logo-box" style={{ width: '48px', height: '48px', border: '1px solid #e2e8f0', borderRadius: '6px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f8fafc', overflow: 'hidden' }}>
                              {imagePreview ? <img src={imagePreview} alt="Logo" style={{ width: '100%', height: '100%', objectFit: 'cover' }} /> : <ImageIcon size={22} style={{ color: '#94a3b8' }} />}
                            </div>
                            <input id="logoUploadHidden" type="file" accept="image/*" onChange={handleImageChange} hidden />
                            <button type="button" onClick={() => document.getElementById("logoUploadHidden").click()} style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '8px 12px', background: '#f1f5f9', border: '1px solid #e2e8f0', borderRadius: '6px', fontSize: '13px', color: '#0f172a', cursor: 'pointer' }}>
                              <Upload size={14} /> Upload Logo
                            </button>
                          </div>
                        </label>
                      </div>

                      <div className="proj-form-layout-row columns-4" style={{ marginTop: '20px' }}>
                        <label className="proj-field-item" style={{ gridColumn: 'span 2' }}>
                          <span>Project Description <b style={{color: '#ef4444'}}>*</b></span>
                          <textarea name="projectDescription" value={form.projectDescription} onChange={handleChange} placeholder="Brief description of the project" maxLength={250} />
                        </label>
                        <label className="proj-field-item">
                          <span>Project Objective <b style={{color: '#ef4444'}}>*</b></span>
                          <textarea name="projectObjective" value={form.projectObjective} onChange={handleChange} onKeyDown={handleBulletKeyDown} onFocus={handleBulletFocus} placeholder="Key objective of the project" maxLength={255} />
                        </label>
                        <label className="proj-field-item">
                          <span>Expected Deliverables <b style={{color: '#ef4444'}}>*</b></span>
                          <textarea name="expectedDeliverables" value={form.expectedDeliverables} onChange={handleChange} onKeyDown={handleBulletKeyDown} onFocus={handleBulletFocus} placeholder="What will be delivered" maxLength={255} />
                        </label>
                      </div>
                    </section>

                    {/* 2. Organization Details */}
                    <section className="proj-panel" style={{ backgroundColor: 'white', padding: 0, border: 'none', marginBottom: '32px' }}>
                      <h3 className="proj-section-title" style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', marginBottom: '20px', borderBottom: '1px solid #e2e8f0', paddingBottom: '12px' }}>Organization Details</h3>
                      
                      <div className="proj-form-layout-row columns-4">
                        <label className="proj-field-item">
                          <span>Company <b style={{color: '#ef4444'}}>*</b></span>
                          <select name="companyName" value={form.companyName} onChange={handleChange}>
                            <option value="">Select Company</option>
                          </select>
                        </label>
                        <label className="proj-field-item">
                          <span>Plant <b style={{color: '#ef4444'}}>*</b></span>
                          <select name="plantName" value={form.plantName} onChange={handleChange}>
                            <option value="">Select Plant</option>
                          </select>
                        </label>
                        <label className="proj-field-item">
                          <span>Department <b style={{color: '#ef4444'}}>*</b></span>
                          <select name="department" value={form.department} onChange={handleChange}>
                            <option value="">Select Department</option>
                          </select>
                        </label>
                        <label className="proj-field-item">
                          <span>Created By <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="createdBy" value={form.createdBy} readOnly style={{ backgroundColor: '#f1f5f9', cursor: 'not-allowed', color: '#64748b' }} />
                        </label>
                      </div>

                      <div className="proj-form-layout-row columns-4" style={{ marginTop: '20px' }}>
                        <label className="proj-field-item">
                          <span>Total Project Days <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="text" name="totalProjectDays" value={form.totalProjectDays} onChange={handleChange} placeholder="Enter total days" />
                          <small style={{ color: '#64748b', fontSize: '12px', marginTop: '4px' }}>Auto calculates end date</small>
                        </label>
                        <label className="proj-field-item">
                          <span>Tentative Start Date <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="date" name="startDate" value={form.startDate} onChange={handleChange} />
                        </label>
                        <label className="proj-field-item">
                          <span>Tentative End Date <b style={{color: '#ef4444'}}>*</b></span>
                          <input type="date" name="endDate" value={form.endDate} onChange={handleChange} />
                        </label>
                      </div>
                    </section>

                    {/* 3. Additional Information */}
                    <section className="proj-panel" style={{ backgroundColor: 'white', padding: 0, border: 'none', marginBottom: '32px' }}>
                      <h3 className="proj-section-title" style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', marginBottom: '20px', borderBottom: '1px solid #e2e8f0', paddingBottom: '12px' }}>Additional Information</h3>
                      
                      <div className="proj-form-layout-row columns-4">
                        <label className="proj-field-item" style={{ gridColumn: 'span 4' }}>
                          <span>Remarks</span>
                          <textarea name="remarks" value={form.remarks} onChange={handleChange} placeholder="Any additional remarks" maxLength={255} rows={3} />
                        </label>
                      </div>
                    </section>
                  </div>

                  {/* Form Footer Buttons */}
                  <div className="proj-form-footer" style={{ 
                    display: 'flex', 
                    justifyContent: 'flex-end', 
                    gap: '12px', 
                    padding: '16px 24px',
                    backgroundColor: '#fafbfc',
                    borderTop: '1px solid #e2e8f0'
                  }}>
                    <button type="button" className="proj-btn secondary" onClick={() => {
                      setView("list");
                      handleResetForm();
                      setIsEditing(false);
                      setEditingId(null);
                    }}>
                      Cancel
                    </button>
                    <button type="button" className="proj-btn tertiary" onClick={handleResetForm}>
                      <RefreshCcw size={14} /> Reset
                    </button>
                    <button type="button" className="proj-btn primary" onClick={handleSave}>
                      <Save size={14} /> {isEditing ? "Update Project" : "Save Project"}
                    </button>
                  </div>
                </div>
              </div>
            </>
          ) : (
            /* ================= VIEW: PROJECT LIST ================= */
            <div className="proj-content" style={{ maxWidth: '1280px', margin: '0 auto' }}>
              
              {/* INTEGRATED CARD FOR FILTERS AND TABLE */}
              <div className="proj-table-panel" style={{ backgroundColor: 'white', borderRadius: '8px', border: '1px solid #e2e8f0', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
                
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
                      Project List
                    </h2>
                    <p style={{ color: '#64748b', margin: '4px 0 0 0', fontSize: '14px' }}>
                      View and manage all project records
                    </p>
                  </div>
                  <button
                    type="button"
                    className="proj-btn-add-new"
                    onClick={() => {
                      handleResetForm();
                      setIsEditing(false);
                      setView("form");
                    }}
                  >
                    <Plus size={16} /> Add New Project
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
                    <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', fontWeight: '600', color: '#475569' }}>Project Name</label>
                    <input
                      type="text"
                      name="projectName"
                      value={searchInputs.projectName}
                      onChange={handleFilterChange}
                      placeholder="Filter by project name"
                      style={{ width: '100%', padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '6px', fontSize: '14px', boxSizing: 'border-box', outline: 'none', height: '40px' }}
                    />
                  </div>

                  <div style={{ flex: 1, minWidth: '200px' }}>
                    <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', fontWeight: '600', color: '#475569' }}>Project Code</label>
                    <input
                      type="text"
                      name="projectCode"
                      value={searchInputs.projectCode}
                      onChange={handleFilterChange}
                      placeholder="Filter by project code"
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
                      <option value="Draft">Draft</option>
                      <option value="Hold">Hold</option>
                      <option value="Closed">Closed</option>
                      <option value="Live">Live</option>
                    </select>
                  </div>

                  {/* Filter & Reset Buttons */}
                  <div style={{ display: 'flex', gap: '10px', height: '40px' }}>
                    <button
                      type="button"
                      className="proj-filter-btn search"
                      onClick={applySearch}
                    >
                      <Search size={15} /> Search
                    </button>
                    <button
                      type="button"
                      className="proj-filter-btn reset"
                      onClick={resetFilters}
                    >
                      <RefreshCcw size={15} /> Reset
                    </button>
                  </div>
                </div>

                {/* Data Table Section Inside the Card */}
                <div className="proj-table-container" style={{ overflowX: 'auto' }}>
                  <table className="proj-list-table" style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', minWidth: '900px' }}>
                    <thead style={{ backgroundColor: '#f8fafc', borderBottom: '2px solid #e2e8f0' }}>
                      <tr>
                        <th style={{ width: "50px", padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>#</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>LOGO</th>
                        <th
                          className="sortable"
                          onClick={() => handleSort("projectCode")}
                          style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', cursor: 'pointer', textTransform: 'uppercase', letterSpacing: '0.5px' }}
                        >
                          PROJECT CODE{" "}
                          {sortConfig.key === "projectCode" &&
                            (sortConfig.direction === "asc" ? "▲" : "▼")}
                        </th>
                        <th
                          className="sortable"
                          onClick={() => handleSort("projectName")}
                          style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', cursor: 'pointer', textTransform: 'uppercase', letterSpacing: '0.5px' }}
                        >
                          PROJECT NAME{" "}
                          {sortConfig.key === "projectName" &&
                            (sortConfig.direction === "asc" ? "▲" : "▼")}
                        </th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>DEPARTMENT</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>PRIORITY</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>DATES</th>
                        <th style={{ padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>STATUS</th>
                        <th style={{ textAlign: "center", width: "100px", padding: '14px 20px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                          ACTIONS
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {currentItems.length > 0 ? (
                        currentItems.map((project, index) => (
                          <tr key={project.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{indexOfFirstItem + index + 1}</td>
                            <td style={{ padding: '14px 20px' }}>
                              {project.logo ? (
                                <img src={project.logo} alt="Logo" style={{ width: '32px', height: '32px', borderRadius: '4px', objectFit: 'cover', border: '1px solid #e2e8f0' }} />
                              ) : (
                                <div style={{ width: '32px', height: '32px', borderRadius: '4px', background: '#f1f5f9', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px solid #e2e8f0' }}>
                                  <ImageIcon size={16} style={{ color: '#94a3b8' }} />
                                </div>
                              )}
                            </td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>
                              <span style={{ backgroundColor: '#f1f5f9', padding: '4px 10px', borderRadius: '4px', fontWeight: '600', color: '#0f172a', border: '1px solid #e2e8f0', fontSize: '13px' }}>
                                {project.projectCode}
                              </span>
                            </td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}><strong>{project.projectName}</strong></td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>{project.department || "N/A"}</td>
                            <td style={{ padding: '14px 20px', fontSize: '14px', color: '#334155' }}>
                              <span style={{ 
                                padding: '4px 10px', 
                                borderRadius: '4px', 
                                fontSize: '12px', 
                                fontWeight: '600',
                                display: 'inline-block',
                                backgroundColor: project.priority === 'HIGH' ? '#fef2f2' : 
                                              project.priority === 'NORMAL' ? '#eff6ff' :
                                              project.priority === 'MEDIUM' ? '#fefce8' : '#f0fdf4',
                                color: project.priority === 'HIGH' ? '#dc2626' : 
                                       project.priority === 'NORMAL' ? '#2563eb' :
                                       project.priority === 'MEDIUM' ? '#ca8a04' : '#16a34a'
                              }}>
                                {project.priority}
                              </span>
                            </td>
                            <td style={{ padding: '14px 20px', fontSize: '13px', color: '#475569' }}>
                              <div style={{ display: 'flex', flexDirection: 'column' }}>
                                <span style={{ fontSize: '12px' }}>Start: {project.startDate}</span>
                                <span style={{ fontSize: '12px', color: '#94a3b8' }}>End: {project.endDate}</span>
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
                                  backgroundColor: project.status === 'Live' ? '#dcfce7' : 
                                                project.status === 'Draft' ? '#fefce8' :
                                                project.status === 'Hold' ? '#fef3c7' : '#fee2e2',
                                  color: project.status === 'Live' ? '#166534' : 
                                         project.status === 'Draft' ? '#854d0e' :
                                         project.status === 'Hold' ? '#92400e' : '#991b1b'
                                }}
                              >
                                {project.status}
                              </span>
                            </td>
                            <td style={{ position: "relative", padding: '14px 20px', textAlign: 'center' }}>
                              <button
                                type="button"
                                style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#64748b', padding: '4px 8px', borderRadius: '4px' }}
                                onClick={() => toggleDropdown(project.id)}
                                onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f1f5f9'}
                                onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
                              >
                                <MoreVertical size={18} />
                              </button>

                              {/* Actions Dropdown menu */}
                              {activeDropdown === project.id && (
                                <>
                                  <div
                                    className="proj-actions-dropdown-backdrop"
                                    onClick={() => setActiveDropdown(null)}
                                    style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, zIndex: 9 }}
                                  />
                                  <div className="proj-actions-dropdown-menu" style={{ position: 'absolute', right: '30px', top: '8px', backgroundColor: 'white', border: '1px solid #e2e8f0', borderRadius: '8px', boxShadow: '0 4px 12px rgba(0,0,0,0.15)', zIndex: 10, display: 'flex', flexDirection: 'column', padding: '4px 0', minWidth: '140px' }}>
                                    <button
                                      type="button"
                                      style={{ padding: '10px 16px', textAlign: 'left', background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px', color: '#334155', borderRadius: '4px', margin: '2px 4px' }}
                                      onClick={() => {
                                        alert(
                                          `Project Details:\nCode: ${project.projectCode}\nName: ${project.projectName}\nDepartment: ${project.department || 'N/A'}\nPriority: ${project.priority}\nStatus: ${project.status}\nStart: ${project.startDate}\nEnd: ${project.endDate}`
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
                                      onClick={() => handleEdit(project)}
                                      onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f1f5f9'}
                                      onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
                                    >
                                      <Edit size={15} /> Edit
                                    </button>
                                    <button
                                      type="button"
                                      style={{ padding: '10px 16px', textAlign: 'left', background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px', color: '#ef4444', borderRadius: '4px', margin: '2px 4px' }}
                                      onClick={() => triggerDeactivate(project.id)}
                                      onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#fef2f2'}
                                      onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
                                    >
                                      <Trash2 size={15} /> Close
                                    </button>
                                    <button
                                      type="button"
                                      style={{ padding: '10px 16px', textAlign: 'left', background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px', color: '#ef4444', borderRadius: '4px', margin: '2px 4px' }}
                                      onClick={() => handleDelete(project.id)}
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
                          <td colSpan="9" style={{ textAlign: "center", padding: "60px 20px", color: '#64748b', fontSize: '14px' }}>
                            No project records found. Add a new project using the button above.
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>

                {/* Pagination bar */}
                {totalPages > 0 && (
                  <div className="proj-table-pagination-bar" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '14px 24px', borderTop: '1px solid #e2e8f0', backgroundColor: '#fafbfc' }}>
                    <span className="proj-pagination-info" style={{ fontSize: '14px', color: '#64748b' }}>
                      Showing {filteredProjects.length > 0 ? indexOfFirstItem + 1 : 0} to{" "}
                      {Math.min(indexOfLastItem, filteredProjects.length)} of{" "}
                      {filteredProjects.length} entries
                    </span>
                    <div className="proj-pagination-controls" style={{ display: 'flex', gap: '4px' }}>
                      <button
                        type="button"
                        className="proj-pag-btn"
                        onClick={() => paginate(currentPage - 1)}
                        disabled={currentPage === 1}
                      >
                        <ChevronLeft size={16} />
                      </button>
                      {Array.from({ length: totalPages }, (_, i) => (
                        <button
                          key={i + 1}
                          className={`proj-pag-btn ${currentPage === i + 1 ? 'active' : ''}`}
                          onClick={() => paginate(i + 1)}
                        >
                          {i + 1}
                        </button>
                      ))}
                      <button
                        type="button"
                        className="proj-pag-btn"
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
        <div className="proj-modal-overlay" style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.5)', zIndex: 99, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div className="proj-modal" style={{ backgroundColor: 'white', borderRadius: '8px', width: '400px', maxWidth: '90%', boxShadow: '0 10px 15px -3px rgba(0,0,0,0.1)' }}>
            <div className="proj-modal-header" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 20px', borderBottom: '1px solid #e2e8f0' }}>
              <h3 style={{ margin: 0, fontSize: '16px', fontWeight: '700', color: '#1e293b' }}>Close Project Record</h3>
              <button
                type="button"
                className="proj-modal-close"
                onClick={() => setShowDeactivateModal(false)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#64748b' }}
              >
                <X size={18} />
              </button>
            </div>
            <div className="proj-modal-body" style={{ padding: '20px' }}>
              <p style={{ margin: '0 0 8px 0', color: '#334155', fontSize: '14px' }}>Are you sure you want to close this project record?</p>
              <p className="proj-modal-warning" style={{ margin: 0, color: '#ef4444', fontSize: '13px', fontWeight: '500' }}>
                This will change its status to Closed.
              </p>
            </div>
            <div className="proj-modal-footer" style={{ padding: '16px 20px', borderTop: '1px solid #e2e8f0', display: 'flex', justifyContent: 'flex-end', gap: '10px', backgroundColor: '#f8fafc' }}>
              <button
                type="button"
                className="proj-btn-cancel-modal"
                onClick={() => setShowDeactivateModal(false)}
              >
                Cancel
              </button>
              <button
                type="button"
                className="proj-btn-delete-modal"
                onClick={confirmDeactivate}
              >
                <Trash2 size={14} /> Close Project
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ProjectCreation;