---
name: world-doc
description: ZEPETO 기획서(단일 markdown, 섹션 0~12 표준) 작성. brainstorm → figma 라이브 시안 → spec → 오픈 이슈 → self-review → 사용자 리뷰 게이트.
---

# /world-doc — 기획서 쓰기

ZEPETO 신규 기능·UI·시스템 기획서를 단일 markdown으로 작성하는 절차.

> **참고:** 본 skill은 brainstorming skill을 내부에서 참조한다. 자율 모드(balanced)에선 brainstorming의 매 단계 컨펌을 reasonable call로 우회.

## 입력
- `<topic>` — 기획 주제 (예: "인벤토리 UI 리디자인", "PORTING_LOG 표준화")
- (선택) figma 시안 URL
- (선택) 의도·제약 사전 기재

## 절차

### 단계 1: 의도·범위 brainstorm

1. 메모리 grep 우선순위 (자체 memory 시스템을 두고 있다면):
   - 동일 프로젝트의 기존 기획서 양식 (`project_<프로젝트>_*`)
   - figma 라이브 워크플로우 참고 메모리
   - 새 기능 전 기존 것부터 grep하는 결
   - 사용자 UI 결정 보존 결
2. 사용자에게 의도·범위·청중 확인 (필요 시 1회)
3. 기존 기획서 grep으로 유사 결 확인

### 단계 2: figma 라이브 시안 수집

1. figma MCP 활용 (연결 설정은 각자 환경에 맞게)
2. section 전체 metadata 받기 → 큰 페이지면 subagent jq 분석
3. frame 단위 screenshot으로 정체 매핑
4. **★ 시안 ref + "X로 가자/이렇게/이 비율" 표현 수신 시 — 어느 차원(IA / 비율 / 어휘 / 컬러)인지 1줄 확인 후 진행** (CLAUDE.md §1-8 참고). 명시 안 된 차원은 기존안 유지, 임의 다중 차원 변경 금지

### 단계 3: spec 골격 작성 (섹션 0~12 표준)

표준 섹션:
- §0 스코프 (한 줄)
- §1 배경
- §2 문제 정의
- §3 목표·성공 기준
- §4 정보 구조 (IA)
- §5 화면 명세 (5.1~5.N)
- §6 인터랙션·플로우
- §7 시스템·알고리즘
- §8 UI/UX 개선 (시안 대비)
- §9 데이터·시스템 디펜던시
- §10 오픈 이슈 (A·B·C·D 카테고리)
- §11 부록 (시안→구현 매핑)
- §12 다음 단계

출력 위치: `Desktop\<프로젝트>-기획\YYYY-MM-DD-<topic>-design.md`

### 단계 4: 오픈 이슈 + 잔존 가정 표기

1. 결정 불가 항목은 `[확인 필요]` 표기
2. §10에 카테고리 분류 (시안 부재 / 정책 / 알고리즘 / 메트릭)
3. 가정 처리 시 사유 명시
4. **★ 사용자 명시 최종 목표(예: "엑셀 조작만으로", "전부 지금")는 오픈 이슈/미정 옵션(A/B)으로 남기지 말고 단정 반영** — 미정 spec·plan은 거부를 부른다 (CLAUDE.md §3 참고)

### 단계 5: self-review + 사용자 리뷰 게이트

1. self-review 4종:
   - placeholder scan
   - internal consistency
   - scope check
   - ambiguity check
2. 사용자에게 spec 파일 리뷰 요청
3. 변경 사항 반영 후 v1 확정
4. **★ 결정 수렴을 반영한 뒤엔 적대적 검증 2-lens Workflow** (실사례: medium severity 3건이 구현 오류를 예방):
   - lens A **결정 대조**: 확정 결정 목록을 프롬프트에 명시 → 문서와 1건씩 대조 (다르게 적힘 / 언급 누락 / 결정 이전 잔재)
   - lens B **내부 모순**: 처음 읽는 구현자 관점 — 섹션 간 상충·깨진 §참조·수치 합계·드랍 기능이 검증 게이트에 잔존
   - finding 처리: high 0이어도 **medium은 다음 단계 착수 전 문서 보정**. 카운트를 쓰면(예: "파생 5건") 그 자리에 목록 열거까지.

## 출력
- `Desktop\<프로젝트>-기획\YYYY-MM-DD-<topic>-design.md`

## 메모리 grep 패턴 (자체 memory 시스템 사용 시)
- `project_*_redesign`, `project_<프로젝트>_*`
- figma 워크플로우 관련 reference
- 기존 것부터 grep하는 feedback
- 사용자 UI 결정 보존 feedback

## 안전 정책
- 승인되지 않은 외부 LLM으로 데이터 라우팅 지양 (Claude Code 권장, 조직이 승인한 다른 도구 병행 가능)
- 사용자 명시 결정 보존
- 조직 고유 정보(기획·경제 로직 등)는 본 markdown에 직접 작성 OK (외부 전송 X)

## 차후 연계
- 작업 완료 후 `/world-retro` 호출 권장
- spec 완료 후 `/world-build` (구현)으로 연계 가능
- M단위 자율 구현이 목표면 spec → superpowers writing-plans로 plan 작성 → `/world-cycle` (CLAUDE.md §2.5 채널)
