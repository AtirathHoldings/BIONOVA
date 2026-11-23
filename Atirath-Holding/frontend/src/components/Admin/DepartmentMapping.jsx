import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import Sidebar from "../Sidebar.jsx";
import Header from "../Header.jsx";
import AlertModal from "../AlertModal.jsx";
import { getScreenPermission } from "../../utils/permissions";
import {
  Search,
  ArrowLeft,
  RefreshCcw,
  Save,
  Edit,
  Trash2,
  Eye,
  Plus,
  MoreVertical,
  Check,
  X
} from "lucide-react";
import "../../styles/DepartmentMapping.css";

const API_BASE = (import.meta.env.VITE_API_BASE_URL) + "/api";
const getAuthToken = () => sessionStorage.getItem("authToken") || "";
const authHeaders = () => ({
  "Content-Type": "application/json",
  "Authorization": `Bearer ${getAuthToken()}`
});

const SearchableSelect = ({ options, value, onChange, placeholder, name, style, disabled, onCreate }) => {
  const [isOpen, setIsOpen] = useState(false);
  const [search, setSearch] = useState("");
  const wrapperRef = React.useRef(null);

  React.useEffect(() => {
    const handleClickOutside = (e) => {
      if (wrapperRef.current && !wrapperRef.current.contains(e.target)) setIsOpen(false);
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const filtered = options.filter(o => o.label.toLowerCase().includes(search.toLowerCase()));
  const selected = options.find(o => String(o.value) === String(value));

  return (
    <div ref={wrapperRef} style={{ position: 'relative', width: '100%', ...style }}>
      <div 
        onClick={() => !disabled && setIsOpen(!isOpen)}
        style={{
          padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '6px',
          background: disabled ? '#f1f5f9' : 'white', cursor: disabled ? 'not-allowed' : 'pointer', display: 'flex', justifyContent: 'space-between', alignItems: 'center', height: '40px', fontSize: '14px', color: '#0f172a'
        }}
      >
        <span>{selected ? selected.label : placeholder || "Select..."}</span>
        <span style={{ fontSize: '12px', color: '#64748b' }}>▼</span>
      </div>
      {isOpen && !disabled && (
        <div style={{
          position: 'absolute', top: '100%', left: 0, right: 0, 
          background: 'white', border: '1px solid #cbd5e1', borderRadius: '6px',
          marginTop: '4px', zIndex: 999, maxHeight: '250px', overflowY: 'auto',
          boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1)'
        }} onClick={e => e.stopPropagation()}>
          <div style={{ padding: '8px', position: 'sticky', top: 0, background: 'white', borderBottom: '1px solid #e2e8f0', zIndex: 2 }}>
            <input 
              type="text" 
              value={search} 
              onChange={e => setSearch(e.target.value)} 
              placeholder="Search..." 
              style={{ width: '100%', padding: '8px', border: '1px solid #cbd5e1', borderRadius: '4px', fontSize: '13px', outline: 'none', boxSizing: 'border-box' }}
            />
            {onCreate && (
              <div 
                onClick={(e) => {
                  e.stopPropagation();
                  setIsOpen(false);
                  onCreate();
                }}
                style={{
                  marginTop: '8px', padding: '8px 10px', cursor: 'pointer', fontSize: '13px',
                  color: '#2563eb', fontWeight: '600', display: 'flex', alignItems: 'center', gap: '6px',
                  borderRadius: '4px', backgroundColor: '#eff6ff', border: '1px solid #bfdbfe'
                }}
                onMouseEnter={e => e.currentTarget.style.backgroundColor = '#dbeafe'}
                onMouseLeave={e => e.currentTarget.style.backgroundColor = '#eff6ff'}
              >
                <Plus size={14} /> Create New
              </div>
            )}
          </div>
          <div style={{ padding: '4px 0' }}>
            {filtered.map(opt => (
              <div 
                key={opt.value}
                onClick={() => {
                  onChange({ target: { name, value: opt.value } });
                  setIsOpen(false);
                  setSearch("");
                }}
                style={{
                  padding: '8px 12px', cursor: 'pointer', fontSize: '14px',
                  background: String(value) === String(opt.value) ? '#f1f5f9' : 'transparent',
                  color: '#0f172a'
                }}
                onMouseEnter={e => e.currentTarget.style.background = '#f8fafc'}
                onMouseLeave={e => e.currentTarget.style.background = String(value) === String(opt.value) ? '#f1f5f9' : 'transparent'}
              >
                {opt.label}
              </div>
            ))}
            {filtered.length === 0 && (
              <div style={{ padding: '8px 12px', fontSize: '14px', color: '#64748b', textAlign: 'center' }}>No options found</div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

const MultiSearchableSelect = ({ options, value = [], onChange, placeholder, name, style, disabled, onCreate }) => {
  const [isOpen, setIsOpen] = useState(false);
  const [search, setSearch] = useState("");
  const wrapperRef = React.useRef(null);

  React.useEffect(() => {
    const handleClickOutside = (e) => {
      if (wrapperRef.current && !wrapperRef.current.contains(e.target)) setIsOpen(false);
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const selectedValues = (Array.isArray(value) ? value : (value ? [value] : [])).map(String);
  const filtered = options.filter(o => 
    (o.label || "").toLowerCase().includes(search.toLowerCase()) ||
    (o.code || "").toLowerCase().includes(search.toLowerCase())
  );

  const toggleOption = (optVal) => {
    const strVal = String(optVal);
    let newValues;
    if (selectedValues.includes(strVal)) {
      newValues = selectedValues.filter(v => v !== strVal);
    } else {
      newValues = [...selectedValues, optVal];
    }
    onChange({ target: { name, value: newValues } });
  };

  const removeOption = (e, optVal) => {
    e.stopPropagation();
    const strVal = String(optVal);
    const newValues = selectedValues.filter(v => v !== strVal);
    onChange({ target: { name, value: newValues } });
  };

  const handleSelectAll = (e) => {
    e.stopPropagation();
    const allFilteredVals = filtered.map(o => o.value);
    const combined = Array.from(new Set([...selectedValues, ...allFilteredVals]));
    onChange({ target: { name, value: combined } });
  };

  const handleClearAll = (e) => {
    e.stopPropagation();
    onChange({ target: { name, value: [] } });
  };

  const selectedObjects = options.filter(o => selectedValues.includes(String(o.value)));

  return (
    <div ref={wrapperRef} style={{ position: 'relative', width: '100%', ...style }}>
      <div 
        onClick={() => !disabled && setIsOpen(!isOpen)}
        style={{
          padding: '6px 12px',
          border: '1px solid #cbd5e1',
          borderRadius: '6px',
          background: disabled ? '#f1f5f9' : 'white',
          cursor: disabled ? 'not-allowed' : 'pointer',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          minHeight: '40px',
          fontSize: '14px',
          color: '#0f172a',
          gap: '8px',
          boxSizing: 'border-box'
        }}
      >
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px', alignItems: 'center', flex: 1, minWidth: 0 }}>
          {selectedObjects.length === 0 ? (
            <span style={{ color: '#94a3b8', fontSize: '13px' }}>{placeholder || "Select Departments..."}</span>
          ) : (
            selectedObjects.map(item => (
              <span
                key={item.value}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '4px',
                  backgroundColor: '#eff6ff',
                  color: '#1e40af',
                  border: '1px solid #bfdbfe',
                  borderRadius: '4px',
                  padding: '2px 8px',
                  fontSize: '12px',
                  fontWeight: '500',
                  lineHeight: '18px'
                }}
              >
                <span>{item.label}</span>
                {!disabled && (
                  <span
                    onClick={(e) => removeOption(e, item.value)}
                    style={{
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      color: '#60a5fa',
                      marginLeft: '2px'
                    }}
                    onMouseEnter={(e) => e.currentTarget.style.color = '#ef4444'}
                    onMouseLeave={(e) => e.currentTarget.style.color = '#60a5fa'}
                  >
                    <X size={12} />
                  </span>
                )}
              </span>
            ))
          )}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', flexShrink: 0 }}>
          {selectedObjects.length > 0 && !disabled && (
            <span
              onClick={handleClearAll}
              title="Clear all"
              style={{
                cursor: 'pointer',
                color: '#94a3b8',
                display: 'flex',
                alignItems: 'center',
                padding: '2px'
              }}
              onMouseEnter={(e) => e.currentTarget.style.color = '#ef4444'}
              onMouseLeave={(e) => e.currentTarget.style.color = '#94a3b8'}
            >
              <X size={14} />
            </span>
          )}
          <span style={{ fontSize: '11px', color: '#64748b' }}>▼</span>
        </div>
      </div>

      {isOpen && !disabled && (
        <div style={{
          position: 'absolute', top: '100%', left: 0, right: 0, 
          background: 'white', border: '1px solid #cbd5e1', borderRadius: '6px',
          marginTop: '4px', zIndex: 999, maxHeight: '300px', overflowY: 'auto',
          boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1)'
        }} onClick={e => e.stopPropagation()}>
          <div style={{ padding: '8px', position: 'sticky', top: 0, background: 'white', borderBottom: '1px solid #e2e8f0', zIndex: 2 }}>
            <input 
              type="text" 
              value={search} 
              onChange={e => setSearch(e.target.value)} 
              placeholder="Search departments..." 
              style={{ width: '100%', padding: '8px', border: '1px solid #cbd5e1', borderRadius: '4px', fontSize: '13px', outline: 'none', boxSizing: 'border-box' }}
              autoFocus
            />
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '8px', gap: '8px' }}>
              <div style={{ display: 'flex', gap: '6px' }}>
                <button
                  type="button"
                  onClick={handleSelectAll}
                  style={{
                    padding: '3px 8px', fontSize: '11px', fontWeight: '600',
                    color: '#2563eb', background: '#eff6ff', border: '1px solid #bfdbfe',
                    borderRadius: '4px', cursor: 'pointer'
                  }}
                >
                  Select All
                </button>
                <button
                  type="button"
                  onClick={handleClearAll}
                  style={{
                    padding: '3px 8px', fontSize: '11px', fontWeight: '600',
                    color: '#64748b', background: '#f1f5f9', border: '1px solid #cbd5e1',
                    borderRadius: '4px', cursor: 'pointer'
                  }}
                >
                  Clear All
                </button>
              </div>
              {onCreate && (
                <div 
                  onClick={(e) => {
                    e.stopPropagation();
                    setIsOpen(false);
                    onCreate();
                  }}
                  style={{
                    padding: '3px 8px', cursor: 'pointer', fontSize: '11px',
                    color: '#2563eb', fontWeight: '600', display: 'flex', alignItems: 'center', gap: '4px',
                    borderRadius: '4px', backgroundColor: '#eff6ff', border: '1px solid #bfdbfe'
                  }}
                  onMouseEnter={e => e.currentTarget.style.backgroundColor = '#dbeafe'}
                  onMouseLeave={e => e.currentTarget.style.backgroundColor = '#eff6ff'}
                >
                  <Plus size={12} /> Create New
                </div>
              )}
            </div>
          </div>
          <div style={{ padding: '4px 0', maxHeight: '180px', overflowY: 'auto' }}>
            {filtered.map(opt => {
              const isChecked = selectedValues.includes(String(opt.value));
              return (
                <div 
                  key={opt.value}
                  onClick={() => toggleOption(opt.value)}
                  style={{
                    padding: '8px 12px',
                    cursor: 'pointer',
                    fontSize: '13px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    gap: '10px',
                    background: isChecked ? '#f0fdf4' : 'transparent',
                    color: '#0f172a',
                    borderBottom: '1px solid #f8fafc'
                  }}
                  onMouseEnter={e => {
                    if (!isChecked) e.currentTarget.style.background = '#f8fafc';
                  }}
                  onMouseLeave={e => {
                    if (!isChecked) e.currentTarget.style.background = 'transparent';
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', minWidth: 0, flex: 1 }}>
                    <input 
                      type="checkbox"
                      checked={isChecked}
                      onChange={() => {}} // Handled by container onClick
                      style={{ cursor: 'pointer', width: '15px', height: '15px', accentColor: '#16a34a' }}
                    />
                    <span style={{ fontWeight: isChecked ? '600' : '400', fontSize: '13px', color: isChecked ? '#15803d' : '#0f172a' }}>
                      {opt.label}
                    </span>
                  </div>
                  {opt.code && (
                    <span style={{ fontSize: '11px', color: '#64748b', background: '#f1f5f9', padding: '2px 6px', borderRadius: '4px', border: '1px solid #e2e8f0', flexShrink: 0 }}>
                      {opt.code}
                    </span>
                  )}
                </div>
              );
            })}
            {filtered.length === 0 && (
              <div style={{ padding: '12px', fontSize: '13px', color: '#64748b', textAlign: 'center' }}>No departments found</div>
            )}
          </div>
          <div style={{
            padding: '8px 12px',
            borderTop: '1px solid #e2e8f0',
            backgroundColor: '#f8fafc',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center'
          }}>
            <span style={{ fontSize: '12px', color: '#64748b', fontWeight: '500' }}>
              {selectedValues.length} selected
            </span>
            <button
              type="button"
              onClick={() => setIsOpen(false)}
              style={{
                padding: '4px 12px',
                fontSize: '12px',
                fontWeight: '600',
                color: 'white',
                background: '#2563eb',
                border: 'none',
                borderRadius: '4px',
                cursor: 'pointer'
              }}
            >
              Done
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

const DepartmentMapping = ({ onLogout, userRole }) => {
  const screenPerm = getScreenPermission('DEPARTMENT_MAPPING');
  const navigate = useNavigate();

  // Data states
  const [mappings, setMappings] = useState([]);
  const [companies, setCompanies] = useState([]);
  const [plants, setPlants] = useState([]);
  const [departments, setDepartments] = useState([]);
  
  // UI states
  const [view, setView] = useState("list");
  const [isEditing, setIsEditing] = useState(false);
  const [isViewing, setIsViewing] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [activeDropdown, setActiveDropdown] = useState(null);
  const [dropdownPos, setDropdownPos] = useState({ top: 0, right: 0 });

  // Scroll handler to reposition dropdown dynamically
  useEffect(() => {
    const handleScroll = () => {
      if (activeDropdown !== null) {
        const btn = document.getElementById(`action-btn-${activeDropdown}`);
        if (btn) {
          const rect = btn.getBoundingClientRect();
          const spaceBelow = window.innerHeight - rect.bottom;
          const spaceAbove = rect.top;
          const dropdownHeight = 250;
          const isTop = spaceBelow < dropdownHeight && spaceAbove > spaceBelow;
          setDropdownPos({
            isTop,
            top: rect.top,
            bottom: rect.bottom,
            right: Math.max(10, window.innerWidth - rect.right)
          });
        }
      }
    };

    window.addEventListener('scroll', handleScroll, true);
    return () => {
      window.removeEventListener('scroll', handleScroll, true);
    };
  }, [activeDropdown]);
  const [tableSearchQuery, setTableSearchQuery] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [loading, setLoading] = useState(true);

  // Department Creation Popup States
  const [showDeptPopup, setShowDeptPopup] = useState(false);
  const [newDeptData, setNewDeptData] = useState({ deptCode: "", deptNm: "", descr: "", sts: true });



  // Alert settings
  const [alertConfig, setAlertConfig] = useState({
    isOpen: false,
    type: "info",
    title: "",
    message: ""
  });

  const triggerAlert = (type, title, message) => {
    setAlertConfig({ isOpen: true, type, title, message });
  };

  // Form State
  const [formData, setFormData] = useState({
    coyId: "",
    pltId: "",
    deptId: "",
    deptIds: [],
    sts: true
  });

  // Fetch all mappings from backend
  const fetchMappings = async () => {
    try {
      const res = await fetch(`${API_BASE}/dept-coy-plt-maps`, { headers: authHeaders() });
      if (res.ok) {
        const data = await res.json();
        setMappings(data);
      }
    } catch (err) {
      console.error("Error fetching mappings:", err);
    }
  };

  // Fetch Companies, Plants, and Departments
  const fetchMetadata = async () => {
    setLoading(true);
    try {
      const [compRes, plantRes, deptRes] = await Promise.all([
        fetch(`${API_BASE}/companies`, { headers: authHeaders() }),
        fetch(`${API_BASE}/plants`, { headers: authHeaders() }),
        fetch(`${API_BASE}/departments`, { headers: authHeaders() })
      ]);

      if (compRes.ok) setCompanies(await compRes.json());
      if (plantRes.ok) setPlants(await plantRes.json());
      if (deptRes.ok) setDepartments(await deptRes.json());
    } catch (err) {
      console.error("Error fetching metadata:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMetadata();
    fetchMappings();
  }, []);

  // Filter plants based on selected company
  const filteredPlants = plants.filter(p => String(p.coyId) === String(formData.coyId));

  // Find info helper
  const currentDeptIds = Array.isArray(formData.deptIds) && formData.deptIds.length > 0
    ? formData.deptIds
    : (formData.deptId ? [formData.deptId] : []);

  const selectedDeptsList = departments.filter(d => 
    currentDeptIds.some(id => String(id) === String(d.deptId))
  );

  const selectedDept = selectedDeptsList[0] || null;
  const deptCode = selectedDept ? (selectedDept.deptCd || selectedDept.deptCode || "") : "";
  const deptNm = selectedDept ? selectedDept.deptNm : "";
  const deptDescr = selectedDept ? selectedDept.descr : "";

  // Handle Input Changes
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    if (name === "coyId") {
      setFormData(prev => ({ ...prev, coyId: value, pltId: "" }));
    } else if (name === "deptIds") {
      setFormData(prev => ({ ...prev, deptIds: value, deptId: value[0] || "" }));
    } else {
      setFormData(prev => ({ ...prev, [name]: value }));
    }
  };

  const handleToggleStatus = (e) => {
    setFormData(prev => ({ ...prev, sts: e.target.checked }));
  };

  const handleResetForm = () => {
    setFormData({
      coyId: "",
      pltId: "",
      deptId: "",
      deptIds: [],
      sts: true
    });
  };

  const handleCreateDept = async () => {
    if (!newDeptData.deptCode.trim() || !newDeptData.deptNm.trim()) {
      triggerAlert("error", "Validation Error", "Department Code and Name are required.");
      return;
    }

    if (/\s/.test(newDeptData.deptCode)) {
      triggerAlert("error", "Validation Error", "Spaces are not allowed in Department Code.");
      return;
    }

    if (/[^a-zA-Z0-9\s]/.test(newDeptData.deptNm.trim())) {
      triggerAlert("error", "Validation Error", "Special characters are not allowed in Department Name.");
      return;
    }

    if (!/[a-zA-Z]/.test(newDeptData.deptNm.trim())) {
      triggerAlert("error", "Validation Error", "Department Name must contain at least one letter.");
      return;
    }

    const codeToCheck = newDeptData.deptCode.trim().toUpperCase();
    const isDuplicate = departments.some(dept => {
      const apiCode = dept.deptCd || dept.deptCode || dept.code || "";
      return apiCode.toUpperCase() === codeToCheck;
    });

    if (isDuplicate) {
      triggerAlert("error", "Duplicate Error", "This Department Code already exists. Please use a unique code.");
      return;
    }

    const payload = {
      deptCode: codeToCheck,
      deptNm: newDeptData.deptNm.trim(),
      descr: newDeptData.descr ? newDeptData.descr.trim() : "",
      sts: newDeptData.sts
    };

    try {
      const res = await fetch(`${API_BASE}/departments`, {
        method: "POST",
        headers: authHeaders(),
        body: JSON.stringify(payload)
      });
      if (res.ok) {
        // Re-fetch all departments
        const deptRes = await fetch(`${API_BASE}/departments`, { headers: authHeaders() });
        if (deptRes.ok) {
          const freshDepts = await deptRes.json();
          setDepartments(freshDepts);
          const newlyCreated = freshDepts.find(d => {
            const apiCode = d.deptCd || d.deptCode || "";
            return apiCode.toUpperCase() === newDeptData.deptCode.trim().toUpperCase();
          });
          if (newlyCreated) {
            setFormData(prev => {
              const curIds = Array.isArray(prev.deptIds) ? [...prev.deptIds] : (prev.deptId ? [prev.deptId] : []);
              if (!curIds.some(id => String(id) === String(newlyCreated.deptId))) {
                curIds.push(newlyCreated.deptId);
              }
              return {
                ...prev,
                deptId: newlyCreated.deptId,
                deptIds: curIds
              };
            });
          }
        }
        triggerAlert("success", "Success", "Department created successfully!");
        setShowDeptPopup(false);
        setNewDeptData({ deptCode: "", deptNm: "", descr: "", sts: true });
      } else {
        let errData = {};
        try {
          errData = await res.json();
        } catch (e) {
          errData = { message: `Server returned status ${res.status}` };
        }
        triggerAlert("error", "Error", errData.message || "Failed to create department.");
      }
    } catch (err) {
      console.error("Error creating department:", err);
      triggerAlert("error", "Error", "A network error occurred.");
    }
  };

  const handleSave = async () => {
    if (!formData.coyId) {
      triggerAlert("error", "Validation Error", "Company selection is required.");
      return;
    }
    if (!formData.pltId) {
      triggerAlert("error", "Validation Error", "Plant selection is required.");
      return;
    }

    const deptIdsToSave = (Array.isArray(formData.deptIds) && formData.deptIds.length > 0)
      ? formData.deptIds
      : (formData.deptId ? [formData.deptId] : []);

    if (deptIdsToSave.length === 0) {
      triggerAlert("error", "Validation Error", "Department selection is required.");
      return;
    }

    // Existing mappings for this company and plant
    const existingDeptIdsForPlant = mappings
      .filter(m => String(m.coyId) === String(formData.coyId) && String(m.pltId) === String(formData.pltId))
      .map(m => String(m.deptId));

    try {
      if (isEditing) {
        const primaryDeptId = deptIdsToSave[0];
        const payload = {
          coyId: Number(formData.coyId),
          pltId: Number(formData.pltId),
          deptId: Number(primaryDeptId),
          sts: formData.sts
        };

        const res = await fetch(`${API_BASE}/dept-coy-plt-maps/${editingId}`, {
          method: "PUT",
          headers: authHeaders(),
          body: JSON.stringify(payload)
        });

        if (!res.ok) {
          const errorData = await res.json().catch(() => ({}));
          triggerAlert("error", "Error", errorData.message || "Failed to update mapping.");
          return;
        }

        // If extra departments were selected while editing, create them
        const additionalDeptIds = deptIdsToSave.slice(1).filter(id => !existingDeptIdsForPlant.includes(String(id)));
        if (additionalDeptIds.length > 0) {
          await Promise.all(
            additionalDeptIds.map(dId =>
              fetch(`${API_BASE}/dept-coy-plt-maps`, {
                method: "POST",
                headers: authHeaders(),
                body: JSON.stringify({
                  coyId: Number(formData.coyId),
                  pltId: Number(formData.pltId),
                  deptId: Number(dId),
                  sts: formData.sts
                })
              })
            )
          );
        }

        triggerAlert("success", "Success", "Department mapping updated successfully!");
        fetchMappings();
        handleResetForm();
        setIsEditing(false);
        setEditingId(null);
        setView("list");
      } else {
        // CREATE MODE
        const newDeptIds = deptIdsToSave.filter(id => !existingDeptIdsForPlant.includes(String(id)));
        const alreadyMappedCount = deptIdsToSave.length - newDeptIds.length;

        if (newDeptIds.length === 0) {
          triggerAlert("warning", "Already Mapped", "All selected department(s) are already mapped to this Company and Plant.");
          return;
        }

        const responses = await Promise.all(
          newDeptIds.map(dId =>
            fetch(`${API_BASE}/dept-coy-plt-maps`, {
              method: "POST",
              headers: authHeaders(),
              body: JSON.stringify({
                coyId: Number(formData.coyId),
                pltId: Number(formData.pltId),
                deptId: Number(dId),
                sts: formData.sts
              })
            })
          )
        );

        const allOk = responses.every(r => r.ok);
        const successCount = responses.filter(r => r.ok).length;

        if (allOk) {
          let msg = `${successCount} Department(s) mapped successfully!`;
          if (alreadyMappedCount > 0) {
            msg += ` (${alreadyMappedCount} were already mapped).`;
          }
          triggerAlert("success", "Success", msg);
          fetchMappings();
          handleResetForm();
          setIsEditing(false);
          setEditingId(null);
          setView("list");
        } else {
          fetchMappings();
          triggerAlert(
            "warning",
            "Partial Success",
            `${successCount} of ${newDeptIds.length} departments mapped successfully. Some could not be saved.`
          );
          if (successCount > 0) {
            handleResetForm();
            setView("list");
          }
        }
      }
    } catch (err) {
      console.error("Error saving department mapping:", err);
      triggerAlert("error", "Error", "A network error occurred while saving.");
    }
  };

  const handleEdit = (mapping) => {
    setFormData({
      coyId: mapping.coyId,
      pltId: mapping.pltId,
      deptId: mapping.deptId,
      deptIds: [mapping.deptId],
      sts: mapping.sts
    });
    setIsEditing(true);
    setIsViewing(false);
    setEditingId(mapping.mapId);
    setActiveDropdown(null);
    setView("form");
  };

  const handleView = (mapping) => {
    setFormData({
      coyId: mapping.coyId,
      pltId: mapping.pltId,
      deptId: mapping.deptId,
      deptIds: [mapping.deptId],
      sts: mapping.sts
    });
    setIsEditing(false);
    setIsViewing(true);
    setEditingId(mapping.mapId);
    setActiveDropdown(null);
    setView("form");
  };

  const handleDelete = (id) => {
    setAlertConfig({
      isOpen: true,
      type: "warning",
      title: "Confirm Delete",
      message: "Are you sure you want to delete this mapping record?",
      confirmText: "Delete",
      cancelText: "Cancel",
      onConfirm: async () => {
        try {
          const res = await fetch(`${API_BASE}/dept-coy-plt-maps/${id}`, {
            method: "DELETE",
            headers: authHeaders()
          });
          if (res.ok) {
            triggerAlert("success", "Success", "Mapping record deleted successfully!");
            fetchMappings();
            setActiveDropdown(null);
          } else {
            triggerAlert("error", "Error", "Failed to delete mapping record.");
          }
        } catch (err) {
          console.error("Error deleting mapping:", err);
          triggerAlert("error", "Error", "A network error occurred.");
        }
      }
    });
    setActiveDropdown(null);
  };

  const toggleDropdown = (e, id) => {
    e.stopPropagation();
    if (activeDropdown === id) {
      setActiveDropdown(null);
    } else {
      const btn = e.currentTarget;
      const rect = btn.getBoundingClientRect();
      
      const spaceBelow = window.innerHeight - rect.bottom;
      const spaceAbove = rect.top;
      const dropdownHeight = 250;

      setDropdownPos({
        isTop: spaceBelow < dropdownHeight && spaceAbove > spaceBelow,
        top: rect.top,
        bottom: rect.bottom,
        right: Math.max(10, window.innerWidth - rect.right)
      });
      setActiveDropdown(id);
    }
  };

  // Helper names resolver
  const getCompanyName = (id) => {
    const found = companies.find(c => String(c.coyId) === String(id));
    return found ? found.coyNm : `Company ID: ${id}`;
  };

  const getCompanyCode = (id) => {
    const found = companies.find(c => String(c.coyId) === String(id));
    return found ? (found.coyCd || found.coyCode || found.code || "N/A") : "N/A";
  };

  const getPlantName = (id) => {
    const found = plants.find(p => String(p.pltId) === String(id));
    return found ? found.pltNm : `Plant ID: ${id}`;
  };

  const getDeptName = (id) => {
    const found = departments.find(d => String(d.deptId) === String(id));
    return found ? found.deptNm : `Dept ID: ${id}`;
  };

  const getDeptCode = (id) => {
    const found = departments.find(d => String(d.deptId) === String(id));
    return found ? (found.deptCd || found.deptCode || "N/A") : "N/A";
  };

  const getDeptDescr = (id) => {
    const found = departments.find(d => String(d.deptId) === String(id));
    return found ? found.descr : "N/A";
  };

  const filteredMappings = mappings.filter(mapping => {
    if (!tableSearchQuery) return true;
    const searchLower = tableSearchQuery.toLowerCase();
    const coyNmStr = getCompanyName(mapping.coyId).toLowerCase();
    const pltNmStr = getPlantName(mapping.pltId).toLowerCase();
    const deptCodeStr = getDeptCode(mapping.deptId).toLowerCase();
    const deptNmStr = getDeptName(mapping.deptId).toLowerCase();
    
    return (
      deptCodeStr.includes(searchLower) ||
      coyNmStr.includes(searchLower) ||
      pltNmStr.includes(searchLower) ||
      deptNmStr.includes(searchLower)
    );
  });

  // Pagination logic
  const recordsPerPage = 10;
  const indexOfLastRecord = currentPage * recordsPerPage;
  const indexOfFirstRecord = indexOfLastRecord - recordsPerPage;
  const currentItems = filteredMappings.slice(indexOfFirstRecord, indexOfLastRecord);
  const totalPages = Math.ceil(filteredMappings.length / recordsPerPage);

  return (
    <div className="dept-map-shell-container" style={{ display: "flex", minHeight: "100vh", background: "#f8fafc" }}>
      {/* Sidebar */}
      <Sidebar userRole={userRole} onLogout={onLogout} />

      {/* Main View Container */}
      <div className="dept-map-shell" style={{ flex: 1, display: "flex", flexDirection: "column", minWidth: 0 }}>
        <Header title="Department Mapping" showSearch={false} />

        <main className="dept-map-content" style={{ padding: "24px", display: "flex", flexDirection: "column", gap: "24px" }}>
          
          {view === "form" ? (
            /* ================= VIEW: FORM MODE ================= */
            <div className="cc-form-card" style={{ backgroundColor: "white", borderRadius: "8px", border: "1px solid #e2e8f0", boxShadow: "0 1px 3px rgba(0,0,0,0.05)" }}>
              {/* Form Title & Back Bar */}
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "20px 24px", borderBottom: "1px solid #e2e8f0", backgroundColor: "#fafbfc" }}>
                <div>
                  <h2 style={{ fontSize: "20px", fontWeight: "700", color: "#0f172a", margin: 0 }}>
                    {isViewing ? "View Department Mapping" : isEditing ? "Edit Department Mapping" : "Department Mapping"}
                  </h2>
                  <p style={{ color: "#64748b", margin: "4px 0 0 0", fontSize: "14px" }}>
                    {isViewing ? "View mapping details" : "Map Department with Company and Plant"}
                  </p>
                </div>
                <button
                  type="button"
                  className="cc-nav-view-btn"
                  onClick={() => {
                    setView("list");
                    handleResetForm();
                    setIsEditing(false);
                    setIsViewing(false);
                    setEditingId(null);
                  }}
                  style={{ display: "flex", alignItems: "center", gap: "6px", padding: "8px 16px", background: "#2563eb", color: "white", border: "none", borderRadius: "6px", cursor: "pointer", fontSize: "13px", fontWeight: "500" }}
                >
                  <ArrowLeft size={15} /> Back to Department List
                </button>
              </div>

              {/* Form Fields */}
              <div style={{ padding: "24px", display: "flex", flexDirection: "column", gap: "28px" }}>
                
                {isViewing ? (
                  <div className="cc-view-unified" style={{ padding: '12px 0' }}>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0 40px' }}>
                      
                      {/* Left Column Fields */}
                      <div style={{ display: 'flex', flexDirection: 'column' }}>
                        <div style={{ display: 'grid', gridTemplateColumns: '160px 1fr', padding: '12px 0', borderBottom: '1px dashed #e2e8f0' }}>
                          <span style={{ fontSize: '13px', fontWeight: '600', color: '#64748b' }}>Company :</span>
                          <span style={{ fontSize: '14px', color: '#0f172a', fontWeight: '500' }}>{getCompanyName(formData.coyId) || '-'}</span>
                        </div>
                        <div style={{ display: 'grid', gridTemplateColumns: '160px 1fr', padding: '12px 0', borderBottom: '1px dashed #e2e8f0' }}>
                          <span style={{ fontSize: '13px', fontWeight: '600', color: '#64748b' }}>Plant :</span>
                          <span style={{ fontSize: '14px', color: '#0f172a', fontWeight: '500' }}>{getPlantName(formData.pltId) || '-'}</span>
                        </div>
                        <div style={{ display: 'grid', gridTemplateColumns: '160px 1fr', padding: '12px 0', borderBottom: '1px dashed #e2e8f0' }}>
                          <span style={{ fontSize: '13px', fontWeight: '600', color: '#64748b' }}>Department :</span>
                          <span style={{ fontSize: '14px', color: '#0f172a', fontWeight: '500' }}>{getDeptName(formData.deptId) || '-'}</span>
                        </div>
                      </div>
                      
                      {/* Right Column Fields */}
                      <div style={{ display: 'flex', flexDirection: 'column' }}>
                        <div style={{ display: 'grid', gridTemplateColumns: '160px 1fr', padding: '12px 0', borderBottom: '1px dashed #e2e8f0', alignItems: 'center' }}>
                          <span style={{ fontSize: '13px', fontWeight: '600', color: '#64748b' }}>Status :</span>
                          <span style={{ padding: '2px 10px', borderRadius: '12px', fontSize: '12px', fontWeight: '600', width: 'fit-content', backgroundColor: formData.sts === true ? '#dcfce7' : '#fee2e2', color: formData.sts === true ? '#166534' : '#991b1b' }}>{formData.sts === true ? 'Active' : 'Inactive'}</span>
                        </div>
                        <div style={{ display: 'grid', gridTemplateColumns: '160px 1fr', padding: '12px 0', borderBottom: '1px dashed #e2e8f0' }}>
                          <span style={{ fontSize: '13px', fontWeight: '600', color: '#64748b' }}>Department Code :</span>
                          <span style={{ fontSize: '14px', color: '#0f172a', fontWeight: '500' }}>{getDeptCode(formData.deptId) || '-'}</span>
                        </div>
                        <div style={{ display: 'grid', gridTemplateColumns: '160px 1fr', padding: '12px 0', borderBottom: '1px dashed #e2e8f0' }}>
                          <span style={{ fontSize: '13px', fontWeight: '600', color: '#64748b' }}>Description :</span>
                          <span style={{ fontSize: '14px', color: '#0f172a', fontWeight: '500' }}>{getDeptDescr(formData.deptId) || '-'}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                ) : (
                  <>
                    {/* Selection Header */}
                    <div>
                      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px" }}>
                        <h3 style={{ fontSize: "16px", fontWeight: "700", color: "#1e293b", margin: 0 }}>Mapping Selection</h3>
                        
                        {/* Status Toggle Bar */}
                        <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                          <span style={{ fontSize: "14px", fontWeight: "600", color: "#475569" }}>Status:</span>

                          <label style={{ position: "relative", display: "inline-block", width: "46px", height: "26px", margin: 0, opacity: isViewing ? 0.6 : 1, cursor: isViewing ? "not-allowed" : "pointer" }}>
                            <input
                              type="checkbox"
                              checked={formData.sts === true}
                              onChange={handleToggleStatus}
                              disabled={isViewing}
                              style={{ opacity: 0, width: 0, height: 0 }}
                            />
                            <span style={{
                              position: "absolute", cursor: "pointer", top: 0, left: 0, right: 0, bottom: 0,
                              backgroundColor: formData.sts === true ? "#10b981" : "#cbd5e1",
                              transition: ".4s", borderRadius: "34px"
                            }}>
                              <span style={{
                                position: "absolute", height: "20px", width: "20px",
                                left: formData.sts === true ? "23px" : "3px", bottom: "3px",
                                backgroundColor: "white", transition: ".4s", borderRadius: "50%",
                                boxShadow: "0 2px 4px rgba(0,0,0,0.1)"
                              }}></span>
                            </span>
                          </label>

                          <span style={{
                            fontSize: "14px", fontWeight: "600", minWidth: "60px",
                            color: formData.sts === true ? "#16a34a" : "#dc2626"
                          }}>
                            {formData.sts === true ? "Active" : "Inactive"}
                          </span>
                        </div>
                      </div>

                      <div className="cc-form-layout-row columns-3">
                        <label className="cc-field-item">
                          <span>Company <b style={{ color: "#ef4444" }}>*</b></span>
                          <SearchableSelect 
                            name="coyId" 
                            value={formData.coyId} 
                            onChange={handleInputChange} 
                            placeholder="Select Company"
                            options={companies.map(c => ({ value: c.coyId, label: c.coyNm }))}
                            disabled={isViewing}
                          />
                        </label>

                        <label className="cc-field-item">
                          <span>Plant <b style={{ color: "#ef4444" }}>*</b></span>
                          <SearchableSelect 
                            name="pltId" 
                            value={formData.pltId} 
                            onChange={handleInputChange} 
                            placeholder={formData.coyId ? "Select Plant" : "Select Company First"}
                            options={filteredPlants.map(p => ({ value: p.pltId, label: p.pltNm }))}
                            disabled={!formData.coyId || isViewing}
                          />
                        </label>

                        <label className="cc-field-item">
                          <span>Department <b style={{ color: "#ef4444" }}>*</b></span>
                          <MultiSearchableSelect 
                            name="deptIds" 
                            value={formData.deptIds && formData.deptIds.length > 0 ? formData.deptIds : (formData.deptId ? [formData.deptId] : [])} 
                            onChange={(e) => {
                              const selectedVals = e.target.value;
                              setFormData(prev => ({
                                ...prev,
                                deptIds: selectedVals,
                                deptId: selectedVals[0] || ""
                              }));
                            }} 
                            placeholder="Select Department(s)"
                            options={departments.map(d => ({ 
                              value: d.deptId, 
                              label: d.deptNm,
                              code: d.deptCd || d.deptCode || ""
                            }))}
                            onCreate={!isViewing ? () => setShowDeptPopup(true) : undefined}
                            disabled={isViewing}
                          />
                        </label>
                      </div>
                    </div>

                    {/* Details Header */}
                    {selectedDeptsList.length > 1 ? (
                      <div>
                        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "14px" }}>
                          <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                            <h3 style={{ fontSize: "16px", fontWeight: "700", color: "#1e293b", margin: 0 }}>
                              Selected Departments
                            </h3>
                            <span style={{
                              backgroundColor: "#eff6ff", color: "#2563eb", border: "1px solid #bfdbfe",
                              padding: "2px 8px", borderRadius: "12px", fontSize: "12px", fontWeight: "600"
                            }}>
                              {selectedDeptsList.length} Selected
                            </span>
                          </div>
                          <span style={{ fontSize: "13px", color: "#64748b" }}>
                            All {selectedDeptsList.length} departments will be mapped to the selected plant
                          </span>
                        </div>

                        <div style={{ border: '1px solid #e2e8f0', borderRadius: '8px', overflow: 'hidden', backgroundColor: 'white' }}>
                          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px' }}>
                            <thead>
                              <tr style={{ backgroundColor: '#f8fafc', borderBottom: '1px solid #e2e8f0', textAlign: 'left' }}>
                                <th style={{ padding: '10px 16px', width: '60px', color: '#64748b', fontWeight: '600' }}>S.NO</th>
                                <th style={{ padding: '10px 16px', width: '160px', color: '#64748b', fontWeight: '600' }}>DEPARTMENT CODE</th>
                                <th style={{ padding: '10px 16px', color: '#64748b', fontWeight: '600' }}>DEPARTMENT NAME</th>
                                <th style={{ padding: '10px 16px', color: '#64748b', fontWeight: '600' }}>DESCRIPTION</th>
                                <th style={{ padding: '10px 16px', width: '80px', textAlign: 'center', color: '#64748b', fontWeight: '600' }}>ACTION</th>
                              </tr>
                            </thead>
                            <tbody>
                              {selectedDeptsList.map((dept, idx) => (
                                <tr key={dept.deptId} style={{ borderBottom: idx < selectedDeptsList.length - 1 ? '1px solid #f1f5f9' : 'none' }}>
                                  <td style={{ padding: '12px 16px', color: '#64748b' }}>{idx + 1}</td>
                                  <td style={{ padding: '12px 16px' }}>
                                    <span style={{ backgroundColor: '#f1f5f9', padding: '3px 8px', borderRadius: '4px', fontWeight: '600', color: '#0f172a', border: '1px solid #e2e8f0', fontSize: '12px' }}>
                                      {dept.deptCd || dept.deptCode || "-"}
                                    </span>
                                  </td>
                                  <td style={{ padding: '12px 16px', fontWeight: '600', color: '#0f172a' }}>{dept.deptNm}</td>
                                  <td style={{ padding: '12px 16px', color: '#64748b' }}>{dept.descr || "-"}</td>
                                  <td style={{ padding: '12px 16px', textAlign: 'center' }}>
                                    <button
                                      type="button"
                                      onClick={() => {
                                        const updated = (formData.deptIds || []).filter(id => String(id) !== String(dept.deptId));
                                        setFormData(prev => ({
                                          ...prev,
                                          deptIds: updated,
                                          deptId: updated[0] || ""
                                        }));
                                      }}
                                      style={{
                                        background: '#fee2e2', border: '1px solid #fecaca', color: '#ef4444', cursor: 'pointer', padding: '4px 8px', borderRadius: '4px', display: 'inline-flex', alignItems: 'center', gap: '4px', fontSize: '11px', fontWeight: '600'
                                      }}
                                      title="Remove department"
                                    >
                                      <X size={13} /> Remove
                                    </button>
                                  </td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                      </div>
                    ) : (
                      <div>
                        <div style={{ display: "flex", alignItems: "center", gap: "8px", marginBottom: "16px" }}>
                          <h3 style={{ fontSize: "16px", fontWeight: "700", color: "#1e293b", margin: 0 }}>Department Details</h3>
                        </div>

                        <div className="cc-form-layout-row columns-3">
                          <label className="cc-field-item">
                            <span>Department Code</span>
                            <input type="text" name="code" value={deptCode} readOnly style={{ backgroundColor: "#f8fafc", color: "#64748b", cursor: "not-allowed" }} placeholder="Auto-fills from Selection" />
                          </label>

                          <label className="cc-field-item">
                            <span>Department Name</span>
                            <input type="text" name="name" value={deptNm} readOnly style={{ backgroundColor: "#f8fafc", color: "#64748b", cursor: "not-allowed" }} placeholder="Auto-fills from Selection" />
                          </label>

                          <label className="cc-field-item">
                            <span>Description</span>
                            <textarea name="description" value={deptDescr} readOnly style={{ backgroundColor: "#f8fafc", color: "#64748b", cursor: "not-allowed" }} placeholder="Auto-fills from selection" rows={2} />
                          </label>
                        </div>
                      </div>
                    )}
                  </>
                )}

              </div>

              {/* Form Action Buttons */}
              {!isViewing && (
              <div className="cc-form-footer" style={{ display: "flex", justifyContent: "flex-end", gap: "12px", padding: "16px 24px", backgroundColor: "#fafbfc", borderTop: "1px solid #e2e8f0" }}>
                <button type="button" className="cc-btn primary" onClick={handleSave}>
                  <Save size={14} /> {isEditing ? "Update Mapping" : selectedDeptsList.length > 1 ? `Save (${selectedDeptsList.length}) Mappings` : "Save Mapping"}
                </button>
                <button type="button" className="cc-btn secondary" onClick={() => { setView("list"); handleResetForm(); setIsEditing(false); setIsViewing(false); setEditingId(null); }}>
                  Cancel
                </button>
              </div>
              )}
            </div>
          ) : (
            /* ================= VIEW: LIST MODE ================= */
            <div className="cc-table-panel" style={{ backgroundColor: "white", borderRadius: "8px", border: "1px solid #e2e8f0", overflow: "hidden", boxShadow: "0 1px 3px rgba(0,0,0,0.05)" }}>
              {/* Table Title and Mapping selection Button */}
              <div className="dept-map-list-header master-list-header">
                <div>
                  <h2 style={{ fontSize: "18px", fontWeight: "700", color: "#0f172a", margin: 0 }}>
                    Mapped Departments
                  </h2>
                  <p style={{ color: "#64748b", margin: "4px 0 0 0", fontSize: "14px" }}>
                    View and manage department mappings with companies and plants
                  </p>
                </div>
                <div className="dept-map-list-actions master-list-actions">
                  <div className="dept-map-search-box master-search-box">
                    <Search size={16} className="master-search-icon" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#64748b' }} />
                    <input
                      type="text"
                      placeholder="Search mappings..."
                      value={tableSearchQuery}
                      onChange={(e) => {
                        setTableSearchQuery(e.target.value);
                        setCurrentPage(1);
                      }}
                      className="dept-map-search-input master-search-input"
                    />
                  </div>
                  {screenPerm.canCreate && (
                    <button
                      type="button"
                      className="cc-btn-add-new master-btn-add-new"
                      onClick={() => {
                        handleResetForm();
                        setIsEditing(false);
                        setIsViewing(false);
                        setView("form");
                      }}
                    >
                      <Plus size={16} /> Add Department Mapping
                    </button>
                  )}
                </div>
              </div>

              {/* Data Table */}
              <div className="cc-table-container" style={{ overflowX: "auto" }}>
                <table className="cc-list-table department-mapping-table" style={{ width: "100%", borderCollapse: "collapse", textAlign: "left" }}>
                  <thead style={{ backgroundColor: "#f8fafc", borderBottom: "2px solid #e2e8f0" }}>
                    <tr>
                      <th className="deptmap-col-hide-mobile" style={{ width: "50px", padding: "14px 20px", fontSize: "11px", color: "#64748b", fontWeight: "700", textTransform: "uppercase", letterSpacing: "0.5px" }}>S.NO</th>
                      <th className="col-deptmap-code" style={{ padding: "14px 20px", fontSize: "11px", color: "#64748b", fontWeight: "700", textTransform: "uppercase", letterSpacing: "0.5px" }}>Department Code</th>
                      <th className="deptmap-col-hide-mobile" style={{ padding: "14px 20px", fontSize: "11px", color: "#64748b", fontWeight: "700", textTransform: "uppercase", letterSpacing: "0.5px" }}>Company</th>
                      <th className="deptmap-col-hide-mobile" style={{ padding: "14px 20px", fontSize: "11px", color: "#64748b", fontWeight: "700", textTransform: "uppercase", letterSpacing: "0.5px" }}>Plant</th>
                      <th className="col-deptmap-name" style={{ padding: "14px 20px", fontSize: "11px", color: "#64748b", fontWeight: "700", textTransform: "uppercase", letterSpacing: "0.5px" }}>Department</th>
                      <th className="deptmap-col-hide-mobile" style={{ padding: "14px 20px", fontSize: "11px", color: "#64748b", fontWeight: "700", textTransform: "uppercase", letterSpacing: "0.5px" }}>Status</th>
                      <th className="col-deptmap-actions" style={{ textAlign: "center", width: "100px", padding: "14px 20px", fontSize: "11px", color: "#64748b", fontWeight: "700", textTransform: "uppercase", letterSpacing: "0.5px" }}>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {currentItems.length > 0 ? (
                      currentItems.map((item, idx) => (
                        <tr key={item.mapId || idx} style={{ borderBottom: "1px solid #f1f5f9" }}>
                          <td data-label="S.NO" className="deptmap-col-hide-mobile" style={{ padding: "14px 20px", fontSize: "14px", color: "#334155" }}>{indexOfFirstRecord + idx + 1}</td>
                          <td data-label="DEPARTMENT CODE" className="col-deptmap-code" style={{ padding: "14px 20px", fontSize: "14px", color: "#334155" }}>
                            <span style={{ backgroundColor: "#f1f5f9", padding: "4px 10px", borderRadius: "4px", fontWeight: "600", color: "#0f172a", border: "1px solid #e2e8f0", fontSize: "13px" }}>
                              {getDeptCode(item.deptId)}
                            </span>
                          </td>
                          <td data-label="COMPANY NAME" className="deptmap-col-hide-mobile" style={{ padding: "14px 20px", fontSize: "14px", color: "#334155" }}><strong>{getCompanyName(item.coyId)}</strong></td>
                          <td data-label="PLANT NAME" className="deptmap-col-hide-mobile" style={{ padding: "14px 20px", fontSize: "14px", color: "#334155" }}>{getPlantName(item.pltId)}</td>
                          <td data-label="DEPARTMENT NAME" className="col-deptmap-name" style={{ padding: "14px 20px", fontSize: "14px", color: "#334155" }}>{getDeptName(item.deptId)}</td>
                          <td data-label="STATUS" className="deptmap-col-hide-mobile" style={{ padding: "14px 20px", fontSize: "14px", color: "#334155" }}>
                            <span style={{ padding: "4px 12px", borderRadius: "12px", fontSize: "12px", fontWeight: "600", display: "inline-block", backgroundColor: item.sts === true ? "#dcfce7" : "#fee2e2", color: item.sts === true ? "#166534" : "#991b1b" }}>
                              {item.sts === true ? "Active" : "Inactive"}
                            </span>
                          </td>
                          <td data-label="ACTIONS" className="col-deptmap-actions" style={{ position: "relative", padding: "14px 20px", textAlign: "center" }}>
                            <button
                              id={`action-btn-${item.mapId}`}
                              type="button"
                              style={{ background: "none", border: "none", cursor: "pointer", color: "#64748b", padding: "4px 8px", borderRadius: "4px" }}
                              onClick={(e) => toggleDropdown(e, item.mapId)}
                            >
                              <MoreVertical size={18} />
                            </button>

                            {activeDropdown === item.mapId && (
                              <>
                                <div className="cc-actions-dropdown-backdrop" onClick={() => setActiveDropdown(null)} style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, zIndex: 90 }} />
                                <div className="cc-actions-dropdown-menu" style={{ position: 'fixed', right: `${dropdownPos.right}px`, top: dropdownPos.isTop ? 'auto' : `${dropdownPos.bottom}px`, bottom: dropdownPos.isTop ? `${window.innerHeight - dropdownPos.top}px` : 'auto', backgroundColor: 'white', border: '1px solid #e2e8f0', borderRadius: '8px', boxShadow: '0 4px 12px rgba(0,0,0,0.15)', zIndex: 99, display: 'flex', flexDirection: 'column', padding: '4px 0', minWidth: '140px' }}>
                                  <button
                                    type="button"
                                    style={{ padding: "10px 16px", textAlign: "left", background: "none", border: "none", cursor: "pointer", display: "flex", alignItems: "center", gap: "10px", fontSize: "14px", color: "#334155", borderRadius: "4px", margin: "2px 4px" }}
                                    onClick={() => handleView(item)}
                                  >
                                    <Eye size={15} /> View
                                  </button>
                                  {screenPerm.canEdit && (
                                    <button
                                      type="button"
                                      style={{ padding: "10px 16px", textAlign: "left", background: "none", border: "none", cursor: "pointer", display: "flex", alignItems: "center", gap: "10px", fontSize: "14px", color: "#334155", borderRadius: "4px", margin: "2px 4px" }}
                                      onClick={() => handleEdit(item)}
                                    >
                                      <Edit size={15} /> Edit
                                    </button>
                                  )}
                                  {screenPerm.canDelete && (
                                    <button
                                      type="button"
                                      style={{ padding: "10px 16px", textAlign: "left", background: "none", border: "none", cursor: "pointer", display: "flex", alignItems: "center", gap: "10px", fontSize: "14px", color: "#ef4444", borderRadius: "4px", margin: "2px 4px" }}
                                      onClick={() => handleDelete(item.mapId)}
                                    >
                                      <Trash2 size={15} /> Delete
                                    </button>
                                  )}
                                </div>
                              </>
                            )}
                          </td>
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td colSpan="7" className="col-deptmap-empty" style={{ textAlign: "center", padding: "60px 20px" }}>
                          {loading ? (
                            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '10px', color: '#64748b', fontSize: '14px' }}>
                              <RefreshCcw className="spinning" style={{ animation: 'spin 1s linear infinite' }} size={16} />
                              <span>Loading department mappings...</span>
                            </div>
                          ) : (
                            <span style={{ color: '#64748b', fontSize: '14px' }}>No mapping records found. Click the button above to add a mapping.</span>
                          )}
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>

              {/* Pagination Controls */}
              {totalPages > 0 && (
                <div style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  padding: '16px 24px',
                  borderTop: '1px solid #e2e8f0',
                  backgroundColor: '#fafbfc'
                }}>
                  <span style={{ fontSize: '14px', color: '#64748b' }}>
                    Showing {indexOfFirstRecord + 1} to {Math.min(indexOfLastRecord, filteredMappings.length)} of {filteredMappings.length} entries
                  </span>
                  <div style={{ display: 'flex', gap: '8px' }}>
                    <button
                      onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
                      disabled={currentPage === 1}
                      style={{
                        padding: '6px 12px',
                        border: '1px solid #cbd5e1',
                        borderRadius: '6px',
                        background: currentPage === 1 ? '#f1f5f9' : 'white',
                        color: currentPage === 1 ? '#94a3b8' : '#334155',
                        cursor: currentPage === 1 ? 'not-allowed' : 'pointer',
                        fontSize: '14px',
                        fontWeight: '500'
                      }}
                    >
                      Previous
                    </button>
                    
                    <button
                      style={{
                        padding: '6px 12px',
                        border: '1px solid #2563eb',
                        borderRadius: '6px',
                        background: '#2563eb',
                        color: 'white',
                        cursor: 'default',
                        fontSize: '14px',
                        fontWeight: '500'
                      }}
                    >
                      {currentPage}
                    </button>

                    <button
                      onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
                      disabled={currentPage === totalPages}
                      style={{
                        padding: '6px 12px',
                        border: '1px solid #cbd5e1',
                        borderRadius: '6px',
                        background: currentPage === totalPages ? '#f1f5f9' : 'white',
                        color: currentPage === totalPages ? '#94a3b8' : '#334155',
                        cursor: currentPage === totalPages ? 'not-allowed' : 'pointer',
                        fontSize: '14px',
                        fontWeight: '500'
                      }}
                    >
                      Next
                    </button>
                  </div>
                </div>
              )}
            </div>
          )}

        </main>
      </div>

      <AlertModal
        isOpen={alertConfig.isOpen}
        type={alertConfig.type}
        title={alertConfig.title}
        message={alertConfig.message}
        onClose={() => setAlertConfig(prev => ({ ...prev, isOpen: false }))}
        onConfirm={alertConfig.onConfirm}
        confirmText={alertConfig.confirmText}
        cancelText={alertConfig.cancelText}
      />

      {showDeptPopup && (
        <div style={{
          position: "fixed", top: 0, left: 0, right: 0, bottom: 0,
          backgroundColor: "rgba(15, 23, 42, 0.6)",
          display: "flex", alignItems: "center", justifyContent: "center",
          zIndex: 9999, backdropFilter: "blur(4px)"
        }}>
          <div style={{
            backgroundColor: "white", borderRadius: "12px", width: "450px",
            boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)",
            overflow: "hidden"
          }}>
            <div style={{ padding: "20px 24px", borderBottom: "1px solid #e2e8f0", display: "flex", justifyContent: "space-between", alignItems: "center", backgroundColor: "#f8fafc" }}>
              <h2 style={{ fontSize: "18px", fontWeight: "700", color: "#0f172a", margin: 0 }}>Create New Department</h2>
              <button 
                onClick={() => setShowDeptPopup(false)}
                style={{ background: "none", border: "none", color: "#64748b", cursor: "pointer", padding: "4px" }}
              >
                ✕
              </button>
            </div>
            
            <div style={{ padding: "24px", display: "flex", flexDirection: "column", gap: "16px" }}>
              <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
                <label style={{ fontSize: "14px", fontWeight: "600", color: "#475569" }}>Department Code <b style={{ color: "#ef4444" }}>*</b></label>
                <input 
                  type="text" 
                  value={newDeptData.deptCode}
                  readOnly
                  style={{ padding: "10px 12px", border: "1px solid #cbd5e1", borderRadius: "6px", fontSize: "14px", outline: "none" }}
                  placeholder="Auto-generated code"
                />
              </div>
              <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
                <label style={{ fontSize: "14px", fontWeight: "600", color: "#475569" }}>Department Name <b style={{ color: "#ef4444" }}>*</b></label>
                <input 
                  type="text" 
                  value={newDeptData.deptNm}
                  onChange={(e) => setNewDeptData(p => ({...p, deptNm: e.target.value}))}
                  style={{ padding: "10px 12px", border: "1px solid #cbd5e1", borderRadius: "6px", fontSize: "14px", outline: "none" }}
                  placeholder="e.g. Human Resources"
                />
              </div>
              <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
                <label style={{ fontSize: "14px", fontWeight: "600", color: "#475569" }}>Description</label>
                <textarea 
                  value={newDeptData.descr}
                  onChange={(e) => setNewDeptData(p => ({...p, descr: e.target.value}))}
                  style={{ padding: "10px 12px", border: "1px solid #cbd5e1", borderRadius: "6px", fontSize: "14px", outline: "none", minHeight: "80px", resize: "vertical" }}
                  placeholder="Department details..."
                />
              </div>
            </div>

            <div style={{ padding: "16px 24px", borderTop: "1px solid #e2e8f0", backgroundColor: "#f8fafc", display: "flex", justifyContent: "flex-end", gap: "12px" }}>
              <button 
                type="button" 
                onClick={() => setShowDeptPopup(false)}
                style={{ padding: "8px 16px", borderRadius: "6px", fontSize: "14px", fontWeight: "500", backgroundColor: "white", border: "1px solid #cbd5e1", color: "#475569", cursor: "pointer" }}
              >
                Cancel
              </button>
              <button 
                type="button" 
                onClick={handleCreateDept}
                style={{ padding: "8px 16px", borderRadius: "6px", fontSize: "14px", fontWeight: "500", backgroundColor: "#2563eb", border: "1px solid #2563eb", color: "white", cursor: "pointer" }}
              >
                Save Department
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default DepartmentMapping;