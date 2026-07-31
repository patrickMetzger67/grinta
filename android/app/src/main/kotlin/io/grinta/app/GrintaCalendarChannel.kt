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
                        val calendarId = call.argument<String>("calendarId")
                        result.success(openCalendarApp(activity, calendarId))
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

    private fun openCalendarApp(activity: MainActivity, calendarId: String?): Boolean {
        val id = calendarId?.trim()?.toLongOrNull()
        if (id != null) {
            // Make sure the Grinta local calendar is listed before opening.
            ensureCalendarVisible(activity, id.toString())
        }

        val focusMillis = if (id != null) {
            findFocusTimeForCalendar(activity, id) ?: System.currentTimeMillis()
        } else {
            System.currentTimeMillis()
        }

        // Prefer opening a concrete Grinta event so the calendar app lands on
        // the calendar that actually holds the synced agenda.
        if (id != null) {
            val eventId = findFocusEventId(activity, id, focusMillis)
            if (eventId != null) {
                val eventIntent = Intent(Intent.ACTION_VIEW).apply {
                    data = ContentUris.withAppendedId(
                        CalendarContract.Events.CONTENT_URI,
                        eventId,
                    )
                    putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, focusMillis)
                    putExtra(CalendarContract.Events.CALENDAR_ID, id)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                if (startActivitySafely(activity, eventIntent)) return true
            }
        }

        val timeBuilder = CalendarContract.CONTENT_URI.buildUpon().appendPath("time")
        ContentUris.appendId(timeBuilder, focusMillis)
        val timeIntent = Intent(Intent.ACTION_VIEW).apply {
            data = timeBuilder.build()
            if (id != null) {
                putExtra(CalendarContract.Events.CALENDAR_ID, id)
                putExtra("calendar_id", id)
            }
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        if (startActivitySafely(activity, timeIntent)) return true

        val legacyTimeIntent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("content://com.android.calendar/time/$focusMillis")
            if (id != null) {
                putExtra(CalendarContract.Events.CALENDAR_ID, id)
                putExtra("calendar_id", id)
            }
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        if (startActivitySafely(activity, legacyTimeIntent)) return true

        val appIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_APP_CALENDAR)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return startActivitySafely(activity, appIntent)
    }

    private fun startActivitySafely(activity: MainActivity, intent: Intent): Boolean {
        return try {
            // Do not gate on resolveActivity(): on Android 11+ it often returns
            // null for calendar apps unless <queries> lists them, even when
            // startActivity would succeed.
            activity.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Prefer the next upcoming event in [calendarId]; otherwise the most recent past one.
     */
    private fun findFocusTimeForCalendar(activity: MainActivity, calendarId: Long): Long? {
        val upcoming = queryEventLong(
            activity = activity,
            selection = (
                "${CalendarContract.Events.CALENDAR_ID}=? AND " +
                    "${CalendarContract.Events.DELETED}=0 AND " +
                    "${CalendarContract.Events.DTSTART}>=?"
                ),
            selectionArgs = arrayOf(calendarId.toString(), System.currentTimeMillis().toString()),
            sortOrder = "${CalendarContract.Events.DTSTART} ASC",
            column = CalendarContract.Events.DTSTART,
        )
        if (upcoming != null) return upcoming

        return queryEventLong(
            activity = activity,
            selection = (
                "${CalendarContract.Events.CALENDAR_ID}=? AND " +
                    "${CalendarContract.Events.DELETED}=0"
                ),
            selectionArgs = arrayOf(calendarId.toString()),
            sortOrder = "${CalendarContract.Events.DTSTART} DESC",
            column = CalendarContract.Events.DTSTART,
        )
    }

    private fun findFocusEventId(
        activity: MainActivity,
        calendarId: Long,
        focusMillis: Long,
    ): Long? {
        return queryEventLong(
            activity = activity,
            selection = (
                "${CalendarContract.Events.CALENDAR_ID}=? AND " +
                    "${CalendarContract.Events.DELETED}=0 AND " +
                    "${CalendarContract.Events.DTSTART}=?"
                ),
            selectionArgs = arrayOf(calendarId.toString(), focusMillis.toString()),
            sortOrder = null,
            column = CalendarContract.Events._ID,
        )
    }

    private fun queryEventLong(
        activity: MainActivity,
        selection: String,
        selectionArgs: Array<String>,
        sortOrder: String?,
        column: String,
    ): Long? {
        activity.contentResolver.query(
            CalendarContract.Events.CONTENT_URI,
            arrayOf(CalendarContract.Events._ID, CalendarContract.Events.DTSTART),
            selection,
            selectionArgs,
            sortOrder,
        )?.use { cursor ->
            if (!cursor.moveToFirst()) return null
            val index = when (column) {
                CalendarContract.Events._ID -> 0
                CalendarContract.Events.DTSTART -> 1
                else -> return null
            }
            if (cursor.isNull(index)) return null
            return cursor.getLong(index)
        }
        return null
    }
}
