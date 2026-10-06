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

// ar_flutter_plugin_plus 1.1.3 requests a JDK 17 toolchain explicitly.
// Current Flutter/Android Studio ships JDK 21, which can still emit Java 17
// bytecode. Point only that plugin at the bundled JDK instead of requiring a
// second local JDK installation.
subprojects {
    afterEvaluate {
        if (name == "ar_flutter_plugin_plus") {
            extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension> {
                jvmToolchain(21)
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
