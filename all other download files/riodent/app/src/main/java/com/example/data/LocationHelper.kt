package com.example.data

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.location.Geocoder
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withTimeoutOrNull
import java.util.Locale

data class LocationData(
    val latitude: Double,
    val longitude: Double,
    val address: String = "",
    val landmark: String = "",
    val city: String = "Hyderabad",
    val isLiveGps: Boolean = true,
    val sourceDescription: String = "Live Device GPS",
    val accuracyMeters: Float = 0f
)

class LocationHelper(private val context: Context) {
    private val TAG = "LocationHelper"
    private val fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)

    @SuppressLint("MissingPermission")
    suspend fun getCurrentLocation(): LocationData {
        val finePerm = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION)
        val coarsePerm = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION)
        val hasPermission = finePerm == PackageManager.PERMISSION_GRANTED || coarsePerm == PackageManager.PERMISSION_GRANTED

        var bestLocation: Location? = null

        if (hasPermission) {
            // 1. Try FusedLocationProviderClient with 3.5s timeout
            try {
                val cts = CancellationTokenSource()
                bestLocation = withTimeoutOrNull(3500) {
                    fusedLocationClient.getCurrentLocation(
                        Priority.PRIORITY_HIGH_ACCURACY,
                        cts.token
                    ).await()
                } ?: withTimeoutOrNull(1500) {
                    fusedLocationClient.lastLocation.await()
                }
            } catch (e: Exception) {
                Log.w(TAG, "FusedLocationProvider exception: ${e.message}")
            }

            // 2. Fallback to system LocationManager if fused returned null
            if (bestLocation == null) {
                try {
                    val lm = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
                    if (lm != null) {
                        val gpsLoc = lm.getLastKnownLocation(LocationManager.GPS_PROVIDER)
                        val netLoc = lm.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
                        val passLoc = lm.getLastKnownLocation(LocationManager.PASSIVE_PROVIDER)
                        bestLocation = gpsLoc ?: netLoc ?: passLoc
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "LocationManager fallback notice: ${e.message}")
                }
            }
        }

        // Check if location was obtained
        if (bestLocation != null) {
            val lat = bestLocation.latitude
            val lng = bestLocation.longitude
            val accuracy = bestLocation.accuracy

            // Check if coordinates correspond to the standard Android Emulator default (Mountain View 37.42N, -122.08W)
            val isEmulatorDefault = (lat in 37.3..37.5 && lng in -122.2..-122.0) || (lat == 0.0 && lng == 0.0)

            if (!isEmulatorDefault) {
                // Real physical device GPS coordinates acquired!
                var addressText = ""
                var landmarkText = ""
                try {
                    val geocoder = Geocoder(context, Locale.getDefault())
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val addresses = geocoder.getFromLocation(lat, lng, 1)
                        if (!addresses.isNullOrEmpty()) {
                            val addr = addresses[0]
                            addressText = addr.getAddressLine(0) ?: "${addr.subLocality ?: ""}, ${addr.locality ?: "Hyderabad"}"
                            landmarkText = addr.featureName ?: addr.subLocality ?: ""
                        }
                    } else {
                        @Suppress("DEPRECATION")
                        val addresses = geocoder.getFromLocation(lat, lng, 1)
                        if (!addresses.isNullOrEmpty()) {
                            val addr = addresses[0]
                            addressText = addr.getAddressLine(0) ?: "${addr.subLocality ?: ""}, ${addr.locality ?: "Hyderabad"}"
                            landmarkText = addr.featureName ?: addr.subLocality ?: ""
                        }
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Geocoder reverse geocode notice: ${e.message}")
                }

                val finalAddr = if (addressText.isNotBlank()) {
                    if (!addressText.contains("Hyderabad", ignoreCase = true)) "$addressText, Hyderabad, Telangana" else addressText
                } else {
                    "Hyderabad Clinic Coordinates (${String.format(Locale.US, "%.4f", lat)}, ${String.format(Locale.US, "%.4f", lng)})"
                }

                return LocationData(
                    latitude = lat,
                    longitude = lng,
                    address = finalAddr,
                    landmark = landmarkText,
                    city = "Hyderabad",
                    isLiveGps = true,
                    sourceDescription = "Live GPS Sensor (±${accuracy.toInt().coerceAtLeast(5)}m accuracy)",
                    accuracyMeters = accuracy
                )
            } else {
                // Device returned standard Android emulator mock coordinates (California).
                // Centering to prime Hyderabad medical hub so booking stays strictly in Hyderabad.
                return LocationData(
                    latitude = 17.4156,
                    longitude = 78.4487,
                    address = "Road No. 1, Banjara Hills, Hyderabad, Telangana",
                    landmark = "Near Care Hospital / City Center Mall",
                    city = "Hyderabad",
                    isLiveGps = false,
                    sourceDescription = "Emulator detected — auto-centered to Hyderabad (Banjara Hills)",
                    accuracyMeters = 10f
                )
            }
        }

        // Default Hyderabad Dental hub coordinates when sensors are offline / permission pending
        return LocationData(
            latitude = 17.4156,
            longitude = 78.4487,
            address = "Road No. 1, Banjara Hills, Hyderabad, Telangana",
            landmark = "Near Care Hospital / City Center Mall",
            city = "Hyderabad",
            isLiveGps = false,
            sourceDescription = "Hyderabad Central Dental Hub (Select your area below)",
            accuracyMeters = 25f
        )
    }

    companion object {
        // Prominent Hyderabad dental hubs for quick one-tap clinic area selection
        val HYDERABAD_AREAS = listOf(
            "Banjara Hills, Hyderabad" to Pair(17.4156, 78.4487),
            "Jubilee Hills, Hyderabad" to Pair(17.4319, 78.4073),
            "Madhapur / Hitec City, Hyderabad" to Pair(17.4483, 78.3915),
            "Secunderabad, Hyderabad" to Pair(17.4399, 78.4983),
            "Kukatpally, Hyderabad" to Pair(17.4849, 78.4138),
            "Ameerpet, Hyderabad" to Pair(17.4375, 78.4483),
            "Gachibowli, Hyderabad" to Pair(17.4401, 78.3489),
            "Dilsukhnagar, Hyderabad" to Pair(17.3688, 78.5247),
            "Begumpet, Hyderabad" to Pair(17.4447, 78.4664),
            "Somajiguda, Hyderabad" to Pair(17.4265, 78.4593)
        )
    }
}
