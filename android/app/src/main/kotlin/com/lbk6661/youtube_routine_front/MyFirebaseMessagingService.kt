package com.lbk6661.youtube_routine_front

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import android.os.Build
//import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import android.content.pm.PackageManager
import android.media.RingtoneManager
import android.media.AudioAttributes

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        val youtubeLink = remoteMessage.data["youtubeLink"]
        val title = remoteMessage.data["title"] ?: "유튜브 루틴"
        val body = remoteMessage.data["body"] ?: "알림이 도착했습니다."

        if (!youtubeLink.isNullOrEmpty()) {
            showNotification(title, body, youtubeLink)
        }
    }

    private fun showNotification(title: String, body: String, youtubeLink: String) {
        val fallbackUrl = "https://www.youtube.com/"
        val finalUrl = try {
            val uri = Uri.parse(youtubeLink)
            if (uri.scheme == "http" || uri.scheme == "https") youtubeLink else fallbackUrl
        } catch (e: Exception) {
            fallbackUrl
        }

        val channelId = "youtube_routine_channel_v2"
        val notificationId = System.currentTimeMillis().toInt()

        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(finalUrl)).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 🔊 기본 알림 소리
        val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

            val channel = NotificationChannel(
                channelId,
                "YouTube Routine 알림",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                setSound(soundUri, audioAttributes) // ✅ 소리 설정
                enableLights(true)
                enableVibration(true)
            }

            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }

        val notificationBuilder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setSound(soundUri) // ✅ 소리 설정 추가

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                return
            }
        }

        NotificationManagerCompat.from(this).notify(notificationId, notificationBuilder.build())
    }

    override fun onNewToken(token: String) {
        // 새 토큰 수신 처리
    }
}