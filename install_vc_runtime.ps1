$logPath = "C:\Users\Public\install_vc_runtime_log.txt"

function Write-Log {
    param (
        [string]$message,
        [string]$level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp [$level] $message"
    Write-Host $entry
    Add-Content -Path $logPath -Value $entry
}

function Run-Step {
    param (
        [string]$stepName,
        [scriptblock]$action
    )
    Write-Log "$stepName..."
    $start = Get-Date
    try {
        & $action
        $duration = (Get-Date) - $start
        Write-Log "$stepName completed in $($duration.TotalSeconds) seconds."
    } catch {
        $duration = (Get-Date) - $start
        Write-Log "Failed: $stepName - $_ (after $($duration.TotalSeconds) seconds)" "ERROR"
    }
}

# =============================
Run-Step "Downloading VC++ Redistributable 2015-2022 (x64)" {
    $url = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
    $dest = "C:\Windows\Temp\vc_redist.x64.exe"
    Invoke-WebRequest -Uri $url -OutFile $dest
}

Run-Step "Installing VC++ Redistributable silently" {
    $exePath = "C:\Windows\Temp\vc_redist.x64.exe"
    Start-Process -FilePath $exePath -ArgumentList "/install", "/quiet", "/norestart" -Wait
    Remove-Item $exePath -Force
}

Write-Log "VC++ Runtime installation script completed."
