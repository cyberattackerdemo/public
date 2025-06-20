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
    Write-Log "=== $stepName ==="
    $start = Get-Date
    try {
        $output = & $action 2>&1
        $end = Get-Date
        $duration = ($end - $start).TotalSeconds
        Write-Log "$stepName completed in $duration seconds."
        if ($output) {
            Write-Log "Output:`n$output"
        } else {
            Write-Log "No output."
        }
    } catch {
        $end = Get-Date
        $duration = ($end - $start).TotalSeconds
        Write-Log "Failed: $stepName - $_ (after $duration seconds)" "ERROR"
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

# ========== Install Japanese Language Pack ==========
Run-Step "Installing Japanese language pack" {
    Add-WindowsCapability -Online -Name "Language.Basic~~~ja-JP~0.0.1.0"
    Add-WindowsCapability -Online -Name "Language.Handwriting~~~ja-JP~0.0.1.0" -ErrorAction SilentlyContinue
    Add-WindowsCapability -Online -Name "Language.Speech~~~ja-JP~0.0.1.0" -ErrorAction SilentlyContinue
    Add-WindowsCapability -Online -Name "Language.TextToSpeech~~~ja-JP~0.0.1.0" -ErrorAction SilentlyContinue
    Add-WindowsCapability -Online -Name "InputMethod.Editor.Japanese~~~ja-JP~0.0.1.0"
}

# ========== Install Japanese Language Pack ========== 
Run-Step "Installing Japanese language pack and fonts" { 
    # 基本 Language Pack 
    Add-WindowsCapability -Online -Name "Language.Basic~~~ja-JP~0.0.1.0" 
    # 手書き 
    Add-WindowsCapability -Online -Name "Language.Handwriting~~~ja-JP~0.0.1.0" -ErrorAction SilentlyContinue 
    # 音声入力 
    Add-WindowsCapability -Online -Name "Language.Speech~~~ja-JP~0.0.1.0" -ErrorAction SilentlyContinue 
    # Text-to-Speech 
    Add-WindowsCapability -Online -Name "Language.TextToSpeech~~~ja-JP~0.0.1.0" -ErrorAction SilentlyContinue 
    # IME 
    Add-WindowsCapability -Online -Name "InputMethod.Editor.Japanese~~~ja-JP~0.0.1.0" 
    # フォント (Fonts.Jpan) 
    Add-WindowsCapability -Online -Name "Language.Fonts.Jpan~~~und-JPAN~0.0.1.0" -ErrorAction Stop 
}

# ========== Set Time Zone ==========
Run-Step "Setting time zone to Tokyo" {
    Set-TimeZone -Id 'Tokyo Standard Time'
}

# ========== Pause Windows Update for 14 days ==========
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

# ========== Disable DNS-over-HTTPS in Chrome ==========
Run-Step "Disabling DNS-over-HTTPS in Chrome" {
    $regPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    New-ItemProperty -Path $regPath -Name "DnsOverHttpsMode" -PropertyType String -Value "off" -Force | Out-Null
}

# ========== Configure Proxy ==========
Run-Step "Configuring internet proxy and WinHTTP proxy" {
    $proxyAddress = "10.0.1.6:8080"

    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "http://$proxyAddress" /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoDetect /t REG_DWORD /d 0 /f

    netsh winhttp set proxy proxy-server="http://$proxyAddress"

    [Environment]::SetEnvironmentVariable("HTTPS_PROXY", "https://$proxyAddress", "Machine")
    [Environment]::SetEnvironmentVariable("HTTP_PROXY", "http://$proxyAddress", "Machine")
}

# ========== DNS connection setting ==========
Run-Step "Forcing DNS server to 10.0.1.7" {
    Get-DnsClient | Where-Object {$_.InterfaceAlias -like "Ethernet*"} | ForEach-Object {
        Set-DnsClientServerAddress -InterfaceAlias $_.InterfaceAlias -ServerAddresses 10.0.1.7
    }
}

# ========== デフォルトゲートウェイ 10.0.1.7 を追加 ==========
Run-Step "Setting default gateway to 10.0.1.7" {
    Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | ForEach-Object {
        $ifIndex = $_.ifIndex
        # 既存 default route 削除
        Remove-NetRoute -InterfaceIndex $ifIndex -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue
        # 新 default route 追加
        New-NetRoute -InterfaceIndex $ifIndex -DestinationPrefix "0.0.0.0/0" -NextHop "10.0.1.7"
    }
}

# ========== Final Message ==========
Write-Log "===== Setup completed. Please restart the system to apply the Japanese UI and IME settings. ====="