# React Native Authentication Guide

## Overview

This guide explains how React Native clients should authenticate with the Rails API Template API. The API detects mobile clients using a simple header and uses token-based authentication instead of cookies.

## Client Detection

The API detects mobile clients using a single header:

- `X-Client-Type: mobile`

## Recommended Configuration

### 1. Configure HTTP Client
```javascript
// Configure your HTTP client with the mobile header
const apiClient = axios.create({
  baseURL: 'https://api.example.com/api/v1',
  headers: {
    'X-Client-Type': 'mobile',
    'Content-Type': 'application/json'
  }
});
```

### 2. Use Token-Based Authentication
```javascript
// Login request
const loginResponse = await apiClient.post('/authentication/login', {
  email: 'user@example.com',
  password: 'password'
});

// Store tokens (NO cookies will be sent)
const { token, refresh_token } = loginResponse.data;

// Use token in subsequent requests
apiClient.defaults.headers.common['Authorization'] = `Bearer ${token}`;
```

### 3. Token Refresh

**Important**: The API implements **refresh token rotation** for enhanced security and to prevent timeout issues. Each refresh returns a **new refresh token**, and the old one is automatically revoked. This allows continuous refresh without forcing users to re-authenticate.

```javascript
// When token expires, use refresh token
const refreshResponse = await apiClient.post('/authentication/refresh', {
  refresh_token: storedRefreshToken
});

// CRITICAL: Always save the NEW refresh token - the old one is now invalid
// This allows continuous refresh without timeout (important for mobile apps)
const { token: newToken, refresh_token: newRefreshToken } = refreshResponse.data;

// Update stored tokens with the new refresh token
// The old refresh token cannot be reused
storage.saveTokens(newToken, newRefreshToken);
```

**Key Points**:
- ✅ Each refresh returns a **new refresh token** (the old one is revoked)
- ✅ This allows **continuous refresh** without timeout - your app can stay logged in indefinitely
- ✅ You **must** save the new refresh token returned in the response
- ✅ Attempting to reuse an old refresh token will fail

## Benefits

✅ **No Cookie Overhead**: Mobile clients don't receive unnecessary cookies  
✅ **Better Performance**: Reduced payload size  
✅ **Cleaner Architecture**: Token-based auth is more appropriate for mobile  
✅ **Automatic Detection**: No manual configuration needed  

## Testing

You can test client detection by checking the logs:

```
Mobile client detected via X-Client-Type header
```

If you see this log, cookies will NOT be sent to your React Native client.

## Alternative Headers

The header value is case-insensitive and whitespace-tolerant:
- `X-Client-Type: mobile` ✅
- `X-Client-Type: MOBILE` ✅  
- `X-Client-Type: " mobile "` ✅
- `X-Client-Type: web` ❌ (will receive cookies)

## Email Confirmation

When users register, they receive an email with a confirmation link. Mobile clients need to handle this link to confirm the user's email address.

### Email Confirmation Flow

1. **User receives email** with a link like: `https://portal.example.com/confirm-email?token=ABC123...`
2. **User clicks link** - this opens in a browser or your app (via deep linking)
3. **Extract token** from the URL
4. **Call API endpoint** to confirm the email
5. **Show success/error** message to the user

### API Endpoint

**POST** `/api/v1/confirm_email`

**Request Body:**
```json
{
  "token": "abc123..."
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

### Implementation Approaches

#### Option 1: Deep Linking (Recommended)

Configure your app to handle the confirmation link via deep linking. When the user clicks the email link, it opens your app directly.

**React Native Example with React Navigation:**

```javascript
import { Linking } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { useEffect } from 'react';

// Configure deep linking
const linking = {
  prefixes: ['https://portal.example.com', 'rails-api-template://'],
  config: {
    screens: {
      ConfirmEmail: 'confirm-email',
      // ... other screens
    },
  },
};

function App() {
  return (
    <NavigationContainer linking={linking}>
      {/* Your navigation structure */}
    </NavigationContainer>
  );
}
```

**Email Confirmation Screen:**

```javascript
import React, { useState, useEffect } from 'react';
import { View, Text, Button, Alert } from 'react-native';
import { useRoute } from '@react-navigation/native';
import axios from 'axios';

const apiClient = axios.create({
  baseURL: 'https://api.example.com/api/v1',
  headers: {
    'X-Client-Type': 'mobile',
    'Content-Type': 'application/json'
  }
});

function ConfirmEmailScreen() {
  const route = useRoute();
  const [loading, setLoading] = useState(false);
  const [confirmed, setConfirmed] = useState(false);
  const [error, setError] = useState(null);

  // Extract token from route params (from deep link)
  const token = route.params?.token;

  useEffect(() => {
    // If token is present, automatically confirm
    if (token) {
      confirmEmail(token);
    }
  }, [token]);

  const confirmEmail = async (emailToken) => {
    setLoading(true);
    setError(null);

    try {
      const response = await apiClient.post('/confirm_email', {
        token: emailToken
      });

      setConfirmed(true);
      Alert.alert('Success', response.data.message);
    } catch (err) {
      const errorMessage = err.response?.data?.error || 'Failed to confirm email';
      setError(errorMessage);
      Alert.alert('Error', errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={{ flex: 1, justifyContent: 'center', padding: 20 }}>
      {loading && <Text>Confirming email...</Text>}
      {confirmed && <Text style={{ color: 'green' }}>Email confirmed successfully!</Text>}
      {error && <Text style={{ color: 'red' }}>{error}</Text>}
      {!token && !loading && (
        <Text>No confirmation token found. Please check your email.</Text>
      )}
    </View>
  );
}

export default ConfirmEmailScreen;
```

#### Option 2: Manual Token Entry

If deep linking isn't configured, users can manually enter the token from the email link.

```javascript
import React, { useState } from 'react';
import { View, TextInput, Button, Alert } from 'react-native';
import axios from 'axios';

const apiClient = axios.create({
  baseURL: 'https://api.example.com/api/v1',
  headers: {
    'X-Client-Type': 'mobile',
    'Content-Type': 'application/json'
  }
});

function ManualConfirmEmailScreen() {
  const [token, setToken] = useState('');
  const [loading, setLoading] = useState(false);

  const confirmEmail = async () => {
    if (!token.trim()) {
      Alert.alert('Error', 'Please enter a confirmation token');
      return;
    }

    setLoading(true);

    try {
      const response = await apiClient.post('/confirm_email', {
        token: token.trim()
      });

      Alert.alert('Success', response.data.message, [
        { text: 'OK', onPress: () => navigation.navigate('Login') }
      ]);
    } catch (err) {
      const errorMessage = err.response?.data?.error || 'Failed to confirm email';
      Alert.alert('Error', errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={{ flex: 1, justifyContent: 'center', padding: 20 }}>
      <Text>Enter the confirmation token from your email:</Text>
      <TextInput
        value={token}
        onChangeText={setToken}
        placeholder="Confirmation token"
        style={{ borderWidth: 1, padding: 10, marginVertical: 10 }}
      />
      <Button
        title={loading ? 'Confirming...' : 'Confirm Email'}
        onPress={confirmEmail}
        disabled={loading || !token.trim()}
      />
    </View>
  );
}
```

#### Option 3: Universal Link Handling

For iOS, you can use Universal Links. For Android, use App Links. Both allow the email link to open directly in your app.

**iOS Universal Links Setup:**

1. Add Associated Domains capability in Xcode
2. Configure `apple-app-site-association` file on your web server
3. Handle the link in your app:

```javascript
import { useEffect } from 'react';
import { Linking } from 'react-native';

useEffect(() => {
  // Handle initial URL when app opens from link
  Linking.getInitialURL().then((url) => {
    if (url) {
      handleDeepLink(url);
    }
  });

  // Handle URLs when app is already running
  const subscription = Linking.addEventListener('url', (event) => {
    handleDeepLink(event.url);
  });

  return () => {
    subscription.remove();
  };
}, []);

const handleDeepLink = (url) => {
  // Parse URL: https://portal.example.com/confirm-email?token=ABC123
  const urlObj = new URL(url);
  if (urlObj.pathname === '/confirm-email') {
    const token = urlObj.searchParams.get('token');
    if (token) {
      // Navigate to confirmation screen with token
      navigation.navigate('ConfirmEmail', { token });
    }
  }
};
```

### Complete Example with Error Handling

```javascript
import React, { useState, useEffect } from 'react';
import { View, Text, Button, ActivityIndicator, Alert } from 'react-native';
import { useRoute, useNavigation } from '@react-navigation/native';
import axios from 'axios';

const apiClient = axios.create({
  baseURL: 'https://api.example.com/api/v1',
  headers: {
    'X-Client-Type': 'mobile',
    'Content-Type': 'application/json'
  }
});

function ConfirmEmailScreen() {
  const route = useRoute();
  const navigation = useNavigation();
  const [loading, setLoading] = useState(false);
  const [confirmed, setConfirmed] = useState(false);
  const [error, setError] = useState(null);

  const token = route.params?.token;

  useEffect(() => {
    if (token) {
      confirmEmail(token);
    }
  }, [token]);

  const confirmEmail = async (emailToken) => {
    setLoading(true);
    setError(null);

    try {
      const response = await apiClient.post('/confirm_email', {
        token: emailToken
      });

      setConfirmed(true);
      
      Alert.alert(
        'Email Confirmed',
        response.data.message,
        [
          {
            text: 'OK',
            onPress: () => navigation.navigate('Login')
          }
        ]
      );
    } catch (err) {
      let errorMessage = 'Failed to confirm email';
      
      if (err.response) {
        // Server responded with error
        errorMessage = err.response.data?.error || `Server error: ${err.response.status}`;
      } else if (err.request) {
        // Request made but no response
        errorMessage = 'Network error. Please check your connection.';
      }

      setError(errorMessage);
      Alert.alert('Confirmation Failed', errorMessage);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <ActivityIndicator size="large" />
        <Text style={{ marginTop: 10 }}>Confirming your email...</Text>
      </View>
    );
  }

  return (
    <View style={{ flex: 1, justifyContent: 'center', padding: 20 }}>
      {confirmed && (
        <View>
          <Text style={{ color: 'green', fontSize: 18, marginBottom: 10 }}>
            ✓ Email Confirmed Successfully!
          </Text>
          <Text>You can now log in to your account.</Text>
        </View>
      )}

      {error && (
        <View>
          <Text style={{ color: 'red', fontSize: 18, marginBottom: 10 }}>
            ✗ Confirmation Failed
          </Text>
          <Text>{error}</Text>
          {token && (
            <Button
              title="Try Again"
              onPress={() => confirmEmail(token)}
            />
          )}
        </View>
      )}

      {!token && !confirmed && !error && (
        <View>
          <Text style={{ fontSize: 18, marginBottom: 10 }}>
            No confirmation token found
          </Text>
          <Text>
            Please check your email and click the confirmation link, or enter the token manually.
          </Text>
        </View>
      )}
    </View>
  );
}

export default ConfirmEmailScreen;
```

### Important Notes

1. **Token Extraction**: The token is in the URL query parameter: `?token=ABC123...`
2. **No Authentication Required**: The confirmation endpoint doesn't require authentication
3. **Rate Limiting**: The endpoint has rate limiting (10 requests per 3 minutes)
4. **One-Time Use**: Confirmation tokens are single-use and expire
5. **Error Handling**: Always handle network errors and invalid/expired tokens gracefully
6. **User Experience**: Consider showing a loading state and clear success/error messages

### Resending Confirmation Email

If a user needs a new confirmation email, they can request one:

**POST** `/api/v1/send_email_confirmation`

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

```javascript
const resendConfirmation = async (email) => {
  try {
    const response = await apiClient.post('/send_email_confirmation', {
      email: email
    });
    Alert.alert('Success', response.data.message);
  } catch (err) {
    Alert.alert('Error', err.response?.data?.error || 'Failed to send confirmation email');
  }
};
```
