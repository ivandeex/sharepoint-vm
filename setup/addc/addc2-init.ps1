# Logging
Start-Transcript -Append -Path C:\setup.log
Set-PSDebug -Strict # -Trace 2
Write-Host "Running addc2-init ..."

# DomainMode / ForestMode:
#   Server 2003: 2 or Win2003
#   Server 2008: 3 or Win2008
#   Server 2008 R2: 4 or Win2008R2
#   Server 2012: 5 or Win2012
#   Server 2012 R2: 6 or Win2012R2

$DomainMode = 'Win2012R2'
$ForestMode = 'Win2012R2'

$DomainName = (Get-Content C:\setup\domain.txt -First 1).Trim()
$NetBiosName = ($DomainName -replace '[.].*','')

$PlainPass = (Get-Content C:\setup\pass.txt -First 1).Trim()
$SecurePass = (ConvertTo-SecureString $PlainPass -AsPlaintext -Force)

# Run script on next logon
$RunOnce = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
Set-ItemProperty -Path $RunOnce -Name 'AD-Users' -Value 'C:\Windows\System32\cmd.exe /c C:\setup\addc3-users.bat'

# Install Active Directory
Write-Host "Windows Server 2012 R2 - Active Directory Installation"

Write-Host " - Installing AD-Domain-Services..."
Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools

Import-Module ADDSDeployment

Write-Host " - Creating new AD-Domain-Services Forest..."
Install-ADDSForest `
    -CreateDNSDelegation:$false `
    -SafeModeAdministratorPassword $SecurePass `
    -DomainName $DomainName `
    -DomainMode $DomainMode `
    -ForestMode $ForestMode `
    -DomainNetBiosName $NetBiosName `
    -InstallDNS:$true `
    -Confirm:$false

# Reboot as requested by Install-Forest
Write-Host " - Forest Done. Rebooting."
Start-Sleep -Seconds 5
# Restart was requested above
