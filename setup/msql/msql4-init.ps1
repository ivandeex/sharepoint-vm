# Logging
Start-Transcript -Append -Path C:\setup.log
Set-PSDebug -Strict # -Trace 2
Write-Host "Running msql4-init ..."

# Variables

$AdminUser = 'spAdmin'
$Server = $env:COMPUTERNAME
$DomainName = (Get-Content C:\setup\domain.txt -First 1).Trim()
$NetBiosName = ($DomainName -replace '[.].*','')
$DomainUser = "${NetBiosName}\${AdminUser}"
$PlainPass = (Get-Content C:\setup\pass.txt -First 1).Trim()

# Enable TCP protocol in SQL Server
$quiet = [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SqlWmiManagement')
$SrvWMI = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $Server
$SrvTCP = $SrvWMI.ServerInstances['MSSQLSERVER'].ServerProtocols['Tcp']
if (! $SrvTCP.IsEnabled) {
    Write-Host "Enabling TCP in SQL Server ..."
    $SrvTCP.IsEnabled = $true
    $SrvTCP.Alter()
}
else {
    Write-Host "TCP is already enabled in SQL Server."
}

# Open DB Engine port in Windows Firewall
netsh advfirewall firewall add rule `
      name="Open SQL Server Port 1433" `
      dir=in action=allow `
      protocol=TCP localport=1433

# Function to Add User and Role
function Add-SQLAccountToSQLRole ([String]$Server, [String]$Username, [String]$Password, [String]$Role)
{
    Write-Host "- Add SQL user '${Username}' with role '${Role}'"
    $quiet = [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo')
    $Srv = New-Object Microsoft.SqlServer.Management.Smo.Server $Server

    # Check if Role entered Correctly
    $SrvRole = $Srv.Roles[$Role]
    if ($SrvRole -eq $null) {
        Write-Host " $Role is not a valid Role on $Server"
        return
    }

    # Check if User already exists
    $SrvUser = (New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login $Server,$Username)
    if (! $Srv.Logins.Contains($Username)) {
        $SrvUser.LoginType = 'WindowsUser'
        $SrvUser.PasswordExpirationEnabled = $false
        $SrvUser.Create($Password)
    }

    # Add User to Role
    if ($Role -notcontains 'public') {
        $SrvRole.AddMember($SrvUser.Name)
    }
}

# Add User and Roles
Add-SQLAccountToSQLRole $Server $DomainUser $PlainPass 'dbcreator'
Add-SQLAccountToSQLRole $Server $DomainUser $PlainPass 'securityadmin'
Add-SQLAccountToSQLRole $Server $DomainUser $PlainPass 'sysadmin'

# Disable IE Enhanced Security for Admin and User
Set-ItemProperty `
    -Path 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' `
    -Name 'IsInstalled' -Value 0 -Force
Set-ItemProperty `
    -Path 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' `
    -Name 'IsInstalled' -Value 0 -Force

# Disable Autologon
$RegPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
Remove-ItemProperty -Path $RegPath -Name 'ForceAutoLogon'
Remove-ItemProperty -Path $RegPath -Name 'AutoAdminLogon'
Remove-ItemProperty -Path $RegPath -Name 'AutoLogonCount'
Remove-ItemProperty -Path $RegPath -Name 'DefaultUsername'
Remove-ItemProperty -Path $RegPath -Name 'DefaultPassword'
Remove-ItemProperty -Path $RegPath -Name 'DefaultDomainName'

# All done!
Write-Host "SQL Server configured!"
Start-Sleep -Seconds 5
Restart-Computer -Force
