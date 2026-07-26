# Moodie Sky — Liquid Glass 앱 아이콘 소스

Icon Composer(Xcode 26+)로 Liquid Glass 아이콘을 만들기 위한 **납작한 레이어 소스**입니다.
그림자·하이라이트·그라데이션·글로우는 넣지 않았습니다 — 유리 질감과 반사광(specular)은 Icon Composer가 입힙니다.

## 파일

| 파일 | 역할 | 비고 |
|------|------|------|
| `moon.svg` | 전경 — 초승달 | 흰색, 투명 배경 |
| `stars.svg` | 중간 — 별/반짝임 | 흰색, 투명 배경 |
| `background.svg` | 배경(참고용) | 밤하늘 그라데이션. 실제로는 Icon Composer의 배경 기능을 쓰는 걸 권장 |

- 캔버스: 1024×1024, 라운드 마스크(둥근 사각형) **없음** (풀 블리드)
- 전경은 흰색 → 유리 하이라이트가 선명하게 뜸

## Icon Composer 사용 순서

1. Icon Composer 실행 → 새 아이콘 생성
2. 배경: 시스템 배경 또는 커스텀 그라데이션 지정 (`background.svg`를 참고해 남색→인디고)
3. `stars.svg`, `moon.svg`를 캔버스로 드래그해서 각각 레이어로 추가
4. 레이어를 뎁스 그룹(최대 4개)으로 정리 — 달을 가장 위(가장 앞) 뎁스로
5. 각 레이어에 blur / shadow / specular highlight 조정
6. Light / Dark / Clear / Tinted 모드에서 확인
7. `.icon` 파일로 저장 → Xcode 26 프로젝트의 App Icon에 연결

## 주의

- **Icon Composer / `.icon` 은 Xcode 26 이상**에서만 지원. 현재 프로젝트의 기존
  `AppIcon.appiconset`(PNG 3종: 기본/Dark/Tinted)는 하위 호환용으로 유지.
- iOS 26 미만 기기에서는 Liquid Glass 없이 기존 방식으로 폴백됩니다.

## 수정 요청 시

달 크기/위치, 별 개수/배치, 배경 색은 SVG의 숫자만 바꾸면 됩니다.
Claude에게 "달 더 크게 / 별 하나 빼줘 / 배경 더 보라색" 처럼 말하면 바로 반영합니다.
