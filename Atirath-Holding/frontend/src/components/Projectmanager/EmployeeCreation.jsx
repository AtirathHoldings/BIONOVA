import { useState, useEffect } from "react";
import {
  ArrowLeft,
  Bell,
  ChevronDown,
  ChevronRight,
  Edit,
  Eye,
  EyeOff,
  Menu,
  RefreshCcw,
  Save,
  Trash2,
  User,
  Search,
  X,
  MoreVertical,
  Calendar,
  Mail,
  Phone,
  MapPin,
  Image,
  Lock,
  Plus,
  Building,
  Factory,
  Users,
  Briefcase,
  Upload,
  CheckCircle2,
  FileText
} from "lucide-react";
import Sidebar from "../Sidebar";
import Header from "../Header";
import "../../styles/employeeCreation.css";

const EmployeeCreation = ({ userRole, onLogout }) => {
  // Employees State
  const [employees, setEmployees] = useState(() => {
    const saved = localStorage.getItem("employeesData");
    return saved ? JSON.parse(saved) : [];
  });

  // Departments State (Shared with DepartmentCreation via localStorage)
  const [departments, setDepartments] = useState(() => {
    const saved = localStorage.getItem("departments_user_data");
    return saved ? JSON.parse(saved) : [];
  });

  // Views & UI States
  const [view, setView] = useState("list");
  const [isEditing, setIsEditing] = useState(false);
  const [editId, setEditId] = useState(null);
  const [photo, setPhoto] = useState(null);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [activeActionsMenu, setActiveActionsMenu] = useState(null);

  // Department Modal State
  const [showDeptModal, setShowDeptModal] = useState(false);
  const [deptForm, setDeptForm] = useState({
    code: "",
    name: "",
    description: "",
    status: "Active"
  });

  // Filters State for List Page
  const [filters, setFilters] = useState({
    employeeCode: "",
    employeeName: "",
    company: "",
    plant: "",
    department: "",
    status: ""
  });
  const [searchTriggeredFilters, setSearchTriggeredFilters] = useState({
    employeeCode: "",
    employeeName: "",
    company: "",
    plant: "",
    department: "",
    status: ""
  });

  // Employee Form State
  const [form, setForm] = useState({
    employeeCode: "",
    firstName: "",
    lastName: "",
    gender: "",
    dateOfBirth: "",
    email: "",
    mobile: "",
    bloodGroup: "",
    address: "",
    photoPath: "",
    joiningDate: "",
    role: "",
    company: "",
    plant: "",
    department: "",
    workLocation: "",
    reportingManager: "",
    username: "",
    password: "",
    confirmPassword: "",
    status: ""
  });

  // Sync states to local storage
  useEffect(() => {
    localStorage.setItem("employeesData", JSON.stringify(employees));
  }, [employees]);

  useEffect(() => {
    localStorage.setItem("departments_user_data", JSON.stringify(departments));
  }, [departments]);

  // Handle Input Change for Employee Form
  const handleChange = (e) => {
    const { name, value } = e.target;
    
    // Check if user clicked "+ Create Department"
    if (name === "department" && value === "CREATE_NEW") {
      setShowDeptModal(true);
      return;
    }

    setForm((prev) => ({ ...prev, [name]: value }));
  };

  // Handle Profile Photo Upload
  const handlePhotoChange = (event) => {
    const file = event.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onloadend = () => {
      setPhoto(reader.result);
      setForm((prev) => ({ ...prev, photoPath: reader.result }));
    };
    reader.readAsDataURL(file);
  };

  // Handle New Department Modal Input Change
  const handleDeptChange = (e) => {
    const { name, value } = e.target;
    setDeptForm((prev) => ({ ...prev, [name]: value }));
  };

  // Save New Department from Modal
  const handleSaveNewDepartment = () => {
    if (!deptForm.code.trim() || !deptForm.name.trim()) {
      alert("Department code and name are required.");
      return;
    }

    const codeToCheck = deptForm.code.trim().toUpperCase();
    const isDuplicate = departments.some((dept) => dept.code.toUpperCase() === codeToCheck);

    if (isDuplicate) {
      alert("Department code already exists.");
      return;
    }

    const nextId = departments.length ? Math.max(...departments.map((d) => d.id)) + 1 : 1;
    const newDept = {
      id: nextId,
      code: codeToCheck,
      name: deptForm.name.trim(),
      company: form.company || "Atirath Bio Energy Private Limited", // Associates with selected company
      head: "Admin User",
      employeesCount: 0,
      status: deptForm.status,
      description: deptForm.description.trim()
    };

    setDepartments((prev) => [...prev, newDept]);
    
    // Auto-select newly created department in the employee form
    setForm((prev) => ({ ...prev, department: newDept.name }));
    
    // Reset and close modal
    setDeptForm({ code: "", name: "", description: "", status: "Active" });
    setShowDeptModal(false);
    alert("Department created successfully!");
  };

  // Reset Employee Form
  const handleReset = () => {
    setForm({
      employeeCode: "",
      firstName: "",
      lastName: "",
      gender: "",
      dateOfBirth: "",
      email: "",
      mobile: "",
      bloodGroup: "",
      address: "",
      photoPath: "",
      joiningDate: "",
      role: "",
      company: "",
      plant: "",
      department: "",
      workLocation: "",
      reportingManager: "",
      username: "",
      password: "",
      confirmPassword: "",
      status: ""
    });
    setPhoto(null);
    setShowPassword(false);
    setShowConfirmPassword(false);
  };

  // Save / Submit Employee
  const handleSave = (e) => {
    if (e) e.preventDefault();

    const required = [
      "employeeCode", "firstName", "lastName", "gender", "dateOfBirth",
      "email", "mobile", "address", "joiningDate", "role", "company",
      "plant", "department", "workLocation", "reportingManager",
      "username", "password", "confirmPassword", "status"
    ];

    const missing = required.filter(field => !form[field] || form[field].trim() === "");
    if (missing.length > 0) {
      alert("Please fill all required fields marked with *");
      return;
    }

    if (form.password !== form.confirmPassword) {
      alert("Password and Confirm Password do not match!");
      return;
    }

    const employeeFullName = `${form.firstName.trim()} ${form.lastName.trim()}`;
    const employeeData = {
      id: isEditing ? editId : Date.now(),
      employeeCode: form.employeeCode.trim(),
      employeeName: employeeFullName,
      gender: form.gender,
      mobile: form.mobile.trim(),
      email: form.email.trim(),
      company: form.company,
      plant: form.plant,
      department: form.department,
      role: form.role.trim(),
      reportingManager: form.reportingManager,
      status: form.status,
      dateOfBirth: form.dateOfBirth,
      bloodGroup: form.bloodGroup,
      address: form.address.trim(),
      photoPath: form.photoPath.trim(),
      joiningDate: form.joiningDate,
      workLocation: form.workLocation.trim(),
      username: form.username.trim(),
      password: form.password,
      confirmPassword: form.confirmPassword
    };

    if (isEditing) {
      setEmployees((prev) => prev.map((emp) => (emp.id === editId ? employeeData : emp)));
      alert("Employee updated successfully!");
    } else {
      setEmployees((prev) => [...prev, employeeData]);
      alert("Employee created successfully!");
    }

    setIsEditing(false);
    setEditId(null);
    handleReset();
    setView("list");
  };

  // Edit Action
  const handleEdit = (emp) => {
    const names = emp.employeeName.split(" ");
    const fName = names[0] || "";
    const lName = names.slice(1).join(" ") || "";

    setForm({
      employeeCode: emp.employeeCode || "",
      firstName: fName,
      lastName: lName,
      gender: emp.gender || "",
      dateOfBirth: emp.dateOfBirth || "",
      email: emp.email || "",
      mobile: emp.mobile || "",
      bloodGroup: emp.bloodGroup || "",
      address: emp.address || "",
      photoPath: emp.photoPath || "",
      joiningDate: emp.joiningDate || "",
      role: emp.role || "",
      company: emp.company || "",
      plant: emp.plant || "",
      department: emp.department || "",
      workLocation: emp.workLocation || "",
      reportingManager: emp.reportingManager || "",
      username: emp.username || emp.email || "",
      password: emp.password || "",
      confirmPassword: emp.confirmPassword || emp.password || "",
      status: emp.status || "Active"
    });

    setPhoto(emp.photoPath && emp.photoPath.startsWith("data:") ? emp.photoPath : null);
    setIsEditing(true);
    setEditId(emp.id);
    setView("form");
    setActiveActionsMenu(null);
  };

  // Toggle Status Action
  const handleToggleStatus = (empId) => {
    setEmployees((prev) =>
      prev.map((emp) => {
        if (emp.id === empId) {
          const nextStatus = emp.status === "Active" ? "Inactive" : "Active";
          alert(`Employee is now ${nextStatus}!`);
          return { ...emp, status: nextStatus };
        }
        return emp;
      })
    );
    setActiveActionsMenu(null);
  };

  // Search filter handlers
  const handleFilterChange = (e) => {
    const { name, value } = e.target;
    setFilters((prev) => ({ ...prev, [name]: value }));
  };

  const applySearch = () => {
    setSearchTriggeredFilters({ ...filters });
  };

  const resetFilters = () => {
    const cleared = {
      employeeCode: "", employeeName: "", company: "", plant: "", department: "", status: ""
    };
    setFilters(cleared);
    setSearchTriggeredFilters(cleared);
  };

  // Filter logic
  const filteredEmployees = employees.filter((emp) => {
    const fCode = searchTriggeredFilters.employeeCode.trim().toLowerCase();
    const fName = searchTriggeredFilters.employeeName.trim().toLowerCase();
    const fComp = searchTriggeredFilters.company;
    const fPlant = searchTriggeredFilters.plant;
    const fDept = searchTriggeredFilters.department;
    const fStat = searchTriggeredFilters.status;

    if (fCode && !emp.employeeCode.toLowerCase().includes(fCode)) return false;
    if (fName && !emp.employeeName.toLowerCase().includes(fName)) return false;
    if (fComp && emp.company !== fComp) return false;
    if (fPlant && emp.plant !== fPlant) return false;
    if (fDept && emp.department !== fDept) return false;
    if (fStat && emp.status !== fStat) return false;
    return true;
  });

  return (
    <div className="emp-shell-container">
      <Sidebar userRole={userRole} onLogout={onLogout} />

      <div className="emp-shell">
        <Header 
          title="Employee Master" 
          showSearch={false} 
          userName="Syed Mohammad Johny Basha" 
          userRole="Web Developer" 
          initials="SB" 
        />

        <main className="emp-main" style={{ padding: '24px', position: 'relative' }}>
          
          {view === "form" ? (
            /* ================= VIEW: ADD NEW EMPLOYEE FORM ================= */
            <div className="emp-content" style={{ paddingBottom: '80px', maxWidth: '1280px', margin: '0 auto' }}>
              
              <div className="emp-form-card" style={{ backgroundColor: 'white', borderRadius: '8px', border: '1px solid #e2e8f0', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '20px 24px', borderBottom: '1px solid #e2e8f0', backgroundColor: '#fafbfc' }}>
                  <h2 style={{ fontSize: '20px', fontWeight: '700', color: '#0f172a', margin: 0 }}>
                    {isEditing ? "Edit Employee" : "Add New Employee"}
                  </h2>
                  <button type="button" className="emp-nav-view-btn" onClick={() => {
                    setView("list"); handleReset(); setIsEditing(false); setEditId(null);
                  }}>
                    <ArrowLeft size={15} /> Back to Employee List
                  </button>
                </div>

                <div style={{ padding: '24px' }}>
                  {/* 1. PERSONAL INFORMATION */}
                  <div className="emp-form-section">
                    <h3 className="emp-form-section-title" style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', marginBottom: '20px', borderBottom: '1px solid #e2e8f0', paddingBottom: '12px' }}>
                      Personal Information
                    </h3>
                    <div className="emp-form-row-4">
                      <div className="emp-form-item">
                        <label>Employee Code <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><User size={16} /></span>
                          <input type="text" name="employeeCode" value={form.employeeCode} onChange={handleChange} placeholder="Enter employee code" required />
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>First Name <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><User size={16} /></span>
                          <input type="text" name="firstName" value={form.firstName} onChange={handleChange} placeholder="Enter first name" required />
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Last Name <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><User size={16} /></span>
                          <input type="text" name="lastName" value={form.lastName} onChange={handleChange} placeholder="Enter last name" required />
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Gender <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <select name="gender" value={form.gender} onChange={handleChange} required>
                            <option value="">Select gender</option>
                            <option value="Male">Male</option>
                            <option value="Female">Female</option>
                            <option value="Others">Others</option>
                          </select>
                        </div>
                      </div>
                    </div>

                    <div className="emp-form-row-4" style={{ marginTop: '16px' }}>
                      <div className="emp-form-item">
                        <label>Date of Birth <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Calendar size={16} /></span>
                          <input type="date" name="dateOfBirth" value={form.dateOfBirth} onChange={handleChange} required />
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Email <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Mail size={16} /></span>
                          <input type="email" name="email" value={form.email} onChange={handleChange} placeholder="Enter email id" required />
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Mobile Number <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Phone size={16} /></span>
                          <input type="text" name="mobile" value={form.mobile} onChange={handleChange} placeholder="Enter mobile number" maxLength="10" required />
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Blood Group</label>
                        <div className="emp-input-icon-wrap">
                          <select name="bloodGroup" value={form.bloodGroup} onChange={handleChange}>
                            <option value="">Select blood group</option>
                            <option value="A+">A+</option>
                            <option value="A-">A-</option>
                            <option value="B+">B+</option>
                            <option value="B-">B-</option>
                            <option value="AB+">AB+</option>
                            <option value="AB-">AB-</option>
                            <option value="O+">O+</option>
                            <option value="O-">O-</option>
                          </select>
                        </div>
                      </div>
                    </div>

                    <div className="emp-form-row-2" style={{ marginTop: '16px' }}>
                      <div className="emp-form-item">
                        <label>Address <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon" style={{ alignSelf: "flex-start", marginTop: "14px" }}><MapPin size={16} /></span>
                          <textarea name="address" value={form.address} onChange={handleChange} placeholder="Enter full address" required />
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Photo (URL) / Path</label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon" style={{ alignSelf: "flex-start", marginTop: "14px" }}><Image size={16} /></span>
                          <textarea name="photoPath" value={form.photoPath} onChange={handleChange} placeholder="Enter photo URL or path" />
                        </div>
                        <div className="emp-photo-row-container">
                          <div className="emp-photo-row-preview">
                            {form.photoPath || photo ? (
                              <img src={form.photoPath || photo} alt="" />
                            ) : (
                              <User size={20} />
                            )}
                          </div>
                          <input id="empPhotoUpload" type="file" accept="image/*" onChange={handlePhotoChange} hidden />
                          <button type="button" className="emp-photo-row-upload-btn" onClick={() => document.getElementById("empPhotoUpload").click()}>
                            <Upload size={14} /> Upload File instead
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* 2. EMPLOYMENT INFORMATION */}
                  <div className="emp-form-section" style={{ marginTop: '32px' }}>
                    <h3 className="emp-form-section-title" style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', marginBottom: '20px', borderBottom: '1px solid #e2e8f0', paddingBottom: '12px' }}>
                      Employment Information
                    </h3>
                    <div className="emp-form-row-4">
                      <div className="emp-form-item">
                        <label>Joining Date <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Calendar size={16} /></span>
                          <input type="date" name="joiningDate" value={form.joiningDate} onChange={handleChange} required />
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Role <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Briefcase size={16} /></span>
                          <input type="text" name="role" value={form.role} onChange={handleChange} placeholder="Enter role" required />
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Company <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Building size={16} /></span>
                          <select name="company" value={form.company} onChange={handleChange} required>
                            <option value="">Select company</option>
                            <option value="Atirath Holdings">Atirath Holdings</option>
                            <option value="Atirath Bio Energy Pvt. Ltd.">Atirath Bio Energy Pvt. Ltd.</option>
                            <option value="Exclusive Traders">Exclusive Traders</option>
                          </select>
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Plant <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Factory size={16} /></span>
                          <select name="plant" value={form.plant} onChange={handleChange} required>
                            <option value="">Select plant</option>
                            <option value="Hyderabad Plant">Hyderabad Plant</option>
                            <option value="Bangalore Plant">Bangalore Plant</option>
                            <option value="Pune Plant">Pune Plant</option>
                            <option value="Chennai Plant">Chennai Plant</option>
                          </select>
                        </div>
                      </div>
                    </div>

                    <div className="emp-form-row-4" style={{ marginTop: '16px' }}>
                      <div className="emp-form-item">
                        <label>Department <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Users size={16} /></span>
                          <select name="department" value={form.department} onChange={handleChange} required>
                            <option value="">Select department</option>
                            {/* DYNAMIC DEPARTMENTS FROM STATE/LOCALSTORAGE */}
                            {departments.map((dept) => (
                              <option key={dept.id} value={dept.name}>{dept.name}</option>
                            ))}
                            <option value="CREATE_NEW" style={{ fontWeight: 'bold', color: '#2563eb' }}>
                              + Create Department
                            </option>
                          </select>
                        </div>
                      </div>
                      <div className="emp-form-item emp-span-2">
                        <label>Work Location <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><MapPin size={16} /></span>
                          <input type="text" name="workLocation" value={form.workLocation} onChange={handleChange} placeholder="Enter work location" required />
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Reporting Manager <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><User size={16} /></span>
                          <select name="reportingManager" value={form.reportingManager} onChange={handleChange} required>
                            <option value="">Select reporting manager</option>
                            {/* DYNAMIC REPORTING MANAGERS */}
                            {employees.length > 0 ? employees.map((emp) => (
                               <option key={emp.id} value={emp.employeeName}>{emp.employeeName}</option>
                            )) : (
                               <option value="Admin User">Admin User</option>
                            )}
                          </select>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* 3. LOGIN INFORMATION */}
                  <div className="emp-form-section" style={{ marginTop: '32px' }}>
                    <h3 className="emp-form-section-title" style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', marginBottom: '20px', borderBottom: '1px solid #e2e8f0', paddingBottom: '12px' }}>
                      Login Information
                    </h3>
                    <div className="emp-form-row-3">
                      <div className="emp-form-item">
                        <label>Username (Email) <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Mail size={16} /></span>
                          <input type="email" name="username" value={form.username} onChange={handleChange} placeholder="Enter email id" required />
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Password <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Lock size={16} /></span>
                          <input type={showPassword ? "text" : "password"} name="password" value={form.password} onChange={handleChange} placeholder="Enter password" required />
                          <button type="button" className="emp-input-suffix-btn" onClick={() => setShowPassword(!showPassword)}>
                            {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                          </button>
                        </div>
                      </div>
                      <div className="emp-form-item">
                        <label>Confirm Password <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><Lock size={16} /></span>
                          <input type={showConfirmPassword ? "text" : "password"} name="confirmPassword" value={form.confirmPassword} onChange={handleChange} placeholder="Confirm password" required />
                          <button type="button" className="emp-input-suffix-btn" onClick={() => setShowConfirmPassword(!showConfirmPassword)}>
                            {showConfirmPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* 4. STATUS */}
                  <div className="emp-form-section" style={{ marginTop: '32px' }}>
                    <h3 className="emp-form-section-title" style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', marginBottom: '20px', borderBottom: '1px solid #e2e8f0', paddingBottom: '12px' }}>
                      Status
                    </h3>
                    <div className="emp-form-row-4">
                      <div className="emp-form-item">
                        <label>Employee Status <span className="emp-req-star">*</span></label>
                        <div className="emp-input-icon-wrap">
                          <span className="emp-input-prefix-icon"><CheckCircle2 size={16} /></span>
                          <select name="status" value={form.status} onChange={handleChange} required>
                            <option value="">Select status</option>
                            <option value="Active">Active</option>
                            <option value="Inactive">Inactive</option>
                          </select>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="emp-form-footer" style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', padding: '16px 24px', backgroundColor: '#fafbfc', borderTop: '1px solid #e2e8f0' }}>
                  <button type="button" className="emp-btn secondary" onClick={() => { setView("list"); handleReset(); setIsEditing(false); setEditId(null); }}>
                    Cancel
                  </button>
                  <button type="button" className="emp-btn tertiary" onClick={handleReset}>
                    <RefreshCcw size={14} /> Reset
                  </button>
                  <button type="button" className="emp-btn primary" onClick={handleSave}>
                    <Save size={14} /> {isEditing ? "Update Employee" : "Save Employee"}
                  </button>
                </div>
              </div>
            </div>
          ) : (
            /* ================= VIEW: EMPLOYEE LIST ================= */
            <div className="emp-content" style={{ maxWidth: '1280px', margin: '0 auto' }}>
              <div className="emp-table-panel" style={{ backgroundColor: 'white', borderRadius: '8px', border: '1px solid #e2e8f0', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '20px 24px', borderBottom: '1px solid #e2e8f0' }}>
                  <div>
                    <h2 style={{ fontSize: '18px', fontWeight: '700', color: '#0f172a', margin: 0 }}>Employee List</h2>
                    <p style={{ color: '#64748b', margin: '4px 0 0 0', fontSize: '14px' }}>View and manage all employees</p>
                  </div>
                  <button type="button" className="emp-btn-add-new" onClick={() => { handleReset(); setIsEditing(false); setView("form"); }}>
                    <Plus size={16} /> Add New Employee
                  </button>
                </div>

                <div style={{ display: 'flex', alignItems: 'flex-end', gap: '16px', flexWrap: 'wrap', padding: '20px 24px', borderBottom: '1px solid #e2e8f0', backgroundColor: '#fafbfc' }}>
                  <div style={{ flex: 1, minWidth: '180px' }}>
                    <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', fontWeight: '600', color: '#475569' }}>Employee Code</label>
                    <input type="text" name="employeeCode" value={filters.employeeCode} onChange={handleFilterChange} placeholder="Filter by code" style={{ width: '100%', padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '6px', fontSize: '14px', boxSizing: 'border-box', outline: 'none', height: '40px' }} />
                  </div>
                  <div style={{ flex: 1, minWidth: '180px' }}>
                    <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', fontWeight: '600', color: '#475569' }}>Employee Name</label>
                    <input type="text" name="employeeName" value={filters.employeeName} onChange={handleFilterChange} placeholder="Filter by name" style={{ width: '100%', padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '6px', fontSize: '14px', boxSizing: 'border-box', outline: 'none', height: '40px' }} />
                  </div>
                  <div style={{ flex: 1, minWidth: '180px' }}>
                    <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', fontWeight: '600', color: '#475569' }}>Company</label>
                    <select name="company" value={filters.company} onChange={handleFilterChange} style={{ width: '100%', padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '6px', fontSize: '14px', backgroundColor: 'white', boxSizing: 'border-box', outline: 'none', cursor: 'pointer', height: '40px' }}>
                      <option value="">Select company</option>
                      <option value="Atirath Holdings">Atirath Holdings</option>
                      <option value="Atirath Bio Energy Pvt. Ltd.">Atirath Bio Energy Pvt. Ltd.</option>
                      <option value="Exclusive Traders">Exclusive Traders</option>
                    </select>
                  </div>
                  <div style={{ flex: 1, minWidth: '180px' }}>
                    <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', fontWeight: '600', color: '#475569' }}>Status</label>
                    <select name="status" value={filters.status} onChange={handleFilterChange} style={{ width: '100%', padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '6px', fontSize: '14px', backgroundColor: 'white', boxSizing: 'border-box', outline: 'none', cursor: 'pointer', height: '40px' }}>
                      <option value="">Select status</option>
                      <option value="Active">Active</option>
                      <option value="Inactive">Inactive</option>
                    </select>
                  </div>
                  <div style={{ display: 'flex', gap: '10px', height: '40px' }}>
                    <button type="button" className="emp-filter-btn search" onClick={applySearch}><Search size={15} /> Search</button>
                    <button type="button" className="emp-filter-btn reset" onClick={resetFilters}><RefreshCcw size={15} /> Reset</button>
                  </div>
                </div>

                <div className="emp-table-container" style={{ overflowX: 'auto' }}>
                  <table className="emp-list-table" style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', minWidth: '1200px' }}>
                    <thead style={{ backgroundColor: '#f8fafc', borderBottom: '2px solid #e2e8f0' }}>
                      <tr>
                        <th style={{ width: "50px", padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>#</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Employee Code</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Employee Name</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Gender</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Mobile</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Email</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Company</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Department</th>
                        <th style={{ padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Status</th>
                        <th style={{ textAlign: "center", width: "100px", padding: '14px 16px', fontSize: '11px', color: '#64748b', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.5px' }}>ACTIONS</th>
                      </tr>
                    </thead>
                    <tbody>
                      {filteredEmployees.length === 0 ? (
                        <tr><td colSpan="10" style={{ textAlign: "center", padding: "60px 20px", color: '#64748b', fontSize: '14px' }}>No employee records found. Add a new employee using the button above.</td></tr>
                      ) : (
                        filteredEmployees.map((emp, index) => (
                          <tr key={emp.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{index + 1}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}><span style={{ backgroundColor: '#f1f5f9', padding: '4px 10px', borderRadius: '4px', fontWeight: '600', color: '#0f172a', border: '1px solid #e2e8f0', fontSize: '13px' }}>{emp.employeeCode}</span></td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                {emp.photoPath ? ( <img src={emp.photoPath} alt="" style={{ width: '28px', height: '28px', borderRadius: '50%', objectFit: 'cover', border: '1px solid #e2e8f0' }} /> ) : ( <div style={{ width: '28px', height: '28px', borderRadius: '50%', background: '#e2e8f0', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: '600', color: '#475569' }}>{emp.employeeName.charAt(0)}</div> )}
                                <strong>{emp.employeeName}</strong>
                              </div>
                            </td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{emp.gender}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{emp.mobile}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{emp.email}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{emp.company}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>{emp.department}</td>
                            <td style={{ padding: '14px 16px', fontSize: '14px', color: '#334155' }}>
                              <span style={{ padding: '4px 12px', borderRadius: '12px', fontSize: '12px', fontWeight: '600', display: 'inline-block', backgroundColor: emp.status === 'Active' ? '#dcfce7' : '#fee2e2', color: emp.status === 'Active' ? '#166534' : '#991b1b' }}>{emp.status}</span>
                            </td>
                            <td style={{ position: "relative", padding: '14px 16px', textAlign: 'center' }}>
                              <button type="button" style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#64748b', padding: '4px 8px', borderRadius: '4px' }} onClick={() => setActiveActionsMenu(activeActionsMenu === emp.id ? null : emp.id)} onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f1f5f9'} onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}>
                                <MoreVertical size={18} />
                              </button>
                              {activeActionsMenu === emp.id && (
                                <>
                                  <div className="emp-actions-dropdown-backdrop" onClick={() => setActiveActionsMenu(null)} style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, zIndex: 9 }} />
                                  <div className="emp-actions-dropdown-menu" style={{ position: 'absolute', right: '30px', top: '8px', backgroundColor: 'white', border: '1px solid #e2e8f0', borderRadius: '8px', boxShadow: '0 4px 12px rgba(0,0,0,0.15)', zIndex: 10, display: 'flex', flexDirection: 'column', padding: '4px 0', minWidth: '140px' }}>
                                    <button type="button" style={{ padding: '10px 16px', textAlign: 'left', background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px', color: '#334155', borderRadius: '4px', margin: '2px 4px' }} onClick={() => { alert(`Employee Details:\nName: ${emp.employeeName}\nCode: ${emp.employeeCode}\nDepartment: ${emp.department}\nLocation: ${emp.workLocation || "N/A"}`); setActiveActionsMenu(null); }} onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f1f5f9'} onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}> <Eye size={15} /> View </button>
                                    <button type="button" style={{ padding: '10px 16px', textAlign: 'left', background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px', color: '#334155', borderRadius: '4px', margin: '2px 4px' }} onClick={() => handleEdit(emp)} onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f1f5f9'} onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}> <Edit size={15} /> Edit </button>
                                    <button type="button" style={{ padding: '10px 16px', textAlign: 'left', background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '14px', color: '#ef4444', borderRadius: '4px', margin: '2px 4px' }} onClick={() => handleToggleStatus(emp.id)} onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#fef2f2'} onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}> <Trash2 size={15} /> {emp.status === "Active" ? "Deactivate" : "Activate"} </button>
                                  </div>
                                </>
                              )}
                            </td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
                </div>

                <div className="emp-table-pagination-bar" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '14px 24px', borderTop: '1px solid #e2e8f0', backgroundColor: '#fafbfc' }}>
                  <span className="emp-pagination-info" style={{ fontSize: '14px', color: '#64748b' }}>Showing 1 to {filteredEmployees.length} of {filteredEmployees.length} records</span>
                  <div className="emp-pagination-controls" style={{ display: 'flex', gap: '4px' }}>
                    <button className="emp-pag-btn" disabled style={{ padding: '6px 10px', border: '1px solid #cbd5e1', backgroundColor: 'white', borderRadius: '4px', cursor: 'not-allowed', color: '#94a3b8' }}>{"<"}</button>
                    <button className="emp-pag-btn active" style={{ padding: '6px 14px', border: '1px solid #2563eb', backgroundColor: '#2563eb', color: 'white', borderRadius: '4px', cursor: 'pointer', fontSize: '14px', fontWeight: '600' }}>1</button>
                    <button className="emp-pag-btn" disabled style={{ padding: '6px 10px', border: '1px solid #cbd5e1', backgroundColor: 'white', borderRadius: '4px', cursor: 'not-allowed', color: '#94a3b8' }}>{">"}</button>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* ===================== DEPARTMENT CREATION POPUP MODAL ===================== */}
          {showDeptModal && (
            <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.5)', zIndex: 999, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <div style={{ backgroundColor: 'white', borderRadius: '8px', width: '500px', maxWidth: '95%', boxShadow: '0 10px 25px rgba(0,0,0,0.2)', overflow: 'hidden' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 24px', borderBottom: '1px solid #e2e8f0', backgroundColor: '#fafbfc' }}>
                  <h3 style={{ margin: 0, fontSize: '16px', fontWeight: '700', color: '#0f172a' }}>Add New Department</h3>
                  <button onClick={() => { setShowDeptModal(false); setForm(p => ({ ...p, department: "" })); }} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#64748b' }}>
                    <X size={18} />
                  </button>
                </div>
                
                <div style={{ padding: '24px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
                  <div className="emp-form-item">
                    <label>Department Code <span className="emp-req-star">*</span></label>
                    <div className="emp-input-icon-wrap">
                      <span className="emp-input-prefix-icon"><Calendar size={16} /></span>
                      <input type="text" name="code" value={deptForm.code} onChange={handleDeptChange} placeholder="Enter department code" required />
                    </div>
                  </div>
                  <div className="emp-form-item">
                    <label>Department Name <span className="emp-req-star">*</span></label>
                    <div className="emp-input-icon-wrap">
                      <span className="emp-input-prefix-icon"><Building size={16} /></span>
                      <input type="text" name="name" value={deptForm.name} onChange={handleDeptChange} placeholder="Enter department name" required />
                    </div>
                  </div>
                  <div className="emp-form-item">
                    <label>Description</label>
                    <div className="emp-input-icon-wrap">
                      <span className="emp-input-prefix-icon" style={{ alignSelf: "flex-start", marginTop: "14px" }}><FileText size={16} /></span>
                      <textarea name="description" value={deptForm.description} onChange={handleDeptChange} placeholder="Enter description (optional)" rows={3} style={{ height: "80px" }} />
                    </div>
                  </div>
                  <div className="emp-form-item">
                    <label>Status</label>
                    <div className="emp-input-icon-wrap">
                      <select name="status" value={deptForm.status} onChange={handleDeptChange}>
                        <option value="Active">Active</option>
                        <option value="Inactive">Inactive</option>
                      </select>
                    </div>
                  </div>
                </div>

                <div style={{ padding: '16px 24px', borderTop: '1px solid #e2e8f0', display: 'flex', justifyContent: 'flex-end', gap: '12px', backgroundColor: '#fafbfc' }}>
                  <button type="button" onClick={() => { setShowDeptModal(false); setForm(p => ({ ...p, department: "" })); }} style={{ padding: '8px 16px', background: 'white', border: '1px solid #cbd5e1', borderRadius: '6px', color: '#475569', cursor: 'pointer', fontWeight: '500' }}>
                    Cancel
                  </button>
                  <button type="button" onClick={handleSaveNewDepartment} style={{ padding: '8px 16px', background: '#2563eb', color: 'white', border: 'none', borderRadius: '6px', cursor: 'pointer', fontWeight: '500', display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <Save size={14} /> Save Department
                  </button>
                </div>
              </div>
            </div>
          )}
        </main>
      </div>
    </div>
  );
};

export default EmployeeCreation;