# Install AWS CLI v2 on Windows (run this in an elevated PowerShell)
# Usage: Run PowerShell as Administrator and execute:
#   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
#   .\install_aws_cli.ps1

param(
    [string]$OutputPath = "$env:TEMP\AWSCLIV2.msi"
)

Write-Host "Downloading AWS CLI v2 installer to $OutputPath"

try {
    # Use TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Invoke-WebRequest -Uri 'https://awscli.amazonaws.com/AWSCLIV2.msi' -OutFile $OutputPath -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Error "Failed to download installer: $_"
    exit 1
}

Write-Host "Running installer (requires admin). This may prompt for elevation and take a few minutes..."

$msi = $OutputPath
$arguments = "/i `"$msi`""

# Launch the installer with GUI so UAC prompt appears. If silent install is desired, use /qn instead of /i
Start-Process -FilePath msiexec.exe -ArgumentList $arguments -Wait

Write-Host "Installer finished. Verifying installation..."

try {
    $ver = & aws --version 2>&1
    Write-Host "aws --version output: $ver"
} catch {
    Write-Warning "aws CLI not found in PATH after install. You may need to log out and log back in, or ensure C:\\Program Files\\Amazon\\AWSCLIV2\\ is in your PATH."
}

Write-Host "If aws is not available, try restarting PowerShell or your machine."
