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

// Fix camera_android_camerax compiling against camera-core:1.5.3 on JDK 23+.
// javac now hard-errors (instead of warning) when it can't find a class needed
// to attach a type-use annotation. camera-core's @NonNull annotations sit on
// CallbackToFutureAdapter fields, but androidx.concurrent:concurrent-futures
// isn't on that module's compile classpath. Inject it so javac can resolve it.
subprojects {
    if (name == "camera_android_camerax") {
        afterEvaluate {
            dependencies.add(
                "implementation",
                "androidx.concurrent:concurrent-futures:1.2.0",
            )
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
