$logFile = "C:\win_langpack_setup.log"
function Log($msg) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestampt$msg"
}

try {
    Log "日本語言語パックのインストール開始"

    Set-Service -Name wuauserv -StartupType Automatic
    Start-Service wuauserv

    Add-WindowsCapability -Online -Name Language.Basic~~~ja-JP~0.0.1.0

    Log "日本語言語パックインストール完了"

    Set-WinUILanguageOverride -Language "ja-JP"
    Set-WinSystemLocale -SystemLocale "ja-JP"
    Set-Culture -CultureInfo "ja-JP"
    Set-WinHomeLocation -GeoId 122

    Log "日本語表示設定適用完了"
} catch {
    Log "エラー発生: $($_.Exception.Message)"
}

try {
    Log "既存ユーザー言語リスト確認と日本語追加"
    $LangList = Get-WinUserLanguageList
    if ($LangList.LanguageTag -notcontains "ja-JP") {
        $LangList.Add("ja-JP")
        Set-WinUserLanguageList $LangList -Force
        Log "日本語をユーザー言語リストに追加しました"
    } else {
        Log "日本語はすでにユーザー言語リストに含まれています"
    }
} catch {
    Log "ユーザー言語リスト設定エラー: $($_.Exception.Message)"
}