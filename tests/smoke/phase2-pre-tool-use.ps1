# Phase 2 PreToolUse smoke
$hook = "$env:USERPROFILE\.claude\world-starter\hooks\pre-tool-use.ps1"

function Test-Hook($name, $payload, $expectBlock) {
    Write-Host "=== $name ==="
    $output = ($payload | ConvertTo-Json -Compress) | & powershell -NoProfile -ExecutionPolicy Bypass -File $hook
    Write-Host "Output: $output"
    $blocked = $output -match 'permissionDecision":"deny"'
    if ($blocked -eq $expectBlock) {
        Write-Host "[PASS] block=$blocked (expected=$expectBlock)"
    } else {
        Write-Host "[FAIL] block=$blocked (expected=$expectBlock)"
    }
    Write-Host ""
}

# Test 1: git push to 보호 레포 → 차단 (config/preserve-list.json의 예시 레포명 기준)
Test-Hook "Test 1: your-main-repo push" `
    @{tool_name="Bash"; tool_input=@{command="git push origin your-main-repo"}} $true

# Test 2: 일반 git push → 통과
Test-Hook "Test 2: 일반 push" `
    @{tool_name="Bash"; tool_input=@{command="git push origin feature-x"}} $false

# Test 3: rm -rf → 차단
Test-Hook "Test 3: rm -rf" `
    @{tool_name="Bash"; tool_input=@{command="rm -rf /tmp/test"}} $true

# Test 4: 일반 Edit → 통과
Test-Hook "Test 4: 일반 Edit" `
    @{tool_name="Edit"; tool_input=@{file_path="$env:USERPROFILE\Desktop\test.md"}} $false

# Test 5: 보존 UI 파일 Edit → 차단
Test-Hook "Test 5: status_uitk mock 수정" `
    @{tool_name="Edit"; tool_input=@{file_path="$env:USERPROFILE\Desktop\assets\uitk\status_uitk_v3_mock.html"}} $true

Write-Host "=== Block log tail ==="
Get-Content "$env:TEMP\world-starter\preTool-block.log" -Tail 5 -ErrorAction SilentlyContinue
