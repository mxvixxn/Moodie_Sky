# Moodie Sky — 채팅용 컨텍스트 브리핑

> 이 문서는 **폴더에 접근할 수 없는 Claude 채팅(claude.ai)** 에게 이 앱이 뭔지 한 번에 이해시키기 위한 요약본입니다.
> 새 대화를 시작할 때 이 파일을 프로젝트 지식에 올리거나 첫 메시지에 붙여넣으세요.
> 코드가 바뀌면 이 문서도 갱신해야 합니다. (최종 갱신: 2026-08-03)

---

## 1. 한 문단 요약

**Moodie Sky(무디 스카이)** 는 하루의 기분을 '마음 날씨'로 기록하는 iOS 감성 다이어리 앱입니다.
개인 개발자(mxvixxn) 1인 프로젝트이고, **SwiftUI + SwiftData 기반의 순수 로컬 앱**입니다.
서버 백엔드가 없고, 동기화는 CloudKit(사용자 본인 iCloud)만 씁니다. 즉 **네트워크 API·DB·서버 코드가 존재하지 않습니다.**

- 저장소: https://github.com/mxvixxn/Moodie_Sky (브랜치 `main`)
- 로컬 경로: `~/Desktop/Moodie Sky`
- 대화 언어: 한국어. 앱 UI 문구도 전부 한국어이며, **다정하고 부드러운 존댓말 톤**("~해요", "~했어요")을 씁니다.

---

## 2. 기술 스택 / 제약

| 항목 | 값 |
|---|---|
| 언어 / UI | Swift, SwiftUI (UIKit은 `UIViewControllerRepresentable` 공유시트 정도만) |
| 아키텍처 | MVVM — 모든 로직이 `MoodViewModel`(`@MainActor`, `ObservableObject`)에 집중 |
| 영속성 | SwiftData (`@Model final class MoodEntry`), 설정값은 `UserDefaults` |
| 동기화 | CloudKit (사용자 iCloud 프라이빗 DB) |
| 보안 | Keychain, CryptoKit(AES-GCM + HKDF), LocalAuthentication(Face ID) |
| 알림 | UserNotifications (요일별 리마인더, 방해금지 시간) |
| 위젯 | `MoodieSkyWidgets` 타깃, App Group으로 데이터 공유 |
| 타깃 OS | 최신 iOS (iOS 26 Liquid Glass API를 그대로 사용 중) |
| 빌드 | Xcode 프로젝트(`Moodie Sky.xcodeproj`). SPM 패키지·CocoaPods 의존성 **없음** |
| 테스트 | 자동화 테스트 타깃 없음 (검증은 빌드 + 시뮬레이터 수동 확인) |

> 채팅에서 코드 제안할 때 주의: **써드파티 라이브러리를 도입하는 답변은 이 프로젝트의 방향과 맞지 않습니다.** 애플 순정 프레임워크만 씁니다.

---

## 3. 파일 구조 (전체 Swift 14개, 약 4,900줄)

```
Moodie Sky/
  Moodie_SkyApp.swift          앱 진입점 (13줄)
  MoodViewModel.swift          비즈니스 로직 전부 (1,834줄) ★가장 큼
  ContentView.swift            루트 TabView + 데이터 모델 + 공용 modifier (598줄)
  ContentView+Record.swift     '오늘' 탭 — 기록 화면
  ContentView+Timeline.swift   흐름/타임라인
  ContentView+Diary.swift      '다이어리' 탭 — 월별 캘린더 (380줄)
  ContentView+EntryDetails.swift  기록 상세
  ContentView+Reports.swift    리포트/인사이트
  ContentView+Settings.swift   '관리' 탭 — 설정 전체 (872줄)
  ContentView+Onboarding.swift 온보딩
  ContentView+Shared.swift     공용 뷰 조각
  ContentView+Preview.swift    프리뷰
  WidgetDataProvider.swift     위젯용 데이터 브리지
MoodieSkyWidgets/
  MoodieSkyWidgets.swift       위젯 (387줄)
Design/IconComposer/           앱 아이콘 소스 (Icon Composer)
docs/superpowers/              설계 문서 & 구현 계획
```

**주의:** 앱 아이콘 파일은 소스(`Design/`)와 빌드(`Moodie Sky/`) **두 군데에 있어 동기화가 필요**합니다.

---

## 4. 핵심 데이터 모델

```swift
@Model final class MoodEntry: Identifiable, Codable {
  @Attribute(.unique) var id: UUID
  var date: Date
  var weather: String        // "맑음" | "구름" | "비" | "폭풍" | "무지개"
  var emoji: String          // ☀️ ☁️ 🌧️ ⛈️ 🌈 (weather에서 파생)
  var note: String           // 한 줄 메모
  var intensity: Int = 3     // 1~5 감정 강도
  var updatedAt: Date
  var needsSync: Bool        // CloudKit 미반영 플래그
  var cloudRecordName: String?
}
```

날씨는 **이 5종이 전부**이며, 이모지는 `MoodViewModel.emoji(for:)`가 문자열에서 매핑합니다.

---

## 5. 화면 구조 (탭 4개)

| 탭 | 라벨 | SF Symbol | tag | 담당 파일 |
|---|---|---|---|---|
| 1 | 오늘 | `cloud` | 0 | `+Record` |
| 2 | 흐름 | `wind` | 2 | `+Timeline` / `+Reports` |
| 3 | 다이어리 | `book.pages` | 1 | `+Diary` |
| 4 | 관리 | `line.3.horizontal` | 3 | `+Settings` |

> tag 번호와 탭 순서가 일치하지 않습니다(0, 2, 1, 3). 탭 순서를 나중에 바꾼 흔적이며, `preferredStartTab`(시작 탭 설정)이 이 tag 값을 그대로 씁니다. **건드릴 때 주의.**

배경은 전 탭 공통으로 `MoodieBackground(colors:)` 그라디언트를 깔고, 탭바는 iOS 26 순정 Liquid Glass(`.tabBarMinimizeBehavior(.onScrollDown)`) + 브랜드 색 `vm.moodieTint`를 씁니다.

---

## 6. 주요 기능 (구현 완료)

- **기록**: 날씨 5종 + 강도(1~5) + 한 줄 메모. 하루 여러 개 기록 가능.
- **월별 캘린더**: 한 달 마음 날씨를 한눈에.
- **리포트**: 기록 빈도, 메모 길이, 평일/주말 감정 리듬 분석.
- **잠금**: Face ID + 앱 자체 패스코드 + **20자리 복구 키**. 앱 스위처 가림(`obscuresAppSwitcher`).
- **백업/복원**: CSV · JSON · **암호화 백업 `.moodieskybackup`**(비밀번호 → Salt+HKDF+AES-GCM). 전체 삭제 전 "백업 먼저" 유도 플로우 있음.
- **알림**: 요일 선택, 톤 스타일 선택, 방해금지 시간, **오늘 이미 썼으면 스킵**(`skipsReminderAfterTodayEntry`), 백업 리마인더.
- **위젯**: 홈 화면 위젯.
- **설정**: 시작 탭, 날짜 표기 스타일, 테마(`MoodAppTheme`), 기본 날씨.

---

## 7. 현재 진행 상황 (2026-08-03 기준)

- ✅ Liquid Glass 탭바 (인스타그램 스타일 = iOS 26 순정 동작) — 브랜드 tint 적용까지 완료
- ✅ 앱 아이콘 리디자인 (밤하늘 초승달, Icon Composer, 유리감 조정)
- ✅ 설정 화면 SwiftUI `Form` 전환
- ⬜ **Record / Diary / Flow 화면 리디자인 — 미착수** ← 다음 작업 후보

알려진 함정: 탭바 축소는 **스크롤할 콘텐츠가 짧으면 발동하지 않습니다.** 버그가 아니라 정상 동작입니다.

---

## 8. 형제 앱 (헷갈리지 않기)

같은 개발자의 다른 앱들이 있고, 특히 **Fitie와 섞이기 쉬우니** 주의해 주세요.

| 앱 | 플랫폼 | 구분점 |
|---|---|---|
| **Fitie** | iOS 26 | HealthKit 습관 트래커. Swift 6, XcodeGen, 테스트 있음, 동기화 없음 |
| **Vocabie** | iOS 26 | 단어 암기 앱. `@Observable` 사용 |
| **Vocabie Android** | Flutter | Vocabie 안드로이드판, 별도 코드베이스 |
| **Stewardie** | **macOS** | 메뉴바 정리 도구. AppKit + SwiftPM |

Moodie Sky는 이 중 **유일하게 CloudKit 동기화를 쓰고**, 로직이 `MoodViewModel` 하나에 집중된 `ObservableObject` MVVM입니다.
Liquid Glass 설계 원칙("유리는 조작 층에만, 커스텀 유리 금지")은 이 프로젝트에서 정해져 Vocabie로 승계됐어요.

---

## 9. 채팅에게 부탁하고 싶은 것

이 앱에 대해 이야기할 때:

1. **한국어로, 존댓말로** 답해 주세요. UI 문구를 제안할 땐 위 톤("~해요")에 맞춰 주세요.
2. 코드 제안은 **SwiftUI + 애플 순정 프레임워크만** 사용해 주세요. 외부 라이브러리 X.
3. 파일을 직접 볼 수 없다는 점을 감안해서, 특정 파일 내용이 필요하면 **먼저 붙여 달라고 요청**해 주세요. 추측으로 코드를 지어내지 마세요.
4. 실제 코드 수정은 Claude Code(로컬)에서 합니다. 채팅에서는 **설계·아이디어·문구·트러블슈팅 방향**을 잡아 주세요.
