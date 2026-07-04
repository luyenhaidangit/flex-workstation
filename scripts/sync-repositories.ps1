param(
    [switch]$PullExisting
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Test-Command {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Resolve-WorkspacePath {
    param(
        [string]$BasePath,
        [string]$Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $BasePath $Path))
}

function Update-Repository {
    param(
        [string]$Name,
        [string]$TargetPath,
        [string]$ExpectedBranch
    )

    $status = (& git -C $TargetPath status --porcelain)
    if ($status) {
        Write-Warn "$Name has local changes - skipping pull: $TargetPath"
        return
    }

    $currentBranch = (& git -C $TargetPath rev-parse --abbrev-ref HEAD 2>$null | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace($currentBranch) -or $currentBranch -eq "HEAD") {
        Write-Warn "$Name is not on a branch - skipping pull: $TargetPath"
        return
    }

    if (-not [string]::IsNullOrWhiteSpace($ExpectedBranch) -and $currentBranch -ne $ExpectedBranch) {
        Write-Warn "$Name is on branch '$currentBranch' but workstation config expects '$ExpectedBranch'. Pulling current branch."
    }

    Write-Host "Fetching $Name..."
    & git -C $TargetPath fetch --prune origin
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "$Name fetch failed."
        return
    }

    Write-Host "Pulling $Name..."
    & git -C $TargetPath pull --ff-only origin $currentBranch
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "$Name updated: $TargetPath"
    }
    else {
        Write-Warn "$Name pull failed. Resolve branch divergence or conflicts manually: $TargetPath"
    }
}

function Sync-DeclaredRepositories {
    $projectRoot = (Resolve-Path "$PSScriptRoot\..").Path
    $workstationConfigPath = Join-Path $projectRoot "workstation.json"

    Write-Step "Syncing declared Git repositories"

    if (-not (Test-Path $workstationConfigPath)) {
        Write-Warn "Workstation config not found: $workstationConfigPath"
        return
    }

    if (-not (Test-Command "git")) {
        Write-Warn "Git is missing - skipping repository sync."
        return
    }

    try {
        $config = Get-Content -Raw -Encoding UTF8 $workstationConfigPath | ConvertFrom-Json
    }
    catch {
        Write-Warn "Workstation config is not valid JSON: $workstationConfigPath"
        Write-Warn $_.Exception.Message
        return
    }

    if (-not $config.repositories -or -not $config.repositories.items) {
        Write-Warn "Workstation config has no repositories.items: $workstationConfigPath"
        return
    }

    $destinationRootValue = if ($config.repositories.destinationRoot) { [string]$config.repositories.destinationRoot } else { "." }
    $destinationRoot = Resolve-WorkspacePath -BasePath $projectRoot -Path $destinationRootValue
    New-Item -ItemType Directory -Force -Path $destinationRoot | Out-Null

    foreach ($repo in $config.repositories.items) {
        $name = [string]$repo.name
        $url = [string]$repo.url
        $branch = [string]$repo.branch

        if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($url)) {
            Write-Warn "Skipping repository entry because name or url is missing."
            continue
        }

        if ($name.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0) {
            Write-Warn "Skipping repository with invalid local folder name: $name"
            continue
        }

        $targetPath = Join-Path $destinationRoot $name
        $targetGitPath = Join-Path $targetPath ".git"

        if (Test-Path $targetGitPath) {
            $originUrl = $null
            try {
                $originUrl = (& git -C $targetPath remote get-url origin 2>$null)
            }
            catch {
                $originUrl = $null
            }

            if ($originUrl -and ($originUrl -ne $url)) {
                Write-Warn "$name already exists but origin differs. Config: $url; local: $originUrl"
                continue
            }

            if ($PullExisting) {
                Update-Repository -Name $name -TargetPath $targetPath -ExpectedBranch $branch
            }
            else {
                Write-Ok "$name already exists: $targetPath"
            }

            continue
        }

        if (Test-Path $targetPath) {
            Write-Warn "$name target path exists but is not a Git repository: $targetPath"
            continue
        }

        Write-Host "Cloning $name..."
        $cloneArgs = @("clone", $url, $targetPath)
        if (-not [string]::IsNullOrWhiteSpace($branch)) {
            $cloneArgs = @("clone", "--branch", $branch, $url, $targetPath)
        }

        & git @cloneArgs

        if ($LASTEXITCODE -eq 0) {
            Write-Ok "$name cloned: $targetPath"
        }
        else {
            Write-Warn "$name clone failed with exit code $LASTEXITCODE"
        }
    }
}

Sync-DeclaredRepositories
