package com.example

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AdminPanelSettings
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Engineering
import androidx.compose.material.icons.filled.ExitToApp
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.KeyboardHide
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.model.AppConstants.PREDEFINED_ADMIN_EMAIL
import com.example.model.AppConstants.ROLE_ADMIN
import com.example.ui.NavigationTab
import com.example.ui.RioDentViewModel
import com.example.ui.Screen
import com.example.ui.screens.AdminScreen
import com.example.ui.screens.AuthScreen
import com.example.ui.screens.CloseTicketOtpScreen
import com.example.ui.screens.CreateRepairStep1Screen
import com.example.ui.screens.CreateRepairStep2Screen
import com.example.ui.screens.DoctorHomeScreen
import com.example.ui.screens.DoctorProfileScreen
import com.example.ui.screens.DoctorRequestsScreen
import com.example.ui.screens.RequestDetailScreen
import com.example.ui.theme.RioDentNavy
import com.example.ui.theme.RioDentPrimary
import com.example.ui.theme.RioDentTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            RioDentTheme {
                RioDentApp()
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RioDentApp(
    viewModel: RioDentViewModel = viewModel()
) {
    val keyboardController = LocalSoftwareKeyboardController.current
    val focusManager = LocalFocusManager.current

    val currentUser by viewModel.currentUser.collectAsState()
    val doctorProfile by viewModel.currentDoctorProfile.collectAsState()
    val currentScreen by viewModel.currentScreen.collectAsState()
    val currentTab by viewModel.currentTab.collectAsState()
    val isAuthLoading by viewModel.isAuthLoading.collectAsState()
    val isRepairLoading by viewModel.isRepairLoading.collectAsState()
    val selectedRequest by viewModel.selectedRequest.collectAsState()
    val createDraft by viewModel.createDraft.collectAsState()
    val successRequest by viewModel.submissionSuccessRequest.collectAsState()
    val doctorRequests by viewModel.doctorRequests.collectAsState()
    val allRequests by viewModel.allRequests.collectAsState()
    val allDoctors by viewModel.allDoctors.collectAsState()
    val statusMessage by viewModel.statusMessage.collectAsState()
    val inAppNotification by viewModel.inAppNotification.collectAsState()
    val otpInput by viewModel.otpInput.collectAsState()
    val otpError by viewModel.otpError.collectAsState()

    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(statusMessage) {
        statusMessage?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearStatusMessage()
        }
    }

    val isAdmin = currentUser != null && (
        currentUser?.email?.trim().equals(PREDEFINED_ADMIN_EMAIL.trim(), ignoreCase = true) ||
        currentUser?.role == ROLE_ADMIN
    )

    // Robust Back Button Handling across all screens
    BackHandler(enabled = currentScreen != Screen.MAIN) {
        focusManager.clearFocus()
        keyboardController?.hide()
        when (currentScreen) {
            Screen.CREATE_STEP_2 -> viewModel.navigateTo(Screen.CREATE_STEP_1)
            Screen.CREATE_STEP_1 -> viewModel.navigateTo(Screen.MAIN)
            Screen.CLOSE_TICKET_OTP -> viewModel.navigateTo(Screen.REQUEST_DETAIL)
            Screen.REQUEST_DETAIL -> viewModel.navigateTo(Screen.MAIN)
            Screen.ADMIN_PANEL -> viewModel.navigateTo(Screen.MAIN)
            Screen.EDIT_PROFILE -> viewModel.navigateTo(Screen.MAIN)
            else -> viewModel.navigateTo(Screen.MAIN)
        }
    }

    // Back from secondary tab to Home tab in MAIN
    BackHandler(enabled = currentScreen == Screen.MAIN && currentTab != NavigationTab.HOME) {
        focusManager.clearFocus()
        keyboardController?.hide()
        viewModel.navigateToTab(NavigationTab.HOME)
    }

    // Unauthenticated State: Show Login Screen
    if (currentUser == null) {
        AuthScreen(
            viewModel = viewModel,
            isLoading = isAuthLoading
        )
        return
    }

    // Authenticated Flow
    Scaffold(
        modifier = Modifier
            .fillMaxSize()
            .pointerInput(Unit) {
                detectTapGestures(onTap = {
                    focusManager.clearFocus()
                    keyboardController?.hide()
                })
            }
            .imePadding(),
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            if (currentScreen == Screen.MAIN) {
                TopAppBar(
                    title = {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(
                                modifier = Modifier
                                    .size(34.dp)
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(Color(0xFF0F2438))
                                    .padding(4.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                Image(
                                    painter = painterResource(id = R.drawable.ic_technician_logo),
                                    contentDescription = "RioDent Technician Logo",
                                    modifier = Modifier.fillMaxSize()
                                )
                            }
                            Spacer(modifier = Modifier.width(10.dp))
                            Column {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text(
                                        text = "RioDent",
                                        fontWeight = FontWeight.Black,
                                        fontSize = 20.sp,
                                        color = RioDentPrimary
                                    )
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Box(
                                        modifier = Modifier
                                            .clip(RoundedCornerShape(6.dp))
                                            .background(RioDentPrimary.copy(alpha = 0.12f))
                                            .padding(horizontal = 6.dp, vertical = 2.dp)
                                    ) {
                                        Text(
                                            text = "Hyderabad",
                                            fontSize = 10.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = RioDentPrimary
                                        )
                                    }
                                }
                                Text(
                                    text = "Dental Equipment Service",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    },
                    actions = {
                        if (isAdmin) {
                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(Color(0xFF0F2438))
                                    .padding(horizontal = 8.dp, vertical = 4.dp)
                            ) {
                                Text(
                                    text = "ADMIN",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 10.sp,
                                    color = Color(0xFF38BDF8)
                                )
                            }
                        }
                        IconButton(
                            onClick = {
                                focusManager.clearFocus()
                                keyboardController?.hide()
                                viewModel.signOut()
                            },
                            modifier = Modifier.testTag("app_bar_sign_out")
                        ) {
                            Icon(
                                imageVector = Icons.Default.ExitToApp,
                                contentDescription = "Sign Out",
                                tint = MaterialTheme.colorScheme.outline
                            )
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = MaterialTheme.colorScheme.surface
                    )
                )
            }
        },
        bottomBar = {
            if (currentScreen == Screen.MAIN) {
                NavigationBar(
                    modifier = Modifier.testTag("main_bottom_nav"),
                    containerColor = MaterialTheme.colorScheme.surface
                ) {
                    if (isAdmin) {
                        // Admin Navigation: Requests & Registered Doctors (Zero Doctor Profile clutter)
                        NavigationBarItem(
                            selected = currentTab == NavigationTab.HOME || currentTab == NavigationTab.ADMIN,
                            onClick = {
                                focusManager.clearFocus()
                                keyboardController?.hide()
                                viewModel.navigateToTab(NavigationTab.ADMIN)
                            },
                            icon = {
                                BadgedBox(
                                    badge = {
                                        val activeCount = allRequests.count { it.status == "active" }
                                        if (activeCount > 0) {
                                            Badge { Text("$activeCount") }
                                        }
                                    }
                                ) {
                                    Icon(Icons.Default.Build, contentDescription = "Requests")
                                }
                            },
                            label = { Text("Requests") },
                            colors = NavigationBarItemDefaults.colors(
                                selectedIconColor = RioDentPrimary,
                                selectedTextColor = RioDentPrimary,
                                indicatorColor = MaterialTheme.colorScheme.primaryContainer
                            ),
                            modifier = Modifier.testTag("nav_admin_requests")
                        )

                        NavigationBarItem(
                            selected = currentTab == NavigationTab.REQUESTS,
                            onClick = {
                                focusManager.clearFocus()
                                keyboardController?.hide()
                                viewModel.navigateToTab(NavigationTab.REQUESTS)
                            },
                            icon = { Icon(Icons.Default.Engineering, contentDescription = "Doctors") },
                            label = { Text("Doctors") },
                            colors = NavigationBarItemDefaults.colors(
                                selectedIconColor = RioDentPrimary,
                                selectedTextColor = RioDentPrimary,
                                indicatorColor = MaterialTheme.colorScheme.primaryContainer
                            ),
                            modifier = Modifier.testTag("nav_admin_doctors")
                        )
                    } else {
                        // Doctor Navigation: Home, Requests, Profile
                        NavigationBarItem(
                            selected = currentTab == NavigationTab.HOME,
                            onClick = {
                                focusManager.clearFocus()
                                keyboardController?.hide()
                                viewModel.navigateToTab(NavigationTab.HOME)
                            },
                            icon = { Icon(Icons.Default.Home, contentDescription = "Home") },
                            label = { Text("Home") },
                            colors = NavigationBarItemDefaults.colors(
                                selectedIconColor = RioDentPrimary,
                                selectedTextColor = RioDentPrimary,
                                indicatorColor = MaterialTheme.colorScheme.primaryContainer
                            ),
                            modifier = Modifier.testTag("nav_home")
                        )

                        NavigationBarItem(
                            selected = currentTab == NavigationTab.REQUESTS,
                            onClick = {
                                focusManager.clearFocus()
                                keyboardController?.hide()
                                viewModel.navigateToTab(NavigationTab.REQUESTS)
                            },
                            icon = {
                                BadgedBox(
                                    badge = {
                                        val activeCount = doctorRequests.count { it.status == "active" }
                                        if (activeCount > 0) {
                                            Badge { Text("$activeCount") }
                                        }
                                    }
                                ) {
                                    Icon(Icons.Default.Build, contentDescription = "Requests")
                                }
                            },
                            label = { Text("Requests") },
                            colors = NavigationBarItemDefaults.colors(
                                selectedIconColor = RioDentPrimary,
                                selectedTextColor = RioDentPrimary,
                                indicatorColor = MaterialTheme.colorScheme.primaryContainer
                            ),
                            modifier = Modifier.testTag("nav_requests")
                        )

                        NavigationBarItem(
                            selected = currentTab == NavigationTab.PROFILE,
                            onClick = {
                                focusManager.clearFocus()
                                keyboardController?.hide()
                                viewModel.navigateToTab(NavigationTab.PROFILE)
                            },
                            icon = { Icon(Icons.Default.Person, contentDescription = "Profile") },
                            label = { Text("Profile") },
                            colors = NavigationBarItemDefaults.colors(
                                selectedIconColor = RioDentPrimary,
                                selectedTextColor = RioDentPrimary,
                                indicatorColor = MaterialTheme.colorScheme.primaryContainer
                            ),
                            modifier = Modifier.testTag("nav_profile")
                        )
                    }
                }
            }
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            when (currentScreen) {
                Screen.MAIN -> {
                    if (isAdmin) {
                        // Admin Console with Requests and Registered Doctors
                        AdminScreen(
                            currentUser = currentUser,
                            doctors = allDoctors,
                            requests = allRequests,
                            onRequestClick = { viewModel.selectRequest(it) },
                            onUpdateStatus = { reqId, newStatus, amt, reason ->
                                viewModel.adminUpdateStatusDirectly(reqId, newStatus, amt, reason)
                            },
                            onBackClick = null,
                            initialTab = if (currentTab == NavigationTab.REQUESTS) 1 else 0
                        )
                    } else {
                        when (currentTab) {
                            NavigationTab.HOME -> {
                                DoctorHomeScreen(
                                    doctorProfile = doctorProfile,
                                    requests = doctorRequests,
                                    onRequestClick = { viewModel.selectRequest(it) },
                                    onCreateClick = { viewModel.startCreateRequest() },
                                    onEditProfileClick = { viewModel.navigateToTab(NavigationTab.PROFILE) }
                                )
                            }
                            NavigationTab.REQUESTS -> {
                                DoctorRequestsScreen(
                                    requests = doctorRequests,
                                    onRequestClick = { viewModel.selectRequest(it) },
                                    onCreateClick = { viewModel.startCreateRequest() }
                                )
                            }
                            NavigationTab.PROFILE, NavigationTab.ADMIN -> {
                                DoctorProfileScreen(
                                    profile = doctorProfile,
                                    onSaveProfile = { doc, clinic, mob, addr, land ->
                                        viewModel.updateDoctorProfile(doc, clinic, mob, addr, land)
                                    },
                                    onSignOut = { viewModel.signOut() },
                                    onBackClick = { viewModel.navigateToTab(NavigationTab.HOME) }
                                )
                            }
                        }
                    }
                }

                Screen.CREATE_STEP_1 -> {
                    CreateRepairStep1Screen(
                        draft = createDraft,
                        onIssueDescriptionChange = { viewModel.updateIssueDescription(it) },
                        onEquipmentCategoryChange = { viewModel.updateEquipmentCategory(it) },
                        onImagesAdded = { viewModel.addImages(it) },
                        onImageRemoved = { viewModel.removeImage(it) },
                        onNextClick = { viewModel.navigateTo(Screen.CREATE_STEP_2) },
                        onBackClick = { viewModel.navigateTo(Screen.MAIN) }
                    )
                }

                Screen.CREATE_STEP_2 -> {
                    CreateRepairStep2Screen(
                        draft = createDraft,
                        isLoading = isRepairLoading,
                        successRequest = successRequest,
                        onClinicInfoChange = { clinic, doc, addr, land, mob ->
                            viewModel.updateClinicInfo(clinic, doc, addr, land, mob)
                        },
                        onDetectLocationClick = { viewModel.detectGpsLocation() },
                        onSelectHyderabadArea = { name, lat, lng ->
                            viewModel.selectHyderabadArea(name, lat, lng)
                        },
                        onSubmitClick = { clinic, doc, addr, land, mob ->
                            viewModel.submitRepairRequest(clinic, doc, mob, addr, land)
                        },
                        onDismissSuccessDialog = { viewModel.dismissSuccessDialog() },
                        onBackClick = { viewModel.navigateTo(Screen.CREATE_STEP_1) }
                    )
                }

                Screen.REQUEST_DETAIL -> {
                    selectedRequest?.let { req ->
                        RequestDetailScreen(
                            request = req,
                            isAdmin = isAdmin,
                            isLoading = isRepairLoading,
                            onProceedToOtpPage = { amount ->
                                viewModel.proceedToOtpClosure(amount)
                            },
                            onDenyService = { reason, amount ->
                                viewModel.recordServiceDenied(reason, amount)
                            },
                            onBackClick = { viewModel.navigateTo(Screen.MAIN) }
                        )
                    } ?: run {
                        viewModel.navigateTo(Screen.MAIN)
                    }
                }

                Screen.CLOSE_TICKET_OTP -> {
                    selectedRequest?.let { req ->
                        CloseTicketOtpScreen(
                            request = req,
                            isAdmin = isAdmin,
                            isLoading = isRepairLoading,
                            otpError = otpError,
                            onUpdateAmount = { newAmt ->
                                viewModel.updateAmountAndRegenerateOtp(newAmt)
                            },
                            onSendOtpNotification = { amt ->
                                viewModel.sendClosureOtpNotification(amt)
                            },
                            onCloseTicketWithOtp = { enteredOtp ->
                                viewModel.closeTicketWithOtp(enteredOtp)
                            },
                            onAdminCloseTicket = { enteredOtp ->
                                viewModel.adminCloseTicketWithOtp(enteredOtp)
                            },
                            onDenyService = { reason, amount ->
                                viewModel.recordServiceDenied(reason, amount)
                            },
                            onBackClick = { viewModel.navigateTo(Screen.REQUEST_DETAIL) }
                        )
                    } ?: run {
                        viewModel.navigateTo(Screen.MAIN)
                    }
                }

                Screen.ADMIN_PANEL -> {
                    AdminScreen(
                        currentUser = currentUser,
                        doctors = allDoctors,
                        requests = allRequests,
                        onRequestClick = { viewModel.selectRequest(it) },
                        onUpdateStatus = { reqId, newStatus, amt, reason ->
                            viewModel.adminUpdateStatusDirectly(reqId, newStatus, amt, reason)
                        },
                        onBackClick = { viewModel.navigateTo(Screen.MAIN) }
                    )
                }

                Screen.EDIT_PROFILE -> {
                    DoctorProfileScreen(
                        profile = doctorProfile,
                        onSaveProfile = { doc, clinic, mob, addr, land ->
                            viewModel.updateDoctorProfile(doc, clinic, mob, addr, land)
                        },
                        onSignOut = { viewModel.signOut() },
                        onBackClick = { viewModel.navigateTo(Screen.MAIN) }
                    )
                }
            }

            // Floating In-App Heads-Up Notification Banner (Simulating real device SMS / Push Notification)
            inAppNotification?.let { notifText ->
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp)
                        .align(Alignment.TopCenter),
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF0F172A)),
                    elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(modifier = Modifier.weight(1f), verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                Icons.Default.NotificationsActive,
                                contentDescription = null,
                                tint = Color(0xFF38BDF8),
                                modifier = Modifier.size(24.dp)
                            )
                            Spacer(modifier = Modifier.width(10.dp))
                            Column {
                                Text(
                                    text = "RioDent Notification",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 12.sp,
                                    color = Color(0xFF38BDF8)
                                )
                                Text(
                                    text = notifText,
                                    fontSize = 13.sp,
                                    color = Color.White,
                                    fontWeight = FontWeight.Medium
                                )
                            }
                        }

                        IconButton(
                            onClick = { viewModel.clearInAppNotification() },
                            modifier = Modifier.size(28.dp)
                        ) {
                            Icon(Icons.Default.Close, contentDescription = "Dismiss", tint = Color(0xFF94A3B8), modifier = Modifier.size(16.dp))
                        }
                    }
                }
            }
        }
    }
}
