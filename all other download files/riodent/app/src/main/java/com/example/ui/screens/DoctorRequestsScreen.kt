package com.example.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.ui.draw.clip
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.HelpOutline
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.model.AppConstants.STATUS_ACTIVE
import com.example.model.AppConstants.STATUS_CANCELLED
import com.example.model.AppConstants.STATUS_COMPLETED
import com.example.model.RepairRequest
import com.example.ui.components.RequestCard
import com.example.ui.theme.RioDentPrimary

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DoctorRequestsScreen(
    requests: List<RepairRequest>,
    onRequestClick: (RepairRequest) -> Unit,
    onCreateClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    var selectedFilter by remember { mutableStateOf("all") }
    var searchQuery by remember { mutableStateOf("") }

    val filteredByStatus = when (selectedFilter) {
        "active" -> requests.filter { it.status == STATUS_ACTIVE }
        "completed" -> requests.filter { it.status == STATUS_COMPLETED }
        "cancelled" -> requests.filter { it.status == STATUS_CANCELLED }
        else -> requests
    }

    val finalRequests = if (searchQuery.isBlank()) {
        filteredByStatus
    } else {
        filteredByStatus.filter {
            it.equipmentCategory.contains(searchQuery, ignoreCase = true) ||
            it.issueDescription.contains(searchQuery, ignoreCase = true) ||
            it.requestId.contains(searchQuery, ignoreCase = true)
        }
    }

    Box(modifier = modifier.fillMaxSize()) {
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp),
            contentPadding = PaddingValues(top = 16.dp, bottom = 96.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            // Header Bar
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = "My Repair Requests",
                            fontWeight = FontWeight.Bold,
                            fontSize = 20.sp,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Text(
                            text = "Track technician status, amounts & closure OTPs",
                            fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }

                    // Total Count Badge
                    Card(
                        shape = RoundedCornerShape(10.dp),
                        colors = CardDefaults.cardColors(containerColor = RioDentPrimary.copy(alpha = 0.1f))
                    ) {
                        Text(
                            text = "${requests.size} Total",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            color = RioDentPrimary,
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)
                        )
                    }
                }
            }

            // Search Bar
            item {
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = { searchQuery = it },
                    placeholder = { Text("Search by equipment or issue...") },
                    leadingIcon = {
                        Icon(Icons.Default.Search, contentDescription = null, tint = RioDentPrimary)
                    },
                    trailingIcon = {
                        if (searchQuery.isNotEmpty()) {
                            IconButton(onClick = { searchQuery = "" }) {
                                Icon(Icons.Default.Close, contentDescription = "Clear")
                            }
                        }
                    },
                    singleLine = true,
                    shape = RoundedCornerShape(14.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("requests_search_bar")
                )
            }

            // Filter Chips Row
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf(
                        "all" to "All (${requests.size})",
                        "active" to "Active (${requests.count { it.status == STATUS_ACTIVE }})",
                        "completed" to "Completed (${requests.count { it.status == STATUS_COMPLETED }})",
                        "cancelled" to "Cancelled (${requests.count { it.status == STATUS_CANCELLED }})"
                    ).forEach { (key, label) ->
                        FilterChip(
                            selected = selectedFilter == key,
                            onClick = { selectedFilter = key },
                            label = { Text(label, fontSize = 11.sp, fontWeight = if (selectedFilter == key) FontWeight.Bold else FontWeight.Medium) }
                        )
                    }
                }
            }

            // List of Requests
            if (finalRequests.isEmpty()) {
                item {
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 24.dp),
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f)
                        )
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(32.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(54.dp)
                                    .clip(CircleShape)
                                    .background(RioDentPrimary.copy(alpha = 0.1f)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = if (selectedFilter == "active") Icons.Default.Build else Icons.Default.CheckCircle,
                                    contentDescription = null,
                                    tint = RioDentPrimary,
                                    modifier = Modifier.size(28.dp)
                                )
                            }
                            Spacer(modifier = Modifier.height(14.dp))
                            Text(
                                text = if (searchQuery.isNotEmpty()) "No matching repair requests"
                                else if (selectedFilter == "active") "No active repair requests"
                                else if (selectedFilter == "completed") "No completed requests yet"
                                else "No repair requests found",
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            Spacer(modifier = Modifier.height(6.dp))
                            Text(
                                text = if (searchQuery.isNotEmpty()) "Try a different search keyword like 'chair' or 'handpiece'."
                                else "Equipment broken? Tap 'Request Repair' below to dispatch a technician.",
                                fontSize = 12.sp,
                                textAlign = TextAlign.Center,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            } else {
                items(finalRequests, key = { it.requestId }) { req ->
                    RequestCard(
                        request = req,
                        onClick = { onRequestClick(req) }
                    )
                }
            }
        }

        // Floating Action Button to book technician
        ExtendedFloatingActionButton(
            onClick = onCreateClick,
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(16.dp)
                .testTag("requests_screen_fab"),
            containerColor = RioDentPrimary,
            contentColor = Color.White,
            shape = RoundedCornerShape(18.dp)
        ) {
            Icon(Icons.Default.Add, contentDescription = "Request Repair")
            Spacer(modifier = Modifier.width(8.dp))
            Text("Request Repair", fontWeight = FontWeight.Bold)
        }
    }
}
