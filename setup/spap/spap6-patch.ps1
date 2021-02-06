# Logging
Start-Transcript -Append -Path C:\setup.log
Set-PSDebug -Strict # -Trace 2
Write-Host "Running spap6-patch ..."

if (Test-Path C:\setup\patched) {
    Write-Host "Sharepoint already patched"
    exit 0
}

$PrereqDir = 'C:\setup\prereq'

# Install KB3115299 to fix New-SPConfigurationDatabase error getting farm user from AD: RPC server is unavailable
Write-Host "Patching Sharepoint ..."
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

# Reboot and continue
Write-Host "- SharePoint Server patched successfully"
Set-Content -Path C:\setup\patched -Value patched
Start-Sleep -Seconds 5
Restart-Computer -Force
