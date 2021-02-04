# Logging
Start-Transcript -Append -Path C:\setup.log
Set-PSDebug -Strict # -Trace 2
Write-Host "Running spap3-download ..."

# Sharepoint Server 2016 RTM packages
$DownloadURLs = (
  # SQL ODBC
  "https://download.microsoft.com/download/5/7/2/57249A3A-19D6-4901-ACCE-80924ABEB267/ENU/x64/msodbcsql.msi",
  # SQL CLI
  "https://download.microsoft.com/download/B/E/D/BED73AAC-3C8A-43F5-AF4F-EB4FEA6C8F3A/ENU/x64/sqlncli.msi",
  # Microsoft Sync Framework Runtime v1.0 SP1 (x64)
  "https://download.microsoft.com/download/E/0/0/E0060D8F-2354-4871-9596-DC78538799CC/Synchronization.msi",
  # Windows Server AppFabric 1.1
  "https://download.microsoft.com/download/A/6/7/A678AB47-496B-4907-B3D4-0A2D280A13C0/WindowsServerAppFabricSetup_x64.exe",
  # Cumulative Update 7 for Microsoft AppFabric 1.1 for Windows Server
  "https://download.microsoft.com/download/F/1/0/F1093AF6-E797-4CA8-A9F6-FC50024B385C/AppFabric-KB3092423-x64-ENU.exe",
  # Microsoft Information Protection and Control Client
  "https://download.microsoft.com/download/3/C/F/3CF781F5-7D29-4035-9265-C34FF2369FA2/setup_msipc_x64.exe",
  # Microsoft Identity Extensions
  "https://download.microsoft.com/download/0/1/D/01D06854-CA0C-46F1-ADBA-EBF86010DCC6/rtm/MicrosoftIdentityExtensions-64.msi",
  # Microsoft WCF Data Services 5.6
  "https://download.microsoft.com/download/1/C/A/1CAA41C7-88B9-42D6-9E11-3C655656DAB1/WcfDataServices.exe",
  # Visual C++ Redistributable Package for Visual Studio 2015
  "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe",
  # Another visual C++ Redistributable Package for Visual Studio 2013/2012
  "https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x64.exe",
  # Update for Microsoft .NET Framework to disable RC4 in Transport Layer Security
  "https://download.microsoft.com/download/6/F/9/6F9673B1-87D1-46C4-BF04-95F24C3EB9DA/enu_netfx/Windows8_1-KB3045563-x64_msu/Windows8.1-KB3045563-x64.msu",
  # .NET framework 4.6
  "https://download.microsoft.com/download/C/3/A/C3A5200B-D33C-47E9-9D70-2F7C65DAAD94/NDP46-KB3045557-x86-x64-AllOS-ENU.exe",
  # KB3115299 - fixes New-SPCConfigurationDatabase failure getting SPFarm user from AD: RPC server is unavailable
  "https://download.microsoft.com/download/2/6/A/26A556BB-81B8-4946-98E7-60E3AEDEB841/sts2016-kb3115299-fullfile-x64-glb.exe",

  ## Extra downloads:

  # Command-line Utilities 11 for SQL Server 2014 (not installed)
  "https://download.microsoft.com/download/5/5/B/55BEFD44-B899-4B54-ACD7-506E03142B34/1033/x64/MsSqlCmdLnUtils.msi",
  # Firefox (not installed)
  "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US#/FirefoxSetup.exe",

  # Silverlight
  #"http://silverlight.dlservice.microsoft.com/download/F/8/C/F8C0EACB-92D0-4722-9B18-965DD2A681E9/30514.00/Silverlight_x64.exe",
  # Exchange Web Services Managed API, version 1.2
  #"https://download.microsoft.com/download/7/6/1/7614E07E-BDB8-45DD-B598-952979E4DA29/EwsManagedApi.msi",
  # Windows Identity Foundation (KB974405)
  #"http://download.microsoft.com/download/D/7/2/D72FD747-69B6-40B7-875B-C2B40A6B2BDD/Windows6.1-KB974405-x64.msu",
  # Update for Windows 8.1 for x64-based Systems (KB2919442), a prerequisite for the Windows Server 2012 R2 Update
  #"https://download.microsoft.com/download/C/F/8/CF821C31-38C7-4C5C-89BB-B283059269AF/Windows8.1-KB2919442-x64.msu",
  # Windows Server 2012 R2 Update (KB2919355)
  #"https://download.microsoft.com/download/2/5/6/256CCCFB-5341-4A8D-A277-8A81B21A1E35/clearcompressionflag.exe",
  # Windows Server 2012 R2 Windows8.1-KB2919355-x64.msu 
  #"https://download.microsoft.com/download/2/5/6/256CCCFB-5341-4A8D-A277-8A81B21A1E35/Windows8.1-KB2919355-x64.msu",
  # Windows Server 2012 R2 Windows8.1-KB2932046-x64.msu
  #"https://download.microsoft.com/download/2/5/6/256CCCFB-5341-4A8D-A277-8A81B21A1E35/Windows8.1-KB2932046-x64.msu",
  # Windows Server 2012 R2 Windows8.1-KB2934018-x64.msu
  #"https://download.microsoft.com/download/2/5/6/256CCCFB-5341-4A8D-A277-8A81B21A1E35/Windows8.1-KB2934018-x64.msu",
  # Windows Server 2012 R2 Windows8.1-KB2937592-x64.msu
  #"https://download.microsoft.com/download/2/5/6/256CCCFB-5341-4A8D-A277-8A81B21A1E35/Windows8.1-KB2937592-x64.msu",
  # Windows Server 2012 R2 Windows8.1-KB2938439-x64.msu
  #"https://download.microsoft.com/download/2/5/6/256CCCFB-5341-4A8D-A277-8A81B21A1E35/Windows8.1-KB2938439-x64.msu",
  # Windows Server 2012 R2 Windows8.1-KB2959977-x64.msu
  #"https://download.microsoft.com/download/2/5/6/256CCCFB-5341-4A8D-A277-8A81B21A1E35/Windows8.1-KB2959977-x64.msu",

  # Sharepoint Image (large download)
  "https://download.microsoft.com/download/0/0/4/004EE264-7043-45BF-99E3-3F74ECAE13E5/officeserver.img"
)

# Download Sharepoint packages
$PrereqDir = 'C:\setup\prereq'
Write-Host "Downloading Sharepoint 2016 packages to ${PrereqDir} ..."

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

# Add Sharepoint Admin user to the local Administrators group
$AdminUser = 'spAdmin'
$DomainName = (Get-Content C:\setup\domain.txt -First 1).Trim()
$NetBiosName = ($DomainName -replace '[.].*','')
$DomainUser = "${NetBiosName}\${AdminUser}"
$DomainGroup = "${NetBiosName}\Domain Admins"

net localgroup Administrators $AdminUser /add
#net localgroup Administrators $DomainUser /add
#net localgroup Administrators "$DomainGroup" /add

# Disable UAC
$quiet = New-ItemProperty `
            -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system `
            -Name EnableLUA `
            -Value 0 -PropertyType DWord -Force

# Run next steps as SQL Admin user in AD Domain
$PlainPass = (Get-Content C:\setup\pass.txt -First 1).Trim()
$RegPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
Set-ItemProperty $RegPath 'DefaultUsername' -Value $AdminUser -Type String
Set-ItemProperty $RegPath 'DefaultPassword' -Value $PlainPass -Type String
Set-ItemProperty $RegPath 'DefaultDomainName' -Value $NetBiosName -Type String

# Run script on next logon
$RunOnce = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
Set-ItemProperty -Path $RunOnce -Name 'SP-Baseline' -Value 'C:\Windows\System32\cmd.exe /c C:\setup\spap4-features.bat'

# Reboot and continue
Write-Host "- Sharepoint packages downloaded"
Start-Sleep -Seconds 5
Restart-Computer -Force
