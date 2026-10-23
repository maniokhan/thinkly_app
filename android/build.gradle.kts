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

subprojects {
    val configureAndroid = {
        val android = project.extensions.findByName("android")
        if (android != null) {
            try {
                val compileMethod = android.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                compileMethod.invoke(android, 37)
            } catch (_: Exception) {
                try {
                    val setMethod = android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    setMethod.invoke(android, 37)
                } catch (_: Exception) {}
            }
        }
    }

    if (project.state.executed) {
        configureAndroid()
    } else {
        project.afterEvaluate {
            configureAndroid()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
