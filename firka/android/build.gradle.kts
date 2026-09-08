import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.dsl.LibraryExtension

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
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    if (project.name != "app") {
        project.evaluationDependsOn(":app")

        // android_alarm_manager_plus 5.1.1's own build.gradle.kts only applies
        // org.jetbrains.kotlin.android when AGP < 9, then unconditionally
        // configures KotlinAndroidProjectExtension - which doesn't exist here
        // on AGP 9+ unless we apply the plugin ourselves first.
        if (project.name == "android_alarm_manager_plus") {
            pluginManager.apply("org.jetbrains.kotlin.android")
        }

        afterEvaluate {
            if (plugins.hasPlugin("com.android.library")) {
                extensions.configure<LibraryExtension> {
                    compileSdk = 37
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}