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

    afterEvaluate {
        if (project.extensions.findByName("android") != null) {
            val android = project.extensions.getByName("android")
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                
                if (getNamespace.invoke(android) == null) {
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val contents = manifestFile.readText()
                        val match = Regex("package=\"([^\"]+)\"").find(contents)
                        if (match != null) {
                            setNamespace.invoke(android, match.groupValues[1])
                        } else {
                            setNamespace.invoke(android, "com.library.${project.name.replace("-", "_")}")
                        }
                    } else {
                        setNamespace.invoke(android, "com.library.${project.name.replace("-", "_")}")
                    }
                }
            } catch (e: Exception) {
                // Ignore
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
