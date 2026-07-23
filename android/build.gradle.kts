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

// Algunos plugins (p. ej. screen_protector) no fijan su propio JVM target de
// Kotlin y heredan el del JDK que corre Gradle (21 en instalaciones nuevas de
// Android Studio), mientras que :app compila con Java/Kotlin 17. Eso rompe el
// build con "Inconsistent JVM-target compatibility". Forzamos aquí el mismo
// target en todos los subproyectos para que coincidan. `tasks.withType(...)`
// es seguro de usar sin `afterEvaluate` (a diferencia de tocar la extensión
// `android {}`), ya que algunos subproyectos de plugins de Flutter se evalúan
// antes de que este bloque corra.
subprojects {
    tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
