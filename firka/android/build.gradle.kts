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

    afterEvaluate {
        if (plugins.hasPlugin("com.android.application")) {
            extensions.configure<ApplicationExtension> {
                compileSdk = 37
                defaultConfig {
                    // buildToolsVersion can be set here if needed
                }
            }
        }

        if (plugins.hasPlugin("com.android.library")) {
            extensions.configure<LibraryExtension> {
                compileSdk = 37
            }
        }
    }

    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}