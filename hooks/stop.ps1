# world-starter Stop hook
# 책임: 세션 종료 시 (a) 메모리 저장 가치 alert + (b) 회고(/world-retro) 제안
# 휴리스틱: 작업 분량 임계(>=30 도구 호출) OR "확정/결정/우회/함정" 키워드 N회 이상
# fail-silent: 에러 시 alert 없이 종료

$ErrorActionPreference = 'Continue'
$logDir = "$env:TEMP\world-starter"
$logFile = "$logDir\hook.log"

# UTF-8 raw stream I/O — PS5.1 파이프 기본 [Console] 인코딩=CP949 → 한글 키워드(확정/결정...) 매칭 silent fail fix
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
    Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [stop] invoked" -Encoding UTF8

    $rawInput = (New-Object System.IO.StreamReader([Console]::OpenStandardInput(), $utf8NoBom)).ReadToEnd()
    $transcriptPath = $null
    if ($rawInput) {
        try {
            $json = $rawInput | ConvertFrom-Json
            if ($json.transcript_path) { $transcriptPath = $json.transcript_path }
        } catch {}
    }

    if (-not $transcriptPath -or -not (Test-Path $transcriptPath)) {
        Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [stop] no transcript — silent exit" -Encoding UTF8
        return
    }

    # transcript 분석 — 도구 호출 수 + 키워드 빈도 (★transcript=UTF-8 JSONL — 인코딩 명시 필수)
    $toolUseCount = 0
    $keywordHits = 0
    $kwPattern = '(확정|결정|우회|함정|학습|새로 알게)'
    Get-Content $transcriptPath -Encoding UTF8 | ForEach-Object {
        try {
            $entry = $_ | ConvertFrom-Json
            if ($entry.type -eq "assistant" -and $entry.message.content) {
                foreach ($c in $entry.message.content) {
                    if ($c.type -eq "tool_use") { $toolUseCount++ }
                    if ($c.type -eq "text" -and $c.text -match $kwPattern) { $keywordHits++ }
                }
            }
        } catch {}
    }

    $shouldRetro = ($toolUseCount -ge 30) -or ($keywordHits -ge 3)
    Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [stop] toolUse=$toolUseCount keywords=$keywordHits retro=$shouldRetro" -Encoding UTF8

    if (-not $shouldRetro) {
        Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [stop] below threshold — silent exit" -Encoding UTF8
        return
    }

    # alert 메시지 조립
    $msg = "## world-starter Stop alert`n`n이번 세션 분량 — 도구 호출 $toolUseCount회, 결정·학습 키워드 $keywordHits회 등장.`n`n**제안**:`n1. **메모리 저장 가치 점검** — 새로 알게 된 결·트랩·결정이 있다면 ``feedback_*`` / ``reference_*`` 메모리 저장 고려`n2. **회고 (/world-retro)** — 이번 작업의 Worked / Didn't / Improvements 분류 → 자가 patch 후보 생성`n`n회고 진행하려면 ``/world-retro`` 호출."

    # Stop hook output - systemMessage 표시 (decision 미사용)
    $output = @{
        systemMessage = $msg
    } | ConvertTo-Json -Depth 5 -Compress

    Write-HookOutput $output
} catch {
    Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [stop] ERROR $_ (fail-silent)" -Encoding UTF8
}
