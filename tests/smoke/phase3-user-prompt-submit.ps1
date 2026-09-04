$hook = "$env:USERPROFILE\.claude\world-starter\hooks\user-prompt-submit.ps1"

function Test-Prompt($name, $prompt, $expectMatches) {
    Write-Host "=== $name ==="
    $payload = @{prompt=$prompt; hook_event_name="UserPromptSubmit"} | ConvertTo-Json -Compress
    $output = $payload | & powershell -NoProfile -ExecutionPolicy Bypass -File $hook
    Write-Host "Output: $output"
    if ($expectMatches -gt 0) {
        $hit = $output -match "관련 있음"
        Write-Host "[$(if($hit){'PASS'}else{'FAIL'})] 매칭 발견 (기대 매칭 수=$expectMatches)"
    } else {
        $silent = -not ($output -match "관련 있음")
        Write-Host "[$(if($silent){'PASS'}else{'FAIL'})] silent (매칭 없음 기대)"
    }
    Write-Host ""
}

Test-Prompt "Test 1: 검색기능" "검색기능 v1 plan 작성해" 3
Test-Prompt "Test 2: buildit 포팅" "buildit 포팅 진행" 4
Test-Prompt "Test 3: 무관한 프롬프트" "오늘 날씨 어때" 0
Test-Prompt "Test 4: UI Toolkit USS" "uitk modal overlay 작성" 4

Get-Content "$env:TEMP\world-starter\hook.log" -Tail 5
