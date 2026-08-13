[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z][A-Za-z0-9]*$')]
    [string] $Company,

    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z][A-Za-z0-9]*$')]
    [string] $Service,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputPath
)

$templateRoot = $PSScriptRoot
$targetRoot = [System.IO.Path]::GetFullPath($OutputPath)
$companyLower = $Company.ToLowerInvariant()
$serviceLower = $Service.ToLowerInvariant()

New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null

Get-ChildItem -Path $templateRoot -Recurse -File |
    Where-Object { $_.Name -ne 'render.ps1' } |
    ForEach-Object {
        $relativePath = $_.FullName.Substring($templateRoot.Length).TrimStart('\')
        $relativePath = $relativePath -replace '\.template$', ''
        $relativePath = $relativePath.Replace('{Company}', $Company)
        $relativePath = $relativePath.Replace('{Service}', $Service)
        $relativePath = $relativePath.Replace('{company}', $companyLower)
        $relativePath = $relativePath.Replace('{service}', $serviceLower)

        $destination = Join-Path $targetRoot $relativePath
        $destinationDirectory = Split-Path -Parent $destination
        New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null

        $content = [System.IO.File]::ReadAllText($_.FullName)
        $content = $content.Replace('{Company}', $Company)
        $content = $content.Replace('{Service}', $Service)
        $content = $content.Replace('{company}', $companyLower)
        $content = $content.Replace('{service}', $serviceLower)

        [System.IO.File]::WriteAllText(
            $destination,
            $content,
            [System.Text.UTF8Encoding]::new($false))
    }

Write-Host "Rendered $Company.$Service template to $targetRoot"
