# validate-naming.ps1
# Checks naming conventions in flex-workstation per SPEC.md.
# Run from the repo root: .\scripts\validate-naming.ps1

param(
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$violations = @()

function Test-KebabCase([string]$name) {
    $name -cmatch '^[a-z0-9]+(-[a-z0-9]+)*$'
}

# docs/**/*.md -> kebab-case.md
$docsPath = Join-Path $Root "docs"
if (Test-Path $docsPath) {
    Get-ChildItem -Path $docsPath -Recurse -Filter "*.md" | ForEach-Object {
        $stem = $_.BaseName
        if (-not (Test-KebabCase $stem)) {
            $rel = $_.FullName.Replace($Root + '\', '')
            $violations += "docs: $rel - expected kebab-case.md"
        }
    }
}

# requirements/*/*.md -> kebab-case.md (folder names are numeric IDs, skip them)
$reqPath = Join-Path $Root "requirements"
if (Test-Path $reqPath) {
    Get-ChildItem -Path $reqPath -Recurse -Filter "*.md" | ForEach-Object {
        $stem = $_.BaseName
        if (-not (Test-KebabCase $stem)) {
            $rel = $_.FullName.Replace($Root + '\', '')
            $violations += "requirements: $rel - expected kebab-case.md"
        }
    }
}

# scripts/*.ps1 and *.sh -> kebab-case
$scriptsPath = Join-Path $Root "scripts"
if (Test-Path $scriptsPath) {
    Get-ChildItem -Path $scriptsPath -File |
        Where-Object { $_.Extension -in @('.ps1', '.sh') } |
        ForEach-Object {
            $stem = $_.BaseName
            if (-not (Test-KebabCase $stem)) {
                $violations += "scripts: $($_.Name) - expected kebab-case"
            }
        }
}

# skills/*/ -> folder must be kebab-case and contain SKILL.md
$skillsPath = Join-Path $Root "skills"
if (Test-Path $skillsPath) {
    Get-ChildItem -Path $skillsPath -Directory | ForEach-Object {
        $folderName = $_.Name
        if (-not (Test-KebabCase $folderName)) {
            $violations += "skills: folder '$folderName' - expected kebab-case"
        }
        $skillFile = Join-Path $_.FullName "SKILL.md"
        if (-not (Test-Path $skillFile)) {
            $violations += "skills: $folderName/ - missing SKILL.md"
        }
    }
}

if ($violations.Count -eq 0) {
    Write-Host "OK: No violations found." -ForegroundColor Green
    exit 0
} else {
    Write-Host "FAIL: $($violations.Count) violation(s) found:" -ForegroundColor Red
    foreach ($v in $violations) { Write-Host "  - $v" -ForegroundColor Yellow }
    exit 1
}
