package com.ozge.adas

import com.ozge.adas.domain.model.DrivingScore
import com.ozge.adas.domain.usecase.CalculateDrivingScoreUseCase
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class CalculateDrivingScoreTest {

    private lateinit var useCase: CalculateDrivingScoreUseCase

    @Before
    fun setup() {
        useCase = CalculateDrivingScoreUseCase()
    }

    @Test
    fun `perfect driving returns score of 100`() {
        val score = useCase(
            totalSpeedReadings = 100,
            speedViolations = 0,
            harshBrakingEvents = 0,
            harshAccelerationEvents = 0,
            drivingMinutes = 30,
            avgFuelConsumption = 5.0
        )

        assertEquals(100, score.overall)
        assertEquals(100, score.speedCompliance)
        assertEquals(100, score.brakingSmoothness)
    }

    @Test
    fun `many speed violations lower score significantly`() {
        val score = useCase(
            totalSpeedReadings = 100,
            speedViolations = 50,  // 50% violations
            harshBrakingEvents = 0,
            harshAccelerationEvents = 0,
            drivingMinutes = 30,
            avgFuelConsumption = 5.0
        )

        assertTrue(score.overall < 80)
        assertEquals(50, score.speedCompliance)
    }

    @Test
    fun `harsh braking events reduce braking score`() {
        val score = useCase(
            totalSpeedReadings = 100,
            speedViolations = 0,
            harshBrakingEvents = 6,
            harshAccelerationEvents = 0,
            drivingMinutes = 30,
            avgFuelConsumption = 5.0
        )

        assertEquals(30, score.brakingSmoothness)
    }

    @Test
    fun `long driving duration reduces trip management score`() {
        val score = useCase(
            totalSpeedReadings = 100,
            speedViolations = 0,
            harshBrakingEvents = 0,
            harshAccelerationEvents = 0,
            drivingMinutes = 180,  // 3 hours
            avgFuelConsumption = 5.0
        )

        assertEquals(20, score.tripDurationManagement)
    }

    @Test
    fun `score components have correct weights`() {
        // All components at 100 should give overall 100
        val perfectScore = DrivingScore.calculate(100, 100, 100, 100, 100)
        assertEquals(100, perfectScore.overall)

        // All at 0 should give 0
        val worstScore = DrivingScore.calculate(0, 0, 0, 0, 0)
        assertEquals(0, worstScore.overall)

        // Verify speed compliance has highest weight (30%)
        val speedOnly = DrivingScore.calculate(100, 0, 0, 0, 0)
        assertEquals(30, speedOnly.overall)
    }
}

package com.ozge.adas

import com.ozge.adas.domain.model.*
import com.ozge.adas.domain.usecase.MonitorFatigueUseCase
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import com.ozge.adas.domain.repository.AlertRepository
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class MonitorFatigueUseCaseTest {

    private lateinit var useCase: MonitorFatigueUseCase
    private lateinit var alertRepository: AlertRepository

    @Before
    fun setup() {
        alertRepository = mockk(relaxed = true)
        useCase = MonitorFatigueUseCase(alertRepository)
    }

    @Test
    fun `no alert for short driving duration`() = runTest {
        val alert = useCase.checkFatigue(30)
        assertNull(alert)
    }

    @Test
    fun `info alert at 90 minutes`() = runTest {
        val alert = useCase.checkFatigue(90)
        assertNotNull(alert)
        assertEquals(AlertType.FATIGUE_REMINDER, alert!!.type)
        assertEquals(AlertSeverity.INFO, alert.severity)
    }

    @Test
    fun `warning alert at 120 minutes`() = runTest {
        val alert = useCase.checkFatigue(120)
        assertNotNull(alert)
        assertEquals(AlertType.FATIGUE_WARNING, alert!!.type)
        assertEquals(AlertSeverity.WARNING, alert.severity)
    }

    @Test
    fun `critical alert at 150 minutes`() = runTest {
        val alert = useCase.checkFatigue(150)
        assertNotNull(alert)
        assertEquals(AlertType.FATIGUE_URGENT, alert!!.type)
        assertEquals(AlertSeverity.CRITICAL, alert.severity)
    }

    @Test
    fun `alert is saved to repository`() = runTest {
        useCase.checkFatigue(120)
        coVerify(exactly = 1) { alertRepository.saveAlert(any()) }
    }

    @Test
    fun `no save when no alert`() = runTest {
        useCase.checkFatigue(30)
        coVerify(exactly = 0) { alertRepository.saveAlert(any()) }
    }
}

class AlertModelTest {

    @Test
    fun `alert severity ordering`() {
        assertTrue(AlertSeverity.CRITICAL.ordinal > AlertSeverity.WARNING.ordinal)
        assertTrue(AlertSeverity.WARNING.ordinal > AlertSeverity.INFO.ordinal)
    }

    @Test
    fun `driving score calculate with mixed scores`() {
        val score = DrivingScore.calculate(
            speedCompliance = 80,
            brakingSmoothness = 60,
            accelerationPatterns = 70,
            tripDurationManagement = 90,
            fuelEfficiency = 50
        )
        // 80*0.3 + 60*0.25 + 70*0.2 + 90*0.15 + 50*0.10
        // = 24 + 15 + 14 + 13.5 + 5 = 71.5 → 71
        assertEquals(71, score.overall)
    }

    @Test
    fun `vehicle data default values`() {
        val data = VehicleData()
        assertEquals(0, data.speedKmh)
        assertEquals(0, data.rpm)
        assertEquals(0, data.engineCoolantTemp)
    }

    @Test
    fun `connection states are complete`() {
        val states = ConnectionState.values()
        assertEquals(5, states.size)
        assertTrue(states.contains(ConnectionState.DISCONNECTED))
        assertTrue(states.contains(ConnectionState.CONNECTING))
        assertTrue(states.contains(ConnectionState.CONNECTED))
        assertTrue(states.contains(ConnectionState.ERROR))
        assertTrue(states.contains(ConnectionState.RECONNECTING))
    }
}

class TripModelTest {

    @Test
    fun `trip ongoing when endTime is null`() {
        val trip = Trip(
            startTime = java.time.LocalDateTime.now().minusMinutes(30),
            endTime = null
        )
        assertTrue(trip.isOngoing)
    }

    @Test
    fun `trip completed when endTime is set`() {
        val trip = Trip(
            startTime = java.time.LocalDateTime.now().minusMinutes(60),
            endTime = java.time.LocalDateTime.now()
        )
        assertFalse(trip.isOngoing)
    }

    @Test
    fun `trip duration calculated correctly`() {
        val start = java.time.LocalDateTime.of(2026, 1, 1, 10, 0)
        val end = java.time.LocalDateTime.of(2026, 1, 1, 11, 30)
        val trip = Trip(startTime = start, endTime = end)
        assertEquals(90, trip.durationMinutes)
    }
}

package com.ozge.adas

import com.ozge.adas.domain.model.*
import com.ozge.adas.domain.repository.AlertRepository
import com.ozge.adas.domain.repository.TripRepository
import com.ozge.adas.domain.repository.VehicleRepository
import com.ozge.adas.domain.usecase.*
import com.ozge.adas.presentation.dashboard.DashboardViewModel
import io.mockk.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.*
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class DashboardViewModelTest {

    private val testDispatcher = UnconfinedTestDispatcher()

    private lateinit var vehicleRepository: VehicleRepository
    private lateinit var tripRepository: TripRepository
    private lateinit var alertRepository: AlertRepository
    private lateinit var monitorSpeedUseCase: MonitorSpeedUseCase
    private lateinit var detectHarshBrakingUseCase: DetectHarshBrakingUseCase
    private lateinit var monitorFatigueUseCase: MonitorFatigueUseCase
    private lateinit var calculateDrivingScoreUseCase: CalculateDrivingScoreUseCase

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)

        vehicleRepository = mockk(relaxed = true)
        tripRepository = mockk(relaxed = true)
        alertRepository = mockk(relaxed = true)
        monitorSpeedUseCase = mockk(relaxed = true)
        detectHarshBrakingUseCase = mockk(relaxed = true)
        monitorFatigueUseCase = mockk(relaxed = true)
        calculateDrivingScoreUseCase = CalculateDrivingScoreUseCase()

        every { vehicleRepository.getConnectionState() } returns flowOf(ConnectionState.DISCONNECTED)
        every { vehicleRepository.getVehicleDataStream() } returns flowOf(VehicleData())
        every { alertRepository.getRecentAlerts(any()) } returns flowOf(emptyList())
        every { tripRepository.getActiveTrip() } returns flowOf(null)
        every { monitorSpeedUseCase(any()) } returns flowOf(null)
        every { detectHarshBrakingUseCase() } returns flowOf(null)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private fun createViewModel() = DashboardViewModel(
        vehicleRepository, tripRepository, alertRepository,
        monitorSpeedUseCase, detectHarshBrakingUseCase,
        monitorFatigueUseCase, calculateDrivingScoreUseCase
    )

    @Test
    fun `initial state is disconnected`() {
        val vm = createViewModel()
        assertFalse(vm.uiState.value.isConnected)
        assertEquals(ConnectionState.DISCONNECTED, vm.uiState.value.connectionState)
    }

    @Test
    fun `speed limit change updates state`() {
        val vm = createViewModel()
        vm.onSpeedLimitChanged(100)
        assertEquals(100, vm.uiState.value.speedLimit)
    }

    @Test
    fun `dismiss alert clears active alert`() {
        val vm = createViewModel()
        vm.dismissAlert()
        assertNull(vm.uiState.value.activeAlert)
    }

    @Test
    fun `start trip updates state`() = runTest {
        coEvery { tripRepository.startTrip() } returns 1L
        val vm = createViewModel()
        vm.onStartTrip()
        assertTrue(vm.uiState.value.isTripActive)
        assertEquals(1L, vm.uiState.value.activeTripId)
    }

    @Test
    fun `connected state detected`() = runTest {
        every { vehicleRepository.getConnectionState() } returns flowOf(ConnectionState.CONNECTED)
        val vm = createViewModel()
        assertTrue(vm.uiState.value.isConnected)
    }

    @Test
    fun `default speed limit is 120`() {
        val vm = createViewModel()
        assertEquals(120, vm.uiState.value.speedLimit)
    }
}

<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <!-- Bluetooth Permissions -->
    <uses-permission android:name="android.permission.BLUETOOTH" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />

    <!-- Location Permissions (required for Bluetooth scanning & GPS) -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

    <!-- Foreground Service (for continuous OBD-II monitoring) -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <!-- Sensors -->
    <uses-permission android:name="android.permission.HIGH_SAMPLING_RATE_SENSORS" />

    <!-- Internet (for Google Maps) -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <!-- Vibration (for alerts) -->
    <uses-permission android:name="android.permission.VIBRATE" />

    <!-- Bluetooth feature declaration -->
    <uses-feature
        android:name="android.hardware.bluetooth"
        android:required="true" />

    <application
        android:name=".AdasApplication"
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.RetrofitADAS"
        tools:targetApi="34">

        <!-- Google Maps API Key (add your key in local.properties: MAPS_API_KEY=xxx) -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="${MAPS_API_KEY}" />

        <!-- Main Activity -->
        <activity
            android:name=".presentation.MainActivity"
            android:exported="true"
            android:theme="@style/Theme.RetrofitADAS">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- OBD-II Foreground Service -->
        <service
            android:name=".service.ObdForegroundService"
            android:foregroundServiceType="connectedDevice"
            android:exported="false" />

    </application>

</manifest>

<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <!-- Background padding for adaptive icon safe zone -->
    <group
        android:translateX="27"
        android:translateY="27">
        <!-- Simple car icon -->
        <path
            android:fillColor="#FFFFFF"
            android:pathData="M27,18.5C27,17.12 26.12,15.95 24.91,15.44L22.35,9.12C21.73,7.62 20.28,6.5 18.58,6.5L7.42,6.5C5.72,6.5 4.27,7.62 3.65,9.12L1.09,15.44C-0.12,15.95 -1,17.12 -1,18.5L-1,26.5C-1,27.33 -0.33,28 0.5,28L2.5,28C3.33,28 4,27.33 4,26.5L4,25.5L22,25.5L22,26.5C22,27.33 22.67,28 23.5,28L25.5,28C26.33,28 27,27.33 27,26.5L27,18.5ZM7.42,9.5L18.58,9.5L20.58,14.5L5.42,14.5L7.42,9.5ZM4,21.5C2.62,21.5 1.5,20.38 1.5,19C1.5,17.62 2.62,16.5 4,16.5C5.38,16.5 6.5,17.62 6.5,19C6.5,20.38 5.38,21.5 4,21.5ZM22,21.5C20.62,21.5 19.5,20.38 19.5,19C19.5,17.62 20.62,16.5 22,16.5C23.38,16.5 24.5,17.62 24.5,19C24.5,20.38 23.38,21.5 22,21.5Z"/>
        <!-- Speed lines -->
        <path
            android:fillColor="#FFFFFF"
            android:pathData="M13,34L13,38"
            android:strokeWidth="2"
            android:strokeColor="#FFFFFF"/>
        <path
            android:fillColor="#FFFFFF"
            android:pathData="M7,33L5,37"
            android:strokeWidth="1.5"
            android:strokeColor="#FFFFFF"/>
        <path
            android:fillColor="#FFFFFF"
            android:pathData="M19,33L21,37"
            android:strokeWidth="1.5"
            android:strokeColor="#FFFFFF"/>
        <!-- ADAS text -->
        <path
            android:fillColor="#FFFFFF"
            android:pathData="M4,44L22,44"
            android:strokeWidth="0"
            android:strokeColor="#FFFFFF"/>
    </group>
</vector>

<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="adas_blue">#1565C0</color>
    <color name="adas_blue_dark">#0D47A1</color>
    <color name="adas_green">#2E7D32</color>
    <color name="adas_red">#C62828</color>
    <color name="adas_orange">#EF6C00</color>
    <color name="adas_yellow">#F9A825</color>
    <color name="background_light">#F5F5F5</color>
    <color name="background_dark">#121212</color>
</resources>

<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.RetrofitADAS" parent="android:Theme.Material.Light.NoActionBar">
        <item name="android:statusBarColor">@color/adas_blue</item>
        <item name="android:navigationBarColor">@android:color/white</item>
    </style>
</resources>

<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Retrofit ADAS</string>

    <!-- Dashboard -->
    <string name="dashboard_title">Retrofit ADAS</string>
    <string name="speed_unit">km/h</string>
    <string name="connect_vehicle">Araca Bağlan</string>
    <string name="disconnect">Bağlantıyı Kes</string>

    <!-- Connection -->
    <string name="connection_title">Araç Bağlantısı</string>
    <string name="scanning">Aranıyor…</string>
    <string name="scan_devices">Cihaz Tara</string>
    <string name="paired_devices">Eşleşmiş Cihazlar</string>
    <string name="connected">Bağlı</string>
    <string name="disconnected">Bağlı Değil</string>

    <!-- Trips -->
    <string name="trips_title">Seyahat Geçmişi</string>
    <string name="no_trips">Henüz seyahat kaydı yok</string>
    <string name="trip_duration">Süre</string>
    <string name="trip_distance">Mesafe</string>
    <string name="driving_score">Sürüş Skoru</string>

    <!-- Alerts -->
    <string name="speed_exceeded">Hız limiti aşıldı!</string>
    <string name="harsh_braking">Sert fren algılandı!</string>
    <string name="fatigue_reminder">Mola vermeyi düşünün</string>
    <string name="fatigue_warning">Mola önerilir</string>
    <string name="fatigue_urgent">Lütfen mola verin!</string>

    <!-- Settings -->
    <string name="settings_title">Ayarlar</string>
    <string name="speed_limit">Hız Limiti</string>
    <string name="sound_alerts">Sesli Uyarılar</string>
    <string name="vibration_alerts">Titreşim Uyarıları</string>
    <string name="dark_mode">Karanlık Mod</string>
    <string name="about">Hakkında</string>
    <string name="version">Versiyon %1$s</string>
</resources>

<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/adas_blue"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>

<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/adas_blue"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>

package com.ozge.adas.di

import android.content.Context
import androidx.room.Room
import com.ozge.adas.data.local.AdasDatabase
import com.ozge.adas.data.local.AlertDao
import com.ozge.adas.data.local.RoutePointDao
import com.ozge.adas.data.local.TripDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideAdasDatabase(
        @ApplicationContext context: Context
    ): AdasDatabase {
        return Room.databaseBuilder(
            context,
            AdasDatabase::class.java,
            AdasDatabase.DATABASE_NAME
        )
            .fallbackToDestructiveMigration()
            .build()
    }

    @Provides
    fun provideTripDao(database: AdasDatabase): TripDao = database.tripDao()

    @Provides
    fun provideRoutePointDao(database: AdasDatabase): RoutePointDao = database.routePointDao()

    @Provides
    fun provideAlertDao(database: AdasDatabase): AlertDao = database.alertDao()
}

package com.ozge.adas.di

import com.ozge.adas.data.repository.AlertRepositoryImpl
import com.ozge.adas.data.repository.TripRepositoryImpl
import com.ozge.adas.data.repository.VehicleRepositoryImpl
import com.ozge.adas.domain.repository.AlertRepository
import com.ozge.adas.domain.repository.TripRepository
import com.ozge.adas.domain.repository.VehicleRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindVehicleRepository(
        impl: VehicleRepositoryImpl
    ): VehicleRepository

    @Binds
    @Singleton
    abstract fun bindTripRepository(
        impl: TripRepositoryImpl
    ): TripRepository

    @Binds
    @Singleton
    abstract fun bindAlertRepository(
        impl: AlertRepositoryImpl
    ): AlertRepository
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
