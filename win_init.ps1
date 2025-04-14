# Microsoft Defenderのリアルタイム保護を無効化
Set-MpPreference -DisableRealtimeMonitoring $true

# Windowsファイアウォールを無効化
netsh advfirewall set allprofiles state off

# Wordマクロ警告のレジストリ設定
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Word' -Force | Out-Null
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Word\Security' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Word\Security' -Name 'VBAWarnings' -PropertyType DWord -Value 1 -Force

# Chromeのインストーラを取得
Invoke-WebRequest -Uri 'https://dl.google.com/chrome/install/latest/chrome_installer.exe' -OutFile 'C:\chrome_installer.exe'

# Chromeをサイレントインストール + ログ出力
Start-Process -FilePath 'C:\chrome_installer.exe' -ArgumentList '/silent /install /log C:\chrome_install_log.txt' -Wait

# Chromeインストーラを削除
Remove-Item 'C:\chrome_installer.exe'

# 既定のブラウザをGoogle Chromeに設定（Edgeの既定解除も含む）
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (Test-Path $chromePath) {
    Start-Process "$chromePath" -ArgumentList "--make-default-browser" -Wait
}
