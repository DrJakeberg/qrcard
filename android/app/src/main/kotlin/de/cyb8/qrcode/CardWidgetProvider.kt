package de.cyb8.qrcode

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.io.File

/**
 * Zeigt den QR-Code der aktiven Visitenkarte auf dem Homescreen.
 *
 * Ein Widget kann kein Flutter darstellen. Die App rendert den Code deshalb
 * als PNG und legt nur den Dateipfad ab - hier wird er geladen und angezeigt.
 */
class CardWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val data = HomeWidgetPlugin.getData(context)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.card_widget)

            val imagePath = data.getString(KEY_IMAGE_PATH, null)
            val bitmap = imagePath
                ?.let { File(it) }
                ?.takeIf { it.exists() }
                ?.let { BitmapFactory.decodeFile(it.absolutePath) }

            if (bitmap != null) {
                views.setImageViewBitmap(R.id.widget_qr, bitmap)
            } else {
                // Noch keine Karte gespeichert - Platzhalter zeigen.
                views.setImageViewResource(R.id.widget_qr, R.drawable.widget_placeholder)
            }

            val name = data.getString(KEY_NAME, null).orEmpty()
            val subtitle = data.getString(KEY_SUBTITLE, null).orEmpty()
            views.setTextViewText(
                R.id.widget_name,
                name.ifEmpty { context.getString(R.string.widget_empty_title) },
            )
            views.setTextViewText(R.id.widget_subtitle, subtitle)

            // Tippen oeffnet die App.
            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
                ?.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP }
            if (launchIntent != null) {
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private companion object {
        // Muessen zu WidgetBridge in lib/services/widget_bridge.dart passen.
        const val KEY_IMAGE_PATH = "card_qr_path"
        const val KEY_NAME = "card_name"
        const val KEY_SUBTITLE = "card_subtitle"
    }
}
