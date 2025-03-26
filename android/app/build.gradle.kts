import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("app/key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ant_revolution.lunch_recommender"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.ant_revolution.lunch_recommender"
        minSdk = 27
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // AdMob 앱 ID 설정
        manifestPlaceholders["admobAppId"] = getAdMobAppId()
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

// AdMob 앱 ID를 가져오는 함수
fun getAdMobAppId(): String {
    // 로컬 속성 파일에서 값을 가져오거나 기본값 사용
    val localProperties = Properties()
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localProperties.load(FileInputStream(localPropertiesFile))
        val appId = localProperties.getProperty("admob.app.id")
        if (appId != null) {
            return appId
        }
    }
    
    // 환경 변수에서 값을 가져오거나 기본값 사용
    val envAppId = System.getenv("ADMOB_APP_ID")
    if (envAppId != null) {
        return envAppId
    }
    
    // 디버그 모드에서는 테스트 앱 ID 사용
    return "ca-app-pub-3940256099942544~3347511713" // 테스트 앱 ID
}
