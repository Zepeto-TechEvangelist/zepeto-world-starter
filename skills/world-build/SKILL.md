---
name: world-build
description: ZEPETO 월드(커스텀 Unity SDK 프로젝트 or buildit) 구현·포팅. spec grep → mock-first → 일괄 포팅 → PORTING_LOG 갱신.
---

# /world-build — 월드 만들기

ZEPETO 월드 구현·포팅 작업. 커스텀 Unity SDK 프로젝트(C#) / buildit(TS) 두 환경.

> **참고:** 본 skill은 `/world-doc` 기획서가 존재할 때 가장 효과적. 없으면 안내만 하고 계속 진행.

## 입력
- `<topic>` — 월드 작업 주제 (예: "PORTING_LOG 갱신", "검색기능 UI mock")
- (선택) 환경 — `unity-sdk` / `buildit`
- (선택) 기획서 경로

## 절차

### 단계 1: 기획서 grep

1. `/world-doc`로 만든 기획서가 `Desktop\<프로젝트>-기획\*-design.md`에 있는지 확인
2. 없으면 사용자에게 알림 ("기획서 없네, 그래도 진행할까?") — 강제 X
3. (선택) 자체 memory 시스템을 운영하고 있다면 관련 항목부터 grep — 이 skill 자체는 memory 유무와 무관하게 동작:
   - buildit 포팅 사례·환경 노트
   - TS 런타임 강제 규약
   - base+layered 원칙
   - UI Toolkit 트랩 카탈로그

### 단계 1.5: 정찰(recon) — Unity 클릭 전 가정 실측 (★비싼 왕복 방지)

포팅·구현 착수 전, 대상 씬 구성·셰이더/머티리얼·의존성 폐포·카메라/SDK API 가정을 정찰(recon)로 일괄 실측 → 산출물을 spec/PORTING_LOG에 명시. Unity·재베이크 왕복은 비개발자에게 비싸므로 가정 위에 쌓기 전 확인. 규모 크면 Workflow 오케스트레이션으로 병렬 정찰 (실제 포팅 사례: cullingMask 오답·셰이더 마젠타·의존성 폐포를 착수 전 사전 포착한 경험 기반).

### 단계 2: 트랙 분기 — UI-heavy는 mock-first, 공간/분위기는 월드 크래프트

- **UI-heavy 장르(소셜·수집·리듬 등)** → mock 먼저:
  1. UI 요소는 무조건 mock 먼저. mock 위치: `Desktop\<프로젝트>\assets\uitk\` 또는 `assets\`
  2. 패널별 mock → port 반복 금지. 모든 mock 작성 → 승인 → 일괄 포트
- **공간·분위기 장르(호러·탐험·워킹심·방탈출 등)** → **월드 크래프트 트랙** (UI가 본체가 아님):
  - 씬 구성·조명 베이크·환경 오디오·카메라 리그(1인칭 등)·의존성 폐포 포팅이 본체. 공식맵 기반 포팅이면 아트-온리 포팅 파이프라인 참고, 1인칭 카메라는 전역 1인칭 설정 참고.
  - mock 대신 recon 산출물(단계 1.5)이 시안 역할.

### 단계 3: 일괄 포팅 (사용자 승인 후)

#### 커스텀 Unity SDK 프로젝트(C#) 환경
- 위치: `<your-repo>\Assets\<YourFeature>\` (프로젝트별 실제 경로로 치환)
- 패턴: 씬 컨트롤러는 inline 헬퍼 우선 (컴포넌트 분리보다 단일 컨트롤러 내 inline 처리가 유지보수에 유리했던 경험)
- UI: uGUI + `typeof(RectTransform)` 패턴
- 함정: `gameObject.SetActive` 동일 GO 함정, `GetComponent + ??` fake null 패턴 주의

#### buildit(TS) 환경
- 위치 (정본): **작업 대상 월드 프로젝트(세션 입력 명시)** — 프로젝트마다 실제 루트 경로를 세션 시작 시 확정할 것. 미지정 시 사용자에게 확인.
  - ★ 다른 AI 코딩 도구로 병행 작업 중인 복사본이 있다면 — 별도 물리 복사본과 섞이지 않도록 작업 전 인수인계 문서/PORTING_LOG 갱신분을 먼저 확인
- 패턴: ZepetoScriptBehaviour 기반
- UI: UI Toolkit USS
- **★ 자체 .ts 작성 전 Puerts(ZepetoScript) 컴파일 트랩 카탈로그 1차 점검 필수** (자체 memory나 팀 위키에 누적해 둔 함정 목록이 있다면 그것부터)
- 함정: UIDocument `Q<T>()` Puerts 이슈, TS generic variance 이슈

### 단계 4: PORTING_LOG 자동 갱신

1. 위치: **작업 대상 월드 프로젝트의 PORTING_LOG.md**
2. 컨벤션:
   - 단계·결정·이슈·툴 후보 누적
   - 모든 작업이 자동화 툴 추출 후보
3. entry 양식:

```markdown
## YYYY-MM-DD <slice 이름>
- 단계: <단계 번호·이름>
- 결정: <핵심 결정>
- 이슈: <발생 함정·해결>
- 툴 후보: <추후 자동화 가능 부분>
```

### 단계 5: /world-verify 호출 안내 (v1.1+)

1. 작업 완료 후 manual 검증 체크리스트:
   - [ ] mock과 port 시각 일치
   - [ ] 함정 관련 재발 없음
   - [ ] PORTING_LOG entry 추가
   - [ ] Unity Console 0 error
   - [ ] **모달/팝업 컨트롤러는 init `[X] ready` 로그로 통과 처리 X — 실제 `Open()`/`render()` 경로까지 검증**
     (클릭 트리거 불가 시 임시로 `Start()`에서 1회 자동 호출 → 예외 0 확인 → 임시 코드 되돌림. `ready` 로그는 Start 끝일 뿐, render는 클릭 시점에만 도는 함정)
   - [ ] **MCP `find_gameobjects`로 인스턴스 prefab 확인 시 `(Clone)` 접미사 고려** (Object.Instantiate는 "(Clone)" 붙임 → by_name 정확일치 0을 "로드 실패"로 오진 금지)
   - [ ] **★ QR/출시 빌드 전 실기기 4종 점검** — ① 런타임 커스텀 .cs 잔존 grep (Editor 폴더 밖 MonoBehaviour = 기기 미포함) ② UI 문자열 비ASCII 글리프 감사 (지원 문자셋 밖 = 빈칸/이모지 깨짐) ③ 터치 타겟 <110px 스캔 (1080 기준 7mm) ④ Build Settings 씬 구성 확인 (스테일 부트씬 잔존 여부)
   - [ ] **데이터 CSV 잠김 해제 게이트** — 로컬 CSV가 엑셀에 열려 있으면 빌드 Sharing violation 부분실패(작은 패키지)·Play 시 `Resources.Load` = null — 빌드/Play 전 편집기 닫기

## 출력
- Unity·buildit asset 변경
- `PORTING_LOG.md` entries

## 안전 정책
- **보호 레포 push 금지** (PreToolUse hook이 `config/preserve-list.json`의 `deny_commands` 규칙으로 자동 차단 — 본인 레포명으로 채워 넣을 것)
- 사용자 명시 UI 결정 보존
- mock-first
- 외부 폰트 임포트 금지 (ZEPETO 기본 자산 유지)

## 차후 연계
- 작업 완료 후 `/world-retro` 호출
- 새 함정 발견 시 memory/노트 저장 후보
