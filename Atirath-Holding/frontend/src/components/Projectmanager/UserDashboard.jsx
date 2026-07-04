import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Calendar, Building2, CheckCircle2, AlertCircle, ClipboardCheck, CheckSquare, ArrowRight, ChevronDown } from 'lucide-react';
import Sidebar from '../Sidebar'; 
import Header from '../Header'; // <--- Dynamic Header
import '../../styles/userDashboard.css';

const UserDashboard = ({ onLogout }) => {
  const navigate = useNavigate();
  const [timeFilter, setTimeFilter] = useState('this-month');

  const taskData = {
    'this-week': {
      overall: 45,
      completed: { count: 9, percent: 45, color: 'success', hex: '#198754' },
      inProgress: { count: 5, percent: 25, color: 'primary', hex: '#0d6efd' },
      underReview: { count: 3, percent: 15, color: 'warning', hex: '#ffc107' },
      pending: { count: 2, percent: 10, color: 'purple', hex: '#6f42c1' },
      overdue: { count: 1, percent: 5, color: 'danger', hex: '#dc3545' }
    },
    'this-month': {
      overall: 64,
      completed: { count: 32, percent: 64, color: 'success', hex: '#198754' },
      inProgress: { count: 12, percent: 24, color: 'primary', hex: '#0d6efd' },
      underReview: { count: 4, percent: 8, color: 'warning', hex: '#ffc107' },
      pending: { count: 1, percent: 2, color: 'purple', hex: '#6f42c1' },
      overdue: { count: 1, percent: 2, color: 'danger', hex: '#dc3545' }
    },
    'last-month': {
      overall: 82,
      completed: { count: 41, percent: 82, color: 'success', hex: '#198754' },
      inProgress: { count: 4, percent: 8, color: 'primary', hex: '#0d6efd' },
      underReview: { count: 2, percent: 4, color: 'warning', hex: '#ffc107' },
      pending: { count: 2, percent: 4, color: 'purple', hex: '#6f42c1' },
      overdue: { count: 1, percent: 2, color: 'danger', hex: '#dc3545' }
    },
    'this-year': {
      overall: 75,
      completed: { count: 150, percent: 75, color: 'success', hex: '#198754' },
      inProgress: { count: 20, percent: 10, color: 'primary', hex: '#0d6efd' },
      underReview: { count: 10, percent: 5, color: 'warning', hex: '#ffc107' },
      pending: { count: 10, percent: 5, color: 'purple', hex: '#6f42c1' },
      overdue: { count: 10, percent: 5, color: 'danger', hex: '#dc3545' }
    }
  };

  const currentData = taskData[timeFilter];

  const getDynamicGradient = () => {
    const c = currentData.completed.percent;
    const i = c + currentData.inProgress.percent;
    const u = i + currentData.underReview.percent;
    const p = u + currentData.pending.percent;
    
    return `conic-gradient(
      ${currentData.completed.hex} 0% ${c}%, 
      ${currentData.inProgress.hex} ${c}% ${i}%, 
      ${currentData.underReview.hex} ${i}% ${u}%, 
      ${currentData.pending.hex} ${u}% ${p}%, 
      ${currentData.overdue.hex} ${p}% 100%
    )`;
  };

  return (
    <div className="dashboard-shell-container">
      {/* Sidebar Navigation */}
      <Sidebar userRole="Site Engineer" onLogout={onLogout} />

      {/* Main Container Viewport (Fixes Layout Shift) */}
      <div className="dashboard-shell">
        
        {/* ======================= DYNAMIC HEADER ======================= */}
        <Header 
          title="User Dashboard" 
          showSearch={false} 
          userName="Ravi Kumar" 
          userRole="Site Engineer" 
          initials="RK" 
        />

        <main className="dashboard-main">
          <div className="row g-4 mt-1">
            {/* TO-DO List */}
            <div className="col-md-6">
              <div className="ud-card h-100 d-flex flex-column">
                <div className="d-flex justify-content-between align-items-center mb-3">
                  <h6 className="fw-bold d-flex align-items-center gap-2 m-0 text-uppercase">
                    <CheckSquare size={18} className="text-success" /> To-Do List
                  </h6>
                  <a href="#" className="text-primary text-decoration-none small fw-semibold">View all</a>
                </div>
                <div className="todo-list flex-grow-1">
                  {[
                    { task: "Update excavation progress", id: "PRJ-001 • Excavation Work", priority: "High", date: "Today", pColor: "danger" },
                    { task: "Upload PCC inspection report", id: "PRJ-001 • PCC Work", priority: "Medium", date: "Today", pColor: "warning" },
                    { task: "Complete safety checklist", id: "PRJ-005 • Safety", priority: "Low", date: "30 May 2025", pColor: "success" },
                    { task: "Submit daily progress report", id: "PRJ-001 • Daily Reporting", priority: "Medium", date: "31 May 2025", pColor: "warning" },
                  ].map((item, index) => (
                    <div key={index} className="todo-item d-flex align-items-center justify-content-between">
                      <div className="d-flex align-items-start gap-3">
                        <input type="checkbox" className="form-check-input mt-1 cursor-pointer" />
                        <div>
                          <p className="mb-0 fw-semibold">{item.task}</p>
                          <small className="text-muted">{item.id}</small>
                        </div>
                      </div>
                      <div className="d-flex align-items-center gap-3">
                        <span className={`badge bg-${item.pColor}-subtle text-${item.pColor} rounded-pill px-3 py-2`}>{item.priority}</span>
                        <small className="text-muted d-flex align-items-center gap-1"><Calendar size={14} /> {item.date}</small>
                      </div>
                    </div>
                  ))}
                </div>
                <div className="text-center mt-auto pt-3 border-top">
                  <a href="#" className="text-primary text-decoration-none fw-semibold small">View full to-do list <ArrowRight size={14}/></a>
                </div>
              </div>
            </div>

            {/* Upcoming Tasks */}
            <div className="col-md-6">
              <div className="ud-card h-100 d-flex flex-column">
                <div className="d-flex justify-content-between align-items-center mb-3">
                  <h6 className="fw-bold d-flex align-items-center gap-2 m-0 text-uppercase">
                    <Calendar size={18} className="text-primary" /> Upcoming Tasks
                  </h6>
                  <a href="#" className="text-primary text-decoration-none small fw-semibold">View all</a>
                </div>
                <div className="table-responsive flex-grow-1">
                  <table className="table table-borderless table-hover align-middle mb-0 ud-table">
                    <thead className="text-muted small border-bottom">
                      <tr>
                        <th className="pb-2">Task Name</th>
                        <th className="pb-2">Project</th>
                        <th className="pb-2">Due Date</th>
                        <th className="pb-2">Priority</th>
                      </tr>
                    </thead>
                    <tbody>
                      {[
                        { task: "PCC Work", prj: "PRJ-001", date: "02-Jun-2025", priority: "Medium", pColor: "warning" },
                        { task: "Reinforcement Fixing", prj: "PRJ-001", date: "05-Jun-2025", priority: "High", pColor: "danger" },
                        { task: "Equipment Inspection", prj: "PRJ-005", date: "08-Jun-2025", priority: "Medium", pColor: "warning" },
                        { task: "Grouting Work", prj: "PRJ-002", date: "10-Jun-2025", priority: "Low", pColor: "success" },
                        { task: "Pipe Line Testing", prj: "PRJ-005", date: "12-Jun-2025", priority: "Medium", pColor: "warning" },
                      ].map((row, i) => (
                        <tr key={i} className="border-bottom">
                          <td className="fw-semibold py-3">{row.task}</td>
                          <td className="text-muted">{row.prj}</td>
                          <td className="text-muted">{row.date}</td>
                          <td><span className={`badge bg-${row.pColor}-subtle text-${row.pColor} rounded-pill px-3 py-2`}>{row.priority}</span></td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                <div className="text-center mt-auto pt-3">
                  <a href="#" className="text-primary text-decoration-none fw-semibold small">View all upcoming tasks <ArrowRight size={14}/></a>
                </div>
              </div>
            </div>

            {/* My Projects */}
            <div className="col-md-6">
              <div className="ud-card h-100 d-flex flex-column">
                <div className="d-flex justify-content-between align-items-center mb-3">
                  <h6 className="fw-bold d-flex align-items-center gap-2 m-0 text-uppercase">
                    <Building2 size={18} className="text-primary" /> My Projects
                  </h6>
                  <a href="#" className="text-primary text-decoration-none small fw-semibold">View all</a>
                </div>
                <div className="projects-list flex-grow-1">
                  {[
                    { name: "50 TPD CBG Plant Construction", role: "Site Engineer", loc: "Atirath Bio Energy Pvt. Ltd. | Nalgonda Plant", prog: 65, tasks: 8, open: 3, pColor: "success" },
                    { name: "Bio Fertilizer Unit", role: "QA Engineer", loc: "Atirath Bio Energy Pvt. Ltd. | Nalgonda Plant", prog: 40, tasks: 4, open: 2, pColor: "primary" },
                    { name: "CBG Expansion Phase-II", role: "Reviewer", loc: "Atirath Bio Energy Pvt. Ltd. | Nalgonda Plant", prog: 25, tasks: 5, open: 1, pColor: "purple" },
                  ].map((prj, i) => (
                    <div key={i} className="project-item d-flex align-items-center py-3 border-bottom">
                      <div className="prj-img me-3"></div>
                      <div className="flex-grow-1">
                        <h6 className="mb-1 fw-bold fs-6">{prj.name}</h6>
                        <small className="text-muted d-block mb-1">{prj.loc}</small>
                        <small className="text-muted">Role: <strong>{prj.role}</strong></small>
                      </div>
                      <div className="d-flex align-items-center gap-4 text-center">
                        <div>
                          <div className={`circular-progress text-${prj.pColor}`}>{prj.prog}%</div>
                          <small className="text-muted mt-1 d-block" style={{fontSize: '10px'}}>Progress</small>
                        </div>
                        <div>
                          <h5 className="mb-0 fw-bold">{prj.tasks}</h5>
                          <small className="text-muted" style={{fontSize: '10px'}}>Tasks Assigned</small>
                        </div>
                        <div>
                          <h5 className="mb-0 fw-bold">{prj.open}</h5>
                          <span className="badge bg-success-subtle text-success mt-1 rounded-pill px-2" style={{fontSize: '10px'}}>In Progress</span>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
                <div className="text-center mt-auto pt-3">
                  <a href="#" className="text-primary text-decoration-none fw-semibold small">View all projects <ArrowRight size={14}/></a>
                </div>
              </div>
            </div>

            {/* Task Completion Overview */}
            <div className="col-md-6">
              <div className="ud-card h-100 d-flex flex-column">
                <div className="d-flex justify-content-between align-items-center mb-4">
                  <h6 className="fw-bold d-flex align-items-center gap-2 m-0 text-uppercase">
                    <CheckCircle2 size={18} className="text-secondary" /> Task Completion Overview
                  </h6>
                  
                  <select 
                    className="form-select form-select-sm w-auto bg-light border-0 fw-semibold cursor-pointer" 
                    value={timeFilter}
                    onChange={(e) => setTimeFilter(e.target.value)}
                  >
                    <option value="this-week">This Week</option>
                    <option value="this-month">This Month</option>
                    <option value="last-month">Last Month</option>
                    <option value="this-year">This Year</option>
                  </select>
                </div>
                
                <div className="d-flex align-items-center justify-content-around my-auto py-3">
                  <div className="donut-chart-container">
                    <div className="donut-chart" style={{ background: getDynamicGradient() }}>
                      <div className="donut-inner">
                        <h2 className="fw-bold mb-0 fs-1">{currentData.overall}%</h2>
                        <small className="text-muted text-center" style={{fontSize: '13px'}}>Overall<br/>Completion</small>
                      </div>
                    </div>
                  </div>
                  
                  <div className="chart-legend">
                    <div className="legend-item"><span className="dot bg-success"></span><span className="l-text">Completed</span><span className="l-val text-success fw-bold">{currentData.completed.count} ({currentData.completed.percent}%)</span></div>
                    <div className="legend-item"><span className="dot bg-primary"></span><span className="l-text">In Progress</span><span className="l-val text-primary fw-bold">{currentData.inProgress.count} ({currentData.inProgress.percent}%)</span></div>
                    <div className="legend-item"><span className="dot bg-warning"></span><span className="l-text">Under Review</span><span className="l-val text-warning fw-bold">{currentData.underReview.count} ({currentData.underReview.percent}%)</span></div>
                    <div className="legend-item"><span className="dot bg-purple"></span><span className="l-text">Pending</span><span className="l-val text-purple fw-bold">{currentData.pending.count} ({currentData.pending.percent}%)</span></div>
                    <div className="legend-item"><span className="dot bg-danger"></span><span className="l-text">Overdue</span><span className="l-val text-danger fw-bold">{currentData.overdue.count} ({currentData.overdue.percent}%)</span></div>
                  </div>
                </div>
                
                <div className="text-center mt-auto pt-3 border-top">
                  <a href="#" className="text-primary text-decoration-none fw-semibold small">View detailed report <ArrowRight size={14}/></a>
                </div>
              </div>
            </div>
          </div>

          {/* Bottom Summary Cards */}
          <div className="row row-cols-1 row-cols-md-3 row-cols-xl-5 g-3 mt-3 mb-4">
            {[
              { icon: Building2, val: 3, label: "My Projects", link: "View projects", path: "/projects", cardBg: "ud-card-green", iconColor: "text-success bg-success-subtle" },
              { icon: ClipboardCheck, val: 14, label: "My Tasks", link: "View tasks", path: "/my-tasks", cardBg: "ud-card-blue", iconColor: "text-primary bg-primary-subtle" },
              { icon: Calendar, val: 2, label: "Due Today", link: "View today's tasks", path: "/calendar", cardBg: "ud-card-orange", iconColor: "text-warning bg-warning-subtle" },
              { icon: AlertCircle, val: 1, label: "Overdue Tasks", link: "View overdue", path: "/my-tasks", cardBg: "ud-card-red", iconColor: "text-danger bg-danger-subtle" },
              { icon: CheckCircle2, val: 32, label: "Completed Tasks", link: "View completed", path: "/my-tasks", cardBg: "ud-card-purple", iconColor: "text-purple bg-purple-subtle" }
            ].map((card, i) => (
              <div key={i} className="col">
                <div className={`ud-summary-card h-100 d-flex align-items-center gap-3 px-3 py-3 ${card.cardBg}`}>
                  <div className={`icon-box ${card.iconColor}`}>
                    <card.icon size={26} strokeWidth={2.2} />
                  </div>
                  <div className="d-flex flex-column justify-content-center text-start">
                    <h4 className="fw-bolder mb-0 text-dark lh-1">{card.val}</h4>
                    <span className="text-secondary small fw-medium mt-1 mb-2" style={{fontSize: '13px'}}>{card.label}</span>
                    <span onClick={() => navigate(card.path)} className="text-primary text-decoration-none fw-semibold d-flex align-items-center gap-1" style={{fontSize: '12px', letterSpacing: '0.3px', cursor: 'pointer'}}>
                      {card.link} <ArrowRight size={13}/>
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </main>
      </div>
    </div>
  );
};

export default UserDashboard;