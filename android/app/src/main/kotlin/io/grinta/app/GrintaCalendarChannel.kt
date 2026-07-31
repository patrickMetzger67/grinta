package io.grinta.app

import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.provider.CalendarContract
import android.util.Log
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
    private const val TAG = "GrintaCalendar"

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

    /**
     * Opens a calendar app focused near Grinta events.
     *
     * Returns a map `{ok, via, attempts}` so Flutter can show a useful error.
     * Prefer day/time view over event detail: Google Calendar often flashes and
     * closes for LOCAL calendar event URIs even when startActivity does not throw.
     */
    private fun openCalendarApp(
        activity: MainActivity,
        calendarId: String?,
    ): Map<String, Any?> {
        val id = calendarId?.trim()?.toLongOrNull()
        if (id != null) {
            ensureCalendarVisible(activity, id.toString())
        }

        val focusMillis = if (id != null) {
            findFocusTimeForCalendar(activity, id) ?: System.currentTimeMillis()
        } else {
            System.currentTimeMillis()
        }

        val timeUri = CalendarContract.CONTENT_URI.buildUpon()
            .appendPath("time")
            .let { builder ->
                ContentUris.appendId(builder, focusMillis)
                builder.build()
            }
        val legacyTimeUri = Uri.parse("content://com.android.calendar/time/$focusMillis")

        val packages = listOf(
            "com.google.android.calendar",
            "com.samsung.android.calendar",
            "com.huawei.calendar",
            "com.xiaomi.calendar",
        )

        val candidates = mutableListOf<Pair<String, Intent>>()
        for (pkg in packages) {
            candidates += "pkg:$pkg/time" to Intent(Intent.ACTION_VIEW, timeUri).setPackage(pkg)
            candidates += "pkg:$pkg/legacy" to Intent(Intent.ACTION_VIEW, legacyTimeUri).setPackage(pkg)
        }
        candidates += "implicit/time" to Intent(Intent.ACTION_VIEW, timeUri).also { intent ->
            if (id != null) {
                intent.putExtra(CalendarContract.Events.CALENDAR_ID, id)
                intent.putExtra("calendar_id", id)
            }
        }
        candidates += "implicit/legacy" to Intent(Intent.ACTION_VIEW, legacyTimeUri)
        candidates += "app_calendar" to Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_APP_CALENDAR)

        // Explicit launchers as last package-targeted resorts.
        for (pkg in packages) {
            val launch = activity.packageManager.getLaunchIntentForPackage(pkg)
            if (launch != null) {
                candidates += "launcher:$pkg" to launch
            }
        }

        candidates += "chooser/time" to Intent.createChooser(
            Intent(Intent.ACTION_VIEW, timeUri),
            "Calendar",
        )

        val attempts = mutableListOf<String>()
        for ((label, intent) in candidates) {
            // Activity context: do not use FLAG_ACTIVITY_NEW_TASK (can leave the
            // calendar in another task so it never comes to the foreground).
            intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            try {
                activity.startActivity(intent)
                Log.i(TAG, "opened via $label focus=$focusMillis calendarId=$id")
                return mapOf(
                    "ok" to true,
                    "via" to label,
                    "focusMillis" to focusMillis,
                    "calendarId" to id?.toString(),
                    "attempts" to attempts,
                )
            } catch (e: Exception) {
                val detail = "$label -> ${e.javaClass.simpleName}: ${e.message}"
                attempts += detail
                Log.w(TAG, "open failed: $detail", e)
            }
        }

        Log.e(TAG, "all open attempts failed calendarId=$id attempts=$attempts")
        return mapOf(
            "ok" to false,
            "via" to null,
            "focusMillis" to focusMillis,
            "calendarId" to id?.toString(),
            "attempts" to attempts,
        )
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
