# Auth API Examples

This document shows example API request/response formats for the auth feature.

## Login

**Request:**
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (Success):**
```json
{
  "user": {
    "id": "123",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "phone": "+1234567890",
    "is_email_verified": true,
    "is_phone_verified": false,
    "created_at": "2024-01-01T00:00:00Z"
  },
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "requires_verification": false
}
```

**Response (OTP Required):**
```json
{
  "message": "OTP verification required",
  "verification_key": "abc123xyz",
  "requires_verification": true
}
```

## Sign Up

**Request:**
```http
POST /auth/signup
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "first_name": "John",
  "last_name": "Doe",
  "phone": "+1234567890"
}
```

**Response:**
```json
{
  "message": "User registered successfully. Please verify your email.",
  "verification_key": "abc123xyz",
  "requires_verification": true
}
```

## Verify OTP

**Request:**
```http
POST /auth/verify-otp
Content-Type: application/json

{
  "verification_key": "abc123xyz",
  "otp": "123456"
}
```

**Response:**
```json
{
  "user": {
    "id": "123",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "is_email_verified": true,
    "created_at": "2024-01-01T00:00:00Z"
  },
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

## Reset Password

**Request:**
```http
POST /auth/reset-password
Content-Type: application/json

{
  "email": "user@example.com"
}
```

**Response:**
```json
{
  "message": "Password reset OTP sent to your email"
}
```

## Verify Reset Password

**Request:**
```http
POST /auth/verify-reset-password
Content-Type: application/json

{
  "user_id": "123",
  "otp": "123456",
  "new_password": "newPassword123"
}
```

**Response:**
```json
{
  "message": "Password reset successful"
}
```

## Refresh Token

**Request:**
```http
POST /auth/refresh-token
Content-Type: application/json

{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

## Get Current User

**Request:**
```http
GET /auth/me
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response:**
```json
{
  "id": "123",
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone": "+1234567890",
  "profile_image": "https://example.com/profile.jpg",
  "is_email_verified": true,
  "is_phone_verified": true,
  "created_at": "2024-01-01T00:00:00Z"
}
```

## Logout

**Request:**
```http
POST /auth/logout
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response:**
```json
{
  "message": "Logged out successfully"
}
```

