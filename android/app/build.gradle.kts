plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.whisper"
    compileSdk = 35  // Flutter en az bunu destekliyor
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.whisper"
        minSdk = 26 // ✅ D8 hataları için en az 26
        targetSdk =  flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true // ✅ D8 fix
    }

    kotlinOptions {
        jvmTarget = "17" // Kotlin uyumlu hale getirdik
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.12.0"))
    implementation("com.google.firebase:firebase-analytics")

    // ✅ D8 için gerekli
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
