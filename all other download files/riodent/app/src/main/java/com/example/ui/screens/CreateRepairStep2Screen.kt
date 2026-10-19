package com.example.ui.screens

import android.Manifest
import android.content.Intent
import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
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
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Engineering
import androidx.compose.material.icons.filled.Key
import androidx.compose.material.icons.filled.KeyboardHide
import androidx.compose.material.icons.filled.LocationCity
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.PhoneInTalk
import androidx.compose.material.icons.filled.PinDrop
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
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.LocationHelper
import com.example.model.RepairRequest
import com.example.ui.CreateRequestDraft
import com.example.ui.theme.RioDentPrimary

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateRepairStep2Screen(
    draft: CreateRequestDraft,
    isLoading: Boolean,
    successRequest: RepairRequest?,
    onClinicInfoChange: (clinic: String, doctor: String, addr: String, land: String, mob: String) -> Unit,
    onDetectLocationClick: () -> Unit,
    onSelectHyderabadArea: (name: String, lat: Double, lng: Double) -> Unit,
    onSubmitClick: (clinic: String, doctor: String, addr: String, land: String, mob: String) -> Unit,
    onDismissSuccessDialog: () -> Unit,
    onBackClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    BackHandler(onBack = onBackClick)
    val context = LocalContext.current
    val keyboardController = LocalSoftwareKeyboardController.current
    val focusManager = LocalFocusManager.current

    var clinicName by remember { mutableStateOf(draft.clinicName) }
    var doctorName by remember { mutableStateOf(draft.doctorName) }
    var streetAddress by remember { mutableStateOf(draft.address.removeSuffix(", Hyderabad, Telangana").removeSuffix(", Hyderabad").trim()) }
    var landmark by remember { mutableStateOf(draft.landmark) }
    var mobileNumber by remember { mutableStateOf(draft.mobileNumber) }

    // Locked City requirement: Hyderabad, Telangana only (Non-changeable)
    val lockedCity = "Hyderabad, Telangana"

    fun getFullAddress(): String = if (streetAddress.isBlank()) lockedCity else "$streetAddress, $lockedCity"

    // Validation states
    var clinicNameError by remember { mutableStateOf<String?>(null) }
    var doctorNameError by remember { mutableStateOf<String?>(null) }
    var mobileNumberError by remember { mutableStateOf<String?>(null) }
    var addressError by remember { mutableStateOf<String?>(null) }

    fun notifyChanges() {
        onClinicInfoChange(clinicName, doctorName, getFullAddress(), landmark, mobileNumber)
    }

    fun validateAndSubmit() {
        var isValid = true
        if (clinicName.trim().isBlank()) {
            clinicNameError = "Please enter clinic name"
            isValid = false
        } else {
            clinicNameError = null
        }

        if (doctorName.trim().isBlank()) {
            doctorNameError = "Please enter doctor name"
            isValid = false
        } else {
            doctorNameError = null
        }

        val cleanMobileDigits = mobileNumber.filter { it.isDigit() }
        if (cleanMobileDigits.length < 10) {
            mobileNumberError = "Mobile number is mandatory (min 10 digits for technician on-site call)"
            isValid = false
        } else {
            mobileNumberError = null
        }

        if (streetAddress.trim().isBlank()) {
            addressError = "Please enter clinic street or area in Hyderabad"
            isValid = false
        } else {
            addressError = null
        }

        if (isValid) {
            focusManager.clearFocus()
            keyboardController?.hide()
            notifyChanges()
            onSubmitClick(clinicName.trim(), doctorName.trim(), getFullAddress().trim(), landmark.trim(), mobileNumber.trim())
        }
    }

    val locationPermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val fineGranted = permissions[Manifest.permission.ACCESS_FINE_LOCATION] ?: false
        val coarseGranted = permissions[Manifest.permission.ACCESS_COARSE_LOCATION] ?: false
        if (fineGranted || coarseGranted) {
            onDetectLocationClick()
        }
    }

    // Modal Confirmation Dialog: "Technician Booking Confirmed"
    if (successRequest != null) {
        AlertDialog(
            onDismissRequest = { /* force action */ },
            icon = {
                Box(
                    modifier = Modifier
                        .size(56.dp)
                        .clip(CircleShape)
                        .background(Color(0xFFDCFCE7)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.CheckCircle,
                        contentDescription = null,
                        tint = Color(0xFF15803D),
                        modifier = Modifier.size(36.dp)
                    )
                }
            },
            title = {
                Text(
                    text = "Technician Booking Confirmed!",
                    fontWeight = FontWeight.Black,
                    fontSize = 20.sp,
                    textAlign = TextAlign.Center
                )
            },
            text = {
                Column(
                    verticalArrangement = Arrangement.spacedBy(14.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Card(
                        shape = RoundedCornerShape(14.dp),
                        colors = CardDefaults.cardColors(containerColor = Color(0xFFE0F2FE)),
                        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFBAE6FD)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier.padding(14.dp),
                            verticalAlignment = Alignment.Top
                        ) {
                            Icon(
                                imageVector = Icons.Default.PhoneInTalk,
                                contentDescription = null,
                                tint = Color(0xFF0284C7),
                                modifier = Modifier.size(24.dp)
                            )
                            Spacer(modifier = Modifier.width(10.dp))
                            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                Text(
                                    text = "We Will Update You Shortly",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 14.sp,
                                    color = Color(0xFF0369A1)
                                )
                                Text(
                                    text = "An assigned technician will call you on ${successRequest.mobileNumber} to confirm equipment parts and on-site timing in Hyderabad.",
                                    fontSize = 13.sp,
                                    color = Color(0xFF075985),
                                    lineHeight = 18.sp
                                )
                            }
                        }
                    }

                    Card(
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(12.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text(
                                    text = "Repair Request ID",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = MaterialTheme.colorScheme.outline
                                )
                                Text(
                                    text = successRequest.requestId,
                                    fontSize = 20.sp,
                                    fontWeight = FontWeight.Black,
                                    color = Color(0xFF0F172A)
                                )
                            }
                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(Color(0xFFDCFCE7))
                                    .padding(horizontal = 8.dp, vertical = 4.dp)
                            ) {
                                Text(
                                    text = "Hyderabad Lead Active",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 11.sp,
                                    color = Color(0xFF15803D)
                                )
                            }
                        }
                    }

                    Card(
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = Color(0xFFFEF3C7)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier.padding(12.dp),
                            verticalAlignment = Alignment.Top
                        ) {
                            Icon(
                                imageVector = Icons.Default.Key,
                                contentDescription = null,
                                tint = Color(0xFFD97706),
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Column {
                                Text(
                                    text = "Completion OTP: ${successRequest.completionOtp}",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 14.sp,
                                    color = Color(0xFF92400E)
                                )
                                Text(
                                    text = "When service is taken, enter the amount paid and validate this OTP to close the ticket.",
                                    fontSize = 11.sp,
                                    color = Color(0xFF78350F),
                                    lineHeight = 15.sp
                                )
                            }
                        }
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = onDismissSuccessDialog,
                    colors = ButtonDefaults.buttonColors(containerColor = RioDentPrimary),
                    shape = RoundedCornerShape(10.dp),
                    modifier = Modifier.testTag("dismiss_success_button")
                ) {
                    Text("Go to Request Details & Track Call", fontWeight = FontWeight.Bold)
                }
            }
        )
    }

    Scaffold(
        modifier = Modifier
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
                            text = "Clinic Address & Location",
                            fontWeight = FontWeight.Bold,
                            fontSize = 18.sp
                        )
                        Text(
                            text = "Step 2 of 2: Hyderabad Location",
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
                        modifier = Modifier.testTag("step2_back_button")
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
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
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
                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                    modifier = Modifier.height(30.dp)
                ) {
                    Icon(Icons.Default.KeyboardHide, contentDescription = null, modifier = Modifier.size(14.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Dismiss Keyboard", fontSize = 11.sp)
                }
            }

            // Hyderabad Operational Notice Badge (Locked)
            Card(
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = Color(0xFFE0F2FE)),
                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFBAE6FD)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier.padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Lock,
                        contentDescription = "Locked City",
                        tint = Color(0xFF0284C7),
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(10.dp))
                    Column {
                        Text(
                            text = "Operating Exclusively in Hyderabad (Locked)",
                            fontWeight = FontWeight.Bold,
                            fontSize = 13.sp,
                            color = Color(0xFF0369A1)
                        )
                        Text(
                            text = "Service is active across Hyderabad, Telangana. City cannot be changed.",
                            fontSize = 11.sp,
                            color = Color(0xFF075985)
                        )
                    }
                }
            }

            // Quick Hyderabad Locality Chips
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(
                    text = "Quick Select Hyderabad Clinic Area",
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    contentPadding = PaddingValues(vertical = 2.dp)
                ) {
                    items(LocationHelper.HYDERABAD_AREAS) { (areaName, coords) ->
                        val areaShort = areaName.substringBefore(",")
                        val isSelected = streetAddress.contains(areaShort, ignoreCase = true)
                        FilterChip(
                            selected = isSelected,
                            onClick = {
                                focusManager.clearFocus()
                                keyboardController?.hide()
                                streetAddress = areaShort
                                onSelectHyderabadArea(areaShort, coords.first, coords.second)
                                notifyChanges()
                            },
                            label = { Text(areaShort, fontSize = 12.sp) },
                            leadingIcon = if (isSelected) {
                                { Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(14.dp)) }
                            } else null,
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
                                selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer
                            )
                        )
                    }
                }
            }

            // Clinic Name Field
            OutlinedTextField(
                value = clinicName,
                onValueChange = {
                    clinicName = it
                    if (it.isNotBlank()) clinicNameError = null
                    notifyChanges()
                },
                label = { Text("Clinic Name *") },
                isError = clinicNameError != null,
                supportingText = {
                    if (clinicNameError != null) {
                        Text(clinicNameError!!, color = MaterialTheme.colorScheme.error)
                    }
                },
                leadingIcon = {
                    Icon(imageVector = Icons.Default.Business, contentDescription = null)
                },
                placeholder = { Text("e.g. Apex Dental Hospital") },
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("clinic_name_input"),
                shape = RoundedCornerShape(12.dp),
                singleLine = true,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next)
            )

            // Doctor Name Field
            OutlinedTextField(
                value = doctorName,
                onValueChange = {
                    doctorName = it
                    if (it.isNotBlank()) doctorNameError = null
                    notifyChanges()
                },
                label = { Text("Doctor Name *") },
                isError = doctorNameError != null,
                supportingText = {
                    if (doctorNameError != null) {
                        Text(doctorNameError!!, color = MaterialTheme.colorScheme.error)
                    }
                },
                leadingIcon = {
                    Icon(imageVector = Icons.Default.Person, contentDescription = null)
                },
                placeholder = { Text("e.g. Dr. Rajesh Kulkarni, BDS") },
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("doctor_name_input"),
                shape = RoundedCornerShape(12.dp),
                singleLine = true,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next)
            )

            // Contact Mobile Number Field (Mandatory)
            OutlinedTextField(
                value = mobileNumber,
                onValueChange = {
                    mobileNumber = it
                    if (it.isNotBlank()) mobileNumberError = null
                    notifyChanges()
                },
                label = { Text("Contact Mobile Number (Mandatory) *") },
                isError = mobileNumberError != null,
                supportingText = {
                    if (mobileNumberError != null) {
                        Text(mobileNumberError!!, color = MaterialTheme.colorScheme.error)
                    } else {
                        Text("Mandatory: Technician will call this number before arrival in Hyderabad", fontSize = 11.sp)
                    }
                },
                leadingIcon = {
                    Icon(imageVector = Icons.Default.Phone, contentDescription = null)
                },
                placeholder = { Text("+91 98765 43210") },
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("mobile_number_input"),
                shape = RoundedCornerShape(12.dp),
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone, imeAction = ImeAction.Next)
            )

            // Street / Building Address in Hyderabad
            OutlinedTextField(
                value = streetAddress,
                onValueChange = {
                    streetAddress = it
                    if (it.isNotBlank()) addressError = null
                    notifyChanges()
                },
                label = { Text("Clinic Locality / Street Address in Hyderabad *") },
                isError = addressError != null,
                supportingText = {
                    if (addressError != null) {
                        Text(addressError!!, color = MaterialTheme.colorScheme.error)
                    } else {
                        Text("e.g. Road No. 1, Banjara Hills / Hitec City", fontSize = 11.sp)
                    }
                },
                leadingIcon = {
                    Icon(imageVector = Icons.Default.LocationOn, contentDescription = null)
                },
                placeholder = { Text("e.g. Road No. 1, Banjara Hills, Suite 304") },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(96.dp)
                    .testTag("address_input"),
                shape = RoundedCornerShape(12.dp),
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next)
            )

            // Locked Operational City (Hyderabad, Telangana)
            OutlinedTextField(
                value = lockedCity,
                onValueChange = { /* Locked */ },
                readOnly = true,
                enabled = false,
                label = { Text("Operational City (Locked to Hyderabad)") },
                leadingIcon = {
                    Icon(imageVector = Icons.Default.Lock, contentDescription = "Locked City", tint = Color(0xFF0284C7))
                },
                supportingText = {
                    Text("Currently operating in Hyderabad only.", color = Color(0xFF0369A1), fontSize = 11.sp)
                },
                modifier = Modifier.fillMaxWidth().testTag("locked_city_field"),
                shape = RoundedCornerShape(12.dp)
            )

            // Landmark Field
            OutlinedTextField(
                value = landmark,
                onValueChange = {
                    landmark = it
                    notifyChanges()
                },
                label = { Text("Hyderabad Landmark (Optional)") },
                leadingIcon = {
                    Icon(imageVector = Icons.Default.PinDrop, contentDescription = null)
                },
                placeholder = { Text("Near Care Hospital / Metro station...") },
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("landmark_input"),
                shape = RoundedCornerShape(12.dp),
                singleLine = true,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                keyboardActions = KeyboardActions(
                    onDone = {
                        focusManager.clearFocus()
                        keyboardController?.hide()
                    }
                )
            )

            // Real GPS Location Card
            Card(
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                ),
                border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(14.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                imageVector = Icons.Default.MyLocation,
                                contentDescription = null,
                                tint = RioDentPrimary,
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Clinic GPS Location",
                                fontWeight = FontWeight.Bold,
                                fontSize = 14.sp
                            )
                        }

                        OutlinedButton(
                            onClick = {
                                focusManager.clearFocus()
                                keyboardController?.hide()
                                locationPermissionLauncher.launch(
                                    arrayOf(
                                        Manifest.permission.ACCESS_FINE_LOCATION,
                                        Manifest.permission.ACCESS_COARSE_LOCATION
                                    )
                                )
                            },
                            shape = RoundedCornerShape(10.dp),
                            modifier = Modifier.testTag("detect_gps_button")
                        ) {
                            if (draft.isDetectingLocation) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(16.dp),
                                    strokeWidth = 2.dp
                                )
                            } else {
                                Text("Detect Live GPS", fontSize = 12.sp)
                            }
                        }
                    }

                    val hasCoords = draft.latitude != 0.0 && draft.longitude != 0.0
                    val displayLat = if (hasCoords) draft.latitude else 17.4156
                    val displayLng = if (hasCoords) draft.longitude else 78.4487

                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(8.dp))
                            .background(Color(0xFFDCFCE7))
                            .padding(horizontal = 10.dp, vertical = 8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = null,
                            tint = Color(0xFF15803D),
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Column {
                            Text(
                                text = "Coordinates: ${String.format("%.4f", displayLat)}° N, ${String.format("%.4f", displayLng)}° E (Hyderabad)",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF166534)
                            )
                            Text(
                                text = if (draft.locationStatusText.isNotBlank()) draft.locationStatusText else "Verified for Hyderabad technician on-site dispatch",
                                fontSize = 11.sp,
                                color = Color(0xFF14532D)
                            )
                        }
                    }

                    // Verify on Google Maps button
                    OutlinedButton(
                        onClick = {
                            val mapUri = Uri.parse("geo:$displayLat,$displayLng?q=$displayLat,$displayLng(RioDent+Clinic+Location)")
                            val intent = Intent(Intent.ACTION_VIEW, mapUri)
                            context.startActivity(intent)
                        },
                        modifier = Modifier.fillMaxWidth().height(36.dp),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Icon(Icons.Default.Map, contentDescription = null, modifier = Modifier.size(14.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Verify Coordinates on Google Maps", fontSize = 11.sp)
                    }
                }
            }

            // Primary Booking Action Button (Easily reachable by scrolling down, even with keyboard active)
            Button(
                onClick = {
                    focusManager.clearFocus()
                    keyboardController?.hide()
                    validateAndSubmit()
                },
                enabled = !isLoading,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(54.dp)
                    .testTag("submit_book_technician_button"),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(containerColor = RioDentPrimary)
            ) {
                if (isLoading) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Booking...", fontWeight = FontWeight.Bold)
                } else {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Engineering, contentDescription = null, modifier = Modifier.size(22.dp))
                        Spacer(modifier = Modifier.width(10.dp))
                        Text(
                            text = "Book Technician (Hyderabad)",
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }

            // Helper to dismiss keyboard
            OutlinedButton(
                onClick = {
                    focusManager.clearFocus()
                    keyboardController?.hide()
                },
                modifier = Modifier.fillMaxWidth().height(42.dp),
                shape = RoundedCornerShape(10.dp)
            ) {
                Icon(Icons.Default.KeyboardHide, contentDescription = null, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text("Dismiss Keyboard", fontSize = 13.sp)
            }

            // Generous spacing so user can scroll completely past keyboard and view the button
            Spacer(modifier = Modifier.height(140.dp))
        }
    }
}
