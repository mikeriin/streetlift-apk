import java.security.KeyStore
import java.security.MessageDigest
import java.util.Base64

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "fr.tchoupi.streetlift_tracker"
    compileSdk = 36
    // KT-019 : r28c aligne les nouvelles bibliothèques natives sur 16 Ko.
    ndkVersion = "28.2.13676358"
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    defaultConfig {
        applicationId = "fr.tchoupi.streetlift_tracker"
        // M1 : Flutter 3.47 refuse une cible inférieure à Android 6 (API 23)
        // et son moteur vise Android 7.0 (API 24), minimum retenu.
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    // M1 : avec minSdk ≥ 23, AGP range les bibliothèques natives non
    // compressées dans l'APK (+ ~40 Mo pour l'APK universel installé à la
    // main). Compression conservée comme avant M1 ; l'alignement 16 Ko des
    // ELF et de l'AAB reste vérifié par tools/verify_android_artifacts.py.
    packaging { jniLibs { useLegacyPackaging = true } }
    signingConfigs {
        create("release") {
            storeFile = file("../../signing/kalis_track.p12")
            storePassword = System.getenv("KALIS_KEYSTORE_PASSWORD")
            keyAlias = "kalis"
            keyPassword = storePassword
            storeType = "PKCS12"
        }
    }
    buildTypes {
        release {
            // L1b-R1 : Flutter ne fournit pas de moteur x86 32 bits. Sans filtre, la
            // bibliothèque x86 de androidx.datastore (shared_preferences_android)
            // entre dans l'APK/AAB. Même liste que les filtres par défaut de Flutter 3.35.
            ndk { abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86_64")) }
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}
// M1 : Kotlin 2.3 (minimum de Flutter 3.47) remplace `kotlinOptions` par
// `compilerOptions`, même cible Java 17.
kotlin {
    compilerOptions { jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17) }
}
flutter { source = "../.." }
dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }

// Vérifier les secrets uniquement lorsqu'une tâche produit/signe une release.
// Analyse, tests et tâches debug restent accessibles sans secrets.
val applicationProject = project
gradle.taskGraph.whenReady {
    val releaseOutput = allTasks.any { task ->
        task.project == applicationProject && task.name.contains("Release") &&
            listOf("validateSigning", "package", "sign", "assemble", "bundle").any {
                task.name.startsWith(it)
            }
    }
    if (releaseOutput) {
        val encoded = System.getenv("KALIS_KEYSTORE_BASE64")
        val password = System.getenv("KALIS_KEYSTORE_PASSWORD")
        if (encoded.isNullOrBlank() || password.isNullOrEmpty()) {
            throw GradleException("Release refusée : KALIS_KEYSTORE_BASE64 et KALIS_KEYSTORE_PASSWORD sont obligatoires.")
        }
        val raw = try {
            Base64.getDecoder().decode(encoded.trim())
        } catch (_: IllegalArgumentException) {
            throw GradleException("Release refusée : KALIS_KEYSTORE_BASE64 invalide.")
        }
        val keystoreFile = file("../../signing/kalis_track.p12")
        if (!keystoreFile.isFile || !keystoreFile.readBytes().contentEquals(raw)) {
            throw GradleException("Release refusée : clé non restaurée ou différente du secret. Exécuter python3 tools/signing.py restore.")
        }
        val chars = password.toCharArray()
        val fingerprint = try {
            val keystore = KeyStore.getInstance("PKCS12")
            keystoreFile.inputStream().use { keystore.load(it, chars) }
            check(keystore.isKeyEntry("kalis") && keystore.getKey("kalis", chars) != null)
            MessageDigest.getInstance("SHA-256").digest(keystore.getCertificate("kalis").encoded)
                .joinToString("") { "%02x".format(it) }
        } catch (_: Exception) {
            throw GradleException("Release refusée : keystore, mot de passe ou clé privée kalis invalide.")
        } finally {
            chars.fill('\u0000')
        }
        val expected = file("../../signing/certificate.sha256").readText().trim().lowercase()
        if (fingerprint != expected) {
            throw GradleException("Release refusée : certificat différent de la référence locale.")
        }
    }
}
