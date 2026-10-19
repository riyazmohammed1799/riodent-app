package com.example.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Block
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.CurrencyRupee
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.Key
import androidx.compose.material.icons.filled.KeyboardHide
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.PhoneInTalk
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import coil.compose.AsyncImage
import com.example.model.AppConstants.STATUS_ACTIVE
import com.example.model.AppConstants.STATUS_CANCELLED
import com.example.model.AppConstants.STATUS_COMPLETED
import com.example.model.RepairRequest
import com.example.ui.components.StatusBadge
import com.example.ui.theme.RioDentPrimary
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RequestDetailScreen(
    request: RepairRequest,
    isAdmin: Boolean,
    isLoading: Boolean,
    onProceedToOtpPage: (amountPaid: Double) -> Unit,
    onDenyService: (reason: String, amountPaid: Double) -> Unit,
    onBackClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    BackHandler(onBack = onBackClick)
    val context = LocalContext.current
    val keyboardController = LocalSoftwareKeyboardController.current
    val focusManager = LocalFocusManager.current

    var previewImageUrl by remember { mutableStateOf<String?>(null) }
    var showDenialDialog by remember { mutableStateOf(false) }

    // Amount input
    val defaultAmt = request.amountPaid?.let { String.format(Locale.US, "%.0f", it) } ?: "1500"
    var amountPaidInput by remember { mutableStateOf(defaultAmt) }
    var amountError by remember { mutableStateOf<String?>(null) }

    // Denial dialog states
    var selectedDenialReason by remember { mutableStateOf("Quote too high / Fee dispute") }
    var customDenialNotes by remember { mutableStateOf("") }
    var denialFeeInput by remember { mutableStateOf("0") }

    val dateFormat = SimpleDateFormat("dd MMM yyyy, hh:mm a", Locale.getDefault())
    val createdStr = dateFormat.format(Date(request.createdAt))
    val completedStr = request.completedAt?.let { dateFormat.format(Date(it)) }
    val cancelledStr = request.cancelledAt?.let { dateFormat.format(Date(it)) }

    // Image Zoom Dialog
    if (previewImageUrl != null) {
        Dialog(onDismissRequest = { previewImageUrl = null }) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(Color.Black)
                    .padding(8.dp)
            ) {
                AsyncImage(
                    model = previewImageUrl,
                    contentDescription = "Full photo",
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(380.dp),
                    contentScale = ContentScale.Fit
                )
            }
        }
    }

    Scaffold(
        modifier = Modifier
            .fillMaxSize()
            .imePadding()
            .pointerInput(Unit) {
                detectTapGestures(onTap = {
                    focusManager.clearFocus()
                    keyboardController?.hide()
                })
            },
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Request ${request.requestId}",
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp
                    )
                },
                navigationIcon = {
                    IconButton(
                        onClick = onBackClick,
                        modifier = Modifier.testTag("detail_back_button")
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                actions = {
                    StatusBadge(status = request.status, modifier = Modifier.padding(end = 12.dp))
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        }
    ) { innerPadding ->
        Column(
            modifier = modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Dismiss Keyboard button
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.End
            ) {
                OutlinedButton(
                    onClick = {
                        focusManager.clearFocus()
                        keyboardController?.hide()
                    },
                    shape = RoundedCornerShape(8.dp),
                    contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                    modifier = Modifier.height(30.dp)
                ) {
                    Icon(Icons.Default.KeyboardHide, contentDescription = null, modifier = Modifier.size(14.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Dismiss Keyboard", fontSize = 11.sp)
                }
            }

            // Technician Booking Confirmed Banner
            if (request.status == STATUS_ACTIVE) {
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFFE0F2FE)),
                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFBAE6FD)),
                    modifier = Modifier.fillMaxWidth().testTag("tech_confirmed_banner")
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(
                                modifier = Modifier
                                    .size(38.dp)
                                    .clip(CircleShape)
                                    .background(Color(0xFF0284C7)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Default.PhoneInTalk,
                                    contentDescription = null,
                                    tint = Color.White,
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                            Spacer(modifier = Modifier.width(10.dp))
                            Column {
                                Text(
                                    text = "Technician Booking Active",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 15.sp,
                                    color = Color(0xFF0369A1)
                                )
                                Text(
                                    text = "Hyderabad Technician Assigned",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = Color(0xFF0284C7)
                                )
                            }
                        }

                        Text(
                            text = "An assigned technician will call or visit ${request.clinicName} on-site in Hyderabad.",
                            fontSize = 13.sp,
                            color = Color(0xFF075985)
                        )
                    }
                }
            }

            // Outcome Badges for Closed Requests (Doctor History)
            if (request.status == STATUS_COMPLETED) {
                Card(
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFFDCFCE7)),
                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF86EFAC)),
                    modifier = Modifier.fillMaxWidth().testTag("service_taken_card")
                ) {
                    Column(
                        modifier = Modifier.padding(14.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.CheckCircle, contentDescription = null, tint = Color(0xFF15803D), modifier = Modifier.size(22.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Service Completed & Ticket Closed", fontWeight = FontWeight.Bold, fontSize = 16.sp, color = Color(0xFF15803D))
                        }
                        if (request.amountPaid != null && request.amountPaid > 0) {
                            Text(
                                text = "Amount Paid by Doctor: ₹${String.format(Locale.US, "%.0f", request.amountPaid)}",
                                fontWeight = FontWeight.Black,
                                fontSize = 16.sp,
                                color = Color(0xFF166534)
                            )
                        }
                        Text("Validated with OTP: ${request.completionOtp}", fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = Color(0xFF0369A1))
                        Text("Official closure recorded on $completedStr", fontSize = 12.sp, color = Color(0xFF14532D))
                    }
                }
            } else if (request.status == STATUS_CANCELLED) {
                Card(
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFFFEE2E2)),
                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFFCA5A5)),
                    modifier = Modifier.fillMaxWidth().testTag("service_denied_card")
                ) {
                    Column(
                        modifier = Modifier.padding(14.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Block, contentDescription = null, tint = Color(0xFFB91C1C), modifier = Modifier.size(22.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Service Cancelled / Denied", fontWeight = FontWeight.Bold, fontSize = 16.sp, color = Color(0xFFB91C1C))
                        }
                        if (!request.denialReason.isNullOrBlank()) {
                            Text("Reason: ${request.denialReason}", fontSize = 13.sp, color = Color(0xFF991B1B))
                        }
                        val fee = request.amountPaid ?: 0.0
                        Text("Amount Paid: ₹${String.format(Locale.US, "%.0f", fee)}", fontSize = 13.sp, color = Color(0xFF7F1D1D))
                        Text("Ticket closed on $cancelledStr", fontSize = 12.sp, color = Color(0xFF7F1D1D))
                    }
                }
            }

            // PRIMARY ACTION SECTION FOR ACTIVE TICKETS: Enter Amount & Proceed to Next Page for OTP Verification
            if (request.status == STATUS_ACTIVE) {
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                    elevation = CardDefaults.cardElevation(defaultElevation = 3.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Text(
                            text = "Ticket Resolution & Payment",
                            fontWeight = FontWeight.Bold,
                            fontSize = 16.sp,
                            color = MaterialTheme.colorScheme.onSurface
                        )

                        Text(
                            text = "Type the amount paid to the technician. On the next page, you will verify with OTP to officially close this ticket and save the amount.",
                            fontSize = 13.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            lineHeight = 18.sp
                        )

                        // Amount Paid Input (No payment mode options - direct cash/UPI between doc and tech)
                        OutlinedTextField(
                            value = amountPaidInput,
                            onValueChange = {
                                amountPaidInput = it
                                if (it.isNotBlank()) amountError = null
                            },
                            label = { Text("Amount Paid to Technician (₹) *") },
                            leadingIcon = {
                                Icon(Icons.Default.CurrencyRupee, contentDescription = null, tint = RioDentPrimary)
                            },
                            isError = amountError != null,
                            supportingText = {
                                if (amountError != null) {
                                    Text(amountError!!, color = MaterialTheme.colorScheme.error)
                                } else {
                                    Text("Enter total fee paid to technician (for history & closure)", fontSize = 11.sp)
                                }
                            },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number, imeAction = ImeAction.Done),
                            keyboardActions = KeyboardActions(
                                onDone = {
                                    focusManager.clearFocus()
                                    keyboardController?.hide()
                                }
                            ),
                            modifier = Modifier.fillMaxWidth().testTag("amount_paid_input"),
                            singleLine = true,
                            shape = RoundedCornerShape(10.dp)
                        )

                        // Quick Amount Chips
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(6.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            listOf(500, 1000, 1500, 2500, 5000).forEach { preset ->
                                FilterChip(
                                    selected = amountPaidInput == preset.toString(),
                                    onClick = {
                                        amountPaidInput = preset.toString()
                                        amountError = null
                                    },
                                    label = { Text("₹$preset", fontSize = 11.sp) },
                                    colors = FilterChipDefaults.filterChipColors(
                                        selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
                                        selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer
                                    )
                                )
                            }
                        }

                        // Proceed to OTP Verification (Next Page)
                        Button(
                            onClick = {
                                val amount = amountPaidInput.toDoubleOrNull()
                                if (amount == null || amount < 0) {
                                    amountError = "Please enter valid payment amount"
                                    return@Button
                                }
                                focusManager.clearFocus()
                                keyboardController?.hide()
                                onProceedToOtpPage(amount)
                            },
                            modifier = Modifier.fillMaxWidth().height(50.dp).testTag("proceed_to_otp_page_button"),
                            shape = RoundedCornerShape(12.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF15803D))
                        ) {
                            Icon(Icons.Default.Key, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Proceed to OTP & Close Ticket (Next Page)",
                                fontWeight = FontWeight.Bold,
                                fontSize = 13.sp
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = null, modifier = Modifier.size(16.dp))
                        }

                        // Option 2: Service Cancelled / Denied
                        OutlinedButton(
                            onClick = { showDenialDialog = true },
                            modifier = Modifier.fillMaxWidth().height(42.dp).testTag("service_denied_button"),
                            shape = RoundedCornerShape(10.dp),
                            colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFFB91C1C))
                        ) {
                            Icon(Icons.Default.Block, contentDescription = null, modifier = Modifier.size(16.dp), tint = Color(0xFFB91C1C))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Service Cancelled / Denied", fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                        }
                    }
                }
            }

            // Equipment & Malfunction Details Card
            Card(
                shape = RoundedCornerShape(16.dp),
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
                            Icon(
                                imageVector = Icons.Default.Build,
                                contentDescription = null,
                                tint = RioDentPrimary,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = request.equipmentCategory,
                                fontWeight = FontWeight.Bold,
                                fontSize = 15.sp,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        }

                        Text(
                            text = createdStr,
                            fontSize = 11.sp,
                            color = MaterialTheme.colorScheme.outline
                        )
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    Text(
                        text = "Reported Malfunction",
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 13.sp,
                        color = MaterialTheme.colorScheme.outline
                    )

                    Spacer(modifier = Modifier.height(4.dp))

                    Text(
                        text = request.issueDescription,
                        fontSize = 14.sp,
                        lineHeight = 22.sp,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }
            }

            // Uploaded Photos
            if (request.imageUrls.isNotEmpty()) {
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                imageVector = Icons.Default.Image,
                                contentDescription = null,
                                tint = RioDentPrimary,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "Uploaded Photos (${request.imageUrls.size})",
                                fontWeight = FontWeight.Bold,
                                fontSize = 14.sp
                            )
                        }

                        Spacer(modifier = Modifier.height(10.dp))

                        LazyRow(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            items(request.imageUrls) { url ->
                                AsyncImage(
                                    model = url,
                                    contentDescription = "Equipment Photo",
                                    modifier = Modifier
                                        .size(110.dp)
                                        .clip(RoundedCornerShape(12.dp))
                                        .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(12.dp))
                                        .clickable { previewImageUrl = url },
                                    contentScale = ContentScale.Crop
                                )
                            }
                        }
                    }
                }
            }

            // Clinic & Contact Details Card
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Text(
                        text = "Clinic & Location Details (Hyderabad)",
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp,
                        color = MaterialTheme.colorScheme.onSurface
                    )

                    Text(
                        text = "${request.doctorName} • ${request.clinicName}",
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 14.sp,
                        color = RioDentPrimary
                    )

                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.LocationOn,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = request.address + if (request.landmark.isNotBlank()) " (Near ${request.landmark})" else "",
                            fontSize = 13.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }

                    // Mobile Dialer Row
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                imageVector = Icons.Default.Phone,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = request.mobileNumber.ifBlank { "Mobile not set" },
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Medium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }

                        if (request.mobileNumber.isNotBlank()) {
                            OutlinedButton(
                                onClick = {
                                    val intent = Intent(Intent.ACTION_DIAL).apply {
                                        data = Uri.parse("tel:${request.mobileNumber}")
                                    }
                                    context.startActivity(intent)
                                },
                                shape = RoundedCornerShape(8.dp),
                                modifier = Modifier.testTag("call_doctor_button")
                            ) {
                                Text("Call", fontSize = 12.sp)
                            }
                        }
                    }

                    // Google Maps Button
                    if (request.latitude != 0.0 && request.longitude != 0.0) {
                        OutlinedButton(
                            onClick = {
                                val gmmIntentUri = Uri.parse("geo:${request.latitude},${request.longitude}?q=${request.latitude},${request.longitude}(${Uri.encode(request.clinicName)})")
                                val mapIntent = Intent(Intent.ACTION_VIEW, gmmIntentUri)
                                context.startActivity(mapIntent)
                            },
                            modifier = Modifier.fillMaxWidth().testTag("open_maps_button"),
                            shape = RoundedCornerShape(10.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Map,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Open Clinic in Google Maps", fontSize = 13.sp)
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(80.dp))
        }
    }

    // Denial Dialog
    if (showDenialDialog) {
        AlertDialog(
            onDismissRequest = { showDenialDialog = false },
            title = { Text("Record Service Cancelled / Denied", fontWeight = FontWeight.Bold) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Select reason:", fontSize = 13.sp)
                    listOf(
                        "Quote too high / Fee dispute",
                        "Spare parts unavailable",
                        "Equipment unrepairable",
                        "Resolved by clinic",
                        "Technician delayed"
                    ).forEach { opt ->
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.fillMaxWidth().clickable { selectedDenialReason = opt }.padding(vertical = 2.dp)
                        ) {
                            RadioButton(selected = selectedDenialReason == opt, onClick = { selectedDenialReason = opt })
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(opt, fontSize = 12.sp)
                        }
                    }
                    OutlinedTextField(
                        value = denialFeeInput,
                        onValueChange = { denialFeeInput = it },
                        label = { Text("Fee Paid (₹) - 0 if none") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        val fee = denialFeeInput.toDoubleOrNull() ?: 0.0
                        onDenyService(selectedDenialReason, fee)
                        showDenialDialog = false
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFB91C1C))
                ) {
                    Text("Confirm Cancellation")
                }
            },
            dismissButton = {
                OutlinedButton(onClick = { showDenialDialog = false }) { Text("Back") }
            }
        )
    }
}
