plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.dagger.hilt.android")
    id("com.google.devtools.ksp")
}

android {
    namespace = "com.ozge.adas"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.ozge.adas"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "0.1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }

        // Read Maps API key from local.properties
        val properties = java.util.Properties()
        val localPropsFile = rootProject.file("local.properties")
        if (localPropsFile.exists()) {
            properties.load(localPropsFile.inputStream())
        }
        manifestPlaceholders["MAPS_API_KEY"] = properties.getProperty("MAPS_API_KEY", "")
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
            applicationIdSuffix = ".debug"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.8"
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    // ── Core Android ──
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.7.0")
    implementation("androidx.activity:activity-compose:1.8.2")

    // ── Jetpack Compose ──
    implementation(platform("androidx.compose:compose-bom:2024.01.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")

    // ── Navigation ──
    implementation("androidx.navigation:navigation-compose:2.7.6")
    implementation("androidx.hilt:hilt-navigation-compose:1.1.0")

    // ── Hilt (Dependency Injection) ──
    implementation("com.google.dagger:hilt-android:2.50")
    ksp("com.google.dagger:hilt-android-compiler:2.50")

    // ── Room (Local Database) ──
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    ksp("androidx.room:room-compiler:2.6.1")

    // ── Coroutines ──
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")

    // ── Google Maps ──
    implementation("com.google.maps.android:maps-compose:4.3.0")
    implementation("com.google.android.gms:play-services-maps:18.2.0")
    implementation("com.google.android.gms:play-services-location:21.0.1")

    // ── OBD-II ──
    implementation("com.github.pires:obd-java-api:1.0")

    // ── DataStore (Preferences) ──
    implementation("androidx.datastore:datastore-preferences:1.0.0")

    // ── Gson (JSON) ──
    implementation("com.google.code.gson:gson:2.10.1")

    // ── Testing ──
    testImplementation("junit:junit:4.13.2")
    testImplementation("io.mockk:mockk:1.13.9")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
    testImplementation("app.cash.turbine:turbine:1.0.0")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
    androidTestImplementation(platform("androidx.compose:compose-bom:2024.01.00"))
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
}

# Retrofit ADAS ProGuard Rules

# Keep Room entities
-keep class com.ozge.adas.data.local.** { *; }

# Keep domain models (used with Gson)
-keep class com.ozge.adas.domain.model.** { *; }

# Hilt
-dontwarn dagger.hilt.**

# OBD-II Java API
-keep class pt.lighthouselabs.obd.** { *; }

# Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# Compose
-dontwarn androidx.compose.**

package com.ozge.adas.util

import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

/**
 * App-wide constants for the ADAS system.
 */
object Constants {
    // Speed thresholds
    const val DEFAULT_SPEED_LIMIT_KMH = 120
    const val SPEED_WARNING_OFFSET = 10    // warn at limit + 10
    const val SPEED_CRITICAL_OFFSET = 30   // critical at limit + 30

    // Braking thresholds
    const val HARSH_BRAKING_G_FORCE = 0.42  // ~15 km/h/s deceleration
    const val HARSH_ACCEL_G_FORCE = 0.35

    // Fatigue thresholds (minutes)
    const val FATIGUE_REMINDER_MIN = 90L
    const val FATIGUE_WARNING_MIN = 120L
    const val FATIGUE_URGENT_MIN = 150L

    // OBD-II refresh rate
    const val OBD_REFRESH_DELAY_MS = 200L  // ~5Hz

    // Database
    const val DB_NAME = "adas_database"
}

/**
 * Extension functions for common operations.
 */
fun LocalDateTime.toDisplayString(): String {
    return this.format(DateTimeFormatter.ofPattern("dd MMM yyyy, HH:mm"))
}

fun LocalDateTime.toIsoString(): String {
    return this.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME)
}

fun String.toLocalDateTime(): LocalDateTime {
    return LocalDateTime.parse(this, DateTimeFormatter.ISO_LOCAL_DATE_TIME)
}

/**
 * Format duration in minutes to human-readable string.
 */
fun Long.formatDuration(): String {
    return when {
        this < 60 -> "$this dk"
        else -> "${this / 60}s ${this % 60}dk"
    }
}

/**
 * Format distance in km to display string.
 */
fun Double.formatDistance(): String {
    return String.format("%.1f km", this)
}

package com.ozge.adas.domain.usecase

import com.ozge.adas.domain.model.*
import com.ozge.adas.domain.repository.AlertRepository
import com.ozge.adas.domain.repository.VehicleRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

/**
 * Monitors vehicle speed and generates alerts when limits are exceeded.
 */
class MonitorSpeedUseCase @Inject constructor(
    private val vehicleRepository: VehicleRepository,
    private val alertRepository: AlertRepository
) {
    operator fun invoke(speedLimitKmh: Int): Flow<Alert?> {
        return vehicleRepository.getVehicleDataStream().map { data ->
            if (data.speedKmh > speedLimitKmh) {
                val severity = when {
                    data.speedKmh > speedLimitKmh + 30 -> AlertSeverity.CRITICAL
                    data.speedKmh > speedLimitKmh + 10 -> AlertSeverity.WARNING
                    else -> AlertSeverity.INFO
                }
                val alert = Alert(
                    type = AlertType.SPEED_LIMIT_EXCEEDED,
                    severity = severity,
                    message = "Hız limiti aşıldı: ${data.speedKmh} km/h (Limit: $speedLimitKmh km/h)",
                    value = data.speedKmh.toDouble()
                )
                alertRepository.saveAlert(alert)
                alert
            } else null
        }
    }
}

/**
 * Detects harsh braking events using speed delta analysis.
 */
class DetectHarshBrakingUseCase @Inject constructor(
    private val vehicleRepository: VehicleRepository,
    private val alertRepository: AlertRepository
) {
    private var previousSpeed: Int? = null
    private var previousTimestamp: Long? = null

    companion object {
        const val HARSH_BRAKING_THRESHOLD_KMH_PER_SEC = 15.0 // ~0.42g
    }

    operator fun invoke(): Flow<Alert?> {
        return vehicleRepository.getVehicleDataStream().map { data ->
            val prev = previousSpeed
            val prevTime = previousTimestamp
            previousSpeed = data.speedKmh
            previousTimestamp = data.timestamp

            if (prev != null && prevTime != null) {
                val timeDeltaSec = (data.timestamp - prevTime) / 1000.0
                if (timeDeltaSec > 0) {
                    val deceleration = (prev - data.speedKmh) / timeDeltaSec
                    if (deceleration > HARSH_BRAKING_THRESHOLD_KMH_PER_SEC) {
                        val alert = Alert(
                            type = AlertType.HARSH_BRAKING,
                            severity = AlertSeverity.WARNING,
                            message = "Sert fren algılandı! (${String.format("%.1f", deceleration)} km/h/s)",
                            value = deceleration
                        )
                        alertRepository.saveAlert(alert)
                        return@map alert
                    }
                }
            }
            null
        }
    }
}

/**
 * Monitors driving duration and issues fatigue alerts.
 */
class MonitorFatigueUseCase @Inject constructor(
    private val alertRepository: AlertRepository
) {
    companion object {
        const val REMINDER_MINUTES = 90L    // 1.5 hours
        const val WARNING_MINUTES = 120L    // 2 hours
        const val URGENT_MINUTES = 150L     // 2.5 hours
    }

    suspend fun checkFatigue(drivingMinutes: Long): Alert? {
        val (type, severity, message) = when {
            drivingMinutes >= URGENT_MINUTES -> Triple(
                AlertType.FATIGUE_URGENT,
                AlertSeverity.CRITICAL,
                "⚠️ ${drivingMinutes} dakikadır sürüyorsunuz! Lütfen mola verin."
            )
            drivingMinutes >= WARNING_MINUTES -> Triple(
                AlertType.FATIGUE_WARNING,
                AlertSeverity.WARNING,
                "Dikkat: ${drivingMinutes} dakikadır sürüyorsunuz. Mola önerilir."
            )
            drivingMinutes >= REMINDER_MINUTES -> Triple(
                AlertType.FATIGUE_REMINDER,
                AlertSeverity.INFO,
                "${drivingMinutes} dakikadır sürüyorsunuz. Mola vermeyi düşünün."
            )
            else -> return null
        }

        val alert = Alert(type = type, severity = severity, message = message)
        alertRepository.saveAlert(alert)
        return alert
    }
}

/**
 * Calculates the driving score for a completed trip.
 */
class CalculateDrivingScoreUseCase @Inject constructor() {

    operator fun invoke(
        totalSpeedReadings: Int,
        speedViolations: Int,
        harshBrakingEvents: Int,
        harshAccelerationEvents: Int,
        drivingMinutes: Long,
        avgFuelConsumption: Double
    ): DrivingScore {
        val speedCompliance = if (totalSpeedReadings > 0) {
            ((1 - speedViolations.toDouble() / totalSpeedReadings) * 100).toInt().coerceIn(0, 100)
        } else 100

        val brakingSmoothness = when {
            harshBrakingEvents == 0 -> 100
            harshBrakingEvents <= 2 -> 80
            harshBrakingEvents <= 5 -> 60
            else -> 30
        }

        val accelerationPatterns = when {
            harshAccelerationEvents == 0 -> 100
            harshAccelerationEvents <= 3 -> 75
            else -> 40
        }

        val tripDurationManagement = when {
            drivingMinutes <= 90 -> 100
            drivingMinutes <= 120 -> 80
            drivingMinutes <= 150 -> 50
            else -> 20
        }

        val fuelEfficiency = when {
            avgFuelConsumption <= 6.0 -> 100
            avgFuelConsumption <= 8.0 -> 80
            avgFuelConsumption <= 10.0 -> 60
            else -> 40
        }

        return DrivingScore.calculate(
            speedCompliance = speedCompliance,
            brakingSmoothness = brakingSmoothness,
            accelerationPatterns = accelerationPatterns,
            tripDurationManagement = tripDurationManagement,
            fuelEfficiency = fuelEfficiency
        )
    }
}

package com.ozge.adas.domain.model

import java.time.LocalDateTime

/**
 * Represents a completed or ongoing driving trip.
 */
data class Trip(
    val id: Long = 0,
    val startTime: LocalDateTime,
    val endTime: LocalDateTime? = null,
    val distanceKm: Double = 0.0,
    val avgSpeedKmh: Double = 0.0,
    val maxSpeedKmh: Double = 0.0,
    val drivingScore: Int = 0, // 0-100
    val harshBrakingCount: Int = 0,
    val speedViolationCount: Int = 0,
    val fuelEstimateLiters: Double = 0.0,
    val routePoints: List<RoutePoint> = emptyList()
) {
    val durationMinutes: Long
        get() = java.time.Duration.between(startTime, endTime ?: LocalDateTime.now()).toMinutes()

    val isOngoing: Boolean
        get() = endTime == null
}

/**
 * A single GPS point along a trip route.
 */
data class RoutePoint(
    val latitude: Double,
    val longitude: Double,
    val speedKmh: Double,
    val timestamp: LocalDateTime
)

package com.ozge.adas.domain.model

/**
 * Real-time vehicle data snapshot from OBD-II.
 */
data class VehicleData(
    val speedKmh: Int = 0,
    val rpm: Int = 0,
    val engineCoolantTemp: Int = 0,   // °C
    val throttlePosition: Int = 0,     // 0-100%
    val fuelLevel: Int = 0,            // 0-100%
    val timestamp: Long = System.currentTimeMillis()
)

/**
 * OBD-II connection states.
 */
enum class ConnectionState {
    DISCONNECTED,
    CONNECTING,
    CONNECTED,
    ERROR,
    RECONNECTING
}

/**
 * Bluetooth device info for OBD-II adapter selection.
 */
data class ObdDevice(
    val name: String,
    val address: String,  // MAC address
    val isPaired: Boolean = false
)

package com.ozge.adas.domain.model

import java.time.LocalDateTime

/**
 * Represents a safety alert triggered by the ADAS system.
 */
data class Alert(
    val id: Long = 0,
    val type: AlertType,
    val severity: AlertSeverity,
    val message: String,
    val timestamp: LocalDateTime = LocalDateTime.now(),
    val tripId: Long? = null,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val value: Double? = null  // e.g., speed value, g-force
)

enum class AlertType {
    SPEED_LIMIT_EXCEEDED,
    HARSH_BRAKING,
    HARSH_ACCELERATION,
    FATIGUE_REMINDER,
    FATIGUE_WARNING,
    FATIGUE_URGENT,
    ENGINE_OVERHEAT,
    CONNECTION_LOST
}

enum class AlertSeverity {
    INFO,       // Blue - gentle reminders
    WARNING,    // Orange - attention needed
    CRITICAL    // Red - immediate action required
}

/**
 * Driving score breakdown for analytics.
 */
data class DrivingScore(
    val overall: Int,                  // 0-100
    val speedCompliance: Int,          // 30% weight
    val brakingSmoothness: Int,        // 25% weight
    val accelerationPatterns: Int,     // 20% weight
    val tripDurationManagement: Int,   // 15% weight
    val fuelEfficiency: Int            // 10% weight
) {
    companion object {
        fun calculate(
            speedCompliance: Int,
            brakingSmoothness: Int,
            accelerationPatterns: Int,
            tripDurationManagement: Int,
            fuelEfficiency: Int
        ): DrivingScore {
            val overall = (
                speedCompliance * 0.30 +
                brakingSmoothness * 0.25 +
                accelerationPatterns * 0.20 +
                tripDurationManagement * 0.15 +
                fuelEfficiency * 0.10
            ).toInt()

            return DrivingScore(
                overall = overall,
                speedCompliance = speedCompliance,
                brakingSmoothness = brakingSmoothness,
                accelerationPatterns = accelerationPatterns,
                tripDurationManagement = tripDurationManagement,
                fuelEfficiency = fuelEfficiency
            )
        }
    }
}

package com.ozge.adas.domain.repository

import com.ozge.adas.domain.model.*
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for OBD-II vehicle data operations.
 */
interface VehicleRepository {
    fun getVehicleDataStream(): Flow<VehicleData>
    fun getConnectionState(): Flow<ConnectionState>
    suspend fun connect(device: ObdDevice)
    suspend fun disconnect()
    fun getAvailableDevices(): Flow<List<ObdDevice>>
}

/**
 * Repository interface for trip data persistence.
 */
interface TripRepository {
    fun getAllTrips(): Flow<List<Trip>>
    suspend fun getTripById(id: Long): Trip?
    suspend fun startTrip(): Long
    suspend fun endTrip(tripId: Long)
    suspend fun updateTrip(trip: Trip)
    suspend fun deleteTrip(tripId: Long)
    fun getActiveTrip(): Flow<Trip?>
}

/**
 * Repository interface for alert management.
 */
interface AlertRepository {
    fun getAlertsForTrip(tripId: Long): Flow<List<Alert>>
    fun getRecentAlerts(limit: Int = 10): Flow<List<Alert>>
    suspend fun saveAlert(alert: Alert)
    suspend fun clearAlerts(tripId: Long)
}

package com.ozge.adas.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.ozge.adas.data.remote.ObdConnectionManager
import com.ozge.adas.domain.model.ConnectionState
import com.ozge.adas.presentation.MainActivity
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.collectLatest
import javax.inject.Inject

/**
 * Foreground service that maintains OBD-II connection
 * and continues data collection when the app is in background.
 */
@AndroidEntryPoint
class ObdForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "adas_obd_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "com.ozge.adas.START_OBD"
        const val ACTION_STOP = "com.ozge.adas.STOP_OBD"
    }

    @Inject lateinit var obdConnectionManager: ObdConnectionManager
    @Inject lateinit var alertNotificationManager: AlertNotificationManager

    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var dataStreamJob: Job? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                startForeground(NOTIFICATION_ID, createNotification("Bağlantı bekleniyor..."))
                startDataCollection()
            }
            ACTION_STOP -> {
                stopDataCollection()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startDataCollection() {
        dataStreamJob = serviceScope.launch {
            // Update notification based on connection state
            obdConnectionManager.connectionState.collectLatest { state ->
                val text = when (state) {
                    ConnectionState.CONNECTED -> "Araç verisi okunuyor..."
                    ConnectionState.CONNECTING -> "Bağlanıyor..."
                    ConnectionState.RECONNECTING -> "Yeniden bağlanıyor..."
                    ConnectionState.ERROR -> "Bağlantı hatası"
                    ConnectionState.DISCONNECTED -> "Bağlantı kesildi"
                }
                updateNotification(text)
            }
        }

        // Start reading vehicle data
        serviceScope.launch {
            try {
                obdConnectionManager.startDataStream()
            } catch (e: Exception) {
                updateNotification("Veri okuma hatası: ${e.message}")
            }
        }
    }

    private fun stopDataCollection() {
        dataStreamJob?.cancel()
        obdConnectionManager.disconnect()
        serviceScope.cancel()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "ADAS Araç Bağlantısı",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "OBD-II veri akışı durumu"
            setShowBadge(false)
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    private fun createNotification(text: String): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Retrofit ADAS")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .build()
    }

    private fun updateNotification(text: String) {
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, createNotification(text))
    }

    override fun onDestroy() {
        super.onDestroy()
        stopDataCollection()
    }
}

package com.ozge.adas.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat
import com.ozge.adas.domain.model.Alert
import com.ozge.adas.domain.model.AlertSeverity
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Handles alert notifications via system notifications, sound, and vibration.
 */
@Singleton
class AlertNotificationManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        const val ALERT_CHANNEL_ID = "adas_alerts"
        const val ALERT_NOTIFICATION_ID = 2001
    }

    private val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    private val vibrator: Vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        (context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
    } else {
        @Suppress("DEPRECATION")
        context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
    }

    init {
        createAlertChannel()
    }

    private fun createAlertChannel() {
        val channel = NotificationChannel(
            ALERT_CHANNEL_ID,
            "ADAS Uyarıları",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Hız aşımı, sert fren ve yorgunluk uyarıları"
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 300, 200, 300)
        }
        notificationManager.createNotificationChannel(channel)
    }

    fun showAlert(alert: Alert, enableSound: Boolean = true, enableVibration: Boolean = true) {
        // Vibration pattern based on severity
        if (enableVibration) {
            val pattern = when (alert.severity) {
                AlertSeverity.CRITICAL -> longArrayOf(0, 500, 200, 500, 200, 500) // 3 long bursts
                AlertSeverity.WARNING -> longArrayOf(0, 300, 200, 300)             // 2 medium bursts
                AlertSeverity.INFO -> longArrayOf(0, 200)                           // 1 short burst
            }
            vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
        }

        // Notification
        val icon = when (alert.severity) {
            AlertSeverity.CRITICAL -> android.R.drawable.ic_dialog_alert
            AlertSeverity.WARNING -> android.R.drawable.ic_dialog_alert
            AlertSeverity.INFO -> android.R.drawable.ic_dialog_info
        }

        val builder = NotificationCompat.Builder(context, ALERT_CHANNEL_ID)
            .setSmallIcon(icon)
            .setContentTitle(
                when (alert.severity) {
                    AlertSeverity.CRITICAL -> "⚠️ KRİTİK UYARI"
                    AlertSeverity.WARNING -> "⚠️ Uyarı"
                    AlertSeverity.INFO -> "ℹ️ Bilgi"
                }
            )
            .setContentText(alert.message)
            .setPriority(
                when (alert.severity) {
                    AlertSeverity.CRITICAL -> NotificationCompat.PRIORITY_MAX
                    AlertSeverity.WARNING -> NotificationCompat.PRIORITY_HIGH
                    AlertSeverity.INFO -> NotificationCompat.PRIORITY_DEFAULT
                }
            )
            .setAutoCancel(true)

        if (enableSound) {
            builder.setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM))
        }

        notificationManager.notify(ALERT_NOTIFICATION_ID, builder.build())
    }

    fun cancelAlerts() {
        notificationManager.cancel(ALERT_NOTIFICATION_ID)
        vibrator.cancel()
    }
}

package com.ozge.adas.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "adas_settings")

/**
 * DataStore-backed user preferences for app settings.
 * Provides reactive flows for each setting and suspend functions to update them.
 */
@Singleton
class UserPreferences @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private object Keys {
        val SPEED_LIMIT = intPreferencesKey("speed_limit")
        val DARK_MODE = booleanPreferencesKey("dark_mode")
        val SOUND_ALERTS = booleanPreferencesKey("sound_alerts")
        val VIBRATION_ALERTS = booleanPreferencesKey("vibration_alerts")
    }

    // ── Read Flows ──

    val speedLimit: Flow<Int> = context.dataStore.data
        .catch { emit(emptyPreferences()) }
        .map { it[Keys.SPEED_LIMIT] ?: 120 }

    val darkMode: Flow<Boolean> = context.dataStore.data
        .catch { emit(emptyPreferences()) }
        .map { it[Keys.DARK_MODE] ?: false }

    val soundAlerts: Flow<Boolean> = context.dataStore.data
        .catch { emit(emptyPreferences()) }
        .map { it[Keys.SOUND_ALERTS] ?: true }

    val vibrationAlerts: Flow<Boolean> = context.dataStore.data
        .catch { emit(emptyPreferences()) }
        .map { it[Keys.VIBRATION_ALERTS] ?: true }

    // ── Write Functions ──

    suspend fun setSpeedLimit(limit: Int) {
        context.dataStore.edit { it[Keys.SPEED_LIMIT] = limit }
    }

    suspend fun setDarkMode(enabled: Boolean) {
        context.dataStore.edit { it[Keys.DARK_MODE] = enabled }
    }

    suspend fun setSoundAlerts(enabled: Boolean) {
        context.dataStore.edit { it[Keys.SOUND_ALERTS] = enabled }
    }

    suspend fun setVibrationAlerts(enabled: Boolean) {
        context.dataStore.edit { it[Keys.VIBRATION_ALERTS] = enabled }
    }
}

package com.ozge.adas.data.local

import androidx.room.*
import kotlinx.coroutines.flow.Flow
import java.time.LocalDateTime

// ═══════════════════════════════════════════
// Room Entities
// ═══════════════════════════════════════════

@Entity(tableName = "trips")
data class TripEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val startTime: String,         // ISO-8601
    val endTime: String? = null,
    val distanceKm: Double = 0.0,
    val avgSpeedKmh: Double = 0.0,
    val maxSpeedKmh: Double = 0.0,
    val drivingScore: Int = 0,
    val harshBrakingCount: Int = 0,
    val speedViolationCount: Int = 0,
    val fuelEstimateLiters: Double = 0.0
)

@Entity(
    tableName = "route_points",
    foreignKeys = [ForeignKey(
        entity = TripEntity::class,
        parentColumns = ["id"],
        childColumns = ["tripId"],
        onDelete = ForeignKey.CASCADE
    )],
    indices = [Index("tripId")]
)
data class RoutePointEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val tripId: Long,
    val latitude: Double,
    val longitude: Double,
    val speedKmh: Double,
    val timestamp: String
)

@Entity(
    tableName = "alerts",
    indices = [Index("tripId")]
)
data class AlertEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val type: String,
    val severity: String,
    val message: String,
    val timestamp: String,
    val tripId: Long? = null,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val value: Double? = null
)

// ═══════════════════════════════════════════
// DAOs
// ═══════════════════════════════════════════

@Dao
interface TripDao {
    @Query("SELECT * FROM trips ORDER BY startTime DESC")
    fun getAllTrips(): Flow<List<TripEntity>>

    @Query("SELECT * FROM trips WHERE id = :id")
    suspend fun getTripById(id: Long): TripEntity?

    @Query("SELECT * FROM trips WHERE endTime IS NULL LIMIT 1")
    fun getActiveTrip(): Flow<TripEntity?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTrip(trip: TripEntity): Long

    @Update
    suspend fun updateTrip(trip: TripEntity)

    @Query("DELETE FROM trips WHERE id = :id")
    suspend fun deleteTrip(id: Long)
}

@Dao
interface RoutePointDao {
    @Query("SELECT * FROM route_points WHERE tripId = :tripId ORDER BY timestamp ASC")
    fun getRoutePointsForTrip(tripId: Long): Flow<List<RoutePointEntity>>

    @Insert
    suspend fun insertRoutePoint(point: RoutePointEntity)

    @Insert
    suspend fun insertRoutePoints(points: List<RoutePointEntity>)
}

@Dao
interface AlertDao {
    @Query("SELECT * FROM alerts WHERE tripId = :tripId ORDER BY timestamp DESC")
    fun getAlertsForTrip(tripId: Long): Flow<List<AlertEntity>>

    @Query("SELECT * FROM alerts ORDER BY timestamp DESC LIMIT :limit")
    fun getRecentAlerts(limit: Int): Flow<List<AlertEntity>>

    @Insert
    suspend fun insertAlert(alert: AlertEntity)

    @Query("DELETE FROM alerts WHERE tripId = :tripId")
    suspend fun clearAlertsForTrip(tripId: Long)
}

// ═══════════════════════════════════════════
// Database
// ═══════════════════════════════════════════

@Database(
    entities = [TripEntity::class, RoutePointEntity::class, AlertEntity::class],
    version = 1,
    exportSchema = false
)
abstract class AdasDatabase : RoomDatabase() {
    abstract fun tripDao(): TripDao
    abstract fun routePointDao(): RoutePointDao
    abstract fun alertDao(): AlertDao

    companion object {
        const val DATABASE_NAME = "adas_database"
    }
}

package com.ozge.adas.data.remote

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import com.ozge.adas.domain.model.ConnectionState
import com.ozge.adas.domain.model.ObdDevice
import com.ozge.adas.domain.model.VehicleData
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import java.io.InputStream
import java.io.OutputStream
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manages Bluetooth SPP connection to ELM327 OBD-II adapter.
 * Handles connection lifecycle, command execution, and data parsing.
 */
@Singleton
class ObdConnectionManager @Inject constructor() {

    companion object {
        // Standard SPP UUID for Bluetooth serial communication
        val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

        // ELM327 initialization commands
        val INIT_COMMANDS = listOf(
            "ATZ",      // Reset
            "ATE0",     // Echo off
            "ATL0",     // Linefeeds off
            "ATS0",     // Spaces off
            "ATH0",     // Headers off
            "ATSP0"     // Auto-detect protocol
        )

        // OBD-II PID commands
        const val PID_SPEED = "010D"          // Vehicle speed (km/h)
        const val PID_RPM = "010C"            // Engine RPM
        const val PID_COOLANT_TEMP = "0105"   // Engine coolant temperature
        const val PID_THROTTLE = "0111"       // Throttle position
    }

    private var socket: BluetoothSocket? = null
    private var inputStream: InputStream? = null
    private var outputStream: OutputStream? = null

    private val _connectionState = MutableStateFlow(ConnectionState.DISCONNECTED)
    val connectionState: StateFlow<ConnectionState> = _connectionState.asStateFlow()

    private val _vehicleData = MutableSharedFlow<VehicleData>(replay = 1)
    val vehicleData: SharedFlow<VehicleData> = _vehicleData.asSharedFlow()

    /**
     * Get list of paired Bluetooth devices that could be OBD-II adapters.
     */
    @SuppressLint("MissingPermission")
    fun getPairedDevices(bluetoothAdapter: BluetoothAdapter): List<ObdDevice> {
        return bluetoothAdapter.bondedDevices.map { device ->
            ObdDevice(
                name = device.name ?: "Unknown",
                address = device.address,
                isPaired = true
            )
        }
    }

    /**
     * Connect to an OBD-II adapter via Bluetooth.
     */
    @SuppressLint("MissingPermission")
    suspend fun connect(device: BluetoothDevice) = withContext(Dispatchers.IO) {
        try {
            _connectionState.value = ConnectionState.CONNECTING

            socket = device.createRfcommSocketToServiceRecord(SPP_UUID)
            socket?.connect()

            inputStream = socket?.inputStream
            outputStream = socket?.outputStream

            // Initialize ELM327
            initializeElm327()

            _connectionState.value = ConnectionState.CONNECTED
        } catch (e: Exception) {
            _connectionState.value = ConnectionState.ERROR
            disconnect()
            throw e
        }
    }

    /**
     * Send ELM327 initialization commands.
     */
    private suspend fun initializeElm327() {
        INIT_COMMANDS.forEach { cmd ->
            sendCommand(cmd)
            delay(200)
        }
    }

    /**
     * Start continuous data reading loop.
     */
    suspend fun startDataStream() = withContext(Dispatchers.IO) {
        while (_connectionState.value == ConnectionState.CONNECTED) {
            try {
                val speed = queryPid(PID_SPEED)?.let { parseSpeed(it) } ?: 0
                val rpm = queryPid(PID_RPM)?.let { parseRpm(it) } ?: 0
                val temp = queryPid(PID_COOLANT_TEMP)?.let { parseCoolantTemp(it) } ?: 0
                val throttle = queryPid(PID_THROTTLE)?.let { parseThrottle(it) } ?: 0

                _vehicleData.emit(
                    VehicleData(
                        speedKmh = speed,
                        rpm = rpm,
                        engineCoolantTemp = temp,
                        throttlePosition = throttle
                    )
                )

                delay(200) // ~5 Hz refresh rate
            } catch (e: Exception) {
                _connectionState.value = ConnectionState.RECONNECTING
                delay(1000)
            }
        }
    }

    /**
     * Send a raw OBD-II command and return the response.
     */
    private suspend fun sendCommand(command: String): String = withContext(Dispatchers.IO) {
        outputStream?.write("$command\r".toByteArray())
        outputStream?.flush()
        delay(100)
        readResponse()
    }

    private fun queryPid(pid: String): String? {
        return try {
            outputStream?.write("$pid\r".toByteArray())
            outputStream?.flush()
            Thread.sleep(100)
            readResponse().takeIf { !it.contains("NO DATA") && !it.contains("ERROR") }
        } catch (e: Exception) {
            null
        }
    }

    private fun readResponse(): String {
        val buffer = ByteArray(1024)
        val builder = StringBuilder()
        Thread.sleep(100)

        while (inputStream?.available() ?: 0 > 0) {
            val bytesRead = inputStream?.read(buffer) ?: 0
            builder.append(String(buffer, 0, bytesRead))
        }

        return builder.toString().trim().replace(">", "").trim()
    }

    // ── PID Parsers ──

    private fun parseSpeed(response: String): Int {
        // Response format: "41 0D XX" where XX is speed in hex
        val bytes = response.replace(" ", "").takeLast(2)
        return bytes.toIntOrNull(16) ?: 0
    }

    private fun parseRpm(response: String): Int {
        // Response format: "41 0C XX YY" → RPM = ((A * 256) + B) / 4
        val clean = response.replace(" ", "")
        if (clean.length < 8) return 0
        val a = clean.substring(4, 6).toIntOrNull(16) ?: 0
        val b = clean.substring(6, 8).toIntOrNull(16) ?: 0
        return ((a * 256) + b) / 4
    }

    private fun parseCoolantTemp(response: String): Int {
        // Response: "41 05 XX" → Temp = A - 40
        val bytes = response.replace(" ", "").takeLast(2)
        return (bytes.toIntOrNull(16) ?: 40) - 40
    }

    private fun parseThrottle(response: String): Int {
        // Response: "41 11 XX" → Throttle = (A * 100) / 255
        val bytes = response.replace(" ", "").takeLast(2)
        return ((bytes.toIntOrNull(16) ?: 0) * 100) / 255
    }

    /**
     * Disconnect and clean up resources.
     */
    fun disconnect() {
        try {
            inputStream?.close()
            outputStream?.close()
            socket?.close()
        } catch (_: Exception) { }

        inputStream = null
        outputStream = null
        socket = null
        _connectionState.value = ConnectionState.DISCONNECTED
    }
}

package com.ozge.adas.data.repository

import com.ozge.adas.data.local.*
import com.ozge.adas.data.remote.ObdConnectionManager
import com.ozge.adas.domain.model.*
import com.ozge.adas.domain.repository.AlertRepository
import com.ozge.adas.domain.repository.TripRepository
import com.ozge.adas.domain.repository.VehicleRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import javax.inject.Inject
import javax.inject.Singleton

// ═══════════════════════════════════════════
// Vehicle Repository Implementation
// ═══════════════════════════════════════════

@Singleton
class VehicleRepositoryImpl @Inject constructor(
    private val obdConnectionManager: ObdConnectionManager
) : VehicleRepository {

    override fun getVehicleDataStream(): Flow<VehicleData> {
        return obdConnectionManager.vehicleData
    }

    override fun getConnectionState(): Flow<ConnectionState> {
        return obdConnectionManager.connectionState
    }

    override suspend fun connect(device: ObdDevice) {
        // TODO: Get BluetoothDevice from address and call obdConnectionManager.connect()
    }

    override suspend fun disconnect() {
        obdConnectionManager.disconnect()
    }

    override fun getAvailableDevices(): Flow<List<ObdDevice>> {
        // TODO: Implement Bluetooth scanning flow
        throw NotImplementedError("Bluetooth scanning will be implemented in Week 2")
    }
}

// ═══════════════════════════════════════════
// Trip Repository Implementation
// ═══════════════════════════════════════════

@Singleton
class TripRepositoryImpl @Inject constructor(
    private val tripDao: TripDao,
    private val routePointDao: RoutePointDao
) : TripRepository {

    override fun getAllTrips(): Flow<List<Trip>> {
        return tripDao.getAllTrips().map { entities ->
            entities.map { it.toDomain() }
        }
    }

    override suspend fun getTripById(id: Long): Trip? {
        return tripDao.getTripById(id)?.toDomain()
    }

    override suspend fun startTrip(): Long {
        val entity = TripEntity(
            startTime = LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME)
        )
        return tripDao.insertTrip(entity)
    }

    override suspend fun endTrip(tripId: Long) {
        val trip = tripDao.getTripById(tripId) ?: return
        tripDao.updateTrip(
            trip.copy(endTime = LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME))
        )
    }

    override suspend fun updateTrip(trip: Trip) {
        tripDao.updateTrip(trip.toEntity())
    }

    override suspend fun deleteTrip(tripId: Long) {
        tripDao.deleteTrip(tripId)
    }

    override fun getActiveTrip(): Flow<Trip?> {
        return tripDao.getActiveTrip().map { it?.toDomain() }
    }
}

// ═══════════════════════════════════════════
// Alert Repository Implementation
// ═══════════════════════════════════════════

@Singleton
class AlertRepositoryImpl @Inject constructor(
    private val alertDao: AlertDao
) : AlertRepository {

    override fun getAlertsForTrip(tripId: Long): Flow<List<Alert>> {
        return alertDao.getAlertsForTrip(tripId).map { entities ->
            entities.map { it.toDomain() }
        }
    }

    override fun getRecentAlerts(limit: Int): Flow<List<Alert>> {
        return alertDao.getRecentAlerts(limit).map { entities ->
            entities.map { it.toDomain() }
        }
    }

    override suspend fun saveAlert(alert: Alert) {
        alertDao.insertAlert(alert.toEntity())
    }

    override suspend fun clearAlerts(tripId: Long) {
        alertDao.clearAlertsForTrip(tripId)
    }
}

// ═══════════════════════════════════════════
// Entity ↔ Domain Mappers
// ═══════════════════════════════════════════

private fun TripEntity.toDomain(): Trip {
    return Trip(
        id = id,
        startTime = LocalDateTime.parse(startTime),
        endTime = endTime?.let { LocalDateTime.parse(it) },
        distanceKm = distanceKm,
        avgSpeedKmh = avgSpeedKmh,
        maxSpeedKmh = maxSpeedKmh,
        drivingScore = drivingScore,
        harshBrakingCount = harshBrakingCount,
        speedViolationCount = speedViolationCount,
        fuelEstimateLiters = fuelEstimateLiters
    )
}

private fun Trip.toEntity(): TripEntity {
    return TripEntity(
        id = id,
        startTime = startTime.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME),
        endTime = endTime?.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME),
        distanceKm = distanceKm,
        avgSpeedKmh = avgSpeedKmh,
        maxSpeedKmh = maxSpeedKmh,
        drivingScore = drivingScore,
        harshBrakingCount = harshBrakingCount,
        speedViolationCount = speedViolationCount,
        fuelEstimateLiters = fuelEstimateLiters
    )
}

private fun AlertEntity.toDomain(): Alert {
    return Alert(
        id = id,
        type = AlertType.valueOf(type),
        severity = AlertSeverity.valueOf(severity),
        message = message,
        timestamp = LocalDateTime.parse(timestamp),
        tripId = tripId,
        latitude = latitude,
        longitude = longitude,
        value = value
    )
}

private fun Alert.toEntity(): AlertEntity {
    return AlertEntity(
        id = id,
        type = type.name,
        severity = severity.name,
        message = message,
        timestamp = timestamp.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME),
        tripId = tripId,
        latitude = latitude,
        longitude = longitude,
        value = value
    )
}

package com.ozge.adas.data.sensor

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.sqrt

/**
 * Reads accelerometer and gyroscope data from phone sensors.
 * Used for harsh braking detection and sensor fusion.
 */
@Singleton
class SensorReader @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager

    data class AccelerometerData(
        val x: Float,
        val y: Float,
        val z: Float,
        val timestamp: Long
    ) {
        /** Total acceleration magnitude (m/s²) */
        val magnitude: Float get() = sqrt(x * x + y * y + z * z)

        /** G-force (1g ≈ 9.81 m/s²) */
        val gForce: Float get() = magnitude / 9.81f
    }

    data class GyroscopeData(
        val x: Float, // rotation rate around X axis (rad/s)
        val y: Float,
        val z: Float,
        val timestamp: Long
    )

    /**
     * Stream accelerometer data as a Flow.
     * Used for braking and acceleration detection.
     */
    fun getAccelerometerStream(): Flow<AccelerometerData> = callbackFlow {
        val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_LINEAR_ACCELERATION)

        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                trySend(
                    AccelerometerData(
                        x = event.values[0],
                        y = event.values[1],
                        z = event.values[2],
                        timestamp = System.currentTimeMillis()
                    )
                )
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }

        accelerometer?.let {
            sensorManager.registerListener(
                listener,
                it,
                SensorManager.SENSOR_DELAY_GAME // ~50Hz
            )
        }

        awaitClose {
            sensorManager.unregisterListener(listener)
        }
    }

    /**
     * Stream gyroscope data as a Flow.
     * Used for turn detection.
     */
    fun getGyroscopeStream(): Flow<GyroscopeData> = callbackFlow {
        val gyroscope = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE)

        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                trySend(
                    GyroscopeData(
                        x = event.values[0],
                        y = event.values[1],
                        z = event.values[2],
                        timestamp = System.currentTimeMillis()
                    )
                )
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }

        gyroscope?.let {
            sensorManager.registerListener(
                listener,
                it,
                SensorManager.SENSOR_DELAY_GAME
            )
        }

        awaitClose {
            sensorManager.unregisterListener(listener)
        }
    }

    /**
     * Check if required sensors are available on this device.
     */
    fun hasAccelerometer(): Boolean =
        sensorManager.getDefaultSensor(Sensor.TYPE_LINEAR_ACCELERATION) != null

    fun hasGyroscope(): Boolean =
        sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE) != null
}

package com.ozge.adas.data.sensor

import com.ozge.adas.domain.model.VehicleData
import kotlinx.coroutines.flow.*
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.abs

/**
 * Fuses OBD-II vehicle data with phone sensor data for enhanced accuracy.
 *
 * Sensor fusion priorities:
 * - Speed: OBD-II primary, GPS as fallback/validation
 * - Braking: Accelerometer primary (faster response), OBD-II speed delta as confirmation
 * - Turn detection: Gyroscope primary
 */
@Singleton
class SensorFusionEngine @Inject constructor(
    private val sensorReader: SensorReader
) {
    data class FusedData(
        val speedKmh: Int,
        val rpm: Int,
        val engineTemp: Int,
        val throttle: Int,
        val longitudinalG: Float,    // braking/acceleration g-force
        val lateralG: Float,          // turning g-force
        val isHarshBraking: Boolean,
        val isHarshAcceleration: Boolean,
        val isSharpTurn: Boolean,
        val dataSource: DataSource,
        val timestamp: Long
    )

    enum class DataSource {
        OBD_ONLY,           // Only OBD-II data available
        SENSOR_ONLY,        // Only phone sensors (OBD disconnected)
        FUSED               // Both sources combined
    }

    companion object {
        const val HARSH_BRAKING_G = 0.42f       // ~4.1 m/s²
        const val HARSH_ACCEL_G = 0.35f          // ~3.4 m/s²
        const val SHARP_TURN_RAD_PER_SEC = 0.5f  // gyroscope threshold
        const val SPEED_DISCREPANCY_THRESHOLD = 10 // km/h difference triggers fallback
    }

    /**
     * Combine OBD-II data stream with accelerometer data.
     * Returns fused data with enhanced braking/acceleration detection.
     */
    fun fuse(
        obdDataStream: Flow<VehicleData>,
        gpsSpeedKmh: Flow<Int>? = null
    ): Flow<FusedData> {
        val accelStream = sensorReader.getAccelerometerStream()

        return combine(obdDataStream, accelStream) { obd, accel ->
            // Longitudinal acceleration (forward/backward axis)
            // Phone Y-axis typically aligns with vehicle forward direction
            val longitudinalG = accel.y / 9.81f
            val lateralG = accel.x / 9.81f

            val isHarshBraking = longitudinalG < -HARSH_BRAKING_G
            val isHarshAcceleration = longitudinalG > HARSH_ACCEL_G

            FusedData(
                speedKmh = obd.speedKmh,
                rpm = obd.rpm,
                engineTemp = obd.engineCoolantTemp,
                throttle = obd.throttlePosition,
                longitudinalG = longitudinalG,
                lateralG = lateralG,
                isHarshBraking = isHarshBraking,
                isHarshAcceleration = isHarshAcceleration,
                isSharpTurn = abs(lateralG) > SHARP_TURN_RAD_PER_SEC,
                dataSource = DataSource.FUSED,
                timestamp = System.currentTimeMillis()
            )
        }
    }

    /**
     * Create fused data from OBD-II data only (when sensors unavailable).
     */
    fun fromObdOnly(obdData: VehicleData): FusedData {
        return FusedData(
            speedKmh = obdData.speedKmh,
            rpm = obdData.rpm,
            engineTemp = obdData.engineCoolantTemp,
            throttle = obdData.throttlePosition,
            longitudinalG = 0f,
            lateralG = 0f,
            isHarshBraking = false,
            isHarshAcceleration = false,
            isSharpTurn = false,
            dataSource = DataSource.OBD_ONLY,
            timestamp = obdData.timestamp
        )
    }
}

package com.ozge.adas

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

/**
 * Application class for Retrofit ADAS.
 * Annotated with @HiltAndroidApp to trigger Hilt's code generation
 * and serve as the application-level dependency container.
 */
@HiltAndroidApp
class AdasApplication : Application()

package com.ozge.adas.presentation.connection

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.ozge.adas.domain.model.ConnectionState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ConnectionScreen(
    onNavigateBack: () -> Unit,
    viewModel: ConnectionViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Araç Bağlantısı") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Geri")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
        ) {
            // Connection Status
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = when (uiState.connectionState) {
                        ConnectionState.CONNECTED -> Color(0xFF2E7D32).copy(alpha = 0.1f)
                        ConnectionState.CONNECTING -> Color(0xFFEF6C00).copy(alpha = 0.1f)
                        ConnectionState.ERROR -> Color(0xFFC62828).copy(alpha = 0.1f)
                        else -> MaterialTheme.colorScheme.surfaceVariant
                    }
                )
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(20.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = when (uiState.connectionState) {
                            ConnectionState.CONNECTED -> Icons.Filled.BluetoothConnected
                            ConnectionState.CONNECTING -> Icons.Filled.BluetoothSearching
                            else -> Icons.Filled.BluetoothDisabled
                        },
                        contentDescription = null,
                        tint = when (uiState.connectionState) {
                            ConnectionState.CONNECTED -> Color(0xFF2E7D32)
                            ConnectionState.CONNECTING -> Color(0xFFEF6C00)
                            ConnectionState.ERROR -> Color(0xFFC62828)
                            else -> Color.Gray
                        },
                        modifier = Modifier.size(40.dp)
                    )
                    Spacer(modifier = Modifier.width(16.dp))
                    Column {
                        Text(
                            text = when (uiState.connectionState) {
                                ConnectionState.CONNECTED -> "Bağlı"
                                ConnectionState.CONNECTING -> "Bağlanıyor..."
                                ConnectionState.RECONNECTING -> "Yeniden bağlanıyor..."
                                ConnectionState.ERROR -> "Bağlantı Hatası"
                                ConnectionState.DISCONNECTED -> "Bağlı Değil"
                            },
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = uiState.connectedDeviceName ?: "OBD-II adaptörü seçin",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }

            // Error message
            uiState.errorMessage?.let { error ->
                Spacer(modifier = Modifier.height(8.dp))
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFFC62828).copy(alpha = 0.1f))
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Filled.Error, contentDescription = null, tint = Color(0xFFC62828))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(error, color = Color(0xFFC62828), style = MaterialTheme.typography.bodySmall)
                        Spacer(modifier = Modifier.weight(1f))
                        IconButton(onClick = { viewModel.clearError() }) {
                            Icon(Icons.Filled.Close, contentDescription = "Kapat", modifier = Modifier.size(16.dp))
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Refresh button
            OutlinedButton(
                onClick = { viewModel.loadPairedDevices() },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            ) {
                Icon(Icons.Filled.Refresh, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Cihaz Listesini Yenile")
            }

            // Disconnect button
            if (uiState.connectionState == ConnectionState.CONNECTED) {
                Spacer(modifier = Modifier.height(8.dp))
                Button(
                    onClick = { viewModel.disconnect() },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFC62828))
                ) {
                    Icon(Icons.Filled.BluetoothDisabled, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Bağlantıyı Kes")
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Paired devices
            Text(
                text = "Eşleşmiş Cihazlar (${uiState.pairedDevices.size})",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(bottom = 8.dp)
            )

            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.weight(1f)
            ) {
                items(uiState.pairedDevices) { device ->
                    Card(
                        onClick = { viewModel.connectToDevice(device) },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        enabled = uiState.connectionState != ConnectionState.CONNECTING
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth().padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Filled.Bluetooth,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = device.name,
                                    style = MaterialTheme.typography.bodyLarge,
                                    fontWeight = FontWeight.Medium
                                )
                                Text(
                                    text = device.address,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            if (uiState.connectedDeviceName == device.name &&
                                uiState.connectionState == ConnectionState.CONNECTED
                            ) {
                                Icon(Icons.Filled.CheckCircle, contentDescription = "Bağlı", tint = Color(0xFF2E7D32))
                            }
                            if (uiState.connectionState == ConnectionState.CONNECTING) {
                                CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                            }
                        }
                    }
                }
            }

            // Setup instructions
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                )
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Kurulum Adımları", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("1. ELM327 adaptörünü aracın OBD-II portuna takın")
                    Text("2. Kontağı açın")
                    Text("3. Telefon Bluetooth ayarlarından adaptörü eşleştirin (PIN: 1234)")
                    Text("4. Yukarıdaki listeden cihazı seçin")
                }
            }
        }
    }
}

package com.ozge.adas.presentation.connection

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ozge.adas.data.remote.ObdConnectionManager
import com.ozge.adas.domain.model.ConnectionState
import com.ozge.adas.domain.model.ObdDevice
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ConnectionUiState(
    val pairedDevices: List<ObdDevice> = emptyList(),
    val connectionState: ConnectionState = ConnectionState.DISCONNECTED,
    val connectedDeviceName: String? = null,
    val isScanning: Boolean = false,
    val errorMessage: String? = null
)

@HiltViewModel
class ConnectionViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    private val obdConnectionManager: ObdConnectionManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(ConnectionUiState())
    val uiState: StateFlow<ConnectionUiState> = _uiState.asStateFlow()

    private val bluetoothAdapter: BluetoothAdapter? by lazy {
        val manager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        manager?.adapter
    }

    init {
        observeConnectionState()
        loadPairedDevices()
    }

    private fun observeConnectionState() {
        viewModelScope.launch {
            obdConnectionManager.connectionState.collect { state ->
                _uiState.update { it.copy(connectionState = state) }
            }
        }
    }

    fun loadPairedDevices() {
        try {
            val adapter = bluetoothAdapter ?: run {
                _uiState.update { it.copy(errorMessage = "Bluetooth desteklenmiyor") }
                return
            }
            val devices = obdConnectionManager.getPairedDevices(adapter)
            _uiState.update { it.copy(pairedDevices = devices, errorMessage = null) }
        } catch (e: SecurityException) {
            _uiState.update { it.copy(errorMessage = "Bluetooth izni gerekli") }
        }
    }

    fun connectToDevice(device: ObdDevice) {
        viewModelScope.launch {
            try {
                val adapter = bluetoothAdapter ?: return@launch
                val btDevice = adapter.getRemoteDevice(device.address)
                obdConnectionManager.connect(btDevice)
                _uiState.update {
                    it.copy(connectedDeviceName = device.name, errorMessage = null)
                }
                // Start data stream after connection
                obdConnectionManager.startDataStream()
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(errorMessage = "Bağlantı hatası: ${e.message}")
                }
            }
        }
    }

    fun disconnect() {
        obdConnectionManager.disconnect()
        _uiState.update { it.copy(connectedDeviceName = null) }
    }

    fun clearError() {
        _uiState.update { it.copy(errorMessage = null) }
    }
}

package com.ozge.adas.presentation.trips

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TripDetailScreen(
    tripId: Long,
    onNavigateBack: () -> Unit,
    viewModel: TripDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(tripId) {
        viewModel.loadTrip(tripId)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Seyahat Detayı") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Geri")
                    }
                },
                actions = {
                    IconButton(onClick = { viewModel.deleteTrip(tripId, onNavigateBack) }) {
                        Icon(Icons.Filled.Delete, contentDescription = "Sil", tint = Color(0xFFC62828))
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
                .verticalScroll(rememberScrollState())
        ) {
            // Driving Score Circle
            Box(
                modifier = Modifier.fillMaxWidth().padding(vertical = 16.dp),
                contentAlignment = Alignment.Center
            ) {
                ScoreCircle(score = uiState.drivingScore)
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Trip Summary Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Text("Seyahat Özeti", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(16.dp))

                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                        StatItem(icon = Icons.Filled.Timer, label = "Süre", value = uiState.duration)
                        StatItem(icon = Icons.Filled.Straighten, label = "Mesafe", value = uiState.distance)
                    }
                    Spacer(modifier = Modifier.height(12.dp))
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                        StatItem(icon = Icons.Filled.Speed, label = "Ort. Hız", value = "${uiState.avgSpeed} km/h")
                        StatItem(icon = Icons.Filled.Speed, label = "Maks. Hız", value = "${uiState.maxSpeed} km/h")
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Score Breakdown
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Text("Skor Dağılımı", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(16.dp))

                    ScoreBar(label = "Hız Uyumu", score = uiState.speedComplianceScore, weight = "30%")
                    ScoreBar(label = "Fren Yumuşaklığı", score = uiState.brakingScore, weight = "25%")
                    ScoreBar(label = "Hızlanma", score = uiState.accelerationScore, weight = "20%")
                    ScoreBar(label = "Sürüş Süresi", score = uiState.durationScore, weight = "15%")
                    ScoreBar(label = "Yakıt Verimliliği", score = uiState.fuelScore, weight = "10%")
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Events Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Text("Olaylar", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(12.dp))

                    EventRow(
                        icon = Icons.Filled.Warning,
                        label = "Hız İhlali",
                        count = uiState.speedViolations,
                        color = Color(0xFFEF6C00)
                    )
                    EventRow(
                        icon = Icons.Filled.RemoveCircle,
                        label = "Sert Fren",
                        count = uiState.harshBrakingCount,
                        color = Color(0xFFC62828)
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Date info
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Başlangıç: ${uiState.startTime}", style = MaterialTheme.typography.bodyMedium)
                    Text("Bitiş: ${uiState.endTime}", style = MaterialTheme.typography.bodyMedium)
                }
            }
        }
    }
}

@Composable
fun ScoreCircle(score: Int) {
    val color = when {
        score >= 80 -> Color(0xFF2E7D32)
        score >= 60 -> Color(0xFFEF6C00)
        else -> Color(0xFFC62828)
    }
    Box(modifier = Modifier.size(140.dp), contentAlignment = Alignment.Center) {
        Canvas(modifier = Modifier.fillMaxSize().padding(8.dp)) {
            drawArc(
                color = Color(0xFFE0E0E0), startAngle = -90f, sweepAngle = 360f,
                useCenter = false, style = Stroke(width = 12.dp.toPx(), cap = StrokeCap.Round)
            )
            drawArc(
                color = color, startAngle = -90f, sweepAngle = 360f * score / 100f,
                useCenter = false, style = Stroke(width = 12.dp.toPx(), cap = StrokeCap.Round)
            )
        }
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(text = score.toString(), fontSize = 36.sp, fontWeight = FontWeight.Bold, color = color)
            Text(text = "/ 100", fontSize = 14.sp, color = Color.Gray)
        }
    }
}

@Composable
fun StatItem(icon: androidx.compose.ui.graphics.vector.ImageVector, label: String, value: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(24.dp))
        Spacer(modifier = Modifier.height(4.dp))
        Text(value, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        Text(label, style = MaterialTheme.typography.labelSmall, color = Color.Gray)
    }
}

@Composable
fun ScoreBar(label: String, score: Int, weight: String) {
    val color = when {
        score >= 80 -> Color(0xFF2E7D32)
        score >= 60 -> Color(0xFFEF6C00)
        else -> Color(0xFFC62828)
    }
    Column(modifier = Modifier.padding(vertical = 4.dp)) {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text("$label ($weight)", style = MaterialTheme.typography.bodySmall)
            Text("$score", style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.Bold, color = color)
        }
        Spacer(modifier = Modifier.height(4.dp))
        LinearProgressIndicator(
            progress = { score / 100f },
            modifier = Modifier.fillMaxWidth().height(8.dp),
            color = color,
            trackColor = Color(0xFFE0E0E0),
            strokeCap = StrokeCap.Round,
        )
    }
}

@Composable
fun EventRow(icon: androidx.compose.ui.graphics.vector.ImageVector, label: String, count: Int, color: Color) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(20.dp))
        Spacer(modifier = Modifier.width(8.dp))
        Text(label, style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(1f))
        Text("$count", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = color)
    }
}

package com.ozge.adas.presentation.trips

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ozge.adas.domain.model.Trip
import com.ozge.adas.domain.repository.TripRepository
import com.ozge.adas.util.formatDuration
import com.ozge.adas.util.toDisplayString
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class TripHistoryViewModel @Inject constructor(
    private val tripRepository: TripRepository
) : ViewModel() {

    val trips: StateFlow<List<TripPreview>> = tripRepository.getAllTrips()
        .map { tripList ->
            tripList.map { trip ->
                TripPreview(
                    id = trip.id,
                    date = trip.startTime.toDisplayString(),
                    duration = trip.durationMinutes.formatDuration(),
                    distance = String.format("%.1f km", trip.distanceKm),
                    score = trip.drivingScore
                )
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
}

package com.ozge.adas.presentation.trips

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ozge.adas.domain.repository.AlertRepository
import com.ozge.adas.domain.repository.TripRepository
import com.ozge.adas.util.formatDuration
import com.ozge.adas.util.toDisplayString
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class TripDetailUiState(
    val drivingScore: Int = 0,
    val duration: String = "-",
    val distance: String = "-",
    val avgSpeed: String = "-",
    val maxSpeed: String = "-",
    val startTime: String = "-",
    val endTime: String = "-",
    val speedViolations: Int = 0,
    val harshBrakingCount: Int = 0,
    val speedComplianceScore: Int = 0,
    val brakingScore: Int = 0,
    val accelerationScore: Int = 0,
    val durationScore: Int = 0,
    val fuelScore: Int = 0
)

@HiltViewModel
class TripDetailViewModel @Inject constructor(
    private val tripRepository: TripRepository,
    private val alertRepository: AlertRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(TripDetailUiState())
    val uiState: StateFlow<TripDetailUiState> = _uiState.asStateFlow()

    fun loadTrip(tripId: Long) {
        viewModelScope.launch {
            val trip = tripRepository.getTripById(tripId) ?: return@launch
            _uiState.update {
                it.copy(
                    drivingScore = trip.drivingScore,
                    duration = trip.durationMinutes.formatDuration(),
                    distance = String.format("%.1f km", trip.distanceKm),
                    avgSpeed = String.format("%.0f", trip.avgSpeedKmh),
                    maxSpeed = String.format("%.0f", trip.maxSpeedKmh),
                    startTime = trip.startTime.toDisplayString(),
                    endTime = trip.endTime?.toDisplayString() ?: "Devam ediyor",
                    speedViolations = trip.speedViolationCount,
                    harshBrakingCount = trip.harshBrakingCount,
                    // Score breakdown (estimated from trip data)
                    speedComplianceScore = if (trip.drivingScore > 0) (trip.drivingScore * 1.1).toInt().coerceIn(0, 100) else 0,
                    brakingScore = when { trip.harshBrakingCount == 0 -> 100; trip.harshBrakingCount <= 2 -> 80; else -> 50 },
                    accelerationScore = 75,
                    durationScore = when { trip.durationMinutes <= 90 -> 100; trip.durationMinutes <= 120 -> 80; else -> 50 },
                    fuelScore = 70
                )
            }
        }
    }

    fun deleteTrip(tripId: Long, onDeleted: () -> Unit) {
        viewModelScope.launch {
            tripRepository.deleteTrip(tripId)
            onDeleted()
        }
    }
}

package com.ozge.adas.presentation.trips

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TripHistoryScreen(
    onNavigateBack: () -> Unit,
    onTripClick: (Long) -> Unit,
    viewModel: TripHistoryViewModel = hiltViewModel()
) {
    val trips by viewModel.trips.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Seyahat Geçmişi") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Geri")
                    }
                }
            )
        }
    ) { padding ->
        if (trips.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(Icons.Filled.Route, contentDescription = null, modifier = Modifier.size(64.dp), tint = Color.Gray)
                    Spacer(modifier = Modifier.height(16.dp))
                    Text("Henüz seyahat kaydı yok", style = MaterialTheme.typography.bodyLarge, color = Color.Gray)
                    Text("Araca bağlanıp sürüşe başlayın", style = MaterialTheme.typography.bodyMedium, color = Color.Gray)
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(padding).padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
                contentPadding = PaddingValues(vertical = 16.dp)
            ) {
                items(trips) { trip ->
                    TripCard(trip = trip, onClick = { onTripClick(trip.id) })
                }
            }
        }
    }
}

@Composable
fun TripCard(trip: TripPreview, onClick: () -> Unit) {
    val scoreColor = when {
        trip.score >= 80 -> Color(0xFF2E7D32)
        trip.score >= 60 -> Color(0xFFEF6C00)
        else -> Color(0xFFC62828)
    }
    Card(onClick = onClick, modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp)) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                modifier = Modifier.size(48.dp),
                shape = RoundedCornerShape(12.dp),
                color = scoreColor.copy(alpha = 0.1f)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Text(trip.score.toString(), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = scoreColor)
                }
            }
            Spacer(modifier = Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(trip.date, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium)
                Row {
                    Text(trip.duration, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text(" • ", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text(trip.distance, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            Icon(Icons.Filled.ChevronRight, contentDescription = null, tint = Color.Gray)
        }
    }
}

data class TripPreview(val id: Long, val date: String, val duration: String, val distance: String, val score: Int)

package com.ozge.adas.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.ozge.adas.presentation.connection.ConnectionScreen
import com.ozge.adas.presentation.dashboard.DashboardScreen
import com.ozge.adas.presentation.profile.ProfileScreen
import com.ozge.adas.presentation.settings.SettingsScreen
import com.ozge.adas.presentation.trips.TripDetailScreen
import com.ozge.adas.presentation.trips.TripHistoryScreen

object AdasRoutes {
    const val DASHBOARD = "dashboard"
    const val CONNECTION = "connection"
    const val TRIPS = "trips"
    const val TRIP_DETAIL = "trips/{tripId}"
    const val SETTINGS = "settings"
    const val PROFILE = "profile"

    fun tripDetail(tripId: Long) = "trips/$tripId"
}

@Composable
fun AdasNavHost(modifier: Modifier = Modifier) {
    val navController = rememberNavController()

    NavHost(
        navController = navController,
        startDestination = AdasRoutes.DASHBOARD,
        modifier = modifier
    ) {
        composable(AdasRoutes.DASHBOARD) {
            DashboardScreen(
                onNavigateToConnection = { navController.navigate(AdasRoutes.CONNECTION) },
                onNavigateToTrips = { navController.navigate(AdasRoutes.TRIPS) },
                onNavigateToSettings = { navController.navigate(AdasRoutes.SETTINGS) },
                onNavigateToProfile = { navController.navigate(AdasRoutes.PROFILE) }
            )
        }

        composable(AdasRoutes.CONNECTION) {
            ConnectionScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(AdasRoutes.TRIPS) {
            TripHistoryScreen(
                onNavigateBack = { navController.popBackStack() },
                onTripClick = { tripId ->
                    navController.navigate(AdasRoutes.tripDetail(tripId))
                }
            )
        }

        composable(
            route = AdasRoutes.TRIP_DETAIL,
            arguments = listOf(navArgument("tripId") { type = NavType.LongType })
        ) { backStackEntry ->
            val tripId = backStackEntry.arguments?.getLong("tripId") ?: return@composable
            TripDetailScreen(
                tripId = tripId,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(AdasRoutes.SETTINGS) {
            SettingsScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(AdasRoutes.PROFILE) {
            ProfileScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }
    }
}

package com.ozge.adas.presentation.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Circular speed gauge component with animated arc.
 * Shows current speed with color-coded status based on speed limit.
 */
@Composable
fun SpeedGaugeArc(
    currentSpeed: Int,
    maxSpeed: Int = 220,
    speedLimit: Int = 120,
    modifier: Modifier = Modifier
) {
    val progress = (currentSpeed.toFloat() / maxSpeed).coerceIn(0f, 1f)
    val sweepAngle = 240f * progress // 240° arc

    val arcColor = when {
        currentSpeed > speedLimit + 20 -> Color(0xFFC62828)  // Critical
        currentSpeed > speedLimit -> Color(0xFFEF6C00)        // Warning
        else -> Color(0xFF1565C0)                              // Normal
    }
    val trackColor = Color(0xFFE0E0E0)

    Box(modifier = modifier.size(220.dp), contentAlignment = Alignment.Center) {
        Canvas(modifier = Modifier.fillMaxSize().padding(16.dp)) {
            val strokeWidth = 16.dp.toPx()
            val arcSize = Size(size.width - strokeWidth, size.height - strokeWidth)
            val topLeft = Offset(strokeWidth / 2, strokeWidth / 2)

            // Background track
            drawArc(
                color = trackColor,
                startAngle = 150f,
                sweepAngle = 240f,
                useCenter = false,
                topLeft = topLeft,
                size = arcSize,
                style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
            )

            // Progress arc
            drawArc(
                color = arcColor,
                startAngle = 150f,
                sweepAngle = sweepAngle,
                useCenter = false,
                topLeft = topLeft,
                size = arcSize,
                style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
            )
        }

        // Center text
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = currentSpeed.toString(),
                fontSize = 56.sp,
                fontWeight = FontWeight.Bold,
                color = arcColor
            )
            Text(
                text = "km/h",
                fontSize = 14.sp,
                color = arcColor.copy(alpha = 0.7f)
            )
            if (currentSpeed > speedLimit) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "Limit: $speedLimit",
                    fontSize = 11.sp,
                    color = Color(0xFFC62828),
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

/**
 * Simple info chip for displaying a label-value pair.
 */
@Composable
fun InfoChip(
    label: String,
    value: String,
    modifier: Modifier = Modifier,
    valueColor: Color = MaterialTheme.colorScheme.onSurface
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(2.dp))
        Text(
            text = value,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = valueColor
        )
    }
}

package com.ozge.adas.presentation.profile

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(
    onNavigateBack: () -> Unit,
    viewModel: ProfileViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Profil") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Geri")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Profile avatar
            Surface(
                modifier = Modifier.size(80.dp),
                shape = CircleShape,
                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        Icons.Filled.Person,
                        contentDescription = null,
                        modifier = Modifier.size(48.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))
            Text("Sürücü", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)

            Spacer(modifier = Modifier.height(24.dp))

            // Overall stats
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Text("Genel İstatistikler", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(16.dp))

                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                        ProfileStat(value = "${uiState.totalTrips}", label = "Seyahat")
                        ProfileStat(value = "${String.format("%.0f", uiState.totalDistanceKm)} km", label = "Mesafe")
                        ProfileStat(value = "${uiState.totalDrivingHours}s", label = "Süre")
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Average driving score
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(20.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text("Ortalama Sürüş Skoru", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                        Text("Son ${uiState.totalTrips} seyahate göre", style = MaterialTheme.typography.bodySmall, color = Color.Gray)
                    }

                    val scoreColor = when {
                        uiState.avgScore >= 80 -> Color(0xFF2E7D32)
                        uiState.avgScore >= 60 -> Color(0xFFEF6C00)
                        else -> Color(0xFFC62828)
                    }

                    Surface(
                        modifier = Modifier.size(64.dp),
                        shape = CircleShape,
                        color = scoreColor.copy(alpha = 0.1f)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Text(
                                "${uiState.avgScore}",
                                fontSize = 24.sp,
                                fontWeight = FontWeight.Bold,
                                color = scoreColor
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Safety summary
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Text("Güvenlik Özeti", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(12.dp))

                    SafetyRow(
                        icon = Icons.Filled.Speed,
                        label = "Toplam Hız İhlali",
                        value = "${uiState.totalSpeedViolations}",
                        color = Color(0xFFEF6C00)
                    )
                    SafetyRow(
                        icon = Icons.Filled.Warning,
                        label = "Toplam Sert Fren",
                        value = "${uiState.totalHarshBraking}",
                        color = Color(0xFFC62828)
                    )
                    SafetyRow(
                        icon = Icons.Filled.TrendingUp,
                        label = "En Yüksek Hız",
                        value = "${uiState.topSpeedKmh} km/h",
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
        }
    }
}

@Composable
fun ProfileStat(value: String, label: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
        Text(label, style = MaterialTheme.typography.labelSmall, color = Color.Gray)
    }
}

@Composable
fun SafetyRow(icon: androidx.compose.ui.graphics.vector.ImageVector, label: String, value: String, color: Color) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(20.dp))
        Spacer(modifier = Modifier.width(8.dp))
        Text(label, style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(1f))
        Text(value, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
    }
}

package com.ozge.adas.presentation.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ozge.adas.domain.repository.TripRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import javax.inject.Inject

data class ProfileUiState(
    val totalTrips: Int = 0,
    val totalDistanceKm: Double = 0.0,
    val totalDrivingHours: Int = 0,
    val avgScore: Int = 0,
    val totalSpeedViolations: Int = 0,
    val totalHarshBraking: Int = 0,
    val topSpeedKmh: Int = 0
)

@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val tripRepository: TripRepository
) : ViewModel() {

    val uiState: StateFlow<ProfileUiState> = tripRepository.getAllTrips()
        .map { trips ->
            if (trips.isEmpty()) return@map ProfileUiState()

            ProfileUiState(
                totalTrips = trips.size,
                totalDistanceKm = trips.sumOf { it.distanceKm },
                totalDrivingHours = (trips.sumOf { it.durationMinutes } / 60).toInt(),
                avgScore = if (trips.isNotEmpty()) trips.map { it.drivingScore }.average().toInt() else 0,
                totalSpeedViolations = trips.sumOf { it.speedViolationCount },
                totalHarshBraking = trips.sumOf { it.harshBrakingCount },
                topSpeedKmh = trips.maxOfOrNull { it.maxSpeedKmh.toInt() } ?: 0
            )
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), ProfileUiState())
}

package com.ozge.adas.presentation.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ozge.adas.data.local.UserPreferences
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SettingsUiState(
    val speedLimit: Int = 120,
    val darkMode: Boolean = false,
    val soundAlerts: Boolean = true,
    val vibrationAlerts: Boolean = true
)

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val userPreferences: UserPreferences
) : ViewModel() {

    val uiState: StateFlow<SettingsUiState> = combine(
        userPreferences.speedLimit,
        userPreferences.darkMode,
        userPreferences.soundAlerts,
        userPreferences.vibrationAlerts
    ) { speed, dark, sound, vibration ->
        SettingsUiState(
            speedLimit = speed,
            darkMode = dark,
            soundAlerts = sound,
            vibrationAlerts = vibration
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), SettingsUiState())

    fun setSpeedLimit(limit: Int) {
        viewModelScope.launch { userPreferences.setSpeedLimit(limit) }
    }

    fun setDarkMode(enabled: Boolean) {
        viewModelScope.launch { userPreferences.setDarkMode(enabled) }
    }

    fun setSoundAlerts(enabled: Boolean) {
        viewModelScope.launch { userPreferences.setSoundAlerts(enabled) }
    }

    fun setVibrationAlerts(enabled: Boolean) {
        viewModelScope.launch { userPreferences.setVibrationAlerts(enabled) }
    }
}

package com.ozge.adas.presentation.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onNavigateBack: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Ayarlar") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Geri")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier.fillMaxSize().padding(padding).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Speed Limit
            Text("Uyarı Ayarları", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            Card(shape = RoundedCornerShape(12.dp)) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Hız Limiti: ${uiState.speedLimit} km/h", style = MaterialTheme.typography.bodyLarge)
                    Slider(
                        value = uiState.speedLimit.toFloat(),
                        onValueChange = { viewModel.setSpeedLimit(it.toInt()) },
                        valueRange = 50f..200f,
                        steps = 29
                    )
                }
            }

            // Alert Settings
            Card(shape = RoundedCornerShape(12.dp)) {
                Column {
                    SettingsToggle("Sesli Uyarılar", "Hız aşımında sesli bildirim", uiState.soundAlerts) { viewModel.setSoundAlerts(it) }
                    HorizontalDivider()
                    SettingsToggle("Titreşim Uyarıları", "Sert fren ve hız aşımında titreşim", uiState.vibrationAlerts) { viewModel.setVibrationAlerts(it) }
                }
            }

            // Display
            Text("Görünüm", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            Card(shape = RoundedCornerShape(12.dp)) {
                SettingsToggle("Karanlık Mod", "Gece sürüşü için koyu tema", uiState.darkMode) { viewModel.setDarkMode(it) }
            }

            // About
            Text("Hakkında", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            Card(shape = RoundedCornerShape(12.dp)) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Retrofit ADAS", fontWeight = FontWeight.Bold)
                    Text("Versiyon 0.1.0", style = MaterialTheme.typography.bodySmall)
                    Spacer(modifier = Modifier.height(4.dp))
                    Text("Bitirme Tezi Projesi — Özge Zelal Küçük", style = MaterialTheme.typography.bodySmall)
                }
            }
        }
    }
}

@Composable
fun SettingsToggle(title: String, subtitle: String, checked: Boolean, onCheckedChange: (Boolean) -> Unit) {
    Row(modifier = Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
        Column(modifier = Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.bodyLarge)
            Text(subtitle, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Switch(checked = checked, onCheckedChange = onCheckedChange)
    }
}

package com.ozge.adas.presentation

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.ui.Modifier
import com.ozge.adas.presentation.navigation.AdasNavHost
import com.ozge.adas.presentation.theme.RetrofitAdasTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            RetrofitAdasTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    AdasNavHost(
                        modifier = Modifier.padding(innerPadding)
                    )
                }
            }
        }
    }
}
