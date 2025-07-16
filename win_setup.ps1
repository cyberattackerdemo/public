$logFile = "C:\win_config_log.txt"

# ログ出力関数（通常）
function Log($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp [INFO] $message"
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

# ログ出力関数（エラー）
function LogError($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp [ERROR] $message"
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

# 実行のトランスクリプトを開始
Start-Transcript -Path "C:\win_setup_transcript.txt" -Append
Log "スクリプト実行開始"

# Defender無効化
try {
    Log "Defenderのリアルタイム保護を無効化"
    Set-MpPreference -DisableRealtimeMonitoring $true
} catch { LogError "Defenderの無効化失敗: $($_.Exception.Message)" }

# Defender Cloud-delivered protection 無効化
try {
    Log "DefenderのCloud-delivered protection (MAPS) を無効化"
    Set-MpPreference -MAPSReporting Disabled
} catch { LogError "Cloud-delivered protection無効化失敗: $($_.Exception.Message)" }

# Defender Automatic Sample Submission 無効化
try {
    Log "DefenderのAutomatic Sample Submissionを無効化"
    Set-MpPreference -SubmitSamplesConsent NeverSend
} catch { LogError "Automatic Sample Submission無効化失敗: $($_.Exception.Message)" }

# ファイアウォール無効化
try {
    Log "ファイアウォールを無効化"
    netsh advfirewall set allprofiles state off
} catch { LogError "ファイアウォール無効化失敗: $($_.Exception.Message)" }

# Office AMSI スキャン無効化
try {
    Log "Office AMSI スキャン無効化レジストリ設定（DisableOfficeAMSI=1）"
    $officeSecurityPath = "HKLM:\SOFTWARE\Microsoft\Office\16.0\Common\Security"
    if (!(Test-Path $officeSecurityPath)) {
        New-Item -Path $officeSecurityPath -Force | Out-Null
    }
    New-ItemProperty -Path $officeSecurityPath -Name "DisableOfficeAMSI" -PropertyType DWord -Value 1 -Force | Out-Null
    Log "Office AMSI スキャン無効化設定完了"
} catch { LogError "Office AMSI スキャン無効化設定失敗: $($_.Exception.Message)" }

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

# Wordインストール用ファイルダウンロード & 実行
try {
    Log "WordインストールファイルをGitHubからダウンロード"
    $tempPath = "C:\ODT"
    if (!(Test-Path $tempPath)) {
        New-Item -ItemType Directory -Path $tempPath | Out-Null
    }
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/cyberattackerdemo/public/main/setup.exe" -OutFile "$tempPath\setup.exe"
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/cyberattackerdemo/public/main/config.xml" -OutFile "$tempPath\config.xml"
    if (!(Test-Path "$tempPath\setup.exe") -or !(Test-Path "$tempPath\config.xml")) {
        throw "必要なファイルが揃っていません"
    }
    Start-Process -FilePath "$tempPath\setup.exe" -ArgumentList "/configure $tempPath\config.xml" -Wait
} catch { LogError "Wordインストール失敗: $($_.Exception.Message)" }

# Chromeインストール
try {
    Log "Chromeをダウンロード＆インストール"
    Invoke-WebRequest -Uri "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -OutFile "C:\chrome_installer.exe"
    Start-Process -FilePath "C:\chrome_installer.exe" -ArgumentList "/silent /install /log C:\chrome_install_log.txt" -Wait
    Remove-Item "C:\chrome_installer.exe" -Force
} catch { LogError "Chromeインストール失敗: $($_.Exception.Message)" }

# Chromeを既定ブラウザに
try {
    $chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    if (Test-Path $chromePath) {
        Start-Process $chromePath -ArgumentList "--make-default-browser" -Wait
    }
} catch { LogError "Chrome既定ブラウザ設定失敗: $($_.Exception.Message)" }

# ブックマーク作成
try {
    Log "ブックマークファイル作成"
    $bookmarkPath = "$env:PUBLIC\Bookmarks"
    New-Item -ItemType Directory -Force -Path $bookmarkPath | Out-Null
    Set-Content -Path "$bookmarkPath\bookmarks.txt" -Value "https://gmail.com`r`nhttps://dp-handson-jp4.cybereason.net"
} catch { LogError "ブックマーク作成失敗: $($_.Exception.Message)" }

# GitHubファイルダウンロード用スクリプト作成 & タスク登録
try {
    Log "GitHubファイルダウンロード用PS1/BAT作成・タスク登録"
    $ps1Path = "C:\Users\Public\GitHubFileDownloader.ps1"
    $batPath = "C:\Users\Public\Desktop\github_downloader.bat"
    $downloadLog = "C:\Users\Public\github_download_log.txt"

    $ps1Content = @'
$logFile = "C:\Users\Public\github_download_log.txt"
function Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$ts`t$msg"
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}
function LogError($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$ts`t[ERROR] $msg"
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}
Log "GitHubファイルダウンロード開始"
$desktop = [Environment]::GetFolderPath("Desktop")
$urls = @(
"https://raw.githubusercontent.com/cyberattackerdemo/public/main/password.txt",
"https://raw.githubusercontent.com/cyberattackerdemo/public/main/Customerlist.txt",
"https://raw.githubusercontent.com/cyberattackerdemo/public/main/document1.docx",
"https://raw.githubusercontent.com/cyberattackerdemo/public/main/document2.docx",
"https://raw.githubusercontent.com/cyberattackerdemo/public/main/document3.docx"
)
foreach ($url in $urls) {
    $fileName = Split-Path $url -Leaf
    $target = Join-Path $desktop $fileName
    if (-not (Test-Path $target)) {
        try {
            Invoke-WebRequest -Uri $url -OutFile $target -ErrorAction Stop
            Log "Downloaded: $fileName"
        } catch {
            LogError "Failed: $fileName - $($_.Exception.Message)"
        }
    } else {
        Log "Already exists: $fileName"
    }
}
$all = $true
foreach ($url in $urls) {
    $fileName = Split-Path $url -Leaf
    if (-not (Test-Path (Join-Path $desktop $fileName))) {
        $all = $false
        break
    }
}
if ($all) {
    Log "全ファイルダウンロード完了・クリーンアップ"
    Remove-Item -Path "C:\Users\Public\GitHubFileDownloader.ps1" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Users\Public\Desktop\github_downloader.bat" -Force -ErrorAction SilentlyContinue
    schtasks /Delete /TN "RunGitHubDownloader" /F | Out-Null
}
'@

    Set-Content -Path $ps1Path -Value $ps1Content -Force
    Set-Content -Path $batPath -Value "powershell -ExecutionPolicy Bypass -File `"$ps1Path`"" -Force
    schtasks /Create /TN "RunGitHubDownloader" /TR "$batPath" /SC ONLOGON /RL HIGHEST /F | Out-Null
    Log "GitHubファイルダウンロードスクリプト登録完了"
} catch { LogError "GitHubファイルダウンロードタスク設定失敗: $($_.Exception.Message)" }

# 日本語言語パック追加
try {
    Log "日本語言語パックとIMEをインストール"
    Add-WindowsCapability -Online -Name Language.Basic~~~ja-JP~0.0.1.0
    Add-WindowsCapability -Online -Name Language.Handwriting~~~ja-JP~0.0.1.0
    Add-WindowsCapability -Online -Name Language.Speech~~~ja-JP~0.0.1.0
    Add-WindowsCapability -Online -Name Language.TextToSpeech~~~ja-JP~0.0.1.0
} catch { LogError "日本語言語パックインストール失敗: $($_.Exception.Message)" }

# 日本語化設定
try {
    Log "言語設定を日本語に変更"
    Set-WinUILanguageOverride -Language ja-JP
    Set-WinUserLanguageList ja-JP -Force
    Set-WinSystemLocale ja-JP
    Set-Culture ja-JP
    Set-WinHomeLocation -GeoId 122
} catch { LogError "言語設定失敗: $($_.Exception.Message)" }

# マクロ削除回避のための信頼センター設定
try {
    Log "信頼されていないマクロ有効化（警告なし）"
    $macroSecurityPath = "HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Word\Security"
    if (!(Test-Path $macroSecurityPath)) {
        New-Item -Path $macroSecurityPath -Force | Out-Null
    }
    Set-ItemProperty -Path $macroSecurityPath -Name "VBAWarnings" -Value 1 -Force
    Set-ItemProperty -Path $macroSecurityPath -Name "blockcontentexecutionfrominternet" -Value 0 -Force
    Log "マクロセキュリティ設定完了 (VBAWarnings=1, blockcontentexecutionfrominternet=0)"
} catch { LogError "マクロセキュリティ設定失敗: $($_.Exception.Message)" }

# Outlook ショートカットをデスクトップに作成
try {
    Log "Outlookショートカットをデスクトップに作成"

    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "Outlook.lnk"
    $shell = New-Object -ComObject WScript.Shell

    # Outlook の実行パスを自動検出
    $outlookPath = Get-ChildItem "C:\Program Files*\Microsoft Office\root\Office*\OUTLOOK.EXE" -ErrorAction SilentlyContinue | Select-Object -First 1

    if ($outlookPath) {
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $outlookPath.FullName
        $shortcut.IconLocation = $outlookPath.FullName
        $shortcut.Save()
        Log "Outlookショートカット作成完了: $($shortcutPath)"
    } else {
        LogError "Outlook 実行ファイルが見つかりませんでした"
    }
} catch { LogError "Outlookショートカット作成失敗: $($_.Exception.Message)" }

try {
    Log "次回セットアップ用スクリプトをGitHubからデスクトップにダウンロード"
    $desktop = [Environment]::GetFolderPath("Desktop")
    $setupScriptUrl = "https://raw.githubusercontent.com/cyberattackerdemo/public/main/setup_Japanese_windows10.ps1"
    $setupScriptPath = Join-Path $desktop "setup_Japanese_windows10.ps1"

    Invoke-WebRequest -Uri $setupScriptUrl -OutFile $setupScriptPath -UseBasicParsing
    Log "セットアップスクリプトのダウンロード完了: $setupScriptPath"
} catch {
    LogError "セットアップスクリプトのダウンロード失敗: $($_.Exception.Message)"
}

try {
    Log "セットアップ用BATファイルをデスクトップに作成"
    $desktop = [Environment]::GetFolderPath("Desktop")
    $batPath = Join-Path $desktop "Run_setup_Japanese_windows10.bat"
    $ps1Path = Join-Path $desktop "setup_Japanese_windows10.ps1"

    $batContent = "@echo off`r`npowershell -ExecutionPolicy Bypass -File `"$ps1Path`"`r`npause"
    Set-Content -Path $batPath -Value $batContent -Encoding ASCII -Force

    Log "BATファイル作成完了: $batPath"
} catch {
    LogError "BATファイル作成失敗: $($_.Exception.Message)"
}


# 一時フォルダ削除
try {
    Log "一時フォルダ (C:\ODT) を削除"
    Remove-Item -Path "C:\ODT" -Recurse -Force
} catch { LogError "一時フォルダ削除失敗: $($_.Exception.Message)" }

Log "スクリプト完了"
Stop-Transcript
