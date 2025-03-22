package com.example.youtube_routine_front

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import android.content.pm.PackageManager


class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        Log.d("FCM", "✅ 푸시 알림 수신됨")

        val youtubeLink = remoteMessage.data["youtubeLink"]
        val title = remoteMessage.data["title"] ?: "유튜브 루틴"
        val body = remoteMessage.data["body"] ?: "알림이 도착했습니다."

        if (!youtubeLink.isNullOrEmpty()) {
            showNotification(title, body, youtubeLink)
        } else {
            Log.w("FCM", "❌ youtubeLink 없음, 알림 생략")
        }
    }

    private fun showNotification(title: String, body: String, youtubeLink: String) {
        val channelId = "youtube_routine_channel"
        val notificationId = System.currentTimeMillis().toInt()

        // 알림 클릭 시 유튜브 링크로 이동하는 인텐트
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(youtubeLink)).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Android 8 이상 알림 채널 설정
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "YouTube Routine 알림",
                NotificationManager.IMPORTANCE_HIGH
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }

        // 알림 생성
        val notificationBuilder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                Log.w("FCM", "알림 권한 없음, 알림 생략")
                return
            }
        }

        NotificationManagerCompat.from(this).notify(notificationId, notificationBuilder.build())


        Log.d("FCM", "✅ 알림 표시 완료, 유튜브 링크: $youtubeLink")
    }

    override fun onNewToken(token: String) {
        Log.d("FCM", "🔄 새 FCM 토큰 수신: $token")
        // 여기서 서버로 토큰 전송 로직 넣어도 됨
    }
}
