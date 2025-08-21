import org.apache.commons.io.FileUtils
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

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("org.jetbrains.kotlin.plugin.compose") version "2.2.0"
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
    ndkVersion = "27.0.12077973"

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

        println(
            "Signing with:\n" +
                    "\t- store: ${store.name}\n" +
                    "\t- key: ${props["keyAlias"]}"
        )

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
            } else {
                // This isn't an error, however by default flutter will hide warnings and etc.
                // so the only way to make this show up in flutter build is to
                // 1. make it an error
                // 2. use println
                // however, println doesn't bring enough attention to the warning
                // so I decided to use logger.error
                logger.error("[WARNING] No keystore specified! Using debug keys to sign the apk.")
                logger.error("[WARNING] DO NOT STORE ANY SENSITIVE DATA INSIDE THE APP")
                logger.error("[WARNING] An attacker could steal it, if you sideload their malicious app.")
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

tasks.register("transformAndResignDebugApk") {
    group = "build"
    description = "Transform and resign APK with debug key"

    dependsOn("assembleDebug")

    doLast {
        transformApks(true)
    }
}

tasks.register("transformAndResignReleaseApk") {
    group = "build"
    description = "Transform and resign APK with release key"

    dependsOn("assembleRelease")

    doLast {
        transformApks(false)
    }
}

tasks.register("transformAndResignReleaseBundle") {
    group = "build"
    description = "Transform and resign bundle with release key"

    dependsOn("bundleRelease")

    doLast {
        transformAppBundle()
    }
}

afterEvaluate {
    tasks.findByName("assembleDebug")?.finalizedBy("transformAndResignDebugApk")
    tasks.findByName("assembleRelease")?.finalizedBy("transformAndResignReleaseApk")
    tasks.findByName("bundleRelease")?.finalizedBy("transformAndResignReleaseBundle")
}

fun transformApks(debug: Boolean, i : Int = 0) {
    try {
        _transformApks(debug)
    } catch (e: Exception) {
        if (i < 5) {
            e.printStackTrace()

            println("Retrying: ${i + 1}")
            transformApks(debug, i + 1)
        } else {
            throw e
        }
    }
}

fun _transformApks(debug: Boolean) {
    println("Starting APK transformation process...")

    val buildDir = project.buildDir
    val apkDir = File(buildDir, "outputs/flutter-apk")
    val apks = getApks(debug)
    var c = 0
    apks
        .forEach { c++; transformAndSignApk(apkDir, it.nameWithoutExtension, debug) }

    println("Transformed: $c apks")
}

fun transformAndSignApk(apkDir: File, name: String, debug: Boolean) {
    val originalApk = File(apkDir, "$name.apk")
    val transformedApk = File(apkDir, "$name-transformed.apk")
    val finalApk = File(apkDir, "$name-resigned.apk")
    val finalIdsig = File(apkDir, "$name-resigned.apk.idsig")

    if (!originalApk.exists()) {
        throw GradleException("Original APK not found at: ${originalApk.absolutePath}")
    }

    if (transformedApk.exists()) transformedApk.delete()
    if (finalApk.exists()) finalApk.delete()

    println("Original APK: ${originalApk.absolutePath}")

    try {
        println("Transforming APK...")
        transformApk(originalApk, transformedApk, if (debug) { "6" } else {"Z"})

        if (debug) {
            println("Signing with debug key...")
            signWithDebugKey(transformedApk, finalApk)
        } else {
            println("Signing with release key...")
            signWithReleaseKey(transformedApk, finalApk)
        }

        if (finalApk.exists()) {
            originalApk.delete()
            finalIdsig.delete()
            finalApk.renameTo(originalApk)
            println("APK successfully transformed")
            println("Final APK: ${originalApk.absolutePath}")
        }

        transformedApk.delete()
    } catch (e: Exception) {
        throw GradleException("Failed to transform and resign APK: ${e.message}", e)
    }
}

fun transformApk(input: File, output: File, compressionLevel: String = "Z") {
    val tempDir = File(project.buildDir, "tmp/apk-transform")
    val cacheDir = File(project.buildDir, "cache")
    val optipngCacheDir = File(cacheDir, "optipng")
    val assetCompressionDir = File(cacheDir, "assets")
    tempDir.deleteRecursively()
    tempDir.mkdirs()
    if (!optipngCacheDir.exists()) optipngCacheDir.mkdirs()
    if (!assetCompressionDir.exists()) assetCompressionDir.mkdirs()

    val brotli = findToolInPath("brotli")
        ?: throw Exception("Brotli not found in path")
    val optipng = findToolInPath("optipng")

    if (optipng == null || optipng.isEmpty()) {
        println("Optipng was not found in PATH, optimizing images will be skipped.")
    }

    copy {
        from(zipTree(input))
        into(tempDir)
    }

    val metaInf = File(tempDir, "META-INF")
    val metaInfFiles = metaInf.listFiles()
    for (file in metaInfFiles!!) {
        if (file.name.endsWith("MF") || file.name.endsWith("SF")
            || file.name.endsWith("RSA")) {
            file.delete()
        }
    }

    val arches = File(tempDir, "lib").listFiles()
    val compressedLibs = mutableMapOf<String, String>()
    for (arch in arches!!) {
        val libFlutter = File(arch, "libflutter.so")

        if (!libFlutter.exists()) continue

        val compressedFlutter = File(arch, "libflutter-br.so")

        compressedLibs["libflutter.so"] = libFlutter.sha256()

        println("Compressing ${arch.name}/libflutter.so with brotli")
        exec {
            commandLine(
                brotli,
                "-$compressionLevel",
                libFlutter.absolutePath,
                "-o", compressedFlutter.absolutePath
            )
        }
        libFlutter.delete()

        val json = groovy.json.JsonBuilder(compressedLibs)
        File(arch, "index.so").writeText(json.toString())
    }

    val topDirL = tempDir.absolutePath.length + 1
    val zos = ZipOutputStream(output.outputStream())

    val coreCount = Runtime.getRuntime().availableProcessors()
    val flutterResources = tempDir.walkTopDown().filter{f -> f.absolutePath.contains("flutter_assets")}
    val pngFiles = tempDir.walkTopDown().filter{f -> f.name.endsWith(".png")}

    val assetIndex = mutableMapOf<String, String>()
    val indexReadWriteLock = ReentrantReadWriteLock()

    if (compressionLevel == "Z") {
        if (optipng != null) {
            val executor = Executors.newFixedThreadPool(coreCount)
            val futures = mutableListOf<Future<*>>()

            pngFiles.forEach { pngFile ->
                val cacheFile = File(optipngCacheDir, pngFile.sha256())

                if (cacheFile.exists()) {
                    cacheFile.copyTo(pngFile, true)
                } else {
                    val future = executor.submit {
                        exec {
                            commandLine(
                                optipng,
                                "-zm", "9",
                                "-zw", "32k",
                                "-o9",
                                pngFile.absolutePath
                            )
                        }

                        pngFile.copyTo(cacheFile, true)
                    }

                    futures.add(future)
                }
            }

            futures.forEach { it.get() }
            executor.shutdown()
        }

        val executor = Executors.newFixedThreadPool(coreCount)
        val futures = mutableListOf<Future<*>>()

        val blacklist = listOf(
            // "AssetManifest.bin",
            "AssetManifest.json",
            "FontManifest.json",
            "isolate_snapshot_data",
            "kernel_blob.bin",
            "NativeAssetsManifest.json",
            "NOTICES.Z",
            "vm_snapshot_data",
            "fonts",
            "shaders"
        )

        flutterResources.forEach { f ->
            val relName = f.absolutePath.substring(topDirL).replace("\\", "/")
            if (f.isDirectory) return@forEach

            val cacheFileRaw = File(assetCompressionDir, f.sha256()+".r")
            val cacheFileGz = File(assetCompressionDir, f.sha256()+".gz")
            val cacheFileBr = File(assetCompressionDir, f.sha256()+".br")

            if (cacheFileRaw.exists() || cacheFileGz.exists() || cacheFileBr.exists()) {
                if (cacheFileRaw.exists()) {
                    cacheFileRaw.copyTo(f, true)

                    indexReadWriteLock.writeLock().lock()
                    assetIndex[relName] = "r"
                    indexReadWriteLock.writeLock().unlock()
                } else if (cacheFileGz.exists()) {
                    cacheFileGz.copyTo(f, true)

                    indexReadWriteLock.writeLock().lock()
                    assetIndex[relName] = "g"
                    indexReadWriteLock.writeLock().unlock()
                } else {
                    cacheFileBr.copyTo(f, true)

                    indexReadWriteLock.writeLock().lock()
                    assetIndex[relName] = "b"
                    indexReadWriteLock.writeLock().unlock()
                }
            } else {
                val future = executor.submit {
                    val brTmp = File(f.absolutePath + ".br.tmp")
                    val gzTmp = File(f.absolutePath + ".gz.tmp")

                    var blacklisted = false
                    for (f in blacklist) {
                        if (relName.contains(f)) {
                            blacklisted = true

                            break
                        }
                    }

                    if (!blacklisted) {
                        println("$relName: Testing with brotli")
                        exec {
                            commandLine(
                                brotli,
                                "-$compressionLevel",
                                f.absolutePath,
                                "-o", brTmp.absolutePath
                            )
                        }

                        println("$relName: Testing with gzip")
                        ant.invokeMethod(
                            "gzip", mapOf(
                                "src" to f.absolutePath,
                                "destfile" to gzTmp.absolutePath,
                            )
                        )

                        println("$brTmp: ${brTmp.length()}")
                        println("$gzTmp: ${gzTmp.length()}")
                        if (f.length() < gzTmp.length() && f.length() < brTmp.length()) {
                            println("$relName: Raw file wins")

                            f.copyTo(cacheFileRaw, true)

                            indexReadWriteLock.writeLock().lock()
                            assetIndex[relName] = "r"
                            indexReadWriteLock.writeLock().unlock()
                        } else {
                            if (brTmp.length() < gzTmp.length()) {
                                println("$relName: Brotli wins")

                                f.delete()
                                brTmp.copyTo(f, true)
                                brTmp.copyTo(cacheFileBr, true)

                                indexReadWriteLock.writeLock().lock()
                                assetIndex[relName] = "b"
                                indexReadWriteLock.writeLock().unlock()
                            } else {
                                println("$relName: Gzip wins")

                                f.delete()
                                gzTmp.copyTo(f, true)
                                gzTmp.copyTo(cacheFileGz, true)

                                indexReadWriteLock.writeLock().lock()
                                assetIndex[relName] = "g"
                                indexReadWriteLock.writeLock().unlock()
                            }
                        }

                        brTmp.delete()
                        gzTmp.delete()
                    }
                }

                futures.add(future)
            }
        }

        futures.forEach { it.get() }
        executor.shutdown()
    }

    tempDir.walkTopDown().forEach { f ->
        if (f.absolutePath == tempDir.absolutePath) return@forEach

        var relName = f.absolutePath.substring(topDirL).replace("\\", "/")
        if (f.isDirectory && !relName.endsWith("/")) relName += "/"

        if (compressionLevel == "Z") {
            if (relName == "assets/flutter_assets/assets/firka.i") return@forEach
        }

        println(relName)

        val compress = !relName.endsWith(".so") && !relName.endsWith(".arsc")
        zos.setMethod(if (compress) { DEFLATED } else { STORED })
        val entry = ZipEntry(relName)
        if (!compress) {
            entry.size = f.length()
            entry.crc = FileUtils.checksumCRC32(f)
        }
        zos.putNextEntry(entry)
        if (f.isFile) {
            zos.write(f.readBytes())
        }
        zos.closeEntry()
    }
    if (compressionLevel == "Z") {
        zos.setMethod(DEFLATED)
        zos.putNextEntry(ZipEntry("assets/flutter_assets/assets/firka.i"))

        val indexUncompressed = File(tempDir, "index.json")
        indexReadWriteLock.readLock().lock()
        val json = groovy.json.JsonBuilder(assetIndex)
        indexReadWriteLock.readLock().unlock()
        indexUncompressed.writeText(json.toString())

        val indexCompressed = File(tempDir, "index.json.br")

        exec {
            commandLine(
                brotli,
                "-$compressionLevel",
                indexUncompressed.absolutePath,
                "-o", indexCompressed.absolutePath
            )
        }

        zos.write(indexCompressed.readBytes())
        indexUncompressed.delete()
        indexCompressed.delete()

        zos.closeEntry()
    }
    zos.close()

    tempDir.deleteRecursively()
    println("APK transformed successfully")
}

fun transformAppBundle() {
    val buildDir = project.buildDir
    val bundle = File(buildDir, "outputs/bundle/release/app-release.aab")
    val bundleTmp = File(buildDir, "outputs/bundle/release/tmp.zip")

    val apks = getApks(false)
    val apkCount = apks.count { it.name.startsWith("app-") && it.name.endsWith("-release.apk") }

    if (!bundle.exists()) {
        throw Exception("Bundle not found at: $bundle")
    }

    if (apkCount < 3) {
        throw Exception("Excepected 3 apks per abi but only found $apkCount")
    }

    val aabTempDir = File(project.buildDir, "tmp/aab-transform")
    aabTempDir.deleteRecursively()
    aabTempDir.mkdirs()

    val apksUnzipped = File(project.buildDir, "tmp/apks-unzipped")
    apksUnzipped.deleteRecursively()

    val arm32TempDir = File(apksUnzipped, "armeabi-v7a")
    arm32TempDir.mkdirs()
    val arm64TempDir = File(apksUnzipped, "arm64-v8a")
    arm64TempDir.mkdirs()
    val x86TempDir = File(apksUnzipped, "x86_64")
    x86TempDir.mkdirs()

    copy {
        from(zipTree(bundle))
        into(aabTempDir)
    }
    copy {
        from(zipTree(apks.first { it.name.contains("armeabi-v7a") }))
        into(arm32TempDir)
    }
    copy {
        from(zipTree(apks.first { it.name.contains("arm64-v8a") }))
        into(arm64TempDir)
    }
    copy {
        from(zipTree(apks.first { it.name.contains("x86_64") }))
        into(x86TempDir)
    }

    val libs = File(aabTempDir, "base/lib").listFiles()!!

    for (dstLibs in libs) {
        println("Copying lib: ${dstLibs.name}")
        val srcDir = File(apksUnzipped, dstLibs.name)
        if (!srcDir.exists()) {
            continue
        }
        val srcLibs = File(srcDir, "lib/${dstLibs.name}/")

        dstLibs.listFiles()!!.forEach { it.delete() }
        srcLibs.listFiles()!!.forEach { it.copyTo(File(dstLibs, it.name)) }
    }

    val zos = ZipOutputStream(bundleTmp.outputStream())
    val bundleZip = ZipFile(bundle)
    val bundleEntries = bundleZip.entries()

    val brotli = findToolInPath("brotli")
        ?: throw Exception("Brotli not found in path")
    val optipng = findToolInPath("optipng")
        ?: throw Exception("Optipng not found in path")

    val indexReadWriteLock = ReentrantReadWriteLock()
    val assetIndex = mutableMapOf<String, String>()

    while (bundleEntries.hasMoreElements()) {
        val entry = bundleEntries.nextElement()

        /*
if (entry.name == "base/assets/flutter_assets/assets/firka.i") {
    println("Patching: ${entry.name}")
    zos.putNextEntry(ZipEntry("assets/flutter_assets/assets/firka.i"))

    val indexUncompressed = File(aabTempDir, "index.json")
    indexReadWriteLock.readLock().lock()
    val json = groovy.json.JsonBuilder(assetIndex)
    indexReadWriteLock.readLock().unlock()
    indexUncompressed.writeText(json.toString())

    val indexCompressed = File(aabTempDir, "index.json.br")

    exec {
        commandLine(
            brotli,
            "-Z",
            indexUncompressed.absolutePath,
            "-o", indexCompressed.absolutePath
        )
    }

    zos.write(indexCompressed.readBytes())
    indexUncompressed.delete()
    indexCompressed.delete()

    zos.closeEntry()
    continue
}
if (entry.name.startsWith("base/lib")) {
    println("Patching: ${entry.name}")
    zos.putNextEntry(ZipEntry(entry.name))



    zos.closeEntry()
    continue
}
*/

        println("Adding: ${entry.name}")

        zos.putNextEntry(ZipEntry(entry.name))

        if (!entry.isDirectory) {
            val data = bundleZip.getInputStream(entry).readAllBytes()
            zos.write(data)
        }
        zos.closeEntry()
    }
    bundleZip.close()
    zos.close()

    bundle.delete()
    signBundle(bundleTmp, bundle)
    bundleTmp.delete()

    aabTempDir.deleteRecursively()
    println("AAB transformed successfully")

}

fun File.sha256(): String {
    val md = MessageDigest.getInstance("SHA-256")
    val digest = md.digest(this.readBytes())
    return digest.fold("") { str, it -> str + "%02x".format(it) }
}

fun getApks(debug: Boolean): List<File> {
    val buildDir = project.buildDir
    val apkDir = File(buildDir, "outputs/flutter-apk")
    val apks = apkDir.listFiles()!!
    val flavor = if (debug) { "debug" } else { "release" }

    return apks
        .filter { apk -> apk.name.startsWith("app-") && apk.name.endsWith("-$flavor.apk") }
        .toList()
}

fun getDebugKeystorePath(): String {
    val userHome = System.getProperty("user.home")
    val debugKeystore = File(userHome, ".android/debug.keystore")

    if (!debugKeystore.exists()) {
        throw GradleException("Debug keystore not found at: ${debugKeystore.absolutePath}")
    }

    return debugKeystore.absolutePath
}

fun getDefaultAndroidSdkPath(): String? {
    val os = System.getProperty("os.name").lowercase()
    val userHome = System.getProperty("user.home")

    return when {
        os.contains("win") ->
            "$userHome\\AppData\\Local\\Android\\Sdk"
        os.contains("mac") ->
            "$userHome/Library/Android/sdk"
        os.contains("linux") ->
            "$userHome/Android/Sdk"
        else -> null
    }
}

fun findToolInPath(toolName: String): String? {
    val pathEnvironment = System.getenv("PATH")
    val pathDirs = pathEnvironment.split(File.pathSeparator)

    val executableNames = when {
        System.getProperty("os.name").lowercase().contains("win") ->
            listOf("$toolName.exe", toolName)
        else ->
            listOf(toolName)
    }

    for (pathDir in pathDirs) {
        for (execName in executableNames) {
            val possibleTool = File(pathDir, execName)
            if (possibleTool.exists() && possibleTool.canExecute()) {
                return possibleTool.absolutePath
            }
        }
    }

    return null
}

fun findToolInSdkPath(toolName: String): String? {
    var androidHome : String? = System.getenv("ANDROID_HOME")
        ?: System.getenv("ANDROID_SDK_ROOT")

    if (androidHome == null) androidHome = getDefaultAndroidSdkPath()

    if (androidHome != null) {
        val buildTools = File(androidHome, "build-tools")
        if (buildTools.exists()) {
            val latestVersion = buildTools.listFiles()
                ?.filter { it.isDirectory }
                ?.filter { it.name != "debian" }
                ?.maxByOrNull { it.name }

            if (latestVersion != null) {
                val toolExec = File(latestVersion, toolName)
                if (toolExec.exists()) {
                    return toolExec.absolutePath
                }
            }
        }
    }

    if (!toolName.contains(".exe")) {
        val exeTool = findToolInSdkPath("$toolName.exe")
        if (exeTool != null) return exeTool
    }
    if (!toolName.contains(".sh")) {
        val shTool = findToolInSdkPath("$toolName.sh")
        if (shTool != null) return shTool
    }
    if (!toolName.contains(".bat")) {
        val batTool = findToolInSdkPath("$toolName.bat")
        if (batTool != null) return batTool
    }

    return null
}

fun signWithDebugKey(input: File, output: File) {
    val debugKeystore = getDebugKeystorePath()
    val debugKeystorePassword = "android"
    val debugKeyAlias = "androiddebugkey"
    val debugKeyPassword = "android"

    val zipAlign: String = findToolInSdkPath("zipalign")
        ?: throw Exception("Could not find zipalign in ANDROID_SDK")
    val apksigner: String = findToolInSdkPath("apksigner")
        ?: throw Exception("Could not find zipalign in ANDROID_SDK")

    exec {
        commandLine(
            zipAlign,
            "-v", "4",
            input.absolutePath,
            output.absolutePath
        )
    }

    exec {
        commandLine(
            apksigner, "sign",
            "--ks", debugKeystore,
            "--ks-pass", "pass:$debugKeystorePassword",
            "--ks-key-alias", debugKeyAlias,
            "--key-pass", "pass:$debugKeyPassword",
            output.absolutePath
        )
    }

    println("APK signed and aligned successfully")
}

fun signWithReleaseKey(input: File, output: File) {
    val secretsDir = File(projectDir.absolutePath, "../../../secrets/")
    val propsFile = File(secretsDir, "keystore.properties")

    if (!propsFile.exists()) {
        throw Exception("Release keystore not found!")
    }

    val props = loadProperties(propsFile)

    val releaseKeystore = File(secretsDir, props["storeFile"].toString())
    val releaseKeystorePassword = props["storePassword"] as String
    val releaseKeyAlias = props["keyAlias"] as String
    val releaseKeyPassword = props["keyPassword"] as String

    val zipAlign: String = findToolInSdkPath("zipalign")
        ?: throw Exception("Could not find zipalign either in ANDROID_SDK")
    val apksigner: String = findToolInSdkPath("apksigner")
        ?: throw Exception("Could not find zipalign either in ANDROID_SDK")

    exec {
        commandLine(
            zipAlign,
            "-v", "4",
            input.absolutePath,
            output.absolutePath
        )
    }

    exec {
        commandLine(
            apksigner, "sign",
            "--ks", releaseKeystore,
            "--ks-pass", "pass:$releaseKeystorePassword",
            "--ks-key-alias", releaseKeyAlias,
            "--key-pass", "pass:$releaseKeyPassword",
            output.absolutePath
        )
    }

    println("APK signed and aligned successfully")
}

fun signBundle(input: File, output: File) {
    val secretsDir = File(projectDir.absolutePath, "../../../secrets/")
    val propsFile = File(secretsDir, "keystore.properties")

    if (!propsFile.exists()) {
        throw Exception("Release keystore not found!")
    }

    val props = loadProperties(propsFile)

    val releaseKeystore = File(secretsDir, props["storeFile"].toString())
    val releaseKeystorePassword = props["storePassword"] as String
    val releaseKeyAlias = props["keyAlias"] as String
    val releaseKeyPassword = props["keyPassword"] as String

    // val zipAlign: String = findToolInSdkPath("zipalign")
    //     ?: throw Exception("Could not find zipalign in ANDROID_SDK")
    val jarsigner: String = findToolInPath("jarsigner")
        ?: throw Exception("Could not find jarsigner in PATH")

    /*
    exec {
        commandLine(
            zipAlign,
            "-v", "4",
            input.absolutePath,
            output.absolutePath
        )
    }
     */
    input.copyTo(output, true)

    exec {
        // -keystore $KEYSTORE -storetype $STORETYPE -storepass $STOREPASS -digestalg SHA1 -sigalg SHA256withRSA application.zip $KEYALIAS
        commandLine(
            jarsigner,
            "-verbose",
            "-sigalg", "SHA256withRSA",
            "-digestalg", "SHA-256",
            "-keystore", releaseKeystore,
            "-storepass", releaseKeystorePassword,
            output.absolutePath,
            releaseKeyAlias
        )
    }

    println("AAB signed and aligned successfully")
}