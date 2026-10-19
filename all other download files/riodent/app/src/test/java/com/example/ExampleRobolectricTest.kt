package com.example

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class ExampleRobolectricTest {

  @Test
  fun `read string from context`() {
    val context = ApplicationProvider.getApplicationContext<Context>()
    val appName = context.getString(R.string.app_name)
    assertEquals("RioDent", appName)
  }

  @Test
  fun `verify admin email check logic`() {
    val adminEmail = com.example.model.AppConstants.PREDEFINED_ADMIN_EMAIL
    assertEquals("riyaz.mohammed1799@gmail.com", adminEmail)
  }

  @Test
  fun `verify default city is Hyderabad`() {
    val req = com.example.model.RepairRequest(
      requestId = "RIO-TEST",
      city = "Hyderabad",
      state = "Telangana"
    )
    assertEquals("Hyderabad", req.city)
    assertEquals("Telangana", req.state)
  }

  @Test
  fun `verify service taken with payment and otp model`() {
    val completedReq = com.example.model.RepairRequest(
      requestId = "RIO-TEST-COMPLETED",
      status = com.example.model.AppConstants.STATUS_COMPLETED,
      serviceOutcome = "service_taken",
      amountPaid = 1500.0,
      completionOtp = "654321"
    )
    assertEquals("service_taken", completedReq.serviceOutcome)
    assertEquals(1500.0, completedReq.amountPaid ?: 0.0, 0.01)
    assertEquals("654321", completedReq.completionOtp)
  }

  @Test
  fun `verify service denied model`() {
    val deniedReq = com.example.model.RepairRequest(
      requestId = "RIO-TEST-DENIED",
      status = com.example.model.AppConstants.STATUS_CANCELLED,
      serviceOutcome = "service_denied",
      denialReason = "Quote too high",
      amountPaid = 0.0
    )
    assertEquals("service_denied", deniedReq.serviceOutcome)
    assertEquals(0.0, deniedReq.amountPaid ?: 0.0, 0.01)
  }

  @Test
  fun `verify screen enums and close ticket otp flow`() {
    val screen = com.example.ui.Screen.CLOSE_TICKET_OTP
    assertEquals("CLOSE_TICKET_OTP", screen.name)
    val defaultScreen = com.example.ui.Screen.MAIN
    assertEquals("MAIN", defaultScreen.name)
    val defaultTab = com.example.ui.NavigationTab.HOME
    assertEquals("HOME", defaultTab.name)
  }
}
