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

try {
    Log "GitHubファイルダウンロード用PS1とBATを作成・タスク登録（Public Desktop対応）"

    $ps1Path = "C:\Users\Public\GitHubFileDownloader.ps1"
    $batPath = "C:\Users\Public\Desktop\github_downloader.bat"
    $logPath = "C:\Users\Public\github_download_log.txt"
    $desktopPath = "C:\Users\Public\Desktop"

    $downloadUrls = @(
        "https://raw.githubusercontent.com/cyberattackerdemo/public/main/password.txt",
        "https://raw.githubusercontent.com/cyberattackerdemo/public/main/Customerlist.txt",
        "https://raw.githubusercontent.com/cyberattackerdemo/public/main/document1.docx",
        "https://raw.githubusercontent.com/cyberattackerdemo/public/main/document2.docx",
        "https://raw.githubusercontent.com/cyberattackerdemo/public/main/document3.docx"
    )

    $ps1Content = @"
$logFile = "C:\Users\Public\github_download_log.txt"
function Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$ts`t$msg"
}

Log "GitHubファイルダウンロード開始"

$desktopPath = "C:\Users\Public\Desktop"
$urls = @(
    "https://raw.githubusercontent.com/cyberattackerdemo/public/main/password.txt",
    "https://raw.githubusercontent.com/cyberattackerdemo/public/main/Customerlist.txt",
    "https://raw.githubusercontent.com/cyberattackerdemo/public/main/document1.docx",
    "https://raw.githubusercontent.com/cyberattackerdemo/public/main/document2.docx",
    "https://raw.githubusercontent.com/cyberattackerdemo/public/main/document3.docx"
)

foreach ($url in $urls) {
    $fileName = Split-Path $url -Leaf
    $targetPath = Join-Path $desktopPath $fileName
    if (-Not (Test-Path $targetPath)) {
        try {
            Invoke-WebRequest -Uri $url -OutFile $targetPath -ErrorAction Stop
            Log "Downloaded: $fileName"
        } catch {
            Log "Failed to download: $fileName - $($_.Exception.Message)"
        }
    } else {
        Log "Already exists: $fileName"
    }
}

$allExist = $true
foreach ($url in $urls) {
    $fileName = Split-Path $url -Leaf
    if (-Not (Test-Path (Join-Path $desktopPath $fileName))) {
        $allExist = $false
        break
    }
}

if ($allExist) {
    Log "全ファイルダウンロード成功。自動削除を実行"
    Remove-Item -Path "C:\Users\Public\GitHubFileDownloader.ps1" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Users\Public\Desktop\github_downloader.bat" -Force -ErrorAction SilentlyContinue
    schtasks /Delete /TN "RunGitHubDownloader" /F | Out-Null
}
"@

    # 保存
    Set-Content -Path $ps1Path -Value $ps1Content -Force

    $batContent = "powershell -ExecutionPolicy Bypass -File `"$ps1Path`""
    Set-Content -Path $batPath -Value $batContent -Force

    # タスク登録
    schtasks /Create /TN "RunGitHubDownloader" `
        /TR "$batPath" /SC ONLOGON /RL HIGHEST /F | Out-Null

    Log "GitHubファイルダウンロードスクリプトとタスク登録を完了"
} catch {
    LogError "GitHubファイルダウンロード関連処理失敗: $($_.Exception.Message)"
}

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
    Set-ItemProperty -Path $macroSecurityPath -Name 'VBAWarnings' -Value 1 -Force
    Set-ItemProperty -Path $macroSecurityPath -Name 'blockcontentexecutionfrominternet' -Value 0 -Force
    Log "マクロセキュリティ設定完了 (VBAWarnings=1, blockcontentexecutionfrominternet=0)"
} catch {
    LogError "マクロセキュリティ設定失敗: $($_.Exception.Message)"
}

# 一時フォルダ削除
try {
    Log "一時フォルダ (C:\ODT) を削除"
    Remove-Item -Path "C:\ODT" -Recurse -Force
} catch { LogError "一時フォルダ削除失敗: $($_.Exception.Message)" }

Log "スクリプト完了"
Stop-Transcript
