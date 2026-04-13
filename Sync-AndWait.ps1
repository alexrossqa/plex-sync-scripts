[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$WatchFolder,

    [Parameter(Mandatory=$false)]
    [int]$StabilityWindowSeconds = 60,

    [Parameter(Mandatory=$false)]
    [int]$PollIntervalSeconds = 15,

    [Parameter(Mandatory=$false)]
    [int]$TimeoutMinutes = 120,

    [Parameter(Mandatory=$false)]
    [string]$LogDir = "C:\Logs\PlexSync"
)

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
$ErrorActionPreference = "Stop"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile   = Join-Path $LogDir "Sync-AndWait_$timestamp.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $entry = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Write-Output $entry
    Add-Content -Path $logFile -Value $entry
}

function Get-FolderSnapshot {
    param([string]$Folder)
    [System.IO.Directory]::EnumerateFiles($Folder, '*', [System.IO.SearchOption]::AllDirectories) |
        Measure-Object | Select-Object -ExpandProperty Count
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
try {
    Write-Log "=== Sync-AndWait started ==="
    Write-Log "Watching  : $WatchFolder"
    Write-Log "Stability : $StabilityWindowSeconds seconds of no change required"
    Write-Log "Timeout   : $TimeoutMinutes minutes"

    $deadline    = (Get-Date).AddMinutes($TimeoutMinutes)
    $stablesince = $null
    $lastCount   = -1

    while ((Get-Date) -lt $deadline) {
        $currentCount = Get-FolderSnapshot -Folder $WatchFolder

        if ($currentCount -ne $lastCount) {
            Write-Log "File count changed: $lastCount --> $currentCount. Resetting stability window."
            $lastCount   = $currentCount
            $stablesince = Get-Date
        } else {
            $stableSecs = ((Get-Date) - $stablesince).TotalSeconds
            Write-Log "File count stable at $currentCount for $([math]::Round($stableSecs, 0))s / ${StabilityWindowSeconds}s required."

            if ($stableSecs -ge $StabilityWindowSeconds) {
                Write-Log "Folder stable. Proceeding."
                exit 0
            }
        }

        Start-Sleep -Seconds $PollIntervalSeconds
    }

    Write-Log "TIMEOUT: Folder did not stabilise within $TimeoutMinutes minutes." "ERROR"
    exit 1

} catch {
    Write-Log "FATAL: $_" "ERROR"
    exit 1
}