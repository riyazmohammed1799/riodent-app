package com.example.ui.screens

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Block
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.CurrencyRupee
import androidx.compose.material.icons.filled.Engineering
import androidx.compose.material.icons.filled.KeyboardHide
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.Security
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SecondaryTabRow
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRowDefaults
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
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
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.R
import com.example.model.AppConstants.PREDEFINED_ADMIN_EMAIL
import com.example.model.AppConstants.ROLE_ADMIN
import com.example.model.AppConstants.STATUS_ACTIVE
import com.example.model.AppConstants.STATUS_CANCELLED
import com.example.model.AppConstants.STATUS_COMPLETED
import com.example.model.DoctorProfile
import com.example.model.RepairRequest
import com.example.model.User
import com.example.ui.theme.RioDentPrimary
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminScreen(
    currentUser: User?,
    doctors: List<DoctorProfile>,
    requests: List<RepairRequest>,
    onRequestClick: (RepairRequest) -> Unit,
    onUpdateStatus: ((requestId: String, newStatus: String, amount: Double?, reason: String?) -> Unit)? = null,
    onBackClick: (() -> Unit)? = null,
    initialTab: Int = 0,
    modifier: Modifier = Modifier
) {
    if (onBackClick != null) {
        BackHandler(onBack = onBackClick)
    }

    val focusManager = LocalFocusManager.current
    val keyboardController = LocalSoftwareKeyboardController.current

    val isAuthorized = currentUser != null && (
        currentUser.email.trim().equals(PREDEFINED_ADMIN_EMAIL.trim(), ignoreCase = true) ||
        currentUser.role == ROLE_ADMIN
    )

    if (!isAuthorized) {
        Box(
            modifier = modifier
                .fillMaxSize()
                .padding(24.dp),
            contentAlignment = Alignment.Center
        ) {
            Card(
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                elevation = CardDefaults.cardElevation(defaultElevation = 3.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(60.dp)
                            .clip(CircleShape)
                            .background(Color(0xFFFEE2E2)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Lock,
                            contentDescription = "Lock",
                            tint = Color(0xFFDC2626),
                            modifier = Modifier.size(36.dp)
                        )
                    }

                    Text(
                        text = "Access Denied",
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF991B1B)
                    )

                    Text(
                        text = "Only the single predefined Admin account ($PREDEFINED_ADMIN_EMAIL) is permitted to access the RioDent Admin Panel.",
                        textAlign = TextAlign.Center,
                        fontSize = 14.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    if (onBackClick != null) {
                        OutlinedButton(onClick = onBackClick) {
                            Text("Back to Home")
                        }
                    }
                }
            }
        }
        return
    }

    var selectedAdminTab by remember(initialTab) { mutableIntStateOf(initialTab) }
    var selectedFilterStatus by remember { mutableStateOf("all") }
    var showFirebaseAuthDialog by remember { mutableStateOf(false) }

    // Dialog state for changing status
    var requestToChangeStatus by remember { mutableStateOf<RepairRequest?>(null) }
    var statusDialogAction by remember { mutableStateOf<String?>(null) } // "complete" or "deny"
    var changeAmountInput by remember { mutableStateOf("1500") }
    var changeDenialReason by remember { mutableStateOf("Quote too high / Fee dispute") }
    var changeDenialFeeInput by remember { mutableStateOf("0") }

    val filteredRequests = when (selectedFilterStatus) {
        "active" -> requests.filter { it.status == STATUS_ACTIVE }
        "taken" -> requests.filter { it.status == STATUS_COMPLETED || it.serviceOutcome == "service_taken" }
        "denied" -> requests.filter { it.status == STATUS_CANCELLED || it.serviceOutcome == "service_denied" }
        else -> requests
    }

    val totalHyderabadRevenue = requests
        .filter { it.status == STATUS_COMPLETED }
        .mapNotNull { it.amountPaid }
        .sum()

    Scaffold(
        modifier = modifier
            .fillMaxSize()
            .pointerInput(Unit) {
                detectTapGestures(onTap = {
                    focusManager.clearFocus()
                    keyboardController?.hide()
                })
            },
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = "RioDent Admin Console",
                            fontWeight = FontWeight.Bold,
                            fontSize = 18.sp
                        )
                        Text(
                            text = "Hyderabad Technician Network Control",
                            fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                },
                navigationIcon = {
                    if (onBackClick != null) {
                        IconButton(
                            onClick = {
                                focusManager.clearFocus()
                                keyboardController?.hide()
                                onBackClick()
                            },
                            modifier = Modifier.testTag("admin_back_button")
                        ) {
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                                contentDescription = "Back"
                            )
                        }
                    }
                },
                actions = {
                    IconButton(
                        onClick = {
                            focusManager.clearFocus()
                            keyboardController?.hide()
                        }
                    ) {
                        Icon(
                            imageVector = Icons.Default.KeyboardHide,
                            contentDescription = "Hide Keyboard",
                            tint = MaterialTheme.colorScheme.outline
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        }
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = 16.dp),
            contentPadding = PaddingValues(top = 12.dp, bottom = 140.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Admin Badge & Total Revenue Summary Card
            item {
                Card(
                    shape = RoundedCornerShape(18.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Box(
                                    modifier = Modifier
                                        .size(38.dp)
                                        .clip(RoundedCornerShape(10.dp))
                                        .background(Color(0xFF0F2438))
                                        .padding(4.dp),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Image(
                                        painter = painterResource(id = R.drawable.ic_technician_logo),
                                        contentDescription = "Admin",
                                        modifier = Modifier.fillMaxSize()
                                    )
                                }
                                Spacer(modifier = Modifier.width(10.dp))
                                Column {
                                    Text(
                                        text = "RioDent Administrator",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 16.sp
                                    )
                                    Text(
                                        text = PREDEFINED_ADMIN_EMAIL,
                                        fontSize = 12.sp,
                                        color = MaterialTheme.colorScheme.outline
                                    )
                                }
                            }

                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(Color(0xFF0F2438))
                                    .padding(horizontal = 8.dp, vertical = 4.dp)
                            ) {
                                Text(
                                    text = "HYDERABAD",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 10.sp,
                                    color = Color(0xFF38BDF8)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(14.dp))

                        // Quick Stats Row
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Card(
                                modifier = Modifier.weight(1f),
                                shape = RoundedCornerShape(12.dp),
                                colors = CardDefaults.cardColors(containerColor = Color(0xFFFEF3C7))
                            ) {
                                Column(modifier = Modifier.padding(10.dp)) {
                                    Text("Active Leads", fontSize = 11.sp, color = Color(0xFF92400E))
                                    Text("${requests.count { it.status == STATUS_ACTIVE }}", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Color(0xFF78350F))
                                }
                            }

                            Card(
                                modifier = Modifier.weight(1f),
                                shape = RoundedCornerShape(12.dp),
                                colors = CardDefaults.cardColors(containerColor = Color(0xFFDCFCE7))
                            ) {
                                Column(modifier = Modifier.padding(10.dp)) {
                                    Text("Completed", fontSize = 11.sp, color = Color(0xFF166534))
                                    Text("${requests.count { it.status == STATUS_COMPLETED }}", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Color(0xFF15803D))
                                }
                            }

                            Card(
                                modifier = Modifier.weight(1f),
                                shape = RoundedCornerShape(12.dp),
                                colors = CardDefaults.cardColors(containerColor = Color(0xFFE0F2FE))
                            ) {
                                Column(modifier = Modifier.padding(10.dp)) {
                                    Text("Doctors", fontSize = 11.sp, color = Color(0xFF0369A1))
                                    Text("${doctors.size}", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Color(0xFF0284C7))
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        // Total Collected Amount
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(10.dp))
                                .background(Color(0xFFECFDF5))
                                .padding(horizontal = 12.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(Icons.Default.CurrencyRupee, contentDescription = null, tint = Color(0xFF059669), modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "Total Collected Amount: ₹${String.format(Locale.US, "%.0f", totalHyderabadRevenue)}",
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF047857)
                            )
                        }

                        Spacer(modifier = Modifier.height(10.dp))

                        OutlinedButton(
                            onClick = { showFirebaseAuthDialog = true },
                            modifier = Modifier.fillMaxWidth().height(36.dp).testTag("admin_firebase_auth_button"),
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Icon(Icons.Default.Security, contentDescription = null, modifier = Modifier.size(16.dp), tint = Color(0xFF0284C7))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("Check Firebase Auth & Cloud Setup", fontSize = 12.sp)
                        }
                    }
                }
            }

            // Tabs Selector: Repair Requests & Registered Doctors
            item {
                SecondaryTabRow(
                    selectedTabIndex = selectedAdminTab,
                    containerColor = Color.Transparent,
                    indicator = {
                        TabRowDefaults.SecondaryIndicator(
                            Modifier.tabIndicatorOffset(selectedAdminTab),
                            color = RioDentPrimary
                        )
                    }
                ) {
                    Tab(
                        selected = selectedAdminTab == 0,
                        onClick = { selectedAdminTab = 0 },
                        text = {
                            Text(
                                text = "Repair Requests (${requests.size})",
                                fontWeight = if (selectedAdminTab == 0) FontWeight.Bold else FontWeight.Medium,
                                color = if (selectedAdminTab == 0) RioDentPrimary else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    )
                    Tab(
                        selected = selectedAdminTab == 1,
                        onClick = { selectedAdminTab = 1 },
                        text = {
                            Text(
                                text = "Registered Doctors (${doctors.size})",
                                fontWeight = if (selectedAdminTab == 1) FontWeight.Bold else FontWeight.Medium,
                                color = if (selectedAdminTab == 1) RioDentPrimary else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    )
                }
            }

            // Tab 0: Repair Requests View
            if (selectedAdminTab == 0) {
                // Filter Chips
                item {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        listOf(
                            "all" to "All (${requests.size})",
                            "active" to "Active (${requests.count { it.status == STATUS_ACTIVE }})",
                            "taken" to "Completed (${requests.count { it.status == STATUS_COMPLETED }})",
                            "denied" to "Denied (${requests.count { it.status == STATUS_CANCELLED }})"
                        ).forEach { (key, label) ->
                            FilterChip(
                                selected = selectedFilterStatus == key,
                                onClick = { selectedFilterStatus = key },
                                label = { Text(label, fontSize = 11.sp) }
                            )
                        }
                    }
                }

                // Requests List
                if (filteredRequests.isEmpty()) {
                    item {
                        Card(
                            shape = RoundedCornerShape(12.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(
                                text = "No repair requests found for selected filter.",
                                color = MaterialTheme.colorScheme.outline,
                                fontSize = 13.sp,
                                modifier = Modifier.padding(20.dp),
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                } else {
                    items(filteredRequests, key = { it.requestId }) { req ->
                        val dateFormat = SimpleDateFormat("dd MMM yyyy, hh:mm a", Locale.getDefault())
                        val createdDate = dateFormat.format(Date(req.createdAt))

                        Card(
                            shape = RoundedCornerShape(16.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                            elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { onRequestClick(req) }
                                .testTag("admin_request_card_${req.requestId}")
                        ) {
                            Column(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(16.dp),
                                verticalArrangement = Arrangement.spacedBy(10.dp)
                            ) {
                                // Header Row: Request ID & Status Badge
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Icon(
                                            imageVector = Icons.Default.Build,
                                            contentDescription = null,
                                            tint = RioDentPrimary,
                                            modifier = Modifier.size(16.dp)
                                        )
                                        Spacer(modifier = Modifier.width(6.dp))
                                        Text(
                                            text = req.requestId,
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 14.sp
                                        )
                                    }

                                    // Status Badge
                                    val (statusBg, statusFg, statusText) = when (req.status) {
                                        STATUS_COMPLETED -> Triple(Color(0xFFDCFCE7), Color(0xFF15803D), "COMPLETED")
                                        STATUS_CANCELLED -> Triple(Color(0xFFFEE2E2), Color(0xFFB91C1C), "SERVICE DENIED")
                                        else -> Triple(Color(0xFFFEF3C7), Color(0xFFB45309), "ACTIVE")
                                    }

                                    Box(
                                        modifier = Modifier
                                            .clip(RoundedCornerShape(6.dp))
                                            .background(statusBg)
                                            .padding(horizontal = 8.dp, vertical = 3.dp)
                                    ) {
                                        Text(
                                            text = statusText,
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 11.sp,
                                            color = statusFg
                                        )
                                    }
                                }

                                // Clinic & Doctor Info
                                Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                    Text(
                                        text = req.clinicName,
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 15.sp,
                                        color = MaterialTheme.colorScheme.onSurface
                                    )
                                    Text(
                                        text = "${req.doctorName} • ${req.mobileNumber}",
                                        fontSize = 13.sp,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                    Text(
                                        text = "${req.equipmentCategory}: ${req.issueDescription}",
                                        fontSize = 12.sp,
                                        color = MaterialTheme.colorScheme.outline,
                                        maxLines = 2
                                    )
                                    Text(
                                        text = "${req.address}${if (req.landmark.isNotBlank()) ", Near ${req.landmark}" else ""}",
                                        fontSize = 12.sp,
                                        color = MaterialTheme.colorScheme.outline
                                    )
                                }

                                HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))

                                // Amount Section
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Column {
                                        when (req.status) {
                                            STATUS_COMPLETED -> {
                                                Text(
                                                    text = "Amount Collected: ₹${String.format(Locale.US, "%.0f", req.amountPaid ?: 0.0)}",
                                                    fontWeight = FontWeight.Bold,
                                                    fontSize = 14.sp,
                                                    color = Color(0xFF15803D)
                                                )
                                                Text("Service Completed", fontSize = 11.sp, color = Color(0xFF166534))
                                            }
                                            STATUS_CANCELLED -> {
                                                Text(
                                                    text = "Service Denied (Fee: ₹${String.format(Locale.US, "%.0f", req.amountPaid ?: 0.0)})",
                                                    fontWeight = FontWeight.Bold,
                                                    fontSize = 13.sp,
                                                    color = Color(0xFFB91C1C)
                                                )
                                                if (!req.denialReason.isNullOrBlank()) {
                                                    Text(
                                                        text = "Reason: ${req.denialReason}",
                                                        fontSize = 11.sp,
                                                        color = Color(0xFF991B1B)
                                                    )
                                                }
                                            }
                                            else -> {
                                                Text(
                                                    text = "Expected: ₹${String.format(Locale.US, "%.0f", req.amountPaid ?: 1500.0)}",
                                                    fontWeight = FontWeight.Bold,
                                                    fontSize = 13.sp,
                                                    color = Color(0xFF0369A1)
                                                )
                                                Text("Pending Technician Visit", fontSize = 11.sp, color = Color(0xFF0284C7))
                                            }
                                        }
                                    }
                                }

                                // Option to Change Status (Direct, no OTP)
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    if (req.status != STATUS_COMPLETED) {
                                        Button(
                                            onClick = {
                                                requestToChangeStatus = req
                                                statusDialogAction = "complete"
                                                changeAmountInput = req.amountPaid?.let { String.format(Locale.US, "%.0f", it) } ?: "1500"
                                            },
                                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF15803D)),
                                            shape = RoundedCornerShape(8.dp),
                                            modifier = Modifier.weight(1f).height(38.dp)
                                        ) {
                                            Icon(Icons.Default.CheckCircle, contentDescription = null, modifier = Modifier.size(16.dp))
                                            Spacer(modifier = Modifier.width(4.dp))
                                            Text("Completed", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                        }
                                    }

                                    if (req.status != STATUS_CANCELLED) {
                                        OutlinedButton(
                                            onClick = {
                                                requestToChangeStatus = req
                                                statusDialogAction = "deny"
                                                changeDenialFeeInput = "0"
                                                changeDenialReason = "Quote too high / Fee dispute"
                                            },
                                            colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFFB91C1C)),
                                            shape = RoundedCornerShape(8.dp),
                                            modifier = Modifier.weight(1f).height(38.dp)
                                        ) {
                                            Icon(Icons.Default.Block, contentDescription = null, modifier = Modifier.size(14.dp), tint = Color(0xFFB91C1C))
                                            Spacer(modifier = Modifier.width(4.dp))
                                            Text("Denied / Cancel", fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                                        }
                                    }

                                    if (req.status != STATUS_ACTIVE) {
                                        OutlinedButton(
                                            onClick = {
                                                onUpdateStatus?.invoke(req.requestId, STATUS_ACTIVE, null, null)
                                            },
                                            shape = RoundedCornerShape(8.dp),
                                            modifier = Modifier.weight(1f).height(38.dp)
                                        ) {
                                            Text("Set Active", fontSize = 12.sp)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                // Tab 1: Registered Doctors Directory
                items(doctors, key = { it.uid }) { doctor ->
                    val dateFormat = SimpleDateFormat("dd MMM yyyy", Locale.getDefault())
                    val regDate = dateFormat.format(Date(doctor.createdAt))
                    val doctorRequestsCount = requests.count { it.doctorUid == doctor.uid }

                    Card(
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                        modifier = Modifier.fillMaxWidth().testTag("doctor_card_${doctor.uid}")
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = doctor.doctorName,
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 16.sp,
                                        color = MaterialTheme.colorScheme.onSurface
                                    )
                                    Text(
                                        text = doctor.clinicName,
                                        fontWeight = FontWeight.SemiBold,
                                        fontSize = 13.sp,
                                        color = RioDentPrimary
                                    )
                                }
                                Box(
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(8.dp))
                                        .background(Color(0xFFE0F2FE))
                                        .padding(horizontal = 8.dp, vertical = 4.dp)
                                ) {
                                    Text(
                                        text = "$doctorRequestsCount Leads",
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = RioDentPrimary
                                    )
                                }
                            }

                            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))

                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.Phone, contentDescription = null, modifier = Modifier.size(15.dp), tint = RioDentPrimary)
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    text = doctor.mobileNumber.ifBlank { "Mobile not set" },
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.Medium,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                                Spacer(modifier = Modifier.width(12.dp))
                                Text("•", color = MaterialTheme.colorScheme.outline)
                                Spacer(modifier = Modifier.width(12.dp))
                                Text(doctor.email, fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }

                            Row(verticalAlignment = Alignment.Top) {
                                Icon(Icons.Default.LocationOn, contentDescription = null, modifier = Modifier.size(15.dp).padding(top = 2.dp), tint = MaterialTheme.colorScheme.outline)
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    text = "${doctor.address}${if (doctor.landmark.isNotBlank()) " (Near ${doctor.landmark})" else ""}",
                                    fontSize = 12.sp,
                                    color = MaterialTheme.colorScheme.outline,
                                    lineHeight = 16.sp
                                )
                            }

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "Joined $regDate",
                                    fontSize = 11.sp,
                                    color = MaterialTheme.colorScheme.outline
                                )
                                Text(
                                    text = "UID: ${doctor.uid}",
                                    fontSize = 10.sp,
                                    color = MaterialTheme.colorScheme.outlineVariant
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    // Modal Dialog: Change Status to Completed
    if (statusDialogAction == "complete" && requestToChangeStatus != null) {
        val targetReq = requestToChangeStatus!!
        AlertDialog(
            onDismissRequest = {
                statusDialogAction = null
                requestToChangeStatus = null
            },
            icon = {
                Icon(Icons.Default.CheckCircle, contentDescription = null, tint = Color(0xFF15803D), modifier = Modifier.size(32.dp))
            },
            title = {
                Text("Mark Service Completed", fontWeight = FontWeight.Bold)
            },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text("Clinic: ${targetReq.clinicName} (${targetReq.doctorName})", fontSize = 13.sp, fontWeight = FontWeight.Medium)
                    Text("Equipment: ${targetReq.equipmentCategory}", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)

                    OutlinedTextField(
                        value = changeAmountInput,
                        onValueChange = { changeAmountInput = it },
                        label = { Text("Amount Collected from Doctor (₹)") },
                        leadingIcon = { Icon(Icons.Default.CurrencyRupee, contentDescription = null) },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number, imeAction = ImeAction.Done),
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )

                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp), modifier = Modifier.fillMaxWidth()) {
                        listOf(500, 1000, 1500, 2000, 3000).forEach { preset ->
                            FilterChip(
                                selected = changeAmountInput == preset.toString(),
                                onClick = { changeAmountInput = preset.toString() },
                                label = { Text("₹$preset", fontSize = 11.sp) }
                            )
                        }
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        val amt = changeAmountInput.toDoubleOrNull() ?: 1500.0
                        onUpdateStatus?.invoke(targetReq.requestId, STATUS_COMPLETED, amt, null)
                        statusDialogAction = null
                        requestToChangeStatus = null
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF15803D))
                ) {
                    Text("Confirm & Redirect to Home")
                }
            },
            dismissButton = {
                OutlinedButton(onClick = {
                    statusDialogAction = null
                    requestToChangeStatus = null
                }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Modal Dialog: Change Status to Denied / Cancelled
    if (statusDialogAction == "deny" && requestToChangeStatus != null) {
        val targetReq = requestToChangeStatus!!
        AlertDialog(
            onDismissRequest = {
                statusDialogAction = null
                requestToChangeStatus = null
            },
            icon = {
                Icon(Icons.Default.Block, contentDescription = null, tint = Color(0xFFB91C1C), modifier = Modifier.size(32.dp))
            },
            title = {
                Text("Mark Service Denied / Cancelled", fontWeight = FontWeight.Bold)
            },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text("Clinic: ${targetReq.clinicName} (${targetReq.doctorName})", fontSize = 13.sp, fontWeight = FontWeight.Medium)
                    Text("Select denial reason:", fontSize = 12.sp, fontWeight = FontWeight.Bold)

                    listOf(
                        "Quote too high / Fee dispute",
                        "Spare parts unavailable",
                        "Equipment unrepairable",
                        "Resolved by clinic",
                        "Technician delayed"
                    ).forEach { opt ->
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { changeDenialReason = opt }
                                .padding(vertical = 2.dp)
                        ) {
                            RadioButton(selected = changeDenialReason == opt, onClick = { changeDenialReason = opt })
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(opt, fontSize = 12.sp)
                        }
                    }

                    OutlinedTextField(
                        value = changeDenialFeeInput,
                        onValueChange = { changeDenialFeeInput = it },
                        label = { Text("Fee Paid (₹) - 0 if none") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number, imeAction = ImeAction.Done),
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        val fee = changeDenialFeeInput.toDoubleOrNull() ?: 0.0
                        onUpdateStatus?.invoke(targetReq.requestId, STATUS_CANCELLED, fee, changeDenialReason)
                        statusDialogAction = null
                        requestToChangeStatus = null
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFB91C1C))
                ) {
                    Text("Confirm & Redirect to Home")
                }
            },
            dismissButton = {
                OutlinedButton(onClick = {
                    statusDialogAction = null
                    requestToChangeStatus = null
                }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Admin Firebase Auth & Cloud Firestore Verification Dialog
    if (showFirebaseAuthDialog) {
        AlertDialog(
            onDismissRequest = { showFirebaseAuthDialog = false },
            icon = {
                Icon(Icons.Default.Security, contentDescription = null, tint = RioDentPrimary, modifier = Modifier.size(32.dp))
            },
            title = {
                Text("Firebase Auth & Cloud Setup Status", fontWeight = FontWeight.Bold, fontSize = 16.sp)
            },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        text = "How to verify Firebase Auth in this system:",
                        fontWeight = FontWeight.Bold,
                        fontSize = 13.sp
                    )
                    Text(
                        text = "• Admin Account: $PREDEFINED_ADMIN_EMAIL\n" +
                                "• Current UID: ${currentUser?.uid ?: "admin_master_001"}\n" +
                                "• Role: ROLE_ADMIN (Full Console Permissions)\n" +
                                "• Live Requests in DB: ${requests.size}\n" +
                                "• Registered Doctors: ${doctors.size}\n\n" +
                                "To inspect in Google Firebase Console:\n" +
                                "1. Open console.firebase.google.com\n" +
                                "2. Go to 'Authentication' -> 'Users' to see authenticated doctors & admin.\n" +
                                "3. Go to 'Cloud Firestore' -> 'repair_requests' to view tickets, amount paid, and status.\n" +
                                "4. In production, place 'google-services.json' in app root for live multi-device sync.",
                        fontSize = 12.sp,
                        lineHeight = 17.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = { showFirebaseAuthDialog = false }) {
                    Text("Close")
                }
            }
        )
    }
}
