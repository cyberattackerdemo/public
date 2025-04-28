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
    Log "Office Deployment Toolをダウンロード"
    $odtPath = "C:\ODT"
    $odtExe = "C:\ODTSetup.exe"
    Invoke-WebRequest -Uri "Invoke-WebRequest -Uri "https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_18623-20156.exe" -OutFile $odtExe
" -OutFile $odtExe

# 必ずフォルダ存在をチェック
    if (!(Test-Path -Path $odtPath)) { New-Item -ItemType Directory -Path $odtPath -Force | Out-Null }

    Log "ODTSetup.exeを展開"
    Start-Process -FilePath $odtExe -ArgumentList "/quiet /extract:$odtPath" -Wait
    
# 展開が完了するのを待つ
    $timeout = 60  # 最大60秒待つ
    $elapsed = 0
    while (!(Test-Path "$odtPath\setup.exe") -and ($elapsed -lt $timeout)) {
      Start-Sleep -Seconds 1
      $elapsed++
    }

    if (!(Test-Path "$odtPath\setup.exe")) {
      throw "ODT setup.exe が見つかりません。展開に失敗しました。"
    }


} catch { LogError "ODT取得または展開失敗: $($_.Exception.Message)" }

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
    Log "Chromeショートカット作成"
    $chromeExePath = $chromePath
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "Google Chrome.lnk"
    if (Test-Path $chromeExePath) {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $chromeExePath
        $shortcut.IconLocation = $chromeExePath
        $shortcut.Save()
        Log "Chromeをタスクバーにピン留め"
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
    Log "プロキシ設定"
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 1
    Set-ItemProperty -Path $regPath -Name ProxyServer -Value "10.0.1.254:3128"
    netsh winhttp set proxy 10.0.1.254:3128
} catch { LogError "プロキシ設定失敗: $($_.Exception.Message)" }

try {
    Log "Office構成ファイル作成"
    $configXml = @'
<Configuration>
  <Add OfficeClientEdition="64" Channel="Current">
    <Product ID="O365ProPlusRetail">
      <Language ID="ja-jp" />
      <ExcludeApp ID="Access" />
      <ExcludeApp ID="Excel" />
      <ExcludeApp ID="OneNote" />
      <ExcludeApp ID="Outlook" />
      <ExcludeApp ID="PowerPoint" />
      <ExcludeApp ID="Publisher" />
      <ExcludeApp ID="Teams" />
    </Product>
  </Add>
  <Display Level="None" AcceptEULA="TRUE" />
</Configuration>
'@
    Set-Content -Path "$odtPath\config.xml" -Value $configXml
} catch { LogError "Office構成ファイル作成失敗: $($_.Exception.Message)" }

try {
    Log "Wordインストール開始"
    Start-Process -FilePath "$odtPath\setup.exe" -ArgumentList "/configure $odtPath\config.xml" -Wait
} catch { LogError "Wordインストール失敗: $($_.Exception.Message)" }

try {
    Log "Wordマクロ警告レジストリ設定"
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Word' -Force | Out-Null
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Word\Security' -Force | Out-Null
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Word\Security' -Name 'VBAWarnings' -PropertyType DWord -Value 1 -Force
} catch { LogError "Wordレジストリ設定失敗: $($_.Exception.Message)" }

Log "スクリプト完了"
Stop-Transcript
