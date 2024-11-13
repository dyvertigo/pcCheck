# Ensure the script is run as Administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

# Initialize the global logEntries array
$global:logEntries = @()

# Function to check administrator privileges
function Check-AdministratorPrivileges {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $global:logEntries += "[-] This script requires administrator privileges to run certain tasks."
        exit
    } else {
        $global:logEntries += "[+] Administrator privileges confirmed."
    }
}

# Function to check Secure Boot status
function Check-SecureBoot {
    try {
        if (Get-Command Confirm-SecureBootUEFI -ErrorAction SilentlyContinue) {
            $secureBootState = Confirm-SecureBootUEFI
            if ($secureBootState) {
                $global:logEntries += "[-] Secure Boot is ON."
            } else {
                $global:logEntries += "[-] Secure Boot is OFF."
            }
        } else {
            $global:logEntries += "[-] Secure Boot not available on this system."
        }
    } catch {
        $global:logEntries += "[-] Unable to retrieve Secure Boot status: $_"
    }
}

# Function to locate OneDrive path
# Function to locate OneDrive path
function Get-OneDrivePath {
    try {
        # Check default OneDrive path in the UserProfile directory
        $envOneDrive = [System.IO.Path]::Combine($env:UserProfile, "OneDrive")
        if (Test-Path $envOneDrive) {
            $oneDrivePath = $envOneDrive
            $global:logEntries += "[-] OneDrive path detected: $oneDrivePath"
        } else {
            $global:logEntries += "[-] Unable to find OneDrive path."
            $oneDrivePath = $null
        }

        return $oneDrivePath
    } catch {
        $global:logEntries += "Unable to find OneDrive path: $_"
        return $null
    }
}


# Additional Feature: Logging Windows Installation Date
function Log-WindowsInstallDate {
    try {
        $os = Get-WmiObject -Class Win32_OperatingSystem
        $installDate = $os.ConvertToDateTime($os.InstallDate)
        $global:logEntries += "Windows Installation Date: $installDate"
    } catch {
        $global:logEntries += "Unable to retrieve Windows installation date: $_"
    }
}

# Additional Feature: Check for Suspicious .exe, .zip, and .rar files
function Find-SusFiles {
    try {
        $global:logEntries += "[-] Searching for suspicious files with 'loader' in the name..."
        $searchPaths = @($env:UserProfile, "$env:UserProfile\Downloads")
        $susFiles = @()

        foreach ($path in $searchPaths) {
            if (Test-Path $path) {
                $files = Get-ChildItem -Path $path -Recurse -Include *.exe, *.zip, *.rar -File
                $susFiles += $files | Where-Object { $_.Name -match "loader" }
            }
        }

        if ($susFiles.Count -gt 0) {
            $global:logEntries += "Found suspicious files:"
            $susFiles | ForEach-Object { $global:logEntries += $_.FullName }
        } else {
            $global:logEntries += "No suspicious files found."
        }
    } catch {
        $global:logEntries += "Error finding suspicious files: $_"
    }
}

# Additional Feature: Fetch and Log BAM State User Settings
function List-BAMStateUserSettings {
    try {
        $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings"
        if (Test-Path $registryPath) {
            $userSettings = Get-ChildItem -Path $registryPath
            $userSettings | ForEach-Object {
                $global:logEntries += $_.Name
            }
        } else {
            $global:logEntries += "No User Settings entries found."
        }
    } catch {
        $global:logEntries += "Error accessing BAM State User Settings: $_"
    }
}

# Additional Feature: Log Prefetch Files
function Log-PrefetchFiles {
    try {
        $prefetchPath = "C:\Windows\Prefetch"
        if (Test-Path $prefetchPath) {
            $pfFiles = Get-ChildItem -Path $prefetchPath -Filter *.pf -File
            if ($pfFiles.Count -gt 0) {
                $global:logEntries += "Prefetch files found:"
                $pfFiles | ForEach-Object {
                    $global:logEntries += "$($_.Name) - Last Modified: $($_.LastWriteTime)"
                }
            } else {
                $global:logEntries += "No Prefetch files found."
            }
        } else {
            $global:logEntries += "Prefetch folder not found."
        }
    } catch {
        $global:logEntries += "Error logging Prefetch files: $_"
    }
}

function Log-FolderNames {
    $userName = $env:UserName
    $oneDrivePath = Get-OneDrivePath
    $potentialPaths = @("C:\Users\$userName\Documents\My Games\Rainbow Six - Siege", "$oneDrivePath\Documents\My Games\Rainbow Six - Siege")
    $allUserNames = @()

    # Check each potential path for user folders
    foreach ($path in $potentialPaths) {
        if (Test-Path -Path $path) {
            $dirNames = Get-ChildItem -Path $path -Directory | ForEach-Object { $_.Name }
            $allUserNames += $dirNames
        }
    }

    # Remove duplicate usernames
    $uniqueUserNames = $allUserNames | Select-Object -Unique

    # If no usernames were found, log a message
    if ($uniqueUserNames.Count -eq 0) {
        $global:logEntries += "`nNo Rainbow Six Siege usernames detected. Skipping Stats.cc search."
        Write-Host "`nNo Rainbow Six Siege usernames detected. Skipping Stats.cc search." -ForegroundColor Yellow
    } else {
        # Log detected usernames
        $global:logEntries += "`nRainbow Six Siege Usernames Detected:"
        $uniqueUserNames | ForEach-Object { $global:logEntries += " - $_" }

        # Log Stats.cc URLs
        $global:logEntries += "`n**Rainbow Six Siege Stats URLs:**"
        foreach ($name in $uniqueUserNames) {
            $url = "https://stats.cc/siege/$name"
            $global:logEntries += " - $url"
        }

        Write-Host "`nStats URLs have been appended to the log." -ForegroundColor Green
    }

    # Debug: Output the entire log for review
    Write-Host "Log entries: $($global:logEntries -join "`n")" -ForegroundColor Cyan
}

# Function to retrieve and send computer/user information
function Send-InitialMessage {
    $computerName = $env:COMPUTERNAME
    $userName = $env:USERNAME
    $discordWebhookUrl = "https://discord.com/api/webhooks/1305253767687573555/qfDWd_Y2rEP5j8cnAHKDA1l__dUNlr1B8VoGVKCFM_MpClE32YOEhxdY_4d66uvRPND1"

    # JSON payload with computer and user info
    $jsonPayload = @{
        content = "System Check initiated on **$computerName** by **$userName**"
    } | ConvertTo-Json

    try {
        # Send the initial message
        Invoke-RestMethod -Uri $discordWebhookUrl -Method Post -ContentType "application/json" -Body $jsonPayload
        Write-Host "Initial message sent to Discord webhook."
    } catch {
        Write-Host "Failed to send initial message to Discord webhook: $_"
    }
}

# Function to send the log file as an attachment to your Discord webhook
function Send-Logs {
    $desktopPath = [System.Environment]::GetFolderPath('Desktop')
    $logFilePath = Join-Path -Path $desktopPath -ChildPath "SystemCheckLogs.txt"
    $discordWebhookUrl = "https://discord.com/api/webhooks/1305253767687573555/qfDWd_Y2rEP5j8cnAHKDA1l__dUNlr1B8VoGVKCFM_MpClE32YOEhxdY_4d66uvRPND1"

    # Confirm the log file path
    Write-Host "Log file path: $logFilePath"

    # Check if the log file exists
    if (Test-Path $logFilePath) {
        # Prepare the multipart/form-data request body for file upload
        $boundary = [System.Guid]::NewGuid().ToString()
        $LF = "`r`n"  # Line feed
        $fileContent = Get-Content -Path $logFilePath -Raw  # Read the entire file as raw text

        # Build the multipart body
        $bodyLines = (
        "--$boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"SystemCheckLogs.txt`"",
        "Content-Type: text/plain$LF",
        $fileContent,
        "--$boundary--$LF"
        ) -join $LF

        # Send the log file as an attachment
        try {
            $response = Invoke-RestMethod -Uri $discordWebhookUrl -Method Post -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $bodyLines
            Write-Host "Log file successfully sent to the Discord webhook."
        } catch {
            Write-Host "Failed to send log file to Discord webhook: $_"
        }
    } else {
        Write-Host "Log file not found on the desktop."
    }
}

# Final Function to Execute All Checks
function RunSystemCheck {
    # Send initial message with computer and user info
    Send-InitialMessage

    # Run all checks and add logs
    Check-AdministratorPrivileges
    Check-SecureBoot
    Log-WindowsInstallDate
    Log-FolderNames
    Find-SusFiles
    List-BAMStateUserSettings
    Log-PrefetchFiles

    # Save logs to file
    $desktopPath = [System.Environment]::GetFolderPath('Desktop')
    $logFilePath = Join-Path -Path $desktopPath -ChildPath "SystemCheckLogs.txt"
    try {
        $global:logEntries | Out-File -FilePath $logFilePath -Encoding UTF8
        Write-Host "Log file created at $logFilePath"
    } catch {
        Write-Host "Failed to write logs to file: $_"
    }

    # Copy file path to clipboard for easy access
    if (Test-Path $logFilePath) {
        try {
            Set-Clipboard -Path $logFilePath
            Write-Host "Log file path copied to clipboard."
        } catch {
            Write-Host "Failed to copy log file path to clipboard."
        }
    }

    # Send logs via Discord webhook
    Send-Logs
}

# Run the script
RunSystemCheck
