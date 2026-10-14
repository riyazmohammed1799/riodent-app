#!/usr/bin/env node

/**
 * RioDent Administrative Claim Utility
 *
 * This utility uses the Firebase Admin SDK to grant or revoke custom claims ({ admin: true })
 * for administrator accounts. Per security architecture, admin authorization is determined
 * strictly via Firebase Auth Custom Claims, not mutable client Firestore documents.
 *
 * Requirements:
 * - Node.js >= 18
 * - npm install firebase-admin
 * - Google Cloud Service Account credentials JSON file
 *
 * Usage:
 *   # Set Google Cloud Application Credentials in environment:
 *   $env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\serviceAccountKey.json"  # PowerShell
 *   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccountKey.json"   # Bash
 *
 *   # Grant admin claim:
 *   node tools/set_admin_claim.js --email=admin@riodent.in --grant
 *
 *   # Revoke admin claim:
 *   node tools/set_admin_claim.js --email=former_admin@riodent.in --revoke
 *
 *   # Inspect existing claims:
 *   node tools/set_admin_claim.js --email=user@riodent.in --check
 */

const admin = require('firebase-admin');

// Parse CLI arguments
const args = process.argv.slice(2);
let email = null;
let mode = 'grant'; // 'grant', 'revoke', 'check'

for (const arg of args) {
  if (arg.startsWith('--email=')) {
    email = arg.split('=')[1].trim();
  } else if (arg === '--grant') {
    mode = 'grant';
  } else if (arg === '--revoke') {
    mode = 'revoke';
  } else if (arg === '--check') {
    mode = 'check';
  } else if (!arg.startsWith('--') && !email) {
    email = arg.trim();
  }
}

if (!email) {
  console.error('\x1b[31m[ERROR] Target email address is required.\x1b[0m');
  console.log('Usage: node tools/set_admin_claim.js --email=<email_address> [--grant | --revoke | --check]');
  process.exit(1);
}

// Initialize Firebase Admin SDK
try {
  if (admin.apps.length === 0) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
  }
} catch (e) {
  console.error('\x1b[31m[ERROR] Failed to initialize Firebase Admin SDK.\x1b[0m');
  console.error('Make sure GOOGLE_APPLICATION_CREDENTIALS environment variable points to a valid service account JSON.');
  console.error(e.message);
  process.exit(1);
}

async function run() {
  const auth = admin.auth();

  try {
    console.log(`\x1b[34m[INFO] Looking up user: ${email}...\x1b[0m`);
    const user = await auth.getUserByEmail(email);
    console.log(`\x1b[32m[FOUND] User UID: ${user.uid} (${user.displayName || 'No display name'})\x1b[0m`);
    console.log(`Current Custom Claims:`, JSON.stringify(user.customClaims || {}, null, 2));

    if (mode === 'check') {
      const isAdmin = user.customClaims && user.customClaims.admin === true;
      console.log(`\x1b[1mAdmin Status: ${isAdmin ? '\x1b[32mVERIFIED ADMIN' : '\x1b[33mSTANDARD USER (Not Admin)'}\x1b[0m`);
      process.exit(0);
    }

    if (mode === 'grant') {
      console.log(`\x1b[34m[UPDATING] Granting { admin: true } claim and setting emailVerified to true...\x1b[0m`);
      const newClaims = {
        ...(user.customClaims || {}),
        admin: true,
      };

      await auth.setCustomUserClaims(user.uid, newClaims);
      if (!user.emailVerified) {
        await auth.updateUser(user.uid, { emailVerified: true });
        console.log(`\x1b[32m[UPDATED] Email set to verified.\x1b[0m`);
      }

      // Re-verify
      const updatedUser = await auth.getUser(user.uid);
      console.log(`\x1b[32m[SUCCESS] Custom claims updated for ${email}:\x1b[0m`, updatedUser.customClaims);
      console.log('\x1b[33m[NOTE] The user must sign out and sign back in for the new ID token to reflect claims in the app.\x1b[0m');
    } else if (mode === 'revoke') {
      console.log(`\x1b[34m[UPDATING] Revoking { admin: true } claim...\x1b[0m`);
      const newClaims = {
        ...(user.customClaims || {}),
      };
      delete newClaims.admin;

      await auth.setCustomUserClaims(user.uid, newClaims);
      const updatedUser = await auth.getUser(user.uid);
      console.log(`\x1b[32m[SUCCESS] Admin claim revoked for ${email}:\x1b[0m`, updatedUser.customClaims);
      console.log('\x1b[33m[NOTE] The user must sign out and sign back in to lose admin access.\x1b[0m');
    }
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      console.error(`\x1b[31m[ERROR] No account found with email: ${email}\x1b[0m`);
      console.error('Please ensure the user has signed in at least once via the RioDent app before granting admin claims.');
    } else {
      console.error(`\x1b[31m[ERROR]\x1b[0m`, error);
    }
    process.exit(1);
  }
}

run();
