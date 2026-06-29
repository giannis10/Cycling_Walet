package com.cyclingwallet.gt

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

class WidgetCountdownProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            WidgetUpdater.updateWidget(context, appWidgetManager, appWidgetId, "COUNTDOWN_ONLY")
        }
    }
}
