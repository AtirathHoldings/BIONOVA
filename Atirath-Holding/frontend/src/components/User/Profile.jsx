import { useState, useEffect } from "react";
import Sidebar from "../Sidebar";
import Header from "../Header";
import { 
  User, 
  Camera, 
  ShieldCheck, 
  EyeOff, 
  Eye, 
  Lock,
  ChevronRight,
  Home,
  IdCard,
  Mail,
  Phone,
  Building,
  MapPin,
  Calendar,
  Clock
} from "lucide-react";
import "../../styles/profile.css";

const API_BASE = (import.meta.env.VITE_API_BASE_URL) + "/api";

const authHeaders = () => {
  const token = sessionStorage.getItem("authToken");
  return {
    "Content-Type": "application/json",
    "Authorization": token ? `Bearer ${token}` : ""
  };
};

const Profile = ({ userRole, onLogout }) => {
  const [showCurrentPassword, setShowCurrentPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  // Password fields state
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  // Profile data states
  const [profile, setProfile] = useState(null);

  const handleUpdatePassword = async () => {
    setError("");
    setMessage("");

    if (!currentPassword || !newPassword || !confirmPassword) {
      setError("All password fields are required.");
      return;
    }

    if (newPassword !== confirmPassword) {
      setError("New password and confirm password do not match.");
      return;
    }

    // Password strength regex (min 8 chars, at least one uppercase, one lowercase, one number, one special char)
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
    if (!passwordRegex.test(newPassword)) {
      setError("Password must be at least 8 characters long and include uppercase, lowercase, number and special character.");
      return;
    }

    setLoading(true);
    try {
      const res = await fetch(`${API_BASE}/employees/change-password`, {
        method: "POST",
        headers: authHeaders(),
        body: JSON.stringify({ currentPassword, newPassword })
      });

      const data = await res.json();
      if (res.ok) {
        setMessage(data.message || "Password updated successfully!");
        setCurrentPassword("");
        setNewPassword("");
        setConfirmPassword("");
      } else {
        setError(data.message || "Failed to update password.");
      }
    } catch (err) {
      console.error("Error updating password:", err);
      setError("An error occurred. Please try again.");
    } finally {
      setLoading(false);
    }
  };
  const [companies, setCompanies] = useState([]);
  const [plants, setPlants] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [employees, setEmployees] = useState([]);

  const fetchProfileData = async () => {
    const headers = authHeaders();

    // 1. Fetch companies
    try {
      const res = await fetch(`${API_BASE}/companies`, { headers });
      if (res.ok) setCompanies(await res.json());
    } catch (err) {
      console.error("Error fetching companies:", err);
    }

    // 2. Fetch plants
    try {
      const res = await fetch(`${API_BASE}/plants`, { headers });
      if (res.ok) setPlants(await res.json());
    } catch (err) {
      console.error("Error fetching plants:", err);
    }

    // 3. Fetch departments
    try {
      const res = await fetch(`${API_BASE}/departments`, { headers });
      if (res.ok) setDepartments(await res.json());
    } catch (err) {
      console.error("Error fetching departments:", err);
    }

    // 4. Fetch employees and match profile by logged-in user email
    try {
      const res = await fetch(`${API_BASE}/employees`, { headers });
      if (res.ok) {
        const empData = await res.json();
        setEmployees(empData);
        const loggedInEmail = sessionStorage.getItem("userEmail") || localStorage.getItem("userEmail");
        if (loggedInEmail) {
          const matchedProfile = empData.find(
            (emp) => emp.email && emp.email.toLowerCase().trim() === loggedInEmail.toLowerCase().trim()
          );
          if (matchedProfile) {
            setProfile(matchedProfile);
          }
        }
      }
    } catch (err) {
      console.error("Error fetching employees:", err);
    }
  };

  useEffect(() => {
    fetchProfileData();
  }, []);

  const getDeptName = (id) => {
    const d = departments.find(dept => dept.deptId === id);
    return d ? d.deptNm : `Department ID: ${id}`;
  };

  const getManagerName = (id) => {
    if (!id) return "None";
    const mgr = employees.find(emp => emp.empId === id);
    return mgr ? `${mgr.fstNm || ""} ${mgr.lstNm || ""}`.trim() : `Manager ID: ${id}`;
  };

  const profileDetails = profile ? {
    employeeCode: profile.empCode || "N/A",
    employeeName: `${profile.fstNm || ""} ${profile.lstNm || ""}`.trim() || "N/A",
    email: profile.email || "N/A",
    mobileNumber: profile.mobNum || "N/A",
    department: profile.deptId ? getDeptName(profile.deptId) : "N/A",
    role: profile.role || "N/A",
    reportingManager: profile.repManId ? getManagerName(profile.repManId) : "None",
    workLocation: profile.wLoc || "N/A",
    dateOfJoining: profile.doj || "N/A",
    status: profile.sts === true || profile.sts === "ACTIVE" ? "Active" : "Inactive"
  } : {
    employeeCode: "Loading...",
    employeeName: "Loading...",
    email: "Loading...",
    mobileNumber: "Loading...",
    department: "Loading...",
    role: "Loading...",
    reportingManager: "Loading...",
    workLocation: "Loading...",
    dateOfJoining: "Loading...",
    status: "Loading..."
  };

  return (
    <div className="pf-shell-container">
      <Sidebar userRole={userRole} onLogout={onLogout} />

      <div className="pf-shell">
        <Header 
          title="My Profile" 
          showSearch={false} 
          userName={profileDetails.employeeName} 
          userRole={profileDetails.role} 
          initials={profile ? `${profile.fstNm?.[0] || profile.firstName?.[0] || ""}${profile.lstNm?.[0] || profile.lastName?.[0] || ""}`.toUpperCase() || "RK" : "RK"} 
        />

        <main className="pf-main">
          

          

          <div className="pf-content">
            
            {/* Left Card: Profile Information */}
            <div className="pf-card pf-profile-card">
              <div className="pf-card-header">
                <User className="pf-card-icon" size={24} />
                <div className="pf-card-title-wrap">
                  <h2>Profile Information</h2>
                  <p>View your personal and professional details</p>
                </div>
              </div>

              <div className="pf-info-layout">
                {/* Avatar Section */}
                <div className="pf-avatar-section">
                  <div className="pf-avatar-wrapper">
                    <User size={80} color="#94a3b8" strokeWidth={1.5} />
                  </div>
                  <button className="pf-change-photo-btn">
                    <Camera size={16} />
                    Change Photo
                  </button>
                  <span className="pf-avatar-hint">JPG, PNG or GIF. Max size of 2MB</span>
                </div>

                {/* Details List */}
                <div className="pf-details-list">
                  <div className="pf-detail-row">
                    <div className="pf-detail-label">
                      <IdCard size={16} />
                      Employee Code
                    </div>
                    <span className="pf-detail-separator">:</span>
                    <div className="pf-detail-value">{profileDetails.employeeCode}</div>
                  </div>

                  <div className="pf-detail-row">
                    <div className="pf-detail-label">
                      <User size={16} />
                      Employee Name
                    </div>
                    <span className="pf-detail-separator">:</span>
                    <div className="pf-detail-value">{profileDetails.employeeName}</div>
                  </div>

                  <div className="pf-detail-row">
                    <div className="pf-detail-label">
                      <Mail size={16} />
                      Email
                    </div>
                    <span className="pf-detail-separator">:</span>
                    <div className="pf-detail-value">{profileDetails.email}</div>
                  </div>

                  <div className="pf-detail-row">
                    <div className="pf-detail-label">
                      <Phone size={16} />
                      Mobile Number
                    </div>
                    <span className="pf-detail-separator">:</span>
                    <div className="pf-detail-value">{profileDetails.mobileNumber}</div>
                  </div>

                  <div className="pf-detail-row">
                    <div className="pf-detail-label">
                      <Building size={16} />
                      Department
                    </div>
                    <span className="pf-detail-separator">:</span>
                    <div className="pf-detail-value">{profileDetails.department}</div>
                  </div>

                  <div className="pf-detail-row">
                    <div className="pf-detail-label">
                      <ShieldCheck size={16} />
                      Designation
                    </div>
                    <span className="pf-detail-separator">:</span>
                    <div className="pf-detail-value">{profileDetails.role}</div>
                  </div>

                  <div className="pf-detail-row">
                    <div className="pf-detail-label">
                      <User size={16} />
                      Reporting Manager
                    </div>
                    <span className="pf-detail-separator">:</span>
                    <div className="pf-detail-value">{profileDetails.reportingManager}</div>
                  </div>

                  <div className="pf-detail-row">
                    <div className="pf-detail-label">
                      <MapPin size={16} />
                      Work Location
                    </div>
                    <span className="pf-detail-separator">:</span>
                    <div className="pf-detail-value">{profileDetails.workLocation}</div>
                  </div>

                  <div className="pf-detail-row">
                    <div className="pf-detail-label">
                      <Calendar size={16} />
                      Date of Joining
                    </div>
                    <span className="pf-detail-separator">:</span>
                    <div className="pf-detail-value">{profileDetails.dateOfJoining}</div>
                  </div>

                  <div className="pf-detail-row">
                    <div className="pf-detail-label">
                      <Clock size={16} />
                      Status
                    </div>
                    <span className="pf-detail-separator">:</span>
                    <div className="pf-detail-value">
                      <span className="pf-status-badge">
                        <span className="pf-status-dot"></span>
                        {profileDetails.status}
                      </span>
                    </div>
                  </div>

                </div>
              </div>
            </div>

            {/* Right Card: Account & Security */}
            <div className="pf-card pf-security-card">
              <div className="pf-card-header">
                <ShieldCheck className="pf-card-icon" size={24} />
                <div className="pf-card-title-wrap">
                  <h2>Account & Security</h2>
                  <p>Update your account password</p>
                </div>
              </div>

              <div className="pf-security-form">
                <div className="pf-form-group">
                  <label>Current Password <span>*</span></label>
                  <div className="pf-input-wrapper">
                    <input 
                      type={showCurrentPassword ? "text" : "password"} 
                      placeholder="Enter current password" 
                      value={currentPassword}
                      onChange={(e) => setCurrentPassword(e.target.value)}
                    />
                    {showCurrentPassword ? (
                      <Eye className="pf-input-icon" size={18} onClick={() => setShowCurrentPassword(false)} />
                    ) : (
                      <EyeOff className="pf-input-icon" size={18} onClick={() => setShowCurrentPassword(true)} />
                    )}
                  </div>
                </div>

                <div className="pf-form-group">
                  <label>New Password <span>*</span></label>
                  <div className="pf-input-wrapper">
                    <input 
                      type={showNewPassword ? "text" : "password"} 
                      placeholder="Enter new password" 
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                    />
                    {showNewPassword ? (
                      <Eye className="pf-input-icon" size={18} onClick={() => setShowNewPassword(false)} />
                    ) : (
                      <EyeOff className="pf-input-icon" size={18} onClick={() => setShowNewPassword(true)} />
                    )}
                  </div>
                  <p className="pf-password-hint">
                    Password must be at least 8 characters long and include uppercase, lowercase, number and special character.
                  </p>
                </div>

                <div className="pf-form-group">
                  <label>Confirm New Password <span>*</span></label>
                  <div className="pf-input-wrapper">
                    <input 
                      type={showConfirmPassword ? "text" : "password"} 
                      placeholder="Confirm new password" 
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                    />
                    {showConfirmPassword ? (
                      <Eye className="pf-input-icon" size={18} onClick={() => setShowConfirmPassword(false)} />
                    ) : (
                      <EyeOff className="pf-input-icon" size={18} onClick={() => setShowConfirmPassword(true)} />
                    )}
                  </div>
                </div>

                {error && <p style={{ color: '#ef4444', fontSize: '13px', margin: '0 0 16px 0', fontWeight: '500' }}>{error}</p>}
                {message && <p style={{ color: '#16a34a', fontSize: '13px', margin: '0 0 16px 0', fontWeight: '500' }}>{message}</p>}

                <button 
                  className="pf-update-btn" 
                  onClick={handleUpdatePassword}
                  disabled={loading}
                >
                  <Lock size={16} />
                  {loading ? "Updating..." : "Update Password"}
                </button>
              </div>

            </div>
          </div>
        </main>
      </div>
    </div>
  );
};

export default Profile;
