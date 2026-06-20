const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendNotificationOnNewRecord = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notificationData = snap.data();
    
    const toUid = notificationData.toUid;
    const title = notificationData.title || 'Pemberitahuan Baru';
    const body = notificationData.body || 'Kamu mendapat pemberitahuan baru di Tasuru.';
    
    if (!toUid) {
      console.log('No toUid specified in notification');
      return null;
    }

    try {
      // 1. Dapatkan fcmToken dari data pengguna
      const userDoc = await admin.firestore().collection('users').doc(toUid).get();
      if (!userDoc.exists) {
        console.log(`User ${toUid} tidak ditemukan.`);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log(`User ${toUid} tidak memiliki fcmToken (belum mengizinkan notifikasi atau belum login ulang).`);
        return null;
      }

      // 2. Buat Payload Notifikasi (Struktur untuk v1 API)
      const message = {
        notification: {
          title: title,
          body: body,
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'tasuru_channel' // Sesuaikan dengan channelId di Flutter
          }
        },
        token: fcmToken
      };

      // 3. Kirim via FCM
      const response = await admin.messaging().send(message);
      console.log(`Berhasil mengirim push notification ke ${toUid}:`, response);
      
      return response;
    } catch (error) {
      console.error(`Gagal mengirim notifikasi ke ${toUid}:`, error);
      return null;
    }
  });
