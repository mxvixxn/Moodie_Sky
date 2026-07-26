# Liquid Glass 탭바 (Instagram 스타일) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 두 앱(Moodie Sky, Fitie)의 하단 탭바를 iOS 26 순정 Liquid Glass 동작(떠 있는 유리 알약 + 스크롤 시 축소)으로 마감하고, Moodie Sky 선택 탭 색을 감성 브랜드 톤으로 맞춘다.

**Architecture:** 커스텀 뷰를 만들지 않고 애플 순정 `TabView` + `.tabBarMinimizeBehavior(.onScrollDown)` + `.tint(...)` 세 modifier만 사용/조정한다. 신규 로직·상태·데이터 흐름 없음.

**Tech Stack:** SwiftUI, iOS 26 SDK (`tabBarMinimizeBehavior` API), Xcode 26.6, iPhone 17 Pro 시뮬레이터 (iOS 26.5).

## Global Constraints

- 배포 타깃: Moodie Sky iOS 26.4, Fitie iOS 26.0 — `tabBarMinimizeBehavior`는 iOS 26.0+ API이므로 두 앱 모두 `#available` 게이트 불필요.
- 애플 순정 `TabView` 동작을 벗어나는 커스텀 유리 바를 만들지 않는다.
- 탭 구성/태그/라벨/아이콘/네비게이션 로직을 변경하지 않는다.
- Fitie 수정은 메인 워킹트리 `~/Desktop/Fitie/Fitie/Views/RootView.swift`만. `.claude/worktrees/fitie-v1.1/` 사본은 건드리지 않는다.
- 각 태스크의 검증은 빌드 성공 + 시뮬레이터 스크린샷 육안 확인 (이 작업엔 XCTest 단위 테스트가 적용되지 않음).
- 두 앱은 별도 git 저장소. 각 태스크의 커밋은 해당 앱 저장소에서 수행한다.

---

### Task 1: Moodie Sky — 탭바 감성 폴리시 (tint + 죽은 코드 정리)

**Files:**
- Modify: `~/Desktop/Moodie Sky/Moodie Sky/ContentView.swift` (`rootTabView`, 약 430–437행)
- 참조(수정 없음): `~/Desktop/Moodie Sky/Moodie Sky/MoodViewModel.swift:325` (`moodieTint` 정의)

**Interfaces:**
- Consumes: `vm.moodieTint` — `let moodieTint = Color(red: 0.28, green: 0.48, blue: 0.58)` (기존, `MoodViewModel.swift:325`). `vm`은 `ContentView`가 이미 보유한 `MoodViewModel` 인스턴스.
- Produces: 없음 (외부에서 참조하는 새 심볼 없음).

- [ ] **Step 1: 현재 `rootTabView` 확인**

`ContentView.swift`에서 아래 블록을 찾는다 (약 430–437행):

```swift
  @ViewBuilder
  var rootTabView: some View {
    if #available(iOS 18.0, *) {
      tabs
        .tabBarMinimizeBehavior(.onScrollDown)
    } else {
      tabs
    }
  }
```

- [ ] **Step 2: `#available` 게이트 제거 + `.tint` 추가**

위 블록을 아래로 교체한다. `#available` 분기는 배포 타깃 26.4에서 항상 참이라 제거하고, 선택 탭 색을 브랜드 톤으로 지정하는 `.tint(vm.moodieTint)`를 추가한다:

```swift
  @ViewBuilder
  var rootTabView: some View {
    tabs
      .tabBarMinimizeBehavior(.onScrollDown)
      .tint(vm.moodieTint)
  }
```

- [ ] **Step 3: 빌드**

Run:
```bash
cd "/Users/mxvixxn/Desktop/Moodie Sky" && xcodebuild -project "Moodie Sky.xcodeproj" -scheme "Moodie Sky" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`, 경고/에러 없음.

- [ ] **Step 4: 시뮬레이터 육안 검증**

앱을 시뮬레이터에 설치·실행하고 스크린샷으로 확인:
- 하단 탭바가 떠 있는 유리 알약으로 표시된다.
- **선택된 탭의 아이콘/라벨 색이 쨍한 시스템 블루가 아니라 차분한 슬레이트 블루(`moodieTint`)다.**
- 다이어리 등 스크롤 가능한 탭에서 아래로 스크롤하면 탭바가 작은 원형으로 축소된다(회귀 없음 확인).

- [ ] **Step 5: 커밋**

```bash
cd "/Users/mxvixxn/Desktop/Moodie Sky" && git add "Moodie Sky/ContentView.swift" && git commit -m "feat: 탭바 선택 색을 브랜드 톤(moodieTint)으로 지정, 죽은 iOS18 게이트 제거

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: Fitie — 스크롤 시 탭바 축소 동작 추가

**Files:**
- Modify: `~/Desktop/Fitie/Fitie/Views/RootView.swift` (`body`의 `TabView` 체인, 약 27–37행)

**Interfaces:**
- Consumes: 없음 (기존 `TabView`에 modifier 한 줄 추가).
- Produces: 없음.

- [ ] **Step 1: 현재 `TabView` 체인 확인**

`RootView.swift`의 `body`에서 아래 구조를 찾는다 (약 27–40행). `TabView { ... }` 닫는 중괄호 뒤에 `.tint(Theme.accent)`가 이어진다:

```swift
        TabView(selection: $tab) {
            TodayView(refresher: refresher, onShowInsights: { tab = 1 })
                .tabItem { Label("오늘", systemImage: "checklist") }
                .tag(0)
            InsightsView()
                .tabItem { Label("인사이트", systemImage: "sparkles") }
                .tag(1)
            SettingsView(health: health)
                .tabItem { Label("설정", systemImage: "gearshape") }
                .tag(2)
        }
        .tint(Theme.accent)
```

- [ ] **Step 2: `.tabBarMinimizeBehavior(.onScrollDown)` 추가**

`TabView`의 닫는 중괄호 `}` 바로 다음 줄, `.tint(Theme.accent)` 앞에 한 줄을 추가한다:

```swift
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(Theme.accent)
```

(나머지 `.environment(...)`, `.preferredColorScheme(...)` 등은 그대로 유지.)

- [ ] **Step 3: 빌드**

Run:
```bash
cd ~/Desktop/Fitie && xcodebuild -project "Fitie.xcodeproj" -scheme "Fitie" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`, 경고/에러 없음.
(스킴명이 다르면 `xcodebuild -project "Fitie.xcodeproj" -list`로 확인.)

- [ ] **Step 4: 시뮬레이터 육안 검증**

앱을 실행하고 스크린샷으로 확인:
- 하단 탭바가 떠 있는 유리 알약으로 표시된다 (인디고 `Theme.accent` 선택 색 유지).
- **오늘/인사이트 등 스크롤 가능한 탭에서 아래로 스크롤하면 탭바가 작은 원형으로 축소된다.**

- [ ] **Step 5: 커밋**

```bash
cd ~/Desktop/Fitie && git add "Fitie/Views/RootView.swift" && git commit -m "feat: 하단 탭바 스크롤 시 축소 동작 추가 (Liquid Glass)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage:**
- 스펙 목표 1 (Fitie 축소) → Task 2. ✅
- 스펙 목표 2 (Moodie Sky 선택 색 브랜드 톤) → Task 1 Step 2. ✅
- 스펙 목표 3 (두 앱 유리+축소 육안 검증) → Task 1 Step 4, Task 2 Step 4. ✅
- 스펙 목표 4 (커스텀 미제작) → Global Constraints + 두 태스크 모두 순정 modifier만 사용. ✅
- 스펙 컴포넌트 1 죽은 코드 정리 → Task 1 Step 2. ✅
- 스펙 컴포넌트 2 Fitie tint 유지 → Task 2 Step 2에서 `.tint(Theme.accent)` 보존 명시. ✅

**Placeholder scan:** TBD/TODO/"적절히 처리" 등 없음. 모든 코드 단계에 실제 코드 포함. ✅

**Type consistency:** `moodieTint`(Color) 참조는 정의(`MoodViewModel.swift:325`)와 일치. `tabBarMinimizeBehavior(.onScrollDown)` / `.tint(...)` 시그니처 두 태스크 동일. ✅
