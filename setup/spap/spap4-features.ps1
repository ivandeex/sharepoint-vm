# Logging
Start-Transcript -Append -Path C:\setup.log
Set-PSDebug -Strict # -Trace 2
Write-Host "Running spap4-features ..."

# Install prerequisite Windows features for Sharepoint
Install-WindowsFeature `
  AS-Web-Support,`
  AS-TCP-Port-Sharing,`
  AS-WAS-Support,`
  AS-HTTP-Activation,`
  AS-TCP-Activation,`
  AS-Named-Pipes,`
  AS-Net-Framework,`
  NET-Framework-Core,`
  NET-Framework-Features,`
  NET-HTTP-Activation,`
  NET-Non-HTTP-Activ,`
  NET-WCF-HTTP-Activation45,`
  Server-Media-Foundation,`
  WAS,`
  WAS-Config-APIs,`
  WAS-NET-Environment,`
  WAS-Process-Model,`
  Web-App-Dev,`
  Web-Asp-Net,`
  Web-Asp-Net45,`
  Web-Common-Http,`
  Web-Default-Doc,`
  Web-Dir-Browsing,`
  Web-Http-Errors,`
  Web-Http-Logging,`
  Web-Http-Redirect,`
  Web-Http-Tracing,`
  Web-ISAPI-Ext,`
  Web-ISAPI-Filter,`
  Web-Health,`
  Web-Security,`
  Web-IP-Security,`
  Web-Log-Libraries,`
  Web-Net-Ext,`
  Web-Net-Ext45,`
  Web-Basic-Auth,`
  Web-Cert-Auth,`
  Web-Digest-Auth,`
  Web-Client-Auth,`
  Web-Default-Doc,`
  Web-Digest-Auth,`
  Web-URL-Auth,`
  Web-Windows-Auth,`
  Web-Filtering,`
  Web-Performance,`
  Web-Request-Monitor,`
  Web-Stat-Compression,`
  Web-Dyn-Compression,`
  Web-Mgmt-Compat,`
  Web-Mgmt-Console,`
  Web-Mgmt-Tools,`
  Web-Scripting-Tools,`
  Web-Lgcy-Scripting,`
  Web-Lgcy-Mgmt-Console,`
  Web-WMI,`
  Web-Metabase,`
  Web-Server,`
  Web-WebServer,`
  Web-Static-Content,`
  Application-Server,`
  Windows-Identity-Foundation,`
  RSAT-AD-PowerShell,`
  Desktop-Experience,`
  InkAndHandwritingServices,`
  Xps-Viewer

# Reboot and continue
Write-Host "- Windows Features installed"
Start-Sleep -Seconds 5
Restart-Computer -Force
