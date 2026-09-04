# world-starter SessionStart hook
# 책임: cwd 분석 → 작업 유형 추정 → 추정 축 메모리 5건 surface + 최근 회고 1건 surface
# fail-open: 모든 에러는 stderr + %TEMP%\world-starter\hook.log에 기록만, 정상 종료
# Claude Code hook 입력: stdin JSON, 출력: stdout JSON (additionalContext field)

$ErrorActionPreference = 'Continue'
$logDir = "$env:TEMP\world-starter"
$logFile = "$logDir\hook.log"

# UTF-8 raw stream I/O — PS5.1 파이프 기본 [Console] 인코딩=CP949 mojibake fix
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
    Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [session-start] invoked" -Encoding UTF8

    # 입력 읽기 (stdin도 UTF-8 강제 — [Console]::In 기본 CP949)
    $rawInput = (New-Object System.IO.StreamReader([Console]::OpenStandardInput(), $utf8NoBom)).ReadToEnd()
    $cwd = (Get-Location).Path
    if ($rawInput) {
        try {
            $json = $rawInput | ConvertFrom-Json
            if ($json.cwd) { $cwd = $json.cwd }
        } catch { Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [session-start] input JSON parse fail (fallback to cwd)" -Encoding UTF8 }
    }

    # cwd → 작업 유형 추정
    # 아래 패턴은 예시입니다 — 여러분의 폴더 명명 규칙(기획서/월드 프로젝트 경로)에 맞게 교체하세요.
    $workType = "unknown"
    if ($cwd -match '-기획') { $workType = "doc" }
    elseif ($cwd -match 'buildit' -or $cwd -match '\\Assets\\') { $workType = "world" }

    # 추정 축 메모리 grep (PS 5.1 array += 함정 회피 — ArrayList 사용)
    # 아래 glob 패턴도 예시입니다 — 여러분의 메모리 파일 명명 규칙에 맞게 교체하세요.
    $memoryDir = "$env:USERPROFILE\.claude\projects\C--WINDOWS-system32\memory"
    $axisMemories = New-Object System.Collections.ArrayList
    function Add-Memories {
        param($filter, $take)
        $items = @(Get-ChildItem $memoryDir -Filter $filter -ErrorAction SilentlyContinue | Select-Object -First $take)
        foreach ($it in $items) { [void]$axisMemories.Add($it) }
    }
    if ($workType -eq "doc") {
        Add-Memories 'project_*_doc*.md' 3
        Add-Memories 'reference_figma_mcp_*.md' 1
        Add-Memories 'project_zepeto_direction*.md' 1
    } elseif ($workType -eq "world") {
        Add-Memories 'project_*_buildit_porting*.md' 1
        Add-Memories 'reference_buildit_*.md' 2
        Add-Memories 'feedback_buildit_*.md' 2
    }

    # 최근 회고 1건
    $retroDir = "$env:USERPROFILE\.claude\world-starter\retro"
    $latestRetro = $null
    if (Test-Path $retroDir) {
        $latestRetro = Get-ChildItem $retroDir -Filter '*.md' -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    }

    # additionalContext 조립
    $lines = @()
    $lines += "## world-starter SessionStart"
    $lines += ""
    $lines += "- cwd: ``$cwd``"
    $lines += "- 추정 작업 유형: **$workType**"
    if ($workType -eq "unknown") {
        $lines += "  - (cwd 패턴 미매칭 — 작업 시작 시 명시 호출 권장: /world-doc, /world-build, /world-retro)"
    }
    $lines += ""
    if ($axisMemories.Count -gt 0) {
        $lines += "### 추정 축 메모리 ($workType 우선 surface, 상위 $($axisMemories.Count)건)"
        foreach ($m in $axisMemories) {
            $lines += "- ``$($m.Name)``"
        }
        $lines += ""
    }
    if ($latestRetro) {
        $lines += "### 최근 회고"
        $lines += "- ``$($latestRetro.Name)`` (자세히 보려면 Read tool)"
        $lines += ""
    }
    $lines += "### v1 활성 진입점"
    $lines += "- 기획: /world-doc | 월드: /world-build | 회고: /world-retro"
    $lines += "- (v1.1+) Orchestrator: /goal <자연어>"

    $additionalContext = $lines -join "`n"

    # 출력 JSON
    $output = @{
        hookSpecificOutput = @{
            hookEventName = "SessionStart"
            additionalContext = $additionalContext
        }
    } | ConvertTo-Json -Depth 10 -Compress

    Write-HookOutput $output
    Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [session-start] OK workType=$workType axis=$($axisMemories.Count) retro=$(if($latestRetro){'y'}else{'n'})" -Encoding UTF8
} catch {
    Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [session-start] ERROR $_" -Encoding UTF8
    # fail-open: 빈 JSON 반환
    Write-HookOutput '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":""}}'
}
