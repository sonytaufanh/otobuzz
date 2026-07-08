package com.otobuzz.otobuzz

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class OtoBuzzWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_otobuzz)

            val vehicleName = widgetData.getString("vehicle_name", "Pilih kendaraan")
            val totalKm = widgetData.getString("total_km", "0 km")
            val nextMaintenance = widgetData.getString("next_maintenance", "Tidak ada jadwal")
            val oilKmRemaining = widgetData.getString("oil_km_remaining", "-")
            val nextMaintenanceType = widgetData.getString("next_maintenance_type", "")

            views.setTextViewText(R.id.widget_vehicle_name, vehicleName)
            views.setTextViewText(R.id.widget_total_km, totalKm)
            views.setTextViewText(R.id.widget_next_maintenance, nextMaintenance)
            views.setTextViewText(R.id.widget_oil_km_remaining, oilKmRemaining)
            views.setTextViewText(R.id.widget_next_maintenance_type, nextMaintenanceType)

            // Tap widget → open app
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (intent != null) {
                val pendingIntent = android.app.PendingIntent.getActivity(
                    context, 0, intent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_add_km_button, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
