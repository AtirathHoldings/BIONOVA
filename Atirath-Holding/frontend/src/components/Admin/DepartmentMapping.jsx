import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import Sidebar from "../Sidebar";
import Header from "../Header";
import AlertModal from "../AlertModal";
import {
  Search,
  ArrowLeft,
  RefreshCcw,
  Save,
  Edit,
  Trash2,
  Eye,
  Plus,
  MoreVertical
} from "lucide-react";
import "../../styles/CompanyMaster.css";

const API_BASE = (import.meta.env.VITE_API_BASE_URL) + "/api";
const getAuthToken = () => sessionStorage.getItem("authToken") || "";
const authHeaders = () => ({
  "Content-Type": "application/json",
  "Authorization": `Bearer ${getAuthToken()}`
});

const DepartmentMapping = ({ onLogout, userRole }) => {
  const navigate = useNavigate();

  // Data states
  const [mappings, setMappings] = useState([]);
  const [companies, setCompanies] = useState([]);
  const [plants, setPlants] = useState([]);
  const [departments, setDepartments] = useState([]);
  
  // UI states
  const [view, setView] = useState("list");
  const [isEditing, setIsEditing] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [activeDropdown, setActiveDropdown] = useState(null);
  const [loading, setLoading] = useState(true);

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
  const selectedDept = departments.find(d => String(d.deptId) === String(formData.deptId));
  const deptCode = selectedDept ? selectedDept.deptCode : "";
  const deptNm = selectedDept ? selectedDept.deptNm : "";
  const deptDescr = selectedDept ? selectedDept.descr : "";

  // Handle Input Changes
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    if (name === "coyId") {
      setFormData(prev => ({ ...prev, coyId: value, pltId: "" }));
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
      sts: true
    });
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
    if (!formData.deptId) {
      triggerAlert("error", "Validation Error", "Department selection is required.");
      return;
    }

    const payload = {
      coyId: Number(formData.coyId),
      pltId: Number(formData.pltId),
      deptId: Number(formData.deptId),
      sts: formData.sts
    };

    try {
      let url = `${API_BASE}/dept-coy-plt-maps`;
      let method = "POST";
      if (isEditing) {
        url = `${API_BASE}/dept-coy-plt-maps/${editingId}`;
        method = "PUT";
      }

      const res = await fetch(url, {
        method,
        headers: authHeaders(),
        body: JSON.stringify(payload)
      });

      if (res.ok) {
        triggerAlert("success", "Success", isEditing ? "Department mapping updated successfully!" : "Department mapping created successfully!");
        fetchMappings();
        handleResetForm();
        setIsEditing(false);
        setEditingId(null);
        setView("list");
      } else {
        const errorData = await res.json();
        triggerAlert("error", "Error", errorData.message || "Failed to save mapping.");
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
      sts: mapping.sts
    });
    setIsEditing(true);
    setEditingId(mapping.mapId);
    setActiveDropdown(null);
    setView("form");
  };

  const handleDelete = async (id) => {
    if (window.confirm("Are you sure you want to delete this mapping record?")) {
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
  };

  const toggleDropdown = (id) => {
    setActiveDropdown(prev => (prev === id ? null : id));
  };

  // Helper names resolver
  const getCompanyName = (id) => {
    const found = companies.find(c => String(c.coyId) === String(id));
    return found ? found.coyNm : `Company ID: ${id}`;
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
    return found ? found.deptCode : "N/A";
  };

  const getDeptDescr = (id) => {
    const found = departments.find(d => String(d.deptId) === String(id));
    return found ? found.descr : "N/A";
  };

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
            <div className="cc-form-card" style={{ backgroundColor: "white", borderRadius: "8px", border: "1px solid #e2e8f0", overflow: "hidden", boxShadow: "0 1px 3px rgba(0,0,0,0.05)" }}>
              {/* Form Title & Back Bar */}
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "20px 24px", borderBottom: "1px solid #e2e8f0", backgroundColor: "#fafbfc" }}>
                <div>
                  <h2 style={{ fontSize: "20px", fontWeight: "700", color: "#0f172a", margin: 0 }}>
                    {isEditing ? "Edit Department Mapping" : "Department Mapping"}
                  </h2>
                  <p style={{ color: "#64748b", margin: "4px 0 0 0", fontSize: "14px" }}>
                    Map Department with Company and Plant
                  </p>
                </div>
                <button
                  type="button"
                  className="cc-nav-view-btn"
                  onClick={() => {
                    setView("list");
                    handleResetForm();
                    setIsEditing(false);
                    setEditingId(null);
                  }}
                  style={{ display: "flex", alignItems: "center", gap: "6px", padding: "8px 16px", background: "#2563eb", color: "white", border: "none", borderRadius: "6px", cursor: "pointer", fontSize: "13px", fontWeight: "500" }}
                >
                  <ArrowLeft size={15} /> Back to Department List
                </button>
              </div>

              {/* Form Fields */}
              <div style={{ padding: "24px", display: "flex", flexDirection: "column", gap: "28px" }}>
                
                {/* Selection Header */}
                <div>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px" }}>
                    <h3 style={{ fontSize: "16px", fontWeight: "700", color: "#1e293b", margin: 0 }}>Mapping Selection</h3>
                    
                    {/* Status Toggle Bar */}
                    <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                      <span style={{ fontSize: "14px", fontWeight: "600", color: "#475569" }}>Status:</span>

                      <label style={{ position: "relative", display: "inline-block", width: "46px", height: "26px", margin: 0 }}>
                        <input
                          type="checkbox"
                          checked={formData.sts === true}
                          onChange={handleToggleStatus}
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
                      <select name="coyId" value={formData.coyId} onChange={handleInputChange} style={{ backgroundColor: "white" }}>
                        <option value="" disabled hidden>Select Company</option>
                        {companies.map(c => (
                          <option key={c.coyId} value={c.coyId}>{c.coyNm}</option>
                        ))}
                      </select>
                    </label>

                    <label className="cc-field-item">
                      <span>Plant <b style={{ color: "#ef4444" }}>*</b></span>
                      <select name="pltId" value={formData.pltId} onChange={handleInputChange} style={{ backgroundColor: "white" }} disabled={!formData.coyId}>
                        <option value="" disabled hidden>{formData.coyId ? "Select Plant" : "Select Company First"}</option>
                        {filteredPlants.map(p => (
                          <option key={p.pltId} value={p.pltId}>{p.pltNm}</option>
                        ))}
                      </select>
                    </label>

                    <label className="cc-field-item">
                      <span>Department <b style={{ color: "#ef4444" }}>*</b></span>
                      <select name="deptId" value={formData.deptId} onChange={handleInputChange} style={{ backgroundColor: "white" }}>
                        <option value="" disabled hidden>Select Department</option>
                        {departments.map(d => (
                          <option key={d.deptId} value={d.deptId}>{d.deptNm}</option>
                        ))}
                      </select>
                    </label>
                  </div>
                </div>

                {/* Details Header */}
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

              </div>

              {/* Form Action Buttons */}
              <div className="cc-form-footer" style={{ display: "flex", justifyContent: "flex-end", gap: "12px", padding: "16px 24px", backgroundColor: "#fafbfc", borderTop: "1px solid #e2e8f0" }}>
                <button type="button" className="cc-btn secondary" onClick={() => { setView("list"); handleResetForm(); setIsEditing(false); setEditingId(null); }}>
                  Cancel
                </button>
                <button type="button" className="cc-btn tertiary" onClick={handleResetForm}>
                  <RefreshCcw size={14} /> Reset
                </button>
                <button type="button" className="cc-btn primary" onClick={handleSave}>
                  <Save size={14} /> {isEditing ? "Update Mapping" : "Save Mapping"}
                </button>
              </div>
            </div>
          ) : (
            /* ================= VIEW: LIST MODE ================= */
            <div className="cc-table-panel" style={{ backgroundColor: "white", borderRadius: "8px", border: "1px solid #e2e8f0", overflow: "hidden", boxShadow: "0 1px 3px rgba(0,0,0,0.05)" }}>
              {/* Table Title and Mapping selection Button */}
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "20px 24px", borderBottom: "1px solid #e2e8f0" }}>
                <div>
                  <h2 style={{ fontSize: "18px", fontWeight: "700", color: "#0f172a", margin: 0 }}>
                    Department Mappings
                  </h2>
                  <p style={{ color: "#64748b", margin: "4px 0 0 0", fontSize: "14px" }}>
                    View and manage department mappings with companies and plants
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
                  style={{ display: "flex", alignItems: "center", gap: "6px", padding: "8px 20px", background: "#2563eb", color: "white", border: "none", borderRadius: "6px", cursor: "pointer", fontSize: "14px", fontWeight: "500" }}
                >
                  <Plus size={16} /> Add Department Mapping
                </button>
              </div>

              {/* Data Table */}
              <div className="cc-table-container" style={{ overflowX: "auto" }}>
                <table className="cc-list-table" style={{ width: "100%", borderCollapse: "collapse", textAlign: "left", minWidth: "1200px" }}>
                  <thead style={{ backgroundColor: "#f8fafc", borderBottom: "2px solid #e2e8f0" }}>
                    <tr>
                      <th style={{ width: "50px", padding: "14px 20px", fontSize: "11px", color: "#64748b", fontWeight: "700", textTransform: "uppercase", letterSpacing: "0.5px" }}>#</th>
                      <th style={{ padding: "14px 20px", fontSize: "11px", color: "#64748b", fontWeight: "700", textTransform: "uppercase", letterSpacing: "0.5px" }}>Company</th>
                      <th style={{ padding: "14px 20px", fontSize: "11px", color: "#64748b", fontWeight: "700", textTransform: "uppercase", letterSpacing: "0.5px" }}>Plant</th>
                      <th style={{ padding: "14px 20px", fontSize: "11px", color: "#64748b", fontWeight: "700", textTransform: "uppercase", letterSpacing: "0.5px" }}>Department</th>
                      <th style={{ padding: "14px 20px", fontSize: "11px", color: "#64748b", fontWeight: "700", textTransform: "uppercase", letterSpacing: "0.5px" }}>Department Code</th>
                      <th style={{ padding: "14px 20px", fontSize: "11px", color: "#64748b", fontWeight: "700", textTransform: "uppercase", letterSpacing: "0.5px" }}>Status</th>
                      <th style={{ textAlign: "center", width: "100px", padding: "14px 20px", fontSize: "11px", color: "#64748b", fontWeight: "700", textTransform: "uppercase", letterSpacing: "0.5px" }}>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {mappings.length > 0 ? (
                      mappings.map((item, idx) => (
                        <tr key={item.mapId || idx} style={{ borderBottom: "1px solid #f1f5f9" }}>
                          <td style={{ padding: "14px 20px", fontSize: "14px", color: "#334155" }}>{idx + 1}</td>
                          <td style={{ padding: "14px 20px", fontSize: "14px", color: "#334155" }}><strong>{getCompanyName(item.coyId)}</strong></td>
                          <td style={{ padding: "14px 20px", fontSize: "14px", color: "#334155" }}>{getPlantName(item.pltId)}</td>
                          <td style={{ padding: "14px 20px", fontSize: "14px", color: "#334155" }}>{getDeptName(item.deptId)}</td>
                          <td style={{ padding: "14px 20px", fontSize: "14px", color: "#334155" }}>
                            <span style={{ backgroundColor: "#f1f5f9", padding: "4px 10px", borderRadius: "4px", fontWeight: "600", color: "#0f172a", border: "1px solid #e2e8f0", fontSize: "13px" }}>
                              {getDeptCode(item.deptId)}
                            </span>
                          </td>
                          <td style={{ padding: "14px 20px", fontSize: "14px", color: "#334155" }}>
                            <span style={{ padding: "4px 12px", borderRadius: "12px", fontSize: "12px", fontWeight: "600", display: "inline-block", backgroundColor: item.sts === true ? "#dcfce7" : "#fee2e2", color: item.sts === true ? "#166534" : "#991b1b" }}>
                              {item.sts === true ? "Active" : "Inactive"}
                            </span>
                          </td>
                          <td style={{ position: "relative", padding: "14px 20px", textAlign: "center" }}>
                            <button
                              type="button"
                              style={{ background: "none", border: "none", cursor: "pointer", color: "#64748b", padding: "4px 8px", borderRadius: "4px" }}
                              onClick={() => toggleDropdown(item.mapId)}
                            >
                              <MoreVertical size={18} />
                            </button>

                            {activeDropdown === item.mapId && (
                              <>
                                <div className="cc-actions-dropdown-backdrop" onClick={() => setActiveDropdown(null)} style={{ position: "fixed", top: 0, left: 0, right: 0, bottom: 0, zIndex: 9 }} />
                                <div className="cc-actions-dropdown-menu" style={{ position: "absolute", right: "30px", top: "8px", backgroundColor: "white", border: "1px solid #e2e8f0", borderRadius: "8px", boxShadow: "0 4px 12px rgba(0,0,0,0.15)", zIndex: 10, display: "flex", flexDirection: "column", padding: "4px 0", minWidth: "140px" }}>
                                  <button
                                    type="button"
                                    style={{ padding: "10px 16px", textAlign: "left", background: "none", border: "none", cursor: "pointer", display: "flex", alignItems: "center", gap: "10px", fontSize: "14px", color: "#334155", borderRadius: "4px", margin: "2px 4px" }}
                                    onClick={() => {
                                      triggerAlert(
                                        "info",
                                        "Mapping Details",
                                        `Department Mapping Details:\n\nCompany: ${getCompanyName(item.coyId)}\nPlant: ${getPlantName(item.pltId)}\nDepartment: ${getDeptName(item.deptId)}\nCode: ${getDeptCode(item.deptId)}\nDescription: ${getDeptDescr(item.deptId)}\nStatus: ${item.sts === true ? "Active" : "Inactive"}`
                                      );
                                      setActiveDropdown(null);
                                    }}
                                  >
                                    <Eye size={15} /> View
                                  </button>
                                  <button
                                    type="button"
                                    style={{ padding: "10px 16px", textAlign: "left", background: "none", border: "none", cursor: "pointer", display: "flex", alignItems: "center", gap: "10px", fontSize: "14px", color: "#334155", borderRadius: "4px", margin: "2px 4px" }}
                                    onClick={() => handleEdit(item)}
                                  >
                                    <Edit size={15} /> Edit
                                  </button>
                                  <button
                                    type="button"
                                    style={{ padding: "10px 16px", textAlign: "left", background: "none", border: "none", cursor: "pointer", display: "flex", alignItems: "center", gap: "10px", fontSize: "14px", color: "#ef4444", borderRadius: "4px", margin: "2px 4px" }}
                                    onClick={() => handleDelete(item.mapId)}
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
                        <td colSpan="7" style={{ textAlign: "center", padding: "60px 20px", color: "#64748b", fontSize: "14px" }}>
                          {loading ? "Loading department mappings..." : "No mapping records found. Click the button above to add a mapping."}
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
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
      />
    </div>
  );
};

export default DepartmentMapping;
