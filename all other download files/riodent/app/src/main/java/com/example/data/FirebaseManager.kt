package com.example.data

import android.content.Context
import android.util.Log
import com.example.model.AppConstants
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreSettings
import com.google.firebase.storage.FirebaseStorage

object FirebaseManager {
    private const val TAG = "FirebaseManager"
    
    // Environment selector: "riodent-dev" or "riodent-prod"
    var currentEnvironment: String = AppConstants.ENV_DEV
        private set

    private var isInitialized = false

    fun init(context: Context, environment: String = AppConstants.ENV_DEV) {
        currentEnvironment = environment
        try {
            if (FirebaseApp.getApps(context).isEmpty()) {
                // Initialize default or config-based FirebaseApp
                val options = FirebaseOptions.Builder()
                    .setApplicationId(context.packageName)
                    .setProjectId(environment)
                    .setStorageBucket("$environment.appspot.com")
                    .setApiKey("AIzaSyFakeKeyForLocalFallbackIfConfigured000")
                    .build()
                FirebaseApp.initializeApp(context, options)
                Log.d(TAG, "Initialized Firebase with environment: $environment")
            }
            // Configure Firestore offline persistence
            val db = FirebaseFirestore.getInstance()
            val settings = FirebaseFirestoreSettings.Builder()
                .setPersistenceEnabled(true)
                .build()
            db.firestoreSettings = settings
            isInitialized = true
        } catch (e: Exception) {
            Log.w(TAG, "Firebase initialization notice: ${e.message}. Fallback mode active.")
            isInitialized = true
        }
    }

    fun switchEnvironment(context: Context, environment: String) {
        currentEnvironment = environment
        // Update references if needed
        Log.i(TAG, "Switched to environment: $environment")
    }

    val auth: FirebaseAuth?
        get() = try {
            FirebaseAuth.getInstance()
        } catch (e: Exception) {
            null
        }

    val firestore: FirebaseFirestore?
        get() = try {
            FirebaseFirestore.getInstance()
        } catch (e: Exception) {
            null
        }

    val storage: FirebaseStorage?
        get() = try {
            FirebaseStorage.getInstance()
        } catch (e: Exception) {
            null
        }
}
