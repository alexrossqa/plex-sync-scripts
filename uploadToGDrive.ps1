[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$SourceFolder = "E:\#FILMS\",

    [Parameter(Mandatory=$false)]
    [string]$DestFolder = "G:\Other computers\MINI\#FILMS\",

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

$timestamp      = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile        = Join-Path $LogDir "uploadToGDrive_$timestamp.log"
$missingDirFile = Join-Path $LogDir "dirsMissingOnGDrive_$timestamp.txt"
$missingFileFile= Join-Path $LogDir "notInGoogleDrive_$timestamp.txt"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $entry = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Write-Output $entry
    Add-Content -Path $logFile -Value $entry
}

# ---------------------------------------------------------------------------
# Path length trimming helpers
# ---------------------------------------------------------------------------
$srcLen  = $SourceFolder.Length
$destLen = $DestFolder.Length

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
try {
    Write-Log "=== uploadToGDrive started ==="
    Write-Log "Source : $SourceFolder"
    Write-Log "Dest   : $DestFolder"

    # -- Directories ---------------------------------------------------------
    Write-Log "Scanning directories..."

    $srcDirs  = [System.IO.Directory]::EnumerateDirectories($SourceFolder, '*', [System.IO.SearchOption]::AllDirectories) |
                    ForEach-Object { $_.Substring($srcLen) }

    $destDirs = [System.IO.Directory]::EnumerateDirectories($DestFolder, '*', [System.IO.SearchOption]::AllDirectories) |
                    ForEach-Object { $_.Substring($destLen) }

    $missingDirs = Compare-Object -ReferenceObject $srcDirs -DifferenceObject $destDirs |
                       Where-Object { $_.SideIndicator -eq '<=' } |
                       Select-Object -ExpandProperty InputObject

    $missingDirs | Out-File -FilePath $missingDirFile -Encoding utf8

    if ($missingDirs) {
        Write-Log "Creating $($missingDirs.Count) missing director(ies)..."
        foreach ($dir in $missingDirs) {
            $targetPath = Join-Path $DestFolder $dir
            New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
            Write-Log "  [DIR] $targetPath"
        }
    } else {
        Write-Log "No missing directories."
    }

    # -- Files ---------------------------------------------------------------
    Write-Log "Scanning files..."

    $srcFiles  = [System.IO.Directory]::EnumerateFiles($SourceFolder, '*', [System.IO.SearchOption]::AllDirectories) |
                 Where-Object { $_ -notlike '*.ini' } |
                 ForEach-Object { $_.Substring($srcLen) }

	$destFiles = [System.IO.Directory]::EnumerateFiles($DestFolder, '*', [System.IO.SearchOption]::AllDirectories) |
                 Where-Object { $_ -notlike '*.ini' } |
                 ForEach-Object { $_.Substring($destLen) }

    $missingFiles = Compare-Object -ReferenceObject $srcFiles -DifferenceObject $destFiles |
                        Where-Object { $_.SideIndicator -eq '<=' } |
                        Select-Object -ExpandProperty InputObject

    $missingFiles | Out-File -FilePath $missingFileFile -Encoding utf8

    if ($missingFiles) {
        Write-Log "Copying $($missingFiles.Count) missing file(s)..."
        foreach ($item in $missingFiles) {
            $copyFrom = Join-Path $SourceFolder $item
            $copyTo   = Join-Path $DestFolder   $item
            Write-Log "  [COPY] $copyFrom --> $copyTo"
            Copy-Item -LiteralPath $copyFrom -Destination $copyTo -Recurse -Force
        }
    } else {
        Write-Log "No missing files."
    }

    Write-Log "=== uploadToGDrive completed successfully ==="
    exit 0

} catch {
    Write-Log "FATAL: $_" "ERROR"
    exit 1
}
