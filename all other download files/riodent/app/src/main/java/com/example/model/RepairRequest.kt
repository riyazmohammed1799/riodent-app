package com.example.model

import com.example.model.AppConstants.STATUS_ACTIVE

data class RepairRequest(
    val requestId: String = "",
    val doctorUid: String = "",
    val doctorName: String = "",
    val clinicName: String = "",
    val mobileNumber: String = "",
    val issueDescription: String = "",
    val equipmentCategory: String = "Dental Chair",
    val imageUrls: List<String> = emptyList(),
    val address: String = "",
    val landmark: String = "",
    val city: String = "Hyderabad",
    val state: String = "Telangana",
    val latitude: Double = 17.3850,
    val longitude: Double = 78.4867,
    val status: String = STATUS_ACTIVE,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val completedAt: Long? = null,
    val cancelledAt: Long? = null,
    val completionOtp: String = "",
    // Outcome & Payment details (Service Taken vs Denied)
    val serviceOutcome: String? = null, // "service_taken" | "service_denied"
    val amountPaid: Double? = null,
    val paymentMode: String? = null, // "UPI", "Cash", "Card"
    val denialReason: String? = null,
    // Reserved for technician workflow in upcoming sprint:
    val technicianId: String? = null,
    val technicianName: String? = null,
    val technicianMobile: String? = null,
    val assignedAt: Long? = null,
    val assignmentStatus: String? = null
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "requestId" to requestId,
        "doctorUid" to doctorUid,
        "doctorName" to doctorName,
        "clinicName" to clinicName,
        "mobileNumber" to mobileNumber,
        "issueDescription" to issueDescription,
        "equipmentCategory" to equipmentCategory,
        "imageUrls" to imageUrls,
        "address" to address,
        "landmark" to landmark,
        "city" to city,
        "state" to state,
        "latitude" to latitude,
        "longitude" to longitude,
        "status" to status,
        "createdAt" to createdAt,
        "updatedAt" to updatedAt,
        "completedAt" to completedAt,
        "cancelledAt" to cancelledAt,
        "completionOtp" to completionOtp,
        "serviceOutcome" to serviceOutcome,
        "amountPaid" to amountPaid,
        "paymentMode" to paymentMode,
        "denialReason" to denialReason,
        "technicianId" to technicianId,
        "technicianName" to technicianName,
        "technicianMobile" to technicianMobile,
        "assignedAt" to assignedAt,
        "assignmentStatus" to assignmentStatus
    )

    companion object {
        @Suppress("UNCHECKED_CAST")
        fun fromMap(map: Map<String, Any?>): RepairRequest {
            return RepairRequest(
                requestId = map["requestId"] as? String ?: "",
                doctorUid = map["doctorUid"] as? String ?: "",
                doctorName = map["doctorName"] as? String ?: "",
                clinicName = map["clinicName"] as? String ?: "",
                mobileNumber = map["mobileNumber"] as? String ?: "",
                issueDescription = map["issueDescription"] as? String ?: "",
                equipmentCategory = map["equipmentCategory"] as? String ?: "Dental Chair",
                imageUrls = (map["imageUrls"] as? List<*>)?.filterIsInstance<String>() ?: emptyList(),
                address = map["address"] as? String ?: "",
                landmark = map["landmark"] as? String ?: "",
                city = map["city"] as? String ?: "Hyderabad",
                state = map["state"] as? String ?: "Telangana",
                latitude = (map["latitude"] as? Number)?.toDouble() ?: 17.3850,
                longitude = (map["longitude"] as? Number)?.toDouble() ?: 78.4867,
                status = map["status"] as? String ?: STATUS_ACTIVE,
                createdAt = (map["createdAt"] as? Number)?.toLong() ?: System.currentTimeMillis(),
                updatedAt = (map["updatedAt"] as? Number)?.toLong() ?: System.currentTimeMillis(),
                completedAt = (map["completedAt"] as? Number)?.toLong(),
                cancelledAt = (map["cancelledAt"] as? Number)?.toLong(),
                completionOtp = map["completionOtp"] as? String ?: "",
                serviceOutcome = map["serviceOutcome"] as? String?,
                amountPaid = (map["amountPaid"] as? Number)?.toDouble(),
                paymentMode = map["paymentMode"] as? String?,
                denialReason = map["denialReason"] as? String?,
                technicianId = map["technicianId"] as? String?,
                technicianName = map["technicianName"] as? String?,
                technicianMobile = map["technicianMobile"] as? String?,
                assignedAt = (map["assignedAt"] as? Number)?.toLong(),
                assignmentStatus = map["assignmentStatus"] as? String?
            )
        }
    }
}
