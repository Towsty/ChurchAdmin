import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

interface UpdateUserData {
  userId: string;
  churchId: string;
  role: string;
  firstName: string;
  lastName: string;
  adminId?: string;
}

export const updateUserChurchMembership = functions.https.onCall(
  async (data: UpdateUserData, context: functions.https.CallableContext) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    // Get admin user data
    const adminDoc = await admin.firestore().collection('users').doc(context.auth.uid).get();
    const adminData = adminDoc.data();

    if (!adminData || adminData.role !== 'admin') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'User must be an admin'
      );
    }

    const { userId, churchId, role, firstName, lastName } = data;

    if (!userId || !churchId || !role) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required fields'
      );
    }

    try {
      // Update user document
      await admin.firestore().collection('users').doc(userId).update({
        churchId: churchId,
        role: role,
        firstName: firstName,
        lastName: lastName,
        pendingChurchId: admin.firestore.FieldValue.delete(),
        pendingChurchName: admin.firestore.FieldValue.delete(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedBy: context.auth.uid,
      });

      return { success: true };
    } catch (error) {
      console.error('Error updating user:', error);
      throw new functions.https.HttpsError('internal', 'Failed to update user');
    }
  }
); 