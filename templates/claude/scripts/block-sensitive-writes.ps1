$raw = [Console]::In.ReadToEnd()

try {
    $json = $raw | ConvertFrom-Json
    $path = $json.tool_input.file_path

    if (-not $path) {
        return
    }

    $blockedPatterns = @(
        '\.claude[/\\](skills|agents|commands)',
        '\.env($|\.)',
        '(^|[/\\])secrets?([/\\]|$)'
    )

    foreach ($pattern in $blockedPatterns) {
        if ($path -match $pattern) {
            @{
                continue = $false
                stopReason = "BLOCKED: Do not edit generated or sensitive path directly: $path"
            } | ConvertTo-Json -Compress | Write-Output
            return
        }
    }
}
catch {
    return
}
