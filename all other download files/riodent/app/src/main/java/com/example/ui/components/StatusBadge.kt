package com.example.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.model.AppConstants.STATUS_ACTIVE
import com.example.model.AppConstants.STATUS_CANCELLED
import com.example.model.AppConstants.STATUS_COMPLETED
import com.example.ui.theme.StatusActiveBg
import com.example.ui.theme.StatusActiveText
import com.example.ui.theme.StatusCancelledBg
import com.example.ui.theme.StatusCancelledText
import com.example.ui.theme.StatusCompletedBg
import com.example.ui.theme.StatusCompletedText

@Composable
fun StatusBadge(
    status: String,
    modifier: Modifier = Modifier
) {
    val (bgColor, textColor, label) = when (status.lowercase()) {
        STATUS_ACTIVE -> Triple(StatusActiveBg, StatusActiveText, "Active Lead")
        STATUS_COMPLETED -> Triple(StatusCompletedBg, StatusCompletedText, "Completed")
        STATUS_CANCELLED -> Triple(StatusCancelledBg, StatusCancelledText, "Cancelled")
        else -> Triple(Color(0xFFEEEEEE), Color(0xFF616161), status.replaceFirstChar { it.uppercase() })
    }

    Box(
        modifier = modifier
            .testTag("status_badge_${status.lowercase()}")
            .clip(RoundedCornerShape(8.dp))
            .background(bgColor)
            .padding(horizontal = 10.dp, vertical = 4.dp)
    ) {
        Text(
            text = label,
            color = textColor,
            fontSize = 12.sp,
            fontWeight = FontWeight.SemiBold
        )
    }
}
