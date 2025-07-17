# ログ出力用（BOM付き）
function Log($msg) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp`t$msg" | Out-File -FilePath "C:\win_langpack_setup.log" -Encoding utf8 -Append
}

try {
    Log "言語パックインストール開始"

    Set-Service wuauserv -StartupType Automatic
    Start-Service wuauserv

    Add-WindowsCapability -Online -Name Language.Basic~~~ja-JP~0.0.1.0
    Add-WindowsCapability -Online -Name Language.Pack~~~ja-JP~0.0.1.0

    Set-WinUILanguageOverride -Language "ja-JP"
    Set-WinSystemLocale -SystemLocale "ja-JP"
    Set-Culture -CultureInfo "ja-JP"
    Set-WinHomeLocation -GeoId 122

    Log "言語パックと基本設定適用完了"

    Log "ユーザー言語リスト確認と追加"
    $LangList = Get-WinUserLanguageList
    if ($LangList.LanguageTag -notcontains "ja-JP") {
        $LangList.Add("ja-JP")
        Set-WinUserLanguageList $LangList -Force
        Log "日本語をユーザー言語リストに追加"
    } else {
        Log "日本語はすでにユーザー言語リストに含まれています"
    }

    Log "言語設定完了"
} catch {
    Log "エラー発生: $($_.Exception.Message)"
}
