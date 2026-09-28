<#
.SYNOPSIS
    Anthropic Cybersecurity Gate Auditor for Angular Client (VSD-AI-Toolkit).
    Validates the 6 mandatory frontend security gates defined in ANGULAR-ARCHITECTURE.md.

.DESCRIPTION
    Scans Angular components for:
    1. MenuAuth & RBAC enforcement (Action buttons & Route guards)
    2. Cross-Site Scripting (XSS) defense (Safe template binding, no bypassSecurityTrustHtml)
    3. Secrets & credentials protection (No hardcoded secrets, BackEndConfig.API_URL)
    4. Form sanitization & transformation (enforceTextTransform & @FormField)
    5. OWASP Top 10 Web Client compliance (Error handling & data integrity)
    6. Ephemeral Test DoD cleanup validation

.PARAMETER ComponentPath
    Path to the component directory or templates directory

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File ./scripts/audit-angular-cybersecurity-gate.ps1 -ComponentPath "templates/angular-component"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ComponentPath
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$FormatEnumerationLimit = -1

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "🛡️  ANTHROPIC FRONTEND CYBERSECURITY GATE AUDITOR (VSD Solution)" -ForegroundColor Cyan
Write-Host "Component: $ComponentPath" -ForegroundColor Cyan
Write-Host "========================================================`n" -ForegroundColor Cyan

if (-not (Test-Path $ComponentPath)) {
    Write-Host "❌ Error: Component path '$ComponentPath' does not exist." -ForegroundColor Red
    exit 1
}

$allPassed = $true
$violations = @()

# Helper function to find file either directly or with .template extension
function Find-TargetFile {
    param (
        [string]$BasePath,
        [string]$RelativePath
    )
    $exactPath = Join-Path $BasePath $RelativePath
    if (Test-Path $exactPath) { return $exactPath }
    $templatePath = $exactPath + ".template"
    if (Test-Path $templatePath) { return $templatePath }

    # Also search recursively if not found directly
    $baseName = [System.IO.Path]::GetFileName($RelativePath)
    $found = Get-ChildItem -Path $BasePath -Filter "$baseName*" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { return $found.FullName }

    return $null
}

function Test-FilePattern {
    param (
        $FilePath,
        [string]$Pattern
    )
    if (-not $FilePath) { return $false }
    $resolved = if ($FilePath -is [System.IO.FileInfo]) { $FilePath.FullName } elseif ($FilePath.FullName) { $FilePath.FullName } else { $FilePath.ToString() }
    if (-not (Test-Path $resolved)) { return $false }
    $content = Get-Content $resolved -Raw -Encoding UTF8
    return ($content -match $Pattern)
}

# --- GATE 1: MenuAuth RBAC (Buttons & Route Guard) ---
$gate1Pass = $true
$tableHtml = Find-TargetFile -BasePath $ComponentPath -RelativePath "table/table.component.html"
if (-not $tableHtml) {
    $tableHtml = Get-ChildItem -Path $ComponentPath -Filter "*component.html*" -Recurse | Select-Object -First 1
}

$hasRbacButtons = $false
if ($tableHtml) {
    $hasRbacButtons = Test-FilePattern -FilePath $tableHtml -Pattern 'permissionService\.hasPermission\('
}

$routingFile = Find-TargetFile -BasePath $ComponentPath -RelativePath "routing/routing.module.ts"
if (-not $routingFile) {
    # Check parent routing file
    $parentRouting = Get-ChildItem -Path (Split-Path $ComponentPath -Parent) -Filter "*routing.module.ts*" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($parentRouting) { $routingFile = $parentRouting }
}

$hasRouteGuard = $false
if ($routingFile) {
    $hasRouteGuard = Test-FilePattern -FilePath $routingFile -Pattern 'canActivate:\s*\[NavigationPermissionGuard\]'
}

if (-not $hasRbacButtons) {
    $gate1Pass = $false
    $violations += "[Gate 1] Table template lacks permissionService.hasPermission() protecting action buttons."
}
if ($routingFile -and -not $hasRouteGuard) {
    $gate1Pass = $false
    $violations += "[Gate 1] Routing module missing 'canActivate: [NavigationPermissionGuard]'."
}

if ($gate1Pass) {
    Write-Host " [PASS] Gate 1: MenuAuth & RBAC (Action buttons & Route guards protected)" -ForegroundColor Green
} else {
    Write-Host " [FAIL] Gate 1: MenuAuth & RBAC" -ForegroundColor Red
    $allPassed = $false
}

# --- GATE 2: Anti-XSS Defense ---
$gate2Pass = $true
$allSourceFiles = Get-ChildItem -Path $ComponentPath -Include "*.ts", "*.html", "*.ts.template", "*.html.template" -Recurse

foreach ($f in $allSourceFiles) {
    $content = Get-Content $f.FullName -Raw -Encoding UTF8
    if ($content -match 'bypassSecurityTrustHtml|bypassSecurityTrustScript') {
        $gate2Pass = $false
        $violations += "[Gate 2] Insecure DomSanitizer bypass found in $($f.Name)."
    }
}

if ($gate2Pass) {
    Write-Host " [PASS] Gate 2: Anti-XSS (Safe template binding, no unverified DomSanitizer bypass)" -ForegroundColor Green
} else {
    Write-Host " [FAIL] Gate 2: Anti-XSS (Dangerous HTML bypass detected)" -ForegroundColor Red
    $allPassed = $false
}

# --- GATE 3: Secrets & Credential Protection (No Secrets) ---
$gate3Pass = $true
$serviceFile = Find-TargetFile -BasePath $ComponentPath -RelativePath "service/service.ts"
if (-not $serviceFile) {
    $serviceFile = Get-ChildItem -Path $ComponentPath -Filter "*service.ts*" -Recurse | Select-Object -First 1
}

$hasConfigApiUrl = $true
if ($serviceFile) {
    $content = Get-Content $serviceFile -Raw -Encoding UTF8
    if (-not ($content -match 'BackEndConfig\.API_URL')) {
        $hasConfigApiUrl = $false
        $gate3Pass = $false
        $violations += "[Gate 3] Service fails to use 'BackEndConfig.API_URL' for base API address."
    }
}

foreach ($f in $allSourceFiles) {
    if ($f.Name -like "*spec.ts*") { continue }
    $content = Get-Content $f.FullName -Raw -Encoding UTF8
    if ($content -match '(?i)(client_secret|jwt_secret|api_key|password)\s*[:=]\s*"[^"]{8,}"') {
        $gate3Pass = $false
        $violations += "[Gate 3] Potential hardcoded secret or credential in $($f.Name)."
    }
}

if ($gate3Pass) {
    Write-Host " [PASS] Gate 3: Secrets & Credentials Protection (BackEndConfig used, no hardcoded secrets)" -ForegroundColor Green
} else {
    Write-Host " [FAIL] Gate 3: Secrets & Credentials Protection" -ForegroundColor Red
    $allPassed = $false
}

# --- GATE 4: Form Sanitization & Transformation ---
$gate4Pass = $true
$modalFile = Find-TargetFile -BasePath $ComponentPath -RelativePath "modal/modal.component.ts"
if (-not $modalFile) {
    $modalFile = Get-ChildItem -Path $ComponentPath -Filter "*modal*.component.ts*" -Recurse | Select-Object -First 1
}

$hasTextTransform = $false
if ($modalFile) {
    $hasTextTransform = Test-FilePattern -FilePath $modalFile -Pattern 'enforceTextTransform\('
}

$typeFile = Find-TargetFile -BasePath $ComponentPath -RelativePath "type/type.ts"
if (-not $typeFile) {
    $typeFile = Get-ChildItem -Path $ComponentPath -Filter "*type.ts*" -Recurse | Select-Object -First 1
}

$hasFormFieldDecorator = $false
if ($typeFile) {
    $hasFormFieldDecorator = Test-FilePattern -FilePath $typeFile -Pattern '@FormField\('
}

if ($modalFile -and -not $hasTextTransform) {
    $gate4Pass = $false
    $violations += "[Gate 4] Modal component fails to invoke 'enforceTextTransform()' for input sanitization."
}
if ($typeFile -and -not $hasFormFieldDecorator) {
    $gate4Pass = $false
    $violations += "[Gate 4] Entity type fails to declare '@FormField()' decorators."
}

if ($gate4Pass) {
    Write-Host " [PASS] Gate 4: Form Sanitization & Transformation (enforceTextTransform & @FormField active)" -ForegroundColor Green
} else {
    Write-Host " [FAIL] Gate 4: Form Sanitization & Transformation" -ForegroundColor Red
    $allPassed = $false
}

# --- GATE 5: OWASP Top 10 Web Client Compliance ---
$gate5Pass = $true
if ($modalFile) {
    $hasServerErrorsHandling = Test-FilePattern -FilePath $modalFile -Pattern 'FormErrorUtil\.(applyServerErrors|showFormErrors)'
    if (-not $hasServerErrorsHandling) {
        $gate5Pass = $false
        $violations += "[Gate 5] Modal component lacks server validation error synchronization (FormErrorUtil)."
    }
}

if ($gate5Pass) {
    Write-Host " [PASS] Gate 5: OWASP Top 10 Web Client (Input integrity & server validation error sync)" -ForegroundColor Green
} else {
    Write-Host " [FAIL] Gate 5: OWASP Top 10 Web Client" -ForegroundColor Red
    $allPassed = $false
}

# --- GATE 6: Ephemeral Test & DoD Cleanup ---
$gate6Pass = $true
# Note: In templates, the test template is present. In a finalized component, any ephemeral test file must be cleaned up.
$leftoverEphemeralTests = Get-ChildItem -Path $ComponentPath -Filter "*_service_test.spec.ts" -Recurse -ErrorAction SilentlyContinue

if ($leftoverEphemeralTests -and $leftoverEphemeralTests.Count -gt 0) {
    # Check if the file is explicitly tagged with EPHEMERAL_TEST_FILE
    foreach ($lt in $leftoverEphemeralTests) {
        $c = Get-Content $lt.FullName -Raw -Encoding UTF8
        if ($c -match "EPHEMERAL_TEST_FILE:\s*True") {
            $gate6Pass = $false
            $violations += "[Gate 6] DoD Violation: Ephemeral test file '$($lt.Name)' still remains and must be deleted."
        }
    }
}

if ($gate6Pass) {
    Write-Host " [PASS] Gate 6: DoD Cleanup (Ephemeral tests properly scoped and lifecycle verified)" -ForegroundColor Green
} else {
    Write-Host " [FAIL] Gate 6: DoD Cleanup (Ephemeral test not deleted)" -ForegroundColor Red
    $allPassed = $false
}

Write-Host "`n--------------------------------------------------------" -ForegroundColor Cyan
if ($allPassed) {
    Write-Host "🎉 COMPLIANCE RESULT: ALL FRONTEND CYBERSECURITY GATES PASSED (6/6)" -ForegroundColor Green
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
