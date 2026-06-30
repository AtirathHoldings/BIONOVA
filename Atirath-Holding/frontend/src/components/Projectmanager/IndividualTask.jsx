import React, { useState, useRef } from 'react';
import Sidebar from './../Sidebar';
import Header from './../Header';
import { 
  Lock, Calendar as CalendarIcon, Flag, ChevronDown, 
  Edit3, Trash2, Plus, Info, UploadCloud, Save, Eye, X, Check
} from 'lucide-react';
import '../../styles/IndividualTask.css';
import '../../styles/CompanyMaster.css';

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;

const getAuthHeaders = () => ({
  "Content-Type": "application/json",
  "Authorization": `Bearer ${sessionStorage.getItem("authToken") || ""}`
});

const CreateIndividualTask = ({ userRole, onLogout }) => {
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
  const [currentUser, setCurrentUser] = useState(null);
  const [tasks, setTasks] = useState([]);
  const [view, setView] = useState("list");
  const [editId, setEditId] = useState(null);

  const fetchAllData = async () => {
    try {
      const profileRes = await fetch(`${apiBaseUrl}/api/profile`, { headers: getAuthHeaders() });
      if (profileRes.ok) setCurrentUser(await profileRes.json());
      
      const empRes = await fetch(`${apiBaseUrl}/api/employees`, { headers: getAuthHeaders() });
      if (empRes.ok) setEmployees(await empRes.json());
      
      const tasksRes = await fetch(`${apiBaseUrl}/api/individual-tasks`, { headers: getAuthHeaders() });
      if (tasksRes.ok) setTasks(await tasksRes.json());
    } catch (err) {
      console.error("Error fetching data", err);
    }
  };

  React.useEffect(() => {
    fetchAllData();
  }, []);

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
  };

  const handleEdit = (task) => {
    setEditId(task.empTaskId || task.id);
    setTaskCode(task.taskCd || "");
    setTaskTitle(task.taskNm || "");
    const p = task.priority || task.Priority || "HIGH";
    setPriority(p.charAt(0).toUpperCase() + p.slice(1).toLowerCase());
    setStatus(task.taskSts === 'HOLD' ? 'Draft' : 'To-Do');
    
    let sd = task.assignedDt ? String(task.assignedDt).substring(0, 10) : "";
    let dd = task.dueDt ? String(task.dueDt).substring(0, 10) : "";
    setStartDate(sd);
    setDueDate(dd);
    
    if (sd && dd) {
      const start = new Date(sd);
      const end = new Date(dd);
      const diff = Math.ceil((end - start) / (1000 * 60 * 60 * 24));
      setDuration(diff >= 0 ? String(diff) : "0");
    } else {
      setDuration("");
    }
    
    setAssignedEmployee(task.assignedTo ? String(task.assignedTo) : "");
    setDescription(task.taskDesc || "");
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
        alert("Task deleted successfully!");
        fetchAllData();
      } else {
        alert("Failed to delete task.");
      }
    } catch (err) {
      alert("Server error occurred.");
    }
  };

  const handleStartDateChange = (e) => {
    const newStart = e.target.value;
    setStartDate(newStart);
    setDateError("");
    if (newStart && duration) {
      const end = new Date(newStart);
      end.setDate(end.getDate() + parseInt(duration, 10));
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
        setDuration(diff >= 0 ? String(diff) : "0");
      }
    }
  };

  const handleDurationChange = (e) => {
    const val = e.target.value;
    setDuration(val);
    if (val && startDate) {
      const end = new Date(startDate);
      end.setDate(end.getDate() + parseInt(val, 10));
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
      setDuration(diff >= 0 ? String(diff) : "0");
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
    // update sequences
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

  return (
    <div className="cc-shell-container">
      <Sidebar onLogout={onLogout} />
      <div className="cc-shell">
        <Header title=" Individual Task " onLogout={onLogout} userRole={userRole} />

        <main className="cc-main">
          <div className="cit-container">
            
            <div className="cc-header-actions" style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 20 }}>
              {view === "list" ? (
                <button className="cit-btn-create" style={{ background: '#2563eb', color: 'white', padding: '8px 16px', borderRadius: 6, border: 'none', display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer' }} onClick={() => { handleResetForm(); setView("form"); }}>
                  <Plus size={16} /> Add Individual Task
                </button>
              ) : (
                <button className="cit-btn-cancel" style={{ background: 'white', border: '1px solid #cbd5e1', padding: '8px 16px', borderRadius: 6, cursor: 'pointer' }} onClick={() => { handleResetForm(); setView("list"); }}>
                  Back to List
                </button>
              )}
            </div>

            {view === "list" && (
              <div className="cit-card">
                <h3 className="cit-card-title">All Individual Tasks</h3>
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
                        const emp = employees.find(e => String(e.empId || e.id) === String(task.assignedTo));
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
                            <td>{task.assignedDt ? String(task.assignedDt).substring(0, 10) : ''}</td>
                            <td>{task.dueDt ? String(task.dueDt).substring(0, 10) : ''}</td>
                            <td>N/A</td>
                            <td>N/A</td>
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
              <div className="cit-grid">
                {/* LEFT COLUMN */}
                <div className="cit-left-col">
                  
                  {/* Task Details Card */}
                  <div className="cit-card">
                    <h3 className="cit-card-title">Task Details</h3>
                    
                    <div className="cit-form-row">
                      <div className="cit-form-group">
                        <label>Task Code <span>*</span></label>
                        <div className="cit-input-wrapper">
                          <input 
                            type="text" 
                            value={taskCode} 
                            onChange={(e) => setTaskCode(e.target.value)} 
                            maxLength={10}
                          />
                        </div>
                      </div>
                    <div className="cit-form-group" style={{ flex: 1.5 }}>
                      <label>Task Title <span>*</span></label>
                      <div className="cit-input-wrapper">
                        <input type="text" value={taskTitle} onChange={(e) => setTaskTitle(e.target.value)} />
                      </div>
                    </div>
                    <div className="cit-form-group">
                      <label>Priority <span>*</span></label>
                      <div className="cit-input-wrapper">
                        <select value={priority} onChange={(e) => setPriority(e.target.value)} style={{ color: priority === 'High' ? '#ef4444' : priority === 'Medium' ? '#eab308' : '#22c55e', fontWeight: 600 }}>
                          <option value="High" style={{ color: '#ef4444' }}>High</option>
                          <option value="Medium" style={{ color: '#eab308' }}>Medium</option>
                          <option value="Low" style={{ color: '#22c55e' }}>Low</option>
                        </select>
                        <ChevronDown size={14} className="cit-input-icon-right" style={{ color: priority === 'High' ? '#ef4444' : priority === 'Medium' ? '#eab308' : '#22c55e' }} />
                      </div>
                    </div>
                    <div className="cit-form-group">
                      <label>Status <span>*</span></label>
                      <div className="cit-input-wrapper">
                        <select value={status} onChange={(e) => setStatus(e.target.value)} style={{ color: "#2563eb", fontWeight: "600", backgroundColor: "#eff6ff", border: "1px solid #bfdbfe" }}>
                          <option value="Draft">Draft</option>
                          <option value="To-Do">To-Do</option>
                        </select>
                        <ChevronDown size={14} className="cit-input-icon-right" style={{ color: "#2563eb" }} />
                      </div>
                    </div>
                  </div>

                  <div className="cit-form-row">
                    <div className="cit-form-group">
                      <label>Duration (Days) <span>*</span></label>
                      <div className="cit-input-wrapper">
                        <input type="number" value={duration} onChange={handleDurationChange} min="0" />
                      </div>
                    </div>
                    <div className="cit-form-group">
                      <label>Start Date <span>*</span></label>
                      <div className="cit-input-wrapper">
                        <input type="date" value={startDate} onChange={handleStartDateChange} style={{ borderColor: dateError ? 'red' : '' }} />
                      </div>
                    </div>
                    <div className="cit-form-group" style={{ position: 'relative' }}>
                      <label>Due Date <span>*</span></label>
                      <div className="cit-input-wrapper">
                        <input type="date" value={dueDate} onChange={handleDueDateChange} min={startDate} style={{ borderColor: dateError ? 'red' : '' }} />
                      </div>
                      {dateError && <span style={{ color: 'red', fontSize: '11px', position: 'absolute', bottom: '-16px', left: 0 }}>{dateError}</span>}
                    </div>
                  </div>

                  <div className="cit-form-group">
                    <label>Description <span>*</span></label>
                    <div className="cit-input-wrapper">
                      <textarea rows={3} value={description} onChange={(e) => setDescription(e.target.value)}></textarea>
                    </div>
                  </div>
                </div>

                {/* Checklist Items Card */}
                <div className="cit-card">
                  <div className="cit-card-title" style={{ marginBottom: 15 }}>
                    <span>Checklist Items</span>
                    <button className="cit-add-btn" onClick={addChecklistItem}>
                      <Plus size={14} /> Add Checklist Item
                    </button>
                  </div>
                  
                  {(checklist.length > 0 || isAddingChecklist) && (
                  <div className="cit-table-container">
                    <table className="cit-table">
                      <thead>
                        <tr>
                          <th width="10%">#</th>
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
                </div>

              </div>

              {/* RIGHT COLUMN */}
              <div className="cit-right-col">
                
                {/* Assignment Card */}
                <div className="cit-card">
                  <h3 className="cit-card-title">Assignment</h3>
                  <div className="cit-form-group">
                    <label>Employee <span>*</span></label>
                    <div className="cit-input-wrapper">
                      <select value={assignedEmployee} onChange={(e) => setAssignedEmployee(e.target.value)}>
                        <option value="">Select Employee</option>
                        {employees.map(emp => (
                          <option key={emp.empId || emp.id} value={emp.empId || emp.id}>
                            {emp.fstNm || emp.firstName} {emp.lstNm || emp.lastName}
                          </option>
                        ))}
                      </select>
                      <ChevronDown size={14} className="cit-input-icon-right" />
                    </div>
                  </div>
                </div>

                {/* Process / Workflow Card */}
                <div className="cit-card">
                  <h3 className="cit-card-title">Process / Workflow</h3>
                  
                  <div className="cit-toggle-row">
                    <span className="cit-toggle-label">Enable Process / Workflow</span>
                    <div className="cit-toggle" onClick={() => setEnableWorkflow(!enableWorkflow)}>
                      <div className={`cit-toggle-switch ${enableWorkflow ? 'enabled' : 'disabled'}`}></div>
                      <span style={{ color: enableWorkflow ? "#10b981" : "#64748b", fontWeight: 700, fontSize: 13 }}>
                        {enableWorkflow ? "YES" : "NO"}
                      </span>
                    </div>
                  </div>

                  <div className="cit-info-box" style={{ background: enableWorkflow ? "#eff6ff" : "#f1f5f9", borderColor: enableWorkflow ? "#bfdbfe" : "#e2e8f0", color: enableWorkflow ? "#1e40af" : "#64748b" }}>
                    <Info size={18} style={{ marginTop: 2 }} />
                    <span>{enableWorkflow ? "If enabled, the task will go for review and approval process." : "Workflow is disabled. Task will bypass review process."}</span>
                  </div>

                  {enableWorkflow && (
                    <>
                      <div className="cit-form-group" style={{ marginBottom: 16 }}>
                        <label>Reviewer <span>*</span></label>
                        <div className="cit-input-wrapper">
                          <select value={reviewer} onChange={(e) => setReviewer(e.target.value)}>
                            <option value="">Select Reviewer</option>
                            {employees.map(emp => (
                              <option key={emp.empId || emp.id} value={emp.empId || emp.id}>
                                {emp.fstNm || emp.firstName} {emp.lstNm || emp.lastName}
                              </option>
                            ))}
                          </select>
                          <ChevronDown size={14} className="cit-input-icon-right" />
                        </div>
                      </div>

                      <div className="cit-form-group">
                        <label>Approver <span>*</span></label>
                        <div className="cit-input-wrapper">
                          <select value={approver} onChange={(e) => setApprover(e.target.value)}>
                            <option value="">Select Approver</option>
                            {employees.map(emp => (
                              <option key={emp.empId || emp.id} value={emp.empId || emp.id}>
                                {emp.fstNm || emp.firstName} {emp.lstNm || emp.lastName}
                              </option>
                            ))}
                          </select>
                          <ChevronDown size={14} className="cit-input-icon-right" />
                        </div>
                      </div>
                    </>
                  )}
                </div>

                {/* Attachments Card */}
                <div className="cit-card">
                  <h3 className="cit-card-title">Attachments <Info size={14} color="#94a3b8" style={{ marginLeft: 6, cursor: 'pointer' }} /></h3>
                  
                  <div 
                    className="cit-upload-box"
                    onDragOver={(e) => e.preventDefault()}
                    onDrop={handleFileDrop}
                  >
                    <UploadCloud size={32} color="#94a3b8" />
                    <p>Drag & drop files here<br/>or</p>
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
                    <div className="cit-file-list">
                      {attachments.map((file, idx) => (
                        <div className="cit-file-item" key={idx}>
                          <span>{file.name}</span>
                          <button className="cit-file-remove" onClick={() => removeAttachment(idx)}><Trash2 size={14} /></button>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

              </div>
            </div>

            {/* Bottom Bar */}
            <div className="cit-bottom-bar">
              <button className="cit-btn-cancel" onClick={() => setView('list')}>Cancel</button>
              <button className="cit-btn-draft"><Save size={14} /> Save as Draft</button>
              <button className="cit-btn-preview" onClick={() => setShowPreviewModal(true)}><Eye size={16} /> Preview Task</button>
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
              <button className="cit-btn-create" onClick={async () => {
                if (!taskTitle.trim() || !assignedEmployee) {
                  alert("Please fill in task title and assigned employee.");
                  return;
                }
                const payload = {
                  taskCd: taskCode,
                  taskNm: taskTitle,
                  taskDesc: description,
                  assignedTo: parseInt(assignedEmployee),
                  assignedBy: currentUser?.empId || currentUser?.id || 1,
                  assignedDt: startDate,
                  dueDt: dueDate,
                  toBeCompletedDt: dueDate,
                  priority: priority.toUpperCase(),
                  taskSts: status === 'Draft' ? 'HOLD' : 'ASSIGNED',
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
                    alert(`Task '${taskTitle}' has been successfully ${editId ? 'updated' : 'created'}!`);
                    setShowPreviewModal(false);
                    handleResetForm();
                    fetchAllData();
                  } else {
                    alert("Failed to save task. Please try again.");
                  }
                } catch (err) {
                  alert("Server error occurred.");
                }
              }}>
                <Plus size={16} /> {editId ? 'Update Task' : 'Create & Assign Task'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default CreateIndividualTask;
