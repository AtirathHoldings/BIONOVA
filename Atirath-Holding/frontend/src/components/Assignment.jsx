import React, { useState, useRef, useEffect } from 'react';
import Sidebar from './Sidebar';
import Header from './Header';
import {
  Lock, Calendar as CalendarIcon, Flag, ChevronDown,
  Edit3, Trash2, Plus, Info, UploadCloud, Save, Eye, X, Check, ChevronLeft
} from 'lucide-react';
import '../styles/Assignment.css';
import '../styles/CompanyMaster.css';
import AlertModal from './AlertModal';

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;

const getAuthHeaders = () => ({
  "Content-Type": "application/json",
  "Authorization": `Bearer ${sessionStorage.getItem("authToken") || ""}`
});

const SearchableSelect = ({ options, value, onChange, placeholder, name, style, disabled }) => {
  const [isOpen, setIsOpen] = useState(false);
  const [search, setSearch] = useState("");
  const wrapperRef = React.useRef(null);

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (wrapperRef.current && !wrapperRef.current.contains(e.target)) setIsOpen(false);
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const filtered = options.filter(o => o.label.toLowerCase().includes(search.toLowerCase()));
  const selected = options.find(o => String(o.value) === String(value));

  return (
    <div ref={wrapperRef} style={{ position: 'relative', width: '100%', margin: 0 }}>
      <div
        onClick={() => !disabled && setIsOpen(!isOpen)}
        style={{
          padding: '10px 12px',
          border: '1px solid #cbd5e1',
          borderRadius: '6px',
          backgroundColor: disabled ? '#f1f5f9' : 'white',
          cursor: disabled ? 'not-allowed' : 'pointer',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          fontSize: '14px',
          height: '42px',
          ...style
        }}
      >
        <span style={{ color: selected ? '#0f172a' : '#94a3b8', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
          {selected ? selected.label : placeholder}
        </span>
        <ChevronDown size={14} style={{ color: '#64748b', flexShrink: 0, marginLeft: 8 }} />
      </div>
      {isOpen && (
        <div style={{
          position: 'absolute', top: '100%', left: 0, right: 0, marginTop: '4px',
          backgroundColor: 'white', border: '1px solid #cbd5e1', borderRadius: '6px',
          boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)', zIndex: 1000
        }}>
          <div style={{ padding: '8px' }}>
            <input
              type="text" value={search} onChange={(e) => setSearch(e.target.value)}
              placeholder="Search..."
              style={{ width: '100%', padding: '8px', border: '1px solid #e2e8f0', borderRadius: '4px', outline: 'none', fontSize: '14px', boxSizing: 'border-box' }}
              onClick={(e) => e.stopPropagation()}
            />
          </div>
          <div style={{ maxHeight: '200px', overflowY: 'auto' }}>
            {filtered.length > 0 ? (
              filtered.map(opt => (
                <div
                  key={opt.value}
                  onClick={() => {
                    onChange({ target: { name, value: opt.value } });
                    setIsOpen(false);
                    setSearch("");
                  }}
                  style={{ padding: '10px 12px', cursor: 'pointer', backgroundColor: String(value) === String(opt.value) ? '#f1f5f9' : 'transparent', fontSize: '14px' }}
                  onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f8fafc'}
                  onMouseLeave={(e) => e.currentTarget.style.backgroundColor = String(value) === String(opt.value) ? '#f1f5f9' : 'transparent'}
                >
                  {opt.label}
                </div>
              ))
            ) : (
              <div style={{ padding: '10px 12px', color: '#64748b', fontSize: '14px', textAlign: 'center' }}>No results found</div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

const Assignment = ({ userRole, onLogout }) => {
  // --- STATE FOR FORM FIELDS ---
  const [taskCode, setTaskCode] = useState("");
  const [taskTitle, setTaskTitle] = useState("");
  const [priority, setPriority] = useState("High");
  const [status, setStatus] = useState("Draft");
  const [duration, setDuration] = useState("");
  const [startDate, setStartDate] = useState("");
  const [dueDate, setDueDate] = useState("");
  const [dateError, setDateError] = useState("");
  const [description, setDescription] = useState("Prepare and submit the monthly compliance report with all required documents and signatures before the due date.");

  const [assignedEmployee, setAssignedEmployee] = useState("");

  const [enableWorkflow, setEnableWorkflow] = useState(true);
  const [reviewer, setReviewer] = useState("");
  const [approver, setApprover] = useState("");

  const [employees, setEmployees] = useState([]);
  const [companies, setCompanies] = useState([]);
  const [designations, setDesignations] = useState([]);
  const [currentUser, setCurrentUser] = useState(null);
  const [tasks, setTasks] = useState([]);
  const [view, setView] = useState("list");
  const [editId, setEditId] = useState(null);

  const [alertConfig, setAlertConfig] = useState({ isOpen: false, type: 'info', title: '', message: '' });
  const triggerAlert = (type, title, message) => {
    setAlertConfig({ isOpen: true, type, title, message });
  };

  const fetchAllData = async () => {
    try {
      const profileRes = await fetch(`${apiBaseUrl}/api/profile`, { headers: getAuthHeaders() });
      if (profileRes.ok) setCurrentUser(await profileRes.json());

      const [empRes, coyRes, desigRes, pltRes] = await Promise.all([
        fetch(`${apiBaseUrl}/api/employees`, { headers: getAuthHeaders() }),
        fetch(`${apiBaseUrl}/api/companies`, { headers: getAuthHeaders() }),
        fetch(`${apiBaseUrl}/api/designations`, { headers: getAuthHeaders() }),
        fetch(`${apiBaseUrl}/api/plants`, { headers: getAuthHeaders() })
      ]);

      const empData = empRes.ok ? await empRes.json() : [];
      const coyData = coyRes.ok ? await coyRes.json() : [];
      const desigData = desigRes.ok ? await desigRes.json() : [];
      const pltData = pltRes.ok ? await pltRes.json() : [];

      setCompanies(coyData);
      setDesignations(desigData);

      const mappedEmps = empData.map(emp => {
        const coyNm = coyData.find(c => String(c.coyId || c.id) === String(emp.coyId))?.coyNm || emp.company;
        const pltNm = pltData.find(p => String(p.pltId || p.id) === String(emp.pltId))?.pltNm || emp.plant;
        const orgInfo = coyNm ? coyNm : (pltNm ? pltNm : "N/A");

        let desigNm = emp.designation || emp.role;
        if (!desigNm) {
          const desigObj = desigData.find(d => String(d.desigId || d.id) === String(emp.desigId));
          desigNm = desigObj?.desigNm || (emp.desigId ? `Designation ${emp.desigId}` : "N/A");
        }
        return {
          ...emp,
          displayLabel: `${emp.fstNm || emp.firstName} ${emp.lstNm || emp.lastName} - ${desigNm} - ${orgInfo}`
        };
      });
      setEmployees(mappedEmps);

      const tasksRes = await fetch(`${apiBaseUrl}/api/individual-tasks`, { headers: getAuthHeaders() });
      if (tasksRes.ok) {
        const rawTasks = await tasksRes.json();
        const enrichedTasks = await Promise.all(rawTasks.map(async (task) => {
          let reviewerName = "N/A";
          let approverName = "N/A";
          if (task.prcsFlg) {
            try {
              const pcRes = await fetch(`${apiBaseUrl}/api/process-config/draft-task/${task.empTaskId || task.id}`, { headers: getAuthHeaders() });
              if (pcRes.ok) {
                const pcs = await pcRes.json();
                const rev = pcs.find(p => p.stepType === 'REVIEWER');
                if (rev && rev.empId) {
                  const emp = mappedEmps.find(e => String(e.empId || e.id) === String(rev.empId));
                  if (emp) reviewerName = `${emp.fstNm || emp.firstName} ${emp.lstNm || emp.lastName}`;
                }
                const app = pcs.find(p => p.stepType === 'APPROVER');
                if (app && app.empId) {
                  const emp = mappedEmps.find(e => String(e.empId || e.id) === String(app.empId));
                  if (emp) approverName = `${emp.fstNm || emp.firstName} ${emp.lstNm || emp.lastName}`;
                }
              }
            } catch (err) {
              console.error("Failed to fetch process config for task", task.taskCd);
            }
          }
          return { ...task, reviewerName, approverName };
        }));
        setTasks(enrichedTasks);
      }
    } catch (err) {
      console.error("Error fetching data", err);
    }
  };

  React.useEffect(() => {
    fetchAllData();
  }, []);

  const [showQuickAddReviewer, setShowQuickAddReviewer] = useState(false);
  const [showQuickAddApprover, setShowQuickAddApprover] = useState(false);

  const QuickAddBox = ({ role, onClose, onSuccess }) => {
    const [formData, setFormData] = useState({ name: '', designation: '', company: '' });
    const [loading, setLoading] = useState(false);

    const handleSave = async () => {
      if (!formData.name || !formData.designation || !formData.company) {
        triggerAlert("error", "Error", "Please fill all fields");
        return;
      }
      setLoading(true);
      try {
        const nameParts = formData.name.trim().split(" ");
        const fstNm = nameParts[0];
        const lstNm = nameParts.slice(1).join(" ") || " ";

        const payload = {
          empCode: `TMP-${Math.floor(Math.random() * 10000)}`,
          fstNm: fstNm,
          lstNm: lstNm,
          email: `${fstNm.toLowerCase()}@example.com`,
          gender: "MALE",
          mobNum: "9999999999",
          empTyp: "FTE",
          designation: formData.designation,
          sts: true,
          coyId: parseInt(formData.company),
          pltId: 1,
          deptId: 1,
          wLoc: "HQ",
          role: "user"
        };
        const res = await fetch(`${apiBaseUrl}/api/employees`, {
          method: "POST",
          headers: getAuthHeaders(),
          body: JSON.stringify(payload)
        });
        if (res.ok) {
          const newEmp = await res.json();
          const coyObj = companies.find(c => String(c.coyId || c.id) === String(formData.company));
          const coyNm = coyObj ? coyObj.coyNm : "Unknown Company";

          newEmp.displayLabel = `${newEmp.fstNm || newEmp.firstName} ${newEmp.lstNm || newEmp.lastName} - ${newEmp.designation} - ${coyNm}`;
          setEmployees(prev => [...prev, newEmp]);
          onSuccess(newEmp.empId || newEmp.id);
          onClose();
        } else {
          const text = await res.text();
          triggerAlert("error", "Error", `Failed to add employee: ${text}`);
        }
      } catch (err) {
        console.error("Quick add error:", err);
        triggerAlert("error", "Error", "An error occurred");
      } finally {
        setLoading(false);
      }
    };

    return (
      <div style={{ marginTop: '8px', padding: '12px', border: '1px solid #cbd5e1', borderRadius: '6px', backgroundColor: '#f8fafc', boxShadow: '0 1px 2px rgba(0,0,0,0.05)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
          <h4 style={{ fontSize: '13px', fontWeight: '600', color: '#334155', margin: 0 }}>Add New {role}</h4>
          <X size={14} style={{ cursor: 'pointer', color: '#64748b' }} onClick={onClose} />
        </div>
        <input type="text" placeholder="Full Name" value={formData.name} onChange={e => setFormData({ ...formData, name: e.target.value })} style={{ width: '100%', padding: '6px 8px', fontSize: '12px', border: '1px solid #cbd5e1', borderRadius: '4px', marginBottom: '8px', boxSizing: 'border-box' }} />

        <select value={formData.designation} onChange={e => setFormData({ ...formData, designation: e.target.value })} style={{ width: '100%', padding: '6px 8px', fontSize: '12px', border: '1px solid #cbd5e1', borderRadius: '4px', marginBottom: '8px', boxSizing: 'border-box', backgroundColor: 'white' }}>
          <option value="">Select Designation</option>
          {designations.map(d => (
            <option key={d.desigId || d.id} value={d.desigNm}>{d.desigNm}</option>
          ))}
        </select>

        <select value={formData.company} onChange={e => setFormData({ ...formData, company: e.target.value })} style={{ width: '100%', padding: '6px 8px', fontSize: '12px', border: '1px solid #cbd5e1', borderRadius: '4px', marginBottom: '10px', boxSizing: 'border-box', backgroundColor: 'white' }}>
          <option value="">Select Company</option>
          {companies.map(c => (
            <option key={c.coyId || c.id} value={c.coyId || c.id}>{c.coyNm}</option>
          ))}
        </select>

        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px' }}>
          <button type="button" onClick={onClose} style={{ padding: '4px 12px', fontSize: '12px', color: '#64748b', backgroundColor: 'transparent', border: '1px solid #cbd5e1', borderRadius: '4px', cursor: 'pointer' }}>Cancel</button>
          <button type="button" onClick={handleSave} disabled={loading} style={{ padding: '4px 12px', fontSize: '12px', color: 'white', backgroundColor: '#2563eb', border: 'none', borderRadius: '4px', cursor: 'pointer' }}>
            {loading ? 'Saving...' : 'Save'}
          </button>
        </div>
      </div>
    );
  };

  const handleResetForm = () => {
    setEditId(null);
    setTaskCode("");
    setTaskTitle("");
    setPriority("High");
    setStatus("Draft");
    setDuration("");
    setStartDate("");
    setDueDate("");
    setDateError("");
    setAssignedEmployee("");
    setDescription("");
    setReviewer("");
    setApprover("");
    setEnableWorkflow(true);
  };

  const handleEdit = (task) => {
    setEditId(task.empTaskId || task.id);
    setTaskCode(task.taskCd || "");
    setTaskTitle(task.taskNm || "");
    const p = task.priority || task.Priority || "HIGH";
    setPriority(p.charAt(0).toUpperCase() + p.slice(1).toLowerCase());
    setStatus(task.taskSts === 'HOLD' ? 'Draft' : 'To-Do');

    let sd = task.stDt ? String(task.stDt).substring(0, 10) : "";
    let dd = task.endDt ? String(task.endDt).substring(0, 10) : "";
    setStartDate(sd);
    setDueDate(dd);

    if (sd && dd) {
      const start = new Date(sd);
      const end = new Date(dd);
      const diff = Math.ceil((end - start) / (1000 * 60 * 60 * 24));
      setDuration(diff >= 0 ? String(diff + 1) : "0");
    } else {
      setDuration("");
    }

    setAssignedEmployee(task.empId ? String(task.empId) : "");
    setDescription(task.taskDesc || "");

    // Fetch process configs for this task to prefill reviewer and approver dropdowns
    setReviewer("");
    setApprover("");
    setEnableWorkflow(false);

    const taskId = task.empTaskId || task.id;
    if (taskId) {
      fetch(`${apiBaseUrl}/api/process-config/draft-task/${taskId}`, { headers: getAuthHeaders() })
        .then(res => res.ok ? res.json() : [])
        .then(pcs => {
          if (pcs && pcs.length > 0) {
            setEnableWorkflow(true);
            const rev = pcs.find(p => p.stepType === 'REVIEWER');
            if (rev && rev.empId) setReviewer(String(rev.empId));
            const app = pcs.find(p => p.stepType === 'APPROVER');
            if (app && app.empId) setApprover(String(app.empId));
          }
        })
        .catch(err => console.error("Error loading process config:", err));
    }

    setView("form");
  };

  const handleView = (task) => {
    handleEdit(task);
    setView("list");
    setShowPreviewModal(true);
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Are you sure you want to delete this task?")) return;
    try {
      const response = await fetch(`${apiBaseUrl}/api/individual-tasks/${id}`, {
        method: "DELETE",
        headers: getAuthHeaders()
      });
      if (response.ok) {
        triggerAlert("success", "Success", "Task deleted successfully!");
        fetchAllData();
      } else {
        triggerAlert("error", "Error", "Failed to delete task.");
      }
    } catch (err) {
      triggerAlert("error", "Error", "Server error occurred.");
    }
  };

  const handleStartDateChange = (e) => {
    const newStart = e.target.value;
    setStartDate(newStart);
    setDateError("");
    if (newStart && duration) {
      const end = new Date(newStart);
      end.setDate(end.getDate() + Math.max(0, parseInt(duration, 10) - 1));
      setDueDate(end.toISOString().split('T')[0]);
    } else if (newStart && dueDate) {
      const start = new Date(newStart);
      const end = new Date(dueDate);
      const diff = Math.ceil((end - start) / (1000 * 60 * 60 * 24));
      if (diff < 0) {
        setDateError("Due Date cannot be earlier than Start Date.");
        setDueDate("");
        setDuration("");
      } else {
        setDuration(String(diff + 1));
      }
    }
  };

  const handleDurationChange = (e) => {
    const val = e.target.value.replace(/\D/g, "");
    setDuration(val);
    if (val && startDate) {
      const end = new Date(startDate);
      end.setDate(end.getDate() + Math.max(0, parseInt(val, 10) - 1));
      setDueDate(end.toISOString().split('T')[0]);
    }
  };

  const handleDueDateChange = (e) => {
    const newDue = e.target.value;
    setDateError("");
    if (newDue && startDate) {
      const start = new Date(startDate);
      const end = new Date(newDue);
      const diff = Math.ceil((end - start) / (1000 * 60 * 60 * 24));
      if (diff < 0) {
        setDateError("Due Date cannot be earlier than Start Date.");
        return;
      }
      setDueDate(newDue);
      setDuration(String(diff + 1));
    } else {
      setDueDate(newDue);
    }
  };

  // --- ATTACHMENTS STATE & LOGIC ---
  const [attachments, setAttachments] = useState([]);
  const fileInputRef = useRef(null);

  const handleFileDrop = (e) => {
    e.preventDefault();
    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      setAttachments([...attachments, ...Array.from(e.dataTransfer.files)]);
    }
  };

  const handleFileInput = (e) => {
    if (e.target.files && e.target.files.length > 0) {
      setAttachments([...attachments, ...Array.from(e.target.files)]);
    }
  };

  const removeAttachment = (indexToRemove) => {
    setAttachments(attachments.filter((_, index) => index !== indexToRemove));
  };

  // --- CHECKLIST STATE & LOGIC ---
  const [checklist, setChecklist] = useState([]);
  const [editingItemId, setEditingItemId] = useState(null);
  const [editingItemName, setEditingItemName] = useState("");
  const [isAddingChecklist, setIsAddingChecklist] = useState(false);
  const [newChecklistName, setNewChecklistName] = useState("");

  const addChecklistItem = () => {
    setIsAddingChecklist(true);
    setNewChecklistName("");
  };

  const saveNewChecklist = () => {
    if (!newChecklistName.trim()) {
      alert("Please enter a valid checklist item name.");
      return;
    }
    const newItemId = Date.now();
    setChecklist([
      ...checklist,
      { id: newItemId, name: newChecklistName, sequence: checklist.length + 1 }
    ]);
    setIsAddingChecklist(false);
    setNewChecklistName("");
  };

  const deleteChecklistItem = (id) => {
    const updated = checklist.filter(item => item.id !== id);
    const resequenced = updated.map((item, idx) => ({ ...item, sequence: idx + 1 }));
    setChecklist(resequenced);
  };

  const startEditingChecklist = (item) => {
    setEditingItemId(item.id);
    setEditingItemName(item.name);
  };

  const saveChecklistEdit = (id) => {
    if (!editingItemName.trim()) return;
    setChecklist(checklist.map(item => item.id === id ? { ...item, name: editingItemName } : item));
    setEditingItemId(null);
  };

  // --- PREVIEW MODAL STATE ---
  const [showPreviewModal, setShowPreviewModal] = useState(false);

  const handleSaveTask = async () => {
    if (!taskTitle.trim() || !assignedEmployee) {
      triggerAlert("warning", "Missing Fields", "Please fill in task title and assigned employee.");
      return;
    }
    const payload = {
      taskCd: taskCode,
      taskNm: taskTitle,
      taskDesc: description,
      empId: parseInt(assignedEmployee),
      assignedBy: currentUser?.empId || currentUser?.id || 1,
      taskAsgnTo: 'INTERNAL',
      stDt: startDate ? startDate : null,
      endDt: dueDate ? dueDate : null,
      priority: priority.toUpperCase(),
      taskSts: 'ASSIGNED',
      prcsFlg: enableWorkflow,
      prcsYesActn: enableWorkflow ? "YES" : "",
      sts: true
    };

    let url = `${apiBaseUrl}/api/individual-tasks`;
    let method = "POST";
    if (editId) {
      url = `${url}/${editId}`;
      method = "PUT";
    }

    try {
      const response = await fetch(url, {
        method,
        headers: getAuthHeaders(),
        body: JSON.stringify(payload)
      });
      if (response.ok) {
        const savedTask = await response.json();
        const taskId = savedTask.empTaskId || savedTask.id || editId;

        if (enableWorkflow && taskId) {
          if (reviewer) {
            try {
              await fetch(`${apiBaseUrl}/api/process-config/draft-task/${taskId}`, {
                method: "POST", headers: getAuthHeaders(),
                body: JSON.stringify({ ordrId: 1, stepType: "REVIEWER", empId: parseInt(reviewer), stepLabel: "Reviewer" })
              });
            } catch (e) { }
          }
          if (approver) {
            try {
              await fetch(`${apiBaseUrl}/api/process-config/draft-task/${taskId}`, {
                method: "POST", headers: getAuthHeaders(),
                body: JSON.stringify({ ordrId: 2, stepType: "APPROVER", empId: parseInt(approver), stepLabel: "Approver" })
              });
            } catch (e) { }
          }
        } else if (taskId) {
          try {
            const existingSteps = await fetch(`${apiBaseUrl}/api/process-config/draft-task/${taskId}`, { headers: getAuthHeaders() }).then(r => r.ok ? r.json() : []);
            for (const step of existingSteps) {
              const pcId = step.pcId || step.pc_id;
              if (pcId) {
                await fetch(`${apiBaseUrl}/api/process-config/${pcId}`, { method: "DELETE", headers: getAuthHeaders() });
              }
            }
          } catch (e) { }
        }

        triggerAlert("success", "Success", `Task '${taskTitle}' has been successfully ${editId ? 'updated' : 'created'}!`);
        setShowPreviewModal(false);
        handleResetForm();
        fetchAllData();
      } else {
        const errorText = await response.text();
        triggerAlert("error", "Failed to save task", errorText || "An error occurred.");
      }
    } catch (err) {
      triggerAlert("error", "Server error", err.message || "An error occurred.");
    }
  };

  return (
    <div className="cc-shell-container">
      <AlertModal {...alertConfig} onClose={() => setAlertConfig({ ...alertConfig, isOpen: false })} />
      <Sidebar onLogout={onLogout} />
      <div className="cc-shell">
        <Header title=" Assign Task " onLogout={onLogout} userRole={userRole} />

        <main className="cc-main">
          <div className="cit-container">

            {view === "form" && (
              <div className="cc-header-actions" style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 20 }}>

              </div>
            )}

            {view === "list" && (
              <div className="cit-card">
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '20px' }}>
                  <div>
                    <h3 className="cit-card-title" style={{ margin: 0, marginBottom: '4px', fontSize: '18px', color: '#1e293b', fontWeight: 'bold' }}>Assign Task List</h3>
                    <p style={{ margin: 0, color: '#64748b', fontSize: '14px' }}>View and manage all assigned task records</p>
                  </div>
                  <button className="cit-btn-create" style={{ background: '#2563eb', color: 'white', padding: '8px 16px', borderRadius: 6, border: 'none', display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer', fontWeight: '500' }} onClick={() => { handleResetForm(); setView("form"); }}>
                    <Plus size={16} /> Assign New Task
                  </button>
                </div>
                <div className="cit-table-container">
                  <table className="cit-table">
                    <thead>
                      <tr>
                        <th>Task Code</th>
                        <th>Title</th>
                        <th>Assigned To</th>
                        <th>Priority</th>
                        <th>Status</th>
                        <th>Start Date</th>
                        <th>Due Date</th>
                        <th>Reviewer</th>
                        <th>Approver</th>
                        <th>Checklist</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {tasks.length > 0 ? tasks.map(task => {
                        const emp = employees.find(e => String(e.empId || e.id) === String(task.empId));
                        const empName = emp ? `${emp.fstNm || emp.firstName} ${emp.lstNm || emp.lastName}` : "N/A";
                        return (
                          <tr key={task.empTaskId || task.id}>
                            <td>{task.taskCd}</td>
                            <td>{task.taskNm}</td>
                            <td>{empName}</td>
                            <td>
                              <span className={`cit-badge priority-${(task.priority || task.Priority || '').toLowerCase()}`}>
                                {task.priority || task.Priority || 'None'}
                              </span>
                            </td>
                            <td><span style={{ color: "#2563eb", background: "#eff6ff", padding: "2px 8px", borderRadius: 4, fontWeight: 600, border: "1px solid #bfdbfe", fontSize: 12 }}>{task.taskSts}</span></td>
                            <td>{task.stDt ? String(task.stDt).substring(0, 10) : ''}</td>
                            <td>{task.endDt ? String(task.endDt).substring(0, 10) : ''}</td>
                            <td>{task.reviewerName || "N/A"}</td>
                            <td>{task.approverName || "N/A"}</td>
                            <td>0 Items</td>
                            <td>
                              <button className="cit-action-btn view" title="View" style={{ color: '#64748b', marginRight: 8 }} onClick={() => handleView(task)}>
                                <Eye size={16} />
                              </button>
                              <button className="cit-action-btn edit" title="Edit" style={{ color: '#3b82f6', marginRight: 8 }} onClick={() => handleEdit(task)}>
                                <Edit3 size={16} />
                              </button>
                              <button className="cit-action-btn delete" title="Delete" style={{ color: '#ef4444' }} onClick={() => handleDelete(task.empTaskId || task.id)}>
                                <Trash2 size={16} />
                              </button>
                            </td>
                          </tr>
                        );
                      }) : (
                        <tr><td colSpan="11" style={{ textAlign: 'center', padding: '20px' }}>No tasks found.</td></tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {view === "form" && (
              <>
                <div className="cc-content" style={{ paddingBottom: '80px', maxWidth: '1280px', margin: '0 auto' }}>
                  <div className="cc-form-card" style={{
                    backgroundColor: 'white',
                    borderRadius: '8px',
                    border: '1px solid #e2e8f0',
                    overflow: 'hidden',
                    boxShadow: '0 1px 3px rgba(0,0,0,0.05)'
                  }}>

                    {/* Header */}
                    <div style={{
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      padding: '20px 24px',
                      borderBottom: '1px solid #e2e8f0',
                      backgroundColor: '#fafbfc'
                    }}>
                      <h2 style={{ fontSize: '20px', fontWeight: '700', color: '#0f172a', margin: 0 }}>
                        {editId ? "Edit Task" : "Add New Task"}
                      </h2>
                      <button
                        type="button"
                        className="cc-nav-view-btn"
                        onClick={() => {
                          setView("list");
                          handleResetForm();
                        }}
                      >
                        <ChevronLeft size={15} /> Back to Task List
                      </button>
                    </div>

                    <div style={{ padding: '24px' }}>
                      {/* Section 1: Task Details */}
                      <section className="cc-panel" style={{ backgroundColor: 'white', padding: 0, border: 'none', marginBottom: '32px' }}>
                        <h3 className="cc-section-title" style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', marginBottom: '20px', borderBottom: '1px solid #e2e8f0', paddingBottom: '12px' }}>
                          Task Details
                        </h3>

                        <div className="cc-form-layout-row columns-4">
                          <label className="cc-field-item">
                            <span>Task Code <b style={{ color: '#ef4444' }}>*</b></span>
                            <input type="text" value={taskCode} onChange={(e) => setTaskCode(e.target.value)} maxLength={10} placeholder="Enter task code" />
                          </label>
                          <label className="cc-field-item">
                            <span>Task Title <b style={{ color: '#ef4444' }}>*</b></span>
                            <input type="text" value={taskTitle} onChange={(e) => setTaskTitle(e.target.value)} placeholder="Enter task title" />
                          </label>
                          <label className="cc-field-item">
                            <span>Assigned To <b style={{ color: '#ef4444' }}>*</b></span>
                            <SearchableSelect
                              name="assignedEmployee"
                              value={assignedEmployee}
                              onChange={(e) => setAssignedEmployee(e.target.value)}
                              options={employees.map(emp => ({ value: emp.empId || emp.id, label: emp.displayLabel || `${emp.fstNm || emp.firstName} ${emp.lstNm || emp.lastName}` }))}
                              placeholder="Search Employee..."
                            />
                          </label>
                          <label className="cc-field-item">
                            <span>Priority <b style={{ color: '#ef4444' }}>*</b></span>
                            <div className="cit-input-wrapper" style={{ margin: 0 }}>
                              <select value={priority} onChange={(e) => setPriority(e.target.value)} style={{ color: priority === 'High' ? '#ef4444' : priority === 'Medium' ? '#eab308' : '#22c55e', fontWeight: 600 }}>
                                <option value="High" style={{ color: '#ef4444' }}>High</option>
                                <option value="Medium" style={{ color: '#eab308' }}>Medium</option>
                                <option value="Low" style={{ color: '#22c55e' }}>Low</option>
                              </select>
                              <ChevronDown size={14} className="cit-input-icon-right" style={{ color: priority === 'High' ? '#ef4444' : priority === 'Medium' ? '#eab308' : '#22c55e' }} />
                            </div>
                          </label>
                        </div>

                        <div className="cc-form-layout-row columns-3" style={{ marginTop: '20px' }}>
                          <label className="cc-field-item">
                            <span>Duration (Days) <b style={{ color: '#ef4444' }}>*</b></span>
                            <input type="text" value={duration} onChange={handleDurationChange} pattern="\d*" placeholder="Enter days" />
                          </label>
                          <label className="cc-field-item">
                            <span>Start Date <b style={{ color: '#ef4444' }}>*</b></span>
                            <input type="date" value={startDate} onChange={handleStartDateChange} style={{ borderColor: dateError ? 'red' : '' }} />
                          </label>
                          <label className="cc-field-item" style={{ position: 'relative' }}>
                            <span>Due Date <b style={{ color: '#ef4444' }}>*</b></span>
                            <input type="date" value={dueDate} onChange={handleDueDateChange} min={startDate} style={{ borderColor: dateError ? 'red' : '' }} />
                            {dateError && <span style={{ color: 'red', fontSize: '11px', position: 'absolute', bottom: '-16px', left: 0 }}>{dateError}</span>}
                          </label>
                        </div>

                        <div className="cc-form-layout-row columns-1" style={{ marginTop: '20px' }}>
                          <label className="cc-field-item">
                            <span>Description <b style={{ color: '#ef4444' }}>*</b></span>
                            <textarea rows={3} value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Enter task description"></textarea>
                          </label>
                        </div>
                      </section>

                      {/* Section 2: Process & Workflow */}
                      <section className="cc-panel" style={{ backgroundColor: 'white', padding: 0, border: 'none', marginBottom: '32px' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px', borderBottom: '1px solid #e2e8f0', paddingBottom: '12px' }}>
                          <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', margin: 0 }}>
                            Process / Workflow
                          </h3>

                          <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                            <span style={{ fontSize: "14px", fontWeight: "600", color: "#475569" }}>Enable Workflow:</span>
                            <label style={{ position: "relative", display: "inline-block", width: "46px", height: "26px", margin: 0 }}>
                              <input
                                type="checkbox"
                                checked={enableWorkflow}
                                onChange={() => setEnableWorkflow(!enableWorkflow)}
                                style={{ opacity: 0, width: 0, height: 0 }}
                              />
                              <span style={{
                                position: "absolute", cursor: "pointer", top: 0, left: 0, right: 0, bottom: 0,
                                backgroundColor: enableWorkflow ? "#10b981" : "#cbd5e1",
                                transition: ".4s", borderRadius: "34px"
                              }}>
                                <span style={{
                                  position: "absolute", height: "20px", width: "20px",
                                  left: enableWorkflow ? "23px" : "3px", bottom: "3px",
                                  backgroundColor: "white", transition: ".4s", borderRadius: "50%",
                                  boxShadow: "0 2px 4px rgba(0,0,0,0.1)"
                                }}></span>
                              </span>
                            </label>
                            <span style={{
                              fontSize: "14px", fontWeight: "600", minWidth: "30px",
                              color: enableWorkflow ? "#16a34a" : "#64748b"
                            }}>
                              {enableWorkflow ? "YES" : "NO"}
                            </span>
                          </div>
                        </div>

                        {enableWorkflow && (
                          <div className="cc-form-layout-row columns-2">
                            <label className="cc-field-item">
                              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px' }}>
                                <span>Reviewer <b style={{ color: '#ef4444' }}>*</b></span>
                                <span onClick={() => setShowQuickAddReviewer(!showQuickAddReviewer)} style={{ color: '#2563eb', fontSize: '12px', cursor: 'pointer', fontWeight: '600' }}>+ Add New</span>
                              </div>
                              <SearchableSelect
                                name="reviewer"
                                value={reviewer}
                                onChange={(e) => setReviewer(e.target.value)}
                                options={employees
                                  .filter(emp => String(emp.empId || emp.id) !== String(assignedEmployee))
                                  .map(emp => ({ value: emp.empId || emp.id, label: emp.displayLabel || `${emp.fstNm || emp.firstName} ${emp.lstNm || emp.lastName}` }))}
                                placeholder="Search Reviewer..."
                              />
                              {showQuickAddReviewer && (
                                <QuickAddBox
                                  role="Reviewer"
                                  onClose={() => setShowQuickAddReviewer(false)}
                                  onSuccess={(id) => { setReviewer(id); setShowQuickAddReviewer(false); }}
                                />
                              )}
                            </label>
                            <label className="cc-field-item">
                              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px' }}>
                                <span>Approver <b style={{ color: '#ef4444' }}>*</b></span>
                                <span onClick={() => setShowQuickAddApprover(!showQuickAddApprover)} style={{ color: '#2563eb', fontSize: '12px', cursor: 'pointer', fontWeight: '600' }}>+ Add New</span>
                              </div>
                              <SearchableSelect
                                name="approver"
                                value={approver}
                                onChange={(e) => setApprover(e.target.value)}
                                options={employees
                                  .filter(emp => String(emp.empId || emp.id) !== String(assignedEmployee))
                                  .map(emp => ({ value: emp.empId || emp.id, label: emp.displayLabel || `${emp.fstNm || emp.firstName} ${emp.lstNm || emp.lastName}` }))}
                                placeholder="Search Approver..."
                              />
                              {showQuickAddApprover && (
                                <QuickAddBox
                                  role="Approver"
                                  onClose={() => setShowQuickAddApprover(false)}
                                  onSuccess={(id) => { setApprover(id); setShowQuickAddApprover(false); }}
                                />
                              )}
                            </label>
                          </div>
                        )}
                        {!enableWorkflow && (
                          <div className="cit-info-box" style={{ background: "#f1f5f9", borderColor: "#e2e8f0", color: "#64748b", margin: 0 }}>
                            <Info size={18} style={{ marginTop: 2 }} />
                            <span>Workflow is disabled. Task will bypass review process.</span>
                          </div>
                        )}
                      </section>

                      {/* Section 3: Attachments & Checklist */}
                      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px' }}>
                        {/* Attachments Column */}
                        <section className="cc-panel" style={{ backgroundColor: 'white', padding: 0, border: 'none' }}>
                          <h3 className="cc-section-title" style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', marginBottom: '16px' }}>
                            Attachments <Info size={14} color="#94a3b8" style={{ marginLeft: 6, cursor: 'pointer' }} />
                          </h3>
                          <div
                            className="cit-upload-box"
                            onDragOver={(e) => e.preventDefault()}
                            onDrop={handleFileDrop}
                          >
                            <UploadCloud size={32} color="#94a3b8" />
                            <p>Drag & drop files here<br />or</p>
                            <input
                              type="file"
                              ref={fileInputRef}
                              onChange={handleFileInput}
                              style={{ display: "none" }}
                              multiple
                            />
                            <button className="cit-upload-btn" onClick={() => fileInputRef.current.click()}>Browse Files</button>
                            <div className="cit-upload-info">Max file size: 10 MB (PDF, DOC, DOCX, XLS, XLSX, JPG, PNG)</div>
                          </div>
                          {attachments.length > 0 && (
                            <div className="cit-file-list" style={{ marginTop: '16px' }}>
                              {attachments.map((file, idx) => (
                                <div className="cit-file-item" key={idx}>
                                  <span>{file.name}</span>
                                  <button className="cit-file-remove" onClick={() => removeAttachment(idx)}><Trash2 size={14} /></button>
                                </div>
                              ))}
                            </div>
                          )}
                        </section>

                        {/* Checklist Column */}
                        <section className="cc-panel" style={{ backgroundColor: 'white', padding: 0, border: 'none' }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                            <h3 className="cc-section-title" style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', margin: 0 }}>
                              Checklist Items
                            </h3>
                            <button className="cit-add-btn" onClick={addChecklistItem} style={{ margin: 0 }}>
                              <Plus size={14} /> Add Checklist Item
                            </button>
                          </div>
                          {(checklist.length > 0 || isAddingChecklist) && (
                            <div className="cit-table-container">
                              <table className="cit-table">
                                <thead>
                                  <tr>
                                    <th width="10%">S.No</th>
                                    <th width="50%">Checklist Item</th>
                                    <th width="20%">Sequence</th>
                                    <th width="20%">Actions</th>
                                  </tr>
                                </thead>
                                <tbody>
                                  {checklist.map((item, index) => (
                                    <tr key={item.id}>
                                      <td>{index + 1}</td>
                                      <td>
                                        {editingItemId === item.id ? (
                                          <input
                                            type="text"
                                            value={editingItemName}
                                            onChange={(e) => setEditingItemName(e.target.value)}
                                            onKeyDown={(e) => e.key === 'Enter' && saveChecklistEdit(item.id)}
                                            autoFocus
                                            style={{ padding: '6px 10px', width: '100%', border: '1px solid #3b82f6', borderRadius: '4px', outline: 'none' }}
                                          />
                                        ) : (
                                          item.name
                                        )}
                                      </td>
                                      <td>{item.sequence}</td>
                                      <td>
                                        {editingItemId === item.id ? (
                                          <button className="cit-action-btn edit" onClick={() => saveChecklistEdit(item.id)}><Check size={14} /></button>
                                        ) : (
                                          <button className="cit-action-btn edit" onClick={() => startEditingChecklist(item)}><Edit3 size={14} /></button>
                                        )}
                                        <button className="cit-action-btn delete" onClick={() => deleteChecklistItem(item.id)}><Trash2 size={14} /></button>
                                      </td>
                                    </tr>
                                  ))}
                                  {isAddingChecklist && (
                                    <tr>
                                      <td>{checklist.length + 1}</td>
                                      <td>
                                        <input
                                          type="text"
                                          value={newChecklistName}
                                          onChange={(e) => setNewChecklistName(e.target.value)}
                                          onKeyDown={(e) => e.key === 'Enter' && saveNewChecklist()}
                                          autoFocus
                                          placeholder="Enter checklist item..."
                                          style={{ padding: '6px 10px', width: '100%', border: '1px solid #3b82f6', borderRadius: '4px', outline: 'none' }}
                                        />
                                      </td>
                                      <td>{checklist.length + 1}</td>
                                      <td>
                                        <button className="cit-action-btn edit" onClick={saveNewChecklist}><Check size={14} /></button>
                                        <button className="cit-action-btn delete" onClick={() => { setIsAddingChecklist(false); setNewChecklistName(""); }}><Trash2 size={14} /></button>
                                      </td>
                                    </tr>
                                  )}
                                </tbody>
                              </table>
                            </div>
                          )}
                        </section>
                      </div>

                    </div>

                    {/* Footer */}
                    <div className="cc-form-footer" style={{
                      display: 'flex',
                      justifyContent: 'flex-end',
                      gap: '12px',
                      padding: '16px 24px',
                      backgroundColor: '#fafbfc',
                      borderTop: '1px solid #e2e8f0'
                    }}>
                      <button type="button" className="cc-btn primary" onClick={() => setShowPreviewModal(true)} style={{ background: '#3b82f6', borderColor: '#3b82f6', color: 'white', padding: '8px 16px', borderRadius: '6px', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <Eye size={14} /> Preview Task
                      </button>
                      <button type="button" className="cc-btn primary" onClick={handleSaveTask} style={{ background: '#10b981', borderColor: '#10b981', color: 'white', padding: '8px 16px', borderRadius: '6px', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <Save size={14} /> Save
                      </button>
                      <button type="button" className="cc-btn secondary" onClick={() => {
                        setView("list");
                        handleResetForm();
                      }} style={{ background: 'white', border: '1px solid #cbd5e1', color: '#475569', padding: '8px 16px', borderRadius: '6px', fontWeight: 600 }}>
                        Cancel
                      </button>
                    </div>

                  </div>
                </div>
              </>
            )}

          </div>
        </main>
      </div>

      {/* MODAL OVERLAY FOR PREVIEW */}
      {showPreviewModal && (
        <div className="cit-modal-overlay">
          <div className="cit-modal-content">
            <div className="cit-modal-header">
              <h2>Task Preview</h2>
              <button className="cit-modal-close" onClick={() => setShowPreviewModal(false)}>
                <X size={24} />
              </button>
            </div>

            <table className="cit-preview-table">
              <tbody>
                <tr>
                  <th>Task Code</th>
                  <td>{taskCode}</td>
                </tr>
                <tr>
                  <th>Task Title</th>
                  <td>{taskTitle || "-"}</td>
                </tr>
                <tr>
                  <th>Priority</th>
                  <td><span style={{ color: priority === 'High' ? '#ef4444' : priority === 'Medium' ? '#eab308' : '#22c55e', fontWeight: 600 }}>{priority}</span></td>
                </tr>
                <tr>
                  <th>Status</th>
                  <td><span style={{ color: "#2563eb", background: "#eff6ff", padding: "2px 8px", borderRadius: 4, fontWeight: 600, border: "1px solid #bfdbfe" }}>{status}</span></td>
                </tr>
                <tr>
                  <th>Duration</th>
                  <td>{duration ? `${duration} Days` : "-"}</td>
                </tr>
                <tr>
                  <th>Start Date</th>
                  <td>{startDate}</td>
                </tr>
                <tr>
                  <th>Due Date</th>
                  <td>{dueDate}</td>
                </tr>
                <tr>
                  <th>Assigned To</th>
                  <td>{employees.find(e => String(e.empId || e.id) === String(assignedEmployee)) ? `${employees.find(e => String(e.empId || e.id) === String(assignedEmployee)).fstNm || employees.find(e => String(e.empId || e.id) === String(assignedEmployee)).firstName} ${employees.find(e => String(e.empId || e.id) === String(assignedEmployee)).lstNm || employees.find(e => String(e.empId || e.id) === String(assignedEmployee)).lastName}` : "None"}</td>
                </tr>
                <tr>
                  <th>Process / Workflow</th>
                  <td>
                    {enableWorkflow ? (
                      <>
                        <span style={{ color: "#10b981", background: "#d1fae5", padding: "2px 8px", borderRadius: 4, fontWeight: 600 }}>Enabled</span>
                        <span style={{ color: '#94a3b8', margin: '0 4px' }}>|</span> Reviewer: {reviewer}
                        <span style={{ color: '#94a3b8', margin: '0 4px' }}>|</span> Approver: {approver}
                      </>
                    ) : (
                      <span style={{ color: "#64748b", background: "#f1f5f9", padding: "2px 8px", borderRadius: 4, fontWeight: 600 }}>Disabled</span>
                    )}
                  </td>
                </tr>
                <tr>
                  <th>Checklist Items</th>
                  <td>{checklist.length} Items</td>
                </tr>
                <tr>
                  <th>Attachments</th>
                  <td>{attachments.length > 0 ? attachments.map(f => f.name).join(", ") : "No attachments"}</td>
                </tr>
                <tr>
                  <th>Description</th>
                  <td>{description || "-"}</td>
                </tr>
              </tbody>
            </table>

            <div className="cit-modal-footer" style={{ marginTop: '24px', display: 'flex', justifyContent: 'flex-end', gap: '16px', borderTop: '1px solid #e2e8f0', paddingTop: '16px' }}>
              <button className="cit-btn-cancel" onClick={() => setShowPreviewModal(false)}>Close Preview</button>
              <button className="cit-btn-create" onClick={handleSaveTask}>
                <Plus size={16} /> {editId ? 'Update Task' : 'Create & Assign Task'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Assignment;