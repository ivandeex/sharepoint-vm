# Logging
Start-Transcript -Append -Path C:\setup.log
Set-PSDebug -Strict # -Trace 2
Write-Host "Running addc3-users ..."

# Parameters
$OrgUnit = 'UsersSP2016'
$DomainName = (Get-Content C:\setup\domain.txt -First 1).Trim()
$DomainPath = (($DomainName -split '[.]' | %{ "DC=$_" }) -join ',')
$OUPath = "OU=${OrgUnit},${DomainPath}"

$PlainPass = (Get-Content C:\setup\pass.txt -First 1).Trim()
$SecurePass = (ConvertTo-SecureString $PlainPass -AsPlaintext -Force)

Import-Module ActiveDirectory

New-ADOrganizationalUnit `
    -Path $DomainPath `
    -Name $OrgUnit `
    -ProtectedFromAccidentalDeletion:$false

$NewUsers = @{
    'spAdmin'   = 'SharePoint Setup Account'
    'sqlSvcAcc' = 'SQL Server Service Account'
    'spFarmAcc' = 'SharePoint Farm Account'
    'spAppPool' = 'SharePoint Application Pool Account'
}

foreach ($User in $NewUsers.Keys) {
    New-ADUser `
        -Path $OUPath `
        -Name $User `
        -AccountPassword $SecurePass `
        -Description $NewUsers.$User `
        -ChangePasswordAtLogon:$false `
        -CannotChangePassword:$true `
        -PasswordNeverExpires:$true `
        -Enabled:$true
}

Add-ADGroupMember 'Domain Admins' 'spAdmin'

# Disable Autologon
$RegPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
Remove-ItemProperty -Path $RegPath -Name 'ForceAutoLogon'
Remove-ItemProperty -Path $RegPath -Name 'AutoAdminLogon'
Remove-ItemProperty -Path $RegPath -Name 'AutoLogonCount'
Remove-ItemProperty -Path $RegPath -Name 'DefaultUsername'
Remove-ItemProperty -Path $RegPath -Name 'DefaultPassword'
Remove-ItemProperty -Path $RegPath -Name 'DefaultDomainName'

# All done!
Write-Host "Domain users added!"
Set-Content -Path C:\setup\done -Value done
Start-Sleep -Seconds 5
Restart-Computer -Force
