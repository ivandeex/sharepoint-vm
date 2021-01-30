# Logging
Start-Transcript -Append -Path C:\setup.log
Set-PSDebug -Strict # -Trace 2
Write-Host "Running spap2-join2 ..."

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
    Write-Host "Retry joining AD domain (attempt $i) ..."
    Add-Computer -DomainName $DomainName -OUPath $OUPath -Credential $Credential `
                 -Options AccountCreate -Restart -ErrorAction Continue
    Start-Sleep -Seconds 10
}

# Failed to join. Abort sequence.
Write-Host "Failed to join Domain. STOP!"
Remove-ItemProperty -Path $RunOnce -Name 'SP-Deps'
