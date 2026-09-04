# Phase 1 SessionStart hook smoke test
$hook = "$env:USERPROFILE\.claude\world-starter\hooks\session-start.ps1"

Write-Host "=== Test 1: doc cwd ==="
$cwd1 = "$env:USERPROFILE\Desktop\예시프로젝트-기획"
$inputJson = @{cwd=$cwd1; hook_event_name="SessionStart"} | ConvertTo-Json -Compress
$output = $inputJson | & powershell -NoProfile -ExecutionPolicy Bypass -File $hook
Write-Host $output
Write-Host ""

Write-Host "=== Test 2: world cwd ==="
$cwd2 = "$env:USERPROFILE\Desktop\zepeto_buildit_unity_plugin_1_0_11\Assets\ExampleWorld"
$inputJson = @{cwd=$cwd2; hook_event_name="SessionStart"} | ConvertTo-Json -Compress
$output = $inputJson | & powershell -NoProfile -ExecutionPolicy Bypass -File $hook
Write-Host $output
Write-Host ""

Write-Host "=== Test 3: unknown cwd ==="
$cwd3 = "$env:USERPROFILE\Documents"
$inputJson = @{cwd=$cwd3; hook_event_name="SessionStart"} | ConvertTo-Json -Compress
$output = $inputJson | & powershell -NoProfile -ExecutionPolicy Bypass -File $hook
Write-Host $output

Write-Host ""
Write-Host "=== Log tail ==="
Get-Content "$env:TEMP\world-starter\hook.log" -Tail 5
