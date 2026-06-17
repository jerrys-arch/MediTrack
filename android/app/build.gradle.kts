plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.meditrack_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // 1. Enable Core Library Desugaring for Java 8+ features
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID.
        applicationId = "com.example.meditrack_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 2. Enable MultiDex to handle the larger method count from the notification library
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Add your own signing config for the release build.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // 3. The library that makes modern Java "time" features work on Android 11
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")

    // Your existing required annotation libraries
    implementation("com.google.errorprone:error_prone_annotations:2.10.0")
    implementation("javax.annotation:javax.annotation-api:1.3.2")
}