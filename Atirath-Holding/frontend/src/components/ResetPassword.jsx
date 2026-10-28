import React, { useState, useEffect } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import '../styles/login.css';

// Import background image and icon
import loginBg from '/login bg.png';
import resetIcon from '/BioNova.png';

const ResetPassword = () => {
  const [searchParams] = useSearchParams();
  const token = searchParams.get('token');
  const navigate = useNavigate();

  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [error, setError] = useState('');
  const [successMsg, setSuccessMsg] = useState('');
  const [loading, setLoading] = useState(false);

  const [isValidating, setIsValidating] = useState(true);
  const [tokenExpiredError, setTokenExpiredError] = useState('');

  useEffect(() => {
    if (!token) {
      setIsValidating(false);
      setTokenExpiredError("Invalid or missing reset token. Please request a new one.");
      return;
    }

    const validateToken = async () => {
      try {
        const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;
        const response = await fetch(`${apiBaseUrl}/api/auth/validate-reset-token?token=${encodeURIComponent(token)}`, {
          method: 'GET',
          headers: {
            'Accept': 'application/json'
          }
        });

        const data = await response.json();

        if (!response.ok || !data.valid) {
          setTokenExpiredError(data.error || "Reset link has expired. Please request a new one.");
        }
      } catch (err) {
        console.error("Token validation error:", err);
        setTokenExpiredError("Could not verify reset link. Please check your connection or request a new link.");
      } finally {
        setIsValidating(false);
      }
    };

    validateToken();
  }, [token]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSuccessMsg('');

    if (!token) {
      setError("Invalid or missing reset token.");
      return;
    }
    if (!password) {
      setError("Please enter a new password");
      return;
    }
    if (!confirmPassword) {
      setError("Please fill confirm password also");
      return;
    }
    if (password.length < 8) {
      setError("Password must be at least 8 characters long");
      return;
    }
    if (password !== confirmPassword) {
      setError("Passwords do not match");
      return;
    }

    setLoading(true);

    try {
      const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;
      const response = await fetch(`${apiBaseUrl}/api/auth/reset-password`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          token,
          newPassword: password
        })
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || "Reset password request failed.");
      }

      setSuccessMsg("Password reset successful! Redirecting to login...");
      setPassword('');
      setConfirmPassword('');
      setTimeout(() => {
        navigate('/', { replace: true });
      }, 3000);
    } catch (err) {
      console.error("Reset password failed:", err);
      setError(err.message || "Could not connect to server. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  // Background image style
  const backgroundStyle = {
    backgroundImage: `url(${loginBg})`,
    backgroundSize: 'cover',
    backgroundPosition: 'center',
    backgroundRepeat: 'no-repeat'
  };

  return (
    <div className="login-container" style={backgroundStyle}>
      <div className="login-overlay">
        <div className="login-card-wrapper">
          <div className="login-card">

            <div className="reset-header">
              <div className="reset-icon-wrapper">
                <img src={resetIcon} alt="Reset Icon" className="header-icon" />
              </div>
              <h2 className="reset-title">
                {tokenExpiredError ? "Link Expired" : "Create New Password"}
              </h2>
              <p className="reset-subtitle">
                {tokenExpiredError ? "This password reset link is no longer valid" : "Please choose a strong password"}
              </p>
            </div>

            {isValidating ? (
              <div style={{ textAlign: 'center', padding: '30px 0' }}>
                <div className="spinner" style={{ borderColor: '#06092c transparent #06092c transparent', width: '32px', height: '32px', margin: '0 auto 14px' }}></div>
                <p style={{ color: '#666', fontSize: '14px', fontWeight: 500 }}>Validating reset link...</p>
              </div>
            ) : tokenExpiredError ? (
              <div>
                <div className="error-message" style={{ marginBottom: '24px' }}>
                  <i className="fas fa-exclamation-circle"></i> <span>{tokenExpiredError}</span>
                </div>

                <button
                  type="button"
                  className="login-btn"
                  onClick={() => navigate('/', { replace: true })}
                >
                  <i className="fas fa-arrow-left" style={{ marginRight: '8px' }}></i> Back to Login
                </button>
              </div>
            ) : (
              <>
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

                <form onSubmit={handleSubmit}>
                  <div className="input-group">
                    <label>New Password</label>
                    <div className="input-wrapper password-wrapper">
                      <i className="fas fa-lock input-icon"></i>
                      <input
                        type={showPassword ? 'text' : 'password'}
                        value={password}
                        onChange={(e) => { setPassword(e.target.value); setError(''); }}
                        placeholder="Enter new password"
                        className="password-input"
                      />
                      <button
                        type="button"
                        className="password-toggle-btn"
                        onClick={() => setShowPassword(!showPassword)}
                      >
                        <i className={showPassword ? 'far fa-eye-slash' : 'far fa-eye'}></i>
                      </button>
                    </div>
                  </div>

                  <div className="input-group">
                    <label>Confirm Password</label>
                    <div className="input-wrapper password-wrapper">
                      <i className="fas fa-lock input-icon"></i>
                      <input
                        type={showConfirmPassword ? 'text' : 'password'}
                        value={confirmPassword}
                        onChange={(e) => { setConfirmPassword(e.target.value); setError(''); }}
                        placeholder="Confirm new password"
                        className="password-input"
                      />
                      <button
                        type="button"
                        className="password-toggle-btn"
                        onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                      >
                        <i className={showConfirmPassword ? 'far fa-eye-slash' : 'far fa-eye'}></i>
                      </button>
                    </div>
                  </div>

                  <button type="submit" className="login-btn" disabled={loading}>
                    {loading ? <><i className="fas fa-spinner fa-spin" style={{ marginRight: '8px' }}></i> Resetting...</> : "Update Password"}
                  </button>

                  <div className="back-link" onClick={() => navigate('/', { replace: true })}>
                    <i className="fas fa-arrow-left" style={{ marginRight: '5px' }}></i> Back to Login
                  </div>
                </form>
              </>
            )}

          </div>
        </div>
      </div>
    </div>
  );
};

export default ResetPassword;
