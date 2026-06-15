$ErrorActionPreference = "Stop"

Write-Host "==> Verify workspace"

$commands = @()

if (Test-Path "package.json") {
    $packageJson = Get-Content -Raw -Encoding UTF8 "package.json" | ConvertFrom-Json
    if ($packageJson.scripts.lint) { $commands += @{ Name = "lint"; Command = "npm"; Args = @("run", "lint") } }
    if ($packageJson.scripts.typecheck) { $commands += @{ Name = "typecheck"; Command = "npm"; Args = @("run", "typecheck") } }
    if ($packageJson.scripts.test) { $commands += @{ Name = "test"; Command = "npm"; Args = @("test") } }
}

if ($commands.Count -eq 0) {
    Write-Warning "No verify commands found. Add lint/typecheck/test scripts or customize scripts/verify.ps1."
    exit 0
}

foreach ($entry in $commands) {
    Write-Host "==> $($entry.Name)"
    & $entry.Command @($entry.Args)
}

Write-Host "==> Verify completed"
