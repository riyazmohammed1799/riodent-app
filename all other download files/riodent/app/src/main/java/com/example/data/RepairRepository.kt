package com.example.data

import android.content.Context
import android.net.Uri
import android.util.Log
import com.example.model.AppConstants
import com.example.model.AppConstants.STATUS_ACTIVE
import com.example.model.AppConstants.STATUS_CANCELLED
import com.example.model.AppConstants.STATUS_COMPLETED
import com.example.model.DoctorProfile
import com.example.model.RepairRequest
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.random.Random

class RepairRepository(private val context: Context) {
    private val TAG = "RepairRepository"

    private val _requests = MutableStateFlow<List<RepairRequest>>(emptyList())
    val requests: StateFlow<List<RepairRequest>> = _requests.asStateFlow()

    private val _doctors = MutableStateFlow<List<DoctorProfile>>(emptyList())
    val doctors: StateFlow<List<DoctorProfile>> = _doctors.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val ioScope = CoroutineScope(Dispatchers.IO)

    init {
        seedInitialData()
    }

    private fun seedInitialData() {
        val sampleDoctor1 = DoctorProfile(
            uid = "doc_sample_101",
            doctorName = "Dr. Ananya Sharma, BDS",
            clinicName = "SmileCraft Dental & Implant Center",
            mobileNumber = "+91 98765 43210",
            address = "Road No. 12, Banjara Hills",
            landmark = "Opposite Indo-American Cancer Hospital",
            latitude = 17.4156,
            longitude = 78.4487,
            email = "dr.sharma@smiledental.com",
            createdAt = System.currentTimeMillis() - 86400000L * 15
        )

        val sampleDoctor2 = DoctorProfile(
            uid = "doc_sample_102",
            doctorName = "Dr. Rajesh Kulkarni, MDS",
            clinicName = "Apex Maxillofacial Dental Hospital",
            mobileNumber = "+91 98220 11223",
            address = "Plot 42, Hitec City Main Road, Madhapur",
            landmark = "Near Cyber Towers Metro",
            latitude = 17.4483,
            longitude = 78.3915,
            email = "dr.kulkarni@apexdental.in",
            createdAt = System.currentTimeMillis() - 86400000L * 30
        )

        val sampleDoctor3 = DoctorProfile(
            uid = "doc_sample_103",
            doctorName = "Dr. Priya Varma, Orthodontist",
            clinicName = "AlignRight Dental Studio",
            mobileNumber = "+91 94450 78901",
            address = "Road No. 36, Jubilee Hills",
            landmark = "Behind Peddamma Temple Metro Station",
            latitude = 17.4319,
            longitude = 78.4073,
            email = "priya.varma@alignright.com",
            createdAt = System.currentTimeMillis() - 86400000L * 5
        )

        _doctors.value = listOf(sampleDoctor1, sampleDoctor2, sampleDoctor3)

        val req1 = RepairRequest(
            requestId = "RIO-74821",
            doctorUid = sampleDoctor1.uid,
            doctorName = sampleDoctor1.doctorName,
            clinicName = sampleDoctor1.clinicName,
            mobileNumber = sampleDoctor1.mobileNumber,
            issueDescription = "Dental chair hydraulic lift oil leakage. The chair fails to recline smoothly and stops abruptly with motor humming.",
            equipmentCategory = "Dental Chair",
            imageUrls = listOf(
                "https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?auto=format&fit=crop&w=600&q=80"
            ),
            address = sampleDoctor1.address,
            landmark = sampleDoctor1.landmark,
            city = "Hyderabad",
            state = "Telangana",
            latitude = sampleDoctor1.latitude,
            longitude = sampleDoctor1.longitude,
            status = STATUS_ACTIVE,
            createdAt = System.currentTimeMillis() - 3600000L * 4,
            completionOtp = "482910"
        )

        val req2 = RepairRequest(
            requestId = "RIO-62914",
            doctorUid = sampleDoctor1.uid,
            doctorName = sampleDoctor1.doctorName,
            clinicName = sampleDoctor1.clinicName,
            mobileNumber = sampleDoctor1.mobileNumber,
            issueDescription = "Autoclave Class-B sterilizer pressure sensor displaying Error E-04 during cycle 3. Sterilization aborts mid-cycle.",
            equipmentCategory = "Autoclave / Sterilizer",
            imageUrls = emptyList(),
            address = sampleDoctor1.address,
            landmark = sampleDoctor1.landmark,
            city = "Hyderabad",
            state = "Telangana",
            latitude = sampleDoctor1.latitude,
            longitude = sampleDoctor1.longitude,
            status = STATUS_COMPLETED,
            createdAt = System.currentTimeMillis() - 86400000L * 3,
            completedAt = System.currentTimeMillis() - 86400000L * 2,
            completionOtp = "715429",
            serviceOutcome = "service_taken",
            amountPaid = 2400.0,
            paymentMode = "UPI",
            technicianName = "Suresh Patel (Lead Tech)"
        )

        val req3 = RepairRequest(
            requestId = "RIO-89102",
            doctorUid = sampleDoctor2.uid,
            doctorName = sampleDoctor2.doctorName,
            clinicName = sampleDoctor2.clinicName,
            mobileNumber = sampleDoctor2.mobileNumber,
            issueDescription = "High-speed optical fiber handpiece air-rotor turbine overheating and water spray nozzle clogged.",
            equipmentCategory = "Handpiece / Rotor",
            imageUrls = listOf(
                "https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=600&q=80"
            ),
            address = sampleDoctor2.address,
            landmark = sampleDoctor2.landmark,
            city = "Hyderabad",
            state = "Telangana",
            latitude = sampleDoctor2.latitude,
            longitude = sampleDoctor2.longitude,
            status = STATUS_ACTIVE,
            createdAt = System.currentTimeMillis() - 3600000L * 8,
            completionOtp = "391054"
        )

        _requests.value = listOf(req1, req2, req3)
    }

    /**
     * Create a new repair request (Operational strictly in Hyderabad, Telangana).
     */
    suspend fun createRepairRequest(
        doctorUid: String,
        doctorName: String,
        clinicName: String,
        mobileNumber: String,
        issueDescription: String,
        equipmentCategory: String,
        imageUris: List<Uri>,
        address: String,
        landmark: String,
        latitude: Double,
        longitude: Double
    ): Result<RepairRequest> {
        _isLoading.value = true
        return try {
            val requestId = "RIO-" + Random.nextInt(10000, 99999).toString()
            val completionOtp = (100000..999999).random().toString()
            val initialUrls = imageUris.map { it.toString() }

            val newRequest = RepairRequest(
                requestId = requestId,
                doctorUid = doctorUid,
                doctorName = doctorName,
                clinicName = clinicName,
                mobileNumber = mobileNumber,
                issueDescription = issueDescription,
                equipmentCategory = equipmentCategory,
                imageUrls = initialUrls,
                address = address,
                landmark = landmark,
                city = "Hyderabad",
                state = "Telangana",
                latitude = if (latitude == 0.0) 17.3850 else latitude,
                longitude = if (longitude == 0.0) 78.4867 else longitude,
                status = STATUS_ACTIVE,
                createdAt = System.currentTimeMillis(),
                updatedAt = System.currentTimeMillis(),
                completionOtp = completionOtp
            )

            val currentList = _requests.value.toMutableList()
            currentList.add(0, newRequest)
            _requests.value = currentList

            ioScope.launch {
                try {
                    val firestore = FirebaseManager.firestore
                    if (firestore != null) {
                        withTimeoutOrNull(3000) {
                            firestore.collection(AppConstants.COLLECTION_REPAIR_REQUESTS)
                                .document(requestId)
                                .set(newRequest.toMap())
                                .await()

                            val profileUpdate = mapOf(
                                "clinicName" to clinicName,
                                "doctorName" to doctorName,
                                "mobileNumber" to mobileNumber,
                                "address" to address,
                                "landmark" to landmark,
                                "city" to "Hyderabad",
                                "state" to "Telangana",
                                "latitude" to newRequest.latitude,
                                "longitude" to newRequest.longitude,
                                "updatedAt" to System.currentTimeMillis()
                            )
                            firestore.collection(AppConstants.COLLECTION_DOCTOR_PROFILES)
                                .document(doctorUid)
                                .update(profileUpdate)
                                .await()
                        }
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Background Firestore sync notice: ${e.message}")
                }
            }

            _isLoading.value = false
            Result.success(newRequest)
        } catch (e: Exception) {
            _isLoading.value = false
            Log.e(TAG, "Error creating repair request: ${e.message}", e)
            Result.failure(e)
        }
    }

    suspend fun cancelRequest(requestId: String): Result<Unit> {
        return denyService(requestId, "Cancelled by clinic before technician visit")
    }

    /**
     * Doctor confirms payment amount made to technician & generates 6-digit OTP to tell technician orally.
     */
    suspend fun confirmPaymentAmountAndGenerateOtp(
        requestId: String,
        amountPaid: Double
    ): Result<String> {
        val target = _requests.value.find { it.requestId == requestId }
            ?: return Result.failure(Exception("Request not found"))

        val newOtp = (100000..999999).random().toString()
        val now = System.currentTimeMillis()

        _requests.value = _requests.value.map { req ->
            if (req.requestId == requestId) {
                req.copy(
                    amountPaid = amountPaid,
                    completionOtp = newOtp,
                    updatedAt = now
                )
            } else req
        }

        ioScope.launch {
            try {
                val firestore = FirebaseManager.firestore
                if (firestore != null) {
                    withTimeoutOrNull(3000) {
                        firestore.collection(AppConstants.COLLECTION_REPAIR_REQUESTS)
                            .document(requestId)
                            .update(
                                mapOf(
                                    "amountPaid" to amountPaid,
                                    "completionOtp" to newOtp,
                                    "updatedAt" to now
                                )
                            ).await()
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Background OTP update sync notice: ${e.message}")
            }
        }

        return Result.success(newOtp)
    }

    /**
     * Admin closes ticket after technician calls and shares OTP orally.
     */
    suspend fun adminCloseTicketWithOtp(
        requestId: String,
        enteredOtp: String
    ): Result<Unit> {
        val target = _requests.value.find { it.requestId == requestId }
            ?: return Result.failure(Exception("Request not found"))

        if (target.completionOtp.trim() != enteredOtp.trim()) {
            return Result.failure(Exception("Invalid OTP. The 6-digit OTP shared by technician does not match."))
        }

        _isLoading.value = true
        return try {
            val now = System.currentTimeMillis()
            _requests.value = _requests.value.map { req ->
                if (req.requestId == requestId) {
                    req.copy(
                        status = STATUS_COMPLETED,
                        serviceOutcome = "service_taken",
                        completedAt = now,
                        updatedAt = now
                    )
                } else req
            }

            ioScope.launch {
                try {
                    val firestore = FirebaseManager.firestore
                    if (firestore != null) {
                        withTimeoutOrNull(3000) {
                            firestore.collection(AppConstants.COLLECTION_REPAIR_REQUESTS)
                                .document(requestId)
                                .update(
                                    mapOf(
                                        "status" to STATUS_COMPLETED,
                                        "serviceOutcome" to "service_taken",
                                        "completedAt" to now,
                                        "updatedAt" to now
                                    )
                                ).await()
                        }
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Background completion sync notice: ${e.message}")
                }
            }

            _isLoading.value = false
            Result.success(Unit)
        } catch (e: Exception) {
            _isLoading.value = false
            Result.failure(e)
        }
    }

    /**
     * Admin directly updates request status without requiring OTP.
     */
    suspend fun adminUpdateStatusDirect(
        requestId: String,
        newStatus: String,
        amountPaid: Double? = null,
        reason: String? = null
    ): Result<Unit> {
        val target = _requests.value.find { it.requestId == requestId }
            ?: return Result.failure(Exception("Request not found"))

        _isLoading.value = true
        val now = System.currentTimeMillis()
        _requests.value = _requests.value.map { req ->
            if (req.requestId == requestId) {
                req.copy(
                    status = newStatus,
                    serviceOutcome = when (newStatus) {
                        STATUS_COMPLETED -> "service_taken"
                        STATUS_CANCELLED -> "service_denied"
                        else -> req.serviceOutcome
                    },
                    amountPaid = amountPaid ?: req.amountPaid,
                    denialReason = if (newStatus == STATUS_CANCELLED) (reason ?: "Cancelled by Admin") else req.denialReason,
                    completedAt = if (newStatus == STATUS_COMPLETED) now else req.completedAt,
                    cancelledAt = if (newStatus == STATUS_CANCELLED) now else req.cancelledAt,
                    updatedAt = now
                )
            } else req
        }

        ioScope.launch {
            try {
                val firestore = FirebaseManager.firestore
                if (firestore != null) {
                    withTimeoutOrNull(3000) {
                        val updateMap = mutableMapOf<String, Any>(
                            "status" to newStatus,
                            "updatedAt" to now
                        )
                        amountPaid?.let { updateMap["amountPaid"] = it }
                        if (newStatus == STATUS_COMPLETED) {
                            updateMap["serviceOutcome"] = "service_taken"
                            updateMap["completedAt"] = now
                        } else if (newStatus == STATUS_CANCELLED) {
                            updateMap["serviceOutcome"] = "service_denied"
                            updateMap["denialReason"] = reason ?: "Cancelled by Admin"
                            updateMap["cancelledAt"] = now
                        }
                        firestore.collection(AppConstants.COLLECTION_REPAIR_REQUESTS)
                            .document(requestId)
                            .update(updateMap)
                            .await()
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Background direct status update notice: ${e.message}")
            }
        }

        _isLoading.value = false
        return Result.success(Unit)
    }

    /**
     * Service Taken: Doctor enters amount paid to technician + validates 6-digit OTP.
     */
    suspend fun completeServiceWithOtpAndPayment(
        requestId: String,
        enteredOtp: String,
        amountPaid: Double,
        paymentMode: String = ""
    ): Result<Unit> {
        val target = _requests.value.find { it.requestId == requestId }
            ?: return Result.failure(Exception("Request not found"))

        if (target.completionOtp.trim() != enteredOtp.trim()) {
            return Result.failure(Exception("Invalid completion OTP. Please enter the correct 6-digit code provided on the booking ticket."))
        }

        _isLoading.value = true
        return try {
            val now = System.currentTimeMillis()
            _requests.value = _requests.value.map { req ->
                if (req.requestId == requestId) {
                    req.copy(
                        status = STATUS_COMPLETED,
                        serviceOutcome = "service_taken",
                        amountPaid = amountPaid,
                        paymentMode = paymentMode,
                        completedAt = now,
                        updatedAt = now
                    )
                } else req
            }

            ioScope.launch {
                try {
                    val firestore = FirebaseManager.firestore
                    if (firestore != null) {
                        withTimeoutOrNull(3000) {
                            firestore.collection(AppConstants.COLLECTION_REPAIR_REQUESTS)
                                .document(requestId)
                                .update(
                                    mapOf(
                                        "status" to STATUS_COMPLETED,
                                        "serviceOutcome" to "service_taken",
                                        "amountPaid" to amountPaid,
                                        "paymentMode" to paymentMode,
                                        "completedAt" to now,
                                        "updatedAt" to now
                                    )
                                ).await()
                        }
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Background completion sync notice: ${e.message}")
                }
            }

            _isLoading.value = false
            Result.success(Unit)
        } catch (e: Exception) {
            _isLoading.value = false
            Result.failure(e)
        }
    }

    /**
     * Service Denied: Doctor records service not taken with reason and optional visiting fee / OTP validation.
     */
    suspend fun denyService(
        requestId: String,
        reason: String,
        amountPaid: Double = 0.0,
        otp: String = ""
    ): Result<Unit> {
        val target = _requests.value.find { it.requestId == requestId }
            ?: return Result.failure(Exception("Request not found"))

        if (otp.isNotBlank() && target.completionOtp.trim() != otp.trim()) {
            return Result.failure(Exception("Invalid OTP code. Please enter the OTP displayed on the booking ticket."))
        }

        _isLoading.value = true
        return try {
            val now = System.currentTimeMillis()
            _requests.value = _requests.value.map { req ->
                if (req.requestId == requestId) {
                    req.copy(
                        status = STATUS_CANCELLED,
                        serviceOutcome = "service_denied",
                        denialReason = reason,
                        amountPaid = amountPaid,
                        cancelledAt = now,
                        updatedAt = now
                    )
                } else req
            }

            ioScope.launch {
                try {
                    val firestore = FirebaseManager.firestore
                    if (firestore != null) {
                        withTimeoutOrNull(3000) {
                            firestore.collection(AppConstants.COLLECTION_REPAIR_REQUESTS)
                                .document(requestId)
                                .update(
                                    mapOf(
                                        "status" to STATUS_CANCELLED,
                                        "serviceOutcome" to "service_denied",
                                        "denialReason" to reason,
                                        "amountPaid" to amountPaid,
                                        "cancelledAt" to now,
                                        "updatedAt" to now
                                    )
                                ).await()
                        }
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Background denial sync notice: ${e.message}")
                }
            }

            _isLoading.value = false
            Result.success(Unit)
        } catch (e: Exception) {
            _isLoading.value = false
            Result.failure(e)
        }
    }

    suspend fun completeRequestWithOtp(requestId: String, enteredOtp: String): Result<Unit> {
        return completeServiceWithOtpAndPayment(requestId, enteredOtp, 0.0, "Direct")
    }

    fun registerNewDoctor(profile: DoctorProfile) {
        val exists = _doctors.value.any { it.uid == profile.uid }
        if (!exists) {
            _doctors.value = listOf(profile) + _doctors.value
        }
    }
}
