---
name: world-retro
description: ZEPETO 작업 회고. 이번 세션 transcript·메모리·차단 이력 분석 → Worked/Didn't/Improvements 3-분류 → retro/YYYY-MM-DD.md 누적 → 사용자 컨펌 후 자가 patch 적용 (CLAUDE.md·키워드 사전·메모리·skill 본문). `/world-cycle`·Workflow 오케스트레이션 세션이면 cycle skill 본문 patch 후보도 함께 생성.
---

# /world-retro — 회고·자가 발전

작업 종료 시점 회고 + 하네스 자가 patch 흐름.

> **참고:** Stop hook이 임계 초과 작업 시 본 skill 호출을 자동 제안. 사용자가 명시 호출도 가능.

## 입력
- (선택) `<topic>` — 회고 대상 작업명 (기본: 현 세션)
- (선택) `--small` — 작은 작업 강제 회고 (임계 미만이어도 진행)

## 절차

### 단계 1: 작업 분량 임계 확인

- 도구 호출 ≥ 30 OR
- 사용자 redirect ≥ 1회 OR
- 결정·학습 키워드 ≥ 3회 등장 (`확정`·`결정`·`우회`·`함정` 등)

임계 미만이면 회고 skip 권장 (`--small` 옵션으로 강제 가능).

### 단계 2: 이번 작업 transcript + 사용 메모리 + 차단 이력 분석

1. transcript 휴리스틱:
   - 이번 세션 사용된 메모리 (system-reminder에 surface된 것, 자체 memory 시스템 사용 시)
   - 사용자 redirect 횟수
   - PreToolUse 차단 이력 (`%TEMP%\world-starter\preTool-block.log`)
   - **이번 세션이 `/world-cycle` 호출이었는지** (cycle Wave 분배·subagent 호출·완료 보고 흔적)
   - **이번 세션이 Workflow 오케스트레이션 세션이었는지** (스크립트 오케스트레이션·StructuredOutput schema subagent dispatch·resume 캐시 흔적) — 해당 시 `/world-cycle`과 동급으로 단계 3.5 cycle-skill-augment 채널 발동
   - **★ 검증/마무리 에이전트 사망 여부** — Workflow 마지막 phase(verify 등)나 단일 마무리 subagent가 API·모델 이슈로 null 반환했으면 그 검증은 누락된 것. 오케스트레이터가 인라인으로 직접 수행(tsc·핵심 grep) 후 회고 진행 — 검증을 외부 에이전트 생존에 걸지 말 것.
   - **★ 조사/리뷰 워크플로 schema = 사실/판단 분리** — 조사·리뷰 fan-out의 StructuredOutput schema는 **사실(currentState·fileRefs·근거)** 과 **판단(options·recommendation)** 을 분리 필드로 둘 것. 요구사항이 조사 중 바뀌면 판단은 무효화돼도 사실(어디·무엇)은 재사용 가능 → 헛조사 최소화. (실사례: 5-agent 조사 중 사용자 요구사항 변경 → agent 2개 판단은 폐기됐으나 fileRefs/currentState는 전량 회수됨.)
2. 메모리 grep 우선 (자체 memory 시스템 사용 시):
   - `feedback_*` 전체 (어떤 결이 이번에 적용·미적용됐는지 비교)
   - 이전 retro 누적 (`~/.claude/world-starter/retro/*.md`)

### 단계 3: 3-분류 회고 작성

| 분류 | 정의 | 예시 |
|---|---|---|
| ✓ **Worked** | 적용된 결·메모리·skill이 정확히 작동 | "mock-first 결 그대로 적용 → mock 일괄 포팅 잘 됨" |
| ✗ **Didn't** | 놓친 결·redirect 받은 지점·새 함정 | "사용자가 figma 라이브 접근 모드 요청했는데 PNG부터 시도해서 redirect 받음" |
| → **Improvements** | patch 후보 (CLAUDE.md bullet·키워드 매핑·새 메모리·skill 보강) | "키워드 사전에 `figma 라이브` → 관련 reference 매핑 추가" |

### 단계 3.5: `/world-cycle` 또는 Workflow 오케스트레이션 세션이었으면 cycle skill 본문 patch 후보 별도 생성

단계 2에서 "이번 세션이 `/world-cycle` 호출 또는 Workflow 오케스트레이션 세션이었음" 판정된 경우, Improvements 후보의 별도 sub-카테고리 **`cycle-skill-augment`** 를 추가 생성 (Workflow 세션도 동일 채널 — cycle이 아닌 Workflow 세션이라 3.5가 미발동하는 사각지대를 막기 위함). 다음 3 차원에서 추출:

| 차원 | 추출 시그널 |
|---|---|
| 효율 개선 | "Wave N에서 subagent X명이 같은 파일 충돌", "재시도 N회 — 같은 high-severity finding 반복", "특정 종료 조건이 너무 빨라/늦어" |
| 새 함정 | "Puerts/UI Toolkit/Unity 새 패턴이 cycle 적대적 리뷰에서 미감지", "ZepetoScript 컴파일 실패 양상 1종 추가" |
| 종료 조건 보정 | "ready log만으로 충분한 task인지 / Play mode 검증까지 필요한지 재정의", "medium-severity finding 누적 임계 등" |

추출 결과는 `~/.claude/skills/world-cycle/SKILL.md` 본문 v+1 patch 후보로 표기:

```markdown
### → cycle-skill-augment 후보
- [type: cycle-skill-augment] §2.3 적대적 리뷰 reference에 `feedback_<new>` 추가
- [type: cycle-skill-augment] §3 종료 조건 4번에 "<보정 조건>" 추가
- [type: cycle-skill-augment] §2.4 Wave 통합 점검에 "<체크>" 추가
```

> cycle-skill-augment도 매 회고 ≤ 3 한도에 포함 (단계 5.3 안전 정책). cycle skill 본문이 1회 회고당 ≤ 3 patch로 점진 발전.

### 단계 4: retro/YYYY-MM-DD.md에 누적

위치: `~/.claude/world-starter/retro/YYYY-MM-DD.md` (이미 있으면 append):

```markdown
# Retro YYYY-MM-DD

## 세션 메타
- 작업: <topic>
- 도구 호출 수: <N>
- 사용자 redirect: <N>
- PreToolUse 차단: <N>

## ✓ Worked
- ...

## ✗ Didn't
- ...

## → Improvements (patch 후보)
1. <후보 1>
2. <후보 2>
3. <후보 3>

## 자가 patch 결정
- [ ] 후보 1: 적용 / 거부
- [ ] 후보 2: ...
```

### 단계 5: 자가 patch 후보 제시 + 사용자 컨펌 + 적용

#### 5.1 사용자에게 patch 후보 표시

```
Improvements 후보 (≤3건):
1. [type] <간략 설명> → 적용 대상: <파일·위치>
2. ...
```

#### 5.2 사용자 컨펌 받기

- 명시 컨펌 (예: "1번 적용", "2번 거부", "모두 적용") 받기
- 거부된 항목은 retro 파일에 "rejected" 표시

#### 5.3 patch 적용 (컨펌 후만)

**허용 patch 종류**:

| Type | 적용 대상 | 안전 정책 |
|---|---|---|
| `memory-add` | 새 `feedback_*.md` 또는 `reference_*.md` 추가 | 사용자 컨펌 후 |
| `claude-md-add` | `~/.claude/CLAUDE.md`에 bullet 추가 | 사용자 컨펌 + diff 표시 |
| `keyword-dict-add` | `keyword-dict.json`에 매핑 추가 | 사용자 컨펌 후 |
| `skill-augment` | `~/.claude/skills/world-*/SKILL.md` 단계 보강 | 사용자 컨펌 + diff 표시 |
| `cycle-skill-augment` | `~/.claude/skills/world-cycle/SKILL.md` 본문 patch (단계 3.5에서 추출) | 사용자 컨펌 + diff 표시. AI 월드 파이프라인 점진 발전 채널 |

**금지 patch 종류** (v1):
- 기존 결 **삭제·크게 변경** — 무조건 사용자 컨펌 + design doc 갱신 동반
- Hook 동작 변경 — 무조건 사용자 컨펌 + design doc 갱신

#### 5.4 적용 후 retro 파일에 결과 누적

```markdown
## 자가 patch 결정
- [x] 후보 1: 적용 → `keyword-dict.json` line 84에 매핑 추가
- [ ] 후보 2: 거부 (사유: 너무 일찍 일반화)
- [x] 후보 3: 적용 → `CLAUDE.md` §2.2에 bullet 추가
```

### 단계 6: rollback 안내

문제 발생 시:
1. `git -C ~/.claude/world-starter log` 로 retro patch commit 확인
2. `git -C ~/.claude/world-starter revert <hash>` 로 즉시 rollback
3. `~/.claude/CLAUDE.md`나 `keyword-dict.json` 변경도 같은 commit에서 rollback

## 출력
- `~/.claude/world-starter/retro/YYYY-MM-DD.md`
- (컨펌 시) CLAUDE.md, keyword-dict.json, memory, SKILL.md patch + git commit

## 안전 한도
- 매 회고당 patch 후보 ≤ 3건 (디폴트)
- 사용자가 더 많이 적용하려면 명시 컨펌 (한도 위반)
- 기존 삭제·큰 변경은 별도 design doc 갱신 동반

## 자가 발전 cadence
- 매일: 작업 종료 시 `/world-retro`
- 주 1회 (선택, v1.1+): 주간 요약
- 월 1회 (선택, v1.1+): design doc 자체 갱신
