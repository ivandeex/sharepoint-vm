# Logging
Start-Transcript -Append -Path C:\setup.log
Set-PSDebug -Strict # -Trace 2
Write-Host "Running spap7-farm ..."

# Parameters
$ServerName = 'spap'
$FarmAccName = 'spFarmAcc'

$DomainName = (Get-Content C:\setup\domain.txt -First 1).Trim()
$NetBiosName = ($DomainName -replace '[.].*','')
$FarmAcc = "${NetBiosName}\${FarmAccName}"

$ConfigDB = 'spFarmConfiguration'
$CentralAdminContentDB = 'spCentralAdministration'
$CentralAdminPort = '2016'
$DBServer = (Get-Content C:\setup\ip_msql.txt -First 1).Trim()

$PlainPass = (Get-Content C:\setup\pass.txt -First 1).Trim()
$SecurePass = (ConvertTo-SecureString $PlainPass -AsPlaintext -Force)
$CredFarmAcc = (New-Object System.Management.Automation.PsCredential $FarmAcc,$SecurePass)

# Verify that DC is accessible
Import-Module ActiveDirectory
$OK = 'FAIL'
foreach ($i in 1..10) {
    $getres = Get-ADUser -Identity $FarmAccName -ErrorAction SilentlyContinue
    if ((Test-Path variable:getres) -and $getres) {
        $OK = 'PASS'
        break
    }
    Write-Host "Waiting for AD to come up (attempt ${i})..."
    Start-Sleep -Seconds 10
}
Write-Host "Active Directory: ${OK}"
if ($OK -ne 'PASS') {
    exit 1
}
Start-Sleep -Seconds 2

#Write-Host "Dropping old content, if any."
#sqlcmd.exe -S $DBServer -U $DBAdmin -P $PlainPass -i C:\setup\dropdb.sql

# Setup SharePoint

Write-Host " - Enabling Sharepoint Powershell commandlets..."
$snapin = (Get-PSSnapin 'Microsoft.SharePoint.PowerShell' -ErrorAction SilentlyContinue)
if (!$snapin) {
    Add-PSSnapin Microsoft.SharePoint.PowerShell
}

Start-SPAssignment -Global

Write-Host " - Creating configuration database......"
New-SPConfigurationDatabase `
    -DatabaseName $ConfigDB `
    -DatabaseServer $DBServer `
    -AdministrationContentDatabaseName $CentralAdminContentDB `
    -Passphrase $SecurePass `
    -FarmCredentials $CredFarmAcc `
    -LocalServerRole 'Custom' `
    -ErrorAction Stop `
    -Verbose

Write-Host " - Installing Help Collection..."
Install-SPHelpCollection -All

Write-Host " - Securing Resources..."
Initialize-SPResourceSecurity

Write-Host " - Installing Services..."
Install-SPService

Write-Host " - Installing Features......"
$Features = (Install-SPFeature -AllExistingFeatures -Force)

Write-Host " - Creating Central Admin..."
$NewCentralAdmin = (New-SPCentralAdministration -Port $CentralAdminPort -WindowsAuthProvider 'NTLM')

Write-Host " - Installing Application Content..."
Install-SPApplicationContent

Stop-SPAssignment -Global

# At this point we have a basic farm installed,
# no service applications installed yet,
# but based on this then you can move on and
# install the service applicacions depending on
# the server role you will deploy.

# Creating a self-signed cert...
$ServerFQDN = "${ServerName}.${DomainName}"
New-SelfSignedCertificate `
    -DNSName $ServerFQDN `
    -CertStoreLocation cert:Localmachine\My

# TODO CSR creation for prod
$DC = 'addc'
$DomainName = (Get-Content C:\setup\domain.txt -First 1).Trim()
$NetBiosName = ($DomainName -replace '[.].*','')
$UpperDC = $DC.ToUpper()
$RootCA = "ldap:${DC}.${DomainName}\${NetBiosName}-${UpperDC}-CA"

# Run script on next logon
$RunOnce = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
Set-ItemProperty -Path $RunOnce -Name 'SP-Post' -Value 'C:\Windows\System32\cmd.exe /c C:\setup\spap8-apps.bat'

# Reboot and continue
Write-Host "- Farm Created."
Start-Sleep -Seconds 5
Restart-Computer -Force
