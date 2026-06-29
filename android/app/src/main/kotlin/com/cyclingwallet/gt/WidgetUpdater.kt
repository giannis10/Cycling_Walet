package com.cyclingwallet.gt

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.math.ceil

object WidgetUpdater {

    fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        mode: String // "FULL", "EXPIRY_ONLY", "COUNTDOWN_ONLY"
    ) {
        val views = RemoteViews(context.packageName, R.layout.expiry_widget)

        // Title and Header adjustments
        val widgetTitle = "Cycling Wallet"
        views.setTextViewText(R.id.header_title, widgetTitle)
        views.setViewVisibility(R.id.header_expiry, if (mode == "COUNTDOWN_ONLY") View.GONE else View.VISIBLE)
        views.setViewVisibility(R.id.header_countdown, if (mode == "EXPIRY_ONLY") View.GONE else View.VISIBLE)

        // Make the widget clickable to open the app
        val launchIntent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        // Hide all rows initially
        val rowIds = intArrayOf(R.id.row0, R.id.row1, R.id.row2)
        val titleIds = intArrayOf(R.id.row0_title, R.id.row1_title, R.id.row2_title)
        val iconIds = intArrayOf(R.id.row0_icon, R.id.row1_icon, R.id.row2_icon)
        val expiryIds = intArrayOf(R.id.row0_expiry, R.id.row1_expiry, R.id.row2_expiry)
        val countdownIds = intArrayOf(R.id.row0_countdown, R.id.row1_countdown, R.id.row2_countdown)
        val countdownColIds = intArrayOf(R.id.row0_countdown_col, R.id.row1_countdown_col, R.id.row2_countdown_col)

        for (id in rowIds) {
            views.setViewVisibility(id, View.GONE)
        }

        // Read data from Flutter
        val widgetData = HomeWidgetPlugin.getData(context)
        
        var displayedRows = 0
        for (i in 0 until 3) {
            val title = widgetData.getString("doc_${i}_title", "") ?: ""
            val expiryStr = widgetData.getString("doc_${i}_expiry", "") ?: ""
            val iconType = widgetData.getString("doc_${i}_icon", "") ?: ""

            if (title.isNotEmpty()) {
                val rowId = rowIds[displayedRows]
                val titleId = titleIds[displayedRows]
                val iconId = iconIds[displayedRows]
                val expiryId = expiryIds[displayedRows]
                val countdownId = countdownIds[displayedRows]
                val countdownColId = countdownColIds[displayedRows]

                views.setViewVisibility(rowId, View.VISIBLE)
                views.setTextViewText(titleId, title)

                // Date parsing, text generation and coloring
                var expiryText = "--"
                var countdownText = "--"
                var color = Color.parseColor("#A0A0A0") // Grey

                if (expiryStr.isNotEmpty()) {
                    try {
                        val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault())
                        val cleanStr = expiryStr.substringBefore(".").substringBefore("Z")
                        val date = format.parse(cleanStr)
                        
                        if (date != null) {
                            val outFormat = SimpleDateFormat("dd/MM/yyyy", Locale.getDefault())
                            expiryText = outFormat.format(date)
                            
                            val diffInMillis = date.time - System.currentTimeMillis()
                            val days = ceil(diffInMillis.toDouble() / (1000 * 60 * 60 * 24)).toLong()
                            
                            if (days > 0) {
                                countdownText = "$days μέρες"
                                color = if (days < 30) Color.parseColor("#F87171") else Color.parseColor("#4ADE80") // Red/Green
                            } else if (days == 0L) {
                                countdownText = "Σήμερα"
                                color = Color.parseColor("#F87171") // Red
                            } else {
                                countdownText = "Έληξε"
                                color = Color.parseColor("#F87171") // Red
                            }
                        }
                    } catch (e: Exception) {
                        expiryText = expiryStr // Fallback
                    }
                }

                views.setTextViewText(expiryId, expiryText)
                views.setTextViewText(countdownId, countdownText)
                
                // Apply pill background
                if (color == Color.parseColor("#F87171")) {
                    views.setInt(countdownId, "setBackgroundResource", R.drawable.bg_pill_red)
                } else if (color == Color.parseColor("#4ADE80")) {
                    views.setInt(countdownId, "setBackgroundResource", R.drawable.bg_pill_green)
                } else {
                    views.setInt(countdownId, "setBackgroundResource", 0) // clear background
                }

                views.setTextColor(countdownId, color)
                if (expiryStr.isNotEmpty()) {
                    views.setTextColor(expiryId, color)
                }

                // Handle icon visibility and image
                if (iconType == "uci") {
                    views.setImageViewResource(iconId, R.drawable.ic_dot_uci)
                    views.setViewVisibility(iconId, View.VISIBLE)
                } else if (iconType == "eop") {
                    views.setImageViewResource(iconId, R.drawable.ic_dot_eop)
                    views.setViewVisibility(iconId, View.VISIBLE)
                } else if (iconType == "health") {
                    views.setImageViewResource(iconId, R.drawable.ic_dot_health)
                    views.setViewVisibility(iconId, View.VISIBLE)
                } else {
                    views.setViewVisibility(iconId, View.GONE)
                }

                // Handle column visibility
                views.setViewVisibility(expiryId, if (mode == "COUNTDOWN_ONLY") View.GONE else View.VISIBLE)
                views.setViewVisibility(countdownColId, if (mode == "EXPIRY_ONLY") View.GONE else View.VISIBLE)

                displayedRows++
            }
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
