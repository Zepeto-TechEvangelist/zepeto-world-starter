# Phase 5 /world-retro Smoke Test (manual)

## Test 1: 임계 초과 작업 회고
큰 작업 후 새 세션에서 `/world-retro` 호출.

- [ ] skill 호출 인식
- [ ] 작업 분량 임계 확인 (≥30 도구 호출)
- [ ] 3-분류 회고 양식 생성
- [ ] retro/<날짜>.md 작성
- [ ] patch 후보 ≤3건 제시
- [ ] 사용자 컨펌 받음

## Test 2: 작은 작업 (`--small` 미사용)
- [ ] 임계 미만 안내 + skip 권장

## Test 3: 작은 작업 + `--small`
- [ ] 강제 회고 진행

## Test 4: 자가 patch 컨펌 흐름
- [ ] patch 후보 3건 제시 → "1번 적용" / "2번 거부" 흐름 검증
- [ ] git diff 표시 (claude-md-add, skill-augment)
- [ ] rollback 가능 (git revert)

## Test 5: 한도 위반
- [ ] 후보 4건 제시 시 4번째 별도 명시 컨펌

## Test 6: 금지 patch 종류 시도
- [ ] 기존 결 삭제·크게 변경은 design doc 갱신 안내
