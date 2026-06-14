$raw = [Console]::In.ReadToEnd()
try {
    $json = $raw | ConvertFrom-Json
    $path = $json.tool_input.file_path
    if ($path -and ($path -match '\.(claude|agents)[/\\]skills') -and ($path -notmatch 'flex-workstation')) {
        @{
            continue  = $false
            stopReason = "BLOCKED: Khong sua truc tiep trong .claude\skills\ hoac .agents\skills\ (day la runtime, se bi ghi de khi sync). Sua source tai flex-workstation\.claude\skills\ truoc, sau do chay SYNC_WORKSPACE.cmd."
        } | ConvertTo-Json -Compress | Write-Output
    }
} catch {}
