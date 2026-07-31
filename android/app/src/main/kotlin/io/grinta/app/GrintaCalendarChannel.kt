package io.grinta.app

import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.provider.CalendarContract
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Native helpers for device calendar visibility.
 *
 * The [device_calendar] plugin creates calendars with [CalendarContract.ACCOUNT_TYPE_LOCAL]
 * but does not set [CalendarContract.Calendars.VISIBLE] or
 * [CalendarContract.Calendars.SYNC_EVENTS]. Many calendar apps (including Google Calendar)
 * hide those calendars until both flags are set.
 */
object GrintaCalendarChannel {
    const val CHANNEL_NAME = "io.grinta.app/calendar"

    fun register(flutterEngine: FlutterEngine, activity: MainActivity) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "ensureCalendarVisible" -> {
                        val calendarId = call.argument<String>("calendarId")
                        if (calendarId.isNullOrBlank()) {
                            result.error("invalid_args", "calendarId required", null)
                            return@setMethodCallHandler
                        }
                        result.success(ensureCalendarVisible(activity, calendarId))
                    }

                    "getCalendarVisibility" -> {
                        val calendarId = call.argument<String>("calendarId")
                        if (calendarId.isNullOrBlank()) {
                            result.error("invalid_args", "calendarId required", null)
                            return@setMethodCallHandler
                        }
                        result.success(getCalendarVisibility(activity, calendarId))
                    }

                    "openCalendarApp" -> {
                        result.success(openCalendarApp(activity))
                    }

                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("calendar_error", e.message, null)
            }
        }
    }

    private fun ensureCalendarVisible(activity: MainActivity, calendarId: String): Boolean {
        val id = calendarId.trim().toLongOrNull() ?: return false
        val resolver = activity.contentResolver

        val values = ContentValues().apply {
            put(CalendarContract.Calendars.VISIBLE, 1)
            put(CalendarContract.Calendars.SYNC_EVENTS, 1)
        }

        // Prefer sync-adapter style update for LOCAL calendars (matches create path).
        val account = queryAccount(activity, id)
        val updated = if (account != null) {
            val uri = ContentUris.withAppendedId(CalendarContract.Calendars.CONTENT_URI, id)
                .buildUpon()
                .appendQueryParameter(CalendarContract.CALLER_IS_SYNCADAPTER, "true")
                .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_NAME, account.first)
                .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_TYPE, account.second)
                .build()
            resolver.update(uri, values, null, null)
        } else {
            val uri = ContentUris.withAppendedId(CalendarContract.Calendars.CONTENT_URI, id)
            resolver.update(uri, values, null, null)
        }

        if (updated > 0) return true

        // Fallback without sync-adapter query params.
        val fallbackUri = ContentUris.withAppendedId(CalendarContract.Calendars.CONTENT_URI, id)
        return resolver.update(fallbackUri, values, null, null) > 0
    }

    private fun queryAccount(
        activity: MainActivity,
        calendarId: Long,
    ): Pair<String, String>? {
        val uri = ContentUris.withAppendedId(CalendarContract.Calendars.CONTENT_URI, calendarId)
        activity.contentResolver.query(
            uri,
            arrayOf(
                CalendarContract.Calendars.ACCOUNT_NAME,
                CalendarContract.Calendars.ACCOUNT_TYPE,
            ),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val name = cursor.getString(0) ?: return null
                val type = cursor.getString(1) ?: return null
                return name to type
            }
        }
        return null
    }

    private fun getCalendarVisibility(
        activity: MainActivity,
        calendarId: String,
    ): Map<String, Any?>? {
        val id = calendarId.trim().toLongOrNull() ?: return null
        val uri = ContentUris.withAppendedId(CalendarContract.Calendars.CONTENT_URI, id)
        activity.contentResolver.query(
            uri,
            arrayOf(
                CalendarContract.Calendars._ID,
                CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
                CalendarContract.Calendars.ACCOUNT_NAME,
                CalendarContract.Calendars.ACCOUNT_TYPE,
                CalendarContract.Calendars.VISIBLE,
                CalendarContract.Calendars.SYNC_EVENTS,
            ),
            null,
            null,
            null,
        )?.use { cursor ->
            if (!cursor.moveToFirst()) return null
            return mapOf(
                "id" to cursor.getLong(0).toString(),
                "displayName" to cursor.getString(1),
                "accountName" to cursor.getString(2),
                "accountType" to cursor.getString(3),
                "visible" to (cursor.getInt(4) == 1),
                "syncEvents" to (cursor.getInt(5) == 1),
            )
        }
        return null
    }

    private fun openCalendarApp(activity: MainActivity): Boolean {
        val intents = listOf(
            Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("content://com.android.calendar/time/${System.currentTimeMillis()}")
            },
            Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_APP_CALENDAR)
            },
        )
        for (intent in intents) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (intent.resolveActivity(activity.packageManager) != null) {
                activity.startActivity(intent)
                return true
            }
        }
        return false
    }
}
