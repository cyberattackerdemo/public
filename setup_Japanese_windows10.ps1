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

    $LangList = Get-WinUserLanguageList
    if ($LangList.LanguageTag -notcontains "ja-JP") {
        $LangList.Add("ja-JP")
        Set-WinUserLanguageList $LangList -Force
    }

    Log "言語設定完了"
} catch {
    Log "エラー発生: $($_.Exception.Message)"
}
