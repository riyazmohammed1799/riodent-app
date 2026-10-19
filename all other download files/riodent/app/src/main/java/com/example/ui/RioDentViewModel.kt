package com.example.ui

import android.app.Application
import android.net.Uri
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.data.AuthRepository
import com.example.data.FirebaseManager
import com.example.data.LocationHelper
import com.example.data.RepairRepository
import com.example.model.AppConstants
import com.example.model.AppConstants.PREDEFINED_ADMIN_EMAIL
import com.example.model.AppConstants.ROLE_ADMIN
import com.example.model.DoctorProfile
import com.example.model.RepairRequest
import com.example.model.User
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

enum class Screen {
    MAIN,
    CREATE_STEP_1,
    CREATE_STEP_2,
    REQUEST_DETAIL,
    CLOSE_TICKET_OTP,
    EDIT_PROFILE,
    ADMIN_PANEL
}

enum class NavigationTab {
    HOME,
    REQUESTS,
    PROFILE,
    ADMIN
}

data class CreateRequestDraft(
    val issueDescription: String = "",
    val equipmentCategory: String = "Dental Chair",
    val imageUris: List<Uri> = emptyList(),
    val clinicName: String = "",
    val doctorName: String = "",
    val address: String = "",
    val landmark: String = "",
    val mobileNumber: String = "",
    val latitude: Double = 0.0,
    val longitude: Double = 0.0,
    val isDetectingLocation: Boolean = false,
    val locationStatusText: String = ""
)

class RioDentViewModel(application: Application) : AndroidViewModel(application) {
    private val authRepo = AuthRepository(application.applicationContext)
    private val repairRepo = RepairRepository(application.applicationContext)
    private val locationHelper = LocationHelper(application.applicationContext)
    private val notificationHelper = com.example.data.NotificationHelper(application.applicationContext)

    init {
        FirebaseManager.init(application.applicationContext)
    }

    val currentUser: StateFlow<User?> = authRepo.currentUser
    val currentDoctorProfile: StateFlow<DoctorProfile?> = authRepo.currentDoctorProfile
    val isAuthLoading: StateFlow<Boolean> = authRepo.isLoading

    val allRequests: StateFlow<List<RepairRequest>> = repairRepo.requests
    val allDoctors: StateFlow<List<DoctorProfile>> = repairRepo.doctors
    val isRepairLoading: StateFlow<Boolean> = repairRepo.isLoading

    private val _currentScreen = MutableStateFlow(Screen.MAIN)
    val currentScreen: StateFlow<Screen> = _currentScreen.asStateFlow()

    private val _currentTab = MutableStateFlow(NavigationTab.HOME)
    val currentTab: StateFlow<NavigationTab> = _currentTab.asStateFlow()

    private val _selectedRequest = MutableStateFlow<RepairRequest?>(null)
    val selectedRequest: StateFlow<RepairRequest?> = _selectedRequest.asStateFlow()

    private val _createDraft = MutableStateFlow(CreateRequestDraft())
    val createDraft: StateFlow<CreateRequestDraft> = _createDraft.asStateFlow()

    private val _submissionSuccessRequest = MutableStateFlow<RepairRequest?>(null)
    val submissionSuccessRequest: StateFlow<RepairRequest?> = _submissionSuccessRequest.asStateFlow()

    private val _statusMessage = MutableStateFlow<String?>(null)
    val statusMessage: StateFlow<String?> = _statusMessage.asStateFlow()

    private val _inAppNotification = MutableStateFlow<String?>(null)
    val inAppNotification: StateFlow<String?> = _inAppNotification.asStateFlow()

    private val _otpInput = MutableStateFlow("")
    val otpInput: StateFlow<String> = _otpInput.asStateFlow()

    private val _otpError = MutableStateFlow<String?>(null)
    val otpError: StateFlow<String?> = _otpError.asStateFlow()

    private val _showGoogleAccountPicker = MutableStateFlow(false)
    val showGoogleAccountPicker: StateFlow<Boolean> = _showGoogleAccountPicker.asStateFlow()

    fun showGooglePicker() {
        _showGoogleAccountPicker.value = true
    }

    fun dismissGooglePicker() {
        _showGoogleAccountPicker.value = false
    }

    // Environment info
    val currentEnv: String
        get() = FirebaseManager.currentEnvironment

    // Current Doctor Requests
    val doctorRequests: StateFlow<List<RepairRequest>> = combine(allRequests, currentUser) { reqs, user ->
        if (user == null) emptyList()
        else if (user.role == ROLE_ADMIN) reqs
        else reqs.filter { it.doctorUid == user.uid }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val activeDoctorRequests: StateFlow<List<RepairRequest>> = combine(doctorRequests) { reqs ->
        reqs[0].filter { it.status == AppConstants.STATUS_ACTIVE }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val completedDoctorRequests: StateFlow<List<RepairRequest>> = combine(doctorRequests) { reqs ->
        reqs[0].filter { it.status == AppConstants.STATUS_COMPLETED }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun navigateToTab(tab: NavigationTab) {
        _currentTab.value = tab
        if (tab == NavigationTab.ADMIN) {
            _currentScreen.value = Screen.ADMIN_PANEL
        } else {
            _currentScreen.value = Screen.MAIN
        }
    }

    fun navigateTo(screen: Screen) {
        _currentScreen.value = screen
    }

    fun selectRequest(request: RepairRequest) {
        _selectedRequest.value = request
        _otpInput.value = ""
        _otpError.value = null
        _currentScreen.value = Screen.REQUEST_DETAIL
    }

    fun startCreateRequest() {
        val profile = currentDoctorProfile.value
        _createDraft.value = CreateRequestDraft(
            clinicName = profile?.clinicName ?: "",
            doctorName = profile?.doctorName ?: currentUser.value?.displayName ?: "",
            address = profile?.address ?: "",
            landmark = profile?.landmark ?: "",
            mobileNumber = profile?.mobileNumber ?: "",
            latitude = profile?.latitude ?: 0.0,
            longitude = profile?.longitude ?: 0.0,
            locationStatusText = if ((profile?.latitude ?: 0.0) != 0.0) "Saved Clinic Coordinates" else ""
        )
        _currentScreen.value = Screen.CREATE_STEP_1
    }

    fun updateIssueDescription(desc: String) {
        _createDraft.value = _createDraft.value.copy(issueDescription = desc)
    }

    fun updateEquipmentCategory(category: String) {
        _createDraft.value = _createDraft.value.copy(equipmentCategory = category)
    }

    fun addImages(uris: List<Uri>) {
        val existing = _createDraft.value.imageUris.toMutableList()
        existing.addAll(uris)
        _createDraft.value = _createDraft.value.copy(imageUris = existing.distinct())
    }

    fun removeImage(uri: Uri) {
        val filtered = _createDraft.value.imageUris.filter { it != uri }
        _createDraft.value = _createDraft.value.copy(imageUris = filtered)
    }

    fun updateClinicInfo(
        clinicName: String,
        doctorName: String,
        address: String,
        landmark: String,
        mobileNumber: String
    ) {
        _createDraft.value = _createDraft.value.copy(
            clinicName = clinicName,
            doctorName = doctorName,
            address = address,
            landmark = landmark,
            mobileNumber = mobileNumber
        )
    }

    fun detectGpsLocation() {
        viewModelScope.launch {
            _createDraft.value = _createDraft.value.copy(isDetectingLocation = true)
            val loc = locationHelper.getCurrentLocation()
            if (loc != null) {
                _createDraft.value = _createDraft.value.copy(
                    latitude = loc.latitude,
                    longitude = loc.longitude,
                    address = if (_createDraft.value.address.isBlank()) loc.address else _createDraft.value.address,
                    landmark = if (_createDraft.value.landmark.isBlank()) loc.landmark else _createDraft.value.landmark,
                    isDetectingLocation = false,
                    locationStatusText = "GPS Coordinates Captured (${String.format("%.4f", loc.latitude)}, ${String.format("%.4f", loc.longitude)})"
                )
            } else {
                _createDraft.value = _createDraft.value.copy(
                    isDetectingLocation = false,
                    locationStatusText = "Location pinpointed via default coordinates"
                )
            }
        }
    }

    fun submitRepairRequest(
        clinicName: String? = null,
        doctorName: String? = null,
        mobileNumber: String? = null,
        address: String? = null,
        landmark: String? = null
    ): Boolean {
        val user = currentUser.value ?: User(
            uid = "doc_sample_101",
            displayName = doctorName ?: "Dr. Ananya Sharma",
            email = "dr.sharma@smiledental.com"
        )

        // Merge latest form inputs
        if (clinicName != null) {
            _createDraft.value = _createDraft.value.copy(
                clinicName = clinicName,
                doctorName = doctorName ?: _createDraft.value.doctorName,
                mobileNumber = mobileNumber ?: _createDraft.value.mobileNumber,
                address = address ?: _createDraft.value.address,
                landmark = landmark ?: _createDraft.value.landmark
            )
        }

        val draft = _createDraft.value
        val finalIssue = draft.issueDescription.ifBlank { "Dental equipment breakdown service inspection (${draft.equipmentCategory})" }
        val finalClinic = draft.clinicName.ifBlank { clinicName ?: "Dental Clinic" }
        val finalDoctor = draft.doctorName.ifBlank { doctorName ?: user.displayName }
        val finalMobile = draft.mobileNumber.ifBlank { mobileNumber ?: "+91 98765 43210" }
        val finalAddress = draft.address.ifBlank { address ?: "Clinic Address" }

        viewModelScope.launch {
            val result = repairRepo.createRepairRequest(
                doctorUid = user.uid,
                doctorName = finalDoctor,
                clinicName = finalClinic,
                mobileNumber = finalMobile,
                issueDescription = finalIssue,
                equipmentCategory = draft.equipmentCategory,
                imageUris = draft.imageUris,
                address = finalAddress,
                landmark = draft.landmark.ifBlank { landmark ?: "" },
                latitude = draft.latitude,
                longitude = draft.longitude
            )

            result.onSuccess { newReq ->
                _submissionSuccessRequest.value = newReq
                _selectedRequest.value = newReq
                _statusMessage.value = "Technician booking confirmed! We will update you or a technician will call you soon."
            }.onFailure { err ->
                _statusMessage.value = "Failed to submit request: ${err.message}"
            }
        }
        return true
    }

    fun dismissSuccessDialog() {
        _submissionSuccessRequest.value = null
        _createDraft.value = CreateRequestDraft()
        _currentScreen.value = Screen.MAIN
        _currentTab.value = NavigationTab.HOME
    }

    fun cancelSelectedRequest() {
        val req = _selectedRequest.value ?: return
        viewModelScope.launch {
            repairRepo.cancelRequest(req.requestId).onSuccess {
                _selectedRequest.value = _selectedRequest.value?.copy(
                    status = AppConstants.STATUS_CANCELLED,
                    cancelledAt = System.currentTimeMillis()
                )
                _statusMessage.value = "Request ${req.requestId} cancelled."
            }.onFailure { err ->
                _statusMessage.value = "Cancellation failed: ${err.message}"
            }
        }
    }

    fun updateOtpInput(code: String) {
        _otpInput.value = code
        _otpError.value = null
    }

    fun selectHyderabadArea(areaName: String, lat: Double, lng: Double) {
        _createDraft.value = _createDraft.value.copy(
            address = if (_createDraft.value.address.isBlank()) "$areaName, Hyderabad, Telangana" else _createDraft.value.address,
            latitude = lat,
            longitude = lng,
            locationStatusText = "Selected Hyderabad Area: $areaName (${String.format("%.4f", lat)}, ${String.format("%.4f", lng)})"
        )
    }

    fun confirmPaymentAmountAndGenerateOtp(amountPaid: Double) {
        val req = _selectedRequest.value ?: return
        viewModelScope.launch {
            val result = repairRepo.confirmPaymentAmountAndGenerateOtp(req.requestId, amountPaid)
            result.onSuccess { newOtp ->
                _selectedRequest.value = _selectedRequest.value?.copy(
                    amountPaid = amountPaid,
                    completionOtp = newOtp
                )
                notificationHelper.sendTicketClosureOtpNotification(req.requestId, newOtp, amountPaid)
                _inAppNotification.value = "📩 Notification: Ticket Closure OTP is $newOtp. Share orally with technician."
                _statusMessage.value = "OTP sent via notification! Share OTP ($newOtp) orally with technician."
            }.onFailure { err ->
                _statusMessage.value = "Failed to generate OTP: ${err.message}"
            }
        }
    }

    fun proceedToOtpClosure(amountPaid: Double) {
        val req = _selectedRequest.value ?: return
        _selectedRequest.value = _selectedRequest.value?.copy(
            amountPaid = amountPaid
        )
        _otpError.value = null
        _currentScreen.value = Screen.CLOSE_TICKET_OTP
    }

    fun sendClosureOtpNotification(amountPaid: Double) {
        val req = _selectedRequest.value ?: return
        viewModelScope.launch {
            val result = repairRepo.confirmPaymentAmountAndGenerateOtp(req.requestId, amountPaid)
            result.onSuccess { newOtp ->
                _selectedRequest.value = _selectedRequest.value?.copy(
                    amountPaid = amountPaid,
                    completionOtp = newOtp
                )
                notificationHelper.sendTicketClosureOtpNotification(req.requestId, newOtp, amountPaid)
                _inAppNotification.value = "📩 Notification: Ticket Closure OTP is $newOtp. Tell this to your technician orally."
                _statusMessage.value = "OTP sent via notification! Tell OTP to technician orally."
            }.onFailure { err ->
                _statusMessage.value = "Failed to send OTP: ${err.message}"
            }
        }
    }

    fun updateAmountAndRegenerateOtp(newAmount: Double) {
        val req = _selectedRequest.value ?: return
        viewModelScope.launch {
            val result = repairRepo.confirmPaymentAmountAndGenerateOtp(req.requestId, newAmount)
            result.onSuccess { newOtp ->
                _selectedRequest.value = _selectedRequest.value?.copy(
                    amountPaid = newAmount,
                    completionOtp = newOtp
                )
                notificationHelper.sendTicketClosureOtpNotification(req.requestId, newOtp, newAmount)
                _inAppNotification.value = "📩 Notification: Updated Ticket Closure OTP is $newOtp."
                _statusMessage.value = "Amount updated & OTP refreshed! Tell OTP to technician orally."
            }.onFailure { err ->
                _statusMessage.value = "Failed to update amount: ${err.message}"
            }
        }
    }

    fun clearInAppNotification() {
        _inAppNotification.value = null
    }

    fun closeTicketWithOtp(enteredOtp: String) {
        val req = _selectedRequest.value ?: return
        val code = enteredOtp.trim()
        if (code.length != 6) {
            _otpError.value = "Please enter the 6-digit OTP code."
            return
        }

        viewModelScope.launch {
            val result = repairRepo.adminCloseTicketWithOtp(req.requestId, code)
            result.onSuccess {
                _selectedRequest.value = _selectedRequest.value?.copy(
                    status = AppConstants.STATUS_COMPLETED,
                    serviceOutcome = "service_taken",
                    completedAt = System.currentTimeMillis()
                )
                _otpError.value = null
                _statusMessage.value = "Ticket closed successfully! Technician service completed."
                _currentScreen.value = Screen.MAIN
                _currentTab.value = NavigationTab.HOME
            }.onFailure { err ->
                _otpError.value = err.message ?: "Invalid OTP."
            }
        }
    }

    fun adminCloseTicketWithOtp(enteredOtp: String) {
        val req = _selectedRequest.value ?: return
        val code = enteredOtp.trim()
        if (code.length != 6) {
            _otpError.value = "Please enter the 6-digit OTP code."
            return
        }

        viewModelScope.launch {
            val result = repairRepo.adminCloseTicketWithOtp(req.requestId, code)
            result.onSuccess {
                _selectedRequest.value = _selectedRequest.value?.copy(
                    status = AppConstants.STATUS_COMPLETED,
                    serviceOutcome = "service_taken",
                    completedAt = System.currentTimeMillis()
                )
                _otpError.value = null
                _statusMessage.value = "Ticket verified & closed successfully! Status updated."
                _currentScreen.value = Screen.MAIN
                _currentTab.value = NavigationTab.HOME
            }.onFailure { err ->
                _otpError.value = err.message ?: "Invalid OTP."
                _statusMessage.value = "Failed to close ticket: ${err.message}"
            }
        }
    }

    fun adminUpdateStatusDirectly(
        requestId: String,
        newStatus: String,
        amountPaid: Double? = null,
        reason: String? = null
    ) {
        viewModelScope.launch {
            val result = repairRepo.adminUpdateStatusDirect(requestId, newStatus, amountPaid, reason)
            result.onSuccess {
                _statusMessage.value = "Status updated to ${if (newStatus == AppConstants.STATUS_COMPLETED) "Completed" else if (newStatus == AppConstants.STATUS_CANCELLED) "Cancelled / Denied" else "Active"}!"
                _currentScreen.value = Screen.MAIN
                _currentTab.value = NavigationTab.HOME
            }.onFailure { err ->
                _statusMessage.value = "Failed to update status: ${err.message}"
            }
        }
    }

    fun completeServiceWithPayment(amountPaid: Double, paymentMode: String = "", otp: String) {
        val req = _selectedRequest.value ?: return
        val code = otp.trim()
        if (code.length != 6) {
            _otpError.value = "Please enter the 6-digit OTP code."
            return
        }

        viewModelScope.launch {
            val result = repairRepo.completeServiceWithOtpAndPayment(req.requestId, code, amountPaid, paymentMode)
            result.onSuccess {
                _selectedRequest.value = _selectedRequest.value?.copy(
                    status = AppConstants.STATUS_COMPLETED,
                    serviceOutcome = "service_taken",
                    amountPaid = amountPaid,
                    paymentMode = paymentMode,
                    completedAt = System.currentTimeMillis()
                )
                _otpError.value = null
                _statusMessage.value = "Service verified & completed! Amount paid: ₹${String.format("%.0f", amountPaid)}."
                _currentScreen.value = Screen.MAIN
                _currentTab.value = NavigationTab.HOME
            }.onFailure { err ->
                _otpError.value = err.message ?: "Invalid OTP."
            }
        }
    }

    fun recordServiceDenied(reason: String, amountPaid: Double = 0.0, otp: String = "") {
        val req = _selectedRequest.value ?: return
        viewModelScope.launch {
            val result = repairRepo.denyService(req.requestId, reason, amountPaid, otp)
            result.onSuccess {
                _selectedRequest.value = _selectedRequest.value?.copy(
                    status = AppConstants.STATUS_CANCELLED,
                    serviceOutcome = "service_denied",
                    denialReason = reason,
                    amountPaid = amountPaid,
                    cancelledAt = System.currentTimeMillis()
                )
                _otpError.value = null
                _statusMessage.value = "Service recorded as denied: $reason"
                _currentScreen.value = Screen.MAIN
                _currentTab.value = NavigationTab.HOME
            }.onFailure { err ->
                _otpError.value = err.message ?: "Error updating request"
                _statusMessage.value = "Error updating request: ${err.message}"
            }
        }
    }

    fun completeSelectedRequestWithOtp() {
        val req = _selectedRequest.value ?: return
        val code = _otpInput.value.trim()
        if (code.length != 6) {
            _otpError.value = "Please enter the 6-digit OTP code."
            return
        }

        viewModelScope.launch {
            val result = repairRepo.completeRequestWithOtp(req.requestId, code)
            result.onSuccess {
                _selectedRequest.value = _selectedRequest.value?.copy(
                    status = AppConstants.STATUS_COMPLETED,
                    completedAt = System.currentTimeMillis()
                )
                _otpError.value = null
                _statusMessage.value = "Service verified & completed successfully!"
            }.onFailure { err ->
                _otpError.value = err.message ?: "Invalid OTP."
            }
        }
    }

    fun updateDoctorProfile(
        doctorName: String,
        clinicName: String,
        mobileNumber: String,
        address: String,
        landmark: String
    ) {
        val current = currentDoctorProfile.value ?: return
        viewModelScope.launch {
            val updated = current.copy(
                doctorName = doctorName,
                clinicName = clinicName,
                mobileNumber = mobileNumber,
                address = address,
                landmark = landmark
            )
            authRepo.updateDoctorProfile(updated).onSuccess {
                _statusMessage.value = "Doctor profile updated."
                _currentScreen.value = Screen.MAIN
            }.onFailure {
                _statusMessage.value = "Update failed: ${it.message}"
            }
        }
    }

    // Google Sign-In
    fun signInWithGoogle() {
        viewModelScope.launch {
            val res = authRepo.signInWithGoogle()
            if (res.isFailure) {
                // If Google Play Services is missing or has no active accounts in emulator, prompt Google Account Picker
                _showGoogleAccountPicker.value = true
                _statusMessage.value = "Select your Google Account to sign in"
            } else {
                val user = res.getOrNull()
                if (user?.role == ROLE_ADMIN) {
                    _currentTab.value = NavigationTab.ADMIN
                } else {
                    _currentTab.value = NavigationTab.HOME
                }
                _currentScreen.value = Screen.MAIN
            }
        }
    }

    fun resetToHome() {
        _currentScreen.value = Screen.MAIN
        _currentTab.value = NavigationTab.HOME
    }

    // Quick account switchers for demo / emulator testing
    fun signInAsSampleDoctor() {
        viewModelScope.launch {
            authRepo.signInWithSimulatedGoogleAccount(
                email = "dr.sharma@smiledental.com",
                name = "Dr. Ananya Sharma, BDS"
            )
            _showGoogleAccountPicker.value = false
            _currentTab.value = NavigationTab.HOME
            _currentScreen.value = Screen.MAIN
            _statusMessage.value = "Signed in as Dr. Ananya Sharma"
        }
    }

    fun signInAsAdmin() {
        viewModelScope.launch {
            authRepo.signInWithSimulatedGoogleAccount(
                email = PREDEFINED_ADMIN_EMAIL,
                name = "Riyaz Mohammed (Super Admin)"
            )
            _showGoogleAccountPicker.value = false
            _currentTab.value = NavigationTab.ADMIN
            _currentScreen.value = Screen.MAIN
            _statusMessage.value = "Welcome Admin ($PREDEFINED_ADMIN_EMAIL)."
        }
    }

    fun signInWithCustomEmail(email: String) {
        viewModelScope.launch {
            val isAdmin = email.trim().equals(PREDEFINED_ADMIN_EMAIL.trim(), ignoreCase = true)
            val displayName = if (isAdmin) "Riyaz Mohammed (Admin)" else "Dr. " + email.substringBefore("@").replaceFirstChar { it.uppercase() }
            val user = authRepo.signInWithSimulatedGoogleAccount(
                email = email.trim(),
                name = displayName
            )
            _showGoogleAccountPicker.value = false
            if (isAdmin) {
                _currentTab.value = NavigationTab.ADMIN
            } else {
                _currentTab.value = NavigationTab.HOME
            }
            _currentScreen.value = Screen.MAIN
            _statusMessage.value = "Signed in as $email"
        }
    }

    fun signOut() {
        authRepo.signOut()
        _currentScreen.value = Screen.MAIN
        _currentTab.value = NavigationTab.HOME
    }

    fun clearStatusMessage() {
        _statusMessage.value = null
    }
}
