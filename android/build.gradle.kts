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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
