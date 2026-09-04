# Phase 2 Stop hook smoke
$hook = "$env:USERPROFILE\.claude\world-starter\hooks\stop.ps1"

# Mock transcript 작성 (40 도구 호출 + 5 키워드)
$mockTranscript = "$env:TEMP\world-starter\mock-transcript.jsonl"
if (-not (Test-Path "$env:TEMP\world-starter")) { New-Item -ItemType Directory -Force -Path "$env:TEMP\world-starter" | Out-Null }
$lines = @()
for ($i = 0; $i -lt 40; $i++) {
    $lines += '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"ls"}}]}}'
}
$lines += '{"type":"assistant","message":{"content":[{"type":"text","text":"이 항목 확정했다"}]}}'
$lines += '{"type":"assistant","message":{"content":[{"type":"text","text":"우회 방식 결정"}]}}'
$lines += '{"type":"assistant","message":{"content":[{"type":"text","text":"새로운 함정 발견"}]}}'
$lines | Out-File -Encoding utf8 $mockTranscript

Write-Host "=== Test 1: 임계 초과 transcript ==="
$payload = @{transcript_path=$mockTranscript; hook_event_name="Stop"} | ConvertTo-Json -Compress
$output = $payload | & powershell -NoProfile -ExecutionPolicy Bypass -File $hook
Write-Host "Output: $output"
$expected = $output -match "Stop alert"
Write-Host "[$(if($expected){'PASS'}else{'FAIL'})] alert 생성 여부"
Write-Host ""

# Small transcript (3 tool calls)
$smallTranscript = "$env:TEMP\world-starter\mock-small.jsonl"
@(
    '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Read"}]}}',
    '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Read"}]}}',
    '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Read"}]}}'
) | Out-File -Encoding utf8 $smallTranscript

Write-Host "=== Test 2: 작은 transcript (alert 없어야) ==="
$payload2 = @{transcript_path=$smallTranscript; hook_event_name="Stop"} | ConvertTo-Json -Compress
$output2 = $payload2 | & powershell -NoProfile -ExecutionPolicy Bypass -File $hook
Write-Host "Output: '$output2'"
$silent = [string]::IsNullOrWhiteSpace($output2)
Write-Host "[$(if($silent){'PASS'}else{'FAIL'})] silent 종료"
Write-Host ""

Write-Host "=== Log tail ==="
Get-Content "$env:TEMP\world-starter\hook.log" -Tail 5
