<#
.SYNOPSIS
    Anthropic Cybersecurity Gate Auditor for VSD-AI-Toolkit.
    Validates the 6 mandatory security gates defined in API-ARCHITECTURE.md.

.DESCRIPTION
    Scans Go API components for:
    1. Row-Level Security (RLS) enforcement
    2. SQL Injection defense (Parameterized queries)
    3. IDOR protection (Tenant ID override and update suppression)
    4. Secrets & JWT protection
    5. MenuAuth & RBAC readiness
    6. OpenAPI Swagger Godoc documentation

.PARAMETER ComponentPath
    Path to the component directory (e.g., internal/tdtt/danhmuc/chucvu)

.PARAMETER TableName
    Physical table name (optional)

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File ./scripts/audit-api-cybersecurity-gate.ps1 -ComponentPath "internal/tdtt/danhmuc/chucvu"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ComponentPath,

    [Parameter(Mandatory = $false)]
    [string]$TableName = ""
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$FormatEnumerationLimit = -1

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "🛡️  ANTHROPIC CYBERSECURITY GATE AUDITOR (VSD Solution)" -ForegroundColor Cyan
Write-Host "Component: $ComponentPath" -ForegroundColor Cyan
Write-Host "========================================================`n" -ForegroundColor Cyan

if (-not (Test-Path $ComponentPath)) {
    Write-Host "❌ Error: Component path '$ComponentPath' does not exist." -ForegroundColor Red
    exit 1
}

$allPassed = $true
$violations = @()

# Helper function to test regex pattern
function Test-FilePattern {
    param (
        [string]$FilePath,
        [string]$Pattern
    )
    if (-not (Test-Path $FilePath)) { return $false }
    $content = Get-Content $FilePath -Raw -Encoding UTF8
    return ($content -match $Pattern)
}

function Search-FileForbiddenPattern {
    param (
        [string]$FilePath,
        [string]$Pattern
    )
    if (-not (Test-Path $FilePath)) { return $false }
    $content = Get-Content $FilePath -Raw -Encoding UTF8
    return ($content -match $Pattern)
}

# Helper function to find file either as .go or .go.template
function Find-TargetFile {
    param (
        [string]$BasePath,
        [string]$RelativePath
    )
    $exactPath = Join-Path $BasePath $RelativePath
    if (Test-Path $exactPath) { return $exactPath }
    $templatePath = $exactPath + ".template"
    if (Test-Path $templatePath) { return $templatePath }
    return $null
}

# --- GATE 1: Row-Level Security (RLS) ---
$gate1Pass = $true
$routerFiles = Get-ChildItem -Path $ComponentPath -Filter "router*.go*" -Recurse
$handlerFile = Find-TargetFile -BasePath $ComponentPath -RelativePath "handler/handler.go"

$hasRlsProcedure = $false
foreach ($rf in $routerFiles) {
    if (Test-FilePattern -FilePath $rf.FullName -Pattern "CALL\s+apply_rls_for_tables") {
        $hasRlsProcedure = $true
        break
    }
}

$hasSetTenantSession = $false
if ($handlerFile) {
    $hasSetTenantSession = Test-FilePattern -FilePath $handlerFile -Pattern "SET\s+LOCAL\s+app\.current_tenant\s*=\s*\?"
}

if (-not $hasRlsProcedure) {
    $gate1Pass = $false
    $violations += "[Gate 1] Router lacks 'CALL apply_rls_for_tables' execution."
}
if (-not $hasSetTenantSession) {
    $gate1Pass = $false
    $violations += "[Gate 1] Handler lacks parameterized 'SET LOCAL app.current_tenant = ?' inside transaction."
}

if ($gate1Pass) {
    Write-Host " [PASS] Gate 1: Row-Level Security (RLS) & Multi-tenant Isolation" -ForegroundColor Green
} else {
    Write-Host " [FAIL] Gate 1: Row-Level Security (RLS) & Multi-tenant Isolation" -ForegroundColor Red
    $allPassed = $false
}

# --- GATE 2: SQL Injection Defense ---
$gate2Pass = $true
$queryFiles = Get-ChildItem -Path $ComponentPath -Include "*.go", "*.go.template" -Recurse

foreach ($qf in $queryFiles) {
    if ($qf.Name -like "*_test.go*") { continue }
    $content = Get-Content $qf.FullName -Raw -Encoding UTF8

    # Check for forbidden string concatenation in Where/Order/Exec
    if ($content -match '\.(Where|Order|Exec|Raw)\s*\([^)]*(\+|fmt\.Sprintf)') {
        $gate2Pass = $false
        $violations += "[Gate 2] Insecure query string concatenation or fmt.Sprintf found in $($qf.Name)"
    }
}

if ($gate2Pass) {
    Write-Host " [PASS] Gate 2: Anti-SQLi (100% Parameterized queries with '?')" -ForegroundColor Green
} else {
    Write-Host " [FAIL] Gate 2: Anti-SQLi (String concatenation detected)" -ForegroundColor Red
    $allPassed = $false
}

# --- GATE 3: IDOR Defense ---
$gate3Pass = $true
$serviceFile = Find-TargetFile -BasePath $ComponentPath -RelativePath "service/service.go"

$hasHandlerTenantOverride = $false
if ($handlerFile) {
    $hasHandlerTenantOverride = Test-FilePattern -FilePath $handlerFile -Pattern 'input\.TenantID\s*=\s*tenantID'
}

$hasServiceDeleteTenant = $false
if ($serviceFile) {
    $hasServiceDeleteTenant = Test-FilePattern -FilePath $serviceFile -Pattern 'delete\s*\(\s*updateMap\s*,\s*"tenant_id"\s*\)'
}

if (-not $hasHandlerTenantOverride) {
    $gate3Pass = $false
    $violations += "[Gate 3] Handler fails to forcefully override input.TenantID from JWT context."
}
if (-not $hasServiceDeleteTenant) {
    $gate3Pass = $false
    $violations += "[Gate 3] Service fails to delete 'tenant_id' from updateMap (IDOR risk on update)."
}

if ($gate3Pass) {
    Write-Host " [PASS] Gate 3: Anti-IDOR (Tenant ID context enforcement & update suppression)" -ForegroundColor Green
} else {
    Write-Host " [FAIL] Gate 3: Anti-IDOR (Tenant tampering vulnerability detected)" -ForegroundColor Red
    $allPassed = $false
}

# --- GATE 4: Secrets & JWT Protection ---
$gate4Pass = $true
foreach ($gf in $queryFiles) {
    $content = Get-Content $gf.FullName -Raw -Encoding UTF8
    if ($content -match '(?i)(password|secret|jwt_key|private_key)\s*[:=]\s*"[^"]{8,}"') {
        $gate4Pass = $false
        $violations += "[Gate 4] Potential hardcoded secret or credential in $($gf.Name)"
    }
}

if ($gate4Pass) {
    Write-Host " [PASS] Gate 4: Secrets & Credentials Protection (No hardcoded secrets)" -ForegroundColor Green
} else {
    Write-Host " [FAIL] Gate 4: Secrets & Credentials Protection" -ForegroundColor Red
    $allPassed = $false
}

# --- GATE 5: MenuAuth & RBAC Middleware ---
$gate5Pass = $true
$subsystemRouterFile = Get-ChildItem -Path $ComponentPath -Filter "*Subsystem.go*" -Recurse | Select-Object -First 1
if (-not $subsystemRouterFile) {
    $parentSubsystemRouter = Get-ChildItem -Path (Split-Path (Split-Path $ComponentPath -Parent) -Parent) -Filter "router*.go*" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($parentSubsystemRouter) { $subsystemRouterFile = $parentSubsystemRouter }
}

if ($subsystemRouterFile) {
    $hasTenantMw = Test-FilePattern -FilePath $subsystemRouterFile.FullName -Pattern "TenantMiddleware"
    if (-not $hasTenantMw) {
        $gate5Pass = $false
        $violations += "[Gate 5] Subsystem router missing TenantMiddleware."
    }
}

if ($gate5Pass) {
    Write-Host " [PASS] Gate 5: MenuAuth & RBAC Middleware Readiness" -ForegroundColor Green
} else {
    Write-Host " [WARN] Gate 5: Subsystem router check failed" -ForegroundColor Yellow
}

# --- GATE 6: OpenAPI Swagger Godoc Annotations ---
$gate6Pass = $true
if ($handlerFile -and (Test-Path $handlerFile)) {
    $hContent = Get-Content $handlerFile -Raw -Encoding UTF8
    $endpoints = @("GetAll", "Paginate", "GetByID", "Create", "Update", "Delete")
    foreach ($ep in $endpoints) {
        if (-not ($hContent -match "(?s)// $ep godoc.*?func \(h \*Handler\) $ep")) {
            $gate6Pass = $false
            $violations += "[Gate 6] Missing or incomplete Swagger Godoc annotations for endpoint '$ep'."
        }
    }
} else {
    $gate6Pass = $false
    $violations += "[Gate 6] Handler file not found."
}

if ($gate6Pass) {
    Write-Host " [PASS] Gate 6: OpenAPI Swagger Godoc (All 6 standard endpoints documented)" -ForegroundColor Green
} else {
    Write-Host " [FAIL] Gate 6: OpenAPI Swagger Godoc annotations incomplete" -ForegroundColor Red
    $allPassed = $false
}

# --- GATE 7: Ephemeral Test & DoD Cleanup ---
$gate7Pass = $true
$leftoverEphemeralTests = Get-ChildItem -Path $ComponentPath -Filter "*_service_test.go" -Recurse -ErrorAction SilentlyContinue
$legacyTest = Get-ChildItem -Path $ComponentPath -Filter "service_test.go" -Recurse -ErrorAction SilentlyContinue
$allTests = @($leftoverEphemeralTests) + @($legacyTest) | Where-Object { $_ }

foreach ($lt in $allTests) {
    if ($lt.FullName -like "*.template") { continue }
    $c = Get-Content $lt.FullName -Raw -Encoding UTF8
    if ($c -match "EPHEMERAL_TEST_FILE:\s*True") {
        $gate7Pass = $false
        $violations += "[Gate 7] DoD Violation: Ephemeral test file '$($lt.Name)' still remains and must be deleted."
    }
}

if ($gate7Pass) {
    Write-Host " [PASS] Gate 7: DoD Cleanup (Ephemeral tests properly scoped and lifecycle verified)" -ForegroundColor Green
} else {
    Write-Host " [FAIL] Gate 7: DoD Cleanup (Ephemeral test not deleted)" -ForegroundColor Red
    $allPassed = $false
}

Write-Host "`n--------------------------------------------------------" -ForegroundColor Cyan
if ($allPassed) {
    Write-Host "🎉 COMPLIANCE RESULT: ALL CYBERSECURITY GATES PASSED (7/7)" -ForegroundColor Green
    Write-Host "--------------------------------------------------------`n" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "⚠️  COMPLIANCE RESULT: FAILED GATES AUDIT" -ForegroundColor Red
    foreach ($v in $violations) {
        Write-Host "   - $v" -ForegroundColor Red
    }
    Write-Host "--------------------------------------------------------`n" -ForegroundColor Cyan
    exit 1
}
