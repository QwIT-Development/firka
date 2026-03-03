import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("org.jetbrains.kotlin.plugin.compose") version "2.1.0"
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun loadProperties(file: File): Properties {
    val properties = Properties()
    FileInputStream(file).use { inputStream ->
        properties.load(inputStream)
    }
    return properties
}

android {
    namespace = "app.firka.naplo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "app.firka.naplo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 29
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val secretsDir = File(projectDir.absolutePath, "../../../secrets/")
    val propsFile = File(secretsDir, "keystore.properties")

    if (propsFile.exists()) {
        val props = loadProperties(propsFile)
        val store = File(secretsDir, props["storeFile"].toString())

        signingConfigs {
            create("release") {
                storeFile = store
                storePassword = props["storePassword"] as String
                keyPassword = props["keyPassword"] as String
                keyAlias = props["keyAlias"] as String
            }
        }
    }

    buildTypes {
        getByName("debug") {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
        release {
            val config = signingConfigs.findByName("release")

            if (config != null) {
                signingConfig = config
            }

            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}
dependencies {
    implementation("androidx.wear:wear-ongoing:1.0.0")
    implementation("androidx.glance:glance-appwidget:1.1.1")
}

flutter {
    source = "../.."
}

fun checkReleaseKey() {
    val secretsDir = File(projectDir.absolutePath, "../../../secrets/")
    val propsFile = File(secretsDir, "keystore.properties")

    if (propsFile.exists()) {
        val props = loadProperties(propsFile)
        val store = File(secretsDir, props["storeFile"].toString())

        println(
            "Signing with:\n" +
                    "\t- store: ${store.name}\n" +
                    "\t- key: ${props["keyAlias"]}"
        )
    } else {
        throw Exception("Release keystore not found!")
    }
}
