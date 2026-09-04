# world-starter

**바이브 코딩으로 ZEPETO 월드를 기획부터 출시까지 — Claude Code 스타터 킷.**

코드를 직접 작성하지 않아도, Claude Code와 대화하며 ZEPETO 월드를 기획하고 만들고 다듬어 출시할 수 있도록 설계된 작업 규약(CLAUDE.md) + 슬래시 커맨드 4종 + 자동화 hook 세트입니다.

## 이게 뭘 해주나요

- **`/world-doc`** — 월드 기획서를 표준 구조(섹션 0~12)로 정리된 markdown 문서로 작성합니다.
- **`/world-build`** — 기획서를 바탕으로 Unity SDK 프로젝트 또는 buildit(TS) 환경에서 실제 월드를 구현·포팅합니다. mock 먼저 만들어 승인받고 일괄 반영하는 절차, 작업 이력을 남기는 `PORTING_LOG.md` 컨벤션이 포함됩니다.
- **`/world-cycle`** — 구현 계획을 여러 단계(Wave)로 나눠 자율적으로 진행하고, 매 단계 일반·원칙·적대적 검토를 거쳐 종료 조건을 통과할 때까지 반복합니다.
- **`/world-retro`** — 세션이 끝날 때 무엇이 잘 됐고 무엇이 안 됐는지 3가지로 분류해 회고하고, 다음 세션부터 적용할 규칙을 사용자 확인 후 CLAUDE.md에 반영합니다. **쓸수록 여러분의 경험으로 똑똑해지는 하네스입니다.**

세션이 시작되면 hook이 현재 작업 폴더를 보고 어떤 작업인지 자동으로 추정해 관련 정보를 먼저 보여주고, 위험한 명령(보호 레포 push, 재귀 삭제 등)은 실행 전에 한 번 더 확인을 요구합니다.

## 요구 사항

- **권장: [Claude Code](https://claude.com/product/claude-code)** — 이 스타터 킷의 hook·skill 형식은 Claude Code를 기준으로 설계·검증되었습니다. 커스텀 슬래시 커맨드와 세션 훅을 지원하는 다른 AI 코딩 도구가 있다면, 형식만 맞춰 이식해 쓸 수도 있습니다.
- Windows + PowerShell 5.1 (hook 스크립트가 PowerShell로 작성되어 있습니다)
- ZEPETO 월드 개발 환경(커스텀 Unity SDK 프로젝트 또는 buildit) — 없어도 `/world-doc`, `/world-retro`는 바로 쓸 수 있습니다.

## 빠른 시작

1. 이 레포를 원하는 위치에 내려받습니다.
2. `hooks/`, `config/`, `tests/` 폴더를 `~/.claude/world-starter/`에 복사합니다.
3. `skills/world-*` 각 폴더를 `~/.claude/skills/world-*/`에 복사합니다.
4. `CLAUDE.md`를 `~/.claude/CLAUDE.md`에 복사한 뒤, **§0 사용자 프로필을 여러분 상황에 맞게 고쳐 씁니다** (가장 먼저 해야 할 일입니다).
5. `~/.claude/settings.json`에 `hooks.SessionStart` / `hooks.PreToolUse` / `hooks.Stop` / `hooks.UserPromptSubmit`을 각각 `hooks/*.ps1` 경로로 등록합니다 — 자세한 순서는 `tests/smoke/gate-checklist.md`를 참고하세요.
6. `config/preserve-list.json`의 `deny_commands`에, 실수로 push되면 안 되는 여러분의 실제 레포명을 채워 넣습니다.
7. 새 Claude Code 세션을 열고 `/world-doc 테스트`처럼 가볍게 호출해 잘 붙었는지 확인합니다.

## 폴더 구조

```
CLAUDE.md              세션마다 자동으로 노출되는 작업 규약 — 가장 먼저 읽고 커스터마이징할 파일
hooks/                 PowerShell hook 4종 (SessionStart / PreToolUse / Stop / UserPromptSubmit)
config/
  keyword-dict.json    프롬프트 키워드 → 관련 메모리 매핑 (예시 3건, 직접 채워나가는 파일)
  preserve-list.json   push 금지 레포·수정 보존 파일 패턴 (예시, 실사용 전 필수 수정)
skills/
  world-doc/           기획서 작성 skill
  world-build/         월드 구현·포팅 skill
  world-cycle/         자율 구현 사이클 skill
  world-retro/         회고·자가 개선 skill
tests/smoke/           설치 후 hook이 정상 동작하는지 확인하는 수동 테스트 스크립트
```

## 커스터마이징 체크리스트

이 스타터 킷은 그대로 두면 예시 상태입니다. 실제로 쓰려면:

- [ ] `CLAUDE.md` §0 사용자 프로필 — 본인(또는 팀)이 개발자인지 아닌지에 따라 설명 방식이 달라져야 합니다.
- [ ] `config/preserve-list.json` — 보호할 실제 레포명·파일 패턴으로 교체.
- [ ] `config/keyword-dict.json` — 처음엔 비어 있다시피 합니다. `/world-retro`를 반복하며 여러분 프로젝트의 키워드를 하나씩 늘려가세요.
- [ ] (선택) memory 시스템 — `CLAUDE.md` §4에 권장 구조가 설명되어 있습니다. 세션 간 맥락을 이어받고 싶다면 도입을 고려하세요.

## 안전 정책

- 프로젝트 데이터를 승인되지 않은 외부 LLM 서비스로 임의 라우팅하지 않는 것을 권장합니다. 이 스타터 킷은 Claude Code를 기준으로 설계됐지만, 같은 원칙 하에 신뢰하는 다른 도구를 함께 써도 무방합니다.
- CLAUDE.md에 대한 자가 patch(회고 결과 반영)는 항상 사용자 확인 후에만 적용됩니다.
- `config/preserve-list.json`의 `deny_commands`에 등록된 레포로의 push, `rm -rf` 등 위험한 명령은 실행 전에 이유·우회 방법·사용자 승인 여부를 먼저 답하도록 막습니다.
- 이 레포 안에는 API 키 등 비밀값이 포함되어 있지 않습니다. 실제 키 관리는 안전한 방식(환경변수·시크릿 매니저 등)을 따르세요.

## 만든 곳

**World Studio**가 만들었습니다. 여기 담긴 규칙들은 시작점일 뿐이니, `/world-retro`를 반복하며 여러분의 프로젝트 경험으로 계속 채워 나가세요.

버그를 발견했거나 개선 제안이 있다면 이 레포에 이슈로 남겨주세요.

## 라이선스

[MIT License](LICENSE) — 자유롭게 사용·수정·재배포할 수 있습니다.
