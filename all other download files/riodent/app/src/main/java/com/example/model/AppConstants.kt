package com.example.model

object AppConstants {
    const val ROLE_DOCTOR = "doctor"
    const val ROLE_ADMIN = "admin"

    // Predefined Admin Gmail account
    const val PREDEFINED_ADMIN_EMAIL = "riyaz.mohammed1799@gmail.com"

    // Request Statuses
    const val STATUS_ACTIVE = "active"
    const val STATUS_COMPLETED = "completed"
    const val STATUS_CANCELLED = "cancelled"

    // Firestore Collections
    const val COLLECTION_USERS = "users"
    const val COLLECTION_DOCTOR_PROFILES = "doctorProfiles"
    const val COLLECTION_REPAIR_REQUESTS = "repairRequests"

    // Storage Paths
    const val STORAGE_REPAIR_IMAGES = "repair_images"

    // Environments
    const val ENV_DEV = "riodent-dev"
    const val ENV_PROD = "riodent-prod"
}
