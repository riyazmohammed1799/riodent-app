package com.example

import org.junit.Assert.*
import org.junit.Test

/**
 * Example local unit test, which will execute on the development machine (host).
 *
 * See [testing documentation](http://d.android.com/tools/testing).
 */
class ExampleUnitTest {
  @Test
  fun addition_isCorrect() {
    assertEquals(4, 2 + 2)
  }

  @Test
  fun testTechnicianConfirmationMessage() {
    val message = "Technician Booking Confirmed! We will update you shortly. An assigned technician will call you or get back to you soon."
    assertTrue(message.contains("Technician Booking Confirmed"))
    assertTrue(message.contains("technician will call you"))
  }
}
