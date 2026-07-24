plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.lexiora.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Extract native libraries (e.g. libpdfium.so, libsqlite3.so) at install
    // time so Dart FFI's DynamicLibrary.open('libpdfium.so') can resolve them
    // in RELEASE builds. Without this, release APKs store .so files
    // uncompressed and unextracted, so the bare-name dlopen fails at runtime —
    // which caused every PDF to fail to open in release while debug worked.
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Stable application ID for the Lexiora platform (Phase 1).
        applicationId = "com.lexiora.app"
        // minSdk 26 (Android 8.0): floor required by pdfrx / PDFium and by the
        // app's use of modern APIs. versionCode / versionName come from pubspec.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Phase 1 CI/dev builds are signed with the debug key so the release
            // APK is directly installable. Production release signing (an upload
            // keystore) is a Phase-1.x release task, tracked in ROADMAP.md.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
