plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningRequired = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true) || it.contains("bundle", ignoreCase = true)
}

fun signingValue(vararg keys: String): String? {
    for (key in keys) {
        val gradleValue = providers.gradleProperty(key).orNull
        if (!gradleValue.isNullOrBlank()) return gradleValue

        val envValue = providers.environmentVariable(key).orNull
        if (!envValue.isNullOrBlank()) return envValue
    }
    return null
}

android {
    namespace = "com.chiempt.odoocrm"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.chiempt.odoocrm"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFilePath = signingValue("ANDROID_RELEASE_STORE_FILE", "RELEASE_STORE_FILE")
            val storePasswordValue = signingValue("ANDROID_RELEASE_STORE_PASSWORD", "RELEASE_STORE_PASSWORD")
            val keyAliasValue = signingValue("ANDROID_RELEASE_KEY_ALIAS", "RELEASE_KEY_ALIAS")
            val keyPasswordValue = signingValue("ANDROID_RELEASE_KEY_PASSWORD", "RELEASE_KEY_PASSWORD")

            if (!storeFilePath.isNullOrBlank()) {
                storeFile = file(storeFilePath)
            }
            if (!storePasswordValue.isNullOrBlank()) {
                storePassword = storePasswordValue
            }
            if (!keyAliasValue.isNullOrBlank()) {
                keyAlias = keyAliasValue
            }
            if (!keyPasswordValue.isNullOrBlank()) {
                keyPassword = keyPasswordValue
            }

            if (releaseSigningRequired) {
                val missing = mutableListOf<String>()
                if (storeFilePath.isNullOrBlank()) missing.add("ANDROID_RELEASE_STORE_FILE")
                if (storePasswordValue.isNullOrBlank()) missing.add("ANDROID_RELEASE_STORE_PASSWORD")
                if (keyAliasValue.isNullOrBlank()) missing.add("ANDROID_RELEASE_KEY_ALIAS")
                if (keyPasswordValue.isNullOrBlank()) missing.add("ANDROID_RELEASE_KEY_PASSWORD")
                if (missing.isNotEmpty()) {
                    throw GradleException(
                        "Missing Android release signing credentials: ${missing.joinToString(", ")}. " +
                            "Set as Gradle properties or environment variables before release builds.",
                    )
                }
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // Optimize release output for smaller, smoother production builds.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
