# world-starter PreToolUse hook
# 책임: Bash·Edit·Write 도구 호출 직전 위험 검사 → Soft-block (사용자 명시 답변으로 우회 가능)
# fail-open: 검사 자체 에러는 통과 (가용성 우선)
# Claude Code hook 입력: stdin JSON ({tool_name, tool_input}), 출력: stdout JSON

$ErrorActionPreference = 'Continue'
$logDir = "$env:TEMP\world-starter"
$logFile = "$logDir\hook.log"
$blockLog = "$logDir\preTool-block.log"
$configFile = "$env:USERPROFILE\.claude\world-starter\config\preserve-list.json"

# UTF-8 raw stream I/O — PS5.1 파이프 기본 [Console] 인코딩=CP949 → 차단 메시지 한글 mojibake fix
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
function Write-HookOutput {
    param($text)
    $writer = New-Object System.IO.StreamWriter([Console]::OpenStandardOutput(), $utf8NoBom)
    $writer.Write($text)
    $writer.Flush()
}

function Read-Config {
    try {
        return Get-Content $configFile -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [pre-tool-use] config read fail: $_"
        return $null
    }
}

function Test-DenyCommand {
    param($cmd, $config)
    if (-not $config) { return $null }
    foreach ($rule in $config.deny_commands) {
        if ($cmd -match $rule.pattern) {
            return $rule
        }
    }
    return $null
}

function Test-PreserveFile {
    param($filePath, $config)
    if (-not $config -or -not $filePath) { return $null }
    foreach ($rule in $config.patterns) {
        # glob → regex
        $regex = $rule.pattern -replace '\\', '\\' -replace '\*', '.*'
        if ($filePath -match $regex) {
            return $rule
        }
    }
    return $null
}

try {
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
    if ((Test-Path $logFile) -and ((Get-Item $logFile).Length -gt 2MB)) { Move-Item $logFile "$logFile.old" -Force }
    Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [pre-tool-use] invoked" -Encoding UTF8

    $rawInput = (New-Object System.IO.StreamReader([Console]::OpenStandardInput(), $utf8NoBom)).ReadToEnd()
    if (-not $rawInput) {
        Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [pre-tool-use] empty input — allow" -Encoding UTF8
        Write-HookOutput '{}'
        return
    }

    $json = $rawInput | ConvertFrom-Json
    $toolName = $json.tool_name
    $config = Read-Config

    $blockReason = $null
    $blockSource = $null

    if ($toolName -in @("Bash", "PowerShell")) {
        # PowerShell 도구도 명령 검사 — matcher 확장과 짝, soft-block 우회 구멍 봉합
        $cmd = $json.tool_input.command
        $rule = Test-DenyCommand -cmd $cmd -config $config
        if ($rule) {
            $blockReason = $rule.reason
            $blockSource = $rule.source
        }
    } elseif ($toolName -in @("Edit", "Write")) {
        $filePath = $json.tool_input.file_path
        $rule = Test-PreserveFile -filePath $filePath -config $config
        if ($rule) {
            $blockReason = "사용자 명시 결정 보존 파일 수정 시도: $($rule.reason)"
            $blockSource = $rule.source
        }
    }

    if ($blockReason) {
        $sourceText = if ($blockSource) { "[[" + $blockSource + "]]" } else { "(no source)" }
        $msg = "## world-starter Soft-block`n`n**차단 이유**: $blockReason`n**출처**: $sourceText`n`n이 명령을 정말 실행해야 하면, 다음을 명시 답변:`n1. 왜 이 위험을 무릅쓰는지 (1~2문장)`n2. 어떤 우회 방식이 안전한지 (예: branch 변경, 다른 파일로 우회)`n3. 사용자 컨펌 받았는지`n`n답변 후 다시 시도하면 통과합니다 (1회 우회)."

        Add-Content $blockLog "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [BLOCK] tool=$toolName reason=$blockReason" -Encoding UTF8
        # PreToolUse permissionDecision schema (Claude Code 공식)
        $output = @{
            hookSpecificOutput = @{
                hookEventName = "PreToolUse"
                permissionDecision = "deny"
                permissionDecisionReason = $msg
            }
        } | ConvertTo-Json -Depth 10 -Compress
        Write-HookOutput $output
    } else {
        Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [pre-tool-use] OK tool=$toolName allow" -Encoding UTF8
        Write-HookOutput '{}'
    }
} catch {
    Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [pre-tool-use] ERROR $_ (fail-open)" -Encoding UTF8
    Write-HookOutput '{}'
}
