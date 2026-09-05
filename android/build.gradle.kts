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

gradle.beforeProject {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            if (name == "flutter_any_logo") {
                namespace = "com.jordyhers.flutter_any_logo"
            }
        }
    }
}

// Paksa compileSdk 34 untuk library lama (usage_stats dll) — harus afterProject agar menimpa nilai akhir
gradle.afterProject {
    if (state.failure != null) return@afterProject
    extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.let { lib ->
        val currentSdk = lib.compileSdk ?: 0
        if (currentSdk in 1..33) {
            lib.compileSdkVersion(34)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
