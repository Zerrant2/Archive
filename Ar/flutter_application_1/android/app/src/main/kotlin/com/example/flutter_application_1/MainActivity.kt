package com.example.flutter_application_1

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "retro_ar/device_capabilities"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getArCapabilities" -> result.success(getArCapabilities())
                "launchSceneViewer" -> {
                    val glbUrl = call.argument<String>("glbUrl").orEmpty()
                    val title = call.argument<String>("title").orEmpty()
                    val mode = call.argument<String>("mode") ?: "ar_preferred"
                    result.success(launchSceneViewer(glbUrl, title, mode))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getArCapabilities(): Map<String, Any> {
        val manufacturer = Build.MANUFACTURER.orEmpty()
        val brand = Build.BRAND.orEmpty()
        val model = Build.MODEL.orEmpty()
        val arCoreInstalled = isPackageEnabled("com.google.ar.core")
        val googleAppInstalled = isPackageEnabled("com.google.android.googlequicksearchbox")
        val googlePlayServicesInstalled = isPackageEnabled("com.google.android.gms")
        val hasCameraArFeature = packageManager.hasSystemFeature("android.hardware.camera.ar")
        val isChinaBrand = isLikelyChinaMarketBrand(manufacturer, brand)
        val likelyChinaMarketWithoutGoogle =
            isChinaBrand && (!googleAppInstalled || !googlePlayServicesInstalled)

        return mapOf(
            "manufacturer" to manufacturer,
            "brand" to brand,
            "model" to model,
            "hasCameraArFeature" to hasCameraArFeature,
            "arCoreInstalled" to arCoreInstalled,
            "googleAppInstalled" to googleAppInstalled,
            "googlePlayServicesInstalled" to googlePlayServicesInstalled,
            "likelyChinaMarketWithoutGoogle" to likelyChinaMarketWithoutGoogle
        )
    }

    @Suppress("DEPRECATION")
    private fun isPackageEnabled(packageName: String): Boolean {
        return try {
            packageManager.getApplicationInfo(packageName, 0).enabled
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun launchSceneViewer(glbUrl: String, title: String, mode: String): Boolean {
        if (glbUrl.isBlank()) return false

        val uri = Uri.parse("https://arvr.google.com/scene-viewer/1.0")
            .buildUpon()
            .appendQueryParameter("file", glbUrl)
            .appendQueryParameter("mode", mode)
            .appendQueryParameter("title", title)
            .build()
        val intent = Intent(Intent.ACTION_VIEW, uri).apply {
            setPackage("com.google.android.googlequicksearchbox")
        }

        return try {
            val handler = intent.resolveActivity(packageManager)
            if (handler == null) {
                false
            } else {
                startActivity(intent)
                true
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun isLikelyChinaMarketBrand(manufacturer: String, brand: String): Boolean {
        val deviceName = "${manufacturer.lowercase()} ${brand.lowercase()}"
        val brands = listOf(
            "huawei",
            "honor",
            "xiaomi",
            "redmi",
            "poco",
            "oppo",
            "oneplus",
            "vivo",
            "realme",
            "meizu",
            "zte",
            "nubia",
            "lenovo",
            "tecno",
            "infinix"
        )

        return brands.any { deviceName.contains(it) }
    }
}
