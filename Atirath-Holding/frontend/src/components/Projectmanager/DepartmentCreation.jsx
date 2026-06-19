import { useState, useEffect } from "react";
import {
  ArrowLeft,
  Calendar,
  Building,
  FileText,
  CheckCircle2,
  X,
  RefreshCcw,
  Save,
  Plus,
  Search,
  Edit,
  Eye,
  Trash2,
  Menu,
  Bell,
  MoreVertical,
  ChevronRight,
  ChevronDown
} from "lucide-react";
import Sidebar from "../Sidebar";
import Header from "../Header";
import "../../styles/departmentCreation.css";

const DepartmentCreation = ({ userRole, onLogout }) => {
  // Local storage synchronization without initial dummy data
  const [departments, setDepartments] = useState(() => {
    const saved = localStorage.getItem("departments_user_data");
    return saved ? JSON.parse(saved) : [];
  });

  useEffect(() => {
    localStorage.setItem("departments_user_data", JSON.stringify(departments));
  }, [departments]);

  // Screen View: "form" or "list"
  const [view, setView] = useState("list");
  const [isEditing, setIsEditing] = useState(false);
  const [editingId, setEditingId] = useState(null);

  // Form State
  const [form, setForm] = useState({
    code: "",
    name: "",
    description: "",
    status: "Active"
  });

  // Filter States
  const [searchInputs, setSearchInputs] = useState({
    company: "",
    status: "",
    search: ""
  });
  const [activeFilters, setActiveFilters] = useState({
    company: "",
    status: "",
    search: ""
  });

  // UI States
  const [error, setError] = useState("");
  const [showModal, setShowModal] = useState(false);
  const [deleteId, setDeleteId] = useState(null);
  const [activeDropdown, setActiveDropdown] = useState(null);

  // Sorting
  const [sortConfig, setSortConfig] = useState({ key: null, direction: "asc" });

  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;

  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
    if (error) setError("");
  };

  const handleFilterChange = (e) => {
    const { name, value } = e.target;
    setSearchInputs((prev) => ({ ...prev, [name]: value }));
  };

  const handleReset = () => {
    setForm({ code: "", name: "", description: "", status: "Active" });
    setError("");
  };

  const handleSave = (e) => {
    if (e) e.preventDefault();

    if (!form.code.trim() || !form.name.trim()) {
      setError("Department code and name are required.");
      return;
    }

    const codeToCheck = form.code.trim().toUpperCase();

    const isDuplicate = departments.some(
      (dept) => dept.code.toUpperCase() === codeToCheck && (!isEditing || dept.id !== editingId)
    );

    if (isDuplicate) {
      setError("Department code already exists.");
      return;
    }

    if (isEditing) {
      setDepartments((prev) =>
        prev.map((dept) =>
          dept.id === editingId
            ? { ...dept, code: codeToCheck, name: form.name.trim(), description: form.description.trim(), status: form.status }
            : dept
        )
      );
      alert("Department updated successfully!");
    } else {
      const nextId = departments.length ? Math.max(...departments.map((d) => d.id)) + 1 : 1;
      const newDept = {
        id: nextId,
        code: codeToCheck,
        name: form.name.trim(),
        company: "Atirath Bio Energy Private Limited",
        head: "Admin User",
        employeesCount: 0,
        status: form.status,
        description: form.description.trim()
      };
      setDepartments((prev) => [...prev, newDept]);
      alert("Department created successfully!");
    }

    handleReset();
    setIsEditing(false);
    setEditingId(null);
    setView("list");
  };

  const resetFilters = () => {
    const cleared = { company: "", status: "", search: "" };
    setSearchInputs(cleared);
    setActiveFilters(cleared);
    setCurrentPage(1);
  };

  const applySearch = () => {
    setActiveFilters(searchInputs);
    setCurrentPage(1);
  };

  const handleEdit = (dept) => {
    setForm({ code: dept.code, name: dept.name, description: dept.description || "", status: dept.status });
    setIsEditing(true);
    setEditingId(dept.id);
    setActiveDropdown(null);
    setView("form");
  };

  const confirmDelete = (id) => {
    setDeleteId(id);
    setShowModal(true);
    setActiveDropdown(null);
  };

  const handleDelete = () => {
    setDepartments((current) => current.filter((item) => item.id !== deleteId));
    setShowModal(false);
    setDeleteId(null);
    alert("Department deactivated successfully!");
  };

  const toggleDropdown = (id) => {
    setActiveDropdown((prev) => (prev === id ? null : id));
  };

  const handleSort = (key) => {
    let direction = "asc";
    if (sortConfig.key === key && sortConfig.direction === "asc") { direction = "desc"; }
    setSortConfig({ key, direction });
  };

  const filteredDepartments = departments.filter((dept) => {
    const matchesCompany = activeFilters.company ? dept.company.toLowerCase().includes(activeFilters.company.toLowerCase()) : true;
    const matchesStatus = activeFilters.status ? dept.status === activeFilters.status : true;
    const matchesSearch = activeFilters.search ? dept.code.toLowerCase().includes(activeFilters.search.toLowerCase()) || dept.name.toLowerCase().includes(activeFilters.search.toLowerCase()) : true;
    return matchesCompany && matchesStatus && matchesSearch;
  });

  const sortedDepartments = [...filteredDepartments].sort((a, b) => {
    if (!sortConfig.key) return 0;
    const aValue = a[sortConfig.key];
    const bValue = b[sortConfig.key];
    if (aValue < bValue) return sortConfig.direction === "asc" ? -1 : 1;
    if (aValue > bValue) return sortConfig.direction === "asc" ? 1 : -1;
    return 0;
  });

  const totalItems = sortedDepartments.length;
  const totalPages = Math.ceil(totalItems / itemsPerPage);
  const indexOfLastItem = currentPage * itemsPerPage;
  const indexOfFirstItem = indexOfLastItem - itemsPerPage;
  const currentItems = sortedDepartments.slice(indexOfFirstItem, indexOfLastItem);

  return (
    <div className="dept-shell-container">
      <Sidebar userRole={userRole} onLogout={onLogout} />

      <div className="dept-shell">
        <Header 
          title="Department Master" 
          showSearch={false} 
          userName="Syed Mohammad Johny Basha" 
          userRole="Web Developer" 
          initials="SB" 
        />

        <main className="dept-main" style={{ padding: '24px' }}>
          {view === "form" ? (
            <div className="dept-content" style={{ paddingBottom: '80px', maxWidth: '1280px', margin: '0 auto' }}>
              <div className="dept-form-card" style={{ backgroundColor: 'white', borderRadius: '8px', border: '1px solid #e2e8f0', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '20px 24px', borderBottom: '1px solid #e2e8f0', backgroundColor: '#fafbfc' }}>
                  <h2 style={{ fontSize: '20px', fontWeight: '700', color: '#0f172a', margin: 0 }}>
                    {isEditing ? "Edit Department" : "Add New Department"}
                  </h2>
                  <button type="button" className="dept-nav-view-btn" onClick={() => { handleReset(); setIsEditing(false); setView("list"); }}>
                    <ArrowLeft size={15} /> Back to Department List
                  </button>
                </div>

                <div style={{ padding: '24px' }}>
                  {error && <div className="dept-form-error" style={{ color: '#dc2626', marginBottom: '20px', padding: '12px 16px', backgroundColor: '#fef2f2', borderLeft: '4px solid #dc2626', borderRadius: '6px', fontWeight: '500' }}>{error}</div>}
                  <div className="dept-form-section">
                    <div className="dept-form-item">
                      <label>Department Code <span className="dept-req-star">*</span></label>
                      <div className="dept-input-icon-wrap">
                        <span className="dept-input-prefix-icon"><Calendar size={16} /></span>
                        <input type="text" name="code" value={form.code} onChange={handleChange} placeholder="Enter department code" disabled={isEditing} required />
                      </div>
                      <div className="dept-input-helper-text" style={{ color: '#64748b', fontSize: '12px', marginTop: '4px' }}>Department code must be unique.</div>
                    </div>
                    <div className="dept-form-item">
                      <label>Department Name <span className="dept-req-star">*</span></label>
                      <div className="dept-input-icon-wrap">
                        <span className="dept-input-prefix-icon"><Building size={16} /></span>
                        <input type="text" name="name" value={form.name} onChange={handleChange} placeholder="Enter department name" required />
                      </div>
                    </div>
                    <div className="dept-form-item">
                      <label>Description (Optional)</label>
                      <div className="dept-input-icon-wrap">
                        <span className="dept-input-prefix-icon"><FileText size={16} /></span>
                        <textarea name="description" value={form.description} onChange={handleChange} placeholder="Enter description (optional)" rows={4} />
                      </div>
                    </div>
                    <div className="dept-form-item">
                      <label>Status <span className="dept-req-star">*</span></label>
                      <div className="dept-radio-group">
                        <label className="dept-radio-label">
                          <input type="radio" name="status" value="Active" checked={form.status === "Active"} onChange={handleChange} />
                          <span className="dept-radio-circle"></span>
                          <span>Active</span>
                        </label>
                        <label className="dept-radio-label">
                          <input type="radio" name="status" value="Inactive" checked={form.status === "Inactive"} onChange={handleChange} />
                          <span className="dept-radio-circle"></span>
                          <span>Inactive</span>
                        </label>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="dept-form-footer" style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', padding: '16px 24px', backgroundColor: '#fafbfc', borderTop: '1px solid #e2e8f0' }}>
                  <button type="button" className="dept-btn secondary" onClick={() => { handleReset(); setIsEditing(false); setView("list"); }}>Cancel</button>
                  <button type="button" className="dept-btn tertiary" onClick={handleReset}><RefreshCcw size={14} /> Reset</button>
                  <button type="button" className="dept-btn primary" onClick={handleSave}><Save size={14} /> {isEditing ? "Update Department" : "Save Department"}</button>
                </div>
              </div>
            </div>
          ) : (
            <div className="dept-content" style={{ maxWidth: '1280px', margin: '0 auto' }}>
              <div className="dept-table-panel" style={{ backgroundColor: 'white', borderRadius: '8px', border: '1px solid #e2e8f0', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '20px 24px', borderBottom: '1px solid #e2e8f0' }}>
                  <div>
                    <h2 style={{ fontSize: '18px', fontWeight: '700', color: '#0f172a', margin: 0 }}>Department List</h2>
                    <p style={{ color: '#64748b', margin: '4px 0 0 0', fontSize: '14px' }}>View and manage all departments</p>
                  </div>
                  <button type="button" className="dept-btn-add-new" onClick={() => { handleReset(); setIsEditing(false); setView("form"); }}>
                    <Plus size={16} /> Add New Department
                  </button>
                </div>

                <div style={{ display: 'flex', alignItems: 'flex-end', gap: '16px', flexWrap: 'wrap', padding: '20px 24px', borderBottom: '1px solid #e2e8f0', backgroundColor: '#fafbfc' }}>
                  <div style={{ flex: 1, minWidth: '180px' }}>
                    <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', fontWeight: '600', color: '#475569' }}>Company</label>
                    <select name="company" value={searchInputs.company} onChange={handleFilterChange} style={{ width: '100%', padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '6px', fontSize: '14px', backgroundColor: 'white', boxSizing: 'border-box', outline: 'none', cursor: 'pointer', height: '40px' }}>
                      <option value="">Select company</option>
                      <option value="Atirath Holdings India Limited">Atirath Holdings India Limited</option>
                      <option value="Atirath Bio Energy Private Limited">Atirath Bio Energy Private Limited</option>
                      <option value="Exclusive Traders">Exclusive Traders</option>
                    </select>
                  </div>
                  <div style={{ flex: 1, minWidth: '150px' }}>
                    <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', fontWeight: '600', color: '#475569' }}>Status</label>
                    <select name="status" value={searchInputs.status} onChange={handleFilterChange} style={{ width: '100%', padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '6px', fontSize: '14px', backgroundColor: 'white', boxSizing: 'border-box', outline: 'none', cursor: 'pointer', height: '40px' }}>
                      <option value="">Select status</option>
                      <option value="Active">Active</option>
                      <option value="Inactive">Inactive</option>
                    </select>
                  </div>
                  <div style={{ flex: 1, minWidth: '200px' }}>
                    <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', fontWeight: '600', color: '#475569' }}>Search</label>
                    <div style={{ position: 'relative' }}>
                      <Search size={16} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }} />
                      <input type="text" name="search" value={searchInputs.search} onChange={handleFilterChange} placeholder="Search by code or name..." style={{ width: '100%', padding: '8px 12px 8px 36px', border: '1px solid #cbd5e1', borderRadius: '6px', fontSize: '14px', boxSizing: 'border-box', outline: 'none', height: '40px' }} />
                    </div>
                  </div>
                  <div style={{ display: 'flex', gap: '10px', height: '40px' }}>
                    <button type="button" className="dept-filter-btn search" onClick={applySearch}><Search size={15} /> Search</button>
                    <button type="button" className="dept-filter-btn reset" onClick={resetFilters}><RefreshCcw size={15} /> Reset</button>
                  </div>
                </div>

                <div className="dept-table-container" style={{ overflowX: 'auto' }}>
                  <table className="dept-list-table" style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', minWidth: '900px' }}>
                    <thead style={{ backgroundColor: '#f8fafc', borderBottom: '2px solid #e2e8f0' }}>
                      <tr>
                        <th style={{ width: "50px", padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>#</th>
                        <th className="sortable" onClick={() => handleSort("code")} style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', cursor: 'pointer', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Department Code {sortConfig.key === "code" && (sortConfig.direction === "asc" ? "▲" : "▼")}</th>
                        <th className="sortable" onClick={() => handleSort("name")} style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', cursor: 'pointer', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Department Name {sortConfig.key === "name" && (sortConfig.direction === "asc" ? "▲" : "▼")}</th>
                        <th className="sortable" onClick={() => handleSort("company")} style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', cursor: 'pointer', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Company {sortConfig.key === "company" && (sortConfig.direction === "asc" ? "▲" : "▼")}</th>
                        <th className="sortable" onClick={() => handleSort("head")} style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', cursor: 'pointer', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Head of Department {sortConfig.key === "head" && (sortConfig.direction === "asc" ? "▲" : "▼")}</th>
                        <th className="sortable" onClick={() => handleSort("employeesCount")} style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textAlign: 'center', cursor: 'pointer', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Employees {sortConfig.key === "employeesCount" && (sortConfig.direction === "asc" ? "▲" : "▼")}</th>
                        <th className="sortable" onClick={() => handleSort("status")} style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', cursor: 'pointer', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Status {sortConfig.key === "status" && (sortConfig.direction === "asc" ? "▲" : "▼")}</th>
                        <th style={{ textAlign: "center", width: "100px", padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>ACTIONS</th>
                      </tr>
                    </thead>
                    <tbody>
                      {currentItems.length > 0 ? (
                        currentItems.map((dept, index) => (
                          <tr key={dept.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{indexOfFirstItem + index + 1}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}><span style={{ backgroundColor: '#f1f5f9', padding: '4px 10px', borderRadius: '4px', fontWeight: '600', color: '#0f172a', border: '1px solid #e2e8f0', fontSize: '13px' }}>{dept.code}</span></td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}><strong>{dept.name}</strong></td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{dept.company}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{dept.head}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155', textAlign: 'center' }}><span style={{ backgroundColor: '#eff6ff', padding: '4px 10px', borderRadius: '12px', fontWeight: '600', color: '#2563eb', fontSize: '13px' }}>{dept.employeesCount}</span></td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}><span style={{ padding: '4px 12px', borderRadius: '12px', fontSize: '12px', fontWeight: '600', display: 'inline-block', backgroundColor: dept.status === 'Active' ? '#dcfce7' : '#fee2e2', color: dept.status === 'Active' ? '#166534' : '#991b1b' }}>{dept.status}</span></td>
                            <td style={{ position: "relative", padding: '14px 16px', textAlign: 'center' }}>
                              <button type="button" style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#64748b', padding: '4px 8px', borderRadius: '4px' }} onClick={() => toggleDropdown(dept.id)} onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f1f5f9'} onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}>
                                <MoreVertical size={18} />
                              </button>
                              {activeDropdown === dept.id && (
                                <>
                                  <div className="dept-actions-dropdown-backdrop" onClick={() => setActiveDropdown(null)} style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, zIndex: 9 }} />
                                  <div className="dept-actions-dropdown-menu" style={{ position: 'absolute', right: '30px', top: '8px', backgroundColor: 'white', border: '1px solid #e2e8f0', borderRadius: '8px', boxShadow: '0 4px 12px rgba(0,0,0,0.15)', zIndex: 10, display: 'flex', flexDirection: 'column', padding: '4px 0', minWidth: '140px' }}>
                                    <button type="button" style={{ padding: '10px 16px', textAlign: 'left', background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px', color: '#334155', borderRadius: '4px', margin: '2px 4px' }} onClick={() => { alert(`Department Info:\nCode: ${dept.code}\nName: ${dept.name}\nCompany: ${dept.company}\nDescription: ${dept.description}`); setActiveDropdown(null); }} onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f1f5f9'} onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}> <Eye size={15} /> View </button>
                                    <button type="button" style={{ padding: '10px 16px', textAlign: 'left', background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px', color: '#334155', borderRadius: '4px', margin: '2px 4px' }} onClick={() => handleEdit(dept)} onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f1f5f9'} onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}> <Edit size={15} /> Edit </button>
                                    <button type="button" style={{ padding: '10px 16px', textAlign: 'left', background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px', color: '#ef4444', borderRadius: '4px', margin: '2px 4px' }} onClick={() => confirmDelete(dept.id)} onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#fef2f2'} onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}> <Trash2 size={15} /> Deactivate </button>
                                  </div>
                                </>
                              )}
                            </td>
                          </tr>
                        ))
                      ) : (
                        <tr><td colSpan={8} style={{ textAlign: "center", padding: "60px 20px", color: '#64748b', fontSize: '14px' }}>No department records found. Add a new department using the button above.</td></tr>
                      )}
                    </tbody>
                  </table>
                </div>

                {totalPages > 0 && (
                  <div className="dept-table-pagination-bar" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '14px 24px', borderTop: '1px solid #e2e8f0', backgroundColor: '#fafbfc' }}>
                    <span className="dept-pagination-info" style={{ fontSize: '14px', color: '#64748b' }}>Showing {totalItems > 0 ? indexOfFirstItem + 1 : 0} to {Math.min(indexOfLastItem, totalItems)} of {totalItems} records</span>
                    <div className="dept-pagination-controls" style={{ display: 'flex', gap: '4px' }}>
                      <button className="dept-pag-btn" onClick={() => setCurrentPage(1)} disabled={currentPage === 1} style={{ padding: '6px 10px', border: '1px solid #cbd5e1', backgroundColor: 'white', borderRadius: '4px', cursor: currentPage === 1 ? 'not-allowed' : 'pointer', color: currentPage === 1 ? '#94a3b8' : '#334155' }}>«</button>
                      <button className="dept-pag-btn" onClick={() => setCurrentPage((c) => Math.max(c - 1, 1))} disabled={currentPage === 1} style={{ padding: '6px 10px', border: '1px solid #cbd5e1', backgroundColor: 'white', borderRadius: '4px', cursor: currentPage === 1 ? 'not-allowed' : 'pointer', color: currentPage === 1 ? '#94a3b8' : '#334155' }}>‹</button>
                      {Array.from({ length: totalPages }, (_, i) => i + 1).map((p) => (
                        <button key={p} className={`dept-pag-btn ${currentPage === p ? 'active' : ''}`} onClick={() => setCurrentPage(p)} style={{ padding: '6px 14px', border: '1px solid #cbd5e1', backgroundColor: currentPage === p ? '#2563eb' : 'white', color: currentPage === p ? 'white' : '#334155', borderRadius: '4px', cursor: 'pointer', fontSize: '14px', fontWeight: currentPage === p ? '600' : '400' }}>{p}</button>
                      ))}
                      <button className="dept-pag-btn" onClick={() => setCurrentPage((c) => Math.min(c + 1, totalPages))} disabled={currentPage === totalPages} style={{ padding: '6px 10px', border: '1px solid #cbd5e1', backgroundColor: 'white', borderRadius: '4px', cursor: currentPage === totalPages ? 'not-allowed' : 'pointer', color: currentPage === totalPages ? '#94a3b8' : '#334155' }}>›</button>
                      <button className="dept-pag-btn" onClick={() => setCurrentPage(totalPages)} disabled={currentPage === totalPages} style={{ padding: '6px 10px', border: '1px solid #cbd5e1', backgroundColor: 'white', borderRadius: '4px', cursor: currentPage === totalPages ? 'not-allowed' : 'pointer', color: currentPage === totalPages ? '#94a3b8' : '#334155' }}>»</button>
                    </div>
                  </div>
                )}
              </div>
            </div>
          )}
        </main>

        {showModal && (
          <div className="dept-modal-overlay" style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.5)', zIndex: 99, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <div className="dept-modal" style={{ backgroundColor: 'white', borderRadius: '8px', width: '400px', maxWidth: '90%', boxShadow: '0 10px 15px -3px rgba(0,0,0,0.1)' }}>
              <div className="dept-modal-header" style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 20px', borderBottom: '1px solid #e2e8f0' }}>
                <h3 style={{ margin: 0, fontSize: '16px', fontWeight: '700', color: '#1e293b' }}>Confirm Deactivation</h3>
                <button className="dept-modal-close" onClick={() => setShowModal(false)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#64748b' }}>
                  <X size={18} />
                </button>
              </div>
              <div className="dept-modal-body" style={{ padding: '20px' }}>
                <p style={{ margin: '0 0 8px 0', color: '#334155', fontSize: '14px' }}>Are you sure you want to deactivate this department?</p>
                <p className="dept-modal-warning" style={{ margin: 0, color: '#ef4444', fontSize: '13px', fontWeight: '500' }}>This operation cannot be undone!</p>
              </div>
              <div className="dept-modal-footer" style={{ padding: '16px 20px', borderTop: '1px solid #e2e8f0', display: 'flex', justifyContent: 'flex-end', gap: '10px', backgroundColor: '#f8fafc' }}>
                <button className="dept-btn-cancel-modal" onClick={() => setShowModal(false)} style={{ padding: '8px 16px', backgroundColor: 'white', border: '1px solid #cbd5e1', borderRadius: '6px', cursor: 'pointer', fontWeight: '500', color: '#475569' }}>Cancel</button>
                <button className="dept-btn-delete-modal" onClick={handleDelete} style={{ padding: '8px 16px', backgroundColor: '#ef4444', color: 'white', border: 'none', borderRadius: '6px', cursor: 'pointer', fontWeight: '500', display: 'flex', alignItems: 'center', gap: '6px' }}><Trash2 size={14} /> Deactivate</button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default DepartmentCreation;