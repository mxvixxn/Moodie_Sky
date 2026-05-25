# ☀️ Moodie Sky (무디 스카이)

[🇰🇷 한국어](#-한국어) | [🇺🇸 English](#-english)

---

## 🇰🇷 한국어

> **"오늘 하루, 당신의 마음 하늘은 어떤 색이었나요?"**
> Moodie Sky는 그날의 감정과 마음의 날씨를 차분하게 기록하고 돌아볼 수 있는 나만의 감성 다이어리 앱이에요.  
> 단순한 텍스트 기록을 넘어 내 마음의 통계를 시각화하고, 철저한 프라이버시 보안 속에서 소중한 기억을 안전하게 보관해 준답니다.

<br>

### ✨ 주요 기능 (Key Features)

* **☁️ 마음 날씨 기록 & 월별 캘린더**
  * '맑음', '구름', '비', '폭풍', '무지개' 등 직관적인 날씨 아이템과 한 줄 메모로 오늘의 기분을 가볍게 기록해요.
  * 월별 캘린더 뷰를 통해 한 달 동안 내 마음 하늘에 어떤 날씨가 가장 많이 머물렀는지 직관적으로 확인할 수 있어요.
* **📊 맞춤형 주간/야간 리포트 (Reports & Insights)**
  * 사용자의 기록 빈도, 메모의 길이, 평일/주말 간의 감정 변화 리듬을 정밀하게 분석해서 따뜻하고 직관적인 인사이트 리포트를 제공해요.
* **🔒 철저한 프라이버시 및 생체 인식 잠금**
  * `LocalAuthentication`을 활용한 **Face ID 인증** 및 자체 앱 암호(Passcode) 설정을 지원해서 개인적인 기록을 완벽하게 보호해요.
  * 기기 암호가 유출되더라도 안전하도록 **20자리 영문/숫자 조합의 복구 키(Recovery Key)** 시스템을 갖추고 있어요.
* **🛡️ 보안 암호화 백업 및 내보내기**
  * 작성한 일기를 일반 CSV, JSON 포맷뿐만 아니라, `CryptoKit` 기반의 **안전한 암호화 백업 파일(`.moodieskybackup`)**로 내보내고 안전하게 복원(Import)할 수 있어요.
* **🔔 세심한 사용자 경험 (UX)**
  * 사용자가 설정한 최적의 시간에 맞춰 다정한 어조로 알림을 보내요. (방해 금지 시간 설정 가능)
  * 일기 저장, 삭제, 편집 등 앱 내 주요 인터랙션마다 적절한 **햅틱 피드백(Haptic Feedback)**을 제공해서 손끝으로 느끼는 감성을 더했답니다.

<br>

### 🛠️ 기술 스택 (Tech Stacks)

* **Language**: Swift
* **UI Framework**: SwiftUI
* **Architecture**: MVVM (철저한 `@MainActor` 및 `@Published` 기반 비즈니스 로직 분리)
* **Data Management**: SwiftData (로컬 영구 저장소), UserDefaults
* **Security & Crypto**: Security (Keychain Access), CryptoKit (AES-GCM 암호화 백업), LocalAuthentication (Face ID)
* **Frameworks**: Combine, UserNotifications, CloudKit (Sync 준비 완료)

<br>

### 🤖 AI 협업 과정 (AI-Assisted Development)

본 프로젝트는 AI 협업 툴과 개발자가 긴밀하게 소통하며 고성능 기능을 단기간에 안정적으로 구현해 낸 **AI 협업 개발(AI-Assisted Development)** 프로젝트예요.

* **Architecture Refactoring**: 대규모 뷰 로직이 엉켜있던 기존 구조에서 모든 비즈니스 로직을 분리하여, 완전히 독립적이고 유지보수가 용이한 `MoodViewModel` 중심의 체계적인 MVVM 구조를 설계했어요.
* **Cryptographic Implementation**: `CryptoKit`을 활용해 소중한 일기 데이터를 유저가 지정한 비밀번호 기반의 **Salt+HKDF+AES-GCM 암호화** 스트림으로 가공하여 `.moodieskybackup`이라는 고유 확장자 백업 파일로 완벽하게 인코딩/디코딩하는 복잡한 로직을 AI와의 프롬프트 엔지니어링을 통해 안전하게 완성했어요.
* **UX & Edge-case Handling**: 사용자 알림 기능 구현 시, 당일 이미 일기를 작성한 유저에게는 알림을 생략하는 스킵 조건(`skipsReminderAfterTodayEntry`) 및 야간 방해 금지 시간 예외 처리 등 복잡한 에러 핸들링과 예외 케이스들을 함께 브레인스토밍하며 완벽히 대응했답니다.

---

## 🇺🇸 English

> **"What color was your mind's sky today?"**
> Moodie Sky is a sentimental diary app designed to help you calmly record and look back on your daily emotions and mental weather.  
> Moving beyond simple text logs, it visualizes your emotional statistics and safely preserves your precious memories with ironclad privacy features.

<br>

### ✨ Key Features

* **☁️ Mind Weather Tracking & Monthly Calendar**
  * Effortlessly log the day's mood with intuitive weather items ('Sunny', 'Cloudy', 'Rainy', 'Stormy', 'Rainbow') and a short note.
  * Visualize which weather dominated your mind's sky over the month at a glance through the monthly calendar view.
* **📊 Customized Weekly/Nightly Reports (Reports & Insights)**
  * Provides warm and intuitive insight reports by precisely analyzing the user's logging frequency, note length, and weekday/weekend emotional rhythms.
* **🔒 Strict Privacy & Biometric Lock**
  * Utilizes `LocalAuthentication` to support **Face ID authentication** and a custom app passcode to fully protect personal records.
  * Features a **20-character alphanumeric Recovery Key** system to ensure safety even if the device passcode is compromised.
* **🛡️ Secure Encrypted Backup & Export**
  * Supports exporting diary entries not only in standard CSV and JSON formats but also as highly secure **encrypted backup files (`.moodieskybackup`)** based on `CryptoKit`, allowing for seamless and safe imports.
* **🔔 Thoughtful User Experience (UX)**
  * Sends reminders in a warm, gentle tone at user-defined times, complete with a customizable 'Do Not Disturb' window.
  * Enhances tactile feedback by providing tailored **Haptic Feedback** for major in-app interactions such as saving, deleting, and editing entries.

<br>

### 🛠️ Tech Stacks

* **Language**: Swift
* **UI Framework**: SwiftUI
* **Architecture**: MVVM (Strict `@MainActor` & `@Published` based business logic separation)
* **Data Management**: SwiftData (Local persistent storage), UserDefaults
* **Security & Crypto**: Security (Keychain Access), CryptoKit (AES-GCM encrypted backup), LocalAuthentication (Face ID)
* **Frameworks**: Combine, UserNotifications, CloudKit (Sync-ready)

<br>

### 🤖 AI-Assisted Development

This project was built through close collaboration between the developer and an AI assistant, successfully implementing high-performance features stably within a short period through **AI-Assisted Development**.

* **Architecture Refactoring**: Separated all business logic from a previously cluttered view-heavy structure to design a highly structured, scalable MVVM architecture centered around an independent `MoodViewModel`.
* **Cryptographic Implementation**: Co-developed a complex data serialization logic using `CryptoKit` to safely encrypt and decrypt diary data into a custom `.moodieskybackup` file format using a user-defined password-based **Salt+HKDF+AES-GCM** stream.
* **UX & Edge-case Handling**: Collaborated on extensive edge-case handling for the notification system, including skipping reminders if an entry was already created (`skipsReminderAfterTodayEntry`) and managing night-time exceptions.
