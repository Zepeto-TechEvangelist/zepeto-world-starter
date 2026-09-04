# world-starter CHANGELOG

## v1.0.0 (Phase 6) ★ v1 출시
- gate-checklist.md (sub-process 검증 + 실 세션 검증 분리)
- README.md v1 첫 실적용 안내 (예시 기획서 작업)
- 모든 phase 1~5 완료 + v1.0 tag

## v0.5.0 (Phase 5)
- /world-retro skill (3-분류 회고: Worked/Didn't/Improvements + 자가 patch 흐름)
- 첫 회고 산출물 예시
- patch 후보 ≤3건 제시 흐름 (사용자 컨펌 대기)
- 안전 정책: ≤3건/회고, 4 patch type, 금지 patch 명시
- phase5-retro.md smoke 체크리스트

## v0.4.0 (Phase 4)
- /world-doc skill (markdown 기획서, 섹션 0~12)
- /world-build skill (Unity/buildit 포팅 + PORTING_LOG)
- skills-tracker.md 추가 (world-starter git 외부 skills 추적)
- phase4-skills.md smoke 체크리스트 (manual, 실 세션에서 확인)

## v0.3.0 (Phase 3)
- UserPromptSubmit hook (키워드 매칭 → 관련 메모리 surface)
- keyword-dict.json v1 (예시 mapping)
- settings.json `hooks.UserPromptSubmit` 등록
- smoke test 5/5 PASS (영문 키워드 — 한국어는 production UTF-8에서 검증)

## v0.2.0 (Phase 2)
- PreToolUse Soft-block (보호 레포 push, rm -rf, preserve-list 보존 UI 파일)
- Stop alert (threshold tool=30 OR keyword=3)
- preserve-list.json (예시 file patterns + deny commands)
- settings.json `hooks.PreToolUse`, `hooks.Stop` 등록 (timeout 30s)
- PreToolUse output schema = `hookSpecificOutput.permissionDecision: deny` (Claude Code 공식)

## v0.1.0 (Phase 1)
- CLAUDE.md 작성 (결 + 작업 유형별 결 + 자율 모드 + 진입점)
- SessionStart hook (cwd→worktype 추정 + axis memory surface + 최근 회고 surface)
- settings.json `hooks.SessionStart` 등록 (timeout 30s)
- 디렉터리 구조 + world-starter git init
- PS 5.1 array `+=` 함정 회피 (ArrayList 사용)
