# Microsoft Identity Verification Root Certificate Authority 2020 の URL
$certUrl = "http://www.microsoft.com/pkiops/certs/Microsoft%20Identity%20Verification%20Root%20Certificate%20Authority%202020.cer"
$certPath = "$env:TEMP\MicrosoftIdentityVerificationRoot2020.cer"

Write-Host "Downloading certificate from: $certUrl"
Invoke-WebRequest -Uri $certUrl -OutFile $certPath -UseBasicParsing

Write-Host "Importing certificate into LocalMachine Root store..."
Import-Certificate -FilePath $certPath -CertStoreLocation "Cert:\LocalMachine\Root"

Write-Host "Import complete. Cleaning up temp file..."
Remove-Item $certPath -Force
