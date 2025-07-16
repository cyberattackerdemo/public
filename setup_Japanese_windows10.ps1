# ログ出力
$logFile = "C:\win_langpack_setup.log"
function Log($msg) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp`t$msg"
}

try {
    Log "日本語言語パックのインストール開始"

    Set-Service -Name wuauserv -StartupType Automatic
    Start-Service wuauserv

    Add-WindowsCapability -Online -Name Language.Basic~~~ja-JP~0.0.1.0

    Set-WinUILanguageOverride -Language "ja-JP"
    Set-WinUserLanguageList -LanguageList "ja-JP" -Force
    Set-WinSystemLocale -SystemLocale "ja-JP"
    Set-Culture -CultureInfo "ja-JP"
    Set-WinHomeLocation -GeoId 122

    Log "日本語言語パックと表示設定適用完了"
} catch {
    Log "エラー発生: $($_.Exception.Message)"
}

try {
    Log "日本語ユーザー言語リストを作成・適用"
    $LangList = New-WinUserLanguageList ja-JP
    Set-WinUserLanguageList $LangList -Force
    Log "ユーザー言語リスト設定完了"
} catch {
    Log "ユーザー言語リスト設定エラー: $($_.Exception.Message)"
}
