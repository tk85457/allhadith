plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}
import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.taha.allhadithshahih"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = file(keystoreProperties.getProperty("storeFile") ?: "allhadith-keystore.jks")
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    defaultConfig {
        applicationId = "com.taha.allhadithshahih"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.activity:activity-ktx:1.9.0")

    // Google Mobile Ads Mediation Adapters & SDKs
    // Unity Ads SDK + Official Google AdMob Adapter
    implementation("com.unity3d.ads:unity-ads:4.13.1")
    implementation("com.google.ads.mediation:unity:4.13.1.0")
    implementation("com.google.ads.mediation:facebook:6.18.0.0")
}

// --- 16 KB page size fix -----------------------------------------------
// shared_preferences_android (pulled in transitively by the shared_preferences
// plugin) bundles androidx.datastore, whose libdatastore_shared_counter.so is
// only 16-KB-page-safe in datastore 1.1.7. Newer 1.2.x re-introduced an
// unaligned .so, so we pin every datastore artifact to 1.1.7 explicitly.
// See: https://github.com/flutter/flutter/issues/182898
configurations.all {
    resolutionStrategy {
        force("androidx.datastore:datastore:1.1.7")
        force("androidx.datastore:datastore-android:1.1.7")
        force("androidx.datastore:datastore-core:1.1.7")
        force("androidx.datastore:datastore-core-android:1.1.7")
        force("androidx.datastore:datastore-preferences:1.1.7")
        force("androidx.datastore:datastore-preferences-android:1.1.7")
        force("androidx.datastore:datastore-preferences-core:1.1.7")
    }
}
