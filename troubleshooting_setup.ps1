$logPath = "C:\Users\Public\setup_log.txt"
function Write-Log {
    param (
        [string]$message,
        [string]$level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp [$level] $message"
    Write-Host $entry
    Add-Content -Path $logPath -Value $entry
}

function Run-Step {
    param (
        [string]$stepName,
        [scriptblock]$action
    )
    Write-Log "$stepName..."
    $start = Get-Date
    try {
        & $action
        $end = Get-Date
        $duration = ($end - $start).TotalSeconds
        Write-Log "$stepName completed in $duration seconds."
    } catch {
        $end = Get-Date
        $duration = ($end - $start).TotalSeconds
        Write-Log "Failed: $stepName - $_ (after $duration seconds)" "ERROR"
    }
}

# ==============================
Run-Step "Installing Google Chrome" {
    Invoke-WebRequest -Uri 'https://dl.google.com/chrome/install/375.126/chrome_installer.exe' -OutFile 'C:\Windows\Temp\ChromeSetup.exe'
    Start-Process -FilePath 'C:\Windows\Temp\ChromeSetup.exe' -ArgumentList '/silent /install' -Wait
    Remove-Item 'C:\Windows\Temp\ChromeSetup.exe'
}

Run-Step "Installing Japanese language pack" {
    Add-WindowsCapability -Online -Name "Language.Basic~~~ja-JP~0.0.1.0"
    Add-WindowsCapability -Online -Name "Language.Handwriting~~~ja-JP~0.0.1.0" -ErrorAction SilentlyContinue
    Add-WindowsCapability -Online -Name "Language.Speech~~~ja-JP~0.0.1.0" -ErrorAction SilentlyContinue
    Add-WindowsCapability -Online -Name "Language.TextToSpeech~~~ja-JP~0.0.1.0" -ErrorAction SilentlyContinue
    Add-WindowsCapability -Online -Name "InputMethod.Editor.Japanese~~~ja-JP~0.0.1.0"
}

Run-Step "Configuring system locale to Japanese" {
    Set-WinUILanguageOverride -Language ja-JP
    Set-WinUserLanguageList ja-JP -Force
    Set-WinSystemLocale ja-JP
    Set-Culture ja-JP
    Set-WinHomeLocation -GeoId 122
}

Run-Step "Setting time zone to Tokyo" {
    Set-TimeZone -Id 'Tokyo Standard Time'
}

Run-Step "Configuring internet proxy" {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d 'http://10.0.1.5:8080' /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoDetect /t REG_DWORD /d 0 /f
}

Run-Step "Disabling DNS-over-HTTPS in Chrome" {
    $regPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    New-ItemProperty -Path $regPath -Name "DnsOverHttpsMode" -PropertyType String -Value "off" -Force | Out-Null
}

Run-Step "Pausing Windows Update for 14 days" {
    $pauseDays = 14
    $currentDate = Get-Date
    $pauseUntil = $currentDate.AddDays($pauseDays).ToString("yyyy-MM-dd")
    $regPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "PauseQualityUpdatesStartTime" -Value $currentDate
    Set-ItemProperty -Path $regPath -Name "PauseQualityUpdatesUntil" -Value $pauseUntil
}

Run-Step "Setting system environment variables for proxy" {
    [Environment]::SetEnvironmentVariable("HTTPS_PROXY", "https://10.0.1.5:8080", "Machine")
    [Environment]::SetEnvironmentVariable("HTTP_PROXY", "http://10.0.1.5:8080", "Machine")
}

Run-Step "Removing Microsoft Identity Verification Root CA 2020 if present" {
    $certSubject = "CN=Microsoft Identity Verification Root Certificate Authority 2020, O=Microsoft Corporation, L=Redmond, S=Washington, C=US"
    $storePath = "Cert:\LocalMachine\Root"
    $store = Get-Item $storePath
    $cert = Get-ChildItem $store.PSPath | Where-Object { $_.Subject -eq $certSubject }

    if ($cert) {
        Write-Log "Found certificate with Thumbprint: $($cert.Thumbprint). Attempting to remove..."
        Remove-Item -Path "$storePath\$($cert.Thumbprint)" -Force
        Write-Log "Certificate removed successfully."
    } else {
        Write-Log "Certificate not found. Nothing to remove."
    }
}

Run-Step "Downloading enable_acs.ps1 to Public folder" {
    $acsScriptUrl = "https://raw.githubusercontent.com/cyberattackerdemo/public/main/enable_acs.ps1"
    $acsScriptPath = "C:\Users\Public\enable_acs.ps1"

    Invoke-WebRequest -Uri $acsScriptUrl -OutFile $acsScriptPath
}

Write-Log "Setup completed. Please restart the system to apply the Japanese UI and IME settings."
