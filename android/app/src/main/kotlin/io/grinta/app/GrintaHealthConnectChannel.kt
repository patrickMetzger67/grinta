package io.grinta.app

import android.util.Log
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.DistanceRecord
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import java.time.Instant

/**
 * Direct Health Connect exercise reader.
 *
 * The Flutter [health] plugin may enrich WORKOUT with extra record types.
 * If any of those reads throws SecurityException, the plugin can return an
 * empty list for the whole query — even when Exercise sessions exist.
 *
 * This channel reads [ExerciseSessionRecord] first, then best-effort enriches
 * with Distance only. Heart rate / calories / sleep / steps are not read
 * (Play Health Connect minimal-scope policy).
 */
object GrintaHealthConnectChannel {
    const val CHANNEL_NAME = "io.grinta.app/health_connect"
    private const val TAG = "GrintaHealthConnect"

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private val exerciseTypeNames: Map<Int, String> = mapOf(
        ExerciseSessionRecord.EXERCISE_TYPE_FOOTBALL_AMERICAN to "AMERICAN_FOOTBALL",
        ExerciseSessionRecord.EXERCISE_TYPE_FOOTBALL_AUSTRALIAN to "AUSTRALIAN_FOOTBALL",
        ExerciseSessionRecord.EXERCISE_TYPE_BADMINTON to "BADMINTON",
        ExerciseSessionRecord.EXERCISE_TYPE_BASEBALL to "BASEBALL",
        ExerciseSessionRecord.EXERCISE_TYPE_BASKETBALL to "BASKETBALL",
        ExerciseSessionRecord.EXERCISE_TYPE_BIKING to "BIKING",
        ExerciseSessionRecord.EXERCISE_TYPE_BOXING to "BOXING",
        ExerciseSessionRecord.EXERCISE_TYPE_CALISTHENICS to "CALISTHENICS",
        ExerciseSessionRecord.EXERCISE_TYPE_DANCING to "DANCING",
        ExerciseSessionRecord.EXERCISE_TYPE_CRICKET to "CRICKET",
        ExerciseSessionRecord.EXERCISE_TYPE_SKIING to "SKIING",
        ExerciseSessionRecord.EXERCISE_TYPE_ELLIPTICAL to "ELLIPTICAL",
        ExerciseSessionRecord.EXERCISE_TYPE_FENCING to "FENCING",
        ExerciseSessionRecord.EXERCISE_TYPE_FRISBEE_DISC to "FRISBEE_DISC",
        ExerciseSessionRecord.EXERCISE_TYPE_GOLF to "GOLF",
        ExerciseSessionRecord.EXERCISE_TYPE_GUIDED_BREATHING to "GUIDED_BREATHING",
        ExerciseSessionRecord.EXERCISE_TYPE_GYMNASTICS to "GYMNASTICS",
        ExerciseSessionRecord.EXERCISE_TYPE_HANDBALL to "HANDBALL",
        ExerciseSessionRecord.EXERCISE_TYPE_HIGH_INTENSITY_INTERVAL_TRAINING to
            "HIGH_INTENSITY_INTERVAL_TRAINING",
        ExerciseSessionRecord.EXERCISE_TYPE_HIKING to "HIKING",
        ExerciseSessionRecord.EXERCISE_TYPE_ICE_SKATING to "ICE_SKATING",
        ExerciseSessionRecord.EXERCISE_TYPE_MARTIAL_ARTS to "MARTIAL_ARTS",
        ExerciseSessionRecord.EXERCISE_TYPE_PARAGLIDING to "PARAGLIDING",
        ExerciseSessionRecord.EXERCISE_TYPE_PILATES to "PILATES",
        ExerciseSessionRecord.EXERCISE_TYPE_RACQUETBALL to "RACQUETBALL",
        ExerciseSessionRecord.EXERCISE_TYPE_ROCK_CLIMBING to "ROCK_CLIMBING",
        ExerciseSessionRecord.EXERCISE_TYPE_ROWING to "ROWING",
        ExerciseSessionRecord.EXERCISE_TYPE_ROWING_MACHINE to "ROWING_MACHINE",
        ExerciseSessionRecord.EXERCISE_TYPE_RUGBY to "RUGBY",
        ExerciseSessionRecord.EXERCISE_TYPE_RUNNING_TREADMILL to "RUNNING_TREADMILL",
        ExerciseSessionRecord.EXERCISE_TYPE_RUNNING to "RUNNING",
        ExerciseSessionRecord.EXERCISE_TYPE_SAILING to "SAILING",
        ExerciseSessionRecord.EXERCISE_TYPE_SCUBA_DIVING to "SCUBA_DIVING",
        ExerciseSessionRecord.EXERCISE_TYPE_SKATING to "SKATING",
        ExerciseSessionRecord.EXERCISE_TYPE_SNOWBOARDING to "SNOWBOARDING",
        ExerciseSessionRecord.EXERCISE_TYPE_SNOWSHOEING to "SNOWSHOEING",
        ExerciseSessionRecord.EXERCISE_TYPE_SOCCER to "SOCCER",
        ExerciseSessionRecord.EXERCISE_TYPE_SOFTBALL to "SOFTBALL",
        ExerciseSessionRecord.EXERCISE_TYPE_SQUASH to "SQUASH",
        ExerciseSessionRecord.EXERCISE_TYPE_STAIR_CLIMBING_MACHINE to "STAIR_CLIMBING_MACHINE",
        ExerciseSessionRecord.EXERCISE_TYPE_STAIR_CLIMBING to "STAIR_CLIMBING",
        ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING to "STRENGTH_TRAINING",
        ExerciseSessionRecord.EXERCISE_TYPE_SURFING to "SURFING",
        ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_OPEN_WATER to "SWIMMING_OPEN_WATER",
        ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_POOL to "SWIMMING_POOL",
        ExerciseSessionRecord.EXERCISE_TYPE_TABLE_TENNIS to "TABLE_TENNIS",
        ExerciseSessionRecord.EXERCISE_TYPE_TENNIS to "TENNIS",
        ExerciseSessionRecord.EXERCISE_TYPE_VOLLEYBALL to "VOLLEYBALL",
        ExerciseSessionRecord.EXERCISE_TYPE_WALKING to "WALKING",
        ExerciseSessionRecord.EXERCISE_TYPE_WATER_POLO to "WATER_POLO",
        ExerciseSessionRecord.EXERCISE_TYPE_WEIGHTLIFTING to "WEIGHTLIFTING",
        ExerciseSessionRecord.EXERCISE_TYPE_WHEELCHAIR to "WHEELCHAIR",
        ExerciseSessionRecord.EXERCISE_TYPE_YOGA to "YOGA",
        ExerciseSessionRecord.EXERCISE_TYPE_OTHER_WORKOUT to "OTHER",
    )

    fun register(flutterEngine: FlutterEngine, activity: MainActivity) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "listExerciseSessions" -> {
                    val lookbackDays = (call.argument<Number>("lookbackDays")?.toInt() ?: 90)
                        .coerceIn(1, 365)
                    scope.launch {
                        try {
                            val payload = listExerciseSessions(activity, lookbackDays)
                            activity.runOnUiThread { result.success(payload) }
                        } catch (e: Exception) {
                            Log.e(TAG, "listExerciseSessions failed", e)
                            activity.runOnUiThread {
                                result.error("health_connect_error", e.message, null)
                            }
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private suspend fun listExerciseSessions(
        activity: MainActivity,
        lookbackDays: Int,
    ): Map<String, Any?> {
        val status = HealthConnectClient.getSdkStatus(activity)
        if (status != HealthConnectClient.SDK_AVAILABLE) {
            Log.w(TAG, "Health Connect SDK unavailable status=$status")
            return mapOf(
                "ok" to false,
                "reason" to "unavailable",
                "sdkStatus" to status,
                "sessionCount" to 0,
                "workouts" to emptyList<Map<String, Any?>>(),
                "warnings" to emptyList<String>(),
            )
        }

        val client = HealthConnectClient.getOrCreate(activity)
        val granted = client.permissionController.getGrantedPermissions()
        val exerciseRead = HealthPermission.getReadPermission(ExerciseSessionRecord::class)
        val hasExercise = granted.contains(exerciseRead)
        Log.i(
            TAG,
            "grantedPermissions=${granted.size} hasExerciseRead=$hasExercise " +
                "lookbackDays=$lookbackDays",
        )

        if (!hasExercise) {
            return mapOf(
                "ok" to false,
                "reason" to "missing_exercise_permission",
                "sessionCount" to 0,
                "workouts" to emptyList<Map<String, Any?>>(),
                "warnings" to listOf("READ_EXERCISE not granted"),
                "grantedPermissionCount" to granted.size,
            )
        }

        val end = Instant.now()
        val start = end.minusSeconds(lookbackDays.toLong() * 24L * 60L * 60L)
        val sessions = mutableListOf<ExerciseSessionRecord>()
        var pageToken: String? = null
        do {
            val response = client.readRecords(
                ReadRecordsRequest(
                    recordType = ExerciseSessionRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(start, end),
                    pageToken = pageToken,
                ),
            )
            sessions.addAll(response.records)
            pageToken = response.pageToken
        } while (!pageToken.isNullOrEmpty())

        Log.i(TAG, "ExerciseSessionRecord count=${sessions.size}")

        val warnings = mutableListOf<String>()
        val workouts = sessions.map { session ->
            enrichSession(client, session, warnings)
        }.sortedByDescending { it["dateFromMs"] as Long }

        return mapOf(
            "ok" to true,
            "reason" to null,
            "sessionCount" to sessions.size,
            "workouts" to workouts,
            "warnings" to warnings.distinct(),
            "grantedPermissionCount" to granted.size,
            "hasDistance" to granted.contains(
                HealthPermission.getReadPermission(DistanceRecord::class),
            ),
        )
    }

    private suspend fun enrichSession(
        client: HealthConnectClient,
        session: ExerciseSessionRecord,
        warnings: MutableList<String>,
    ): Map<String, Any?> {
        val range = TimeRangeFilter.between(session.startTime, session.endTime)

        var totalDistance: Double? = null
        try {
            val distance = client.readRecords(
                ReadRecordsRequest(
                    recordType = DistanceRecord::class,
                    timeRangeFilter = range,
                ),
            )
            val meters = distance.records.sumOf { it.distance.inMeters }
            if (meters > 0.0) totalDistance = meters
        } catch (e: SecurityException) {
            warnings.add("distance_denied")
            Log.w(TAG, "Distance enrich denied for ${session.metadata.id}: ${e.message}")
        } catch (e: Exception) {
            warnings.add("distance_error")
            Log.w(TAG, "Distance enrich failed for ${session.metadata.id}", e)
        }

        val activityType =
            exerciseTypeNames[session.exerciseType] ?: "OTHER"
        val title = session.title?.trim().orEmpty()

        return mapOf(
            "uuid" to session.metadata.id,
            "workoutActivityType" to activityType,
            "title" to title.ifEmpty { null },
            "totalDistance" to totalDistance,
            "totalDistanceUnit" to "METER",
            "dateFromMs" to session.startTime.toEpochMilli(),
            "dateToMs" to session.endTime.toEpochMilli(),
            "sourceName" to session.metadata.dataOrigin.packageName,
        )
    }
}
