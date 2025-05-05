// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.setAdmin = functions.https.onCall((data, context) => {
  // Security check: Only existing admins can set claims
  if (!context.auth || !context.auth.token.isAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'Not authorized');
  }

  return admin.auth().setCustomUserClaims(data.uid, { isAdmin: data.isAdmin });
});