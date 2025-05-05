const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.addAdminRole = functions.https.onCall(async (data, context) => {
  // Security checks:
  // 1. Check if the request is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Only authenticated users can make requests",
    );
  }

  // 2. Check if the requesting user is already an admin
  if (context.auth.token.admin !== true) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only admins can add other admins",
    );
  }

  // 3. Validate the UID is provided
  if (!data.uid) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "User UID must be provided",
    );
  }

  // Set the admin claim
  try {
    await admin.auth().setCustomUserClaims(data.uid, {admin: true});
    return {message: `Success! User ${data.uid} is now an admin`};
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});
