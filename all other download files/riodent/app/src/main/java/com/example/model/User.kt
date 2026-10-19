package com.example.model

import com.example.model.AppConstants.ROLE_DOCTOR

data class User(
    val uid: String = "",
    val email: String = "",
    val displayName: String = "",
    val photoURL: String = "",
    val role: String = ROLE_DOCTOR,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "uid" to uid,
        "email" to email,
        "displayName" to displayName,
        "photoURL" to photoURL,
        "role" to role,
        "createdAt" to createdAt,
        "updatedAt" to updatedAt
    )

    companion object {
        fun fromMap(map: Map<String, Any?>): User {
            return User(
                uid = map["uid"] as? String ?: "",
                email = map["email"] as? String ?: "",
                displayName = map["displayName"] as? String ?: "",
                photoURL = map["photoURL"] as? String ?: "",
                role = map["role"] as? String ?: ROLE_DOCTOR,
                createdAt = (map["createdAt"] as? Number)?.toLong() ?: System.currentTimeMillis(),
                updatedAt = (map["updatedAt"] as? Number)?.toLong() ?: System.currentTimeMillis()
            )
        }
    }
}
