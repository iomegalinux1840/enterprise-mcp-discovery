# inventory_windows.ps1
# Read-only inventory: running windowed apps, installed apps, mapped network
# drives, and the active File Explorer window (the user's open shared folder).
#
# Usage (Windows PowerShell 5.1 or newer):
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\inventory_windows.ps1 | Out-File -Encoding utf8 inventory_raw.json

$ErrorActionPreference = "SilentlyContinue"

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
        if ($paths) { return $paths[-1] }
    } catch {}
    return ""
}

$result = [ordered]@{
    running_apps   = @(Get-RunningGuiApps)
    installed_apps = @(Get-InstalledApps)
    browser_tabs   = @()
    mounted_shares = @(Get-MappedShares)
    finder_target  = Get-ActiveExplorerTarget
    collected_at   = (Get-Date).ToUniversalTime().ToString("o")
    host           = $env:COMPUTERNAME
}

$result | ConvertTo-Json -Depth 6
