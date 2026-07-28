pluginManagement {
    val flutterSdkPath =
        run {
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
    id("com.android.application") version "8.9.1" apply false
    // google_maps_flutter_android / maps-utils pull kotlin-stdlib 2.3.x metadata;
    // KGP 2.1.0 cannot read it (FileAnalysisException / "expected version is 2.1.0").
    id("org.jetbrains.kotlin.android") version "2.3.10" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
