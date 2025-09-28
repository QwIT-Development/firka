pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")

gradle.allprojects {
    afterEvaluate {
        if (hasProperty("android")) {
            val androidExtension = extensions.findByName("android")
            if (androidExtension != null) {
                // Set compileSdk for all modules
                if (androidExtension is com.android.build.gradle.BaseExtension) {
                    androidExtension.compileSdkVersion(35)
                }

                val namespace = androidExtension.javaClass.methods
                    .find { it.name == "getNamespace" }
                    ?.invoke(androidExtension) as? String
                
                if (namespace.isNullOrEmpty()) {
                    val groupBasedNamespace = when {
                        project.group.toString().isNotEmpty() && project.group.toString() != "unspecified" -> project.group.toString()
                        else -> "app.firka.naplo.${project.name}"
                    }
                    
                    androidExtension.javaClass.methods
                        .find { it.name == "setNamespace" }
                        ?.invoke(androidExtension, groupBasedNamespace)
                }
            }
        }
    }
}
