$logPath = "C:\Users\Public\setup_log.txt"

function Write-Log {
    param (
        [string]$message,
        [string]$level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp [$level] $message"

    # 色分け表示
    switch ($level) {
        "INFO"  { Write-Host $entry -ForegroundColor White }
        "ERROR" { Write-Host $entry -ForegroundColor Red }
        default { Write-Host $entry -ForegroundColor White }
    }

    Add-Content -Path $logPath -Value $entry
}

function Run-Step {
    param (
        [string]$stepName,
        [scriptblock]$action
    )
    Write-Log "=== $stepName ==="
    $start = Get-Date
    try {
        $output = & $action 2>&1
        $end = Get-Date
        $duration = ($end - $start).TotalSeconds
        Write-Log "$stepName completed in $duration seconds. ✅ SUCCESS"
        if ($output) {
            Write-Log "Output:`n$output"
        } else {
            Write-Log "No output."
        }
    } catch {
        $end = Get-Date
        $duration = ($end - $start).TotalSeconds
        Write-Log "Failed: $stepName - $_ (after $duration seconds) ❌ FAILED" "ERROR"
    }
}

Write-Log "===== Setup started ====="

# ========== Install Google Chrome ==========
Run-Step "Downloading and Installing Google Chrome" {
    Invoke-WebRequest -Uri 'https://dl.google.com/chrome/install/375.126/chrome_installer.exe' -OutFile 'C:\Windows\Temp\ChromeSetup.exe'
    Start-Process -FilePath 'C:\Windows\Temp\ChromeSetup.exe' -ArgumentList '/silent /install' -Wait
    Remove-Item 'C:\Windows\Temp\ChromeSetup.exe'
}

# ========== Install Wireshark ==========
Run-Step "Installing Wireshark" {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $url = 'https://2.na.dl.wireshark.org/win64/Wireshark-4.4.7-x64.exe'
    $installerPath = 'C:\Users\Public\Wireshark-Installer.exe'
    Start-BitsTransfer -Source $url -Destination $installerPath
    Start-Process -FilePath $installerPath -ArgumentList "/S /quicklaunch=yes /desktopicon=yes" -Wait -ErrorAction Stop
    Remove-Item 'C:\Users\Public\Wireshark-Installer.exe'
}

# ========== Set Time Zone ==========
Run-Step "Setting time zone to Tokyo" {
    Set-TimeZone -Id 'Tokyo Standard Time'
}

# ========== Pause Windows Update for 14 days (modern method) ==========
Run-Step "Pausing Windows Update for 14 days (WindowsUpdateProvider)" {
    try {
        Import-Module WindowsUpdateProvider -ErrorAction Stop
        $pauseDays = 14
        $pauseUntil = (Get-Date).AddDays($pauseDays)

        Set-WUSettings -PauseQualityUpdates $true -QualityUpdatesPauseExpiryDate $pauseUntil -ErrorAction Stop

        Write-Log "✅ Windows Update pause applied until $pauseUntil"
    }
    catch {
        Write-Log "⚠️  Failed to pause Windows Update: $_" "ERROR"
        Write-Log "Fallback to legacy registry method..."
        
        $currentDate = Get-Date
        $pauseUntilStr = $currentDate.AddDays($pauseDays).ToString("yyyy-MM-dd")

        $regPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }

        Set-ItemProperty -Path $regPath -Name "PauseQualityUpdatesStartTime" -Value $currentDate
        Set-ItemProperty -Path $regPath -Name "PauseQualityUpdatesUntil" -Value $pauseUntilStr

        Write-Log "✅ Windows Update pause applied (legacy registry method) until $pauseUntilStr"
    }
}

# ========== Set System Locale to Japanese ==========
Run-Step "Configuring system locale to Japanese" {
    $langPack = Get-WindowsCapability -Online | Where-Object { $_.Name -like "Language.Basic~~~ja-JP~*" }
    if ($langPack.State -ne "Installed") {
        Add-WindowsCapability -Online -Name "Language.Basic~~~ja-JP~0.0.1.0" -ErrorAction Stop
    }
    $LangList = New-WinUserLanguageList ja-JP
    if ($LangList -and $LangList.Count -gt 0) {
        $LangList[0].Handwriting = $true
        Set-WinUserLanguageList $LangList -Force
    }
    Set-WinUILanguageOverride -Language ja-JP
    Set-WinSystemLocale ja-JP
    Set-Culture ja-JP
    Set-WinHomeLocation -GeoId 122
}

# ========== Install Japanese Language Pack ==========
Run-Step "Installing minimum Japanese language pack and fonts" {
    $capabilities = @(
        "Language.Basic~~~ja-JP~0.0.1.0",
        "InputMethod.Editor.Japanese~~~ja-JP~0.0.1.0",
        "Language.Fonts.Jpan~~~und-JPAN~0.0.1.0"
    )

    foreach ($cap in $capabilities) {
        Write-Log "Adding capability: $cap"
        try {
            Add-WindowsCapability -Online -Name $cap -ErrorAction Stop
            Write-Log "✅ Successfully installed: $cap"
        } catch {
            Write-Log "⚠️  Failed to install $cap - $_" "ERROR"
        }
    }
}

# ========== Disable DNS-over-HTTPS in Chrome ==========
Run-Step "Disabling DNS-over-HTTPS in Chrome" {
    $regPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    New-ItemProperty -Path $regPath -Name "DnsOverHttpsMode" -PropertyType String -Value "off" -Force | Out-Null
}

# ========== DNS connection setting ==========
Run-Step "Forcing DNS server to 10.0.1.7" {
    Get-DnsClient | Where-Object {$_.InterfaceAlias -like "Ethernet*"} | ForEach-Object {
        Set-DnsClientServerAddress -InterfaceAlias $_.InterfaceAlias -ServerAddresses 10.0.1.7
    }
}

# ========== Final Message ==========
Write-Log "===== Setup completed. Please restart the system to apply the Japanese UI and IME settings. ====="
