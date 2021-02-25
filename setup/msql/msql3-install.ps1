# Logging
Start-Transcript -Append -Path C:\setup.log
Set-PSDebug -Strict # -Trace 2
Write-Host "Running msql3-install ..."

# Check that joined AD
if (!(Test-Path C:\setup\join)) {
    Write-Host "Failed to join Domain. STOP!"
    exit 1
}

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

$ZipFile = 'C:\temp\prereq.zip'
try {
    $DropboxURL = (Get-Content C:\setup\dropbox_url.txt -First 1).Trim()
} catch {
    $DropboxURL = ""
}
Import-Module BitsTransfer
$quiet = New-Item -ItemType directory -Path $PrereqDir -ErrorAction SilentlyContinue

if ($DropboxURL -ne "") {
    if (!(Test-Path $ZipFile)) {
        $ZipURL = ($DropboxURL -split '[?]')[0] + '?dl=1'
        try {
            $Client = New-Object System.Net.WebClient
            $Client.DownloadFile($ZipURL, $ZipFile)
        }
        catch {
            Write-Host " ! Error downloading archive ${ZipURL}"
            Write-Error $_
            exit 1
        }
    }

    Write-Host "Extracting archive ..."
    $quiet = [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem")
    $Zip = [System.IO.Compression.ZipFile]::OpenRead($ZipFile)
    $Files = ($DownloadURLs | %{ $_.Split('/')[-1] })
    foreach ($Entry in $Zip.Entries.Where({ $_.Name -in $Files })) {
        $FileName = $Entry.Name
        Write-Host " - Extracting: ${FileName}"
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($Entry, "${PrereqDir}\${FileName}")
    }
    $Zip.Dispose()
}

foreach ($URL in $DownloadURLs) {
    $FileName = $URL.Split('/')[-1]
    $FilePath = "${PrereqDir}\${FileName}"

    if ($DropboxURL -ne "") {
        if (Test-Path $FilePath) {
            continue
        }
        Write-Host " ! Missing: ${FileName}"
        exit 1
    }

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
#Remote-Item $ZipFile -Force -ErrorAction SilentlyContinue

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
    $Action = New-ScheduledTaskAction -Execute "${SqlSetupDir}\setup.exe" -Argument $SetupArgs
    $TaskName = 'Install SQL Server'
    # Ensure highest privileges without interactive login
    $Principal = New-ScheduledTaskPrincipal `
                    -UserID 'NT AUTHORITY\SYSTEM' `
                    -LogonType ServiceAccount `
                    -RunLevel Highest
    $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(3)
    $Task = Register-ScheduledTask `
                    -TaskName $TaskName `
                    -Action $Action `
                    -Trigger $Trigger `
                    -Principal $Principal
    do {
        Start-Sleep -Seconds 10
        $ExitCode = (Get-ScheduledTaskInfo $TaskName).LastTaskResult
    } until ($ExitCode -ne 267009)

    if ($ExitCode -ne 0) {
        Write-Host "Setup failed with code ${ExitCode}!"
        exit 1
    }
    Unregister-ScheduledTask $TaskName -Confirm:$false
    Write-Host "Setup Successful"
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

# Enable Mixed (Windows and SQL) login mode
Set-ItemProperty `
    -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQLServer' `
    -Name 'LoginMode' -Value 2 -Type DWord -Force

# Reboot and continue
Write-Host "- SQL Server installed"
Start-Sleep -Seconds 10  # Wait a little more to fix AWS
Restart-Computer -Force
