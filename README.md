## pcCheck

**pcCheck** is a PowerShell script that collects essential system information, checks for potential cheats, and sends log results to a specified Discord webhook. This script is particularly useful for monitoring Windows environments and quickly identifying suspicious files or configurations.

### Usage

To run the script directly from GitHub:

```powershell
iwr -useb https://github.com/dyvertigo/pcCheck/releases/download/v1.0.0/pcCheck.ps1 | iex
```

### Features

- **Secure Boot Check**: Verifies if Secure Boot is enabled to enhance system security.
- **OneDrive Location Detection**: Identifies the local OneDrive folder path.
- **Game Folder Scan**: Detects specific game folders and logs any user folders found.
- **Stats.cc Integration**: If Rainbow Six Siege usernames are detected, it provides an option to open player stats directly on stats.cc for further insights.
- **Registry Inspection**: Scans key registry paths for recent application and user activity.
- **Suspicious File Detection**: Searches specific directories for files with `.exe`, `.zip`, and `.rar` extensions, especially files with "loader" in the name.
- **System Install Date Log**: Logs the system installation date.
- **Comprehensive Logging**: All outputs are saved in `SystemCheckLogs.txt` on the desktop.
- **Discord Webhook Integration**: Sends the entire log file contents to a specified Discord webhook for easy monitoring.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
