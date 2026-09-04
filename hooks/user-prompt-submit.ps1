# world-starter UserPromptSubmit hook
# 책임: 사용자 프롬프트 키워드 매칭 → 관련 메모리 5건 추가 surface as additionalContext
# fail-open: 매칭 0건이면 빈 출력

$ErrorActionPreference = 'Continue'
$logDir = "$env:TEMP\world-starter"
$logFile = "$logDir\hook.log"
$configFile = "$env:USERPROFILE\.claude\world-starter\config\keyword-dict.json"
$memoryDir = "$env:USERPROFILE\.claude\projects\C--WINDOWS-system32\memory"

# UTF-8 raw stream I/O — PS5.1 파이프 기본 [Console] 인코딩=CP949 → 한글 키워드 매칭 silent fail fix
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
function Write-HookOutput {
    param($text)
    $writer = New-Object System.IO.StreamWriter([Console]::OpenStandardOutput(), $utf8NoBom)
    $writer.Write($text)
    $writer.Flush()
}

try {
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
    if ((Test-Path $logFile) -and ((Get-Item $logFile).Length -gt 2MB)) { Move-Item $logFile "$logFile.old" -Force }
    Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [user-prompt-submit] invoked" -Encoding UTF8

    $rawInput = (New-Object System.IO.StreamReader([Console]::OpenStandardInput(), $utf8NoBom)).ReadToEnd()
    if (-not $rawInput) {
        Write-HookOutput '{}'
        return
    }

    $json = $rawInput | ConvertFrom-Json
    $prompt = $json.prompt
    if (-not $prompt) {
        Write-HookOutput '{}'
        return
    }

    # 키워드 사전 로드
    $config = Get-Content $configFile -Raw -Encoding UTF8 | ConvertFrom-Json

    # 매칭
    $matchedMemories = New-Object System.Collections.Generic.HashSet[string]
    foreach ($mapping in $config.mappings) {
        $matched = $false
        foreach ($kw in $mapping.keywords) {
            if ($prompt -like "*$kw*") { $matched = $true; break }
        }
        if ($matched) {
            foreach ($m in $mapping.memories) {
                if ($matchedMemories.Count -ge 5) { break }
                [void]$matchedMemories.Add($m)
            }
        }
        if ($matchedMemories.Count -ge 5) { break }
    }

    if ($matchedMemories.Count -eq 0) {
        Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [user-prompt-submit] no match — silent" -Encoding UTF8
        Write-HookOutput '{}'
        return
    }

    # 존재 파일만 surface
    $existingFiles = New-Object System.Collections.ArrayList
    foreach ($m in $matchedMemories) {
        $path = "$memoryDir\$m"
        if (Test-Path $path) { [void]$existingFiles.Add($m) }
    }

    if ($existingFiles.Count -eq 0) {
        Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [user-prompt-submit] matched but no files exist" -Encoding UTF8
        Write-HookOutput '{}'
        return
    }

    $lines = New-Object System.Collections.ArrayList
    [void]$lines.Add("## world-starter UserPromptSubmit")
    [void]$lines.Add("")
    [void]$lines.Add("프롬프트 키워드 매칭으로 다음 메모리가 관련 있음 (Read tool로 자세히):")
    foreach ($f in $existingFiles) {
        [void]$lines.Add("- ``$f``")
    }
    $additionalContext = ($lines.ToArray()) -join "`n"

    $output = @{
        hookSpecificOutput = @{
            hookEventName = "UserPromptSubmit"
            additionalContext = $additionalContext
        }
    } | ConvertTo-Json -Depth 10 -Compress

    Write-HookOutput $output
    Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [user-prompt-submit] OK matched=$($existingFiles.Count)" -Encoding UTF8
} catch {
    Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [user-prompt-submit] ERROR $_" -Encoding UTF8
    Write-HookOutput '{}'
}
