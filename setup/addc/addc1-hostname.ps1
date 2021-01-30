# Logging
Start-Transcript -Append -Path C:\setup.log
Set-PSDebug -Strict # -Trace 2
Write-Host "Running addc1-hostname ..."

# Configure Virtual IP
$ServerIP = (Get-Content C:\setup\ip_addc.txt -First 1).Trim()
$IPFound = (Get-NetIPConfiguration | ?{ $_.IPv4Address.IPAddress -eq $ServerIP })
if ($IPFound) {
    $Ethernet2 = $IPFound.InterfaceAlias
    Write-Host "IP already found on '${Ethernet2}'"
}
else {
    $IfAliases = (Get-NetIPConfiguration | %{ $_.InterfaceAlias } | Sort)
    $Ethernet2 = $IfAliases[-1]
    Write-Host "Configure IP ${ServerIP} on '${Ethernet2}'"
    $quiet = New-NetIPAddress -IPAddress $ServerIP -PrefixLength 24 -InterfaceAlias $Ethernet2
}

# Let test box ping us
netsh advfirewall firewall add rule name="Allow incoming ICMP" protocol=icmpv4 dir=in action=allow

# Configure Autologon
$RegPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
$PlainPass = (Get-Content C:\setup\pass.txt -First 1).Trim()
$AutoLoginUser = 'Administrator'
$AutoLoginPass = $PlainPass

Set-ItemProperty $RegPath 'ForceAutoLogon' -Value '1' -Type String
Set-ItemProperty $RegPath 'AutoAdminLogon' -Value '1' -Type String
Set-ItemProperty $RegPath 'AutoLogonCount' -Value '10' -Type DWord
Set-ItemProperty $RegPath 'DefaultUsername' -Value $AutoLoginUser -Type String
Set-ItemProperty $RegPath 'DefaultPassword' -Value $AutoLoginPass -Type String
Set-ItemProperty $RegPath 'DefaultDomainName' -Value '' -Type String

# Run script on next logon
$RunOnce = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
Set-ItemProperty -Path $RunOnce -Name 'AD-Init' -Value 'C:\Windows\System32\cmd.exe /c C:\setup\addc2-init.bat'

# Rename Computer
$ServerName = 'addc'
if ($env:COMPUTERNAME -ne $ServerName) {
    Rename-Computer -NewName $ServerName
}

# Reboot and continue
Write-Host "- Continue after reboot"
Start-Sleep -Seconds 5
Restart-Computer -Force
