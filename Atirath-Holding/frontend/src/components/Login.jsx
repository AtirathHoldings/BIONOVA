import React, { useState } from 'react';
import '../styles/login.css';

const Login = ({ onLogin }) => {
  const [currentView, setCurrentView] = useState('login');
  
  const [formData, setFormData] = useState({
    email: '',
    password: ''
  });
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const [resetEmail, setResetEmail] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    setError('');
  };

  const handleLoginSubmit = async (e) => {
    e.preventDefault();
    setError('');

    if (!formData.email.trim()) {
      setError("Please enter your email address");
      return;
    }
    if (!formData.password) {
      setError("Please enter your password");
      return;
    }

    setLoading(true);

    try {
      const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || "http://localhost:8080";
      const response = await fetch(`${apiBaseUrl}/api/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          email: formData.email.trim(),
          password: formData.password
        })
      });

      if (!response.ok) {
        throw new Error("Server responded with an error status: " + response.status);
      }

      const data = await response.json();
      if (data.success) {
        sessionStorage.setItem("isLoggedIn", "true");
        sessionStorage.setItem("userEmail", formData.email.trim());
        sessionStorage.setItem("userRole", data.role || "user");
        // Store JWT token for authenticated API calls
        if (data.token) {
          sessionStorage.setItem("authToken", data.token);
        }
        
        // Extract and format userName from email
        const email = formData.email.trim();
        const namePart = email.split("@")[0];
        const formattedName = namePart
          .split(/[._]/)
          .map(word => word.charAt(0).toUpperCase() + word.slice(1))
          .join(" ");
        sessionStorage.setItem("userName", formattedName);
        
        onLogin(true, data.role || "user");
      } else {
        setError(data.message || "Invalid Email or Password");
      }
    } catch (err) {
      console.error("Login failed:", err);
      setError("Could not connect to server. Please ensure the backend is running.");
    } finally {
      setLoading(false);
    }
  };

  const handleForgotSubmit = (e) => {
    e.preventDefault();
    setError('');
    setSuccessMsg('');

    if (!resetEmail.trim()) {
      setError("Please enter your registered email address");
      return;
    }

    setLoading(true);

    setTimeout(() => {
      setLoading(false);
      setSuccessMsg(`Password reset link has been sent to ${resetEmail}`);
      setResetEmail(''); 
    }, 800);
  };

  const switchView = (view) => {
    setCurrentView(view);
    setError('');
    setSuccessMsg('');
    setFormData({ email: '', password: '' });
    setResetEmail('');
  };

  return (
    <div className="login-container">
      <div className="login-fullscreen-split">
        
        <div className="login-left">
          <img src="/icon3.png.png" alt="Login Background" className="left-side-image" />
        </div>

        <div className="login-right">
          <div className="login-body">
            
            <div className="brand-header-large">
              <div className="brand-icon-placeholder">
                <img src="/icon2.png" alt="A Logo" onError={(e) => { e.target.style.display = 'none'; e.target.nextSibling.style.display = 'block'; }} className="brand-logo-icon" />
                <i className="fas fa-leaf fallback-icon" style={{ display: 'none' }}></i>
              </div>
              <h2 className="brand-title-primary">ATIRATH HOLDINGS</h2>
              <h2 className="brand-title-secondary">INDIA LIMITED</h2>
              <div className="brand-tagline">
                <span>Innovate</span><span>Cultivate</span><span>Elevate</span>
              </div>
            </div>

            {error && (
              <div className="error-message">
                <i className="fas fa-exclamation-circle"></i> <span>{error}</span>
              </div>
            )}
            
            {successMsg && (
              <div className="success-message">
                <i className="fas fa-check-circle"></i> <span>{successMsg}</span>
              </div>
            )}

            {currentView === 'login' ? (
              <form onSubmit={handleLoginSubmit}>
                <div className="input-group">
                  <label>Email</label>
                  <div className="input-wrapper">
                    <i className="far fa-envelope"></i>
                    <input
                      type="email" name="email" value={formData.email} onChange={handleChange}
                      placeholder="Enter your email" autoComplete="off"
                    />
                  </div>
                </div>

                <div className="input-group">
                  <label>Password</label>
                  <div className="input-wrapper password-wrapper">
                    <i className="fas fa-lock" style={{opacity: 0.6}}></i>
                    <input
                      type={showPassword ? 'text' : 'password'} name="password"
                      value={formData.password} onChange={handleChange} placeholder="Enter your password"
                    />
                    <span className="password-toggle" onClick={() => setShowPassword(!showPassword)}>
                      <i className={showPassword ? 'far fa-eye-slash' : 'far fa-eye'}></i>
                    </span>
                  </div>
                </div>

                <div className="forgot-link-wrapper" style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: '20px', marginTop: '-10px' }}>
                  <span className="forgot-link" style={{ color: '#397e32', fontSize: '13px', cursor: 'pointer', fontWeight: '600' }} onClick={() => switchView('forgot')}>
                    Forgot Password?
                  </span>
                </div>

                <button type="submit" className="login-btn" disabled={loading}>
                  {loading ? <><i className="fas fa-spinner fa-spin" style={{marginRight: '8px'}}></i> Logging in...</> : "Sign In"}
                </button>
              </form>
            ) : (
              <form onSubmit={handleForgotSubmit}>
                <div className="welcome-text" style={{ marginBottom: '20px', textAlign: 'center' }}>
                  <h2 style={{ color: '#1e293b', fontSize: '22px', fontWeight: '600', marginBottom: '8px' }}>Reset Password</h2>
                  <p style={{ color: '#64748b', fontSize: '14px' }}>Enter your email to receive instructions</p>
                </div>

                <div className="input-group">
                  <label>Email Address</label>
                  <div className="input-wrapper">
                    <i className="far fa-envelope"></i>
                    <input
                      type="email" value={resetEmail}
                      onChange={(e) => { setResetEmail(e.target.value); setError(''); }}
                      placeholder="Enter your registered email" autoComplete="off"
                    />
                  </div>
                </div>

                <button type="submit" className="login-btn" disabled={loading}>
                  {loading ? <><i className="fas fa-spinner fa-spin" style={{marginRight: '8px'}}></i> Sending...</> : "Send Reset Link"}
                </button>

                <div className="back-link" style={{ textAlign: 'center', marginTop: '20px', color: '#64748b', cursor: 'pointer', fontSize: '14px', fontWeight: '500' }} onClick={() => switchView('login')}>
                  <i className="fas fa-arrow-left" style={{marginRight: '5px'}}></i> Back to Login
                </div>
              </form>
            )}

          </div>
        </div>

      </div>
    </div>
  );
};

export default Login;