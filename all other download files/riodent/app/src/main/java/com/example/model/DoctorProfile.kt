package com.example.model

data class DoctorProfile(
    val uid: String = "",
    val doctorName: String = "",
    val clinicName: String = "",
    val mobileNumber: String = "",
    val address: String = "",
    val landmark: String = "",
    val latitude: Double = 0.0,
    val longitude: Double = 0.0,
    val email: String = "",
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "uid" to uid,
        "doctorName" to doctorName,
        "clinicName" to clinicName,
        "mobileNumber" to mobileNumber,
        "address" to address,
        "landmark" to landmark,
        "latitude" to latitude,
        "longitude" to longitude,
        "email" to email,
        "createdAt" to createdAt,
        "updatedAt" to updatedAt
    )

    companion object {
        fun fromMap(map: Map<String, Any?>): DoctorProfile {
            return DoctorProfile(
                uid = map["uid"] as? String ?: "",
                doctorName = map["doctorName"] as? String ?: "",
                clinicName = map["clinicName"] as? String ?: "",
                mobileNumber = map["mobileNumber"] as? String ?: "",
                address = map["address"] as? String ?: "",
                landmark = map["landmark"] as? String ?: "",
                latitude = (map["latitude"] as? Number)?.toDouble() ?: 0.0,
                longitude = (map["longitude"] as? Number)?.toDouble() ?: 0.0,
                email = map["email"] as? String ?: "",
                createdAt = (map["createdAt"] as? Number)?.toLong() ?: System.currentTimeMillis(),
                updatedAt = (map["updatedAt"] as? Number)?.toLong() ?: System.currentTimeMillis()
            )
        }
    }
}
