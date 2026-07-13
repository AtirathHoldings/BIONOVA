// UserDashboard.jsx - Fixed with full page expansion and sorted upcoming tasks
// ============================================================
// SECTION 1: IMPORTS
// ============================================================

import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";

import {
  Activity,
  AlertTriangle,
  ArrowUpRight,
  Calendar,
  CheckCircle2,
  ClipboardCheck,
  Clock,
  FolderKanban,
  ListTodo,
  Plus,
  Settings,
  Target,
  TrendingUp,
  Users,
  User,
  BarChart3,
  CalendarDays,
  ChevronDown,
  MoreHorizontal,
  MessageSquare,
  Bell,
  Search,
  Filter,
  Menu,
  X,
  Check,
  Eye,
  Play,
  RotateCw,
  Briefcase,
  MapPin,
  Building,
  Heart,
  ShieldCheck,
  Mail,
  Phone,
  Home,
  Star,
  CircleDot,
  Sparkles,
  PieChart,
  Award,
  Zap,
  Clock as ClockIcon,
  FileText,
} from "lucide-react";

import Sidebar from "../Sidebar";
import Header from "../Header";
import AlertModal from "../AlertModal";
import "../../styles/userDashboard.css";

// ============================================================
// SECTION 2: API & CONFIGURATION
// ============================================================

const API_BASE = import.meta.env?.VITE_API_BASE_URL 
  ? `${import.meta.env.VITE_API_BASE_URL}/api` 
  : "http://localhost:8080/api";

const getAuthToken = () => sessionStorage.getItem("authToken") || localStorage.getItem("authToken") || "";

const authHeaders = () => ({
  "Content-Type": "application/json",
  Authorization: `Bearer ${getAuthToken()}`,
});

// ============================================================
// SECTION 3: UTILITY FUNCTIONS
// ============================================================

const getGreeting = () => {
  const hour = new Date().getHours();
  if (hour < 12) return "Good Morning";
  if (hour < 17) return "Good Afternoon";
  return "Good Evening";
};

const getInitials = (name = "") => {
  if (!name) return "U";
  const parts = name.trim().split(" ");
  if (parts.length >= 2) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  return parts[0].substring(0, 2).toUpperCase();
};

const formatDate = (dateValue) => {
  if (!dateValue) return "N/A";
  try {
    const date = new Date(dateValue);
    if (isNaN(date.getTime())) return String(dateValue);
    return date.toLocaleDateString("en-IN", {
      day: "2-digit",
      month: "short",
      year: "numeric",
    });
  } catch {
    return String(dateValue);
  }
};

const getStatusColor = (status) => {
  const s = status?.toUpperCase() || "";
  if (s === 'COMPLETED' || s === 'DONE' || s === 'CLOSED') return '#16a34a';
  if (s === 'IN_PROGRESS' || s === 'WIP' || s === 'ACTIVE') return '#3b82f6';
  if (s === 'UNDER_REVIEW' || s === 'REVIEW' || s === 'SUBMIT_REVIEW') return '#8b5cf6';
  if (s === 'OVERDUE' || s === 'DELAYED' || s === 'OVER_DUE') return '#ef4444';
  if (s === 'REASSIGNED' || s === 'REASSIGN') return '#f59e0b';
  if (s === 'OPEN' || s === 'PENDING' || s === 'NOT_STARTED') return '#f59e0b';
  return '#94a3b8';
};

const getStatusLabel = (status) => {
  const s = status?.toUpperCase() || "";
  if (s === 'COMPLETED' || s === 'DONE' || s === 'CLOSED') return 'Completed';
  if (s === 'IN_PROGRESS' || s === 'WIP' || s === 'ACTIVE') return 'In Progress';
  if (s === 'UNDER_REVIEW' || s === 'REVIEW' || s === 'SUBMIT_REVIEW') return 'Under Review';
  if (s === 'OVERDUE' || s === 'DELAYED' || s === 'OVER_DUE') return 'Overdue';
  if (s === 'REASSIGNED' || s === 'REASSIGN') return 'Reassigned';
  if (s === 'OPEN' || s === 'PENDING' || s === 'NOT_STARTED') return 'Open';
  return 'Open';
};

// ============================================================
// SECTION 4: FALLBACK DATA
// ============================================================

const getFallbackData = () => ({
  fullName: "Employee",
  role: "Staff",
  empId: null,
  taskCounts: {
    assigned: 0,
    open: 0,
    inProgress: 0,
    overdue: 0,
    completed: 0,
  },
  completionRate: 0,
  todoList: [],
  upcomingTasks: [],
  myProjects: [],
  totalProjects: 0,
  recentActivities: [],
  performanceData: {
    tasksCompleted: 0,
    tasksInProgress: 0,
    tasksOverdue: 0,
    efficiency: 100,
    onTimeDelivery: 100,
    qualityScore: 5.0,
  },
});

// ============================================================
// SECTION 5: GREETINGS BANNER COMPONENT
// ============================================================

const GreetingsBanner = ({ userName, onClose }) => {
  const [visible, setVisible] = useState(true);
  const [isExiting, setIsExiting] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => {
      setIsExiting(true);
      setTimeout(() => {
        setVisible(false);
        if (onClose) onClose();
      }, 600);
    }, 2500);

    return () => clearTimeout(timer);
  }, [onClose]);

  if (!visible) return null;

  return (
    <div className={`ud-greetings-banner ${isExiting ? 'exiting' : ''}`}>
      <div className="ud-greetings-content">
        <div className="ud-greetings-icon">
          <Sparkles size={24} />
        </div>
        <div className="ud-greetings-text">
          <h3>{getGreeting()}, {userName}! 👋</h3>
          <p>Welcome back! Have a productive day! 🚀</p>
        </div>
        <button 
          className="ud-greetings-close" 
          onClick={() => {
            setIsExiting(true);
            setTimeout(() => { 
              setVisible(false); 
              if (onClose) onClose(); 
            }, 600);
          }}
        >
          <X size={18} />
        </button>
      </div>
    </div>
  );
};

// ============================================================
// SECTION 6: PIE CHART COMPONENT
// ============================================================

const PieChartComponent = ({ data }) => {
  const total = data.reduce((sum, item) => sum + item.value, 0);
  const size = 160;
  const stroke = 20;
  const radius = (size - stroke) / 2;
  const circumference = 2 * Math.PI * radius;
  
  let currentAngle = 0;
  const filteredData = data.filter(item => item.value > 0);
  
  if (filteredData.length === 0) {
    return (
      <div className="ud-pie-chart-wrapper">
        <div className="ud-empty-state">
          <PieChart size={40} />
          <strong>No data available</strong>
          <span>No tasks to display</span>
        </div>
      </div>
    );
  }
  
  return (
    <div className="ud-pie-chart-wrapper">
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        {filteredData.map((item, index) => {
          const percentage = total > 0 ? (item.value / total) * 100 : 0;
          const dashLength = (percentage / 100) * circumference;
          const offset = -currentAngle * circumference / 100;
          currentAngle += percentage;
          
          return percentage > 0 ? (
            <circle
              key={index}
              cx={size / 2}
              cy={size / 2}
              r={radius}
              fill="none"
              stroke={item.color}
              strokeWidth={stroke}
              strokeDasharray={`${dashLength} ${circumference - dashLength}`}
              strokeDashoffset={offset}
              strokeLinecap="butt"
              transform={`rotate(-90 ${size / 2} ${size / 2})`}
            />
          ) : null;
        })}
        <text 
          x="50%" 
          y="48%" 
          textAnchor="middle" 
          dominantBaseline="middle"
          className="ud-pie-center-value"
        >
          {total}
        </text>
        <text 
          x="50%" 
          y="60%" 
          textAnchor="middle" 
          dominantBaseline="middle"
          className="ud-pie-center-label"
        >
          Total Tasks
        </text>
      </svg>
      <div className="ud-pie-legend">
        {filteredData.map((item, index) => (
          <div className="ud-pie-legend-item" key={index}>
            <span className="ud-pie-legend-dot" style={{ background: item.color }} />
            <span className="ud-pie-legend-label">{item.label}</span>
            <span className="ud-pie-legend-value">{item.value}</span>
          </div>
        ))}
      </div>
    </div>
  );
};

// ============================================================
// SECTION 7: MAIN COMPONENT
// ============================================================

const UserDashboard = ({ userRole, onLogout }) => {
  const navigate = useNavigate();
  
  // 7.1: State Management
  const [loading, setLoading] = useState(true);
  const [dashboardData, setDashboardData] = useState(null);
  const [userName, setUserName] = useState("Employee");
  const [userRoleState, setUserRoleState] = useState("Staff");
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [showAllTasks, setShowAllTasks] = useState(false);
  const [showAllUpcoming, setShowAllUpcoming] = useState(false);
  const [selectedTask, setSelectedTask] = useState(null);
  const [showTaskDetail, setShowTaskDetail] = useState(false);
  const [alertOpen, setAlertOpen] = useState(false);
  const [alertConfig, setAlertConfig] = useState({ type: "success", title: "", message: "" });
  const [showGreeting, setShowGreeting] = useState(true);
  const [updatingTaskId, setUpdatingTaskId] = useState(null);

  // Helper for dynamic star rendering
  const renderStars = (score) => {
    const stars = [];
    const fullStars = Math.floor(score);
    const hasHalf = score % 1 >= 0.4;
    for (let i = 1; i <= 5; i++) {
      if (i <= fullStars) {
        stars.push(<Star key={i} size={16} className="ud-star-filled" />);
      } else if (i === fullStars + 1 && hasHalf) {
        stars.push(<Star key={i} size={16} className="ud-star-half" />);
      } else {
        stars.push(<Star key={i} size={16} style={{ color: '#cbd5e1' }} />);
      }
    }
    return stars;
  };

  // 7.2: Data Fetching
  const fetchDashboardData = async () => {
    setLoading(true);

    try {
      const token = getAuthToken();
      const fallback = getFallbackData();
      let processedData = { ...fallback };

      if (token) {
        const response = await fetch(`${API_BASE}/user-dashboard`, {
          headers: authHeaders()
        });

        if (response.ok) {
          const data = await response.json();

          // Map profile details
          processedData.fullName = data.fullName || "Employee";
          processedData.role = data.role || "Staff";
          
          // Map task status counts
          const sc = data.taskStatusCounts || {};
          const completedCount = sc["Completed"] || 0;
          const wipCount = sc["In Progress"] || 0;
          const overdueCount = sc["Overdue"] || 0;
          const openCount = sc["Open"] || 0;
          const reassignedCount = sc["Reassigned"] || 0;
          const reworkCount = sc["Rework"] || 0;
          const draftCount = sc["Draft"] || 0;
          const underReviewCount = sc["Under Review"] || 0;
          
          processedData.taskCounts = {
            assigned: data.assignedTasksCard?.currentCount || data.myTasksCount || 0,
            open: openCount + reassignedCount + reworkCount + draftCount + underReviewCount,
            inProgress: wipCount,
            overdue: overdueCount,
            completed: completedCount,
          };

          processedData.completionRate = Math.round(data.overallCompletionPercentage || 0);

          // Helper for relative time in activities
          const formatRelativeTime = (dtStr) => {
            if (!dtStr) return "Just now";
            try {
              const diffMs = new Date() - new Date(dtStr);
              const diffMins = Math.floor(diffMs / 60000);
              if (diffMins < 1) return "Just now";
              if (diffMins < 60) return `${diffMins}m ago`;
              const diffHours = Math.floor(diffMins / 60);
              if (diffHours < 24) return `${diffHours}h ago`;
              const diffDays = Math.floor(diffHours / 24);
              return `${diffDays}d ago`;
            } catch {
              return "Recent";
            }
          };

          // Map todoList
          processedData.todoList = (data.todoList || []).map((t, index) => ({
            id: t.taskId || index + 100,
            code: `TSK-${t.taskId || index + 100}`,
            name: t.taskName || "Task",
            project: t.projectCodeName || "Project",
            milestone: "-",
            endDate: t.dueDate,
            startDate: null,
            status: (t.status || "OPEN").toUpperCase(),
            isOverdue: t.overdue || false,
            employees: (t.employees || []).map(e => ({ name: e.fullName, photoUrl: e.photoUrl })),
            priority: t.priority || "Medium",
            description: "",
            rawTask: t,
            isIndividual: t.projectCodeName === "Individual Task"
          }));

          // Map upcomingTasks
          processedData.upcomingTasks = (data.upcomingTasks || []).map((t, index) => ({
            id: t.taskId || index + 100,
            code: `TSK-${t.taskId || index + 100}`,
            name: t.taskName || "Task",
            project: t.projectCode || "Project",
            startDate: t.startDate,
            endDate: t.dueDate,
            status: "OPEN",
            employees: (t.employees || []).map(e => ({ name: e.fullName, photoUrl: e.photoUrl })),
            priority: t.priority || "Medium"
          }));

          // SORT UPCOMING TASKS BY START DATE
          processedData.upcomingTasks.sort((a, b) => {
            if (!a.startDate) return 1;
            if (!b.startDate) return -1;
            return new Date(a.startDate) - new Date(b.startDate);
          });

          // Map performanceData
          processedData.performanceData = {
            tasksCompleted: completedCount,
            tasksInProgress: wipCount,
            tasksOverdue: overdueCount,
            efficiency: data.productivity?.score || 100,
            onTimeDelivery: data.taskCompletion?.score || 100,
            qualityScore: data.qualityScore?.score ? parseFloat((data.qualityScore.score / 20).toFixed(1)) : 5.0,
          };

          // Map myProjects
          processedData.myProjects = (data.myProjects || []).map(p => ({
            id: p.projectId,
            name: p.projectName || "Project",
            status: p.status || "Active",
            progress: p.progress || 0,
            quality: "Good",
            employees: p.tasksAssigned || 0,
            client: p.clientName || "N/A",
            location: p.location || "N/A",
            logo: p.logo
          }));
          processedData.totalProjects = processedData.myProjects.length;

          // Map recent activities
          processedData.recentActivities = (data.recentActivity || []).map(log => ({
            id: log.logId || Math.random(),
            user: "System",
            action: log.message || `Updated ${log.entityTyp} #${log.entityId}`,
            time: formatRelativeTime(log.logDt),
            type: (log.entityTyp || '').toLowerCase() === 'task' ? 'task' : 'project'
          }));
        }
      }

      setDashboardData(processedData);
      setUserName(processedData.fullName || "Employee");
      setUserRoleState(processedData.role || "Staff");

    } catch (err) {
      console.error("Error in dashboard:", err);
      const fallback = getFallbackData();
      setDashboardData(fallback);
      setUserName(fallback.fullName);
      setUserRoleState(fallback.role);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
  }, []);

  // 7.3: Computed Data
  const data = dashboardData || getFallbackData();
  
  const taskCounts = data.taskCounts || {
    assigned: 0,
    open: 0,
    inProgress: 0,
    overdue: 0,
    completed: 0,
  };

  const todoList = data.todoList || [];
  const upcomingTasks = data.upcomingTasks || [];
  const projects = data.myProjects || [];
  const totalProjects = data.totalProjects || projects.length;
  const completionRate = data.completionRate || 0;
  const recentActivities = data.recentActivities || getFallbackData().recentActivities;
  const performanceData = data.performanceData || getFallbackData().performanceData;

  // Sort upcoming tasks by start date (earliest first)
  const sortedUpcomingTasks = [...upcomingTasks].sort((a, b) => {
    if (!a.startDate) return 1;
    if (!b.startDate) return -1;
    return new Date(a.startDate) - new Date(b.startDate);
  });

  const displayedTasks = showAllTasks ? todoList : todoList.slice(0, 5);
  const displayedUpcoming = showAllUpcoming ? sortedUpcomingTasks : sortedUpcomingTasks.slice(0, 5);
  const totalTasks = taskCounts.assigned || 0;

  const pieData = [
    { label: "Completed", value: taskCounts.completed || 0, color: "#16a34a" },
    { label: "In Progress", value: taskCounts.inProgress || 0, color: "#3b82f6" },
    { label: "Open", value: taskCounts.open || 0, color: "#f59e0b" },
    { label: "Overdue", value: taskCounts.overdue || 0, color: "#ef4444" },
  ];

  // 7.4: Event Handlers
  const triggerAlert = (type, title, message) => {
    setAlertConfig({ type, title, message });
    setAlertOpen(true);
  };

  const handleTaskClick = (task) => {
    setSelectedTask(task);
    setShowTaskDetail(true);
  };

  const handleProjectClick = (project) => {
    navigate(`/project-details/${project.id}`);
  };

  const handleStartTask = async (task) => {
    if (updatingTaskId) return;
    
    setUpdatingTaskId(task.id);
    
    try {
      const originalTask = task.rawTask;
      if (originalTask) {
        const updatedTask = {
          ...originalTask,
          taskSts: "WIP",
          stDt: new Date().toISOString().split('T')[0],
        };
        
        const updatePath = task.isIndividual 
          ? `/api/assignments/${task.id}`
          : `/api/task-live/${task.id}`;
        
        const response = await fetch(`${API_BASE}${updatePath}?_t=${Date.now()}`, {
          method: "PUT",
          headers: authHeaders(),
          body: JSON.stringify(updatedTask),
        });

        if (response.ok) {
          setDashboardData(prevData => {
            if (!prevData) return prevData;
            
            const updatedTodoList = prevData.todoList.map(t => {
              if (t.id === task.id) {
                return { 
                  ...t, 
                  status: "WIP", 
                  rawTask: { ...t.rawTask, taskSts: "WIP" },
                  isOverdue: false
                };
              }
              return t;
            });
            
            const newTaskCounts = { ...prevData.taskCounts };
            newTaskCounts.open = Math.max(0, (newTaskCounts.open || 0) - 1);
            newTaskCounts.inProgress = (newTaskCounts.inProgress || 0) + 1;
            
            return {
              ...prevData,
              todoList: updatedTodoList,
              taskCounts: newTaskCounts,
            };
          });
          
          triggerAlert("success", "Started", "Task moved to In Progress.");
          
          setTimeout(() => {
            fetchDashboardData();
          }, 500);
        } else {
          triggerAlert("danger", "Error", "Failed to start task. Please try again.");
        }
      }
    } catch (err) {
      console.error("Error starting task:", err);
      triggerAlert("danger", "Error", "Failed to start task: " + err.message);
    } finally {
      setUpdatingTaskId(null);
    }
  };

  // 7.5: Loading State
  if (loading) {
    return (
      <div className="ud-container">
        <Sidebar userRole={userRoleState} onLogout={onLogout} />
        <div className={`ud-shell ${!sidebarOpen ? 'expanded' : ''}`}>
          <Header 
            title="User Dashboard" 
            showSearch={false} 
            userName={userName} 
            userRole={userRoleState} 
            initials={getInitials(userName)} 
          />
          <main className="ud-main">
            <div className="ud-loading-container">
              <div className="ud-loading-spinner" />
              <p>Loading dashboard...</p>
            </div>
          </main>
        </div>
      </div>
    );
  }

  // ============================================================
  // SECTION 8: RENDER - 4 ROW LAYOUT
  // ============================================================

  return (
    <div className="ud-container">
      <Sidebar userRole={userRoleState} onLogout={onLogout} sidebarOpen={sidebarOpen} />

      <div className={`ud-shell ${!sidebarOpen ? 'expanded' : ''}`}>
        <Header 
          title="User Dashboard" 
          showSearch={false} 
          userName={userName} 
          userRole={userRoleState} 
          initials={getInitials(userName)} 
        />

        <main className="ud-main">
          
          {/* ==========================================================
              ROW 1: GREETINGS BANNER (Sliding from Right)
          ========================================================== */}
          {showGreeting && (
            <GreetingsBanner userName={userName} onClose={() => setShowGreeting(false)} />
          )}


          {/* ==========================================================
              ROW 2: KPI CARDS (6 Cards)
          ========================================================== */}
          <div className="ud-row ud-row-kpi">
            <div className="ud-kpi-grid">
              <div className="ud-kpi-card" onClick={() => navigate("/my-tasks")} style={{ cursor: 'pointer' }}>
                <div className="ud-kpi-icon-wrapper blue"><ListTodo size={20} /></div>
                <div className="ud-kpi-content">
                  <span className="ud-kpi-label">Assigned Tasks</span>
                  <span className="ud-kpi-value">{taskCounts.assigned || 0}</span>
                  <span className="ud-kpi-trend up">↑ {taskCounts.assigned || 0} total</span>
                </div>
              </div>

              <div className="ud-kpi-card" onClick={() => navigate("/my-tasks")} style={{ cursor: 'pointer' }}>
                <div className="ud-kpi-icon-wrapper yellow"><CircleDot size={20} /></div>
                <div className="ud-kpi-content">
                  <span className="ud-kpi-label">Open Tasks</span>
                  <span className="ud-kpi-value">{taskCounts.open || 0}</span>
                  <span className="ud-kpi-trend up">Need attention</span>
                </div>
              </div>

              <div className="ud-kpi-card" onClick={() => navigate("/my-tasks")} style={{ cursor: 'pointer' }}>
                <div className="ud-kpi-icon-wrapper blue-light"><Activity size={20} /></div>
                <div className="ud-kpi-content">
                  <span className="ud-kpi-label">In Progress</span>
                  <span className="ud-kpi-value">{taskCounts.inProgress || 0}</span>
                  <span className="ud-kpi-trend up">Active tasks</span>
                </div>
              </div>

              <div className="ud-kpi-card" onClick={() => navigate("/my-tasks")} style={{ cursor: 'pointer' }}>
                <div className="ud-kpi-icon-wrapper red"><AlertTriangle size={20} /></div>
                <div className="ud-kpi-content">
                  <span className="ud-kpi-label">Overdue Tasks</span>
                  <span className="ud-kpi-value">{taskCounts.overdue || 0}</span>
                  <span className="ud-kpi-trend down">Need action</span>
                </div>
              </div>

              <div className="ud-kpi-card" onClick={() => navigate("/my-tasks")} style={{ cursor: 'pointer' }}>
                <div className="ud-kpi-icon-wrapper green"><CheckCircle2 size={20} /></div>
                <div className="ud-kpi-content">
                  <span className="ud-kpi-label">Completed Tasks</span>
                  <span className="ud-kpi-value">{taskCounts.completed || 0}</span>
                  <span className="ud-kpi-trend up">Well done!</span>
                </div>
              </div>

              <div className="ud-kpi-card" onClick={() => navigate("/projects")} style={{ cursor: 'pointer' }}>
                <div className="ud-kpi-icon-wrapper purple"><FolderKanban size={20} /></div>
                <div className="ud-kpi-content">
                  <span className="ud-kpi-label">My Projects</span>
                  <span className="ud-kpi-value">{totalProjects || 0}</span>
                  <span className="ud-kpi-trend up">Active projects</span>
                </div>
              </div>
            </div>
          </div>

          {/* ==========================================================
              ROW 3: 3 TILES - ToDo List, Upcoming Tasks, My Projects
          ========================================================== */}
          <div className="ud-row ud-row-tiles">
            <div className="ud-main-grid">
              
              {/* Tile 1: My To-Do List */}
              <div className="ud-panel ud-todo-panel">
                <div className="ud-panel-header">
                  <h3>My To-Do List</h3>
                  <div className="ud-panel-actions">
                    <button className="ud-view-all-btn" onClick={() => setShowAllTasks(!showAllTasks)}>
                      {showAllTasks ? 'Show Less' : 'View All'} <ArrowUpRight size={14} />
                    </button>
                  </div>
                </div>
                <div className="ud-todo-table-wrapper">
                  <table className="ud-todo-table">
                    <thead>
                      <tr>
                        <th>Task Name</th>
                        <th>End Date</th>
                        <th>Status</th>
                        <th>Employees</th>
                        <th>Action</th>
                      </tr>
                    </thead>
                    <tbody>
                      {displayedTasks && displayedTasks.length > 0 ? (
                        displayedTasks.map((task, index) => {
                          const isOpen = task.status === "OPEN" || task.status === "PENDING" || task.status === "NOT_STARTED";
                          const isInProgress = task.status === "WIP" || task.status === "IN_PROGRESS";
                          const isCompleted = task.status === "COMPLETED" || task.status === "DONE" || task.status === "CLOSED";
                          
                          return (
                            <tr key={task.id || index} className="ud-todo-row">
                              <td onClick={() => handleTaskClick(task)} style={{ cursor: 'pointer' }}>
                                <div className="ud-task-name">
                                  <span className={`ud-task-indicator ${task.isOverdue ? 'overdue' : ''}`} />
                                  <span className="ud-task-title">{task.name || 'Task'}</span>
                                  <span className="ud-task-project">{task.project || 'Project'}</span>
                                </div>
                              </td>
                              <td onClick={() => handleTaskClick(task)} style={{ cursor: 'pointer' }}>
                                <span className={task.isOverdue ? 'ud-date-overdue' : ''}>
                                  {formatDate(task.endDate)}
                                </span>
                              </td>
                              <td onClick={() => handleTaskClick(task)} style={{ cursor: 'pointer' }}>
                                <span className="ud-status-badge" style={{ backgroundColor: getStatusColor(task.status) }}>
                                  {getStatusLabel(task.status)}
                                </span>
                              </td>
                              <td onClick={() => handleTaskClick(task)} style={{ cursor: 'pointer' }}>
                                <div className="ud-employee-avatars">
                                  {task.employees && task.employees.length > 0 ? (
                                    <>
                                      {task.employees.slice(0, 2).map((emp, i) => (
                                        <span key={i} className="ud-avatar-small" title={emp.name || emp}>
                                          {emp.photoUrl ? (
                                            <img src={emp.photoUrl} alt={emp.name || emp} />
                                          ) : (
                                            getInitials(emp.name || emp)
                                          )}
                                        </span>
                                      ))}
                                      {task.employees.length > 2 && (
                                        <span className="ud-avatar-more">+{task.employees.length - 2}</span>
                                      )}
                                    </>
                                  ) : (
                                    <span className="ud-no-employees">—</span>
                                  )}
                                </div>
                              </td>
                              <td>
                                {isOpen && (
                                  <button 
                                    className="ud-start-btn" 
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      handleStartTask(task);
                                    }}
                                    disabled={updatingTaskId === task.id}
                                  >
                                    {updatingTaskId === task.id ? 'Starting...' : 'Start'}
                                  </button>
                                )}
                                {isInProgress && (
                                  <span className="ud-inprogress-label">In Progress</span>
                                )}
                                {isCompleted && (
                                  <span className="ud-completed-label">✓ Done</span>
                                )}
                              </td>
                            </tr>
                          );
                        })
                      ) : (
                        <tr>
                          <td colSpan="5" className="ud-empty-cell">
                            <div className="ud-empty-state">
                              <CheckCircle2 size={28} />
                              <strong>All caught up!</strong>
                              <span>No pending tasks</span>
                            </div>
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* Tile 2: Upcoming Tasks - Sorted by Start Date */}
              <div className="ud-panel ud-upcoming-panel">
                <div className="ud-panel-header">
                  <h3>Upcoming Tasks</h3>
                  <div className="ud-panel-actions">
                    <button className="ud-view-all-btn" onClick={() => setShowAllUpcoming(!showAllUpcoming)}>
                      {showAllUpcoming ? 'Show Less' : 'View All'} <ArrowUpRight size={14} />
                    </button>
                  </div>
                </div>
                <div className="ud-upcoming-list">
                  {displayedUpcoming && displayedUpcoming.length > 0 ? (
                    displayedUpcoming.map((task, index) => (
                      <div className="ud-upcoming-item" key={task.id || index} onClick={() => handleTaskClick(task)}>
                        <div className="ud-upcoming-date">
                          <span className="ud-upcoming-day">
                            {task.startDate ? new Date(task.startDate).getDate() : '--'}
                          </span>
                          <span className="ud-upcoming-month">
                            {task.startDate ? new Date(task.startDate).toLocaleString('en', { month: 'short' }) : 'N/A'}
                          </span>
                        </div>
                        <div className="ud-upcoming-info">
                          <div className="ud-upcoming-name">{task.name || 'Task'}</div>
                          <div className="ud-upcoming-project">{task.project || 'Project'}</div>
                        </div>
                        <div className="ud-upcoming-employees">
                          {task.employees && task.employees.length > 0 ? (
                            <>
                              {task.employees.slice(0, 2).map((emp, i) => (
                                <span key={i} className="ud-avatar-small" title={emp.name || emp}>
                                  {emp.photoUrl ? (
                                    <img src={emp.photoUrl} alt={emp.name || emp} />
                                  ) : (
                                    getInitials(emp.name || emp)
                                  )}
                                </span>
                              ))}
                              {task.employees.length > 2 && (
                                <span className="ud-avatar-more">+{task.employees.length - 2}</span>
                              )}
                            </>
                          ) : (
                            <span className="ud-no-employees">—</span>
                          )}
                        </div>
                      </div>
                    ))
                  ) : (
                    <div className="ud-empty-state">
                      <Calendar size={28} />
                      <strong>No upcoming tasks</strong>
                      <span>Your schedule is clear.</span>
                    </div>
                  )}
                </div>
              </div>

              {/* Tile 3: My Active Projects */}
              <div className="ud-panel ud-projects-panel">
                <div className="ud-panel-header">
                  <h3>My Active Projects</h3>
                  <div className="ud-panel-actions">
                    <button className="ud-view-all-btn" onClick={() => navigate("/projects")}>
                      View All <ArrowUpRight size={14} />
                    </button>
                  </div>
                </div>
                <div className="ud-projects-list">
                  {projects && projects.length > 0 ? (
                    projects.slice(0, 6).map((project, index) => (
                      <div className="ud-project-item" key={project.id || index} onClick={() => handleProjectClick(project)} style={{ cursor: 'pointer' }}>
                        {project.logo ? (
                          <img src={project.logo} alt={project.name} className="ud-project-logo" />
                        ) : (
                          <div className="ud-project-logo-fallback">
                            <FolderKanban size={16} />
                          </div>
                        )}
                        <div className="ud-project-info">
                          <div className="ud-project-name">{project.name || 'Project'}</div>
                          <div className="ud-project-meta">
                            <span className="ud-project-status" style={{ color: getStatusColor(project.status) }}>
                              {project.status || 'Active'}
                            </span>
                            <span className="ud-project-employees">
                              <Users size={12} /> {project.employees || 0}
                            </span>
                          </div>
                        </div>
                        <div className="ud-project-progress">
                          {project.progress !== undefined && (
                            <>
                              <div className="ud-progress-ring">
                                <svg viewBox="0 0 36 36" className="ud-ring-svg">
                                  <circle cx="18" cy="18" r="15.9" fill="none" stroke="#e2e8f0" strokeWidth="3" />
                                  <circle 
                                    cx="18" cy="18" r="15.9" fill="none" 
                                    stroke={getStatusColor(project.status)}
                                    strokeWidth="3"
                                    strokeDasharray={`${project.progress * 1.0} 100`}
                                    strokeDashoffset="0"
                                    strokeLinecap="round"
                                    transform="rotate(-90 18 18)"
                                  />
                                </svg>
                                <span className="ud-ring-value">{project.progress}%</span>
                              </div>
                              {project.quality && (
                                <span className="ud-project-quality">{project.quality}</span>
                              )}
                            </>
                          )}
                        </div>
                      </div>
                    ))
                  ) : (
                    <div className="ud-empty-state">
                      <FolderKanban size={28} />
                      <strong>No projects</strong>
                      <span>You are not assigned to any projects yet.</span>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>

          {/* ==========================================================
              ROW 4: 3 TILES - Task Progress (Pie), Recent Activity, My Performance
          ========================================================== */}
          <div className="ud-row ud-row-analytics">
            <div className="ud-analytics-grid">
              
              {/* Tile 1: Task Progress (Pie Chart) */}
              <div className="ud-panel ud-progress-pie-panel">
                <div className="ud-panel-header">
                  <h3>Task Progress</h3>
                  <span className="ud-total-tasks-badge">Total: {totalTasks}</span>
                </div>
                <div className="ud-pie-content">
                  <PieChartComponent data={pieData} />
                </div>
              </div>

              {/* Tile 2: Recent Activity */}
              <div className="ud-panel ud-activity-panel">
                <div className="ud-panel-header">
                  <h3>Recent Activity</h3>
                  <button className="ud-view-all-btn" onClick={() => navigate("/activity")}>
                    View All <ArrowUpRight size={14} />
                  </button>
                </div>
                <div className="ud-activity-list">
                  {recentActivities && recentActivities.length > 0 ? (
                    recentActivities.slice(0, 5).map((activity, index) => (
                      <div className="ud-activity-item" key={activity.id || index}>
                        <div className="ud-activity-icon-wrapper">
                          <div className={`ud-activity-icon ${activity.type || 'default'}`}>
                            {activity.type === 'task' ? <CheckCircle2 size={14} /> :
                             activity.type === 'project' ? <FolderKanban size={14} /> :
                             activity.type === 'submission' ? <FileText size={14} /> :
                             <MessageSquare size={14} />}
                          </div>
                          {index < recentActivities.length - 1 && <span className="ud-activity-timeline-line" />}
                        </div>
                        <div className="ud-activity-content">
                          <div className="ud-activity-action">{activity.action}</div>
                          <div className="ud-activity-meta">
                            <span className="ud-activity-user">{activity.user}</span>
                            <span className="ud-activity-time">{activity.time}</span>
                          </div>
                        </div>
                      </div>
                    ))
                  ) : (
                    <div className="ud-empty-state">
                      <Activity size={28} />
                      <strong>No recent activity</strong>
                      <span>Your recent actions will appear here.</span>
                    </div>
                  )}
                </div>
              </div>

              {/* Tile 3: My Performance */}
              <div className="ud-panel ud-performance-panel">
                <div className="ud-panel-header">
                  <h3>My Performance</h3>
                  <div className="ud-performance-rating">
                    {renderStars(performanceData.qualityScore || 5.0)}
                    <span className="ud-rating-text">{performanceData.qualityScore || 5.0}</span>
                  </div>
                </div>
                <div className="ud-performance-content">
                  <div className="ud-performance-stats">
                    <div className="ud-performance-stat">
                      <div className="ud-stat-icon green"><CheckCircle2 size={18} /></div>
                      <div className="ud-stat-info">
                        <span className="ud-stat-value">{performanceData.tasksCompleted || 0}</span>
                        <span className="ud-stat-label">Tasks Completed</span>
                      </div>
                    </div>
                    <div className="ud-performance-stat">
                      <div className="ud-stat-icon blue"><Activity size={18} /></div>
                      <div className="ud-stat-info">
                        <span className="ud-stat-value">{performanceData.tasksInProgress || 0}</span>
                        <span className="ud-stat-label">In Progress</span>
                      </div>
                    </div>
                    <div className="ud-performance-stat">
                      <div className="ud-stat-icon red"><AlertTriangle size={18} /></div>
                      <div className="ud-stat-info">
                        <span className="ud-stat-value">{performanceData.tasksOverdue || 0}</span>
                        <span className="ud-stat-label">Overdue</span>
                      </div>
                    </div>
                  </div>
                  
                  <div className="ud-performance-metrics">
                    <div className="ud-metric-item">
                      <div className="ud-metric-header">
                        <span className="ud-metric-label">Efficiency</span>
                        <span className="ud-metric-value">{performanceData.efficiency || 100}%</span>
                      </div>
                      <div className="ud-metric-bar">
                        <div className="ud-metric-fill" style={{ width: `${performanceData.efficiency || 100}%`, background: '#3b82f6' }} />
                      </div>
                    </div>
                    <div className="ud-metric-item">
                      <div className="ud-metric-header">
                        <span className="ud-metric-label">On-Time Delivery</span>
                        <span className="ud-metric-value">{performanceData.onTimeDelivery || 100}%</span>
                      </div>
                      <div className="ud-metric-bar">
                        <div className="ud-metric-fill" style={{ width: `${performanceData.onTimeDelivery || 100}%`, background: '#16a34a' }} />
                      </div>
                    </div>
                    <div className="ud-metric-item">
                      <div className="ud-metric-header">
                        <span className="ud-metric-label">Quality Score</span>
                        <span className="ud-metric-value">{performanceData.qualityScore || 5.0}/5</span>
                      </div>
                      <div className="ud-metric-bar">
                        <div className="ud-metric-fill" style={{ width: `${(performanceData.qualityScore || 5.0) / 5 * 100}%`, background: '#8b5cf6' }} />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* ==========================================================
              ROW 5: QUICK ACTIONS
          ========================================================== */}
          <div className="ud-row ud-row-actions">
            <div className="ud-quick-actions">
              <h4>Quick Actions</h4>
              <div className="ud-actions-grid">
                <button className="ud-action-btn" onClick={() => navigate("/my-tasks")}>
                  <ListTodo size={20} />
                  <span>My Tasks</span>
                  <small>View all tasks</small>
                </button>
                <button className="ud-action-btn" onClick={() => navigate("/projects")}>
                  <FolderKanban size={20} />
                  <span>My Projects</span>
                  <small>View all projects</small>
                </button>
                <button className="ud-action-btn" onClick={() => navigate("/calendar")}>
                  <CalendarDays size={20} />
                  <span>Calendar</span>
                  <small>View calendar</small>
                </button>
                <button className="ud-action-btn" onClick={() => navigate("/all-project-gantt-chart")}>
                  <BarChart3 size={20} />
                  <span>Gantt View</span>
                  <small>View Gantt chart</small>
                </button>
                <button className="ud-action-btn primary" onClick={() => navigate("/tasks/create")}>
                  <Plus size={20} />
                  <span>Assign Task</span>
                  <small>Assign new task</small>
                </button>
              </div>
            </div>
          </div>

        </main>
      </div>

      {/* ==========================================================
          TASK DETAIL MODAL
      ========================================================== */}
      {showTaskDetail && selectedTask && (
        <div className="ud-modal-overlay" onClick={() => setShowTaskDetail(false)}>
          <div className="ud-modal" onClick={(e) => e.stopPropagation()}>
            <div className="ud-modal-header">
              <h3>Task Details: {selectedTask.code || selectedTask.id}</h3>
              <button className="ud-modal-close" onClick={() => setShowTaskDetail(false)}>
                <X size={18} />
              </button>
            </div>
            <div className="ud-modal-body">
              <div className="ud-detail-row">
                <span className="ud-detail-label">Task Name</span>
                <span className="ud-detail-value">{selectedTask.name || 'Task'}</span>
              </div>
              <div className="ud-detail-row">
                <span className="ud-detail-label">Project</span>
                <span className="ud-detail-value">{selectedTask.project || 'Project'}</span>
              </div>
              <div className="ud-detail-row">
                <span className="ud-detail-label">Milestone</span>
                <span className="ud-detail-value">{selectedTask.milestone || '—'}</span>
              </div>
              <div className="ud-detail-row">
                <span className="ud-detail-label">Status</span>
                <span className="ud-status-badge" style={{ backgroundColor: getStatusColor(selectedTask.status) }}>
                  {getStatusLabel(selectedTask.status)}
                </span>
              </div>
              <div className="ud-detail-row">
                <span className="ud-detail-label">Due Date</span>
                <span className={`ud-detail-value ${selectedTask.isOverdue ? 'ud-date-overdue' : ''}`}>
                  {formatDate(selectedTask.endDate)}
                </span>
              </div>
              <div className="ud-detail-row">
                <span className="ud-detail-label">Priority</span>
                <span className={`ud-priority-badge ${(selectedTask.priority || 'medium').toLowerCase()}`}>
                  {selectedTask.priority || 'Medium'}
                </span>
              </div>
              {selectedTask.description && (
                <div className="ud-detail-row ud-detail-description">
                  <span className="ud-detail-label">Description</span>
                  <span className="ud-detail-value">{selectedTask.description}</span>
                </div>
              )}
            </div>
            <div className="ud-modal-footer">
              {(selectedTask.status === "OPEN" || selectedTask.status === "PENDING" || selectedTask.status === "NOT_STARTED") && (
                <button 
                  className="ud-btn-primary" 
                  onClick={() => { 
                    handleStartTask(selectedTask); 
                    setShowTaskDetail(false); 
                  }}
                  disabled={updatingTaskId === selectedTask.id}
                >
                  <Play size={16} /> {updatingTaskId === selectedTask.id ? 'Starting...' : 'Start Task'}
                </button>
              )}
              <button className="ud-btn-secondary" onClick={() => setShowTaskDetail(false)}>Close</button>
            </div>
          </div>
        </div>
      )}

      <AlertModal 
        isOpen={alertOpen} 
        type={alertConfig.type} 
        title={alertConfig.title} 
        message={alertConfig.message} 
        onClose={() => setAlertOpen(false)} 
      />
    </div>
  );
};

export default UserDashboard;