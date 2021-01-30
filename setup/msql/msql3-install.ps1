# Logging
Start-Transcript -Append -Path C:\setup.log
Set-PSDebug -Strict # -Trace 2
Write-Host "Running msql3-install ..."

# SQL Server 2014 Express packages
$DownloadURLs = (
  # SQL Server 2014 Express
  'https://download.microsoft.com/download/2/A/5/2A5260C3-4143-47D8-9823-E91BB0121F94/SQLEXPR_x64_ENU.exe',

  ## Extra downloads:

  # Command-line Utilities 11 for SQL Server 2014 (not installed)
  'https://download.microsoft.com/download/5/5/B/55BEFD44-B899-4B54-ACD7-506E03142B34/1033/x64/MsSqlCmdLnUtils.msi',
  # Firefox (not installed)
  'https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US#/FirefoxSetup.exe',
  # SQL Server Management Studio (not installed)
  'https://aka.ms/ssmsfullsetup#/SSMS-Setup-ENU.exe'
)

# Download SQL Server packages
$PrereqDir = 'C:\setup\prereq'
Write-Host "Downloading SQL Server 2014 packages to ${PrereqDir} ..."

Import-Module BitsTransfer
$quiet = New-Item -ItemType directory -Path $PrereqDir -ErrorAction SilentlyContinue

foreach ($URL in $DownloadURLs) {
    $FileName = $URL.Split('/')[-1]
    $FilePath = "${PrereqDir}\${FileName}"

    try {
        if (Test-Path $FilePath) {
            Write-Host " + Already exists: ${FileName}"
            continue
        }
        $Client = New-Object System.Net.WebClient
        $Client.DownloadFile($URL, $FilePath)
        Write-Host " - Downloaded: ${FileName}"
    }
    catch {
        Write-Host " ! Error downloading: ${FileName}"
        Write-Error $_
        exit 1
    }
}

Write-Host "- Downloads complete"

# Install SQL Server 2014 Express
$SqlServerDir = 'C:\Program Files\Microsoft SQL Server\120'
$InstalledInstances = (Get-ItemProperty `
                           -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server' `
                           -Name InstalledInstances `
                           -ErrorAction SilentlyContinue)
if ((Test-Path $SqlServerDir) -and $InstalledInstances) {
    Write-Host "SQL Server already installed."
}
else {
    Write-Host "Extracting SQL Server 2014 ..."
    $SqlSetupDir = 'C:\Temp\sqlexpr'
    $quiet = New-Item -ItemType Directory -Path $SqlSetupDir -ErrorAction SilentlyContinue
    Start-Process "${PrereqDir}\SQLEXPR_x64_ENU.exe" -ArgumentList "/u /x:${SqlSetupDir}" -PassThru -Wait

    Write-Host "Installing SQL Server 2014 Express ..."
    $ConfigFile = 'C:\setup\SQLServerConfiguration.ini'
    $SetupArgs = "/ConfigurationFile=${ConfigFile} /IAcceptSQLServerLicenseTerms"
    $Cmd = (Start-Process "${SqlSetupDir}\setup.exe" -ArgumentList $SetupArgs -PassThru -Wait)
    $ExitCode = $Cmd.ExitCode
    if ($ExitCode -ne 0) {
        Write-Host "Setup failed with code ${ExitCode}!"
        exit 1
    }
}

# Install sqlcmd.exe for manual operations
msiexec.exe /i C:\setup\prereq\MsSqlCmdLnUtils.msi /quiet IACCEPTMSSQLCMDLNUTILSLICENSETERMS=YES

# Add Sharepoint Admin user to the local Administrators group
$AdminUser = 'spAdmin'
$DomainName = (Get-Content C:\setup\domain.txt -First 1).Trim()
$NetBiosName = ($DomainName -replace '[.].*','')
$DomainUser = "${NetBiosName}\${AdminUser}"
$DomainGroup = "${NetBiosName}\Domain Admins"

net localgroup Administrators $AdminUser /add
#net localgroup Administrators $DomainUser /add
#net localgroup Administrators "$DomainGroup" /add

# Run script on next logon
$RunOnce = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
Set-ItemProperty -Path $RunOnce -Name 'SQL-Init' -Value 'C:\Windows\System32\cmd.exe /c C:\setup\msql4-init.bat'

# Reboot and continue
Write-Host "- SQL Server installed"
Start-Sleep -Seconds 5
Restart-Computer -Force
