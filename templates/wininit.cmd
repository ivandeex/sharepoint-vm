net user Administrator ${admin_password}
cmd /c winrm quickconfig -q
cmd /c winrm set winrm/config/service @{AllowUnencrypted="true"}
cmd /c winrm set winrm/config/service/auth @{Basic="true"}
cmd /c winrm set winrm/config @{MaxTimeoutms="1800000"}
cmd /c winrm set winrm/config/winrs @{MaxMemoryPerShellMB="300"}
cmd /c winrm set winrm/config @{MaxEnvelopeSizekb="8000"}
netsh advfirewall firewall add rule name="WinRM in" protocol=TCP dir=in profile=any localport=5985 remoteip=any localip=any action=allow
