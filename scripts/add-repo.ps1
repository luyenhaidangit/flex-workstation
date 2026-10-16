param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Url,
    [string]$Root = (Resolve-Path "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Stop"

if ($Name.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0) {
    throw "Invalid folder name: $Name"
}
if ($Url -match '://[^/]*@') {
    throw "Url must not embed credentials."
}

$manifestPath = Join-Path $Root "workstation.json"
$manifest = Get-Content -Raw -Encoding UTF8 $manifestPath
if (($manifest | ConvertFrom-Json).repositories.items.name -contains $Name) {
    throw "$Name is already in workstation.json."
}

# The sync script compares the manifest url to `origin` literally; a mismatch skips the pull.
$repoPath = Join-Path $Root $Name
if (Test-Path (Join-Path $repoPath ".git")) {
    $origin = (& git -C $repoPath remote get-url origin 2>$null)
    if ($origin -and $origin -ne $Url) {
        throw "Url differs from local origin. Use: $origin"
    }
}

# Edit as raw text so line endings and untouched entries stay byte-identical.
function Add-AfterLastLine {
    param([string]$File, [string]$Line)
    $path = Join-Path $Root $File
    $text = [System.IO.File]::ReadAllText($path)
    $eol = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
    if (-not $text.EndsWith($eol)) { $text += $eol }
    [System.IO.File]::WriteAllText($path, $text + $Line + $eol)
}

$eol = if ($manifest.Contains("`r`n")) { "`r`n" } else { "`n" }
$entry = @("      {", "        `"name`": `"$Name`",", "        `"url`": `"$Url`"", "      }") -join $eol
$closing = "$eol    ]"
$idx = $manifest.LastIndexOf($closing)
if ($idx -lt 0) { throw "Unexpected workstation.json layout: cannot find end of repositories.items." }
$updated = $manifest.Substring(0, $idx) + ",$eol$entry" + $manifest.Substring($idx)
$null = $updated | ConvertFrom-Json  # fail before writing if the result is not valid JSON
[System.IO.File]::WriteAllText($manifestPath, $updated)

Add-AfterLastLine ".gitignore" "/$Name/"
Add-AfterLastLine ".ignore" "!/$Name/"

Write-Host "[OK] Registered $Name in workstation.json, .gitignore, .ignore."
Write-Host "Still manual: docs/architecture/system-map.md (tree section 2, manifest section 3, projects section 4)."
