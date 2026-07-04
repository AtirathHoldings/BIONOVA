import React, { useState, useEffect } from "react";
import { Menu, Search, Bell } from "lucide-react";

const Header = ({ title, showSearch = false }) => {
  const [userName, setUserName] = useState("User");
  const [userRole, setUserRole] = useState("Role");
  const [initials, setInitials] = useState("U");
  const [showWelcome, setShowWelcome] = useState(false);

  useEffect(() => {
    // Fetch details dynamically from sessionStorage
    let storedName = sessionStorage.getItem("userName");
    if (!storedName) {
      const email = sessionStorage.getItem("userEmail") || "";
      if (email) {
        const namePart = email.split("@")[0];
        storedName = namePart
          .split(/[._]/)
          .map(word => word.charAt(0).toUpperCase() + word.slice(1))
          .join(" ");
        sessionStorage.setItem("userName", storedName);
      } else {
        storedName = "Admin User";
      }
    }
    const storedRole = sessionStorage.getItem("userRole") || "Super Admin";
    
    setUserName(storedName);
    setUserRole(storedRole);
    
    // Auto-generate initials (e.g., "Syed Johny Basha" -> "SB")
    const nameParts = storedName.split(" ");
    let init = "U";
    if (nameParts.length >= 2) {
      init = nameParts[0][0] + nameParts[nameParts.length - 1][0];
    } else if (nameParts.length === 1) {
      init = nameParts[0][0];
    }
    setInitials(init.toUpperCase());

    // Show Welcome Animation if user just logged in
    const hasSeenWelcome = sessionStorage.getItem("hasSeenWelcome");
    if (!hasSeenWelcome) {
      setShowWelcome(true);
      sessionStorage.setItem("hasSeenWelcome", "true");
      
      // Hide the message after 4.5 seconds
      setTimeout(() => {
        setShowWelcome(false);
      }, 4500);
    }
  }, []);

  return (
    <>
      <style>
        {`
          @keyframes slideInFadeOut {
            0% { opacity: 0; transform: translateY(-20px); }
            10% { opacity: 1; transform: translateY(0); }
            85% { opacity: 1; transform: translateY(0); }
            100% { opacity: 0; transform: translateY(-20px); }
          }
          .welcome-toast {
            position: absolute;
            top: 75px;
            right: 28px;
            background: linear-gradient(135deg, #10b981, #059669);
            color: white;
            padding: 10px 24px;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 500;
            box-shadow: 0 4px 15px rgba(16, 185, 129, 0.3);
            animation: slideInFadeOut 4.5s ease-in-out forwards;
            pointer-events: none;
            z-index: 50;
            display: flex;
            align-items: center;
            gap: 8px;
          }
        `}
      </style>

      <header style={{
        display: "flex", 
        justifyContent: "space-between", 
        alignItems: "center",
        padding: "16px 28px", 
        background: "white", 
        borderBottom: "1px solid #e2e8f0",
        position: "sticky", 
        top: 0, 
        zIndex: 10
      }}>
        {/* Left Side: Title */}
        <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
          <button 
            className="mobile-menu-btn" 
            onClick={() => window.dispatchEvent(new CustomEvent('toggleSidebar'))}
            style={{ 
              background: "transparent", 
              border: "none", 
              cursor: "pointer", 
              color: "#64748b",
              padding: "4px"
            }}
          >
            <Menu size={24} />
          </button>
          <h1 style={{ margin: 0, fontSize: "20px", color: "#1e293b", fontWeight: "700" }}>
            {title}
          </h1>
        </div>
        
        {/* Right Side: Search, Notifications & Dynamic User Info */}
        <div style={{ display: "flex", alignItems: "center", gap: "24px" }}>
          
          {showSearch && (
            <div className="header-desktop-items" style={{ display: "flex", alignItems: "center", background: "#f1f5f9", padding: "8px 16px", borderRadius: "8px", gap: "8px" }}>
              <Search size={16} color="#64748b" />
              <input 
                type="text" 
                placeholder="Search anything..." 
                style={{ background: "none", border: "none", outline: "none", fontSize: "14px", width: "200px" }} 
              />
            </div>
          )}

          <div style={{ display: "flex", alignItems: "center", gap: "12px", borderLeft: "2px solid #e2e8f0", paddingLeft: "24px" }}>
            <div style={{ 
              width: "38px", height: "38px", borderRadius: "50%", background: "#2563eb", 
              color: "white", display: "flex", alignItems: "center", justifyContent: "center", 
              fontWeight: "bold", fontSize: "14px", letterSpacing: "1px" 
            }}>
              {initials}
            </div>
            <div style={{ display: "flex", flexDirection: "column" }}>
              <strong style={{ fontSize: "14px", color: "#1e293b" }}>{userName}</strong>
              <small style={{ fontSize: "12px", color: "#64748b", fontWeight: "500" }}>{userRole}</small>
            </div>
          </div>
        </div>

        {/* Animated Welcome Message (Shows only once after login) */}
        {showWelcome && (
          <div className="welcome-toast">
            <span>🎉 Welcome back, <strong style={{ fontWeight: '700' }}>{userName}</strong>!</span>
          </div>
        )}
      </header>
    </>
  );
};

export default Header;