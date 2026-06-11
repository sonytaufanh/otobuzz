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

            views.setTextViewText(R.id.widget_vehicle_name, vehicleName)
            views.setTextViewText(R.id.widget_total_km, totalKm)
            views.setTextViewText(R.id.widget_next_maintenance, nextMaintenance)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
