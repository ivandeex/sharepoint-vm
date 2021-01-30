# Logging
Start-Transcript -Append -Path C:\setup.log
Set-PSDebug -Strict # -Trace 2
Write-Host "Running spap8-apps ..."

# Parameters
$ServerName = 'spap'
$FarmAccName = 'spAdmin'

$DomainName = (Get-Content C:\setup\domain.txt -First 1).Trim()
$NetBiosName = ($DomainName -replace '[.].*','')
$FarmAcc = "${NetBiosName}\${FarmAccName}"

$SharepointDir = (Get-Content C:\setup\sp_dir.txt -First 1).Trim()
$SearchIndexPath = "${SharepointDir}\Index"

$PlainPass = (Get-Content C:\setup\pass.txt -First 1).Trim()
$SecurePass = (ConvertTo-SecureString $PlainPass -AsPlaintext -Force)
$Credential = (New-Object System.Management.Automation.PSCredential $FarmAcc,$SecurePass)

$DBServer = (Get-Content C:\setup\ip_msql.txt -First 1).Trim()

$EnvName = $NetBiosName
$env:USERDNSDOMAIN = $DomainName

# Configure Sharepoint Applications

Write-Host "Enabling Sharepoint Powershell commandlets..."
$snapin = (Get-PSSnapin 'Microsoft.SharePoint.PowerShell' -ErrorAction SilentlyContinue)
if ($snapin -eq $null) {
    Add-PSSnapin Microsoft.SharePoint.PowerShell
}

$ManAcc = (Get-SPManagedAccount -Identity $FarmAcc -ErrorAction SilentlyContinue)
if (!$ManAcc) {
    Write-Host "Adding managed account..."
    $ManAcc = (New-SPManagedAccount -Credential $Credential)
}

$AppPool = (Get-SPServiceApplicationPool -Identity 'ApplicationPool' -ErrorAction SilentlyContinue)
if (!$AppPool) {
    Write-Host "Adding application pool..."
    $AppPool = (New-SPServiceApplicationPool -Name 'ApplicationPool' -Account $ManAcc.Username)
}

Write-Host "Adding service applications..."

$MetaSvcApp = Get-SPServiceApplication -Name 'MetadataServiceApp' -ErrorAction SilentlyContinue
if (!$MetaSvcApp) {
    Write-Host "Adding metadata app..."
    New-SPMetadataServiceApplication `
        -Name 'MetadataServiceApp' `
        -ApplicationPool $AppPool.Name `
        -DatabaseName 'sp.MetadataDB'
}

$SecureStoreApp = Get-SPServiceApplication -Name 'Secure Store' -ErrorAction SilentlyContinue
if (!$SecureStoreApp) {
    Write-Host "Adding secure store..."
    New-SPSecureStoreServiceApplication `
        -Name 'Secure Store' `
        -ApplicationPool $AppPool.Name `
        -AuditingEnabled:$false `
        -DatabaseServer $DBServer `
        -DatabaseName 'sp.SecureStore'
}

$StartSearchInstances = $true
if ($StartSearchInstances) {
    $Service1 = (Get-SPServiceInstance | where { $_.TypeName -match 'App Management Service' })
    Start-SPServiceInstance -Identity $Service1.ID

    $Service2 = (Get-SPServiceInstance | where { $_.TypeName -match 'Secure Store Service' })
    Start-SPServiceInstance -Identity $Service2.ID

    $Service3 = (Get-SPServiceInstance | where { $_.TypeName -match 'Microsoft SharePoint Foundation Subscription Settings Service' })
    Start-SPServiceInstance -Identity $Service3.ID

    Write-Host "Starting search service instances..."
    Start-SPEnterpriseSearchServiceInstance $ServerName
    Start-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance $ServerName
}

$SetupSearchService = $false
if ($SetupSearchService) {
    Write-Host "Creating Search Service..."

    $SearchServiceApp = New-SPEnterpriseSearchServiceApplication `
                            -Name 'Search Service Application'
                            -ApplicationPool $AppPool.name `
                            -DatabaseName 'sp.SearchService'
    $SearchProxy = New-SPEnterpriseSearchServiceApplicationProxy `
                       -Name "${ServiceAppName} Proxy" `
                       -SearchApplication $SearchServiceApp

    # Clone the default Topology (which is empty)
    # and create a new one and then activate it
    Write-Host "Configuring Search Component Topology..."

    $clone = $SearchServiceApp.ActiveTopology.Clone()
    $SearchServiceInstance = Get-SPEnterpriseSearchServiceInstance

    New-SPEnterpriseSearchAdminComponent `
        -SearchTopology $clone `
        -SearchServiceInstance `
        $SearchServiceInstance

    New-SPEnterpriseSearchContentProcessingComponent `
        -SearchTopology $clone `
        -SearchServiceInstance $SearchServiceInstance

    New-SPEnterpriseSearchAnalyticsProcessingComponent `
        -SearchTopology $clone `
        -SearchServiceInstance $SearchServiceInstance

    New-SPEnterpriseSearchCrawlComponent `
        -SearchTopology $clone `
        -SearchServiceInstance $SearchServiceInstance

    $SearchDirItem = (New-Item -ItemType directory -path $SearchIndexPath)

    New-SPEnterpriseSearchIndexComponent `
        -SearchTopology $clone `
        -SearchServiceInstance $SearchServiceInstance `
        -RootDirectory $SearchDirItem

    New-SPEnterpriseSearchQueryProcessingComponent `
        -SearchTopology $clone `
        -SearchServiceInstance $SearchServiceInstance

    $clone.Activate()
}

# Add web sites
$ConfigureTestSites = $true
if ($ConfigureTestSites) {
    Write-Host "Adding web applications ..."

    $WebName = 'TestWebApp'
    $WebHost = "${ServerName}.${DomainName}"
    $WebPort = 80
    $WebProto = 'http'
    $WebURL = "${WebProto}://${WebHost}"
    $ContentDBName = "spContent${WebName}"

    $IISPubRoot = 'C:\inetpub\wwwroot\wss\VirtualDirectories'
    $WebDir = "${IISPubRoot}\${WebHost}"
    $AuthProv = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication
    $WebAppPoolName = "${WebName}_AppPool"

    $WebApp = (Get-SPWebApplication -Identity $WebName -ErrorAction SilentlyContinue)
    if (!$WebApp) {
        Write-Host "Creating web application '${WebName}' at '${WebURL}' ..."

        Remove-SPWebApplication -Identity $WebName -Confirm:$false -ErrorAction SilentlyContinue
        Remove-Item -Path $WebDir -Recurse -ErrorAction SilentlyContinue
        if (Test-Path $WebDir) {
            Write-Host "Manually remove path: ${WebDir}"
            exit 1
        }

        # In case of "prefix busy" error, restart the IIS:
        # & iisreset

        $WebApp = New-SPWebApplication `
                      -ApplicationPool $WebAppPoolName `
                      -ApplicationPoolAccount $ManAcc `
                      -AuthenticationProvider $AuthProv `
                      -DatabaseServer $DBServer `
                      -DatabaseName $ContentDBName `
                      -DatabaseCredentials $CredDB `
                      -Name $WebName `
                      -Path $WebDir `
                      -HostHeader $WebHost `
                      -URL $WebURL `
                      -Port $WebPort
        if (!$WebApp) {
            exit 1
        }
    }

    $SitePath = '/sites/test'
    $SiteURL = "${WebURL}${SitePath}"
    $SiteName = "${WebName}_TestSite"

    $SiteObj = Get-SPSite -Identity $SiteURL -ErrorAction SilentlyContinue
    if (!$SiteObj) {
        Write-Host "Creating web site '${SiteName}' at '${SiteURL}' ..."
        $SiteObj = New-SPSite -URL $SiteURL -Name $SiteName -Template 'STS#0' -OwnerAlias $FarmAcc

        if (!$SiteObj) {
            exit 1
        }
    }

    Write-Host "Site URL: ${SiteURL}"
    Write-Host "Web User: ${FarmAcc}"
}

# Configure outgoing E-mail in SharePoint
$SetupOutgoingEmail = $false
if ($SetupOutgoingEmail) {
    Write-Host "Configuring outgoing e-mail..."
    $SMTPServer = "${EnvName}-ex01.${DomainName}"
    $FromEmail = "${EnvName}-sharepoint@${DomainName}"
    $ReplyEmail = "${EnvName}-reply@${DomainName}"
    $Charset = 65001

    try {
        $CAWebApp = Get-SPWebApplication -IncludeCentralAdministration | where { $_.IsAdministrationWebApplication }
        $CAWebApp.UpdateMailSettings($SMTPServer, $FromEmail, $ReplyEmail, $Charset)
        Write-Host -f Blue 'Outgoing e-mail configured'
    }
    catch [System.Exception] {
        Write-Host -f Red $_.Exception.ToString()
    }
}

# Assign AD Groups and permissions
# Use this to start mapping roles
# Disabled as I am not adding these users quite yet
$SetupADGroups = $false
if ($SetupADGroups) {
    $ADGroupName = "${DomainName}\${EnvName}-SP-Contribute"
    New-SPUser -UserAlias $ADGroupName -Web $SpSiteURL1 -PermissionLevel Contribute
    New-SPUser -UserAlias $ADGroupName -Web $SpSiteURL2 -PermissionLevel Contribute
    New-SPUser -UserAlias $ADGroupName -Web $SpSiteURL1 -PermissionLevel Read
}

# Disable IE Enhanced Security for Admin and User
Set-ItemProperty `
    -Path 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' `
    -Name 'IsInstalled' -Value 0 -Force
Set-ItemProperty `
    -Path 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' `
    -Name 'IsInstalled' -Value 0 -Force

# Disable Autologon
$RegPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
Remove-ItemProperty -Path $RegPath -Name 'ForceAutoLogon'
Remove-ItemProperty -Path $RegPath -Name 'AutoAdminLogon'
Remove-ItemProperty -Path $RegPath -Name 'AutoLogonCount'
Remove-ItemProperty -Path $RegPath -Name 'DefaultUsername'
Remove-ItemProperty -Path $RegPath -Name 'DefaultPassword'
Remove-ItemProperty -Path $RegPath -Name 'DefaultDomainName'

# All done!
Write-Host "Applications configured!"
Start-Sleep -Seconds 5
Restart-Computer -Force
