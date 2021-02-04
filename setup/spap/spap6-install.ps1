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

# Install KB3115299 to fix New-SPConfigurationDatabase error getting farm user from AD: RPC server is unavailable
# FIXME: computer must be rebooted before patch!
Write-Host "Patching Sharepoint..."
$PatchExe = "${PrereqDir}\sts2016-kb3115299-fullfile-x64-glb.exe"
$Args = '/quiet /extract:C:\Temp'
$Cmd = Start-Process $PatchExe -ArgumentList $Args -PassThru -Wait

$Args = '/update C:\Temp\sts-x-none.msp /quiet'
$Cmd = Start-Process msiexec.exe -ArgumentList $Args -PassThru -Wait
$ExitCode = $Cmd.ExitCode
if ($ExitCode -ne 0) {
    Write-Host "Patch failed with code ${ExitCode}!"
    Start-Sleep -Seconds 15
    Restart-Computer -Force
    exit 1
}

# Install sqlcmd.exe for manual operations
Write-Host "Installing sqlcmd ..."
$Args = "/i ${PrereqDir}\MsSqlCmdLnUtils.msi /quiet IACCEPTMSSQLCMDLNUTILSLICENSETERMS=YES"
$Cmd = Start-Process msiexec.exe -ArgumentList $Args -PassThru -Wait

# Run script on next logon
$RunOnce = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
Set-ItemProperty -Path $RunOnce -Name 'SP-Farm' -Value 'C:\Windows\System32\cmd.exe /c C:\setup\spap7-farm.bat'

# Reboot and continue
Write-Host "- SharePoint Server 2016 installed"
Set-Content -Path C:\setup\installed -Value installed
Start-Sleep -Seconds 5
Restart-Computer -Force
