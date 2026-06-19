import { useState } from "react";
import {
  Bell,
  CalendarDays,
  Edit,
  Menu,
  Plus,
  Save,
  Trash2,
  X,
  Lock,
  ChevronRight
} from "lucide-react";
import Sidebar from "../Sidebar"; 
import "../../styles/milestoneCreation.css";

const initialTasks = [
  { code: "TSK-001", name: "Site Preparation", type: "Internal", assignee: "Ravi Kumar", role: "Project Engineer", start: "2026-06-01", end: "2026-06-03", dependency: "- None -", depType: "-", duration: 3, color: "#39c94d", left: 0, width: 10 },
  { code: "TSK-002", name: "Excavation", type: "Internal", assignee: "Suresh Babu", role: "Site Engineer", start: "2026-06-04", end: "2026-06-08", dependency: "TSK-001", depType: "Sequential", duration: 5, color: "#3498ee", left: 10, width: 16 },
  { code: "TSK-003", name: "PCC Work", type: "Internal", assignee: "Srikanth", role: "Site Engineer", start: "2026-06-09", end: "2026-06-14", dependency: "TSK-002", depType: "Sequential", duration: 6, color: "#ff970f", left: 26, width: 20 },
  { code: "TSK-004", name: "Reinforcement Fixing", type: "Internal", assignee: "Chandu", role: "Steel Incharge", start: "2026-06-15", end: "2026-06-20", dependency: "TSK-003", depType: "Sequential", duration: 6, color: "#b56deb", left: 46, width: 20 },
  { code: "TSK-005", name: "Formwork", type: "Internal", assignee: "Mahesh", role: "Site Engineer", start: "2026-06-15", end: "2026-06-18", dependency: "TSK-003", depType: "Parallel", duration: 4, color: "#d87968", left: 46, width: 13 },
  { code: "TSK-006", name: "Concrete Pouring", type: "External", assignee: "ABC Constructions", role: "abc.con@gmail.com", start: "2026-06-21", end: "2026-06-26", dependency: "TSK-004, TSK-005", depType: "Parallel", duration: 6, color: "#1eb8bb", left: 66, width: 20 }
];

const checklistRows = ["Soil Test Approved", "Drawings Approved", "Material Available", "Safety Clearance"];

const MilestoneCreation = ({ onLogout, userRole }) => {
  const [tasks, setTasks] = useState(initialTasks);
  const [dependencyAvailable, setDependencyAvailable] = useState(true);
  const [taskDependencyAvailable, setTaskDependencyAvailable] = useState(true);
  const [checklistRequired, setChecklistRequired] = useState(true);
  const [processRequired, setProcessRequired] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [deleteCode, setDeleteCode] = useState(null);

  // Maker, Checker, Approver state system
  const [workflow, setWorkflow] = useState({
    maker: "Ravi Kumar (Project Engineer)",
    checker: "Suresh Babu (Site Engineer)",
    approver: "Sir (Director)",
    proceedTo: "TSK-003 - PCC Work",
    goBackTo: "TSK-001 - Site Preparation",
    referenceCode: "TSK-003",
    notes: "Inspection to be done by site incharge before proceeding to PCC Work."
  });

  const [selectedTask, setSelectedTask] = useState({
    code: "TSK-002",
    name: "Excavation",
    type: "Internal",
    assignee: "Suresh Babu",
    role: "Site Engineer",
    start: "2026-06-04",
    end: "2026-06-08",
    duration: "5",
    dependentTask: "TSK-001 - Site Preparation",
    depType: "Sequential",
    notes: "Excavation as per approved drawings and levels."
  });

  const addTask = () => {
    const nextNumber = tasks.length + 1;
    const newTaskCode = `TSK-00${nextNumber}`;
    setTasks((current) => [
      ...current,
      { code: newTaskCode, name: "New Task", type: "Internal", assignee: "Ravi Kumar", role: "Project Engineer", start: "2026-06-27", end: "2026-06-30", dependency: "TSK-006", depType: "Sequential", duration: 4, color: "#64748b", left: 86, width: 14 }
    ]);
  };

  const handleTaskClick = (task) => {
    setSelectedTask({
      code: task.code,
      name: task.name,
      type: task.type,
      assignee: task.assignee,
      role: task.role,
      start: task.start,
      end: task.end,
      duration: task.duration,
      dependentTask: task.dependency !== "- None -" ? `${task.dependency} - Task Link` : "",
      depType: task.depType !== "-" ? task.depType : "Sequential",
      notes: ""
    });
  };

  const confirmDelete = (code) => {
    setDeleteCode(code);
    setShowModal(true);
  };

  const deleteTask = () => {
    setTasks((current) => current.filter((task) => task.code !== deleteCode));
    setShowModal(false);
    setDeleteCode(null);
  };

  return (
    <div className="ms-shell-container">
      <Sidebar userRole={userRole} onLogout={onLogout} />

      <div className="ms-shell">
        <header className="ms-topbar">
          <div className="ms-title-wrap">
            <button className="ms-toggle-btn"><Menu size={20} /></button>
            <h1>Create Milestone & Tasks</h1>
          </div>
          <div className="ms-userbar">
            <button className="ms-bell"><Bell size={20} /><span>5</span></button>
            <div className="ms-avatar">RK</div>
            <div className="ms-usercopy">
              <strong>Ravi Kumar</strong>
              <small>Project Manager</small>
            </div>
          </div>
        </header>

        <main className="ms-main">
          <div className="ms-breadcrumb">
            <span>Home</span> <ChevronRight size={12} />
            <span>Projects</span> <ChevronRight size={12} />
            <strong>Create Milestone & Tasks</strong>
          </div>

          <div className="ms-content">
            {/* ===== MILESTONE DETAILS ===== */}
            <section className="ms-panel">
              <h2 className="ms-section-title">Milestone Details</h2>
              <div className="ms-details-grid">
                <label className="ms-field">
                  <span>Project <b>*</b></span>
                  <select defaultValue="PRJ001 - 50 TPD CBG Plant Construction">
                    <option>PRJ001 - 50 TPD CBG Plant Construction</option>
                  </select>
                </label>
                <label className="ms-field">
                  <span>Milestone Code <b>*</b></span>
                  <div className="ms-input-with-icon locked">
                    <input defaultValue="MLS-001" readOnly className="ms-disabled" />
                    <Lock size={14} className="ms-lock-icon" />
                  </div>
                </label>
                <label className="ms-field">
                  <span>Milestone Title <b>*</b></span>
                  <input defaultValue="Civil Foundation Works" />
                </label>
                <label className="ms-field">
                  <span>Milestone Duration (Days) <b>*</b></span>
                  <input type="number" defaultValue="30" />
                </label>
                <label className="ms-field desc">
                  <span>Milestone Description</span>
                  <textarea defaultValue="All civil foundation related activities for CBG plant project." rows={1} />
                </label>
              </div>
            </section>

            {/* ===== MILESTONE DEPENDENCY ===== */}
            <section className="ms-panel">
              <h2 className="ms-section-title">Milestone Dependency</h2>
              <div className="ms-dependency-grid">
                <label className="ms-field toggle-field">
                  <span>Dependency Available</span>
                  <span className="ms-switch">
                    <input type="checkbox" checked={dependencyAvailable} onChange={() => setDependencyAvailable(!dependencyAvailable)} />
                    <i />
                  </span>
                </label>
                <label className="ms-field">
                  <span>Dependent Milestone <b>*</b></span>
                  <select defaultValue="ML-002 - Civil Construction" disabled={!dependencyAvailable}>
                    <option>ML-002 - Civil Construction</option>
                  </select>
                </label>
                <label className="ms-field">
                  <span>Dependency Type <b>*</b></span>
                  <select defaultValue="Sequential" disabled={!dependencyAvailable}><option>Sequential</option></select>
                </label>
                <label className="ms-field lag">
                  <span>Lag (Days)</span>
                  <input type="number" defaultValue="0" disabled={!dependencyAvailable} />
                </label>
                <p className="ms-dependency-note">
                  <span className="ms-dot" /> This milestone will start after completion of <span className="highlight">ML-002 - Civil Construction.</span>
                </p>
              </div>
            </section>

            {/* ===== SECTION 2: ROW LAYER 1 (TASK DETAILS & DEPENDENCY) ===== */}
            <div className="ms-flex-row-panels">
              {/* Task Details Form Block */}
              <div className="ms-work-panel flex-1">
                <h3>Task Details (For Selected Task)</h3>
                <div className="ms-form-grid two">
                  <label className="ms-field"><span>Task Code <b>*</b></span><input value={selectedTask.code} readOnly /></label>
                  <label className="ms-field"><span>Task Name <b>*</b></span><input value={selectedTask.name} onChange={(e) => setSelectedTask({...selectedTask, name: e.target.value})} /></label>
                </div>
                <div className="ms-radio-row">
                  <strong>Task Type <b>*</b></strong>
                  <label><input type="radio" name="type" checked={selectedTask.type === "Internal"} readOnly /> Internal</label>
                  <label><input type="radio" name="type" checked={selectedTask.type === "External"} readOnly /> External</label>
                </div>
                <label className="ms-field">
                  <span>Assign Employee <b>*</b></span>
                  <div className="ms-token-input">
                    <div className="ms-mini-avatar">{selectedTask.assignee.slice(0, 1)}</div>
                    <span>{selectedTask.assignee} ({selectedTask.role})</span>
                    <span className="ms-token-remove">×</span>
                  </div>
                </label>
                <div className="ms-form-grid three" style={{ marginTop: '10px' }}>
                  <label className="ms-field"><span>Start Date <b>*</b></span><input type="date" value={selectedTask.start} onChange={(e) => setSelectedTask({...selectedTask, start: e.target.value})} /></label>
                  <label className="ms-field"><span>End Date <b>*</b></span><input type="date" value={selectedTask.end} onChange={(e) => setSelectedTask({...selectedTask, end: e.target.value})} /></label>
                </div>
              </div>

              {/* Dynamic Task Dependency Form Block */}
              <div className="ms-work-panel flex-1">
                <h3>Dependency</h3>
                <label className="ms-field toggle-line">
                  <span>Dependency Available</span>
                  <span className="ms-switch">
                    <input type="checkbox" checked={taskDependencyAvailable} onChange={() => setTaskDependencyAvailable(!taskDependencyAvailable)} />
                    <i />
                  </span>
                </label>
                <label className="ms-field">
                  <span>Dependent Task <b>*</b></span>
                  {taskDependencyAvailable ? (
                    <select value={selectedTask.dependentTask} onChange={(e) => setSelectedTask({...selectedTask, dependentTask: e.target.value})}>
                      <option value="">- Select Task -</option>
                      {tasks.filter(t => t.code !== selectedTask.code).map(t => (
                        <option key={t.code} value={`${t.code} - ${t.name}`}>{t.code} - {t.name}</option>
                      ))}
                    </select>
                  ) : (
                    <input value="- None -" readOnly className="ms-disabled" />
                  )}
                </label>
                <label className="ms-field">
                  <span>Dependency Type <b>*</b></span>
                  <select value={selectedTask.depType} onChange={(e) => setSelectedTask({...selectedTask, depType: e.target.value})} disabled={!taskDependencyAvailable}>
                    <option value="Sequential">Sequential</option>
                    <option value="Parallel">Parallel</option>
                  </select>
                </label>
                {taskDependencyAvailable && (
                  <p className="ms-green-note"><span className="ms-dot" /> This task will run dynamically linked to parent configurations.</p>
                )}
              </div>
            </div>

            {/* ===== SECTION 3: ROW LAYER 2 (CHECKLIST & MAKER-CHECKER WORKFLOW) ===== */}
            <div className="ms-flex-row-panels">
              {/* Checklist Section */}
              <div className="ms-work-panel flex-1">
                <div className="ms-panel-title-row">
                  <h3>Checklist (For This Task)</h3>
                  <span className="ms-switch"><input type="checkbox" checked={checklistRequired} onChange={() => setChecklistRequired(!checklistRequired)} /><i /></span>
                </div>
                <div className="ms-checklist-action-row"><button type="button" className="ms-small-add"><Plus size={13} /> Add Item</button></div>
                <table className="ms-mini-table">
                  <thead><tr><th>#</th><th>Checklist Item</th><th>Sequence</th><th>Status</th></tr></thead>
                  <tbody>
                    {checklistRows.map((row, index) => (
                      <tr key={row}><td>{index + 1}</td><td>{row}</td><td><input defaultValue={index + 1} /></td><td><span className="ms-status pending">Pending</span></td></tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Maker Checker Workflow Engine */}
              <div className="ms-work-panel flex-1">
                <div className="ms-panel-title-row">
                  <h3>Process / Workflow System</h3>
                  <span className="ms-switch"><input type="checkbox" checked={processRequired} onChange={() => setProcessRequired(!processRequired)} /><i /></span>
                </div>
                
                {processRequired ? (
                  <div className="ms-workflow-active-layout">
                    <div className="ms-workflow-roles-row">
                      <div className="role-box font-maker"><strong>Maker:</strong> <small>{workflow.maker}</small></div>
                      <div className="role-box font-checker"><strong>Checker:</strong> <small>{workflow.checker}</small></div>
                      <div className="role-box font-approver"><strong>Approver:</strong> <small>{workflow.approver}</small></div>
                    </div>
                    
                    <div className="ms-form-grid two" style={{ marginTop: '10px' }}>
                      <label className="ms-field"><span>If YES {"->"} Proceed To</span>
                        <select value={workflow.proceedTo} onChange={(e) => setWorkflow({...workflow, proceedTo: e.target.value})}>
                          {tasks.map(t => <option key={t.code} value={`${t.code} - ${t.name}`}>{t.code} - {t.name}</option>)}
                        </select>
                      </label>
                      <label className="ms-field"><span>If NO {"->"} Go Back To</span>
                        <select value={workflow.goBackTo} onChange={(e) => setWorkflow({...workflow, goBackTo: e.target.value})}>
                          {tasks.map(t => <option key={t.code} value={`${t.code} - ${t.name}`}>{t.code} - {t.name}</option>)}
                        </select>
                      </label>
                    </div>
                    <label className="ms-field" style={{ marginTop: '8px' }}>
                      <span>Process Notes</span>
                      <textarea value={workflow.notes} onChange={(e) => setWorkflow({...workflow, notes: e.target.value})} rows={1} />
                    </label>
                  </div>
                ) : (
                  <div className="ms-workflow-disabled-msg">Workflow routing is disabled. Task bypasses direct approval logic.</div>
                )}
              </div>
            </div>

            {/* ===== SECTION 4: TASKS MAIN DATA TABLE ===== */}
            <section className="ms-panel">
              <div className="ms-sectionbar">
                <div className="ms-left-actions">
                  <h2 className="ms-section-title">Tasks Management</h2>
                  <button type="button" onClick={addTask} className="ms-add-task-btn"><Plus size={15} /> Add Task</button>
                </div>
                <div className="ms-table-tools">
                  <button type="button"><X size={14} /> Expand All</button>
                  <button type="button"><CalendarDays size={14} /> View as Gantt</button>
                </div>
              </div>

              <div className="ms-table-wrap">
                <table className="ms-task-table">
                  <thead>
                    <tr>
                      <th>#</th>
                      <th>Task Code <b>*</b></th>
                      <th>Task Name <b>*</b></th>
                      <th>Task Type <b>*</b></th>
                      <th>Assign To</th>
                      <th>Duration (Days) <b>*</b></th>
                      <th>Start Date <b>*</b></th>
                      <th>End Date <b>*</b></th>
                      <th>Dependency</th>
                      <th>Dep. Type</th>
                      <th>Checklist Required</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {tasks.map((task, index) => (
                      <tr key={task.code} onClick={() => handleTaskClick(task)} className="ms-clickable-tr" style={{ cursor: "pointer" }}>
                        <td>{index + 1}</td>
                        <td><input value={task.code} readOnly className="ms-table-input-readonly ms-code-input" /></td>
                        <td><input value={task.name} readOnly className="ms-table-input-readonly" /></td>
                        <td><select value={task.type} disabled><option>Internal</option><option>External</option></select></td>
                        <td>
                          <div className="ms-assignee">
                            <div className="ms-mini-avatar">{task.assignee.slice(0, 1)}</div>
                            <span>{task.assignee}<small>{task.role}</small></span>
                          </div>
                        </td>
                        <td><input className="ms-center-input" value={task.duration} readOnly /></td>
                        <td><div className="ms-date-input-wrap"><input value={task.start} readOnly /><CalendarDays size={14} /></div></td>
                        <td><div className="ms-date-input-wrap"><input value={task.end} readOnly /><CalendarDays size={14} /></div></td>
                        <td><select value={task.dependency} disabled><option>{task.dependency}</option></select></td>
                        <td><select value={task.depType} disabled><option>{task.depType}</option></select></td>
                        <td><input type="checkbox" checked={checklistRequired} className="ms-checkbox" disabled /></td>
                        <td>
                          <div className="ms-actions" onClick={(e) => e.stopPropagation()}>
                            <button type="button" className="ms-icon-btn-small edit" onClick={() => handleTaskClick(task)}><Edit size={14} /></button>
                            <button type="button" className="ms-icon-btn-small danger" onClick={() => confirmDelete(task.code)}><Trash2 size={14} /></button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </section>

            {/* ===== SECTION 5: GANTT PREVIEW ===== */}
            <section className="ms-panel ms-gantt-panel">
              <h3>Gantt Preview (Milestone Duration: 30 Days)</h3>
              <div className="ms-gantt">
                <div className="ms-gantt-table-side">
                  <table>
                    <thead><tr><th>Task Code</th><th>Task Name</th><th>Duration</th></tr></thead>
                    <tbody>
                      {tasks.slice(0, 6).map((task) => (
                        <tr key={task.code}><td><span className="ms-code-badge">{task.code}</span></td><td>{task.name}</td><td>{task.duration}</td></tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                <div className="ms-chart">
                  <div className="ms-month">June 2026</div>
                  <div className="ms-days">{Array.from({ length: 30 }, (_, i) => <span key={i}>{String(i + 1).padStart(2, "0")}</span>)}</div>
                  <div className="ms-bars">
                    {tasks.slice(0, 6).map((task, index) => (
                      <div className="ms-bar-row" key={task.code}>
                        <span className="ms-bar" style={{ left: `${task.left}%`, width: `${task.width}%`, background: task.color }} />
                        {index < 4 && <div className={`gantt-line line-${index + 1}`} />}
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </section>
          </div>
        </main>

        {/* ===== STICKY FOOTER ACTION ACTIONS BAR ===== */}
        <div className="ms-footer">
          <button type="button" className="ms-btn secondary">Cancel</button>
          <button type="button" className="ms-btn tertiary"><Save size={16} /> Save Draft</button>
          <button type="button" className="ms-btn primary"><Save size={16} /> Save Milestone</button>
        </div>
      </div>

      {/* Delete Confirmation Modal Dialog */}
      {showModal && (
        <div className="ms-modal-overlay" onClick={() => setShowModal(false)}>
          <div className="ms-modal" onClick={(e) => e.stopPropagation()}>
            <div className="ms-modal-header">
              <h3>Confirm Delete</h3>
              <button className="ms-modal-close" onClick={() => setShowModal(false)}><X size={18} /></button>
            </div>
            <div className="ms-modal-body">
              <p>Are you sure you want to delete task {deleteCode}?</p>
              <p className="ms-modal-warning">This action cannot be undone!</p>
            </div>
            <div className="ms-modal-footer">
              <button className="ms-btn secondary" onClick={() => setShowModal(false)}>Cancel</button>
              <button className="ms-btn danger" onClick={deleteTask}><Trash2 size={14} /> Delete</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default MilestoneCreation;