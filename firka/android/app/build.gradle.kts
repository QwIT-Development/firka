import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("org.jetbrains.kotlin.plugin.compose")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.firka.naplo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

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
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val secretsDir = File(projectDir.absolutePath, "../../../secrets/")
    val propsFile = File(secretsDir, "keystore.properties")

    if (propsFile.exists()) {
        val props = Properties().apply { FileInputStream(propsFile).use { load(it) } }
        val store = File(secretsDir, props["storeFile"].toString())

        signingConfigs {
            create("release") {
                storeFile = store
                storePassword = props["storePassword"] as String
                keyPassword = props["keyPassword"] as String
                keyAlias = props["keyAlias"] as String
                // Use APK Signature Scheme v3 (and v4 for streaming verification). See:
                // https://source.android.com/docs/security/features/apksigning/v3
                enableV3Signing = true
                enableV4Signing = true
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
    implementation("androidx.glance:glance-appwidget:1.1.1")
}

// Ensure .env exists before Flutter bundles assets (copy from .env.example if missing)
val envFile = file("${project.projectDir}/../../.env")
val envExampleFile = file("${project.projectDir}/../../.env.example")
tasks.register("ensureEnv") {
    doLast {
        if (!envFile.exists() && envExampleFile.exists()) {
            envExampleFile.copyTo(envFile, overwrite = false)
            println("Created .env from .env.example for asset bundling.")
        }
    }
}
tasks.matching { it.name.startsWith("compileFlutterBuild") }.configureEach {
    dependsOn("ensureEnv")
}

flutter {
    source = "../.."
}