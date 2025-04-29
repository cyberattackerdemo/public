$logFile = "C:\win_config_log.txt"

function Log($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp [INFO] $message"
}

function LogError($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp [ERROR] $message"
}

Start-Transcript -Path "C:\win_setup_transcript.txt" -Append

Log "スクリプト実行開始"

# 各処理ごとにtry-catchで囲むように変更
try {
    Log "Defenderのリアルタイム保護を無効化"
    Set-MpPreference -DisableRealtimeMonitoring $true
} catch { LogError "Defenderの無効化失敗: $($_.Exception.Message)" }

try {
    Log "ファイアウォールを無効化"
    netsh advfirewall set allprofiles state off
} catch { LogError "ファイアウォール無効化失敗: $($_.Exception.Message)" }

try {
    Log "UACを無効化"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0
} catch { LogError "UAC無効化失敗: $($_.Exception.Message)" }

try {
    Log "タイムゾーンをTokyoに設定"
    Set-TimeZone -Id "Tokyo Standard Time"
} catch { LogError "タイムゾーン設定失敗: $($_.Exception.Message)" }

try {
    Log "NTP設定"
    w32tm /config /manualpeerlist:"ntp.nict.jp" /syncfromflags:manual /update | Out-Null
    w32tm /resync | Out-Null
} catch { LogError "NTP設定失敗: $($_.Exception.Message)" }

try {
    Log "Wordインストール用ファイルをGitHubからダウンロード"

    $tempPath = "C:\ODT"
    if (!(Test-Path -Path $tempPath)) {
        New-Item -ItemType Directory -Path $tempPath | Out-Null
        Log "一時フォルダ作成: $tempPath"
    }

    $setupUrl = "https://raw.githubusercontent.com/cyberattackerdemo/public/main/setup.exe"
    $configUrl = "https://raw.githubusercontent.com/cyberattackerdemo/public/main/config.xml"

    Invoke-WebRequest -Uri $setupUrl -OutFile "$tempPath\setup.exe"
    Invoke-WebRequest -Uri $configUrl -OutFile "$tempPath\config.xml"

    if (!(Test-Path "$tempPath\setup.exe") -or !(Test-Path "$tempPath\config.xml")) {
        throw "必要なファイルが揃っていません。ダウンロードに失敗しました。"
    }

    Log "Wordインストール開始"
    Start-Process -FilePath "$tempPath\setup.exe" -ArgumentList "/configure $tempPath\config.xml" -Wait

    Log "Wordインストール完了"

} catch {
    LogError "Wordインストール失敗: $($_.Exception.Message)"
}

try {
    Log "Chromeをダウンロード＆インストール"
    Invoke-WebRequest -Uri 'https://dl.google.com/chrome/install/latest/chrome_installer.exe' -OutFile 'C:\chrome_installer.exe'
    Start-Process -FilePath 'C:\chrome_installer.exe' -ArgumentList '/silent /install /log C:\chrome_install_log.txt' -Wait
    Remove-Item 'C:\chrome_installer.exe'
} catch { LogError "Chromeインストール失敗: $($_.Exception.Message)" }

try {
    $chromePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
    if (Test-Path $chromePath) {
        Log "Chromeを既定ブラウザに設定"
        Start-Process $chromePath -ArgumentList '--make-default-browser' -Wait
    }
} catch {
    LogError "Chrome既定ブラウザ設定失敗: $($_.Exception.Message)"
}


try {
    Log "Chromeショートカット作成（プロキシオプション付き）"
    $chromeExePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "Google Chrome.lnk"
    if (Test-Path $chromeExePath) {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $chromeExePath
        $shortcut.Arguments = "--proxy-server=10.0.1.254:3128"
        $shortcut.IconLocation = $chromeExePath
        $shortcut.Save()
        Log "Chromeショートカット作成完了（プロキシオプション付き）"

        # タスクバーにピン留め（ファイルをコピー）
        $taskbarShortcutPath = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Google Chrome.lnk"
        Copy-Item -Path $shortcutPath -Destination $taskbarShortcutPath -Force
    }
} catch {
    LogError "Chromeショートカット作成失敗: $($_.Exception.Message)"
}

try {
    Log "ブックマークファイル作成"
    $bookmarkPath = "$env:PUBLIC\Bookmarks"
    New-Item -ItemType Directory -Force -Path $bookmarkPath | Out-Null
    Set-Content -Path "$bookmarkPath\bookmarks.txt" -Value "https://gmail.com`r`nhttps://dp-handson-jp4.cybereason.net"
} catch { LogError "ブックマーク作成失敗: $($_.Exception.Message)" }

try {
    Log "日本語言語パックとIMEをインストール"
    Add-WindowsCapability -Online -Name Language.Basic~~~ja-JP~0.0.1.0
    Add-WindowsCapability -Online -Name Language.Handwriting~~~ja-JP~0.0.1.0
    Add-WindowsCapability -Online -Name Language.Speech~~~ja-JP~0.0.1.0
    Add-WindowsCapability -Online -Name Language.TextToSpeech~~~ja-JP~0.0.1.0
} catch { LogError "日本語言語パックインストール失敗: $($_.Exception.Message)" }

try {
    Log "言語設定を日本語に変更"
    Set-WinUILanguageOverride -Language ja-JP
    Set-WinUserLanguageList ja-JP -Force
    Set-WinSystemLocale ja-JP
    Set-Culture ja-JP
    Set-WinHomeLocation -GeoId 122
} catch { LogError "言語設定失敗: $($_.Exception.Message)" }

try {
    Log "プロキシ設定（AutoDetect無効化＋HKCUとHKLM両方まとめて）"

    # Internet Settingsキーが無ければ作成
    if (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings")) {
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Force
    }
    
    # ユーザー設定（HKCU）
    $regPathUser = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-ItemProperty -Path $regPathUser -Name AutoDetect -Value 0 -Type DWord
    Set-ItemProperty -Path $regPathUser -Name ProxyEnable -Value 1
    Set-ItemProperty -Path $regPathUser -Name ProxyServer -Value "10.0.1.254:3128"

    # ポリシー設定（HKLM）
    $regPathMachine = "HKLM:\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings"
    New-Item -Path $regPathMachine -Force | Out-Null
    Set-ItemProperty -Path $regPathMachine -Name AutoDetect -Value 0 -Type DWord
    Set-ItemProperty -Path $regPathMachine -Name ProxySettingsPerUser -Type DWord -Value 0
    Set-ItemProperty -Path $regPathMachine -Name ProxyEnable -Type DWord -Value 1
    Set-ItemProperty -Path $regPathMachine -Name ProxyServer -Value "10.0.1.254:3128"

    # WinHTTPプロキシ設定
    netsh winhttp set proxy 10.0.1.254:3128

    Log "グループポリシーを即時反映"
    gpupdate /force | Out-Null

} catch {
    LogError "プロキシ設定（AutoDetect無効化＋Proxy指定）失敗: $($_.Exception.Message)"
}

try {
    Log "ログオン後にHKCUへプロキシを適用するスクリプトを作成"

    $fixProxyScript = @'
$regPathUser = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

Set-ItemProperty -Path $regPathUser -Name ProxyEnable -Value 1
Set-ItemProperty -Path $regPathUser -Name ProxyServer -Value "10.0.1.254:3128"
Set-ItemProperty -Path $regPathUser -Name AutoDetect -Value 0

$taskName = "FixProxyHKCU"
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
'@

    $scriptPath = "C:\Users\Public\fix_proxy_hkcu.ps1"
    Set-Content -Path $scriptPath -Value $fixProxyScript -Force

} catch {
    LogError "fix_proxy_hkcu.ps1作成失敗: $($_.Exception.Message)"
}

try {
    Log "Wordマクロ警告レジストリ設定"
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Word' -Force | Out-Null
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Word\Security' -Force | Out-Null
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Word\Security' -Name 'VBAWarnings' -PropertyType DWord -Value 1 -Force
} catch { LogError "Wordレジストリ設定失敗: $($_.Exception.Message)" }

try {
    Log "一時フォルダ (C:\ODT) を削除"
    Remove-Item -Path "C:\ODT" -Recurse -Force
} catch {
    LogError "一時フォルダ削除失敗: $($_.Exception.Message)"
}

Log "スクリプト完了"
Stop-Transcript
