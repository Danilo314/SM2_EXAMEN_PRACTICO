plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.smii.sosmascota"
    compileSdk = flutter.compileSdkVersion
    // Use the highest NDK required by plugins (some plugins require NDK 27)
    ndkVersion = "27.0.12077973"

    // ✅ Habilita compatibilidad con Java moderno + desugaring
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // 👈 IMPORTANTE
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
    applicationId = "com.smii.sosmascota"
    // cloud_firestore and several Firebase plugins require minSdk 23 or higher
    minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true // 👈 por si usas muchas dependencias
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// 👇 AÑADE ESTE BLOQUE AL FINAL
dependencies {
    add("coreLibraryDesugaring", "com.android.tools:desugar_jdk_libs:2.1.5")
    add("implementation", "androidx.multidex:multidex:2.0.1")
}
