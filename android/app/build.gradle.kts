import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.warn("google-services.json not found in android/app/, skipping com.google.gms.google-services application.")
}

android {
    namespace = "com.farmlink.agrimarketmob"
    compileSdk = 34
    // ndkVersion = flutter.ndkVersion

    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    val isSigningConfigured = keystorePropertiesFile.exists() && run {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
        keystoreProperties.containsKey("storeFile") &&
        keystoreProperties.containsKey("storePassword") &&
        keystoreProperties.containsKey("keyAlias") &&
        keystoreProperties.containsKey("keyPassword")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.farmlink.agrimarketmob"
        minSdk = 21
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        if (isSigningConfigured) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { rootProject.file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (isSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
                logger.warn("key.properties not found or incomplete. Falling back to debug signing config.")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
