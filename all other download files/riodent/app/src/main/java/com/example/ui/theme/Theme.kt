package com.example.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val DarkColorScheme = darkColorScheme(
    primary = RioDentCyanGlow,
    onPrimary = RioDentNavyDark,
    primaryContainer = RioDentPrimaryDark,
    onPrimaryContainer = RioDentTealLight,
    secondary = RioDentGold,
    onSecondary = Color(0xFF451A03),
    secondaryContainer = Color(0xFF78350F),
    onSecondaryContainer = RioDentGoldLight,
    tertiary = RioDentGold,
    onTertiary = Color.White,
    background = RioDentBgNight,
    onBackground = RioDentTextPrimaryNight,
    surface = RioDentSurfaceNight,
    onSurface = RioDentTextPrimaryNight,
    surfaceVariant = RioDentSurfaceVariantNight,
    onSurfaceVariant = Color(0xFF94A3B8),
    outline = Color(0xFF263C50),
    outlineVariant = Color(0xFF1E3243)
)

private val LightColorScheme = lightColorScheme(
    primary = RioDentPrimary,
    onPrimary = Color.White,
    primaryContainer = RioDentTealLight,
    onPrimaryContainer = RioDentPrimaryDark,
    secondary = RioDentGoldDark,
    onSecondary = Color.White,
    secondaryContainer = RioDentGoldLight,
    onSecondaryContainer = Color(0xFF78350F),
    tertiary = RioDentNavy,
    onTertiary = Color.White,
    background = RioDentBg,
    onBackground = RioDentTextPrimary,
    surface = RioDentSurface,
    onSurface = RioDentTextPrimary,
    surfaceVariant = RioDentSurfaceVariant,
    onSurfaceVariant = RioDentTextSecondary,
    outline = RioDentBorder,
    outlineVariant = Color(0xFFCBD5E1)
)

@Composable
fun RioDentTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}

@Composable
fun MyApplicationTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit,
) {
    RioDentTheme(darkTheme = darkTheme, content = content)
}
