$logFile = "C:\win_config_log.txt"

# ログ出力関数（通常）
function Log($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp [INFO] $message"
}

# ログ出力関数（エラー）
function LogError($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp [ERROR] $message"
}

# 実行のトランスクリプトを開始
Start-Transcript -Path "C:\win_setup_transcript.txt" -Append

Log "スクリプト実行開始"

# Defender無効化
try {
    Log "Defenderのリアルタイム保護を無効化"
    Set-MpPreference -DisableRealtimeMonitoring $true
} catch { LogError "Defenderの無効化失敗: $($_.Exception.Message)" }

# ファイアウォール無効化
try {
    Log "ファイアウォールを無効化"
    netsh advfirewall set allprofiles state off
} catch { LogError "ファイアウォール無効化失敗: $($_.Exception.Message)" }

# UAC無効化
try {
    Log "UACを無効化"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0
} catch { LogError "UAC無効化失敗: $($_.Exception.Message)" }

# タイムゾーン設定
try {
    Log "タイムゾーンをTokyoに設定"
    Set-TimeZone -Id "Tokyo Standard Time"
} catch { LogError "タイムゾーン設定失敗: $($_.Exception.Message)" }

# NTP設定
try {
    Log "NTPサーバー設定と同期"
    w32tm /config /manualpeerlist:"ntp.nict.jp" /syncfromflags:manual /update | Out-Null
    w32tm /resync | Out-Null
} catch { LogError "NTP設定失敗: $($_.Exception.Message)" }

# Wordインストール用ファイルをダウンロードして実行
try {
    Log "Wordインストール用ファイルをGitHubからダウンロード"
    $tempPath = "C:\ODT"
    if (!(Test-Path -Path $tempPath)) {
        New-Item -ItemType Directory -Path $tempPath | Out-Null
    }
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/cyberattackerdemo/public/main/setup.exe" -OutFile "$tempPath\setup.exe"
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/cyberattackerdemo/public/main/config.xml" -OutFile "$tempPath\config.xml"

    if (!(Test-Path "$tempPath\setup.exe") -or !(Test-Path "$tempPath\config.xml")) {
        throw "必要なファイルが揃っていません。"
    }

    Start-Process -FilePath "$tempPath\setup.exe" -ArgumentList "/configure $tempPath\config.xml" -Wait
} catch { LogError "Wordインストール失敗: $($_.Exception.Message)" }

# ダウンロードファイルのブロック解除（MOTW対策）
try {
    Log "ダウンロードファイルのブロック解除（MOTW対策）"
    Unblock-File -Path "C:\Users\Public\Documents\*.zip"
    Expand-Archive -Path "C:\Users\Public\Documents\your.zip" -DestinationPath "C:\Users\Public\Documents\unzipped"
    Unblock-File -Path "C:\Users\Public\Documents\unzipped\*.docm"
} catch {
    LogError "ファイルのブロック解除失敗: $($_.Exception.Message)"
}

# Chromeインストール
try {
    Log "Chromeをダウンロード＆インストール"
    Invoke-WebRequest -Uri 'https://dl.google.com/chrome/install/latest/chrome_installer.exe' -OutFile 'C:\chrome_installer.exe'
    Start-Process -FilePath 'C:\chrome_installer.exe' -ArgumentList '/silent /install /log C:\chrome_install_log.txt' -Wait
    Remove-Item 'C:\chrome_installer.exe'
} catch { LogError "Chromeインストール失敗: $($_.Exception.Message)" }

# Chromeを既定ブラウザに
try {
    $chromePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
    if (Test-Path $chromePath) {
        Start-Process $chromePath -ArgumentList '--make-default-browser' -Wait
    }
} catch { LogError "Chrome既定ブラウザ設定失敗: $($_.Exception.Message)" }

# Chromeショートカット作成とタスクバーへピン留め（プロキシ指定付き）
try {
    Log "Chromeショートカット作成（プロキシオプション付き）"
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "Google Chrome.lnk"
    if (Test-Path $chromePath) {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $chromePath
        $shortcut.Arguments = "--proxy-server=10.0.1.254:3128 --proxy-bypass-list=10.0.1.*"
        $shortcut.IconLocation = $chromePath
        $shortcut.Save()

        $taskbarShortcutPath = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Google Chrome.lnk"
        Copy-Item -Path $shortcutPath -Destination $taskbarShortcutPath -Force
    }
} catch { LogError "Chromeショートカット作成失敗: $($_.Exception.Message)" }

# ブックマーク作成
try {
    Log "ブックマークファイル作成"
    $bookmarkPath = "$env:PUBLIC\Bookmarks"
    New-Item -ItemType Directory -Force -Path $bookmarkPath | Out-Null
    Set-Content -Path "$bookmarkPath\bookmarks.txt" -Value "https://gmail.com`r`nhttps://dp-handson-jp4.cybereason.net"
} catch { LogError "ブックマーク作成失敗: $($_.Exception.Message)" }

# 日本語言語パックの追加
try {
    Log "日本語言語パックとIMEをインストール"
    Add-WindowsCapability -Online -Name Language.Basic~~~ja-JP~0.0.1.0
    Add-WindowsCapability -Online -Name Language.Handwriting~~~ja-JP~0.0.1.0
    Add-WindowsCapability -Online -Name Language.Speech~~~ja-JP~0.0.1.0
    Add-WindowsCapability -Online -Name Language.TextToSpeech~~~ja-JP~0.0.1.0
} catch { LogError "日本語言語パックインストール失敗: $($_.Exception.Message)" }

# 一般ユーザーの作成
try {
    Log "一般ユーザー victim を作成"

    $userName = "victim"
    $password = "victim" | ConvertTo-SecureString -AsPlainText -Force

    # 既に存在しないか確認してから作成
    if (!(Get-LocalUser -Name $userName -ErrorAction SilentlyContinue)) {
        New-LocalUser -Name $userName -Password $password -FullName "Victim User" -Description "Standard User"
        Add-LocalGroupMember -Group "Users" -Member $userName
        Log "ユーザー victim を作成し、Users グループに追加完了"
    } else {
        Log "ユーザー victim は既に存在しています"
    }
} catch {
    LogError "一般ユーザー作成失敗: $($_.Exception.Message)"
}

# 日本語に設定
try {
    Log "言語設定を日本語に変更"
    Set-WinUILanguageOverride -Language ja-JP
    Set-WinUserLanguageList ja-JP -Force
    Set-WinSystemLocale ja-JP
    Set-Culture ja-JP
    Set-WinHomeLocation -GeoId 122
} catch { LogError "言語設定失敗: $($_.Exception.Message)" }

# プロキシ設定とno_proxy環境変数に10.0.1.0/24を含める
try {
    Log "WinINET＋WinHTTP＋HKLMプロキシ＋no_proxy設定"

    # WinINET (HKCU)
    $regPathUser = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-ItemProperty -Path $regPathUser -Name AutoDetect -Value 0
    Set-ItemProperty -Path $regPathUser -Name ProxyEnable -Value 1
    Set-ItemProperty -Path $regPathUser -Name ProxyServer -Value "10.0.1.254:3128"

    # WinINET (HKLMポリシー)
    $regPathMachine = "HKLM:\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings"
    if (!(Test-Path $regPathMachine)) { New-Item -Path $regPathMachine -Force | Out-Null }
    New-ItemProperty -Path $regPathMachine -Name ProxyEnable -PropertyType DWord -Value 1 -Force | Out-Null
    New-ItemProperty -Path $regPathMachine -Name ProxyServer -PropertyType String -Value "10.0.1.254:3128" -Force | Out-Null
    New-ItemProperty -Path $regPathMachine -Name ProxyOverride -PropertyType String -Value "10.0.1.*" -Force | Out-Null

    # WinHTTP
    netsh winhttp set proxy 10.0.1.254:3128 "10.0.1.*"

    # 環境変数 no_proxy
    [System.Environment]::SetEnvironmentVariable("no_proxy", "10.0.1.*", "Machine")
    [System.Environment]::SetEnvironmentVariable("NO_PROXY", "10.0.1.*", "Machine")

    gpupdate /force | Out-Null
} catch { LogError "プロキシ設定失敗: $($_.Exception.Message)" }

# マクロ削除回避のための信頼センター設定とマクロセキュリティ緩和
try {
    Log "信頼されていないマクロも有効化（警告なし）"
    $macroSecurityPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Word\Security'
    if (!(Test-Path $macroSecurityPath)) {
        New-Item -Path $macroSecurityPath -Force | Out-Null
    }
    Set-ItemProperty -Path $macroSecurityPath -Name 'VBAWarnings' -PropertyType DWord -Value 1 -Force
    Set-ItemProperty -Path $macroSecurityPath -Name 'blockcontentexecutionfrominternet' -PropertyType DWord -Value 0 -Force
    Log "マクロセキュリティ設定完了 (VBAWarnings=1, blockcontentexecutionfrominternet=0)"
} catch {
    LogError "マクロセキュリティ設定失敗: $($_.Exception.Message)"
}

try {
    Log "GitHubファイルダウンロード用PS1と起動用BATファイルを作成"

    # 保存先ディレクトリの作成
    $ps1Dir = "C:\Users\Public\GitHubFiles"
    if (!(Test-Path $ps1Dir)) {
        New-Item -Path $ps1Dir -ItemType Directory | Out-Null
    }

    # GitHubファイルURLと保存ファイル名のペア
    $fileMap = @{
        "https://raw.githubusercontent.com/cyberattackerdemo/public/main/password.txt" = "password.txt"
        "https://raw.githubusercontent.com/cyberattackerdemo/public/main/Customerlist.txt" = "Customerlist.txt"
        "https://raw.githubusercontent.com/cyberattackerdemo/public/main/document1.docx" = "document1.docx"
        "https://raw.githubusercontent.com/cyberattackerdemo/public/main/document2.docx" = "document2.docx"
        "https://raw.githubusercontent.com/cyberattackerdemo/public/main/document3.docx" = "document3.docx"
    }

    # ダウンロード用PS1のパス
    $downloadScriptPath = "$ps1Dir\DownloadFromGitHub.ps1"

    # PS1内容を構成
    $ps1Content = @()
    $ps1Content += 'Write-Host "GitHubファイルのダウンロードを開始します..."'
    foreach ($url in $fileMap.Keys) {
        $filename = $fileMap[$url]
        $destPath = Join-Path $ps1Dir $filename
        $ps1Content += "Invoke-WebRequest -Uri `"$url`" -OutFile `"$destPath`" -UseBasicParsing"
    }
    $ps1Content += 'Write-Host "完了しました。"'

    # PS1ファイル保存
    $ps1Content | Set-Content -Path $downloadScriptPath -Encoding UTF8

    # 実行用BATのパス（全ユーザーデスクトップ）
    $batPath = "$env:PUBLIC\Desktop\Download_5files.bat"
    $batContent = "@echo off`r`n" +
                  "powershell -ExecutionPolicy Bypass -File `"$downloadScriptPath`"`r`n" +
                  "pause"

    # BATファイル保存
    $batContent | Set-Content -Path $batPath -Encoding ASCII

    # 既定プロファイルにもコピー（初回ログイン時にユーザーのデスクトップに反映される）
    $defaultDesktop = "C:\Users\Default\Desktop"
    if (Test-Path $defaultDesktop) {
        Copy-Item -Path $batPath -Destination "$defaultDesktop\Download_5files.bat" -Force
    }

    Log "ダウンロード用PS1とBATファイル作成完了"

} catch {
    LogError "GitHubダウンロード用スクリプト作成失敗: $($_.Exception.Message)"
}

# 一時フォルダ削除
try {
    Log "一時フォルダ (C:\ODT) を削除"
    Remove-Item -Path "C:\ODT" -Recurse -Force
} catch { LogError "一時フォルダ削除失敗: $($_.Exception.Message)" }

Log "スクリプト完了"
Stop-Transcript
