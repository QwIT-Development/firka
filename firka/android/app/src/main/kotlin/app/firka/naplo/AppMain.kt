package app.firka.naplo

import android.annotation.SuppressLint
import android.app.Application
import android.os.Build
import android.util.Log
import org.brotli.dec.BrotliInputStream
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.security.MessageDigest
import java.util.zip.ZipFile

class AppMain : Application() {

    private fun File.sha256(): String {
        if (!exists()) return "0000000000000000000000000000000000000000000000000000000000000000"

        val md = MessageDigest.getInstance("SHA-256")
        val digest = md.digest(this.readBytes())
        return digest.fold("") { str, it -> str + "%02x".format(it) }
    }

    @SuppressLint("UnsafeDynamicallyLoadedCode")
    override fun onCreate() {
        super.onCreate()

        val abi = Build.SUPPORTED_ABIS[0]

        val apks = File(applicationInfo.nativeLibraryDir, "../..").absoluteFile
            .listFiles()!!
            .filter { file -> file.name.endsWith(".apk") }
            .toList()

        var nativesApkN: ZipFile? = null
        for (apk in apks) {
            if (nativesApkN != null) break

            val zip = ZipFile(apk)
            val entries = zip.entries()

            while (entries.hasMoreElements()) {
                val entry = entries.nextElement()

                entry.name.endsWith("$abi/index.so")
                zip.close()
                nativesApkN = ZipFile(apk)
                break
            }

            zip.close()
        }

        if (nativesApkN == null) {
            throw Exception("Can't find native libraries")
        }
        val nativesApk: ZipFile = nativesApkN

        val compressedLibsIndex = nativesApk.getInputStream(
            nativesApk.getEntry("lib/$abi/index.so")
        )
        val compressedLibs = JSONObject(compressedLibsIndex.readBytes().toString(Charsets.UTF_8))

        for (so in compressedLibs.keys()) {
            val soFile = File(cacheDir, so)

            if (soFile.sha256() == compressedLibs.getString(so)) {
                System.load(soFile.absolutePath)
                return
            }

            Log.d("AppMain", "Decompressing: $so")
            val brInput = nativesApk.getInputStream(
                nativesApk.getEntry("lib/$abi/${so.replace(".so", "-br.so")}")
            )
            val soOutput = FileOutputStream(soFile)

            val brIn = BrotliInputStream(brInput)
            brIn.copyTo(soOutput)

            brInput.close()
            soOutput.close()

            System.load(soFile.absolutePath)
        }
    }

}