# Logging
Start-Transcript -Append -Path C:\setup.log
Set-PSDebug -Strict # -Trace 2
Write-Host "Running spap1-hostname ..."

# Configure Virtual IP
$ServerIP = (Get-Content C:\setup\ip_spap.txt -First 1).Trim()
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

# Prevent error in New-SPConfigurationDatabase ("The RPC server is unavailable")
Set-NetIPInterface -InterfaceAlias $Ethernet2 -InterfaceMetric 1

# Let test box ping us
netsh advfirewall firewall add rule name="Allow incoming ICMP" protocol=icmpv4 dir=in action=allow

# Rename Computer
$ServerName = 'spap'
if ($env:COMPUTERNAME -ne $ServerName) {
    Rename-Computer -NewName $ServerName
}

# Reboot and continue
Write-Host "- Continue after reboot"
Start-Sleep -Seconds 5
Restart-Computer -Force
