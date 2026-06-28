package com.vego.salud_prenatal

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class BackgroundService : Service() {
    private val CHANNEL_ID = "BackgroundServiceChannel"

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        val notification = createNotification()
        startForeground(1, notification)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Salud Prenatal Servicio en Segundo Plano",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(serviceChannel)
        }
    }

    private fun createNotification(): Notification {
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Salud Prenatal")
            .setContentText("La aplicación se está ejecutando en segundo plano.")
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setPriority(NotificationCompat.PRIORITY_LOW)
        
        return builder.build()
    }
}
