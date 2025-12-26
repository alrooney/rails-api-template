# Rails API Template JavaScript API Authentication Guide

## Overview

This guide provides comprehensive instructions for JavaScript clients on how to authenticate with the Rails API Template API. The system supports both cookie-based authentication (recommended for web applications) and bearer token authentication (for mobile apps, desktop applications, and server-to-server communication).

## Table of Contents

1. [Authentication Methods](#authentication-methods)
2. [Cookie-Based Authentication (Web Clients)](#cookie-based-authentication-web-clients)
3. [Bearer Token Authentication (Other Clients)](#bearer-token-authentication-other-clients)
4. [Authentication Flow Examples](#authentication-flow-examples)
5. [Password Reset Flow](#password-reset-flow)
6. [Error Handling](#error-handling)
7. [Security Best Practices](#security-best-practices)
8. [Token Management](#token-management)

## Authentication Methods

The Rails API Template supports two primary authentication methods:

1. **Cookie-Based Authentication**: Recommended for web applications running in browsers
2. **Bearer Token Authentication**: Recommended for mobile apps, desktop applications, and server-to-server communication

## Cookie-Based Authentication (Web Clients)

Cookie-based authentication is the recommended approach for web applications as it provides better security and automatic token management.

### Configuration

For cookie-based authentication, ensure your API requests include credentials:

```javascript
// Global fetch configuration for cookie-based auth
const apiConfig = {
  baseURL: 'https://your-domain.com/api/v1',
  credentials: 'include', // This is crucial for cookie-based auth
  headers: {
    'Content-Type': 'application/json'
  }
};
```

**CSRF Protection**: The Rails API Template uses `SameSite: :lax` cookie policy for CSRF protection. This approach provides strong protection against cross-site request forgery attacks without requiring additional CSRF tokens in requests. The `SameSite: :lax` policy ensures cookies are only sent with same-site requests and top-level navigation, effectively preventing CSRF attacks while maintaining a simple authentication flow.

### Login Process

```javascript
async function login(email, password) {
  try {
    const response = await fetch(`${apiConfig.baseURL}/login`, {
      method: 'POST',
      credentials: 'include', // Include cookies in request
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        email: email,
        password: password
      })
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error || 'Login failed');
    }

    const data = await response.json();
    
    // For cookie-based auth, tokens are automatically stored in cookies
    // You don't need to manually handle token storage
    return {
      success: true,
      user: data.user,
      message: 'Login successful'
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}
```

### Making Authenticated Requests

```javascript
async function makeAuthenticatedRequest(endpoint, options = {}) {
  const defaultOptions = {
    credentials: 'include', // Always include cookies
    headers: {
      'Content-Type': 'application/json',
      ...options.headers
    }
  };

  const response = await fetch(`${apiConfig.baseURL}${endpoint}`, {
    ...defaultOptions,
    ...options
  });

  if (response.status === 401) {
    // Handle unauthorized - redirect to login or refresh tokens
    handleUnauthorized();
    throw new Error('Unauthorized');
  }

  return response;
}

// Example usage
async function getGoals() {
  try {
    const response = await makeAuthenticatedRequest('/goals', {
      method: 'GET'
    });
    
    if (response.ok) {
      return await response.json();
    }
    throw new Error('Failed to fetch goals');
  } catch (error) {
    console.error('Error fetching goals:', error);
    throw error;
  }
}
```

### Logout Process

```javascript
async function logout() {
  try {
    const response = await fetch(`${apiConfig.baseURL}/logout`, {
      method: 'DELETE',
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json'
      }
    });

    if (response.ok) {
      // Clear any client-side user data
      clearUserData();
      return { success: true };
    }
    throw new Error('Logout failed');
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}
```



## Bearer Token Authentication (Other Clients)

Bearer token authentication is recommended for mobile apps, desktop applications, and server-to-server communication.

### Token Storage

```javascript
// Secure token storage utilities
class TokenManager {
  constructor() {
    this.accessTokenKey = 'rails_api_template_access_token';
    this.refreshTokenKey = 'rails_api_template_refresh_token';
  }

  // Store tokens securely
  setTokens(accessToken, refreshToken) {
    // For web clients, use httpOnly cookies if possible
    // For mobile/desktop apps, use secure storage
    if (typeof localStorage !== 'undefined') {
      localStorage.setItem(this.accessTokenKey, accessToken);
      localStorage.setItem(this.refreshTokenKey, refreshToken);
    }
  }

  // Retrieve access token
  getAccessToken() {
    if (typeof localStorage !== 'undefined') {
      return localStorage.getItem(this.accessTokenKey);
    }
    return null;
  }

  // Retrieve refresh token
  getRefreshToken() {
    if (typeof localStorage !== 'undefined') {
      return localStorage.getItem(this.refreshTokenKey);
    }
    return null;
  }

  // Clear tokens
  clearTokens() {
    if (typeof localStorage !== 'undefined') {
      localStorage.removeItem(this.accessTokenKey);
      localStorage.removeItem(this.refreshTokenKey);
    }
  }

  // Check if tokens exist
  hasTokens() {
    return !!(this.getAccessToken() && this.getRefreshToken());
  }
}

const tokenManager = new TokenManager();
```

### Login Process

```javascript
async function login(email, password) {
  try {
    const response = await fetch(`${apiConfig.baseURL}/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        email: email,
        password: password
      })
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error || 'Login failed');
    }

    const data = await response.json();
    
    // Store tokens securely
    tokenManager.setTokens(data.access_token, data.refresh_token);
    
    return {
      success: true,
      user: data.user,
      accessToken: data.access_token,
      refreshToken: data.refresh_token,
      expiresIn: data.expires_in
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}
```

### Making Authenticated Requests

```javascript
async function makeAuthenticatedRequest(endpoint, options = {}) {
  const accessToken = tokenManager.getAccessToken();
  
  if (!accessToken) {
    throw new Error('No access token available');
  }

  const defaultOptions = {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${accessToken}`,
      ...options.headers
    }
  };

  let response = await fetch(`${apiConfig.baseURL}${endpoint}`, {
    ...defaultOptions,
    ...options
  });

  // Handle token expiration
  if (response.status === 401) {
    const refreshed = await refreshAccessToken();
    if (refreshed) {
      // Retry the original request with new token
      const newAccessToken = tokenManager.getAccessToken();
      response = await fetch(`${apiConfig.baseURL}${endpoint}`, {
        ...defaultOptions,
        ...options,
        headers: {
          ...defaultOptions.headers,
          'Authorization': `Bearer ${newAccessToken}`
        }
      });
    } else {
      // Refresh failed, redirect to login
      handleUnauthorized();
      throw new Error('Authentication failed');
    }
  }

  return response;
}
```

### Token Refresh

**Important**: The API implements **refresh token rotation** for enhanced security. Each time you refresh your access token, you receive a **new refresh token**, and the old refresh token is automatically revoked. This means:

- ✅ **Continuous Refresh**: You can refresh tokens indefinitely without timeout (especially important for mobile apps)
- ✅ **Better Security**: Old refresh tokens become invalid immediately after use
- ✅ **Mandatory Update**: You **must** save the new refresh token returned in each refresh response

```javascript
async function refreshAccessToken() {
  const refreshToken = tokenManager.getRefreshToken();
  
  if (!refreshToken) {
    return false;
  }

  try {
    const response = await fetch(`${apiConfig.baseURL}/refresh`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        refresh_token: refreshToken
      })
    });

    if (!response.ok) {
      tokenManager.clearTokens();
      return false;
    }

    const data = await response.json();
    
    // CRITICAL: Save both the new access token AND the new refresh token
    // The old refresh token is now revoked and cannot be reused
    tokenManager.setTokens(data.access_token, data.refresh_token);
    return true;
  } catch (error) {
    tokenManager.clearTokens();
    return false;
  }
}
```

**Note**: If you attempt to reuse an old refresh token that was already used in a previous refresh, the request will fail with an "Invalid or expired refresh token" error. Always use the latest refresh token you received from the API.

### Logout Process

```javascript
async function logout() {
  try {
    const refreshToken = tokenManager.getRefreshToken();
    
    if (refreshToken) {
      await fetch(`${apiConfig.baseURL}/logout`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${tokenManager.getAccessToken()}`
        },
        body: JSON.stringify({
          refresh_token: refreshToken
        })
      });
    }
  } catch (error) {
    console.error('Logout error:', error);
  } finally {
    // Always clear tokens locally
    tokenManager.clearTokens();
    clearUserData();
  }
}
```

## Authentication Flow Examples

### Complete Web Application Example

```javascript
class ApiClient {
  constructor(baseURL) {
    this.baseURL = baseURL;
    this.isWebClient = typeof window !== 'undefined' && window.document;
  }

  async login(email, password) {
    const endpoint = '/login';
    const options = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ email, password })
    };

    // Add credentials for web clients
    if (this.isWebClient) {
      options.credentials = 'include';
    }

    const response = await fetch(`${this.baseURL}${endpoint}`, options);
    
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error || 'Login failed');
    }

    const data = await response.json();
    
    // Handle token storage for non-web clients
    if (!this.isWebClient && data.access_token) {
      tokenManager.setTokens(data.access_token, data.refresh_token);
    }

    return data;
  }

  async makeRequest(endpoint, options = {}) {
    const defaultOptions = {
      headers: {
        'Content-Type': 'application/json'
      }
    };

    // Add authentication
    if (this.isWebClient) {
      defaultOptions.credentials = 'include';
    } else {
      const accessToken = tokenManager.getAccessToken();
      if (accessToken) {
        defaultOptions.headers['Authorization'] = `Bearer ${accessToken}`;
      }
    }

    const response = await fetch(`${this.baseURL}${endpoint}`, {
      ...defaultOptions,
      ...options,
      headers: {
        ...defaultOptions.headers,
        ...options.headers
      }
    });

    // Handle token refresh for bearer token auth
    if (!this.isWebClient && response.status === 401) {
      const refreshed = await refreshAccessToken();
      if (refreshed) {
        // Retry with new token
        const newAccessToken = tokenManager.getAccessToken();
        return fetch(`${this.baseURL}${endpoint}`, {
          ...defaultOptions,
          ...options,
          headers: {
            ...defaultOptions.headers,
            ...options.headers,
            'Authorization': `Bearer ${newAccessToken}`
          }
        });
      }
    }

    return response;
  }

  async logout() {
    const endpoint = '/logout';
    const options = { method: 'DELETE' };

    if (this.isWebClient) {
      options.credentials = 'include';
    } else {
      const refreshToken = tokenManager.getRefreshToken();
      if (refreshToken) {
        options.headers = { 'Content-Type': 'application/json' };
        options.body = JSON.stringify({ refresh_token: refreshToken });
      }
    }

    try {
      await this.makeRequest(endpoint, options);
    } finally {
      if (!this.isWebClient) {
        tokenManager.clearTokens();
      }
      clearUserData();
    }
  }
}

// Usage
const client = new ApiClient('https://your-domain.com/api/v1');
```

## Password Reset Flow

The Rails API Template provides a secure password reset flow that allows users to reset their passwords via email. This flow consists of two steps: requesting a password reset and completing the reset with a token.

### Password Reset Endpoints

- `POST /api/v1/password/reset` - Request password reset (sends email)
- `PUT /api/v1/password/reset/:token` - Reset password with token

### Step 1: Request Password Reset

Users can request a password reset by providing their email address. The API will send a password reset email if the email exists in the system.

#### Cookie-Based Authentication (Web Clients)

```javascript
async function requestPasswordReset(email) {
  try {
    const response = await fetch(`${apiConfig.baseURL}/password/reset`, {
      method: 'POST',
      credentials: 'include', // Include cookies for CSRF protection
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        email: email
      })
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error || 'Password reset request failed');
    }

    const data = await response.json();
    return {
      success: true,
      message: data.message
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}
```

#### Bearer Token Authentication (Other Clients)

```javascript
async function requestPasswordReset(email) {
  try {
    const response = await fetch(`${apiConfig.baseURL}/password/reset`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        email: email
      })
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error || 'Password reset request failed');
    }

    const data = await response.json();
    return {
      success: true,
      message: data.message
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}
```

### Step 2: Complete Password Reset

After receiving the password reset email, users click the link which contains a token. The frontend should extract this token and provide a form for the user to enter their new password.

#### Token Extraction from URL

```javascript
function extractTokenFromURL() {
  const urlParams = new URLSearchParams(window.location.search);
  return urlParams.get('token');
}

// Alternative method using URL hash
function extractTokenFromHash() {
  const hash = window.location.hash.substring(1);
  const params = new URLSearchParams(hash);
  return params.get('token');
}
```

#### Complete Password Reset

```javascript
async function completePasswordReset(token, newPassword) {
  try {
    // Validate password requirements
    if (!newPassword || newPassword.length < 6) {
      throw new Error('Password must be at least 6 characters long');
    }

    const response = await fetch(`${apiConfig.baseURL}/password/reset/${token}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        password: newPassword
      })
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error || 'Password reset failed');
    }

    const data = await response.json();
    return {
      success: true,
      message: data.message
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}
```

### Complete Password Reset Implementation

Here's a complete implementation that handles the entire password reset flow:

#### HTML Form Example

```html
<!DOCTYPE html>
<html>
<head>
    <title>Password Reset - Rails API Template</title>
    <style>
        .form-container {
            max-width: 400px;
            margin: 50px auto;
            padding: 20px;
            border: 1px solid #ddd;
            border-radius: 8px;
        }
        .form-group {
            margin-bottom: 15px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
        }
        input[type="email"], input[type="password"] {
            width: 100%;
            padding: 8px;
            border: 1px solid #ccc;
            border-radius: 4px;
            box-sizing: border-box;
        }
        button {
            background-color: #007bff;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            width: 100%;
        }
        button:disabled {
            background-color: #ccc;
            cursor: not-allowed;
        }
        .error {
            color: red;
            margin-top: 10px;
        }
        .success {
            color: green;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="form-container">
        <h2>Password Reset</h2>
        
        <!-- Step 1: Request Reset -->
        <div id="request-reset-form">
            <p>Enter your email address to receive password reset instructions.</p>
            <form id="reset-request-form">
                <div class="form-group">
                    <label for="email">Email Address:</label>
                    <input type="email" id="email" name="email" required>
                </div>
                <button type="submit" id="request-btn">Send Reset Instructions</button>
            </form>
            <div id="request-message"></div>
        </div>

        <!-- Step 2: Complete Reset -->
        <div id="complete-reset-form" style="display: none;">
            <p>Enter your new password.</p>
            <form id="reset-complete-form">
                <div class="form-group">
                    <label for="new-password">New Password:</label>
                    <input type="password" id="new-password" name="password" required minlength="6">
                </div>
                <div class="form-group">
                    <label for="confirm-password">Confirm Password:</label>
                    <input type="password" id="confirm-password" name="password_confirmation" required minlength="6">
                </div>
                <button type="submit" id="complete-btn">Reset Password</button>
            </form>
            <div id="complete-message"></div>
        </div>
    </div>

    <script>
        // Password Reset Implementation
        class PasswordResetManager {
            constructor() {
                this.apiConfig = {
                    baseURL: 'https://your-domain.com/api/v1',
                    credentials: 'include'
                };
                this.currentToken = null;
                this.initializeEventListeners();
                this.checkForToken();
            }

            initializeEventListeners() {
                // Request reset form
                document.getElementById('reset-request-form').addEventListener('submit', (e) => {
                    e.preventDefault();
                    this.handleResetRequest();
                });

                // Complete reset form
                document.getElementById('reset-complete-form').addEventListener('submit', (e) => {
                    e.preventDefault();
                    this.handleResetComplete();
                });
            }

            checkForToken() {
                // Check if we have a token in the URL
                const token = this.extractTokenFromURL();
                if (token) {
                    this.currentToken = token;
                    this.showCompleteResetForm();
                }
            }

            extractTokenFromURL() {
                const urlParams = new URLSearchParams(window.location.search);
                return urlParams.get('token');
            }

            showCompleteResetForm() {
                document.getElementById('request-reset-form').style.display = 'none';
                document.getElementById('complete-reset-form').style.display = 'block';
            }

            async handleResetRequest() {
                const email = document.getElementById('email').value;
                const button = document.getElementById('request-btn');
                const messageDiv = document.getElementById('request-message');

                if (!email) {
                    this.showMessage(messageDiv, 'Please enter your email address', 'error');
                    return;
                }

                button.disabled = true;
                button.textContent = 'Sending...';

                try {
                    const result = await this.requestPasswordReset(email);
                    if (result.success) {
                        this.showMessage(messageDiv, result.message, 'success');
                        document.getElementById('reset-request-form').reset();
                    } else {
                        this.showMessage(messageDiv, result.error, 'error');
                    }
                } catch (error) {
                    this.showMessage(messageDiv, 'An error occurred. Please try again.', 'error');
                } finally {
                    button.disabled = false;
                    button.textContent = 'Send Reset Instructions';
                }
            }

            async handleResetComplete() {
                const password = document.getElementById('new-password').value;
                const confirmPassword = document.getElementById('confirm-password').value;
                const button = document.getElementById('complete-btn');
                const messageDiv = document.getElementById('complete-message');

                // Validate passwords
                if (!password || password.length < 6) {
                    this.showMessage(messageDiv, 'Password must be at least 6 characters long', 'error');
                    return;
                }

                if (password !== confirmPassword) {
                    this.showMessage(messageDiv, 'Passwords do not match', 'error');
                    return;
                }

                if (!this.currentToken) {
                    this.showMessage(messageDiv, 'Invalid or missing reset token', 'error');
                    return;
                }

                button.disabled = true;
                button.textContent = 'Resetting...';

                try {
                    const result = await this.completePasswordReset(this.currentToken, password);
                    if (result.success) {
                        this.showMessage(messageDiv, result.message + ' Redirecting to login...', 'success');
                        // Redirect to login page after successful reset
                        setTimeout(() => {
                            window.location.href = '/login';
                        }, 2000);
                    } else {
                        this.showMessage(messageDiv, result.error, 'error');
                    }
                } catch (error) {
                    this.showMessage(messageDiv, 'An error occurred. Please try again.', 'error');
                } finally {
                    button.disabled = false;
                    button.textContent = 'Reset Password';
                }
            }

            async requestPasswordReset(email) {
                try {
                    const response = await fetch(`${this.apiConfig.baseURL}/password/reset`, {
                        method: 'POST',
                        credentials: 'include',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({ email })
                    });

                    if (!response.ok) {
                        const errorData = await response.json();
                        throw new Error(errorData.error || 'Password reset request failed');
                    }

                    const data = await response.json();
                    return {
                        success: true,
                        message: data.message
                    };
                } catch (error) {
                    return {
                        success: false,
                        error: error.message
                    };
                }
            }

            async completePasswordReset(token, password) {
                try {
                    const response = await fetch(`${this.apiConfig.baseURL}/password/reset/${token}`, {
                        method: 'PUT',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({ password })
                    });

                    if (!response.ok) {
                        const errorData = await response.json();
                        throw new Error(errorData.error || 'Password reset failed');
                    }

                    const data = await response.json();
                    return {
                        success: true,
                        message: data.message
                    };
                } catch (error) {
                    return {
                        success: false,
                        error: error.message
                    };
                }
            }

            showMessage(element, message, type) {
                element.textContent = message;
                element.className = type;
                element.style.display = 'block';
            }
        }

        // Initialize the password reset manager
        const passwordResetManager = new PasswordResetManager();
    </script>
</body>
</html>
```

### React Component Example

```javascript
import React, { useState, useEffect } from 'react';

const PasswordReset = () => {
  const [step, setStep] = useState('request'); // 'request' or 'complete'
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [token, setToken] = useState('');

  const apiConfig = {
    baseURL: 'https://your-domain.com/api/v1',
    credentials: 'include'
  };

  useEffect(() => {
    // Check for token in URL
    const urlParams = new URLSearchParams(window.location.search);
    const urlToken = urlParams.get('token');
    if (urlToken) {
      setToken(urlToken);
      setStep('complete');
    }
  }, []);

  const handleRequestReset = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    setMessage('');

    try {
      const response = await fetch(`${apiConfig.baseURL}/password/reset`, {
        method: 'POST',
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ email })
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Password reset request failed');
      }

      const data = await response.json();
      setMessage(data.message);
      setEmail('');
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleCompleteReset = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    setMessage('');

    // Validate passwords
    if (password.length < 6) {
      setError('Password must be at least 6 characters long');
      setLoading(false);
      return;
    }

    if (password !== confirmPassword) {
      setError('Passwords do not match');
      setLoading(false);
      return;
    }

    try {
      const response = await fetch(`${apiConfig.baseURL}/password/reset/${token}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ password })
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Password reset failed');
      }

      const data = await response.json();
      setMessage(data.message + ' Redirecting to login...');
      
      // Redirect to login after successful reset
      setTimeout(() => {
        window.location.href = '/login';
      }, 2000);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="password-reset-container">
      <h2>Password Reset</h2>
      
      {step === 'request' && (
        <form onSubmit={handleRequestReset}>
          <p>Enter your email address to receive password reset instructions.</p>
          <div className="form-group">
            <label htmlFor="email">Email Address:</label>
            <input
              type="email"
              id="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              disabled={loading}
            />
          </div>
          <button type="submit" disabled={loading || !email}>
            {loading ? 'Sending...' : 'Send Reset Instructions'}
          </button>
        </form>
      )}

      {step === 'complete' && (
        <form onSubmit={handleCompleteReset}>
          <p>Enter your new password.</p>
          <div className="form-group">
            <label htmlFor="password">New Password:</label>
            <input
              type="password"
              id="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              minLength="6"
              disabled={loading}
            />
          </div>
          <div className="form-group">
            <label htmlFor="confirm-password">Confirm Password:</label>
            <input
              type="password"
              id="confirm-password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              required
              minLength="6"
              disabled={loading}
            />
          </div>
          <button type="submit" disabled={loading || !password || !confirmPassword}>
            {loading ? 'Resetting...' : 'Reset Password'}
          </button>
        </form>
      )}

      {message && <div className="success-message">{message}</div>}
      {error && <div className="error-message">{error}</div>}
    </div>
  );
};

export default PasswordReset;
```

### Password Reset Security Considerations

1. **Token Expiration**: Password reset tokens have a limited lifespan for security
2. **Single Use**: Tokens can only be used once
3. **Email Validation**: The system only sends reset emails to registered email addresses
4. **Rate Limiting**: Consider implementing rate limiting on password reset requests
5. **Secure Transmission**: Always use HTTPS for password reset requests

### Error Handling

```javascript
// Enhanced error handling for password reset
async function handlePasswordResetError(response) {
  switch (response.status) {
    case 400:
      return 'Invalid request. Please check your input.';
    case 401:
      return 'Invalid or expired reset token.';
    case 422:
      const errorData = await response.json();
      return errorData.error || 'Validation error.';
    case 429:
      return 'Too many reset requests. Please wait before trying again.';
    case 500:
      return 'Server error. Please try again later.';
    default:
      return 'An unexpected error occurred.';
  }
}
```

## Error Handling

### Authentication Error Handling

```javascript
function handleUnauthorized() {
  // Clear any stored user data
  clearUserData();
  
  // Redirect to login page
  if (typeof window !== 'undefined') {
    window.location.href = '/login';
  }
}

function clearUserData() {
  // Clear any client-side user data
  if (typeof localStorage !== 'undefined') {
    localStorage.removeItem('user_data');
    localStorage.removeItem('user_preferences');
  }
  
  // Clear any global user state
  if (typeof window !== 'undefined' && window.userState) {
    window.userState.clear();
  }
}

// Enhanced error handling for API requests
async function handleApiResponse(response) {
  if (response.ok) {
    return await response.json();
  }

  switch (response.status) {
    case 401:
      handleUnauthorized();
      throw new Error('Authentication required');
    case 403:
      throw new Error('Insufficient permissions');
    case 404:
      throw new Error('Resource not found');
    case 422:
      const errorData = await response.json();
      throw new Error(errorData.errors?.join(', ') || 'Validation error');
    case 500:
      throw new Error('Server error');
    default:
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }
}
```

## Security Best Practices

### 1. Token Security

```javascript
// For web applications, prefer cookie-based auth
// For mobile/desktop apps, use secure storage
class SecureTokenStorage {
  constructor() {
    this.isWebClient = typeof window !== 'undefined';
  }

  setTokens(accessToken, refreshToken) {
    if (this.isWebClient) {
      // For web clients, tokens should be stored in httpOnly cookies
      // This is handled server-side, not in JavaScript
      console.warn('For web clients, use cookie-based authentication');
    } else {
      // For mobile/desktop apps, use secure storage
      // Implementation depends on platform (Keychain, Keystore, etc.)
      this.storeSecurely(accessToken, refreshToken);
    }
  }

  storeSecurely(accessToken, refreshToken) {
    // Platform-specific secure storage implementation
    // This is a placeholder - implement based on your platform
    console.log('Store tokens securely for your platform');
  }
}
```

### 2. HTTPS Only

```javascript
// Ensure all API calls use HTTPS
const apiConfig = {
  baseURL: 'https://your-domain.com/api/v1', // Always HTTPS
  // ... other config
};
```

### 3. Request Validation

```javascript
// Validate requests before sending
function validateRequest(endpoint, options) {
  if (!endpoint.startsWith('/')) {
    throw new Error('Endpoint must start with /');
  }
  
  if (options.body && typeof options.body === 'object') {
    options.body = JSON.stringify(options.body);
  }
  
  return options;
}
```

## CSRF Protection with SameSite Cookies

### How SameSite: Lax Works

The Rails API Template uses `SameSite: :lax` cookie policy as the primary CSRF protection mechanism:

1. **Same-Site Requests**: Cookies are automatically sent with requests to the same domain
2. **Cross-Site Requests**: Cookies are NOT sent with cross-site requests (prevents CSRF)
3. **Top-Level Navigation**: Cookies are sent when users navigate to your site from external links
4. **Simple Implementation**: No additional tokens or headers required

### Benefits of SameSite: Lax

- **Automatic Protection**: No need to manage CSRF tokens manually
- **Simpler Code**: Reduces complexity in frontend authentication
- **Strong Security**: Effectively prevents CSRF attacks
- **Browser Support**: Widely supported across modern browsers
- **Performance**: No additional network requests for token management

### When SameSite: Lax is Sufficient

This approach is ideal for:
- **Web Applications**: Traditional web apps with same-origin requests
- **SPAs**: Single-page applications served from the same domain
- **API-First Apps**: Where the frontend and API share the same domain or subdomain

### When You Might Need Additional CSRF Protection

Consider additional CSRF protection if:
- You have complex cross-origin scenarios
- You need to support older browsers
- You have specific security requirements that exceed SameSite protection

## Token Management

### Automatic Token Refresh

```javascript
class TokenRefreshManager {
  constructor() {
    this.refreshPromise = null;
  }

  async ensureValidToken() {
    if (this.isWebClient) {
      // For web clients with cookies, tokens are managed server-side
      return true;
    }

    const accessToken = tokenManager.getAccessToken();
    if (!accessToken) {
      return false;
    }

    // Check if token is expired (you might want to decode JWT to check expiration)
    if (this.isTokenExpired(accessToken)) {
      return await this.refreshToken();
    }

    return true;
  }

  async refreshToken() {
    // Prevent multiple simultaneous refresh attempts
    if (this.refreshPromise) {
      return this.refreshPromise;
    }

    this.refreshPromise = refreshAccessToken();
    
    try {
      const result = await this.refreshPromise;
      return result;
    } finally {
      this.refreshPromise = null;
    }
  }

  isTokenExpired(token) {
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      const expirationTime = payload.exp * 1000; // Convert to milliseconds
      return Date.now() >= expirationTime;
    } catch (error) {
      return true; // If we can't decode, assume expired
    }
  }
}

const tokenRefreshManager = new TokenRefreshManager();
```

### Token Cleanup

```javascript
// Clean up tokens on app unload
if (typeof window !== 'undefined') {
  window.addEventListener('beforeunload', () => {
    // For bearer token auth, you might want to revoke tokens
    if (!client.isWebClient) {
      // Revoke tokens if possible
      revokeTokens();
    }
  });
}

async function revokeTokens() {
  try {
    const refreshToken = tokenManager.getRefreshToken();
    if (refreshToken) {
      await fetch(`${apiConfig.baseURL}/logout`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ refresh_token: refreshToken })
      });
    }
  } catch (error) {
    console.error('Token revocation failed:', error);
  }
}
```

## Conclusion

This guide provides comprehensive authentication strategies for JavaScript clients interacting with the Rails API Template API. Choose the appropriate authentication method based on your client type:

- **Web Applications**: Use cookie-based authentication for better security and automatic token management
- **Mobile/Desktop Apps**: Use bearer token authentication with secure token storage
- **Server-to-Server**: Use bearer token authentication with proper token management

Always follow security best practices and implement proper error handling to ensure a secure and reliable authentication experience.
