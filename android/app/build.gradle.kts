import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.lunch_recommender"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.lunch_recommender"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // AdMob 앱 ID 설정
        manifestPlaceholders["admobAppId"] = getAdMobAppId()
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
