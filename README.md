**plex-sync-scripts**

**What does it do?**

Synchronises the file libraries of two Plex media servers via Google Drive, ensuring both locations remain up to date with any newly added or missing content.

**Why does it exist?**

This may not be a common need, but I travel frequently between two domestic locations for extended periods, and am often at neither. This pipeline ensures:

1. Full and up-to-date access to a Plex server regardless of location
2. Remote access to an up-to-date server in case one location is inaccessible due to a PC or network outage
3. A rigorous circular backup process, with two physical locations and cloud storage
4. Resilience against bandwidth limitations that may affect remote streaming

**How does it work?**

Location A stores its media library on a local HDD. The file system is synced into Google Drive using uploadToGDrive.ps1, which checks for any folders or files present locally but missing 
from the remote Google Drive location, and copies them across.

Location B stores its media on a local HDD and has access to the same Google Drive account. Once the upload has completed, downloadToHdd.ps1 checks for any folders or files present on Google Drive 
but missing locally, and copies them down.

Both scripts follow the same two-pass approach (directories first, then files) to ensure the folder structure exists before any files are written into it.

A polling script, Sync-AndWait.ps1, sits between the two operations. Rather than using a fixed wait time, it monitors the target folder and only proceeds once the file count has been stable for a 
defined period, ensuring the sync is genuinely complete before the next operation begins.

**Scripts**
| Script | Purpose |
|---|---|
| `uploadToGDrive.ps1` | Syncs local HDD → Google Drive |
| `downloadToHdd.ps1` | Syncs Google Drive → local HDD |
| `Sync-AndWait.ps1` | Polls a folder until file count stabilises |

**Prerequisites**

- Two machines, each running a Plex Media Server (or even just with storage, this would work as a backup solution without Plex)
- Google Drive (or any cloud storage that exposes a mapped drive with a defined path structure)
- PowerShell 5.1 or later
- Both HDD libraries sharing an identical root folder name

**Parameters**

Each script accepts the following parameters, with sensible defaults:

uploadToGDrive.ps1 / downloadToHdd.ps1

| Parameter | Description | Default |
|---|---|---|
| `-SourceFolder` | Path to copy from | Hardcoded per script |
| `-DestFolder` | Path to copy to | Hardcoded per script |
| `-LogDir` | Directory for log output | `C:\Jenkins\Logs\PlexSync` |

Sync-AndWait.ps1

| Parameter | Description | Default |
|---|---|---|
| `-WatchFolder` | Folder to monitor | Required |
| `-StabilityWindowSeconds` | Seconds of stability required | `60` |
| `-PollIntervalSeconds` | How often to check | `15` |
| `-TimeoutMinutes` | Maximum wait before failing | `120` |
| `-LogDir` | Directory for log output | `C:\Jenkins\Logs\PlexSync` |

**Usage**

These scripts are designed to be run as part of the plex-pipeline Jenkins pipeline, but can also be run manually:

```powershell
.\uploadToGDrive.ps1 -SourceFolder "E:\#FILMS\" -DestFolder "G:\Other computers\MINI\#FILMS\" -LogDir "C:\Logs"

.\Sync-AndWait.ps1 -WatchFolder "G:\Other computers\MINI\#FILMS\" -StabilityWindowSeconds 60 -TimeoutMinutes 180

.\downloadToHdd.ps1 -SourceFolder "G:\Other computers\MINI\#FILMS\" -DestFolder "E:\#FILMS\" -LogDir "C:\Logs"
```
