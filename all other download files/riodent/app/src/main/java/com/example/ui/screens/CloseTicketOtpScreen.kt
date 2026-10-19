package com.example.ui.screens

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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Block
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.CurrencyRupee
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Key
import androidx.compose.material.icons.filled.KeyboardHide
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
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
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.model.RepairRequest
import com.example.ui.theme.RioDentPrimary
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CloseTicketOtpScreen(
    request: RepairRequest,
    isAdmin: Boolean = false,
    isLoading: Boolean,
    otpError: String?,
    onUpdateAmount: (Double) -> Unit,
    onSendOtpNotification: (Double) -> Unit,
    onCloseTicketWithOtp: (enteredOtp: String) -> Unit,
    onAdminCloseTicket: ((enteredOtp: String) -> Unit)? = null,
    onDenyService: (reason: String, amountPaid: Double) -> Unit,
    onBackClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    BackHandler(onBack = onBackClick)
    val clipboardManager = LocalClipboardManager.current
    val keyboardController = LocalSoftwareKeyboardController.current
    val focusManager = LocalFocusManager.current

    val initialAmount = request.amountPaid?.let { String.format(Locale.US, "%.0f", it) } ?: "1500"
    var editableAmountInput by remember { mutableStateOf(initialAmount) }
    var isEditingAmount by remember { mutableStateOf(false) }
    var enteredOtpInput by remember { mutableStateOf("") }
    var localError by remember { mutableStateOf<String?>(null) }
    var showDenialDialog by remember { mutableStateOf(false) }

    // User requested: OTP should not be visible by default; comes as notification when clicked
    var isOtpRequested by remember { mutableStateOf(isAdmin) }
    var isOtpMasked by remember { mutableStateOf(!isAdmin) }

    var selectedDenialReason by remember { mutableStateOf("Quote too high / Fee dispute") }
    var customDenialNotes by remember { mutableStateOf("") }
    var denialFeeInput by remember { mutableStateOf("0") }

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
                    Column {
                        Text(
                            text = "Close Ticket & OTP",
                            fontWeight = FontWeight.Bold,
                            fontSize = 18.sp
                        )
                        Text(
                            text = "Request ${request.requestId}",
                            fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                },
                navigationIcon = {
                    IconButton(
                        onClick = {
                            focusManager.clearFocus()
                            keyboardController?.hide()
                            onBackClick()
                        },
                        modifier = Modifier.testTag("close_ticket_back_button")
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
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
        Column(
            modifier = modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Dismiss Keyboard Row
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

            // Request Overview Card
            Card(
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = request.requestId,
                            fontWeight = FontWeight.Black,
                            fontSize = 17.sp,
                            color = RioDentPrimary
                        )
                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(6.dp))
                                .background(Color(0xFFE0F2FE))
                                .padding(horizontal = 8.dp, vertical = 2.dp)
                        ) {
                            Text(request.equipmentCategory, fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color(0xFF0369A1))
                        }
                    }
                    Text(
                        text = "${request.doctorName} • ${request.clinicName}",
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 13.sp
                    )
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.LocationOn, contentDescription = null, tint = MaterialTheme.colorScheme.outline, modifier = Modifier.size(14.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(request.address, fontSize = 12.sp, color = MaterialTheme.colorScheme.outline)
                    }
                }
            }

            // Amount Paid Section (With Update Amount option)
            Card(
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = Color(0xFFF0FDF4)),
                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF86EFAC)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.CurrencyRupee, contentDescription = null, tint = Color(0xFF15803D), modifier = Modifier.size(20.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "Amount Paid by Doctor",
                                fontWeight = FontWeight.Bold,
                                fontSize = 15.sp,
                                color = Color(0xFF166534)
                            )
                        }

                        IconButton(
                            onClick = { isEditingAmount = !isEditingAmount },
                            modifier = Modifier.size(30.dp)
                        ) {
                            Icon(Icons.Default.Edit, contentDescription = "Edit Amount", tint = Color(0xFF15803D), modifier = Modifier.size(18.dp))
                        }
                    }

                    if (!isEditingAmount) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(
                                text = "₹${String.format(Locale.US, "%.0f", request.amountPaid ?: editableAmountInput.toDoubleOrNull() ?: 0.0)}",
                                fontWeight = FontWeight.Black,
                                fontSize = 28.sp,
                                color = Color(0xFF15803D)
                            )

                            OutlinedButton(
                                onClick = { isEditingAmount = true },
                                shape = RoundedCornerShape(8.dp),
                                modifier = Modifier.height(34.dp)
                            ) {
                                Text("Update Amount", fontSize = 11.sp)
                            }
                        }
                    } else {
                        // Editable Amount Input
                        OutlinedTextField(
                            value = editableAmountInput,
                            onValueChange = { editableAmountInput = it },
                            label = { Text("Update Amount Paid (₹)") },
                            leadingIcon = { Icon(Icons.Default.CurrencyRupee, contentDescription = null) },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number, imeAction = ImeAction.Done),
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                            shape = RoundedCornerShape(10.dp)
                        )

                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp), modifier = Modifier.fillMaxWidth()) {
                            listOf(500, 1000, 1500, 2500, 5000).forEach { preset ->
                                FilterChip(
                                    selected = editableAmountInput == preset.toString(),
                                    onClick = { editableAmountInput = preset.toString() },
                                    label = { Text("₹$preset", fontSize = 11.sp) }
                                )
                            }
                        }

                        Button(
                            onClick = {
                                val parsed = editableAmountInput.toDoubleOrNull() ?: 0.0
                                onUpdateAmount(parsed)
                                isEditingAmount = false
                            },
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF15803D)),
                            shape = RoundedCornerShape(8.dp),
                            modifier = Modifier.fillMaxWidth().height(40.dp)
                        ) {
                            Text("Save Amount & Refresh OTP", fontWeight = FontWeight.Bold, fontSize = 12.sp)
                        }
                    }
                }
            }

            // 6-Digit OTP Card (Protected and hidden from screen; received strictly as notification)
            Card(
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = if (isOtpRequested) Color(0xFFF0FDF4) else Color(0xFFF8FAFC)),
                border = androidx.compose.foundation.BorderStroke(1.5.dp, if (isOtpRequested) Color(0xFF86EFAC) else Color(0xFFCBD5E1)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                imageVector = if (isOtpRequested) Icons.Default.CheckCircle else Icons.Default.Lock,
                                contentDescription = null,
                                tint = if (isOtpRequested) Color(0xFF16A34A) else Color(0xFF64748B),
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "Confidential Closure OTP",
                                fontWeight = FontWeight.Bold,
                                fontSize = 14.sp,
                                color = if (isOtpRequested) Color(0xFF166534) else Color(0xFF334155)
                            )
                        }

                        if (isOtpRequested) {
                            OutlinedButton(
                                onClick = {
                                    val currentAmt = request.amountPaid ?: editableAmountInput.toDoubleOrNull() ?: 1500.0
                                    onSendOtpNotification(currentAmt)
                                },
                                shape = RoundedCornerShape(8.dp),
                                modifier = Modifier.height(30.dp)
                            ) {
                                Icon(Icons.Default.Refresh, contentDescription = "Resend", modifier = Modifier.size(12.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Resend", fontSize = 11.sp)
                            }
                        }
                    }

                    if (!isOtpRequested) {
                        // Pre-request state: OTP not sent yet
                        Text(
                            text = "OTP is confidential and never displayed on screen. Click below to generate the OTP and receive it instantly as a phone notification to authorize closing this ticket.",
                            fontSize = 12.sp,
                            color = Color(0xFF64748B),
                            lineHeight = 17.sp
                        )

                        Button(
                            onClick = {
                                val currentAmt = request.amountPaid ?: editableAmountInput.toDoubleOrNull() ?: 1500.0
                                onSendOtpNotification(currentAmt)
                                isOtpRequested = true
                            },
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0284C7)),
                            shape = RoundedCornerShape(10.dp),
                            modifier = Modifier.fillMaxWidth().height(46.dp).testTag("generate_otp_notification_button")
                        ) {
                            Icon(Icons.Default.NotificationsActive, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Generate OTP & Send Notification", fontWeight = FontWeight.Bold, fontSize = 13.sp)
                        }
                    } else {
                        // Post-request state: Sent via notification banner; not shown on screen
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color(0xFFDCFCE7))
                                .padding(horizontal = 10.dp, vertical = 8.dp)
                        ) {
                            Icon(Icons.Default.NotificationsActive, contentDescription = null, tint = Color(0xFF16A34A), modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Column {
                                Text(
                                    text = "OTP Dispatched as Phone Notification!",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFF166534)
                                )
                                Text(
                                    text = "Look at the top notification banner to view your 6-digit code. Enter it below to close this ticket.",
                                    fontSize = 11.sp,
                                    color = Color(0xFF15803D)
                                )
                            }
                        }

                        Text(
                            text = "• • • • • •",
                            fontSize = 28.sp,
                            fontWeight = FontWeight.Black,
                            fontFamily = FontFamily.Monospace,
                            color = Color(0xFF64748B),
                            letterSpacing = 8.sp,
                            modifier = Modifier.align(Alignment.CenterHorizontally).testTag("closure_screen_otp")
                        )
                    }
                }
            }

            // OTP Verification & Closure Section
            Card(
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text(
                        text = "Verify OTP to Close Ticket",
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp,
                        color = MaterialTheme.colorScheme.onSurface
                    )

                    OutlinedTextField(
                        value = enteredOtpInput,
                        onValueChange = {
                            enteredOtpInput = it
                            localError = null
                        },
                        label = { Text("Enter 6-Digit OTP from Notification") },
                        placeholder = { Text("6-digit code") },
                        leadingIcon = { Icon(Icons.Default.Key, contentDescription = null, tint = RioDentPrimary) },
                        isError = localError != null || !otpError.isNullOrBlank(),
                        supportingText = {
                            val err = localError ?: otpError
                            if (err != null) {
                                Text(err, color = MaterialTheme.colorScheme.error)
                            } else {
                                Text("Check the top notification banner to read the OTP", fontSize = 11.sp)
                            }
                        },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number, imeAction = ImeAction.Done),
                        keyboardActions = KeyboardActions(
                            onDone = {
                                focusManager.clearFocus()
                                keyboardController?.hide()
                            }
                        ),
                        singleLine = true,
                        shape = RoundedCornerShape(10.dp),
                        modifier = Modifier.fillMaxWidth().testTag("closure_otp_input")
                    )

                    // Button 1: Complete Service & Close Ticket
                    Button(
                        onClick = {
                            if (enteredOtpInput.trim().length != 6) {
                                localError = "Please enter the 6-digit OTP"
                                return@Button
                            }
                            focusManager.clearFocus()
                            keyboardController?.hide()
                            onCloseTicketWithOtp(enteredOtpInput.trim())
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF15803D)),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth().height(48.dp).testTag("verify_and_close_ticket_button")
                    ) {
                        if (isLoading) {
                            CircularProgressIndicator(color = Color.White, modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                        } else {
                            Icon(Icons.Default.CheckCircle, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Service Completed (Close Ticket)", fontWeight = FontWeight.Bold)
                        }
                    }

                    // Button 2: Service Cancelled / Denied
                    OutlinedButton(
                        onClick = { showDenialDialog = true },
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFFB91C1C)),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth().height(44.dp).testTag("service_cancelled_denied_button")
                    ) {
                        Icon(Icons.Default.Block, contentDescription = null, modifier = Modifier.size(16.dp), tint = Color(0xFFB91C1C))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Service Cancelled / Denied", fontWeight = FontWeight.SemiBold)
                    }
                }
            }

            Spacer(modifier = Modifier.height(100.dp))
        }
    }

    // Denial Dialog
    if (showDenialDialog) {
        AlertDialog(
            onDismissRequest = { showDenialDialog = false },
            title = { Text("Service Cancelled / Denied", fontWeight = FontWeight.Bold) },
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
