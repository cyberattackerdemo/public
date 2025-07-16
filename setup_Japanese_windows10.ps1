$logPath = "C:\win_lang_setup_transcript.txt"

try {
    Start-Transcript -Path $logPath -Append

    Write-Output "===== スクリプト開始 ====="

    # Windows Updateサービス有効化
    Write-Output "Windows Update サービスを有効化"
    Set-Service -Name wuauserv -StartupType Automatic
    Start-Service wuauserv

    # 日本語言語パックインストール
    Write-Output "日本語言語パックをインストール"
    Add-WindowsCapability -Online -Name "Language.Basic~~~ja-JP~0.0.1.0"

    # ユーザーの言語設定
    Write-Output "ユーザーの言語設定 (Set-WinUserLanguageList)"
    Set-WinUserLanguageList -LanguageList ja-JP -Force

    # ロケール・文化・タイムゾーン
    Write-Output "システムロケール・カルチャ・タイムゾーン設定"
    Set-WinSystemLocale -SystemLocale ja-JP
    Set-Culture -CultureInfo ja-JP
    Set-WinHomeLocation -GeoId 0x7a
    Set-TimeZone -Id "Tokyo Standard Time"

    # 表示言語設定
    Write-Output "表示言語設定 (UI Language Override)"
    Set-WinUILanguageOverride -Language "ja-JP"

    # Defaultユーザーのキーボード設定変更
    Write-Output "Defaultユーザーのキーボードレイアウト設定"
    $HiveName = "DefaultUser"
    $HivePath = "HKU\$HiveName"
    $UserDatPath = "C:\Users\Default\NTUSER.DAT"

    if (Test-Path $UserDatPath) {
        & reg load $HivePath $UserDatPath
        & reg add "$HivePath\Keyboard Layout\Preload" /v 1 /t REG_SZ /d 00000411 /f
        & reg unload $HivePath
    } else {
        Write-Output "Defaultユーザーのレジストリが見つかりませんでした"
    }

    Write-Output "===== スクリプト完了 ====="

} catch {
    Write-Output "エラー発生: $($_.Exception.Message)"
} finally {
    Stop-Transcript
}
