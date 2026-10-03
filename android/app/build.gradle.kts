import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing reads android/key.properties (never committed — see
// .gitignore). Release builds fail when the production keystore is absent;
// they never fall back to the Android debug key. See android/KEYSTORE.md.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (!hasReleaseKeystore) {
    throw GradleException(
        "Missing android/key.properties. A production release keystore is required; " +
            "release builds must never use the Android debug key.",
    )
}
keystoreProperties.load(keystorePropertiesFile.inputStream())

android {
    namespace = "com.sapiora.app"
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
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Stable application ID for the Sapiora app. This is permanent once
        // published to the Play Store — never change it after the first
        // release (doing so publishes as a brand-new, unrelated app listing).
        applicationId = "com.sapiora.app"
        // minSdk 26 (Android 8.0): floor required by pdfrx / PDFium and by the
        // app's use of modern APIs. versionCode / versionName come from pubspec.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobAppId"] =
            "ca-app-pub-3940256099942544~3347511713"
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Always use the real production/upload keystore. The build fails
            // above if the production keystore is absent.
            signingConfig = signingConfigs.getByName("release")
            // The Google Mobile Ads SDK validates this App ID in a
            // ContentProvider BEFORE any Dart code runs and throws an
            // uncatchable IllegalStateException ("Invalid application ID")
            // for a malformed value, killing the app at launch. Production
            // IDs must match ca-app-pub-{16 digits}~{10 digits}; until a
            // well-formed production ID is supplied, fall back to Google's
            // official test App ID so the app always starts.
            val admobProductionAppId = "ca-app-pub-434281193355977~3999306324"
            val admobAppIdPattern = Regex("^ca-app-pub-[0-9]{16}~[0-9]{10}$")
            manifestPlaceholders["admobAppId"] =
                if (admobAppIdPattern.matches(admobProductionAppId)) admobProductionAppId
                else "ca-app-pub-3940256099942544~3347511713"
            // Remove unreachable Java/Kotlin bytecode. Notification sounds are
            // selected by resource name at runtime through Flutter, so Android
            // resource shrinking cannot reliably detect and preserve them.
            isMinifyEnabled = true
            isShrinkResources = false
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
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
