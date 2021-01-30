# Logging
Start-Transcript -Append -Path C:\setup.log
Set-PSDebug -Strict # -Trace 2
Write-Host "Running spap5-prereq ..."

# Run script on next logon
$RunOnce = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
Set-ItemProperty -Path $RunOnce -Name 'SP-Install' -Value 'C:\Windows\System32\cmd.exe /c C:\setup\spap6-install.bat'

# Mount ISO
$PrereqDir = 'C:\setup\prereq'
$ImagePath = "${PrereqDir}\officeserver.img"
$mount = Mount-DiskImage -ImagePath $ImagePath -PassThru
$drive = $mount | Get-Volume
$letter = $drive.DriveLetter

# Install prerequisites
$Installer = "${letter}:\PrerequisiteInstaller.exe"
$Method = 1
if ($Method -eq 1) {
    cmd /c $Installer /unattended `
        /SQLNCli:${PrereqDir}\sqlncli.msi `
        /idfx11:${PrereqDir}\MicrosoftIdentityExtensions-64.msi `
        /Sync:${PrereqDir}\Synchronization.msi `
        /AppFabric:${PrereqDir}\WindowsServerAppFabricSetup_x64.exe `
        /kb3092423:${PrereqDir}\AppFabric-KB3092423-x64-ENU.exe `
        /MSIPCClient:${PrereqDir}\setup_msipc_x64.exe `
        /wcfdataservices56:${PrereqDir}\WcfDataServices.exe `
        /odbc:${PrereqDir}\msodbcsql.msi `
        /msvcrt11:${PrereqDir}\vc_redist.x64.exe `
        /msvcrt14:${PrereqDir}\vcredist_x64.exe `
        /dotnetfx:${PrereqDir}\NDP46-KB3045557-x86-x64-AllOS-ENU.exe
    Write-Host "- Prereq1 Complete"
}
if ($Method -eq 2) {
    Start-Process `
        -FilePath $Installer -ArgumentList '/unattended' `
        -Wait -PassThru
    Write-Host "- Prereq2 complete"
}

# Reboot and continue
Start-Sleep -Seconds 5
Restart-Computer -Force
