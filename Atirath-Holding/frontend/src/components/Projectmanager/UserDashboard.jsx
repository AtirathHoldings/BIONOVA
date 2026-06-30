import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Calendar, Building2, CheckCircle2, AlertCircle, ClipboardCheck, CheckSquare, ArrowRight } from 'lucide-react';
import Sidebar from '../Sidebar'; 
import Header from '../Header';
import '../../styles/userDashboard.css';

const API_BASE = (import.meta.env.VITE_API_BASE_URL) + "/api";
const getAuthToken = () => sessionStorage.getItem("authToken") || "";
const authHeaders = () => ({
  "Content-Type": "application/json",
  "Authorization": `Bearer ${getAuthToken()}`
});

const UserDashboard = ({ onLogout }) => {
  const navigate = useNavigate();
  const [dashboardData, setDashboardData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchDashboardData = async () => {
      setLoading(true);
      try {
        const res = await fetch(`${API_BASE}/user-dashboard`, { headers: authHeaders() });
        if (res.ok) {
          const data = await res.json();
          setDashboardData(data);
        } else {
          setError("Failed to fetch user dashboard data");
        }
      } catch (err) {
        console.error("Error loading user dashboard:", err);
        setError("Network error loading dashboard");
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

  const getInitials = (name) => {
    if (!name) return "U";
    const parts = name.split(" ");
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0].substring(0, 2).toUpperCase();
  };

  const formatDate = (dateStr) => {
    if (!dateStr) return "N/A";
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return dateStr;
    const day = String(d.getDate()).padStart(2, '0');
    const month = d.toLocaleDateString('en-GB', { month: 'short' });
    const year = d.getFullYear();
    return `${day} ${month} ${year}`;
  };

  const getPriorityColor = (priority) => {
    const p = (priority || "").toLowerCase();
    if (p === 'high') return 'danger';
    if (p === 'medium') return 'warning';
    return 'success';
  };

  if (loading) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f8fafc', color: '#64748b' }}>
        <div style={{ textAlign: 'center' }}>
          <h4>Loading Dashboard...</h4>
          <p>Please wait while we fetch your assigned tasks and projects.</p>
        </div>
      </div>
    );
  }

  if (error || !dashboardData) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f8fafc', color: '#ef4444' }}>
        <div style={{ textAlign: 'center', maxWidth: '400px', padding: '20px' }}>
          <h4>Access Error</h4>
          <p>{error || "No dashboard data available. Please verify your login session."}</p>
          <button className="btn btn-primary btn-sm mt-3" onClick={() => navigate("/")}>Go to Login</button>
        </div>
      </div>
    );
  }

  // Calculate percentages for donut chart
  const completedCount = dashboardData.taskStatusCounts?.["Completed"] || 0;
  const inProgressCount = dashboardData.taskStatusCounts?.["In Progress"] || 0;
  const underReviewCount = dashboardData.taskStatusCounts?.["Under Review"] || 0;
  const pendingCount = dashboardData.taskStatusCounts?.["Pending"] || 0;
  const overdueCount = dashboardData.taskStatusCounts?.["Overdue"] || 0;

  const totalTasks = completedCount + inProgressCount + underReviewCount + pendingCount + overdueCount;

  const completedPercent = totalTasks > 0 ? Math.round((completedCount / totalTasks) * 100) : 0;
  const inProgressPercent = totalTasks > 0 ? Math.round((inProgressCount / totalTasks) * 100) : 0;
  const underReviewPercent = totalTasks > 0 ? Math.round((underReviewCount / totalTasks) * 100) : 0;
  const pendingPercent = totalTasks > 0 ? Math.round((pendingCount / totalTasks) * 100) : 0;
  const overduePercent = totalTasks > 0 ? Math.round((overdueCount / totalTasks) * 100) : 0;

  const getDynamicGradient = () => {
    const c = completedPercent;
    const i = c + inProgressPercent;
    const u = i + underReviewPercent;
    const p = u + pendingPercent;
    
    return `conic-gradient(
      #198754 0% ${c}%, 
      #0d6efd ${c}% ${i}%, 
      #ffc107 ${i}% ${u}%, 
      #6f42c1 ${u}% ${p}%, 
      #dc3545 ${p}% 100%
    )`;
  };

  return (
    <div className="dashboard-shell-container">
      {/* Sidebar Navigation */}
      <Sidebar userRole={dashboardData.role || "Site Engineer"} onLogout={onLogout} />

      {/* Main Container Viewport (Fixes Layout Shift) */}
      <div className="dashboard-shell">
        
        {/* ======================= DYNAMIC HEADER ======================= */}
        <Header 
          title="User Dashboard" 
          showSearch={false} 
          userName={dashboardData.fullName || "User"} 
          userRole={dashboardData.role || "Site Engineer"} 
          initials={getInitials(dashboardData.fullName)} 
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
                  <span onClick={() => navigate("/my-tasks")} style={{ cursor: 'pointer' }} className="text-primary text-decoration-none small fw-semibold">View all</span>
                </div>
                <div className="todo-list flex-grow-1">
                  {(!dashboardData.todoList || dashboardData.todoList.length === 0) ? (
                    <div className="text-center py-5 text-muted">No pending to-do tasks. All caught up!</div>
                  ) : (
                    dashboardData.todoList.map((item, index) => {
                      const pColor = getPriorityColor(item.priority);
                      return (
                        <div key={item.taskId || index} className="todo-item d-flex align-items-center justify-content-between">
                          <div className="d-flex align-items-start gap-3">
                            <input type="checkbox" className="form-check-input mt-1 cursor-pointer" />
                            <div>
                              <p className="mb-0 fw-semibold">{item.taskName}</p>
                              <small className="text-muted">{item.projectCodeName || "N/A"}</small>
                            </div>
                          </div>
                          <div className="d-flex align-items-center gap-3">
                            <span className={`badge bg-${pColor}-subtle text-${pColor} rounded-pill px-3 py-2`}>{item.priority}</span>
                            <small className="text-muted d-flex align-items-center gap-1">
                              <Calendar size={14} /> {item.isOverdue ? "Overdue" : (item.isDueToday ? "Today" : formatDate(item.dueDate))}
                            </small>
                          </div>
                        </div>
                      );
                    })
                  )}
                </div>
                <div className="text-center mt-auto pt-3 border-top">
                  <span onClick={() => navigate("/my-tasks")} style={{ cursor: 'pointer' }} className="text-primary text-decoration-none fw-semibold small">View full to-do list <ArrowRight size={14}/></span>
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
                  <span onClick={() => navigate("/my-tasks")} style={{ cursor: 'pointer' }} className="text-primary text-decoration-none small fw-semibold">View all</span>
                </div>
                <div className="table-responsive flex-grow-1">
                  {(!dashboardData.upcomingTasks || dashboardData.upcomingTasks.length === 0) ? (
                    <div className="text-center py-5 text-muted">No upcoming tasks scheduled.</div>
                  ) : (
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
                        {dashboardData.upcomingTasks.map((row, i) => {
                          const pColor = getPriorityColor(row.priority);
                          return (
                            <tr key={row.taskId || i} className="border-bottom">
                              <td className="fw-semibold py-3">{row.taskName}</td>
                              <td className="text-muted">{row.projectCode || "N/A"}</td>
                              <td className="text-muted">{formatDate(row.dueDate)}</td>
                              <td><span className={`badge bg-${pColor}-subtle text-${pColor} rounded-pill px-3 py-2`}>{row.priority}</span></td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  )}
                </div>
                <div className="text-center mt-auto pt-3">
                  <span onClick={() => navigate("/my-tasks")} style={{ cursor: 'pointer' }} className="text-primary text-decoration-none fw-semibold small">View all upcoming tasks <ArrowRight size={14}/></span>
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
                  <span onClick={() => navigate("/projects")} style={{ cursor: 'pointer' }} className="text-primary text-decoration-none small fw-semibold">View all</span>
                </div>
                <div className="projects-list flex-grow-1">
                  {(!dashboardData.myProjects || dashboardData.myProjects.length === 0) ? (
                    <div className="text-center py-5 text-muted">No projects assigned yet.</div>
                  ) : (
                    dashboardData.myProjects.map((prj, i) => {
                      const pColors = ["success", "primary", "purple", "warning"];
                      const pColor = pColors[i % pColors.length];
                      return (
                        <div key={prj.projectId || i} className="project-item d-flex align-items-center py-3 border-bottom" style={{ cursor: 'pointer' }} onClick={() => navigate(`/projects/${prj.projectId}`)}>
                          <div className="prj-img me-3" style={{ width: '120px', height: '80px', borderRadius: '8px', overflow: 'hidden', flexShrink: 0, backgroundColor: '#e9ecef' }}>
                            <img src={prj.projectImage || `https://images.unsplash.com/photo-1541888081638-76508920bc8b?w=400&q=80`} alt={prj.projectName} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                          </div>
                          <div className="flex-grow-1">
                            <h6 className="mb-1 fw-bold" style={{ fontSize: '15px', color: '#1e293b' }}>{prj.projectName}</h6>
                            <small className="d-block mb-1" style={{ color: '#64748b', fontSize: '12px' }}>{prj.clientName} | {prj.plantName}</small>
                            <small style={{ color: '#475569', fontSize: '12px' }}>Role: <strong>{prj.role}</strong></small>
                          </div>
                          <div className="d-flex align-items-center text-center" style={{ gap: '30px' }}>
                            <div>
                              <small className="mb-2 d-block" style={{fontSize: '11px', color: '#64748b', fontWeight: '600'}}>Progress</small>
                              <div className={`circular-progress text-${pColor} mx-auto`} style={{ width: '48px', height: '48px', borderRadius: '50%', border: `3px solid currentColor`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold', fontSize: '14px' }}>
                                {prj.progress}%
                              </div>
                            </div>
                            <div>
                              <small className="mb-2 d-block" style={{fontSize: '11px', color: '#64748b', fontWeight: '600'}}>Tasks Assigned</small>
                              <h5 className="mb-0 fw-bold" style={{ fontSize: '18px', color: '#0f172a' }}>{prj.tasksAssigned}</h5>
                            </div>
                            <div>
                              <small className="mb-2 d-block" style={{fontSize: '11px', color: '#64748b', fontWeight: '600'}}>Open Tasks</small>
                              <h5 className="mb-1 fw-bold" style={{ fontSize: '18px', color: '#0f172a' }}>{prj.openTasks || 0}</h5>
                              <span className="badge bg-success-subtle text-success rounded-pill px-2" style={{fontSize: '10px'}}>{prj.status || 'In Progress'}</span>
                            </div>
                          </div>
                        </div>
                      );
                    })
                  )}
                </div>
                <div className="text-center mt-auto pt-3">
                  <span onClick={() => navigate("/projects")} style={{ cursor: 'pointer' }} className="text-primary text-decoration-none fw-semibold small">View all projects <ArrowRight size={14}/></span>
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
                </div>
                
                <div className="d-flex align-items-center justify-content-around my-auto py-3">
                  <div className="donut-chart-container">
                    <div className="donut-chart" style={{ background: getDynamicGradient() }}>
                      <div className="donut-inner">
                        <h2 className="fw-bold mb-0 fs-1">{Math.round(dashboardData.overallCompletionPercentage)}%</h2>
                        <small className="text-muted text-center" style={{fontSize: '13px'}}>Overall<br/>Completion</small>
                      </div>
                    </div>
                  </div>
                  
                  <div className="chart-legend">
                    <div className="legend-item"><span className="dot bg-success"></span><span className="l-text">Completed</span><span className="l-val text-success fw-bold">{completedCount} ({completedPercent}%)</span></div>
                    <div className="legend-item"><span className="dot bg-primary"></span><span className="l-text">In Progress</span><span className="l-val text-primary fw-bold">{inProgressCount} ({inProgressPercent}%)</span></div>
                    <div className="legend-item"><span className="dot bg-warning"></span><span className="l-text">Under Review</span><span className="l-val text-warning fw-bold">{underReviewCount} ({underReviewPercent}%)</span></div>
                    <div className="legend-item"><span className="dot bg-purple"></span><span className="l-text">Pending</span><span className="l-val text-purple fw-bold">{pendingCount} ({pendingPercent}%)</span></div>
                    <div className="legend-item"><span className="dot bg-danger"></span><span className="l-text">Overdue</span><span className="l-val text-danger fw-bold">{overdueCount} ({overduePercent}%)</span></div>
                  </div>
                </div>
                
                <div className="text-center mt-auto pt-3 border-top">
                  <span onClick={() => navigate("/my-tasks")} style={{ cursor: 'pointer' }} className="text-primary text-decoration-none fw-semibold small">View detailed report <ArrowRight size={14}/></span>
                </div>
              </div>
            </div>
          </div>

          {/* Bottom Summary Cards */}
          <div className="row row-cols-1 row-cols-md-3 row-cols-xl-5 g-3 mt-3 mb-4">
            {[
              { icon: Building2, val: dashboardData.myProjectsCount || 0, label: "My Projects", link: "View projects", path: "/projects", cardBg: "ud-card-green", iconColor: "text-success bg-success-subtle" },
              { icon: ClipboardCheck, val: dashboardData.myTasksCount || 0, label: "My Tasks", link: "View tasks", path: "/my-tasks", cardBg: "ud-card-blue", iconColor: "text-primary bg-primary-subtle" },
              { icon: Calendar, val: dashboardData.dueTodayCount || 0, label: "Due Today", link: "View today's tasks", path: "/calendar", cardBg: "ud-card-orange", iconColor: "text-warning bg-warning-subtle" },
              { icon: AlertCircle, val: dashboardData.overdueTasksCount || 0, label: "Overdue Tasks", link: "View overdue", path: "/my-tasks", cardBg: "ud-card-red", iconColor: "text-danger bg-danger-subtle" },
              { icon: CheckCircle2, val: dashboardData.completedTasksCount || 0, label: "Completed Tasks", link: "View completed", path: "/my-tasks", cardBg: "ud-card-purple", iconColor: "text-purple bg-purple-subtle" }
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