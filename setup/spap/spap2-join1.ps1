# Logging
Start-Transcript -Append -Path C:\setup.log
Set-PSDebug -Strict # -Trace 2
Write-Host "Running spap2-join1 ..."

# Point DNS servers to AD controller
$DNS = (Get-Content C:\setup\ip_addc.txt -First 1).Trim()
$DNS2 = '8.8.8.8'
$adapter = Get-NetAdapter | ?{ $_.Status -eq 'up' }
$adapter | Set-DnsClientServerAddress -ServerAddresses $DNS,$DNS2

# Credentials for Domain join
$OrgUnit = 'UsersSP2016'
$DomainName = (Get-Content C:\setup\domain.txt -First 1).Trim()
$DomainPath = (($DomainName -split '[.]' | %{ "DC=$_" }) -join ',')
$OUPath = "OU=${OrgUnit},${DomainPath}"

$AdminUser = 'spAdmin'
$NetBiosName = ($DomainName -replace '[.].*','')
$DomainUser = "${NetBiosName}\${AdminUser}"

$PlainPass = (Get-Content C:\setup\pass.txt -First 1).Trim()
$SecurePass = (ConvertTo-SecureString $PlainPass -AsPlainText -Force)
$Credential = (New-Object -TypeName System.Management.Automation.PSCredential `
                          -ArgumentList $DomainUser,$SecurePass)

# Run script on next logon
$RunOnce = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
Set-ItemProperty -Path $RunOnce -Name 'SP-Deps' -Value 'C:\Windows\System32\cmd.exe /c C:\setup\spap3-download.bat'

# Join computer to domain
foreach ($i in 1..2) {
    Write-Host "Join AD domain (attempt $i) ..."
    Add-Computer -DomainName $DomainName -OUPath $OUPath -Credential $Credential `
                 -Options AccountCreate -Restart -ErrorAction Continue
    Start-Sleep -Seconds 10
}

# Reboot and try again
Remove-ItemProperty -Path $RunOnce -Name 'SP-Deps'
Set-ItemProperty -Path $RunOnce -Name 'AD-Join' -Value 'C:\Windows\System32\cmd.exe /c C:\setup\spap2-join2.bat'

Write-Host "Failed to join, will try again after restart"
Start-Sleep -Seconds 5
Restart-Computer -Force
