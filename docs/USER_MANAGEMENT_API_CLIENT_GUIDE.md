# Rails API Template User Management API Client Guide

## Overview

This guide provides comprehensive instructions for API clients on how to retrieve, update, and manage user information using the Rails API Template API. The user management system supports profile management, role assignments, and password updates.

## Table of Contents

1. [API Base URL](#api-base-url)
2. [Authentication](#authentication)
3. [User Data Structure](#user-data-structure)
4. [API Endpoints](#api-endpoints)
5. [Role Management](#role-management)
6. [Complete Examples](#complete-examples)
7. [Error Handling](#error-handling)
8. [Best Practices](#best-practices)

## API Base URL

```
https://your-domain.com/api/v1
```

## Authentication

**Important**: This guide assumes you have already authenticated with the Rails API Template API. For detailed authentication instructions, please refer to the [JavaScript API Authentication Guide](JAVASCRIPT_API_AUTHENTICATION_GUIDE.md).

The Rails API Template API supports both cookie-based authentication (recommended for web applications) and bearer token authentication (for mobile apps and other clients).

## User Data Structure

### User Attributes

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "type": "user",
  "attributes": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+1234567890",
    "email_confirmed": true,
    "phone_confirmed": true,
    "is_profile_complete": true,
    "require_password_change": false,
    "profile": {
      "bio": "Software developer with 5 years experience",
      "department": "Engineering",
      "job_title": "Senior Software Developer",
      "skills": ["JavaScript", "Ruby", "React"],
      "location": "San Francisco, CA",
      "hire_date": "2020-01-15"
    },
    "roles": ["user", "facilitator"],
    "avatar_url": "https://your-instance.com/rails/active_storage/blobs/.../avatar.jpg",
    "avatar_info": {
      "filename": "avatar.jpg",
      "content_type": "image/jpeg",
      "byte_size": 245760,
      "checksum": "abc123def456..."
    },
    "created_at": "2024-01-01T00:00:00.000Z",
    "updated_at": "2024-01-01T00:00:00.000Z"
  }
}
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Unique identifier for the user |
| `name` | String | Full name of the user |
| `email` | String | Email address (unique, case-insensitive) |
| `phone` | String | Phone number in E.164 format (e.g., +1234567890) |
| `email_confirmed` | Boolean | Whether the email address has been confirmed |
| `phone_confirmed` | Boolean | Whether the phone number has been confirmed |
| `is_profile_complete` | Boolean | Whether the user profile is complete |
| `require_password_change` | Boolean | Whether the user must change their password |
| `profile` | Object | Custom profile data (JSON object) |
| `roles` | Array | Array of role names assigned to the user |
| `avatar_url` | String | Full URL to the user's avatar image (null if no avatar is attached) |
| `avatar_info` | Object | Avatar file metadata (filename, content_type, byte_size, checksum) - only present when avatar is attached |
| `created_at` | DateTime | When the user was created |
| `updated_at` | DateTime | When the user was last updated |

## API Endpoints

### 1. Get Current User Information

Retrieve information about the currently authenticated user:

```http
GET /api/v1/users/me
```

**Response:**
```json
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "type": "user",
    "attributes": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Current User",
      "email": "current@example.com",
      "phone": "+1234567890",
      "email_confirmed": true,
      "phone_confirmed": false,
      "is_profile_complete": false,
      "require_password_change": false,
      "profile": {
        "bio": "Software developer",
        "location": "San Francisco"
      },
      "roles": ["user", "facilitator"],
      "avatar_url": null,
      "avatar_info": null,
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-01T00:00:00.000Z"
    }
  }
}
```

### 2. List All Users

Retrieve a list of all users (requires appropriate permissions):

```http
GET /api/v1/users
```

**Response:**
```json
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "type": "user",
      "attributes": {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "name": "John Doe",
        "email": "john@example.com",
        "phone": "+1234567890",
        "email_confirmed": true,
        "phone_confirmed": true,
        "is_profile_complete": true,
        "require_password_change": false,
        "profile": {
          "bio": "Software developer with 5 years experience",
          "department": "Engineering",
          "job_title": "Senior Software Developer",
          "skills": ["JavaScript", "Ruby", "React"],
          "location": "San Francisco, CA",
          "hire_date": "2020-01-15"
        },
        "roles": ["user"],
        "avatar_url": null,
        "avatar_info": null,
        "created_at": "2024-01-01T00:00:00.000Z",
        "updated_at": "2024-01-01T00:00:00.000Z"
      }
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "type": "user",
      "attributes": {
        "id": "550e8400-e29b-41d4-a716-446655440001",
        "name": "Jane Smith",
        "email": "jane@example.com",
        "phone": "+1987654321",
        "email_confirmed": true,
        "phone_confirmed": false,
        "is_profile_complete": false,
        "require_password_change": true,
        "profile": {},
        "roles": ["user", "facilitator"],
        "avatar_url": null,
        "avatar_info": null,
        "created_at": "2024-01-02T00:00:00.000Z",
        "updated_at": "2024-01-02T00:00:00.000Z"
      }
    }
  ]
}
```

### 3. Get Specific User

Retrieve information about a specific user by ID:

```http
GET /api/v1/users/{user_id}
```

**Response:**
```json
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "type": "user",
    "attributes": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Test User",
      "email": "test@example.com",
      "phone": "+1234567890",
      "email_confirmed": true,
      "phone_confirmed": true,
      "is_profile_complete": true,
      "require_password_change": false,
      "profile": {
        "bio": "Test user bio",
        "location": "Test City"
      },
      "roles": ["user"],
      "avatar_url": null,
      "avatar_info": null,
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-01T00:00:00.000Z"
    }
  }
}
```

### 4. Update User Profile

Update user profile information:

```http
PATCH /api/v1/users/{user_id}
```

**Request Body (JSON for text fields only):**
```json
{
  "user": {
    "name": "John Smith",
    "phone": "+15551234567",
    "profile": {
      "bio": "Experienced software developer with expertise in web technologies",
      "department": "Engineering",
      "job_title": "Senior Software Developer",
      "skills": ["JavaScript", "Ruby", "React", "Node.js"],
      "location": "San Francisco, CA",
      "hire_date": "2020-01-15",
      "manager_email": "manager@example.com",
      "emergency_contact": {
        "name": "Jane Smith",
        "phone": "+15551234567",
        "relationship": "Spouse"
      }
    }
  }
}
```

**Request Body (multipart/form-data for avatar upload):**

To upload an avatar image, use `multipart/form-data` content type:

```javascript
const formData = new FormData();
formData.append('user[name]', 'John Smith');
formData.append('user[phone]', '+15551234567');
formData.append('user[avatar]', avatarFileInput.files[0]); // File input

// For profile, you'll need to stringify it if including
const profileData = {
  bio: "Experienced software developer",
  department: "Engineering"
};
formData.append('user[profile]', JSON.stringify(profileData));

const response = await fetch(`/api/v1/users/${userId}`, {
  method: 'PATCH',
  credentials: 'include',
  body: formData
});
```

**Remove Avatar:**

To remove the avatar attachment from a user profile, send a PATCH request with `Content-Type: application/json` and set `avatar` to `null`:

```http
PATCH /api/v1/users/{user_id}
Content-Type: application/json
```

**Request Body:**
```json
{
  "user": {
    "avatar": null
  }
}
```

**JavaScript Example:**
```javascript
const response = await fetch(`/api/v1/users/${userId}`, {
  method: 'PATCH',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  },
  body: JSON.stringify({
    user: {
      avatar: null
    }
  })
});
```

**Response:**
```json
{
  "data": {
    "attributes": {
      "avatar_url": null,
      "avatar_info": null
    }
  }
}
```

**Full Update Response:**
```json
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "type": "user",
    "attributes": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "John Smith",
      "email": "john.doe@example.com",
      "phone": "+15551234567",
      "email_confirmed": true,
      "phone_confirmed": false,
      "is_profile_complete": true,
      "require_password_change": false,
      "profile": {
        "bio": "Experienced software developer with expertise in web technologies",
        "department": "Engineering",
        "job_title": "Senior Software Developer",
        "skills": ["JavaScript", "Ruby", "React", "Node.js"],
        "location": "San Francisco, CA",
        "hire_date": "2020-01-15",
        "manager_email": "manager@example.com",
        "emergency_contact": {
          "name": "Jane Smith",
          "phone": "+15551234567",
          "relationship": "Spouse"
        }
      },
      "roles": ["user"],
      "avatar_url": "https://your-instance.com/rails/active_storage/blobs/.../avatar.jpg",
      "avatar_info": {
        "filename": "avatar.jpg",
        "content_type": "image/jpeg",
        "byte_size": 245760,
        "checksum": "abc123def456..."
      },
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-01T12:00:00.000Z"
    }
  }
}
```

**Notes:**
- Changing the phone number will automatically reset phone confirmation and send a verification SMS.
- To upload an avatar, use `multipart/form-data` content type and include the avatar file in the request.
- The `avatar_url` field will be `null` if no avatar is attached.
- The `avatar_info` field will be `null` if no avatar is attached.

**Avatar Info Fields:**
- `filename`: Original filename of the uploaded avatar image
- `content_type`: MIME type of the image (e.g., "image/jpeg", "image/png")
- `byte_size`: Size of the image file in bytes
- `checksum`: SHA-256 hash of the file content (used for caching and change detection)

### Avatar Caching with Checksums

The `checksum` field in `avatar_info` allows clients to cache avatar images and avoid re-downloading unchanged files. This is especially useful when displaying user lists or profiles, as avatars rarely change.

**Caching Strategy:**

1. **Store checksums locally** with downloaded avatar images
2. **Before downloading**, compare the API checksum with your local checksum
3. **Only download** if checksums differ or the avatar doesn't exist locally
4. **Use cached image** if checksums match

**JavaScript Example:**

```javascript
// Avatar cache storage
const avatarCache = new Map();

// Check if avatar should be downloaded
function shouldDownloadAvatar(user) {
  if (!user.attributes.avatar_info || !user.attributes.avatar_url) return false;
  
  const cached = avatarCache.get(user.attributes.avatar_url);
  
  // Not cached, download it
  if (!cached) return true;
  
  // Checksum changed, avatar was updated, download new version
  if (cached.checksum !== user.attributes.avatar_info.checksum) return true;
  
  // Same checksum, use cached version
  return false;
}

// Download avatar with caching
async function downloadAvatarWithCache(user) {
  if (!user.attributes.avatar_info || !user.attributes.avatar_url) return null;
  
  const avatarUrl = user.attributes.avatar_url;
  const avatarInfo = user.attributes.avatar_info;
  
  // Check if we need to download
  if (!shouldDownloadAvatar(user)) {
    const cached = avatarCache.get(avatarUrl);
    console.log('Using cached avatar for user:', user.attributes.name);
    return cached.blob; // Return cached blob
  }
  
  // Download the avatar
  console.log('Downloading avatar for user:', user.attributes.name);
  const response = await fetch(avatarUrl);
  const blob = await response.blob();
  
  // Store in cache with checksum
  avatarCache.set(avatarUrl, {
    checksum: avatarInfo.checksum,
    blob: blob,
    timestamp: Date.now(),
    userId: user.id
  });
  
  return blob;
}

// Example: Display user avatar with caching
async function displayUserAvatar(user, imgElement) {
  const blob = await downloadAvatarWithCache(user);
  if (blob) {
    imgElement.src = URL.createObjectURL(blob);
  }
}
```

**Benefits:**
- **Reduced Bandwidth**: Avoid downloading unchanged avatars
- **Faster Performance**: Instant display of cached avatars in user lists
- **Better UX**: Faster loading times when browsing users

### Email Confirmation URL Handling

When users register or update their email address, they receive an email with a confirmation link. Your frontend application needs to handle the confirmation URL and complete the email verification process. The confirmation URLs follow this format:

```
[FRONTEND_URL]/confirm-email?token=[CONFIRMATION_TOKEN]
```

#### Required Frontend Route

Your frontend application should have a route that handles `/confirm-email` with a token query parameter:

**React Router Example:**
```javascript
// App.js or your main router file
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import ConfirmEmailPage from './components/ConfirmEmailPage';

function App() {
  return (
    <Router>
      <Routes>
        {/* Other routes */}
        <Route path="/confirm-email" element={<ConfirmEmailPage />} />
      </Routes>
    </Router>
  );
}
```

**Vue Router Example:**
```javascript
// router/index.js
import { createRouter, createWebHistory } from 'vue-router';
import ConfirmEmail from '@/views/ConfirmEmail.vue';

const routes = [
  // Other routes
  {
    path: '/confirm-email',
    name: 'ConfirmEmail',
    component: ConfirmEmail
  }
];
```

**Next.js Example:**
```javascript
// pages/confirm-email.js or app/confirm-email/page.js
export default function ConfirmEmail() {
  // Component implementation
}
```

#### API Endpoint

**POST** `/api/v1/confirm_email`

**Request Body:**
```json
{
  "token": "confirmation_token_from_email"
}
```

**Success Response (200):**
```json
{
  "message": "Email confirmed successfully. You can now log in."
}
```

**Error Response (422):**
```json
{
  "error": "Invalid or expired confirmation token."
}
```

#### Frontend Implementation Example

Here's a complete React component example for handling email confirmation:

```javascript
// components/ConfirmEmailPage.js
import React, { useState, useEffect } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';

function ConfirmEmailPage() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [confirmed, setConfirmed] = useState(false);
  const [error, setError] = useState('');

  const token = searchParams.get('token');

  useEffect(() => {
    if (!token) {
      setError('Invalid confirmation link. No token provided.');
      return;
    }

    // Automatically confirm email when component loads
    confirmEmail(token);
  }, [token]);

  const confirmEmail = async (emailToken) => {
    setLoading(true);
    setError('');

    try {
      const response = await fetch('/api/v1/confirm_email', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include',
        body: JSON.stringify({
          token: emailToken
        })
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to confirm email');
      }

      const data = await response.json();
      setConfirmed(true);
      
      // Redirect to login after a short delay
      setTimeout(() => {
        navigate('/login', { 
          state: { 
            message: data.message || 'Email confirmed successfully!',
            emailConfirmed: true 
          }
        });
      }, 2000);

    } catch (error) {
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="confirm-email-page">
        <div className="loading-container">
          <div className="spinner"></div>
          <p>Confirming your email address...</p>
        </div>
      </div>
    );
  }

  if (confirmed) {
    return (
      <div className="confirm-email-page">
        <div className="success-container">
          <h1>✓ Email Confirmed!</h1>
          <p>Your email address has been confirmed successfully.</p>
          <p>Redirecting to login...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="confirm-email-page">
        <div className="error-container">
          <h1>✗ Confirmation Failed</h1>
          <p>{error}</p>
          {token && (
            <button onClick={() => confirmEmail(token)}>Try Again</button>
          )}
          <div className="help-links">
            <p>Need help? <a href="/resend-confirmation">Resend confirmation email</a></p>
            <p><a href="/login">Go to Login</a></p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="confirm-email-page">
      <div className="info-container">
        <h1>Email Confirmation</h1>
        <p>No confirmation token found. Please check your email and click the confirmation link.</p>
        <button onClick={() => navigate('/login')}>Go to Login</button>
      </div>
    </div>
  );
}

export default ConfirmEmailPage;
```

#### Resending Confirmation Email

If a user needs a new confirmation email, they can request one:

**POST** `/api/v1/send_email_confirmation`

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Success Response (200):**
```json
{
  "message": "If your account exists and is not confirmed, a confirmation email has been sent."
}
```

```javascript
// Helper function to resend confirmation email
async function resendConfirmationEmail(email) {
  try {
    const response = await fetch('/api/v1/send_email_confirmation', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      credentials: 'include',
      body: JSON.stringify({ email })
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error || 'Failed to send confirmation email');
    }

    const data = await response.json();
    return data.message;
  } catch (error) {
    console.error('Error resending confirmation email:', error);
    throw error;
  }
}
```

#### Key Implementation Points

1. **URL Parameter Extraction**: Extract the `token` from the URL query parameters
2. **Token Validation**: Validate that a token is present
3. **API Integration**: Call the `/api/v1/confirm_email` endpoint
4. **Error Handling**: Display appropriate error messages for invalid/expired tokens
5. **Success Redirect**: Redirect users to login after successful confirmation
6. **Loading States**: Show loading indicators during the confirmation process
7. **Resend Option**: Provide a way for users to request a new confirmation email

### Password Reset URL Handling

When users request a password reset, they receive an email with a reset link. Your frontend application needs to handle the reset URL and guide them through the password reset process. The reset URLs follow this format:

```
[FRONTEND_URL]/reset-password?token=[RESET_TOKEN]
```

#### Required Frontend Route

Your frontend application should have a route that handles `/reset-password` with a token query parameter:

**React Router Example:**
```javascript
// App.js or your main router file
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import ResetPasswordPage from './components/ResetPasswordPage';

function App() {
  return (
    <Router>
      <Routes>
        {/* Other routes */}
        <Route path="/reset-password" element={<ResetPasswordPage />} />
      </Routes>
    </Router>
  );
}
```

**Vue Router Example:**
```javascript
// router/index.js
import { createRouter, createWebHistory } from 'vue-router';
import ResetPassword from '@/views/ResetPassword.vue';

const routes = [
  // Other routes
  {
    path: '/reset-password',
    name: 'ResetPassword',
    component: ResetPassword
  }
];
```

**Next.js Example:**
```javascript
// pages/reset-password.js or app/reset-password/page.js
export default function ResetPassword() {
  // Component implementation
}
```

#### API Endpoints

##### Request Password Reset

**POST** `/api/v1/password/reset`

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Success Response (200):**
```json
{
  "message": "Password reset instructions sent (if user with that email exists)."
}
```

##### Complete Password Reset

**PUT** `/api/v1/password/reset/:token`

**Request Body:**
```json
{
  "password": "newsecurepassword"
}
```

**Success Response (200):**
```json
{
  "message": "Password has been reset."
}
```

**Error Response (401):**
```json
{
  "error": "Invalid token"
}
```
or
```json
{
  "error": "Token has already been used"
}
```
or
```json
{
  "error": "Token has expired"
}
```

#### Frontend Implementation Example

Here's a complete React component example for handling password reset:

```javascript
// components/ResetPasswordPage.js
import React, { useState, useEffect } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';

function ResetPasswordPage() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [reset, setReset] = useState(false);
  const [error, setError] = useState('');
  const [formData, setFormData] = useState({
    password: '',
    password_confirmation: ''
  });

  const token = searchParams.get('token');

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    // Validate passwords match
    if (formData.password !== formData.password_confirmation) {
      setError('Passwords do not match');
      setLoading(false);
      return;
    }

    // Validate password strength
    if (formData.password.length < 6) {
      setError('Password must be at least 6 characters long');
      setLoading(false);
      return;
    }

    if (!token) {
      setError('Invalid reset token');
      setLoading(false);
      return;
    }

    try {
      const response = await fetch(`/api/v1/password/reset/${token}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include',
        body: JSON.stringify({
          password: formData.password
        })
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to reset password');
      }

      const data = await response.json();
      setReset(true);
      
      // Redirect to login after a short delay
      setTimeout(() => {
        navigate('/login', { 
          state: { 
            message: data.message || 'Password reset successfully!',
            passwordReset: true 
          }
        });
      }, 2000);

    } catch (error) {
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };

  if (!token) {
    return (
      <div className="reset-password-page">
        <div className="error-container">
          <h1>Invalid Reset Link</h1>
          <p>This password reset link is invalid or malformed.</p>
          <button onClick={() => navigate('/forgot-password')}>Request New Reset Link</button>
          <button onClick={() => navigate('/login')}>Go to Login</button>
        </div>
      </div>
    );
  }

  if (reset) {
    return (
      <div className="reset-password-page">
        <div className="success-container">
          <h1>✓ Password Reset Successful!</h1>
          <p>Your password has been reset successfully.</p>
          <p>Redirecting to login...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="reset-password-page">
      <div className="reset-form-container">
        <h1>Reset Your Password</h1>
        <p>Enter your new password below.</p>
        
        {error && (
          <div className="error-message">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="reset-form">
          <div className="form-group">
            <label htmlFor="password">New Password *</label>
            <input
              type="password"
              id="password"
              name="password"
              value={formData.password}
              onChange={handleInputChange}
              required
              disabled={loading}
              placeholder="Enter new password (min 6 characters)"
              minLength="6"
            />
          </div>

          <div className="form-group">
            <label htmlFor="password_confirmation">Confirm Password *</label>
            <input
              type="password"
              id="password_confirmation"
              name="password_confirmation"
              value={formData.password_confirmation}
              onChange={handleInputChange}
              required
              disabled={loading}
              placeholder="Confirm new password"
              minLength="6"
            />
          </div>

          <button 
            type="submit" 
            disabled={loading || !formData.password || !formData.password_confirmation}
            className="submit-button"
          >
            {loading ? 'Resetting Password...' : 'Reset Password'}
          </button>
        </form>

        <div className="help-links">
          <p><a href="/login">Back to Login</a></p>
        </div>
      </div>
    </div>
  );
}

export default ResetPasswordPage;
```

#### Requesting Password Reset

Users can request a password reset from your application:

```javascript
// Helper function to request password reset
async function requestPasswordReset(email) {
  try {
    const response = await fetch('/api/v1/password/reset', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      credentials: 'include',
      body: JSON.stringify({ email })
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error || 'Failed to request password reset');
    }

    const data = await response.json();
    return data.message;
  } catch (error) {
    console.error('Error requesting password reset:', error);
    throw error;
  }
}
```

#### Vue.js Implementation Example

```vue
<!-- views/ResetPassword.vue -->
<template>
  <div class="reset-password-page">
    <div v-if="!token" class="error-container">
      <h1>Invalid Reset Link</h1>
      <p>This password reset link is invalid or malformed.</p>
      <button @click="$router.push('/forgot-password')">Request New Reset Link</button>
      <button @click="$router.push('/login')">Go to Login</button>
    </div>

    <div v-else-if="reset" class="success-container">
      <h1>✓ Password Reset Successful!</h1>
      <p>Your password has been reset successfully.</p>
      <p>Redirecting to login...</p>
    </div>

    <div v-else class="reset-form-container">
      <h1>Reset Your Password</h1>
      <p>Enter your new password below.</p>
      
      <div v-if="error" class="error-message">
        {{ error }}
      </div>

      <form @submit.prevent="handleSubmit" class="reset-form">
        <div class="form-group">
          <label for="password">New Password *</label>
          <input
            type="password"
            id="password"
            v-model="formData.password"
            required
            :disabled="loading"
            placeholder="Enter new password (min 6 characters)"
            minlength="6"
          />
        </div>

        <div class="form-group">
          <label for="password_confirmation">Confirm Password *</label>
          <input
            type="password"
            id="password_confirmation"
            v-model="formData.password_confirmation"
            required
            :disabled="loading"
            placeholder="Confirm new password"
            minlength="6"
          />
        </div>

        <button 
          type="submit" 
          :disabled="loading || !isFormValid"
          class="submit-button"
        >
          {{ loading ? 'Resetting Password...' : 'Reset Password' }}
        </button>
      </form>

      <div class="help-links">
        <p><router-link to="/login">Back to Login</router-link></p>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ResetPassword',
  data() {
    return {
      loading: false,
      reset: false,
      error: '',
      formData: {
        password: '',
        password_confirmation: ''
      }
    };
  },
  computed: {
    token() {
      return this.$route.query.token;
    },
    isFormValid() {
      return this.formData.password && 
             this.formData.password_confirmation &&
             this.formData.password.length >= 6;
    }
  },
  methods: {
    async handleSubmit() {
      this.loading = true;
      this.error = '';

      if (this.formData.password !== this.formData.password_confirmation) {
        this.error = 'Passwords do not match';
        this.loading = false;
        return;
      }

      if (this.formData.password.length < 6) {
        this.error = 'Password must be at least 6 characters long';
        this.loading = false;
        return;
      }

      try {
        const response = await fetch(`/api/v1/password/reset/${this.token}`, {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
          },
          credentials: 'include',
          body: JSON.stringify({
            password: this.formData.password
          })
        });

        if (!response.ok) {
          const errorData = await response.json();
          throw new Error(errorData.error || 'Failed to reset password');
        }

        const data = await response.json();
        this.reset = true;
        
        setTimeout(() => {
          this.$router.push({
            path: '/login',
            state: { 
              message: data.message || 'Password reset successfully!',
              passwordReset: true 
            }
          });
        }, 2000);

      } catch (error) {
        this.error = error.message;
      } finally {
        this.loading = false;
      }
    }
  }
};
</script>
```

#### Key Implementation Points

1. **URL Parameter Extraction**: Extract the `token` from the URL query parameters
2. **Token Validation**: Validate that a token is present
3. **Password Validation**: Ensure passwords meet requirements and match
4. **API Integration**: Call the `/api/v1/password/reset/:token` endpoint
5. **Error Handling**: Display appropriate error messages for invalid/expired/used tokens
6. **Success Redirect**: Redirect users to login after successful reset
7. **Loading States**: Show loading indicators during the reset process
8. **Request Reset**: Provide a way for users to request password reset emails

#### Important Notes

- **Token Expiration**: Reset tokens expire after 1 hour
- **Single Use**: Tokens can only be used once - after successful reset, they become invalid
- **No Authentication Required**: The reset endpoint doesn't require authentication
- **Security**: Tokens are automatically marked as used after successful reset
- **Error Messages**: Handle specific error cases (invalid token, expired token, already used token)

### 5. Update User Password

Update user password with current password verification:

```http
PATCH /api/v1/users/{user_id}/password
```

**Request Body:**
```json
{
  "user": {
    "current_password": "currentpassword123",
    "password": "newpassword123",
    "password_confirmation": "newpassword123"
  }
}
```

**Response:**
```json
{
  "message": "Password updated successfully"
}
```

### 6. Update User Email

Update user email address with current password verification:

```http
PATCH /api/v1/users/{user_id}/email
```

**Request Body:**
```json
{
  "user": {
    "current_password": "currentpassword123",
    "email": "newemail@example.com"
  }
}
```

**Response:**
```json
{
  "message": "Email updated successfully. Please check your new email to confirm your account."
}
```

**Note**: The new email will need to be confirmed via email verification link.

### 7. Delete User

Delete a user (requires super admin permissions):

```http
DELETE /api/v1/users/{user_id}
```

**Response:**
```
204 No Content
```

## Role Management

### 1. List Available Roles

Get all available roles in the system:

```http
GET /api/v1/roles
```

**Response:**
```json
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "type": "role",
      "attributes": {
        "name": "user",
        "resource_type": null,
        "resource_id": null,
        "created_at": "2024-01-01T00:00:00.000Z",
        "updated_at": "2024-01-01T00:00:00.000Z"
      }
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "type": "role",
      "attributes": {
        "name": "facilitator",
        "resource_type": null,
        "resource_id": null,
        "created_at": "2024-01-01T00:00:00.000Z",
        "updated_at": "2024-01-01T00:00:00.000Z"
      }
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440002",
      "type": "role",
      "attributes": {
        "name": "org_admin",
        "resource_type": null,
        "resource_id": null,
        "created_at": "2024-01-01T00:00:00.000Z",
        "updated_at": "2024-01-01T00:00:00.000Z"
      }
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440003",
      "type": "role",
      "attributes": {
        "name": "super_admin",
        "resource_type": null,
        "resource_id": null,
        "created_at": "2024-01-01T00:00:00.000Z",
        "updated_at": "2024-01-01T00:00:00.000Z"
      }
    }
  ]
}
```

### 2. Assign Role to User

Assign a role to a user (global or resource-scoped):

```http
POST /api/v1/users/{user_id}/roles
```

**Request Body (Global Role):**
```json
{
  "role": "facilitator"
}
```

**Request Body (Resource-Scoped Role):**
```json
{
  "role": "facilitator",
  "resource_type": "Group",
  "resource_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response:**
```json
{
  "message": "Role 'facilitator' assigned to user for Group#550e8400-e29b-41d4-a716-446655440000"
}
```

### 3. Remove Role from User

Remove a role from a user:

```http
DELETE /api/v1/users/{user_id}/roles
```

**Request Body:**
```json
{
  "role": "facilitator",
  "resource_type": "Group",
  "resource_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response:**
```json
{
  "message": "Role 'facilitator' removed from user for Group#550e8400-e29b-41d4-a716-446655440000"
}
```

### Supported Resource Types for Role Assignment

- `Group`
- `Goal`
- `Milestone`
- `Task`
- `Event`
- `Resource`
- `Competency`

## Complete Examples

### JavaScript Helper Functions

```javascript
// Helper function to get current user information
async function getCurrentUser() {
  try {
    const response = await fetch('/api/v1/users/me', {
      method: 'GET',
      credentials: 'include',
      headers: {
        'Accept': 'application/json'
      }
    });

    if (!response.ok) {
      throw new Error(`Failed to get current user: ${response.statusText}`);
    }

    const data = await response.json();
    return data.data;
  } catch (error) {
    console.error('Error getting current user:', error);
    throw error;
  }
}

// Helper function to get all users
async function getAllUsers() {
  try {
    const response = await fetch('/api/v1/users', {
      method: 'GET',
      credentials: 'include',
      headers: {
        'Accept': 'application/json'
      }
    });

    if (!response.ok) {
      throw new Error(`Failed to get users: ${response.statusText}`);
    }

    const data = await response.json();
    return data.data;
  } catch (error) {
    console.error('Error getting users:', error);
    throw error;
  }
}

// Helper function to update user profile
// If avatarFile is provided, uses multipart/form-data; otherwise uses JSON
async function updateUserProfile(userId, profileData, avatarFile = null) {
  try {
    let headers, body;

    if (avatarFile) {
      // Use FormData for file uploads
      const formData = new FormData();
      Object.keys(profileData).forEach(key => {
        if (key === 'profile' && typeof profileData[key] === 'object') {
          // Stringify profile object if present
          formData.append(`user[profile]`, JSON.stringify(profileData[key]));
        } else if (key !== 'avatar') {
          formData.append(`user[${key}]`, profileData[key]);
        }
      });
      formData.append('user[avatar]', avatarFile);
      body = formData;
      // Don't set Content-Type header - browser will set it with boundary
      headers = {
        'Accept': 'application/json'
      };
    } else {
      // Use JSON for regular updates
      headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      };
      body = JSON.stringify({ user: profileData });
    }

    const response = await fetch(`/api/v1/users/${userId}`, {
      method: 'PATCH',
      credentials: 'include',
      headers: headers,
      body: body
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(`Failed to update profile: ${errorData.errors?.join(', ') || response.statusText}`);
    }

    const data = await response.json();
    return data.data;
  } catch (error) {
    console.error('Error updating user profile:', error);
    throw error;
  }
}

// Helper function to update password
async function updatePassword(userId, currentPassword, newPassword, passwordConfirmation) {
  try {
    const response = await fetch(`/api/v1/users/${userId}/password`, {
      method: 'PATCH',
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        user: {
          current_password: currentPassword,
          password: newPassword,
          password_confirmation: passwordConfirmation
        }
      })
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(`Failed to update password: ${errorData.errors?.join(', ') || response.statusText}`);
    }

    const data = await response.json();
    return data.message;
  } catch (error) {
    console.error('Error updating password:', error);
    throw error;
  }
}

// Helper function to assign role to user
async function assignRoleToUser(userId, roleName, resourceType = null, resourceId = null) {
  try {
    const requestBody = { role: roleName };
    if (resourceType && resourceId) {
      requestBody.resource_type = resourceType;
      requestBody.resource_id = resourceId;
    }

    const response = await fetch(`/api/v1/users/${userId}/roles`, {
      method: 'POST',
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify(requestBody)
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(`Failed to assign role: ${errorData.error || response.statusText}`);
    }

    const data = await response.json();
    return data.message;
  } catch (error) {
    console.error('Error assigning role:', error);
    throw error;
  }
}

// Helper function to remove role from user
async function removeRoleFromUser(userId, roleName, resourceType = null, resourceId = null) {
  try {
    const requestBody = { role: roleName };
    if (resourceType && resourceId) {
      requestBody.resource_type = resourceType;
      requestBody.resource_id = resourceId;
    }

    const response = await fetch(`/api/v1/users/${userId}/roles`, {
      method: 'DELETE',
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify(requestBody)
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(`Failed to remove role: ${errorData.error || response.statusText}`);
    }

    const data = await response.json();
    return data.message;
  } catch (error) {
    console.error('Error removing role:', error);
    throw error;
  }
}

// Helper function to get available roles
async function getAvailableRoles() {
  try {
    const response = await fetch('/api/v1/roles', {
      method: 'GET',
      credentials: 'include',
      headers: {
        'Accept': 'application/json'
      }
    });

    if (!response.ok) {
      throw new Error(`Failed to get roles: ${response.statusText}`);
    }

    const data = await response.json();
    return data.data.map(role => role.attributes.name);
  } catch (error) {
    console.error('Error getting roles:', error);
    throw error;
  }
}
```

### Complete User Management Implementation

```javascript
// Example: Complete user management interface
class UserManager {
  constructor() {
    this.currentUser = null;
    this.users = [];
    this.roles = [];
  }

  // Initialize user manager
  async initialize() {
    try {
      // Load current user and available roles
      const [currentUser, roles] = await Promise.all([
        getCurrentUser(),
        getAvailableRoles()
      ]);

      this.currentUser = currentUser;
      this.roles = roles;

      // Load users if user has permission
      try {
        this.users = await getAllUsers();
      } catch (error) {
        console.warn('User does not have permission to view all users:', error);
      }

      return this;
    } catch (error) {
      console.error('Failed to initialize user manager:', error);
      throw error;
    }
  }

  // Update current user profile
  async updateProfile(profileData, avatarFile = null) {
    try {
      const updatedUser = await updateUserProfile(this.currentUser.id, profileData, avatarFile);
      this.currentUser = updatedUser;
      return updatedUser;
    } catch (error) {
      console.error('Failed to update profile:', error);
      throw error;
    }
  }

  // Update password
  async updatePassword(currentPassword, newPassword, passwordConfirmation) {
    try {
      const message = await updatePassword(
        this.currentUser.id,
        currentPassword,
        newPassword,
        passwordConfirmation
      );
      return message;
    } catch (error) {
      console.error('Failed to update password:', error);
      throw error;
    }
  }

  // Assign role to user
  async assignRole(userId, roleName, resourceType = null, resourceId = null) {
    try {
      const message = await assignRoleToUser(userId, roleName, resourceType, resourceId);
      
      // Refresh user data
      await this.refreshUser(userId);
      
      return message;
    } catch (error) {
      console.error('Failed to assign role:', error);
      throw error;
    }
  }

  // Remove role from user
  async removeRole(userId, roleName, resourceType = null, resourceId = null) {
    try {
      const message = await removeRoleFromUser(userId, roleName, resourceType, resourceId);
      
      // Refresh user data
      await this.refreshUser(userId);
      
      return message;
    } catch (error) {
      console.error('Failed to remove role:', error);
      throw error;
    }
  }

  // Refresh user data
  async refreshUser(userId) {
    try {
      if (userId === this.currentUser.id) {
        this.currentUser = await getCurrentUser();
      } else {
        // Update user in users list
        const userIndex = this.users.findIndex(user => user.id === userId);
        if (userIndex !== -1) {
          const response = await fetch(`/api/v1/users/${userId}`, {
            method: 'GET',
            credentials: 'include',
            headers: { 'Accept': 'application/json' }
          });
          
          if (response.ok) {
            const data = await response.json();
            this.users[userIndex] = data.data;
          }
        }
      }
    } catch (error) {
      console.error('Failed to refresh user:', error);
    }
  }

  // Get user by ID
  getUserById(userId) {
    if (userId === this.currentUser.id) {
      return this.currentUser;
    }
    return this.users.find(user => user.id === userId);
  }

  // Check if user has role
  userHasRole(userId, roleName, resourceType = null, resourceId = null) {
    const user = this.getUserById(userId);
    if (!user) return false;

    if (resourceType && resourceId) {
      // Check for resource-scoped role
      return user.attributes.roles.some(role => 
        role.name === roleName && 
        role.resource_type === resourceType && 
        role.resource_id === resourceId
      );
    } else {
      // Check for global role
      return user.attributes.roles.includes(roleName);
    }
  }

  // Get users by role
  getUsersByRole(roleName, resourceType = null, resourceId = null) {
    return this.users.filter(user => 
      this.userHasRole(user.id, roleName, resourceType, resourceId)
    );
  }
}

// Usage example
async function initializeUserManagement() {
  try {
    const userManager = await new UserManager().initialize();
    
    // Display current user info
    displayCurrentUser(userManager.currentUser);
    
    // Display users list
    displayUsersList(userManager.users);
    
    // Set up event listeners
    setupUserManagementEvents(userManager);
    
    return userManager;
  } catch (error) {
    console.error('Failed to initialize user management:', error);
    showErrorMessage('Failed to load user management interface');
  }
}

// Display current user information
function displayCurrentUser(user) {
  const userInfo = document.getElementById('current-user-info');
  const avatarHtml = user.attributes.avatar_url 
    ? `<img src="${user.attributes.avatar_url}" alt="Avatar" class="user-avatar" />` 
    : '<div class="user-avatar-placeholder">No Avatar</div>';
  
  userInfo.innerHTML = `
    <h2>Current User</h2>
    <div class="user-card">
      ${avatarHtml}
      <h3>${user.attributes.name}</h3>
      <p>Email: ${user.attributes.email}</p>
      <p>Phone: ${user.attributes.phone || 'Not provided'}</p>
      <p>Email Confirmed: ${user.attributes.email_confirmed ? 'Yes' : 'No'}</p>
      <p>Phone Confirmed: ${user.attributes.phone_confirmed ? 'Yes' : 'No'}</p>
      <p>Profile Complete: ${user.attributes.is_profile_complete ? 'Yes' : 'No'}</p>
      <p>Roles: ${user.attributes.roles.join(', ')}</p>
      ${user.attributes.profile.bio ? `<p>Bio: ${user.attributes.profile.bio}</p>` : ''}
      ${user.attributes.profile.location ? `<p>Location: ${user.attributes.profile.location}</p>` : ''}
    </div>
  `;
}

// Display users list
function displayUsersList(users) {
  const usersList = document.getElementById('users-list');
  usersList.innerHTML = users.map(user => {
    const avatarHtml = user.attributes.avatar_url 
      ? `<img src="${user.attributes.avatar_url}" alt="Avatar" class="user-avatar-small" />` 
      : '<div class="user-avatar-placeholder-small">No Avatar</div>';
    
    return `
      <div class="user-card">
        ${avatarHtml}
        <h3>${user.attributes.name}</h3>
        <p>Email: ${user.attributes.email}</p>
        <p>Roles: ${user.attributes.roles.join(', ')}</p>
        <p>Profile Complete: ${user.attributes.is_profile_complete ? 'Yes' : 'No'}</p>
        <div class="user-actions">
          <button onclick="editUser('${user.id}')">Edit</button>
          <button onclick="manageUserRoles('${user.id}')">Manage Roles</button>
        </div>
      </div>
    `;
  }).join('');
}

// Set up event listeners
function setupUserManagementEvents(userManager) {
  // Profile update form
  const profileForm = document.getElementById('profile-form');
  if (profileForm) {
    profileForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const formData = new FormData(profileForm);
      const avatarFile = formData.get('avatar'); // Get avatar file if present
      
      // Build profile data (excluding avatar file)
      const profileData = {};
      for (const [key, value] of formData.entries()) {
        if (key !== 'avatar' && value !== '') {
          profileData[key] = value;
        }
      }
      
      try {
        await userManager.updateProfile(profileData, avatarFile || null);
        showSuccessMessage('Profile updated successfully');
        displayCurrentUser(userManager.currentUser);
        profileForm.reset();
      } catch (error) {
        showErrorMessage('Failed to update profile: ' + error.message);
      }
    });
  }

  // Password update form
  const passwordForm = document.getElementById('password-form');
  if (passwordForm) {
    passwordForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const formData = new FormData(passwordForm);
      
      try {
        await userManager.updatePassword(
          formData.get('current_password'),
          formData.get('password'),
          formData.get('password_confirmation')
        );
        showSuccessMessage('Password updated successfully');
        passwordForm.reset();
      } catch (error) {
        showErrorMessage('Failed to update password: ' + error.message);
      }
    });
  }
}
```

## Error Handling

### Common Error Responses

**Unauthorized (401 Unauthorized):**
```json
{
  "error": "No token provided"
}
```

**Forbidden (403 Forbidden):**
```json
{
  "error": "Access denied"
}
```

**Not Found (404 Not Found):**
```json
{
  "error": "User not found"
}
```

**Validation Error (422 Unprocessable Entity):**
```json
{
  "errors": [
    "Name can't be blank",
    "Email has already been taken"
  ]
}
```

### Error Handling Best Practices

```javascript
async function handleUserApiError(operation) {
  try {
    return await operation();
  } catch (error) {
    if (error.response) {
      const status = error.response.status;
      const data = await error.response.json();
      
      switch (status) {
        case 401:
          console.error('Authentication required');
          // Redirect to login
          window.location.href = '/login';
          break;
        case 403:
          console.error('Access denied:', data.error);
          showErrorMessage('You do not have permission to perform this action');
          break;
        case 404:
          console.error('User not found');
          showErrorMessage('User not found');
          break;
        case 422:
          console.error('Validation error:', data.errors);
          showErrorMessage('Please correct the following errors: ' + data.errors.join(', '));
          break;
        case 500:
          console.error('Server error:', data.error);
          showErrorMessage('Server error. Please try again later.');
          break;
        default:
          console.error('Unexpected error:', data);
          showErrorMessage('An unexpected error occurred');
      }
    } else {
      console.error('Network error:', error.message);
      showErrorMessage('Network error. Please check your connection.');
    }
    throw error;
  }
}
```

## Best Practices

### 1. Security

- **Password Requirements**: Ensure passwords are at least 6 characters long
- **Phone Verification**: Always verify phone numbers before using them for important operations
- **Email Verification**: Check `email_confirmed` status before sending sensitive information
- **Role Permissions**: Verify user permissions before allowing role assignments
- **Input Validation**: Validate all user input on the client side before sending to API

### 2. User Experience

- **Profile Completion**: Guide users to complete their profiles using the `is_profile_complete` flag
- **Password Changes**: Prompt users to change passwords when `require_password_change` is true
- **Confirmation Status**: Show clear indicators for email and phone confirmation status
- **Error Messages**: Provide clear, actionable error messages to users
- **Loading States**: Show loading indicators during API operations

### 3. Performance

- **Caching**: Cache user data to reduce API calls
- **Pagination**: Implement pagination for large user lists
- **Lazy Loading**: Load user details only when needed
- **Debouncing**: Debounce search and filter operations

### 4. Data Management

- **Profile Structure**: Use consistent profile data structure across your application
- **Role Management**: Implement proper role hierarchy and permissions
- **Audit Trail**: Track important user data changes for compliance

### 5. Mobile Considerations

- **Phone Format**: Use proper E.164 format for phone numbers
- **Touch Interfaces**: Ensure role management interfaces work well on touch devices
- **Offline Support**: Consider caching user data for offline access
- **Push Notifications**: Use phone numbers for SMS notifications when appropriate

This guide provides comprehensive coverage of user management in the Rails API Template API, enabling clients to create rich, secure user management experiences with proper error handling and best practices.

## Related Guides

- **[JavaScript API Authentication Guide](JAVASCRIPT_API_AUTHENTICATION_GUIDE.md)** - Authentication methods for web and mobile clients
- **[Goal Viewing API Client Guide](GOAL_VIEWING_API_CLIENT_GUIDE.md)** - Complete guide for viewing goals and related data
- **[Task Management API Client Guide](TASK_MANAGEMENT_API_CLIENT_GUIDE.md)** - Complete guide for managing tasks within goals
- **[Event Management API Client Guide](EVENT_MANAGEMENT_API_CLIENT_GUIDE.md)** - Complete guide for adding and managing events within goals
