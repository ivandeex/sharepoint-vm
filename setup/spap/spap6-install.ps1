# Logging
Start-Transcript -Append -Path C:\setup.log
Set-PSDebug -Strict # -Trace 2
Write-Host "Running spap6-install ..."

if (Test-Path C:\setup\installed) {
    Write-Host "Sharepoint already installed"
    exit 0
}

$PrereqDir = 'C:\setup\prereq'
$ConfigXML = 'C:\setup\sp_config.xml'

# Mount ISO
$ImagePath = "${PrereqDir}\officeserver.img"
$Mount = Mount-DiskImage -ImagePath $ImagePath -PassThru
$Drive = $Mount | Get-Volume
$DriveLetter = $Drive.DriveLetter

# Install Sharepoint
Write-Host "Installing Sharepoint ..."
$SetupExe = "${DriveLetter}:\setup.exe"
$Args = "/config $ConfigXML"
$Cmd = Start-Process $SetupExe -ArgumentList $Args -PassThru -Wait
$ExitCode = $Cmd.ExitCode
if ($ExitCode -ne 0) {
    Write-Host "Sharepoint setup failed with code ${ExitCode}!"
    Start-Sleep -Seconds 15
    Restart-Computer -Force
    exit 1
}

# Reboot and continue
Write-Host "- SharePoint Server 2016 installed"
Set-Content -Path C:\setup\installed -Value installed
Start-Sleep -Seconds 5
Restart-Computer -Force
