const admin = require('firebase-admin');

// Initialize with your service account
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function setAdmin(uid) {
  try {
    await admin.auth().setCustomUserClaims(uid, { isAdmin: true });
    console.log(`Success! User ${uid} is now an admin`);
  } catch (error) {
    console.error('Error:', error);
  }
}

// Replace with your user's UID
setAdmin('tbmwaJVucMNtByiTUyz2gHn57Oh1');