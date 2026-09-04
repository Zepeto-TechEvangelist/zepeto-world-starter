---
name: world-cycle
description: ZEPETO 월드 자율 구현 사이클. plan을 Wave로 분배 → 각 task 병렬 subagent 구현 → 일반/원칙/적대적 리뷰 3종 → 보완 → 컴파일 → Play 검증 반복 → 모든 종료 조건 통과 시 사용자에게 1회 보고. 회고 시 본 skill 본문이 점진적으로 발전.
---

# /world-cycle — 자율 구현 사이클

`/world-doc`로 생긴 spec + writing-plans로 생긴 plan을 받아, M단위 구현을 끝까지 자율로 굴리는 진입점.

> **참고:** 본 skill은 superpowers `dispatching-parallel-agents` + `subagent-driven-development`를 내부에서 활용. 자율 모드(balanced)에선 매 task 컨펌 디폴트 X (CLAUDE.md §3 자율도 정책 따름). 사용자 명시 redirect 시에만 중단.

## 입력
- (필수) `<plan-path>` — 구현 plan markdown 경로. 예: `Desktop\<프로젝트>-기획\2026-05-22-m1-plan.md`
- (선택) `--wave <N>` — 특정 Wave만 실행 (디버깅용)
- (선택) `--dry-run` — 분배만 출력하고 dispatch 안 함

## 절차

### 단계 0: 사전 체크 (실패 시 사용자 중단 요청)

다음 조건 미충족 시 사용자에게 명시 컨펌 요청:

| 체크 | 의미 |
|---|---|
| spec 경로 명시 | plan 내부에 spec 링크가 명시되어 있는가 |
| 작업 위치 확정 | `작업 기준 위치:` 또는 `File Structure:` 박혀있는가 |
| push 정책 적용 | 푸시 금지 + 컨펌 결 박혀있는가 ([[feedback_no_push]]) |
| Acceptance Criteria 박힘 | 종료 조건이 plan 본문에 정의되어 있는가 |
| ZEPETO SDK / 빌드잇 가이드 grep 결과 박힘 | plan §X에 명시 ([[feedback_check_zepeto_sdk_before_spec]]) |

### 단계 1: plan 읽고 Wave 분배

1. plan 파일 Read
2. 모든 task 의존성 그래프 추출 (plan 끝 self-review §의 의존 graph 우선 활용)
3. Wave 분배 결정:
   - 독립 task → 같은 Wave (병렬)
   - 의존 task → 다음 Wave
4. Wave별 task 카드 출력 (사용자에게 1회만 — dispatch 직전):
   ```
   Wave 1 (병렬, N task): Task <id>, <id>, ...
   Wave 2 (병렬, N task): Task <id>, <id>, ...
   ...
   Wave M (최종 통합): Task <id>
   ```

### 단계 2: Wave별 병렬 dispatch

각 Wave에 대해 다음 순서로:

#### 2.1 Wave 시작 직전 1회 컨펌 + 체크포인트
- 분배 카드 출력 + Wave 시작 컨펌 (자율도 balanced에서도 유지)
- 사용자 redirect 시 분배 조정
- **Wave 시작 직전 backup branch 생성** (체크포인트):
  ```powershell
  git -C <repo> branch backup/m<M>-wave-<N>-pre HEAD
  ```
  Wave 전체 회수 anchor. 문제 발생 시 `git reset --hard backup/m<M>-wave-<N>-pre`로 Wave 시작 전 상태 복귀.
  - **★ git 기준 레포 `<repo>`** = **작업 대상 월드 레포 루트 (plan/세션 입력 명시)**. 프로젝트마다 기본 레포가 다를 수 있으니 미지정 시 팀의 default 레포로, 신규 장르·프로젝트 레포면 그 루트로 판단. 서브레포가 있으면 `.git_disabled_*`류로 비활성 — anchor 타깃 금지. push 정책은 조직마다 다르므로 `config/preserve-list.json`의 `deny_commands`에 보호 대상 레포명을 등록해 관리([[feedback_no_push]]) — 신규 user-owned 레포는 커밋 OK·push는 사용자 직접 판단, 조직 공용 메인/배포 레포는 push 금지가 원칙.

#### 2.2 task별 subagent 병렬 dispatch

**★ dispatch 채널 1순위 = Workflow 도구 (v0.6)** — 스크립트 오케스트레이션 + StructuredOutput schema 강제(보고 양식 유실 방지) + resume 캐시. §2.4 항목 1의 'subagent 실패 ≠ 작업 무(無)' 부분완료 처리와 직결 — schema 강제·resume 캐시가 보고 유실 패턴의 정공 해법. Workflow 도구를 못 쓰는 환경에서만 fallback으로 한 메시지 내 여러 Agent 호출.

**★ 병렬 disjoint-file 코드 에이전트 = implement-only + parent 순차 pathspec 커밋 (v1.2)** — 파일군이 겹치지 않는 코드 태스크를 병렬 dispatch할 때, 에이전트가 각자 git 커밋하면 **동시 index.lock 레이스**(v1.1 pathspec 규약의 병렬 심화판). 에이전트는 **구현+리뷰+tsc 스팟까지만(커밋 금지)** 하고, parent가 결과 회수 후 **파일군별 pathspec 커밋을 순차** 실행. 파일 무겹침이면 워킹트리 동시 편집은 안전(커밋만 직렬화). 트리거: 서로 다른 파일을 다루는 코드 에이전트 3개(별개 컨트롤러 3종)를 implement-only 병렬 → parent 순차 커밋 → 레이스 0 + 무관 델타 다수 보존.

**★ 비용 큰 외부 배치 = 검증 1~2건 → 승인 → 전량 (v1.4)** — 이미지·오디오 생성 API, 대량 임포트, 고비용 베이크처럼 **건당 분 단위 비용**이 드는 작업은 전량 발주하지 말고 **가장 까다로운 1~2건을 먼저 뽑아 사용자 승인**을 받은 뒤 나머지를 돌린다. 화풍·크기·톤 같은 **취향 축은 말로 수렴하지 않는다** — 결과물을 봐야 결정된다. 트리거: 스토어 이미지 세트를 규격대로 전량(장당 ~2분, 약 25분) 돌린 뒤 사용자가 화풍→크기 순으로 두 축을 되돌려 다수가 폐기됐다. 이후 배치는 2컷만 검증 → 승인 → 전량으로 갔다. 판정 기준을 **숫자로 고정**할 수 있으면 함께 못 박을 것(예: 인물 키 = 프레임의 62%, 타이틀 폭 = 76%).

**★ 진화 중 설계 = 코어 메커니즘 확정 후 deep recon 발주 (v1.3)** — 사용자가 메시지마다 설계를 확장/변형하는 중이면, 다중에이전트 recon을 성급히 발주하지 말고 **코어 메커니즘**(예: 구매=즉시효과 vs 인벤저장, 상태=로컬 vs 서버)을 먼저 1~2문 확정한 뒤 발주. 미확정 해석으로 recon하면 그 **판단** 부분이 off-target 돼 재작업. 단 recon schema를 **사실/판단 분리(§단계2 v0.9)**로 두면 사실 필드(파일·구조·API)는 재사용되므로 완전 낭비는 아님 → recon 자체보다 "언제 발주하냐"의 문제. 트리거: 상점 기능 재설계 — 첫 요구사항으로 recon-1 발주 후 다음 메시지에서 코어 메커니즘이 바뀌어 recon-1의 판단 부분 폐기(구조·API 조사 사실은 재사용).

**★ 출시/배포 델타 감사 = 발주 전 '기준선' 사용자 1문 확인 (v1.6)** — "이전 버전 대비 추가분 점검" 류 델타 감사 워크플로를 fan-out하기 전, **비교 기준선(어느 커밋/시점이 실 출시본인가)**을 사용자에게 1문으로 확정. **git 리모트(push 지점) ≠ 실 플랫폼 퍼블리시 지점** — ZEPETO는 Studio 업로드가 별개라 origin/main이 최신이어도 라이브는 더 과거 커밋일 수 있다. 잘못된 기준선으로 fan-out하면 델타 범위 전체가 어긋나 재조사. recon schema를 **사실/판단 분리(§단계2 v0.9)**로 두면 기준선 정정 후에도 specSummary(사실)는 재사용되나, 판단(옵션·권고)은 기준선에 의존하므로 처음부터 옳은 기준선이 최선. 트리거: 출시 델타 감사에서 origin/main을 기준선으로 발주했으나 사용자가 실제 출시 커밋을 정정 → 범위 재발주(specSummary는 재사용).

**★ Workflow 도구 usage 트랩 2건 (v1.7)** — 병렬 번역/데이터 fan-out에서 실제로 걸린 2함정: (1) **args는 문자열로 도착 가능** — Workflow `args`로 객체를 넘겨도 스크립트에선 JSON 문자열로 들어와 `Object.keys(args.x)`가 터짐 → 스크립트 서두에 `const W=(typeof args==='string')?JSON.parse(args):(args||{})` guard. (2) **StructuredOutput 결과는 wrapper 아래 중첩** — agent(schema) 반환이 `{result:{...}}` 형태로 감싸질 수 있어 `wrap.get('result',wrap)`(또는 JS `wrap.result ?? wrap`)로 안전 추출. 트리거: 대량 번역 워크플로(수백 키)에서 두 트랩 모두 발현, guard로 해소.

**★★ fan-out은 에이전트, 종합은 오케스트레이터 인라인 (v2.0)** — Workflow의 **마지막 종합·판정 phase를 외부 에이전트에 걸지 말 것.** 추출·조사·구현 phase는 대체로 살아남는데 **종합만 반복해서 죽는다** (컨텍스트가 가장 크고 입력이 앞선 전 에이전트 결과의 합이라 그렇다). 종합이 죽으면 그 워크플로우는 **null을 반환하고 앞선 성과가 전부 회수 불가처럼 보인다.**

두 가지를 같이 지킬 것:

1. **종합은 오케스트레이터가 인라인으로 한다.** 에이전트는 사실을 모으고, 합치는 것은 내가 한다. (기존 v0.7 "검증 에이전트 사망 시 인라인 수행" 지침의 **선제 적용판** — 죽은 뒤 대응이 아니라 처음부터 그렇게 설계한다.)
2. **어쩔 수 없이 종합을 에이전트에 맡기면, 앞선 phase의 schema로 사실을 먼저 확보한다.** `findings[{claim, evidence, grade, impact}]` 처럼 **사실(claim·evidence·grade)과 판단(impact)을 분리**해 두면 종합이 죽어도 `journal.jsonl`에서 사실을 전량 회수해 인라인으로 다시 합칠 수 있다 (§단계2 v0.9의 사실/판단 분리와 같은 뿌리).

★**회수 절차**: 종합이 죽으면 `<transcriptDir>/journal.jsonl`을 읽는다 — 완료된 에이전트마다 `{"type":"result",...}` 한 줄씩 실제 반환값이 들어 있다. **워크플로우 반환값이 null이어도 조사는 살아 있다.** 스크래치패드에 남은 데이터 파일(JSON·스크립트)도 함께 회수한다.

트리거: 검증 세션에서 워크플로우 여러 개 중 다수가 마지막 종합에서만 컨텍스트 초과로 죽었다(전체 에이전트 중 상당수 실패). 추출·조사·검증 phase는 대부분 살았고 종합만 전멸. `findings` schema 덕에 사실을 전량 회수해 커버리지 정정·문서를 오케스트레이터가 직접 작성했다. 한 워크플로우는 재개(resume)로 분류 단계만 되살렸다.

**★★ fan-out 전에 "답이 문서에 있나, 실행 상태에 있나"를 가른다 (v2.3)** — 조사 워크플로를 던지기 전 1문. 답이 **코드·문서·이력**에 있으면 fan-out이 강하다(파일을 넓게 읽어야 하고 병렬이 그대로 이득). 답이 **실행 중인 런타임 값**(물리 쿼리 결과·렌더 가시성·상태머신·좌표)에 있으면 **MCP 실측 1~2왕복이 조사 에이전트보다 빠르고 정확하다** — 에이전트는 소스를 읽어 *추론*할 뿐 값을 잴 수 없다.

트리거: 좌석 점유 조사에서 1번째 워크플로(6-agent 정찰: 서버 모듈 규약·클라 API·씬 구성·SDK 부재 확인·이력)는 **전부 문서/코드 질문이라 크게 유효**했다. 2번째(3-agent: "특정 설정을 고치면 무슨 이슈가 있나")는 **실행 상태를 재야 답이 나오는 질문**이라 30분 넘게 돌다가 직접 A/B 실측이 먼저 답을 내서 중단했다. ★그리고 정찰 중 죽은 에이전트의 목표도 결국 **Play 실측으로 대체**해 더 강한 근거를 얻었다 — 실행 상태 질문은 애초에 에이전트에 맡길 대상이 아니었다.

**★★ 산출물을 파일로 넘기는 fan-out — 2건 (v2.1)** — 레이어·데이터 생성 fan-out에서 실제로 걸린 것.

1. **에이전트가 반환한 뒤에도 파일을 쓰고 있을 수 있다.** 반환값에 담긴 **경로**를 즉시 import·읽으면 **반쯤 쓰인 파일**을 잡는다. 판정 = 소비 전 **파일 mtime이 내 소비 시각보다 앞인지** 확인. 더 나은 해법은 애초에 **경로가 아니라 내용을 반환값으로** 받는 것(용량이 작으면 항상 이쪽). 트리거: 다중 에이전트 절차적 생성 세션 — 산출 스크립트를 import해 오류, 파일 mtime이 소비 시각보다 늦었다. 워크플로우는 이미 반환한 상태였다.
2. **각 에이전트가 `measured[]` 실측 불변식을 함께 반환**하게 할 것 — 산출물만 받으면 오케스트레이터가 검증하려고 **다시 실행**해야 한다. 같은 세션에서 한 에이전트가 수치 검증 결과(오차·단조성·시드 스윕 PASS)를 반환해 **재실행 0회로 합성에 들어갔고**, 자기 버그까지 스스로 찾아 고친 사실을 반환했다. schema에 `measured: string[]` 필드 **하나** 추가하는 비용으로 검증 왕복이 사라진다 (§단계2 v0.9 사실/판단 분리의 실측판 — 사실 필드에 **수치**를 담게 하는 것).

각 agent에 다음을 명시:

- 구현 대상 task의 plan 안 §, file paths, code block 전부 복붙
- 참조 메모리 (CLAUDE.md §1 결 전체 + 본 task 관련 `feedback_*` ≥3건)
- 종료 조건 (per-task) — 본 skill §3 참조
- 보고 양식 (본 skill §4)
- **체크포인트 명시**: subagent는 commit 직후 `git -C <repo> tag m<M>-task-<N> HEAD` 추가 (task별 회수 anchor — 루트 레포 기준)
- **★ grep first 강화 (v0.4)**: subagent는 plan에 박힌 file path를 실재 grep으로 확인 후 진행. 경로 오기 발견 시 자율 정정 + finding으로 보고 (예: 폴더명이 plan과 실제가 다른 path drift)
- 제약:
  - `feedback_no_push` — git push 금지
  - `feedback_check_existing_first_then_ask` — 새 컴포넌트 만들기 전 grep
  - `feedback_check_zepeto_sdk_before_spec` — ZEPETO SDK 우선
  - **★ 서버 전용 모듈 컴파일 경로 (v0.4)** — server-only 모듈 (Sandbox/DataStorage 등) import는 `Assets/World.multiplay/`에서만 valid. server 격리 fork 시 IModule 패턴
  - 본 plan 외 파일 임의 수정 금지

#### 2.3 task별 자율 cycle (subagent 내부 책임)

각 subagent는 다음 사이클을 종료 조건 통과까지 반복:

```
구현
  → 일반 코드 리뷰 (cleanliness / DRY / YAGNI / 타입 일관성)
  → 원칙 리뷰 (spec 위배 / CLAUDE.md §1 결 전체 위배 / memory feedback_* 결 위배)
  → 적대적 코드 리뷰 (race condition / fake null / Puerts 함정 / Unity 함정 / edge case)
  → 보완 작성 + 재구현 (high-severity finding 모두 fix)
  → 컴파일 검증 (Unity Editor / TS strict)
  → Play mode 디버깅 (해당 시) — ready log 통과 확인
  → 미통과면 처음으로 돌아감
```

> 적대적 리뷰 reference (필수 surface): [[feedback_zepetoscript_ts_generic_variance]], [[feedback_zepetoscript_uidoc_query_puerts]], [[feedback_buildit_sdk_vs_devbranch_zepetocharacter_api]], [[feedback_multiplayer_safety_principle]], [[feedback_unity_getcomponent_null_coalescing_trap]], [[feedback_uitk_button_clickable_manipulator_conflict]], [[feedback_zepetoscript_new_field_default_false]](기존 직렬화 컴포넌트에 나중 추가한 public 필드=false/0/null 역직렬화 — 게이트로 쓰면 성공·실패 로그 전무의 조용한 스킵)

> ★ **검증 에이전트 org 스펜드 한도 전멸 유형 (v1.5)** — API 이슈뿐 아니라 조직 월 한도로도 전멸. 인라인 직검은 '핵심 위험 5종' 우선순위로: ①신규 API 전례(검증된 in-product 파일과 동일 패턴 grep) ②크로스 스크립트 계약(이름/arity) ③에셋 guid 존재·유니크 ④씬 직렬화 정합(keys=values 수·편집값·기존 참조 보존) ⑤새 필드 게이트 역직렬화.

> ★ **UI 배경/투명/레이아웃 조사·리뷰 (v1.0)** — "어느 노드가 배경/그 요소인가"는 단일 추정 금지. recon/리뷰 schema에 `GetComponentsInChildren(Image)` **전 레이어 스택(노드 경로·색 RGBA·부모-자식 렌더순서) 전수 열거**를 요구하고, 실제 보이는 bg를 그 스택에서 특정할 것. ZEPETO `Panel()` = 2겹(GOLD 테두리 root + `Body` fill child)이라 한 겹만 보면 오타겟 → redirect(대화/HUD 반투명 관련 세션에서 3회 빗맞음). ([[reference_zepeto_ui_global_scale_and_layers]] [[feedback_runtime_ui_relayout_prefab_contract]])

> ★ **필드 이관·네트 적용위치 리팩터 (v1.4)** — 상태 필드를 공용 구조로 이관/리네임하면 (1) 옛 심볼 dangling 참조가 tsc semantic 전맹으로 런타임까지 잠복 → 옛 심볼 grep 0 hit 검산, (2) 효과 적용을 로컬→수신측(broadcast)으로 옮기면 서버 relay 빈값-drop 가드가 효과 차단으로 변질(유료 아이템 증발) → 서버/수신 가드 동반 감사. 대형 리팩터는 economy·multiplayer·save·puerts·dangling 차원 적대적 검증 워크플로 필수 ([[feedback_state_field_migration_regression_audit]], 상태 통합 리팩터 세션에서 워크플로가 이 2결함 포착).

> ★ **UI 표시 문구·레이아웃 리뷰 (v1.5)** — (a) 화면 표시 텍스트 변경이 **기존 L10n 키**면 코드 `t(key,fallback)`의 fallback만 고쳐선 무반영 — 로컬라이제이션 CSV가 이김 → CSV 확인·수정 (신규 키만 코드 fallback 즉시 반영) ([[feedback_l10n_existing_key_csv_override]]). (b) 아이콘/카드 슬롯 "간격·여백" 이슈는 슬롯 간 gap 상수가 아니라 **정사각 슬롯 속 세로형 스프라이트의 aspect 여백**일 수 있음 → 슬롯 폭(width)부터 점검. (c) legacy Text `Outline` 확대 시 effectDistance 과대(4-copy 벌어져 글자 뭉갬) 주의. (UI 폴리싱 세션 — L10n 오버라이드 2회·간격 오진·외곽선 과대 redirect.)

> ★ **공유 save/state 경로 가드·픽스 = 형제 호출부 전수 감사 (v1.8)** — 공용 리소스(세이브/persist/네트 저장)에 가드나 픽스를 **한 함수에** 넣으면, 적대적 리뷰가 **같은 리소스를 만지는 형제 호출부를 전수 grep**(`.save(`·`persist`·`ReqSaveProgress`·`storage.set`)해 **가드 우회 없음**을 확인할 것. 한 함수만 막으면 형제가 그대로 뚫는다. 트리거: 데이터안전 감사 세션 — 재접속 시 진행도를 지키는 persist 가드를 형제 함수가 우회 → hydrate 前 기본값 저장으로 기존 유저 세이브(재화·진행도 등) 유실 HIGH → 감사 Workflow가 포착, `save()` 자체에 하이드레이트 게이트로 통합 차단. ([[feedback_state_field_migration_regression_audit]] 확장 — 필드 이관뿐 아니라 '가드 추가'도 형제 우회 점검)

#### 2.4 Wave 통합 점검 (parent) + Wave end 체크포인트

모든 subagent 결과 회수 후 parent (world-cycle skill 호출자)가:
1. 각 subagent의 finding/fix 요약 수집
   - **★ subagent 실패(null/에러 종료) ≠ 작업 무(無) (v0.5)**: 죽은 agent의 소유 파일을 mtime/diff로 확인 — 편집이 잔존하면 '부분 완료'로 취급해 보고 유실분(예: 번역 키 목록)을 파일에서 기계 추출해 후속 wave 입력에 포함. 트리거: 대형 세션에서 한 에이전트가 사망 → 편집은 파일 잔존·키 보고만 유실 → 후속 wave 누락 → 검증에서 다수 finding (전부 같은 뿌리). Workflow 도구 dispatch(§2.2 1순위)였으면 StructuredOutput schema 강제·resume 캐시가 이 유실 패턴의 1차 방어선
2. 파일 충돌 (같은 파일 동시 수정) 검사 — 있으면 merge resolution
3. **★ Editor.log 통합 grep** — Wave 전체 변경 파일에 대해 컴파일 에러 0건 검증. subagent self-review는 환경 함정 (module path policy 등) 못 잡으므로 parent가 Editor.log를 truth source로 재확인. mtime이 stale이면 사용자에게 Editor focus 요청
4. plan task별 checkbox 갱신
5. **Wave end backup branch 갱신**:
   ```powershell
   git -C <repo> branch -f backup/m<M>-wave-<N>-end HEAD
   ```
   다음 Wave 시작 전 회수 anchor로 사용. (Wave 1 end = Wave 2 시작 전과 동일 시점)
6. **★ 파괴적 스크립트를 돌린 Wave 는 "내 산출물이 기존 자산을 덮었을 가능성"을 기본 점검 (v1.4)** — `DestroyImmediate`·`CreateAsset`·파일 이동/삭제가 들어간 task 뒤에는 **내가 만든 것이 이상하다**는 지적을 받았을 때 *내가 지운 것*을 먼저 의심한다. 점검법: 새로 만든 오브젝트/에셋 **이름으로 씬·프로젝트를 재조회**해 동명 원본이 있었는지, `_excluded`/휴지통·git status 에 사라진 것이 있는지, 같은 경로 `CreateAsset` 으로 참조가 끊긴 것이 있는지. 트리거: 이펙트 스크립트의 `Find(이름)+DestroyImmediate` 가 **동명의 원본 라이트 오브젝트 다수**를 지웠고, 증상은 "새로 넣은 것이 어긋나 보인다"로만 나타나 사용자 지적 2회 뒤 조사 에이전트가 찾았다. ([[feedback_find_destroy_name_collision]])
7. **★ 대량 데이터/번역 산출물 = 소비측 결정적 재현 검증 (v0.8)** — 워크플로/스크립트가 생성한 데이터(로컬·경제 CSV·번역 등)는 에이전트 자가보고(건수 등) 불신하고, **소비측 파서/런타임 경로를 결정적 스크립트로 재현**해 커버리지·누락·포맷 전수 검증. 예: 로컬 CSV = 공식 Localization 파서 정규식 재현해 맵 진입 키 전수 확인 + doubled-quote(`""` = 파서 깸) 색출. 트리거: 수백 키×5언어 번역 워크플로 — 에이전트 보고 건수가 들쭉날쭉, 소비측 재현으로 누락 키·doubled-quote 색출. ([[reference_zepeto_localization_pipeline]])
8. **★ 리팩터/대량 변환 fan-out 후 = 미사용 import·데드 코드 잔재 정리 (v0.9)** — 동일 함수 단일 소스 통합 등 fan-out 변환은 호출 0인 데드 함수·미사용 import를 남길 수 있다. `noUnusedLocals` off면 tsc는 통과하므로, 변환 후 grep으로 잔재 색출(유틸 import·삭제 대상 함수명) + tsc 0 재확인. 트리거: 포맷팅 함수 여러 곳 중복 → 단일소스 fan-out 후 미사용 import·데드 함수 잔존 → 후속 정리.
9. **★ 경제/데이터 시뮬 재튜닝 = 자기출력 참조 금지·라이브 정본 직독(멱등) (v1.2)** — 시뮬 스크립트가 자기 산출물(예: `_econ_out*.json`)을 base로 읽으면 재실행마다 base-drift로 **비멱등**(승인용 산출물이 실행 순서에 따라 달라짐 = 승인 신뢰 붕괴). base·동결값은 **라이브 CSV/정본 파일 직독**으로만. 3회 재실행 md5 동일 assert로 멱등 확인. 트리거: 경제 재튜닝이 기준 가격을 자기 출력 JSON에서 읽어 스케일이 실행마다 드리프트 → 라이브 CSV 직독으로 수정.

#### 2.5 미통과 처리

Wave 내 task 1개라도 종료 조건 미통과 시:
- 같은 task에 새 subagent dispatch (finding 명시)
- 3회 재시도 후에도 미통과 → 사용자에게 보고 + 중단

### 단계 2.6: 조사·리뷰 fan-out 브리핑 규약

**★★ 오케스트레이터가 준 전제를 반증해도 된다 — 명시적으로 허가할 것.**

브리핑에 "이미 배제된 것"을 적으면 에이전트가 **그 전제까지 성역으로 취급**한다. 그러면
오케스트레이터가 틀렸을 때 아무도 못 잡는다. 한 진단 세션에서
로그 갈래가 *"실패는 내 수정 이후에만 있다"* 는 **오케스트레이터의 전제를 정면으로 반증**해
세션을 구했다(다른 로그 파일에 훨씬 이전 실패가 있었다). 그 갈래가 전제를 지켰다면
사용자는 정상 코드를 되돌렸을 것이다.

브리핑에 다음 문장을 **항상** 넣는다:

```
## 전제에 대하여
아래 "이미 배제된 것"은 오케스트레이터의 판단이며 **틀릴 수 있다.**
조사 중 그 전제와 모순되는 증거를 만나면 **그것을 최우선으로 보고하라.**
전제를 지키는 것보다 전제가 틀렸음을 밝히는 것이 훨씬 값지다.
```

그리고 조사/리뷰 schema 에 `assumptionsChecked` 필드를 둔다 — 각 갈래가
**오케스트레이터 전제 중 무엇을 실제로 확인했고 무엇을 확인하지 않았는지**를 남기게 한다
(v0.9 의 사실/판단 분리에 이어지는 '전제판'). 확인 안 된 전제가 결론을 떠받치고 있으면
그 결론은 아직 미완이다.

```js
assumptionsChecked: {
  type: 'array',
  items: { type: 'object', properties: {
    assumption: { type: 'string' },
    verdict: { type: 'string', enum: ['CONFIRMED', 'CONTRADICTED', 'NOT_CHECKED'] },
    evidence: { type: 'string' },
  }},
}
```

### 단계 3: 종료 조건 (per-task)

다음 7건 모두 통과해야 task 종료:

1. **일반/원칙/적대적 리뷰 high-severity finding 0건** — medium 이하 finding은 task 메모로 누적, 종료 가능
2. **TS strict / C# 정적 self-review 통과** (subagent 환경 한계 안에서)
3. **★ Editor.log 컴파일 에러 0건** — 사용자 Unity Editor reimport 후 다음 grep 결과 0 hit이 진짜 truth source:
   ```bash
   tail -1000 "/c/Users/<user>/AppData/Local/Unity/Editor/Editor.log" | \
     grep -nE "<task-file-patterns>" | \
     grep -iE "error TS[0-9]+|Module.*has no exported|Cannot find module|Property.*does not exist|<task-file>.*error"
   ```
   - TS strict self-review만으로는 **빌드잇 module path policy** 같은 환경 함정 못 잡음 (예: server-side .ts는 `Assets/World.multiplay/`만 인식)
   - subagent 종료 직전 Editor.log mtime 확인 → 자기 변경 후 갱신됐는지 검증. 갱신 안 됐으면 "사용자 Editor focus 필요" 명시
   - ★ **ZepetoScript `console.log`는 read_console MCP·Editor.log에 안 잡힐 수 있음** → 런타임 로그 검증은 Unity Console 창 육안 또는 read_console `filter_text` 검색 병행. import/컴파일 로그만 Editor.log에 남음
3.5. **★ 재현·검증은 '실제 사용자 경로'로 1회** — 내부 함수를 직접 호출해
   재현/검증했다고 통과 처리하지 말 것. UI 가 시작점인 기능은 **실제 버튼 클릭 경로**로 돌린다.
   실제 경로만 도는 코드(코루틴·뼈 스냅·상태 전이)가 버그의 본체일 수 있다
   (한 사례: 내부 함수 직접 호출로 3회 오통과 → 실제 UI 버튼의 별도 코루틴이 원인).
4. **Task에 정의된 ready log 통과** — Play mode console에서 명시 로그 출력 (Task 10 통합 점검 시점 검증)
5. **Play mode basic 기능 동작** (해당 시) — plan task의 검증 step 명시 기능
6. **★ UI task의 Scene 부착 step 점검 (v0.4)** — UXML/USS/Doc.ts 작성만으로 종료 X. 다음 중 하나가 plan 또는 EditorScript에 박혀 있어야:
   - Scene에 GO + UIDocument + ZepetoScript 부착 단계 plan에 명시
   - EditorScript (예: `M1SceneSetup.cs`)에 idempotent setup 헬퍼 포함
   - 부재 시 `getInstance() == null` 발생 → modal 미노출. subagent 자율 정정 또는 finding 보고
7. **★ 만든 UI·상호작용은 Play 에서 실제 클릭 경로로 1회 실행 (v1.4)** — 컴파일·ready log·필드 직렬화가 다 정상인데도 **탐색 경로 하나가 틀려 기능이 처음부터 죽어 있을 수 있다.** 판정은 `onClick.Invoke()` 등으로 **진짜 핸들러를 태우고 결과 값을 읽는 것**(위치·색·상태 전이). 트리거: 버튼 누름 애니메이션 대상이 손자(grandchild) 노드인데 `Transform.Find()` 는 직계만 봐서 참조가 null, 연출이 **한 번도 실행된 적이 없었다.** 사용자가 "잘 되는지 봐줘"라고 해서야 발견. 부착·컴파일 검증은 이 사각을 못 덮는다. ([[feedback_new_ui_path_play_gate]])

- **★ `.ts` 산출물은 `.meta` 크기로 판정한다.** `tsc` 통과·예외 0건만으로 통과 처리하지 말 것 —
  로컬 `tsc --skipLibCheck` 는 SDK typings 파스에러로 **의미 검사가 전맹**이라 `Quaternion * Quaternion`·`Renderer.GetType()` 같은
  트랜스파일 킬러를 0건으로 통과시킨다(실측: 한 세션에서 **890B 실패 2회**, 둘 다 `tsc` 0건이었다).
  판정 = `<파일>.ts.meta` 가 900B급이면 **실패**, 수십~수백 KB면 성공. 실패로 보이면 진단 전에
  `AssetDatabase.ImportAsset(path, ForceUpdate | ForceSynchronousImport)` 로 **재임포트부터** 할 것(에디터 밖 편집은 파일 워처가 놓친다).
  ★ 서버 모듈(`World.multiplay/ServerModule/`)은 **298B 가 정상**이다 — Unity 가 트랜스파일하지 않는다. 대조군으로 다른 서버 모듈을 재 볼 것.
  [[feedback_puerts_struct_and_operator_traps]]

### 단계 4: 최종 완성 신호 (M 전체)

모든 Wave 종료 후 다음 1회 통합 검증:

1. plan 끝의 **Acceptance Criteria** 전체 통과 확인
2. PORTING_LOG.md M 섹션 1줄 갱신 (plan에 양식 박혀있음)
3. 사용자에게 1회 보고 — **중간 단계 보고 X, 완성본만**

> **★ 검증 에이전트 사망 인라인 폴백 (v0.7)**: 최종 통합 검증/마무리를 단일 subagent(또는 Workflow 마지막 phase) 1개에 의존하지 말 것. 그 에이전트가 API·모델 이슈로 죽으면(결과 null) 검증이 통째 누락된다. **마지막 phase 결과가 null이면 오케스트레이터가 직접 인라인으로** tsc(0줄)·핵심 점검(소유 파일 grep·계약 회귀)을 수행한 뒤 종료 — 검증을 외부 에이전트 생존에 걸지 않는다. (§2.4 항목 1 '실패 ≠ 작업 무'의 검증 단계 버전)

> **★★ 집계값이 '통과'로 위장한다 — failures 를 먼저 읽어라 (v1.2)**: v0.7 은 결과가 **null 일 때**를 다룬다. 더 위험한 건 **결과가 멀쩡한 모양으로 오는 경우**다. 적대적 검증 fan-out 에서 반증 에이전트 다수가 전부 spend limit 으로 죽었는데, 스크립트 집계는 `refutedCount: 0` → `survives: true` 로 계산해 **"생존 가설 N건"이라는 정상적인 결과 객체**를 돌려줬다. `refutedCount: 0` 은 *반증에 실패했다*가 아니라 **반증이 실행되지 않았다**였다. 3 규약: ① fan-out 결과를 쓰기 전에 **task-notification 의 `agents_error` / `<failures>` 를 먼저 읽는다** ② 죽은 검증에 걸린 항목은 인라인으로 대체하거나 **"미검증"으로 명시 표기**한다(보고에서 빠뜨리면 미검증 가설이 검증된 것으로 굳는다) ③ 스크립트 집계에 **분모를 함께 싣는다** — `refutedCount` 옆에 `judgedCount` 를 둬 `0/0` 과 `0/3` 이 구분되게 할 것.

> **★★ 구현 에이전트 사망도 인라인 폴백 (v1.1)**: v0.7은 '검증' 에이전트만. **구현 에이전트가 조직 월 사용량 한도·API 오류로 죽어도** 그 태스크를 버리지 말고 오케스트레이터가 소유 파일을 **직접 구현·검증·pathspec 커밋**으로 회수한다. 단일 파일 3지점 삽입·시트 산출 등 인라인이 오히려 적합한 태스크가 많다. 3 동반 규약:
> ① **병렬 커밋 = pathspec 강제** — `git commit -- <소유파일>`만, `add -A`/`add .` 금지. 공유 git index에서 병렬 세션이 서로 스테이징을 삼키는 레이스 발생. ② **tsc 게이트 semantic 전맹 보강** — `tsc --noEmit | grep <키워드>`=0은 SDK typings 파스에러로 semantic(import 형태 등)에 전맹일 수 있음(syntax만 보증). 신규/수정 .ts는 **단일 파일 스팟체크**(`tsc <파일> | grep -E "TS2614|TS2305|TS2613"`)로 import-형태 크래시 클래스 사전 차단 + default/named export 정합 확인(named import한 default export = 런타임 undefined 크래시). ③ **진단 grep 자기 오탐 금지** — 진단 마커/주석에 검색 대상 문자열(예 손상 패턴)을 쓰면 산출물에 섞여 자기 오탐. ([[feedback_zepetoscript_transpile_missing_zepeto_import]])

### 단계 5: 사용자 보고 양식

```markdown
## /world-cycle M<N> 완료 보고

### Acceptance Criteria
- [x] <criteria 1>
- [x] <criteria 2>
- ...

### Wave 진행
| Wave | task 수 | 재시도 | 통과 |
|---|---|---|---|
| 1 | 5 | 0 | ✅ |
| 2 | 3 | 1 | ✅ |
| ...

### High-severity finding (해결 완료)
- Task <id>: <finding 요약> → <fix>
- ...

### 잔존 medium/low finding (다음 M에서 회수)
- Task <id>: <finding 요약>
- ...

### 다음 단계
- M<N+1> plan 작성 (`/world-doc` → writing-plans → `/world-cycle`)
```

## 출력
- 모든 plan task의 checkbox 완료 + commit (루트 레포 단위 — 커밋 OK·push는 사용자 직접)
- PORTING_LOG.md 해당 M 섹션 추가
- 사용자 보고 1건

## 메모리 grep 패턴 (필수 surface)
- CLAUDE.md §1 결 전체
- [[feedback_check_zepeto_sdk_before_spec]]
- [[feedback_check_existing_first_then_ask]]
- [[feedback_no_push]]
- [[feedback_porting_pipeline_documentation]]
- [[feedback_multiplayer_safety_principle]] (멀티 작업 시)
- [[feedback_buildit_typescript_runtime_required]] (빌드잇 작업 시)

## 안전 정책
- 조직 보호 대상 레포 push 금지 (PreToolUse Soft-block 동시 작동) — [[feedback_no_push]]
- 새 기능 spec 전 ZEPETO SDK + 빌드잇 가이드 grep 결과 plan 본문에 박혀있어야 dispatch 가능 — [[feedback_check_zepeto_sdk_before_spec]]
- subagent를 포함해 승인되지 않은 외부 LLM으로 데이터 라우팅 지양 (Claude Code 권장)
- 사용자 명시 UI 결정 보존 — [[feedback_preserve_user_explicit_ui_decisions]]
- subagent는 본 plan 외 파일 임의 수정 금지 (out-of-scope 발견 시 plan 본문 보강 후 별도 task로 분리)

## 체크포인트 & 회수 가이드

**git 기준 레포** = `git -C <repo>` (루트) — **`<repo>` = 작업 대상 월드 레포(plan/세션 입력; 팀의 default 레포, 신규 장르 레포면 그 루트 — §단계1 정의 참조)**. 서브레포 있으면 `.git_disabled_*`로 비활성이므로 아래 표의 `<repo>` 자리는 항상 루트. push 정책: 신규 user-owned 레포 커밋 OK·push는 사용자 직접 / 조직 보호 대상 메인·개발 레포 push 금지 유지.

매 task / Wave에서 자동 박히는 anchor + 회수 명령:

| 단위 | anchor 형태 | 박는 시점 | 회수 명령 |
|---|---|---|---|
| Task | tag `m<M>-task-<N>` | task end commit 직후 | `git -C <repo> reset --hard m<M>-task-<N-1>` (task N 시작 전 상태) |
| Wave | branch `backup/m<M>-wave-<N>-pre` | Wave 시작 직전 | `git -C <repo> reset --hard backup/m<M>-wave-<N>-pre` (Wave 전체 회수) |
| Wave | branch `backup/m<M>-wave-<N>-end` | Wave 통합 점검 후 | `git -C <repo> reset --hard backup/m<M>-wave-<N>-end` (Wave까지만 살림) |

**회수 규칙**:
1. `reset --hard`는 강력 — 사용자 명시 컨펌 후만 실행
2. 회수 후 그 commit들은 reflog에만 남음 (30일 window — `git reflog`로 hash 회수 가능)
3. backup branch는 누적 보존 (지우지 않음). M 종료 시 `m<M>-final` tag 추가
4. Wave 안 task별 finding 가벼우면 task 단위 회수, Wave 통째 문제면 wave 단위 회수
5. 회수 후엔 plan task checkbox를 회수 지점에 맞게 되돌리고, 재시도 시 새 commit (force / amend 금지)
6. **★ tag/branch 네이밍은 작업별 고유 prefix** — `m<M>-task-*` 같은 M 번호 재사용은 이전 작업 anchor를 `-f`로 덮어쓰는 사고 발생(다른 프로젝트의 `m1-task-*`와 충돌 → 복원 필요). 새 작업은 새 prefix (예: `gate-task-*`, `mirror-fix`). 박기 전 `git tag -l "<prefix>*"`로 충돌 확인

## 자가 발전 hook
- 매 `/world-cycle` 완료 후 `/world-retro` 호출 권장
- `/world-retro` 단계 3에서 본 skill 본문 v+1 patch 후보 생성 (이번 cycle에서 발견한 효율 ↑ 패턴, 새로운 함정, 종료 조건 보정)
- v0.1 → v0.N 점진 발전 (사용자 컨펌 후만 적용, 매 회고 ≤ 3 patch)

## 차후 연계
- 완료 후 `/world-retro` 호출
- 다음 M plan 필요 시 `/world-doc` (또는 plan 작성 단계는 spec 변동 없으면 writing-plans 직접)
- plan 분량이 크면 sub-plan으로 분해 후 `/world-cycle` 재호출

## 버전 이력

본 skill은 `/world-retro` 회고를 거치며 실제 프로젝트에서 발견된 함정·효율 패턴을 반영해 점진적으로 patch됩니다(사용자 컨펌 후 적용, 매 회고 ≤3건). 위 본문의 각 항목(v0.x~v2.x 표기)은 그렇게 누적된 결과이며, 여러분의 팀에서 새로 발견하는 패턴은 이 문서에 계속 추가하면 됩니다. 자체 버전 이력은 각자의 레포에서 추적하세요 — 이 배포판에는 원 개발사의 날짜별 인시던트 상세 로그(트리거 세션의 프로젝트명·날짜)는 포함하지 않았습니다.
