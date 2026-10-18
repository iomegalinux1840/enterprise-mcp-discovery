# inventory_windows.ps1
# Read-only inventory: running windowed apps, installed apps, mapped network
# drives, and the active File Explorer window (the user's open shared folder).
#
# Usage (Windows PowerShell 5.1 or newer):
#   powershell -NoProfile -File scripts\inventory_windows.ps1 | Out-File -Encoding utf8 inventory_raw.json

$ErrorActionPreference = "Continue"
$Error.Clear()

function Get-RunningGuiApps {
    $names = Get-Process |
        Where-Object { $_.MainWindowTitle -and $_.MainWindowTitle.Trim() } |
        Select-Object -ExpandProperty ProcessName -Unique
    $names | Sort-Object | ForEach-Object {
        [ordered]@{ name = $_ }
    }
}

function Get-InstalledApps {
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $names = foreach ($p in $paths) {
        Get-ItemProperty $p | Where-Object { $_.DisplayName } |
            Select-Object -ExpandProperty DisplayName
    }
    $names | Sort-Object -Unique
}

function Get-MappedShares {
    Get-CimInstance Win32_LogicalDisk -Filter "DriveType=4" |
        Where-Object { $_.ProviderName } |
        ForEach-Object {
            [ordered]@{
                device      = $_.ProviderName
                mount_point = $_.DeviceID
                fs_type     = "smbfs"
            }
        }
}

function Get-ActiveExplorerTarget {
    try {
        $shell = New-Object -ComObject Shell.Application
        $paths = @()
        foreach ($w in $shell.Windows()) {
            try {
                if ($w.FullName -match "explorer\.exe$") {
                    $p = $w.Document.Folder.Self.Path
                    if ($p) { $paths += $p }
                }
            } catch {}
        }
        return @($paths)
    } catch {}
    return @()
}

$openFolders = @(Get-ActiveExplorerTarget)
$folderCandidates = @()
$commonPaths = @([Environment]::GetFolderPath("MyDocuments"), [Environment]::GetFolderPath("Desktop"), $env:OneDrive, $env:OneDriveCommercial, $env:OneDriveConsumer, (Join-Path $env:USERPROFILE "Dropbox"))
foreach ($p in @($openFolders) + @($commonPaths)) {
    if ($p -and (Test-Path -LiteralPath $p -PathType Container)) {
        $folderCandidates += [ordered]@{ path = $p; evidence = "open_or_common_location"; confirmed = $false }
    }
}
$runningApps = @(Get-RunningGuiApps)
$installedApps = @(Get-InstalledApps)
$mappedShares = @(Get-MappedShares)
$result = [ordered]@{
    running_apps   = $runningApps
    installed_apps = $installedApps
    browser_tabs   = @()
    mounted_shares = $mappedShares
    finder_target  = if ($openFolders.Count) { $openFolders[0] } else { "" }
    open_folders = $openFolders
    folder_candidates = $folderCandidates
    collection_errors = @($Error | ForEach-Object { [ordered]@{ source = "windows_inventory"; error = $_.Exception.GetType().Name } })
    collected_at   = (Get-Date).ToUniversalTime().ToString("o")
    host           = $env:COMPUTERNAME
}

$result | ConvertTo-Json -Depth 6
