$logFile = "C:\win_langpack_setup.log"
function Log($msg) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp`t$msg" -Encoding utf8
}

try {
    Log "言語パックインストール開始"

    Set-Service -Name wuauserv -StartupType Automatic
    Start-Service wuauserv

    # 日本語言語パック (UI 言語) を追加
    Add-WindowsCapability -Online -Name Language.Basic~~~ja-JP~0.0.1.0

    Log "言語パックインストール完了"

    # インストール結果確認
    $capability = Get-WindowsCapability -Online | Where-Object { $_.Name -like "*Language.Basic*" -and $_.Name -like "*ja-JP*" }
    if ($capability -and $capability.State -eq "Installed") {
        Log "確認: 日本語言語パックは正常にインストールされています。"
    } else {
        Log "確認: 日本語言語パックが見つかりません、またはインストールに失敗しています。"
    }

    # 日本語をユーザー言語リストに追加（既存確認）
    $langList = Get-WinUserLanguageList
    if ($langList.LanguageTag -notcontains "ja-JP") {
        $langList.Add("ja-JP")
        Set-WinUserLanguageList $langList -Force
        Log "ユーザー言語リストに日本語追加"
    } else {
        Log "日本語は既にユーザー言語リストに存在"
    }

    # 表示言語に日本語を設定
    Set-WinUILanguageOverride -Language "ja-JP"
    Set-WinSystemLocale -SystemLocale "ja-JP"
    Set-Culture -CultureInfo "ja-JP"
    Set-WinHomeLocation -GeoId 122

    Log "日本語表示設定適用完了"
} catch {
    Log "エラー発生: $($_.Exception.Message)"
}

Log "スクリプト実行完了。必要に応じて手動で[Settings] > [Time & Language] > [Language] から表示言語を日本語に設定してください。"
