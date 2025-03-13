# 점심 추천 앱 (Lunch Recommender)

점심 메뉴 선택에 어려움을 겪는 사용자들을 위한 Flutter 기반 모바일 애플리케이션입니다. 사용자의 위치, 날씨, 이전 식사 기록 등을 고려하여 최적의 점심 메뉴를 추천해 드립니다.

![앱 스크린샷](screenshots/app_screenshot.png)

## 주요 기능

- **맞춤형 음식 추천**: 사용자의 취향과 이전 식사 기록을 분석하여 개인화된 추천 제공
- **날씨 기반 추천**: 현재 날씨 정보를 활용하여 날씨에 적합한 음식 추천
- **식사 기록 관리**: 식사 기록을 저장하고 분석하여 더 나은 추천 제공
- **추천 기록 관리**: 이전에 받았던 추천 내역을 확인 가능

## 기술 스택

- **프레임워크**: Flutter
- **언어**: Dart
- **데이터베이스**: SQLite
- **API**: 기상청 날씨 API, 위치 서비스 API

## 설치 방법

1. Flutter 개발 환경을 설정합니다.
2. 저장소를 클론합니다:
   ```
   git clone https://github.com/yourusername/lunch_recommender.git
   ```
3. 의존성 패키지를 설치합니다:
   ```
   flutter pub get
   ```
4. 아래 '비밀 정보 설정' 섹션의 지침에 따라 API 키를 설정합니다.
5. 앱을 실행합니다:
   ```
   flutter run
   ```

## 비밀 정보 설정

이 프로젝트는 API 키와 같은 비밀 정보를 안전하게 관리하기 위해 별도의 파일을 사용합니다.

1. `lib/config/secrets.example.dart` 파일을 `lib/config/secrets.dart`로 복사합니다.
2. `secrets.dart` 파일 내의 비밀 정보를 실제 값으로 변경합니다.
3. `secrets.dart` 파일은 `.gitignore`에 포함되어 있어 Git에 올라가지 않습니다.

```dart
// secrets.dart 예시
class Secrets {
  static const String weatherApiKey = "여기에_실제_API_키를_입력하세요";
}
```

**주의**: 절대로 실제 API 키나 비밀번호를 Git에 올리지 마세요!

## 기여 방법

1. 이 저장소를 포크합니다.
2. 새로운 기능 브랜치를 생성합니다 (`git checkout -b feature/amazing-feature`).
3. 변경 사항을 커밋합니다 (`git commit -m 'Add some amazing feature'`).
4. 브랜치에 푸시합니다 (`git push origin feature/amazing-feature`).
5. Pull Request를 생성합니다.

