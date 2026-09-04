# Skills Tracker

`~/.claude/skills/`는 user-scope, world-starter git 외부. 변경 기록만 추적.
**`~/.claude/CLAUDE.md`도 git 외부** — 회고 patch로 바뀌므로 여기서 같이 추적하는 것을 권장합니다 (커밋 rollback으로 되돌아가지 않는다는 뜻).

| Skill | 위치 |
|---|---|
| world-doc | `~/.claude/skills/world-doc/SKILL.md` |
| world-build | `~/.claude/skills/world-build/SKILL.md` |
| world-retro | `~/.claude/skills/world-retro/SKILL.md` |
| world-cycle | `~/.claude/skills/world-cycle/SKILL.md` |

## `~/.claude/CLAUDE.md` (git 외부 — 수동 rollback)

`CLAUDE.md`는 `/world-retro`를 통해 점진적으로 patch됩니다. git 히스토리에 남지 않으므로, 각 patch의 버전·날짜·요지를 이 표 형식으로 직접 누적해서 추적하는 것을 권장합니다:

| 버전 | 날짜 | 요지 |
|---|---|---|
| v1.0 | (최초 도입일) | 초기 결 세트 |

세션이 쌓일수록 이 표가 곧 여러분 팀의 엔지니어링 원칙 변경 이력이 됩니다.
