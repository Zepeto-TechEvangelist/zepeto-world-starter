# 출시 게이트 체크리스트

design doc §5.7 기준. sub-process smoke로 검증하는 항목 / 실 세션 검증이 필요한 항목을 구분해서 관리하세요.

## Hook 4종 unit smoke
- [ ] SessionStart — cwd 추정 OK (`phase1-session-start.ps1`)
- [ ] PreToolUse — Soft-block PASS (`phase2-pre-tool-use.ps1`)
- [ ] Stop — 임계 초과 alert + 작은 세션 silent (`phase2-stop.ps1`)
- [ ] UserPromptSubmit — 키워드 매칭 (`phase3-user-prompt-submit.ps1`)

## Skill 4종 unit smoke (manual)
- [ ] /world-doc — 새 Claude Code 세션에서 `/world-doc 테스트` 호출
- [ ] /world-build — `/world-build 테스트` 호출
- [ ] /world-cycle — plan 기반 자율 사이클 1회 진행
- [ ] /world-retro — 회고 생성 + patch 후보 제시 확인

## Fault injection
- [ ] PreToolUse 우회 — Soft-block 출력 schema 검증, deny reason 정상
- [ ] MEMORY.md 일부 손상 → fail-open + alert
- [ ] keyword-dict.json 깨뜨림 → UserPromptSubmit 비활성, skill 정상
- [ ] Hook 스크립트 timeout 시뮬 → abandon (`timeout: 30` 설정, 5+s sleep 주입 시 검증)
- [ ] /world-retro patch 거부 → retro 파일 "rejected" 표시 (SKILL.md §5.2 정책 적용)
- [ ] 자가 patch 적용 후 hook 오작동 → git revert rollback

## PreToolUse 차단·우회 양방향 확인
- [ ] 차단: 보호 레포로 push 시도 → deny + reason (smoke Test 1, config/preserve-list.json 예시 기준)
- [ ] 우회: 사용자 명시 답변 → 다음 시도 통과 (Soft-block 디자인 일관)

## 로그 디렉터리
- [ ] `%TEMP%\world-starter\hook.log` 생성 확인
- [ ] `%TEMP%\world-starter\preTool-block.log` 차단 기록 확인

## retro/*.md
- [ ] `~/.claude/world-starter/retro/` 첫 retro 생성
- [ ] 자가 patch 컨펌 흐름 (사용자 대기)

## settings.json
- [ ] 4 hooks 모두 등록 (SessionStart, PreToolUse, Stop, UserPromptSubmit)
- [ ] JSON 유효성 통과
- [ ] 백업 (`settings.json.bak-*`)

## 실 세션 검증 (도입 직후 첫 기획서/월드 작업에 적용 시)
다음은 새 Claude Code 세션 시작 후 자연 검증:
- [ ] SessionStart hook이 실 세션 첫 system-reminder에 inject
- [ ] CLAUDE.md user-scope 자동 inject 동작 확인
- [ ] UserPromptSubmit hook이 첫 사용자 프롬프트마다 키워드 매칭
- [ ] /world-doc 호출 → SKILL.md 단계 진행
- [ ] Stop hook이 세션 종료 시 alert 표시
- [ ] /world-retro 호출 → 회고 + patch 흐름

이 6 항목은 실제 작업 첫 사이클에서 자연 검증되는 E2E 시나리오입니다.
