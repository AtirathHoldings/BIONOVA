// src/pages/ProjectAccess.jsx
import React, { useState, useEffect } from 'react';
import {
  Search,
  Check,
  Folder,
  Users,
  Plus,
  X,
  Eye,
  Edit,
  Info,
  ChevronDown,
  ChevronRight,
  FileText,
  Minus,
  User,
  Building2,
  Settings,
  Shield,
  Lock,
  Unlock,
  Save,
  RotateCcw,
  ChevronLeft,
  UserPlus,
  UserMinus,
  RefreshCw,
  AlertCircle,
  CheckCircle2
} from 'lucide-react';
import Sidebar from '../Sidebar';
import Header from '../Header';
import AlertModal from '../AlertModal';
import '../../styles/ProjectAccess.css';

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;

const getAuthHeaders = () => {
  const token = sessionStorage.getItem("authToken") || localStorage.getItem("authToken");
  return {
    "Content-Type": "application/json",
    "Authorization": `Bearer ${token || ""}`
  };
};



// Access level definitions
const ACCESS_LEVELS = [
  { value: 'VIEWER', label: 'Viewer', icon: Eye, color: '#3b82f6', description: 'Can view project details and tasks' },
  { value: 'EDITOR', label: 'Editor', icon: Edit, color: '#f59e0b', description: 'Can edit tasks and update progress' },
  { value: 'MANAGER', label: 'Manager', icon: Users, color: '#8b5cf6', description: 'Can manage project and team' },
  { value: 'ADMIN', label: 'Admin', icon: Shield, color: '#ef4444', description: 'Full project control including access management' }
];


const ProjectAccess = ({ userRole, onLogout }) => {
  // ── State ──
  const [projects, setProjects] = useState([]);
  const [selectedProject, setSelectedProject] = useState(null);
  const [projectAccess, setProjectAccess] = useState([]);
  const [employees, setEmployees] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedEmployees, setSelectedEmployees] = useState([]);
  const [accessType, setAccessType] = useState('VIEWER');
  const [showAddModal, setShowAddModal] = useState(false);
  const [showProjectSelect, setShowProjectSelect] = useState(false);
  const [accessTemplates, setAccessTemplates] = useState([]);
  const [alertConfig, setAlertConfig] = useState({
    isOpen: false,
    type: 'info',
    title: '',
    message: ''
  });

  // ── Alert System ──
  const triggerAlert = (type, title, message) => {
    setAlertConfig({ isOpen: true, type, title, message });
  };

  // ── Fetch Data ──
  useEffect(() => {
    fetchProjects();
    fetchEmployees();
    fetchAccessTemplates();
  }, []);

  const fetchProjects = async () => {
    setLoading(true);
    try {
      const response = await fetch(`${apiBaseUrl}/api/projects/access`, {
        headers: getAuthHeaders()
      });
      if (response.ok) {
        const data = await response.json();
        setProjects(data);
      }
    } catch (err) {
      console.error('Error fetching projects:', err);
      triggerAlert('error', 'Error', 'Failed to load projects.');
    } finally {
      setLoading(false);
    }
  };

  const fetchProjectAccess = async (prjId) => {
    setLoading(true);
    try {
      const response = await fetch(`${apiBaseUrl}/api/projects/${prjId}/access`, {
        headers: getAuthHeaders()
      });
      if (response.ok) {
        const data = await response.json();
        setProjectAccess(data.accesses || []);
        setSelectedProject(data.project);
      }
    } catch (err) {
      console.error('Error fetching project access:', err);
      triggerAlert('error', 'Error', 'Failed to load project access.');
    } finally {
      setLoading(false);
    }
  };

  const fetchEmployees = async () => {
    try {
      const response = await fetch(`${apiBaseUrl}/api/employees`, {
        headers: getAuthHeaders()
      });
      if (response.ok) {
        const data = await response.json();
        setEmployees(data);
      }
    } catch (err) {
      console.error('Error fetching employees:', err);
    }
  };

  const fetchAccessTemplates = async () => {
    try {
      const response = await fetch(`${apiBaseUrl}/api/access-templates/project`, {
        headers: getAuthHeaders()
      });
      if (response.ok) {
        const data = await response.json();
        setAccessTemplates(data);
      }
    } catch (err) {
      console.error('Error fetching access templates:', err);
    }
  };

  // ── Project Selection ──
  const handleProjectSelect = (project) => {
    setSelectedProject(project);
    fetchProjectAccess(project.prjId);
    setShowProjectSelect(false);
  };

  // ── Grant Access ──
  const handleGrantAccess = async () => {
    if (selectedEmployees.length === 0) {
      triggerAlert('warning', 'Selection Required', 'Please select at least one employee.');
      return;
    }

    if (!selectedProject) {
      triggerAlert('warning', 'Project Required', 'Please select a project first.');
      return;
    }

    setLoading(true);
    try {
      // Get current user ID for audit
      const currentUser = sessionStorage.getItem("userName") || 'System';

      const response = await fetch(`${apiBaseUrl}/api/projects/${selectedProject.prjId}/access/bulk`, {
        method: 'POST',
        headers: getAuthHeaders(),
        body: JSON.stringify({
          employeeIds: selectedEmployees,
          accessType: accessType,
          performedBy: currentUser,
          remarks: `Access granted via Project Access Control`
        })
      });

      if (response.ok) {
        triggerAlert('success', 'Success', `Access granted to ${selectedEmployees.length} employee(s)`);
        setSelectedEmployees([]);
        // Refresh access list
        fetchProjectAccess(selectedProject.prjId);
        setShowAddModal(false);
      } else {
        const error = await response.json();
        triggerAlert('error', 'Error', error.error || 'Failed to grant access.');
      }
    } catch (err) {
      console.error('Error granting access:', err);
      triggerAlert('error', 'Error', 'Failed to grant access.');
    } finally {
      setLoading(false);
    }
  };

  // ── Revoke Access ──
  const handleRevokeAccess = async (empId, empName) => {
    if (!window.confirm(`Are you sure you want to revoke access for ${empName}?`)) {
      return;
    }

    setLoading(true);
    try {
      const currentUser = sessionStorage.getItem("userName") || 'System';
      
      const response = await fetch(`${apiBaseUrl}/api/projects/${selectedProject.prjId}/access/${empId}`, {
        method: 'DELETE',
        headers: getAuthHeaders(),
        body: JSON.stringify({
          performedBy: currentUser,
          remarks: `Access revoked by ${currentUser}`
        })
      });

      if (response.ok) {
        triggerAlert('success', 'Success', `Access revoked for ${empName}`);
        fetchProjectAccess(selectedProject.prjId);
      } else {
        const error = await response.json();
        triggerAlert('error', 'Error', error.error || 'Failed to revoke access.');
      }
    } catch (err) {
      console.error('Error revoking access:', err);
      triggerAlert('error', 'Error', 'Failed to revoke access.');
    } finally {
      setLoading(false);
    }
  };

  // ── Update Access Type ──
  const handleUpdateAccessType = async (empId, empName, newAccessType) => {
    setLoading(true);
    try {
      const currentUser = sessionStorage.getItem("userName") || 'System';
      
      const response = await fetch(`${apiBaseUrl}/api/projects/${selectedProject.prjId}/access`, {
        method: 'POST',
        headers: getAuthHeaders(),
        body: JSON.stringify({
          empId: empId,
          accessType: newAccessType,
          performedBy: currentUser,
          remarks: `Access type updated to ${newAccessType}`
        })
      });

      if (response.ok) {
        triggerAlert('success', 'Success', `Access type updated for ${empName}`);
        fetchProjectAccess(selectedProject.prjId);
      } else {
        const error = await response.json();
        triggerAlert('error', 'Error', error.error || 'Failed to update access type.');
      }
    } catch (err) {
      console.error('Error updating access type:', err);
      triggerAlert('error', 'Error', 'Failed to update access type.');
    } finally {
      setLoading(false);
    }
  };

  // ── Filtered Employees ──
  const filteredEmployees = employees.filter(emp => {
    const search = searchTerm.toLowerCase();
    const name = `${emp.fstNm || emp.firstName || ''} ${emp.lstNm || emp.lastName || ''}`.toLowerCase();
    const code = (emp.empCode || emp.employeeCode || '').toLowerCase();
    const email = (emp.email || '').toLowerCase();
    return name.includes(search) || code.includes(search) || email.includes(search);
  });

  // ── Get Access Level Info ──
  const getAccessLevelInfo = (accessType) => {
    const level = ACCESS_LEVELS.find(l => l.value === accessType);
    return level || ACCESS_LEVELS[0];
  };

  // ── Get Access Badge Color ──
  const getAccessBadgeColor = (accessType) => {
    switch(accessType) {
      case 'ADMIN': return 'red';
      case 'MANAGER': return 'purple';
      case 'EDITOR': return 'orange';
      case 'VIEWER': return 'blue';
      default: return 'gray';
    }
  };

  // ── Render Project Selector ──
  const renderProjectSelector = () => (
    <div className="pa-project-selector">
      <div className="pa-project-selector-header">
        <h3>Select Project</h3>
        <button 
          className="pa-btn-outline" 
          onClick={() => setShowProjectSelect(!showProjectSelect)}
        >
          {selectedProject ? 'Change Project' : 'Browse Projects'}
        </button>
      </div>

      {selectedProject ? (
        <div className="pa-selected-project">
          <div className="pa-project-info">
            <Folder size={24} className="pa-project-icon" />
            <div>
              <div className="pa-project-name">{selectedProject.prjNm}</div>
              <div className="pa-project-code">{selectedProject.prjCd}</div>
              <div className="pa-project-meta">
                <span>Status: {selectedProject.prjSts}</span>
                <span>•</span>
                <span>{selectedProject.stDt} to {selectedProject.endDt}</span>
              </div>
            </div>
          </div>
          <div className="pa-project-access-count">
            {projectAccess.filter(a => a.sts !== false).length} users have access
          </div>
        </div>
      ) : (
        <div className="pa-no-project">
          <p>No project selected. Click "Browse Projects" to select one.</p>
        </div>
      )}

      {showProjectSelect && (
        <div className="pa-project-list">
          <div className="pa-search-bar">
            <Search size={16} />
            <input 
              type="text" 
              placeholder="Search projects..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <div className="pa-project-items">
            {projects.filter(p => 
              p.prjNm?.toLowerCase().includes(searchTerm.toLowerCase()) ||
              p.prjCd?.toLowerCase().includes(searchTerm.toLowerCase())
            ).map(project => (
              <div 
                key={project.prjId} 
                className={`pa-project-item ${selectedProject?.prjId === project.prjId ? 'selected' : ''}`}
                onClick={() => handleProjectSelect(project)}
              >
                <div className="pa-project-item-info">
                  <span className="pa-project-item-code">{project.prjCd}</span>
                  <span className="pa-project-item-name">{project.prjNm}</span>
                </div>
                {project.has_access && (
                  <span className={`pa-badge pa-badge-${getAccessBadgeColor(project.access_type)}`}>
                    {project.access_type}
                  </span>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );

  // ── Render Access List ──
  const renderAccessList = () => {
    const activeAccess = projectAccess.filter(a => a.sts !== false);

    if (!selectedProject) {
      return (
        <div className="pa-empty-state">
          <Folder size={48} />
          <h3>No Project Selected</h3>
          <p>Please select a project to manage access.</p>
        </div>
      );
    }

    return (
      <div className="pa-access-list-container">
        <div className="pa-access-list-header">
          <h3>Project Access</h3>
          <div className="pa-access-actions">
            <span className="pa-access-count">
              {activeAccess.length} user(s) have access
            </span>
            <button 
              className="pa-btn-primary"
              onClick={() => setShowAddModal(true)}
            >
              <UserPlus size={16} /> Add Access
            </button>
          </div>
        </div>

        <div className="pa-table-container">
          {activeAccess.length === 0 ? (
            <div className="pa-empty-state pa-empty-small">
              <p>No users have access to this project yet.</p>
              <button 
                className="pa-btn-primary pa-btn-sm"
                onClick={() => setShowAddModal(true)}
              >
                <Plus size={14} /> Add First User
              </button>
            </div>
          ) : (
            <table className="pa-table">
              <thead>
                <tr>
                  <th>Employee</th>
                  <th>Code</th>
                  <th>Email</th>
                  <th>Access Level</th>
                  <th>Granted On</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {activeAccess.map((access) => {
                  const emp = access.employee || {};
                  const name = emp.name || 'Unknown';
                  const accessInfo = getAccessLevelInfo(access.access_type);
                  const AccessIcon = accessInfo.icon;

                  return (
                    <tr key={access.pac_id || access.emp_id}>
                      <td>
                        <div className="pa-employee-info">
                          <div className="pa-employee-avatar">
                            {name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)}
                          </div>
                          <span className="pa-employee-name">{name}</span>
                        </div>
                      </td>
                      <td>{emp.code || '-'}</td>
                      <td>{emp.email || '-'}</td>
                      <td>
                        <div className="pa-access-level">
                          <select 
                            className={`pa-access-select pa-access-${getAccessBadgeColor(access.access_type)}`}
                            value={access.access_type}
                            onChange={(e) => {
                              if (e.target.value !== access.access_type) {
                                handleUpdateAccessType(access.emp_id, name, e.target.value);
                              }
                            }}
                          >
                            {ACCESS_LEVELS.map(level => (
                              <option key={level.value} value={level.value}>
                                {level.label}
                              </option>
                            ))}
                          </select>
                        </div>
                      </td>
                      <td>
                        {access.granted_at ? new Date(access.granted_at).toLocaleDateString() : '-'}
                      </td>
                      <td>
                        <button 
                          className="pa-btn-danger-sm"
                          onClick={() => handleRevokeAccess(access.emp_id, name)}
                        >
                          <UserMinus size={14} /> Revoke
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>
      </div>
    );
  };

  // ── Render Add Access Modal ──
  const renderAddAccessModal = () => {
    if (!showAddModal) return null;

    const filteredAvailable = filteredEmployees.filter(emp => 
      !projectAccess.some(a => a.emp_id === (emp.empId || emp.id) && a.sts !== false)
    );

    return (
      <div className="pa-modal-overlay" onClick={() => setShowAddModal(false)}>
        <div className="pa-modal" onClick={(e) => e.stopPropagation()}>
          <div className="pa-modal-header">
            <h3>Add Project Access</h3>
            <button className="pa-modal-close" onClick={() => setShowAddModal(false)}>
              <X size={18} />
            </button>
          </div>
          <div className="pa-modal-body">
            <div className="pa-form-group">
              <label>Project</label>
              <div className="pa-form-value">{selectedProject?.prjNm} ({selectedProject?.prjCd})</div>
            </div>

            <div className="pa-form-group">
              <label>Access Level</label>
              <select 
                className="pa-form-select"
                value={accessType}
                onChange={(e) => setAccessType(e.target.value)}
              >
                {ACCESS_LEVELS.map(level => (
                  <option key={level.value} value={level.value}>
                    {level.label} - {level.description}
                  </option>
                ))}
              </select>
            </div>

            <div className="pa-form-group">
              <label>Select Employees</label>
              <div className="pa-search-bar">
                <Search size={16} />
                <input 
                  type="text" 
                  placeholder="Search employees..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
              </div>
              <div className="pa-employee-list">
                {filteredAvailable.length === 0 ? (
                  <div className="pa-empty-small">No employees available to add.</div>
                ) : (
                  filteredAvailable.map(emp => {
                    const empId = emp.empId || emp.id;
                    const name = `${emp.fstNm || emp.firstName || ''} ${emp.lstNm || emp.lastName || ''}`.trim();
                    const code = emp.empCode || emp.employeeCode || '';
                    const isSelected = selectedEmployees.includes(empId);

                    return (
                      <div 
                        key={empId} 
                        className={`pa-employee-item ${isSelected ? 'selected' : ''}`}
                        onClick={() => {
                          setSelectedEmployees(prev => 
                            prev.includes(empId) 
                              ? prev.filter(id => id !== empId) 
                              : [...prev, empId]
                          );
                        }}
                      >
                        <input 
                          type="checkbox" 
                          className="pa-checkbox"
                          checked={isSelected}
                          onChange={() => {}}
                          onClick={(e) => e.stopPropagation()}
                        />
                        <div className="pa-employee-avatar">
                          {name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)}
                        </div>
                        <div className="pa-employee-info">
                          <div className="pa-employee-name">{code ? `${code} - ${name}` : name}</div>
                          <div className="pa-employee-details">{emp.designation || 'Employee'}</div>
                        </div>
                      </div>
                    );
                  })
                )}
              </div>
            </div>

            <div className="pa-selection-summary">
              Selected: <strong>{selectedEmployees.length}</strong> employee(s)
            </div>
          </div>
          <div className="pa-modal-footer">
            <button className="pa-btn-outline" onClick={() => setShowAddModal(false)}>
              Cancel
            </button>
            <button 
              className="pa-btn-primary" 
              onClick={handleGrantAccess} 
              disabled={loading || selectedEmployees.length === 0}
            >
              {loading ? 'Granting...' : (
                <>
                  <Lock size={16} /> Grant Access
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    );
  };

  // ── Main Render ──
  return (
    <div className="cc-shell-container">
      <Sidebar userRole={userRole} onLogout={onLogout} />
      
      <div className="cc-shell">
        <Header 
          title="Project Access Control" 
          subtitle="Manage user access to projects"
          onLogout={onLogout}
          userRole={userRole}
        />

        <main className="cc-main">
          <div className="pa-container">
            {/* Project Selector */}
            {renderProjectSelector()}

            {/* Access List */}
            <div className="pa-access-section">
              {renderAccessList()}
            </div>
          </div>
        </main>
      </div>

      {/* Add Access Modal */}
      {renderAddAccessModal()}

      {/* Alert Modal */}
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

export default ProjectAccess;