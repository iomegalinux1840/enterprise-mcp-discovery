# browser_tabs_windows.ps1
# Captures open browser window TITLES on Windows.
#
# Windows has no AppleScript equivalent, and Chrome/Edge/Firefox do not expose
# every tab URL to PowerShell by default. URLs are therefore NOT captured here.
# Capture what is available (window titles), set tabs_urls_unavailable, and ask
# the user to paste the address-bar list or use a "copy all tabs" browser extension.
#
# Usage (Windows PowerShell 5.1 or newer):
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\browser_tabs_windows.ps1 | Out-File -Encoding utf8 tabs.json

$ErrorActionPreference = "SilentlyContinue"

$browsers = @(
    @{ proc = "chrome";   name = "Chrome" },
    @{ proc = "msedge";   name = "Microsoft Edge" },
    @{ proc = "firefox";  name = "Firefox" },
    @{ proc = "brave";    name = "Brave" },
    @{ proc = "opera";    name = "Opera" }
)

$tabs = @()
foreach ($b in $browsers) {
    Get-Process -Name $b.proc |
        Where-Object { $_.MainWindowTitle -and $_.MainWindowTitle.Trim() } |
        ForEach-Object {
            $tabs += [ordered]@{
                browser = $b.name
                title   = $_.MainWindowTitle
                url     = ""
            }
        }
}

$result = [ordered]@{
    browser_tabs          = @($tabs)
    tabs_urls_unavailable = $true
    tabs_note             = "Windows PowerShell cannot enumerate every browser tab URL. Titles only; ask the user to paste address-bar URLs or use a copy-all-tabs browser extension."
}

$result | ConvertTo-Json -Depth 4
