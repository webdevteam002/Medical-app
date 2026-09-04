# Person 1 — Desktop Integration Guide

**Role:** Backend Developer
**Goal:** Expand the API and Auth system to support Native Desktop Apps (Windows & macOS) alongside Mobile.

---

## 1. The 2-Device Limit (Mobile + Desktop)

Previously, the system was designed for a strict "1 device per user" rule. Now, users are allowed to be logged in on **one mobile device** and **one desktop device** simultaneously.

### Database Updates
Modify your `device_sessions` table to track the `device_type`.

```prisma
model DeviceSession {
  id           String   @id @default(uuid())
  userId       String
  deviceId     String   // The hardware UUID
  deviceName   String   // "iPhone 14" or "Windows PC"
  deviceType   String   // ENUM: 'MOBILE' or 'DESKTOP'
  refreshToken String
  createdAt    DateTime @default(now())

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
}
```

### Auth Logic
When a user logs in:
1. Identify the `deviceType` from the request (Person 2 must send this in the headers or body, e.g., `X-Device-Type: DESKTOP`).
2. Count the active sessions for the user.
3. If they log in on a new `DESKTOP`, revoke the oldest `DESKTOP` session.
4. If they log in on a new `MOBILE`, revoke the oldest `MOBILE` session.
5. Result: They will only ever have a maximum of 2 active sessions (1 Mobile, 1 Desktop).

## 2. Hardware UUIDs

Native desktop apps provide different hardware identifiers than mobile devices. 
Person 2 will be using `device_info_plus` to generate the `deviceId`.

- **Mobile:** Usually generates an iOS IDFV or Android ID.
- **Windows:** Generates a Windows `deviceId` (often tied to the motherboard or OS install).
- **macOS:** Generates a Mac `systemGUID`.

**Your Task:** Ensure your `deviceId` column in PostgreSQL is a standard `String` (varchar) of sufficient length to handle these various formats (some desktop UUIDs can be longer or formatted differently than mobile IDs). Do not assume a strict UUIDv4 format for the `deviceId`.

## 3. Desktop Payments

If you decide to implement local payment gateways (like JazzCash or Easypaisa) via web checkouts for Desktop users (since RevenueCat is primarily for mobile app stores):
- Expose a `POST /subscriptions/manual-intent` endpoint.
- Include instructions on how desktop users can upload payment proof to the Next.js admin panel for manual approval.

## 4. API Testing

Desktop users are more likely to be on stable, high-speed Wi-Fi compared to mobile users on 4G. However, they may also leave the app open for days at a time.
- Ensure your `JWT_REFRESH_SECRET` logic correctly renews sessions in the background so desktop users do not get randomly logged out while studying. 
- Ensure CORS is correctly configured if any testing happens via a Web build, though Native Desktop apps do not enforce strict CORS like web browsers do.
