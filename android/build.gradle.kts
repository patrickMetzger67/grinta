allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// AGP 8+ requires every Android library module to declare a namespace.
// Backfill it from AndroidManifest package for older Flutter plugins.
subprojects {
    pluginManager.withPlugin("com.android.library") {
        val androidExt = extensions.findByName("android") ?: return@withPlugin
        try {
            val getNamespace =
                androidExt.javaClass.methods.firstOrNull {
                    it.name == "getNamespace" && it.parameterCount == 0
                }
            val current = getNamespace?.invoke(androidExt) as String?
            if (!current.isNullOrBlank()) return@withPlugin

            val manifest = file("src/main/AndroidManifest.xml")
            val fromManifest =
                if (manifest.exists()) {
                    Regex("""package\s*=\s*"([^"]+)"""")
                        .find(manifest.readText())
                        ?.groupValues
                        ?.getOrNull(1)
                } else {
                    null
                }
            val namespace =
                fromManifest
                    ?: "grinta.${name.replace('-', '_').replace('.', '_')}"
            val setNamespace =
                androidExt.javaClass.methods.firstOrNull {
                    it.name == "setNamespace" && it.parameterCount == 1
                }
            setNamespace?.invoke(androidExt, namespace)
            logger.lifecycle("Backfilled Android namespace '$namespace' for :$name")
        } catch (e: Exception) {
            logger.warn("Could not backfill namespace for :$name (${e.message})")
        }
    }
}

// Align compileSdk + Java/Kotlin JVM targets across plugins.
// Legacy plugins ship Java 1.8 / old compileSdk; google_maps_flutter_android
// needs Java 17 (switch expressions + pattern matching instanceof).
// sqflite_android 2.4.2+ references VERSION_CODES.BAKLAVA → compileSdk 36.
fun Project.forceAndroidPluginCompat() {
    extensions.findByName("android")?.let { androidExt ->
        try {
            // Prefer AGP 8 `compileSdk`, fall back to legacy `compileSdkVersion`.
            val setCompileSdk =
                androidExt.javaClass.methods.firstOrNull {
                    it.name == "setCompileSdk" && it.parameterCount == 1
                }
            val setCompileSdkVersion =
                androidExt.javaClass.methods.firstOrNull {
                    it.name == "setCompileSdkVersion" && it.parameterCount == 1
                }
            when {
                setCompileSdk != null -> setCompileSdk.invoke(androidExt, 36)
                setCompileSdkVersion != null -> setCompileSdkVersion.invoke(androidExt, 36)
            }

            val compileOptions =
                androidExt.javaClass.methods
                    .firstOrNull { it.name == "getCompileOptions" && it.parameterCount == 0 }
                    ?.invoke(androidExt)
            if (compileOptions != null) {
                compileOptions.javaClass.methods
                    .firstOrNull {
                        it.name == "setSourceCompatibility" && it.parameterCount == 1
                    }
                    ?.invoke(compileOptions, JavaVersion.VERSION_17)
                compileOptions.javaClass.methods
                    .firstOrNull {
                        it.name == "setTargetCompatibility" && it.parameterCount == 1
                    }
                    ?.invoke(compileOptions, JavaVersion.VERSION_17)
            }
        } catch (e: Exception) {
            logger.warn("Could not align Android compat on :$name (${e.message})")
        }
    }

    tasks.withType(JavaCompile::class.java).configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }

    tasks.matching { it.name.contains("compile", ignoreCase = true) && it.name.contains("Kotlin") }
        .configureEach {
            // Prefer compilerOptions (Kotlin 2.x); fall back to legacy kotlinOptions.
            val compilerOptions =
                this.javaClass.methods
                    .firstOrNull { it.name == "getCompilerOptions" && it.parameterCount == 0 }
                    ?.invoke(this)
            if (compilerOptions != null) {
                val jvmTargetProp =
                    compilerOptions.javaClass.methods
                        .firstOrNull { it.name == "getJvmTarget" && it.parameterCount == 0 }
                        ?.invoke(compilerOptions)
                val setMethod =
                    jvmTargetProp?.javaClass?.methods?.firstOrNull {
                        it.name == "set" && it.parameterCount == 1
                    }
                if (setMethod != null) {
                    try {
                        val jvmTargetClass =
                            Class.forName("org.jetbrains.kotlin.gradle.dsl.JvmTarget")
                        val jvm17 =
                            jvmTargetClass.enumConstants
                                ?.firstOrNull { it.toString().contains("17") }
                        if (jvm17 != null) {
                            setMethod.invoke(jvmTargetProp, jvm17)
                            return@configureEach
                        }
                    } catch (_: Exception) {
                        // Fall through to kotlinOptions.
                    }
                }
            }

            val kotlinOptions =
                this.javaClass.methods
                    .firstOrNull { it.name == "getKotlinOptions" && it.parameterCount == 0 }
                    ?.invoke(this)
            kotlinOptions
                ?.javaClass
                ?.methods
                ?.firstOrNull { it.name == "setJvmTarget" && it.parameterCount == 1 }
                ?.invoke(kotlinOptions, "17")
        }
}

subprojects {
    // evaluationDependsOn(":app") can leave some projects already evaluated.
    if (state.executed) {
        forceAndroidPluginCompat()
    } else {
        afterEvaluate { forceAndroidPluginCompat() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
