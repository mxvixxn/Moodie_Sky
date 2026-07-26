# Liquid Glass 탭바 (Instagram 스타일) — 설계 문서

- **날짜**: 2026-07-26
- **대상 앱**: Moodie Sky (`~/Desktop/Moodie Sky`), Fitie (`~/Desktop/Fitie`)
- **레퍼런스**: Instagram iOS 앱의 하단 탭바 (떠 있는 유리 알약, 스크롤 시 축소)

## 배경 / 동기

사용자가 인스타그램의 하단 탭바를 레퍼런스로 제시. "투명하게 비쳐 감성적이면서도, 유동적으로
화면에 집중할 수 있도록 축소되는 바"를 두 앱에 적용하고 싶다는 요청.

**핵심 발견**: 인스타그램의 그 탭바는 커스텀이 아니라 **애플 iOS 26 순정 Liquid Glass `TabView`**다.
떠 있는 유리 알약, 배경 비침, 스크롤 시 축소가 전부 시스템 기본 동작이다. 두 앱 모두 배포 타깃이
iOS 26 (Moodie Sky 26.4 / Fitie 26.0)이므로 이 순정 동작을 그대로 쓸 수 있다.

**실제 실행으로 검증한 현재 상태** (iPhone 17 Pro 시뮬레이터, iOS 26):

| | 유리 탭바(순정) | 스크롤 시 축소 | 선택 탭 tint |
|---|---|---|---|
| Moodie Sky | ✅ 자동 적용됨 | ✅ 동작 확인 (`.tabBarMinimizeBehavior(.onScrollDown)`) | ⚠️ 기본 시스템 블루(앱 무드와 불일치) |
| Fitie | ✅ 자동 적용됨 | ❌ 없음 | ✅ `Theme.accent`(인디고) |

따라서 이 작업은 신규 기능 개발이 아니라 **순정 기능의 마감/폴리시**다.

## 목표 (성공 기준)

1. Fitie 탭바가 스크롤 시 축소된다 (Moodie Sky와 동일 동작).
2. Moodie Sky 탭바의 선택 색이 앱의 감성 브랜드 톤(차분한 슬레이트 블루)으로 바뀐다.
3. 두 앱 모두 시뮬레이터에서 유리 비침 + 축소 동작이 육안으로 확인된다.
4. 애플 순정 `TabView` 동작을 벗어나는 커스텀 구현을 만들지 않는다.

## 비목표 (범위 제외 — YAGNI)

- 커스텀 유리 바(`.ultraThinMaterial` 등) 직접 제작. 순정보다 열등하고 OS 업데이트마다 깨짐.
- 탭 라벨 제거 / 아이콘 세트 교체 / 탭 구성 변경 등 요청 범위 밖 리디자인.
- iOS 26 미만 폴백. 두 앱 모두 배포 타깃이 iOS 26이라 불필요.

## 설계

### 컴포넌트 1 — Moodie Sky 탭바 감성 폴리시

**파일**: `Moodie Sky/Moodie Sky/ContentView.swift`

- **선택 탭 tint**: `TabView`(또는 `tabs` 뷰)에 `.tint(vm.moodieTint)` 추가.
  `moodieTint = Color(red: 0.28, green: 0.48, blue: 0.58)` — 이미 정의된 앱 브랜드 슬레이트 블루
  (`MoodViewModel.swift:325`). 현재 tint 미지정으로 선택 탭이 기본 시스템 블루로 표시되는 것을
  브랜드 톤으로 교체. 감성적 "비치는 유리" 인상 완성.
- **죽은 코드 정리**: `rootTabView`(`ContentView.swift:430-437`)의 `#available(iOS 18.0, *)` 분기 제거.
  배포 타깃이 26.4라 항상 참이며, `.tabBarMinimizeBehavior`는 iOS 26.0+ API이므로 게이트가 오해를
  부른다. `tabs.tabBarMinimizeBehavior(.onScrollDown)`를 직접 호출하도록 단순화.

**의존성**: `vm.moodieTint`(기존), `tabBarMinimizeBehavior`(iOS 26 SDK).
**인터페이스 변화 없음**: 탭 구성/태그/네비게이션 로직 불변.

### 컴포넌트 2 — Fitie 축소 동작 추가

**파일**: `Fitie/Fitie/Views/RootView.swift`

- `body`의 `TabView(selection: $tab) { ... }` 체인에 `.tabBarMinimizeBehavior(.onScrollDown)` 추가.
  기존 `.tint(Theme.accent)` 등 다른 modifier와 나란히 배치. 배포 타깃 26.0이라 게이트 불필요.
- 기존 `.tint(Theme.accent)`(인디고)는 유지 — Fitie는 이미 적절한 톤.

**의존성**: `tabBarMinimizeBehavior`(iOS 26 SDK).
**주의**: Fitie에는 `.claude/worktrees/fitie-v1.1/`에 워크트리 사본이 존재. 메인 워킹트리
(`Fitie/Fitie/Views/RootView.swift`)만 수정한다.

### 데이터 흐름 / 에러 처리

- 순수 뷰 modifier 추가·조정만 있으므로 데이터 흐름/상태 변화 없음.
- 축소 동작은 스크롤 뷰가 탭바 아래로 콘텐츠를 흐르게 할 때 시스템이 자동 처리. 두 앱 모두
  탭 콘텐츠가 스크롤 컨테이너이므로 별도 처리 불필요(검증 단계에서 확인).
- 실패 모드 없음(런타임 로직 아님). 유일한 리스크는 컴파일/시각적 회귀 → 빌드 + 스크린샷으로 검증.

## 검증 계획

1. **Moodie Sky**: 빌드 → 시뮬레이터 실행 → 탭바 일반 상태(선택 탭이 슬레이트 블루인지) +
   스크롤 후 축소 상태 스크린샷 확인.
2. **Fitie**: 빌드 → 시뮬레이터 실행 → 스크롤 시 축소되는지 스크린샷 확인.
3. 두 앱 모두 컴파일 경고/에러 없음.

## 참고

- iOS 26 Liquid Glass `TabView`는 배경 콘텐츠 밝기에 따라 유리 질감이 자동 적응. Moodie Sky는
  밝은 파스텔 배경이라 유리가 흰빛으로, Instagram 피드처럼 어둡고 컬러풀한 콘텐츠 위에서는 더
  투명하게 보이는 것이 정상. 이는 버그가 아니라 순정 적응 동작이다.
- 관련 메모리: `project_redesign_status.md`, `project_app_icon.md`.
