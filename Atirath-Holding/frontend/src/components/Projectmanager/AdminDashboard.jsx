import React, { useState, useEffect } from "react";
import { 
  Building2, Factory, FolderOpen, Users, 
  ClipboardList, Hourglass, Flag, CheckSquare, 
  FileText, Briefcase, Activity, TrendingUp, AlertCircle,
  ChevronRight
} from "lucide-react";
import Sidebar from "../Sidebar"; 
import Header from "../Header";
import "../../styles/admin.css";

const AdminDashboard = ({ userRole, onLogout }) => {

  // ===== DYNAMIC DATA & STATES =====
  const [projFilter, setProjFilter] = useState("All Projects");
  const [mileFilter, setMileFilter] = useState("This Month");
  const [taskFilter, setTaskFilter] = useState("All Tasks");
  
  // Real-time states
  const [employeeCount, setEmployeeCount] = useState(0);
  const [departmentCount, setDepartmentCount] = useState(0);
  
  // User Name State
  const [userName, setUserName] = useState("Syed Mohammad Johny Basha");

  useEffect(() => {
    // 1. Fetch user info from Login Session
    const email = sessionStorage.getItem("userEmail");
    if (email) {
      let namePart = email.split("@")[0];
      namePart = namePart.charAt(0).toUpperCase() + namePart.slice(1);
      
      if(email === "admin@example.com" || email === "admin@atirath.com") {
         setUserName("Syed Mohammad Johny Basha");
      } else {
         setUserName(namePart);
      }
    }

    // 2. Fetch real-time metrics from localStorage
    const savedEmps = JSON.parse(localStorage.getItem("employeesData") || "[]");
    const savedDepts = JSON.parse(localStorage.getItem("departments_user_data") || "[]");
    
    setEmployeeCount(savedEmps.length > 0 ? savedEmps.length : 248);
    setDepartmentCount(savedDepts.length > 0 ? savedDepts.length : 12);

  }, []);

  // Maps for Charts (ERP Data Simulation)
  const projectDataMap = {
    "All Projects": { total: 56, track: 22, progress: 18, risk: 10, delayed: 6, completed: 0 },
    "This Month": { total: 12, track: 6, progress: 3, risk: 2, delayed: 1, completed: 0 },
    "This Year": { total: 84, track: 40, progress: 20, risk: 10, delayed: 4, completed: 10 }
  };

  const milestoneDataMap = {
    "This Month": { total: 124, completed: 84, progress: 28, overdue: 12 },
    "Last Month": { total: 98, completed: 70, progress: 20, overdue: 8 },
    "All Time": { total: 450, completed: 350, progress: 50, overdue: 50 }
  };

  const taskDataMap = {
    "All Tasks": { total: 142, completed: 62, progress: 48, todo: 20, overdue: 12 },
    "This Week": { total: 45, completed: 15, progress: 20, todo: 8, overdue: 2 },
    "This Month": { total: 210, completed: 100, progress: 60, todo: 30, overdue: 20 }
  };

  const pd = projectDataMap[projFilter];
  const md = milestoneDataMap[mileFilter];
  const td = taskDataMap[taskFilter];

  const getProjGradient = () => {
    let p1 = (pd.track / pd.total) * 100;
    let p2 = p1 + (pd.progress / pd.total) * 100;
    let p3 = p2 + (pd.risk / pd.total) * 100;
    let p4 = p3 + (pd.delayed / pd.total) * 100;
    return `conic-gradient(#10b981 0% ${p1}%, #3b82f6 ${p1}% ${p2}%, #f59e0b ${p2}% ${p3}%, #ef4444 ${p3}% ${p4}%, #e2e8f0 ${p4}% 100%)`;
  };

  const getMileGradient = () => {
    let p1 = (md.completed / md.total) * 100;
    let p2 = p1 + (md.progress / md.total) * 100;
    return `conic-gradient(#10b981 0% ${p1}%, #3b82f6 ${p1}% ${p2}%, #ef4444 ${p2}% 100%)`;
  };

  const getTaskGradient = () => {
    let p1 = (td.completed / td.total) * 100;
    let p2 = p1 + (td.progress / td.total) * 100;
    let p3 = p2 + (td.todo / td.total) * 100;
    return `conic-gradient(#10b981 0% ${p1}%, #3b82f6 ${p1}% ${p2}%, #f59e0b ${p2}% ${p3}%, #ef4444 ${p3}% 100%)`;
  };

  return (
    <div className="db-shell-container">
      <Sidebar userRole={userRole} onLogout={onLogout} />

      <div className="db-shell">
        
        {/* ===== INTEGRATED HEADER COMPONENT ===== */}
        <Header 
          title="Dashboard" 
          showSearch={false} 
          userName={userName} 
          userRole="Web Developer" 
          initials="SB" 
        />

        <main className="db-main">
          
          {/* ===== ERP ENTERPRISE KPI GRID ===== */}
          <div className="erp-kpi-grid">
            
            <div className="erp-kpi-card">
              <div className="kpi-header">
                <span className="kpi-title">Workforce Strength</span>
                <div className="kpi-icon-box bg-blue-light"><Users size={16} className="text-blue"/></div>
              </div>
              <div className="kpi-body">
                <h2>{employeeCount}</h2>
                <div className="kpi-footer">
                  <span className="kpi-trend up"><TrendingUp size={12}/> +4.2%</span>
                  <span className="kpi-subtitle">vs last month</span>
                </div>
              </div>
            </div>

            <div className="erp-kpi-card">
              <div className="kpi-header">
                <span className="kpi-title">Active Departments</span>
                <div className="kpi-icon-box bg-purple-light"><Factory size={16} className="text-purple"/></div>
              </div>
              <div className="kpi-body">
                <h2>{departmentCount}</h2>
                <div className="kpi-footer">
                  <span className="kpi-trend neutral"><Activity size={12}/> Stable</span>
                  <span className="kpi-subtitle">operational units</span>
                </div>
              </div>
            </div>

            <div className="erp-kpi-card">
              <div className="kpi-header">
                <span className="kpi-title">Ongoing Projects</span>
                <div className="kpi-icon-box bg-green-light"><FolderOpen size={16} className="text-green"/></div>
              </div>
              <div className="kpi-body">
                <h2>{pd.total}</h2>
                <div className="kpi-footer">
                  <span className="kpi-trend up"><CheckSquare size={12}/> {pd.track} on track</span>
                  <span className="kpi-subtitle">across all divisions</span>
                </div>
              </div>
            </div>

            <div className="erp-kpi-card">
              <div className="kpi-header">
                <span className="kpi-title">Critical Alerts</span>
                <div className="kpi-icon-box bg-red-light"><AlertCircle size={16} className="text-red"/></div>
              </div>
              <div className="kpi-body">
                <h2>{pd.delayed + td.overdue}</h2>
                <div className="kpi-footer">
                  <span className="kpi-trend down"><Hourglass size={12}/> Action Req</span>
                  <span className="kpi-subtitle">delays & overdue tasks</span>
                </div>
              </div>
            </div>

          </div>

          {/* ===== DYNAMIC CHARTS SECTION ===== */}
          <div className="db-charts-grid">
            <div className="db-card">
              <div className="db-card-header">
                <h3>Project Status</h3>
                <select className="db-select" value={projFilter} onChange={(e) => setProjFilter(e.target.value)}>
                  {Object.keys(projectDataMap).map(k => <option key={k} value={k}>{k}</option>)}
                </select>
              </div>
              <div className="db-chart-content">
                <div className="db-donut-chart" style={{ background: getProjGradient() }}>
                  <div className="donut-inner">
                    <h3>{pd.total}</h3>
                    <p>Total</p>
                  </div>
                </div>
                <div className="db-chart-legend">
                  <div className="legend-item"><span className="dot dot-green"></span> On Track <b>{pd.track}</b></div>
                  <div className="legend-item"><span className="dot dot-blue"></span> In Progress <b>{pd.progress}</b></div>
                  <div className="legend-item"><span className="dot dot-orange"></span> At Risk <b>{pd.risk}</b></div>
                  <div className="legend-item"><span className="dot dot-red"></span> Delayed <b>{pd.delayed}</b></div>
                </div>
              </div>
            </div>

            <div className="db-card">
              <div className="db-card-header">
                <h3>Milestone Progress</h3>
                <select className="db-select" value={mileFilter} onChange={(e) => setMileFilter(e.target.value)}>
                  {Object.keys(milestoneDataMap).map(k => <option key={k} value={k}>{k}</option>)}
                </select>
              </div>
              <div className="db-chart-content">
                <div className="db-donut-chart" style={{ background: getMileGradient() }}>
                  <div className="donut-inner">
                    <h3>{Math.round((md.completed / md.total) * 100)}%</h3>
                    <p>Progress</p>
                  </div>
                </div>
                <div className="db-chart-legend milestone-legend">
                  <div className="legend-row"><span>Total</span> <b>{md.total}</b></div>
                  <div className="legend-row"><span>Completed</span> <b className="text-green">{md.completed}</b></div>
                  <div className="legend-row"><span>In Progress</span> <b className="text-blue">{md.progress}</b></div>
                  <div className="legend-row"><span>Overdue</span> <b className="text-red">{md.overdue}</b></div>
                </div>
              </div>
            </div>

            <div className="db-card">
              <div className="db-card-header">
                <h3>Task Overview</h3>
                <select className="db-select" value={taskFilter} onChange={(e) => setTaskFilter(e.target.value)}>
                  {Object.keys(taskDataMap).map(k => <option key={k} value={k}>{k}</option>)}
                </select>
              </div>
              <div className="db-chart-content">
                <div className="db-donut-chart" style={{ background: getTaskGradient() }}>
                  <div className="donut-inner">
                    <h3>{td.total}</h3>
                    <p>Tasks</p>
                  </div>
                </div>
                <div className="db-chart-legend">
                  <div className="legend-item"><span className="dot dot-green"></span> Completed <b>{td.completed}</b></div>
                  <div className="legend-item"><span className="dot dot-blue"></span> In Progress <b>{td.progress}</b></div>
                  <div className="legend-item"><span className="dot dot-orange"></span> To Do <b>{td.todo}</b></div>
                  <div className="legend-item"><span className="dot dot-red"></span> Overdue <b>{td.overdue}</b></div>
                </div>
              </div>
            </div>
          </div>

          {/* ===== LISTS SECTION ===== */}
          <div className="db-lists-grid">
            <div className="db-card list-card">
              <div className="db-card-header">
                <h3>System Activity Log</h3>
                <a href="#" className="view-all">View Log</a>
              </div>
              <div className="db-list">
                <div className="list-item">
                  <div className="list-icon bg-green-light text-green"><Briefcase size={14} /></div>
                  <div className="list-text">
                    <p>Project "CBG Plant - Phase 2" initiated</p>
                    <span>System Admin • 09:15 AM</span>
                  </div>
                </div>
                <div className="list-item">
                  <div className="list-icon bg-blue-light text-blue"><CheckSquare size={14} /></div>
                  <div className="list-text">
                    <p>Milestone "Civil Construction" approved</p>
                    <span>Ravi Kumar • 08:45 AM</span>
                  </div>
                </div>
                <div className="list-item">
                  <div className="list-icon bg-orange-light text-orange"><Activity size={14} /></div>
                  <div className="list-text">
                    <p>Inventory sync completed</p>
                    <span>Auto Process • 04:20 AM</span>
                  </div>
                </div>
                <div className="list-item">
                  <div className="list-icon bg-purple-light text-purple"><Users size={14} /></div>
                  <div className="list-text">
                    <p>Employee master database updated</p>
                    <span>HR Dept • Yesterday, 11:50 AM</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="db-card list-card">
              <div className="db-card-header">
                <h3>Upcoming Deadlines</h3>
                <a href="#" className="view-all">View Schedule</a>
              </div>
              <div className="db-list">
                <div className="list-item deadline-item">
                  <div className="list-icon-clear text-blue"><Flag size={16} fill="currentColor" /></div>
                  <div className="list-text">
                    <p>Mechanical Installation</p>
                    <span>CBG Plant - Phase 2</span>
                  </div>
                  <div className="deadline-date">
                    <strong>25 Jun 2026</strong>
                    <span className="text-orange">5 Days Left</span>
                  </div>
                </div>
                <div className="list-item deadline-item">
                  <div className="list-icon-clear text-green"><CheckSquare size={16} /></div>
                  <div className="list-text">
                    <p>Pipe Line Testing</p>
                    <span>Bio Energy Project</span>
                  </div>
                  <div className="deadline-date">
                    <strong>28 Jun 2026</strong>
                    <span className="text-orange">8 Days Left</span>
                  </div>
                </div>
                <div className="list-item deadline-item">
                  <div className="list-icon-clear text-red"><Flag size={16} fill="currentColor" /></div>
                  <div className="list-text">
                    <p>Commissioning Handover</p>
                    <span>Solar Power Plant</span>
                  </div>
                  <div className="deadline-date">
                    <strong>02 Jul 2026</strong>
                    <span className="text-red">Critical</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="db-card list-card">
              <div className="db-card-header">
                <h3>Top Projects Tracker</h3>
                <a href="#" className="view-all">View Tracker</a>
              </div>
              <div className="db-list project-progress-list">
                <div className="progress-item">
                  <div className="progress-header">
                    <span>CBG Plant - Phase 1</span>
                    <strong>82%</strong>
                  </div>
                  <div className="progress-bar-bg"><div className="progress-fill" style={{ width: "82%" }}></div></div>
                </div>
                <div className="progress-item">
                  <div className="progress-header">
                    <span>CBG Plant - Phase 2</span>
                    <strong>68%</strong>
                  </div>
                  <div className="progress-bar-bg"><div className="progress-fill" style={{ width: "68%" }}></div></div>
                </div>
                <div className="progress-item">
                  <div className="progress-header">
                    <span>Bio Energy Project</span>
                    <strong>54%</strong>
                  </div>
                  <div className="progress-bar-bg"><div className="progress-fill" style={{ width: "54%" }}></div></div>
                </div>
                <div className="progress-item">
                  <div className="progress-header">
                    <span>Solar Power Plant</span>
                    <strong>41%</strong>
                  </div>
                  <div className="progress-bar-bg"><div className="progress-fill" style={{ width: "41%" }}></div></div>
                </div>
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
};

export default AdminDashboard;