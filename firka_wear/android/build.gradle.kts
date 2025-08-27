import com.android.build.gradle.BaseExtension
import org.jetbrains.kotlin.gradle.plugin.extraProperties

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)

    // fix for verifyReleaseResources

    // note(4831c0): taken from https://github.com/isar/isar/issues/1662
    // note(4831c0): and adapted to kotlin
    afterEvaluate {
        if (plugins.hasPlugin("com.android.application") || plugins.hasPlugin("com.android.library")) {
            val androidExtension = extensions.getByName("android") as BaseExtension
            androidExtension.apply {
                compileSdkVersion(35)
                buildToolsVersion = "35.0.0"
            }
        }
        if (hasProperty("android")) {
            val androidExtension = extensions.getByName("android") as BaseExtension
            androidExtension.apply {
                // Set namespace if it's not already set
                if (!extraProperties.has("namespace")) {
                    extraProperties["namespace"] = project.group.toString()
                }
            }
        }
    }
    // ===============================

    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
