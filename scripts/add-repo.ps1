param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Url,
    [string]$Branch,
    [string]$Scope,
    [string]$Root = (Resolve-Path "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Stop"

if ($Name.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0) {
    throw "Invalid folder name: $Name"
}
if ($Url -match '://[^/@]*:[^/@]*@') {
    throw "Url must not embed credentials."
}

# The sync script compares the manifest url to `origin` literally; a mismatch skips the pull.
$origin = $null
$repoPath = Join-Path $Root $Name
if (Test-Path (Join-Path $repoPath ".git")) {
    $origin = (& git -C $repoPath remote get-url origin 2>$null)
    if ($origin -and $origin -ne $Url) {
        throw "Url differs from local origin. Use: $origin"
    }
}

$manifestPath = Join-Path $Root "workstation.json"
$manifest = [System.IO.File]::ReadAllText($manifestPath)
$eol = if ($manifest.Contains("`r`n")) { "`r`n" } else { "`n" }
$existing = @(($manifest | ConvertFrom-Json).repositories.items) | Where-Object { $_.name -eq $Name }

if ($existing) {
    if ($existing.url -eq $Url) {
        Write-Host "[SKIP] workstation.json already lists $Name with this url."
    }
    elseif ($origin -eq $Url) {
        # Only repair a url when the local origin proves which form is right.
        $pattern = '("name"\s*:\s*"' + [regex]::Escape($Name) + '"\s*,\s*"url"\s*:\s*")[^"]*(")'
        $fixed = [regex]::Replace($manifest, $pattern, { param($m) $m.Groups[1].Value + $Url + $m.Groups[2].Value })
        $null = $fixed | ConvertFrom-Json
        [System.IO.File]::WriteAllText($manifestPath, $fixed)
        Write-Host "[FIX] workstation.json url for $Name changed from $($existing.url) to $Url."
    }
    else {
        throw "$Name is already in workstation.json with a different url ($($existing.url)) and no local origin confirms $Url."
    }
    if ($Branch) { Write-Warning "-Branch ignored: $Name already exists in workstation.json." }
    if ($Scope) {
        if (-not $existing.scope) {
            # Add scope right after the entry's url/branch line, as raw text.
            $manifest = [System.IO.File]::ReadAllText($manifestPath)
            $pattern = '("name"\s*:\s*"' + [regex]::Escape($Name) + '"\s*,\s*"url"\s*:\s*"[^"]*"(?:\s*,\s*"branch"\s*:\s*"[^"]*")?)'
            $withScope = [regex]::Replace($manifest, $pattern, { param($m) $m.Groups[1].Value + ",$eol        `"scope`": " + ($Scope | ConvertTo-Json -Compress) })
            $null = $withScope | ConvertFrom-Json
            [System.IO.File]::WriteAllText($manifestPath, $withScope)
            Write-Host "[OK] workstation.json: added scope for $Name."
        }
        elseif ($existing.scope -ne $Scope) {
            Write-Warning "-Scope ignored: $Name already has a scope in workstation.json."
        }
    }
    else {
        if (-not $existing.scope) { Write-Warning "$Name has no scope in workstation.json; pass -Scope so flex-repo-scope can route to it." }
    }
}
else {
    $lines = @("      {", "        `"name`": `"$Name`",")
    if ($Branch) {
        $lines += "        `"url`": `"$Url`","
        $lines += "        `"branch`": `"$Branch`""
    }
    else {
        $lines += "        `"url`": `"$Url`""
    }
    if ($Scope) {
        $lines[-1] += ","
        $lines += "        `"scope`": $($Scope | ConvertTo-Json -Compress)"
    }
    else {
        Write-Warning "$Name has no scope; pass -Scope so flex-repo-scope can route to it."
    }
    $lines += "      }"
    $entry = $lines -join $eol
    $closing = "$eol    ]"
    $idx = $manifest.LastIndexOf($closing)
    if ($idx -lt 0) { throw "Unexpected workstation.json layout: cannot find end of repositories.items." }
    $updated = $manifest.Substring(0, $idx) + ",$eol$entry" + $manifest.Substring($idx)
    $null = $updated | ConvertFrom-Json  # fail before writing if the result is not valid JSON
    [System.IO.File]::WriteAllText($manifestPath, $updated)
    Write-Host "[OK] workstation.json: added $Name."
}

# Edit as raw text so line endings and untouched entries stay byte-identical. Re-runnable: skips a line already present.
function Add-LineIfMissing {
    param([string]$File, [string]$Line)
    $path = Join-Path $Root $File
    $text = [System.IO.File]::ReadAllText($path)
    if ($text -split "\r?\n" | Where-Object { $_.Trim() -eq $Line }) {
        Write-Host "[SKIP] $File already contains $Line"
        return
    }
    $eol = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
    if (-not $text.EndsWith($eol)) { $text += $eol }
    [System.IO.File]::WriteAllText($path, $text + $Line + $eol)
    Write-Host "[OK] ${File}: added $Line"
}

Add-LineIfMissing ".gitignore" "/$Name/"
Add-LineIfMissing ".ignore" "!/$Name/"

Write-Host "Still manual: docs/architecture/system-map.md (tree section 2, manifest section 3, projects section 4)."
