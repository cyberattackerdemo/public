# ログ出力 (任意)
$logFile = "C:\win_langpack_setup.log"
function Log($msg) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp`t$msg"
}

try {
    Log "日本語言語パックのインストール開始"

    # Windows Updateサービスが有効か確認して有効化
    Set-Service -Name wuauserv -StartupType Automatic
    Start-Service wuauserv

    # 日本語言語パック + 基本機能のインストール
    Add-WindowsCapability -Online -Name Language.Basic~~~ja-JP~0.0.1.0

    Log "日本語言語パックのインストール完了"

    # 日本語を表示言語に設定
    Set-WinUILanguageOverride -Language "ja-JP"
    Set-WinUserLanguageList -LanguageList "ja-JP" -Force
    Set-WinSystemLocale -SystemLocale "ja-JP"
    Set-Culture -CultureInfo "ja-JP"
    Set-WinHomeLocation -GeoId 122

    Log "日本語表示設定適用完了"
} catch {
    Log "エラー発生: $($_.Exception.Message)"
}

