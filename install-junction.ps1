<#
.SYNOPSIS
    Cai dat tich hop nhanh VSD-AI-Toolkit vao du an bat ky hoac toan cuc cho Antigravity IDE su dung NTFS Directory Junction.
.DESCRIPTION
    Script nay tao lien ket thu muc (Directory Junction) tu VSD-AI-Toolkit sang:
    - Du an dich (Workspace scope): Lien ket .agents va cac file cau hinh.
    - Toan cuc (Global scope): Lien ket truc tiep vao ~/.gemini/config/skills/ cho Antigravity IDE.
.PARAMETER TargetPath
    Duong dan thu muc du an dich can tich hop (hoac 'global'/'self' de tich hop toan cuc cho Antigravity).
.PARAMETER Global
    Cong tac tich hop toan cuc cho chinh Antigravity IDE (~/.gemini/config).
.PARAMETER Uninstall
    Go bo lien ket an toan (chi xoa lien ket junction, khong lam mat du lieu goc).
.EXAMPLE
    .\install-junction.ps1 -Global
    .\install-junction.ps1 -TargetPath "D:\VSD-Solution\Projects\MyNewProject"
    .\install-junction.ps1 -Global -Uninstall
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$TargetPath = "",

    [Parameter(Mandatory = $false)]
    [switch]$Global,

    [Parameter(Mandatory = $false)]
    [switch]$Uninstall
)

$ToolkitRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ToolkitRoot)) {
    $ToolkitRoot = (Get-Location).Path
}

# Kiem tra neu chon che do Global
if ($Global -or ($TargetPath -in @("global", "self", "me", "gemini", "antigravity"))) {
    $isGlobalScope = $true
    $TargetPath = Join-Path $env:USERPROFILE ".gemini\config"
} else {
    $isGlobalScope = $false
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
if ($isGlobalScope) {
    Write-Host " [VSD-AI-TOOLKIT] TICH HOP TOAN CUC CHO ANTIGRAVITY IDE" -ForegroundColor Green
    Write-Host " Che do: GLOBAL (~/.gemini/config)" -ForegroundColor Yellow
} else {
    Write-Host " [VSD-AI-TOOLKIT] TRINH TICH HOP NHANH (NTFS JUNCTION)" -ForegroundColor Cyan
    Write-Host " Che do: WORKSPACE / DU AN" -ForegroundColor Yellow
}
Write-Host " Toolkit Source: $ToolkitRoot" -ForegroundColor DarkGray
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# Neu chua truyen TargetPath, yeu cau nguoi dung nhap
if ([string]::IsNullOrWhiteSpace($TargetPath)) {
    Write-Host "Nhap duong dan thu muc du an dich (hoac 'global' de cai toan cuc):" -ForegroundColor Yellow
    $inputPath = Read-Host "Duong dan"
    $cleanInput = $inputPath.Trim('"').Trim("'")
    if ($cleanInput -in @("global", "self", "me", "gemini", "antigravity")) {
        $isGlobalScope = $true
        $TargetPath = Join-Path $env:USERPROFILE ".gemini\config"
    } else {
        $TargetPath = $cleanInput
    }
}

if ([string]::IsNullOrWhiteSpace($TargetPath)) {
    Write-Host "[ERROR] Ban chua cung cap duong dan dich." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -LiteralPath $TargetPath)) {
    if ($isGlobalScope) {
        New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
    } else {
        Write-Host "[ERROR] Thu muc du an dich khong ton tai: '$TargetPath'" -ForegroundColor Red
        exit 1
    }
}

$TargetPath = (Resolve-Path -LiteralPath $TargetPath).Path

# Ham ho tro go bo Junction an toan tuyet doi
function Remove-SafeJunction {
    param ([string]$JunctionPath)
    if (Test-Path -LiteralPath $JunctionPath) {
        $item = Get-Item -LiteralPath $JunctionPath -Force
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            cmd /c rmdir "$JunctionPath" 2>$null
            Write-Host "  [-] Da go bo Junction: $JunctionPath" -ForegroundColor DarkYellow
        } else {
            Write-Host "  [!] Bo qua (khong phai Junction): $JunctionPath" -ForegroundColor Yellow
        }
    }
}

# Ham ho tro tao Junction
function Create-Junction {
    param (
        [string]$LinkPath,
        [string]$DestTarget
    )
    if (Test-Path -LiteralPath $LinkPath) {
        $existing = Get-Item -LiteralPath $LinkPath -Force
        if ($existing.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            Write-Host "  [i] Junction da ton tai: $LinkPath -> $DestTarget" -ForegroundColor DarkGray
            return
        } else {
            Write-Host "  [!] Thu muc thong thuong da ton tai, se xu ly long ghep: $LinkPath" -ForegroundColor Yellow
            return
        }
    }

    # Dam bao thu muc cha ton tai
    $parentDir = Split-Path -Parent $LinkPath
    if (-not (Test-Path -LiteralPath $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    try {
        New-Item -ItemType Junction -Path $LinkPath -Target $DestTarget -Force | Out-Null
        Write-Host "  [+] Da tao Junction: $LinkPath => $DestTarget" -ForegroundColor Green
    } catch {
        cmd /c mklink /J "$LinkPath" "$DestTarget" | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [+] Da tao Junction (qua mklink): $LinkPath => $DestTarget" -ForegroundColor Green
        } else {
            Write-Host "  [ERROR] That bai khi tao Junction cho $LinkPath" -ForegroundColor Red
        }
    }
}

# Ham ho tro dong bo file cau hinh
function Sync-ConfigFile {
    param (
        [string]$SourceFile,
        [string]$DestFile
    )
    if (-not (Test-Path -LiteralPath $SourceFile)) { return }

    $sourceName = Split-Path -Leaf $SourceFile
    if (-not (Test-Path -LiteralPath $DestFile)) {
        Copy-Item -LiteralPath $SourceFile -Destination $DestFile -Force
        Write-Host "  [+] Da dong bo file cau hinh: $sourceName" -ForegroundColor Green
    } else {
        Write-Host "  [i] File da ton tai: $sourceName (giu nguyen)" -ForegroundColor DarkGray
    }
}

# ==========================================
# XU LY GO BO (UNINSTALL)
# ==========================================
if ($Uninstall) {
    Write-Host "Dang go bo tich hop VSD-AI-Toolkit khoi: $TargetPath..." -ForegroundColor Yellow
    Write-Host ""
    
    if ($isGlobalScope) {
        Remove-SafeJunction -JunctionPath (Join-Path $TargetPath "skills\vsd-api")
        Remove-SafeJunction -JunctionPath (Join-Path $TargetPath "skills\vsd-angular")
    } else {
        # Workspace scope
        $targetAgents = Join-Path $TargetPath ".agents"
        Remove-SafeJunction -JunctionPath $targetAgents
        Remove-SafeJunction -JunctionPath (Join-Path $TargetPath ".agents\skills\vsd-api")
        Remove-SafeJunction -JunctionPath (Join-Path $TargetPath ".agents\skills\vsd-angular")
    }

    Write-Host ""
    Write-Host "[SUCCESS] Hoan tat go bo lien ket an toan!" -ForegroundColor Green
    exit 0
}

# ==========================================
# XU LY CAI DAT (INSTALL VIA JUNCTION)
# ==========================================
$sourceAgents = Join-Path $ToolkitRoot ".agents"
if (-not (Test-Path -LiteralPath $sourceAgents)) {
    Write-Host "[ERROR] Thu muc nguon '.agents' khong tim thay tai $ToolkitRoot." -ForegroundColor Red
    exit 1
}

$sourceApiSkill = Join-Path $sourceAgents "skills\vsd-api"
$sourceAngularSkill = Join-Path $sourceAgents "skills\vsd-angular"
$sourceAgentsMd = if (Test-Path -LiteralPath (Join-Path $sourceAgents "AGENTS.md")) { Join-Path $sourceAgents "AGENTS.md" } else { Join-Path $ToolkitRoot "AGENTS.md" }

if ($isGlobalScope) {
    # ----------------------------------------------------
    # CAI DAT TOAN CUC CHO ANTIGRAVITY IDE (~/.gemini/config)
    # ----------------------------------------------------
    Write-Host "Dang tich hop toan cuc cho Antigravity IDE tai: $TargetPath..." -ForegroundColor Cyan
    Write-Host ""

    # [1/3] Tao Junction cac Skills vao ~/.gemini/config/skills/
    Write-Host "[1/3] Tao Junction Global Skills cho Antigravity IDE:" -ForegroundColor Cyan
    $globalSkillsDir = Join-Path $TargetPath "skills"
    if (-not (Test-Path -LiteralPath $globalSkillsDir)) {
        New-Item -ItemType Directory -Path $globalSkillsDir -Force | Out-Null
    }
    Create-Junction -LinkPath (Join-Path $globalSkillsDir "vsd-api") -DestTarget $sourceApiSkill
    Create-Junction -LinkPath (Join-Path $globalSkillsDir "vsd-angular") -DestTarget $sourceAngularSkill

    # [2/3] Dong bo Global Rules vao ~/.gemini/config/rules/ va AGENTS.md
    Write-Host ""
    Write-Host "[2/3] Dong bo Global Rules & Huong dan dieu phoi Agent:" -ForegroundColor Cyan
    $globalRulesDir = Join-Path $TargetPath "rules"
    if (-not (Test-Path -LiteralPath $globalRulesDir)) {
        New-Item -ItemType Directory -Path $globalRulesDir -Force | Out-Null
    }
    Sync-ConfigFile -SourceFile (Join-Path $sourceAgents "rules\vsd-api.md") -DestFile (Join-Path $globalRulesDir "vsd-api.md")
    Sync-ConfigFile -SourceFile (Join-Path $sourceAgents "rules\vsd-angular.md") -DestFile (Join-Path $globalRulesDir "vsd-angular.md")
    Sync-ConfigFile -SourceFile $sourceAgentsMd -DestFile (Join-Path $TargetPath "AGENTS.md")

    # [3/3] Xac thuc Global
    Write-Host ""
    Write-Host "[3/3] Kiem tra tinh hop le cua Global Skills:" -ForegroundColor Cyan
    $testSkillApi = Join-Path $globalSkillsDir "vsd-api\SKILL.md"
    $testSkillAngular = Join-Path $globalSkillsDir "vsd-angular\SKILL.md"

} else {
    # ----------------------------------------------------
    # CAI DAT WORKSPACE / DU AN (Project Scope)
    # ----------------------------------------------------
    Write-Host "Dang tien hanh lien ket Junction toi du an: $TargetPath..." -ForegroundColor Cyan
    Write-Host ""

    $targetAgents = Join-Path $TargetPath ".agents"

    if (-not (Test-Path -LiteralPath $targetAgents)) {
        Write-Host "[1/3] Tao Junction toan bo thu muc .agents:" -ForegroundColor Cyan
        Create-Junction -LinkPath $targetAgents -DestTarget $sourceAgents
    } else {
        Write-Host "[1/3] Phat hien .agents da ton tai, tien hanh lien ket tung Skill va Rule:" -ForegroundColor Cyan
        Create-Junction -LinkPath (Join-Path $targetAgents "skills\vsd-api") -DestTarget $sourceApiSkill
        Create-Junction -LinkPath (Join-Path $targetAgents "skills\vsd-angular") -DestTarget $sourceAngularSkill

        $targetRulesDir = Join-Path $targetAgents "rules"
        if (-not (Test-Path -LiteralPath $targetRulesDir)) {
            New-Item -ItemType Directory -Path $targetRulesDir -Force | Out-Null
        }
        Sync-ConfigFile -SourceFile (Join-Path $sourceAgents "rules\vsd-api.md") -DestFile (Join-Path $targetRulesDir "vsd-api.md")
        Sync-ConfigFile -SourceFile (Join-Path $sourceAgents "rules\vsd-angular.md") -DestFile (Join-Path $targetRulesDir "vsd-angular.md")
        Sync-ConfigFile -SourceFile $sourceAgentsMd -DestFile (Join-Path $targetAgents "AGENTS.md")
    }

    Write-Host ""
    Write-Host "[2/3] Dong bo cau hinh AI Coding Assistants:" -ForegroundColor Cyan
    Sync-ConfigFile -SourceFile $sourceAgentsMd -DestFile (Join-Path $TargetPath "AGENTS.md")
    Sync-ConfigFile -SourceFile (Join-Path $ToolkitRoot ".cursorrules") -DestFile (Join-Path $TargetPath ".cursorrules")

    # Don dep file kien truc cu tai root neu co (kien truc da duoc dong goi khep kin vao references/ cua tung Skill)
    $legacyApiArch = Join-Path $TargetPath "API-ARCHITECTURE.md"
    if (Test-Path -LiteralPath $legacyApiArch) {
        Remove-Item -LiteralPath $legacyApiArch -Force -ErrorAction SilentlyContinue
    }
    $legacyAngularArch = Join-Path $TargetPath "ANGULAR-ARCHITECTURE.md"
    if (Test-Path -LiteralPath $legacyAngularArch) {
        Remove-Item -LiteralPath $legacyAngularArch -Force -ErrorAction SilentlyContinue
    }

    Write-Host ""
    Write-Host "[3/3] Kiem tra tinh hop le cua lien ket Junction:" -ForegroundColor Cyan
    $testSkillApi = Join-Path $TargetPath ".agents\skills\vsd-api\SKILL.md"
    $testSkillAngular = Join-Path $TargetPath ".agents\skills\vsd-angular\SKILL.md"
}

$verified = $true
if (Test-Path -LiteralPath $testSkillApi) {
    Write-Host "  [OK] vsd-api: Hoat dong tot (Nhan dien day du SKILL.md, templates, scripts)" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] vsd-api: Khong tim thay SKILL.md tai $testSkillApi" -ForegroundColor Red
    $verified = $false
}

if (Test-Path -LiteralPath $testSkillAngular) {
    Write-Host "  [OK] vsd-angular: Hoat dong tot (Nhan dien day du SKILL.md, templates, scripts)" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] vsd-angular: Khong tim thay SKILL.md tai $testSkillAngular" -ForegroundColor Red
    $verified = $false
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
if ($verified) {
    if ($isGlobalScope) {
        Write-Host " [THANH CONG] DA TICH HOP TOAN CUC CHO ANTIGRAVITY IDE!" -ForegroundColor Green
        Write-Host "========================================================" -ForegroundColor Cyan
        Write-Host "Chinh Antigravity IDE gio day da so huu ca 2 Agent o moi Workspace:" -ForegroundColor Yellow
    } else {
        Write-Host " [THANH CONG] TICH HOP HOAN TAT QUA NTFS JUNCTION!" -ForegroundColor Green
        Write-Host "========================================================" -ForegroundColor Cyan
        Write-Host "Du an dich da san sang su dung 2 Agent:" -ForegroundColor Yellow
    }
    Write-Host "  1. vsd-api     : Phat trien Go Backend API (7 micro-tasks, 7 an ninh)" -ForegroundColor White
    Write-Host "  2. vsd-angular : Phat trien Angular UI Client (7 micro-tasks, 6 an ninh)" -ForegroundColor White
    Write-Host ""
    Write-Host "Moi cap nhat skill/templates/scripts tai Toolkit se lap tuc co hieu luc ngay!" -ForegroundColor DarkGray
} else {
    Write-Host " [CANH BAO] Tich hop chua hoan hao - Vui long kiem tra lai." -ForegroundColor Yellow
    Write-Host "========================================================" -ForegroundColor Cyan
}
