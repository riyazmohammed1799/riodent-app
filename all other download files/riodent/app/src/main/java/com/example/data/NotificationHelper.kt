package com.example.data

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import com.example.R
import java.util.Locale

class NotificationHelper(private val context: Context) {

    companion object {
        const val CHANNEL_ID = "riodent_otp_channel"
        const val CHANNEL_NAME = "RioDent Ticket Closure OTP"
    }

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Secure notifications for technician ticket closure OTPs"
                enableVibration(true)
            }
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            manager?.createNotificationChannel(channel)
        }
    }

    fun sendTicketClosureOtpNotification(requestId: String, otp: String, amountPaid: Double) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        val amountStr = String.format(Locale.US, "%.0f", amountPaid)
        val title = "RioDent Security: OTP $otp"
        val message = "Your ticket closure OTP for $requestId is $otp (Amount ₹$amountStr). Share this orally with your technician."

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_technician_logo)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        try {
            manager.notify(requestId.hashCode(), notification)
        } catch (_: SecurityException) {
            // Handled gracefully when system notification permission is pending
        }
    }
}
