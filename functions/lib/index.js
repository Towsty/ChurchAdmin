"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateUserChurchMembership = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
exports.updateUserChurchMembership = functions.https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    // Get admin user data
    const adminDoc = await admin.firestore().collection('users').doc(context.auth.uid).get();
    const adminData = adminDoc.data();
    if (!adminData || adminData.role !== 'admin') {
        throw new functions.https.HttpsError('permission-denied', 'User must be an admin');
    }
    const { userId, churchId, role, name } = data;
    if (!userId || !churchId || !role) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }
    try {
        // Update user document
        await admin.firestore().collection('users').doc(userId).update({
            churchId: churchId,
            role: role,
            name: name,
            pendingChurchId: admin.firestore.FieldValue.delete(),
            pendingChurchName: admin.firestore.FieldValue.delete(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedBy: context.auth.uid,
        });
        return { success: true };
    }
    catch (error) {
        console.error('Error updating user:', error);
        throw new functions.https.HttpsError('internal', 'Failed to update user');
    }
});
//# sourceMappingURL=index.js.map