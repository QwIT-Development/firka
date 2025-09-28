// dear god

/*import org.apache.commons.io.FileUtils
import java.io.FileInputStream
import java.security.MessageDigest
import java.util.Properties
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.locks.ReentrantReadWriteLock
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream
import java.util.zip.ZipOutputStream.DEFLATED
import java.util.zip.ZipOutputStream.STORED
*/

plugins {
    id("com.android.application")
    id("kotlin-android")
    //id("org.jetbrains.kotlin.plugin.compose") version "2.2.0" // flutter doesn't need compose
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
    ndkVersion = flutter.ndkVersion //"27.0.12077973"

    compileOptions {
        // simple upgrade, if you really want to have a "modern" env
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_21.toString()
    }

    // whoever thought flutter needs compose was probably on some kind of strong za
    /*buildFeatures {
        compose = true
    }*/

    defaultConfig {
        applicationId = "app.firka.naplo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 29
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val secretsDir = rootProject.file("secrets") // did you know, that you don't need to go up?
    val propsFile = File(secretsDir, "keystore.properties")

    if (propsFile.exists()) {
        val props = loadProperties(propsFile)
        signingConfigs {
            create("release") {
                // much safer
                storeFile = File(secretsDir, props.getProperty("storeFile"))
                storePassword = props.getProperty("storePassword")
                keyPassword = props.getProperty("keyPassword")
                keyAlias = props.getProperty("keyAlias")
            }
        }
    }

    buildTypes {
        getByName("debug") {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfigs.findByName("release")?.let {
                signingConfig = it
            }
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

// a sane person wouldn't rewrite the whole build process, but still someone did it