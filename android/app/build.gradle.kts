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
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // On-device text recognition (OCR) for scanned/photographed PDF pages.
    // Fully on-device: the recognition model downloads once via Google Play
    // Services on first use, then runs completely offline — no API key, no
    // per-request cost, and no usage quota that can run out.
    implementation("com.google.mlkit:text-recognition:16.0.1")

    // Writes an invisible OCR text layer into a PDF's existing pages (the
    // same technique tools like OCRmyPDF use), so a scanned PDF becomes
    // selectable/translatable through the app's normal, already-working
    // text-selection system — no separate selection UI needed for OCR'd
    // pages. Apache 2.0, free, no server dependency.
    implementation("com.tom-roush:pdfbox-android:2.0.27.0")
}

flutter {
    source = "../.."
}
