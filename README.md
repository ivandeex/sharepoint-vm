# Sharepoint Virtual Machines

This is a [terraform](https://terraform.io/) scenario that automates the deployment
of [SharePoint](https://www.microsoft.com/en-us/microsoft-365/sharepoint/collaboration)
on your [AWS](https://aws.amazon.com/ec2/) or [Vultr](https://www.vultr.com/) VPS.

It creates the entire stack based on _Windows Server 2012 R2_, including:
- Active Directory Domain Controller (abbreviated as **ADDC**)
- Microsoft SQL Server 2014 (**MSQL**)
- SharePoint Application Server with example sites (**SPAP**)
- Linux machine with Golang 1.14 for tests
- Private network connecting all boxes

## Creating your servers

Install _terraform_ from the [download page](https://www.terraform.io/downloads.html).

Obtain your Vultr API key from the settings page https://my.vultr.com/settings/#settingsapi
and set the environment variable `VULTR_API_KEY`.

If you want to use AWS (unfortunately this script currently fails on AWS),
set AWS keys in environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

Clone this repository locally:
```
git clone https://github.com/ivandeex/sharepoint-vm
cd sharepoint-vm
```

Create a text file `terraform.tfvars` (in the `vultr` or `aws` directory)
if you want to tune some parameters, e.g.:
```
admin_password = "Secret2021!"
aws_region = "us-east-1"
dropbox_url = "https://www.dropbox.com/sh/aaoj8l0my90gblo/AADlQ7sVmu4uLHxKH-Nl6jYRa"
```

Please note that password should obey default Windows requirements:
have at least 8 characters, upper and lower case, digits and punctuation.
Otherwise installation will fail.

Now change to subdirectory `vultr` (or `aws`) and run the script:
```
cd sharepoint-vm/vultr
terraform init
terraform plan
terraform apply
```

Wait about 1-2 hours for setup to complete...

At the end the script will print IP addresses and names of created servers.

## Custom domain

By default the Active Directory domain is private `example.com`.
If you have a domain registered on [Cloudflare](https://www.cloudflare.com/),
obtain your Cloudflare token from the profile page https://dash.cloudflare.com/profile/api-tokens
and set environment variables `CLOUDFLARE_EMAIL` and `CLOUDFLARE_TOKEN`
(or `CLOUDFLARE_API_KEY`), then add the name of the DNS zone in `terraform.tfvars`:
```
domain_name = "mycloudflaredomain.com"
```

## Using your servers

You can connect to the Windows boxes using any RDP client.
Use public IP address from the script output, username _Administrator_
(or _spAdmin_) and password from settings.
If you configured a Cloudflare domain name, you can use hostnames
like `sptest-spap.yourdomain.com` instead of IP address.

Use the following command to login to the test linux box:
```
cd sharepoint-vm/unix
chmod 600 vagrant.key
ssh -i vagrant.key -l ubuntu -p 22 IP.OF.LINUX.BOX
```

The IP address was printed at the end of terraform run
(or use DNS name `sptest-unix.yourdomain.com`).

## Caveats

Some installation steps are not 100% reliable, Welcome to Windows...
For example, the _6-install_ step sometimes fails with error
[1603](https://docs.microsoft.com/en-us/windows/win32/msi/error-codes).
The script retries many such situations.
If however it failed for you, don't worry.
Just repeat the `terraform apply` command until the problem goes.
This will help in most cases.

A copy of prerequisite downloads for this script was saved in
[Dropbox](https://www.dropbox.com/sh/aaoj8l0my90gblo/AADlQ7sVmu4uLHxKH-Nl6jYRa?dl=0).
This should help in case Microsoft decides to deprecate some of them.

Currently installation of Sharepoint Server on AWS stops at the prerequisites stage.
Probably, _wsman_ connection breaks due to high CPU usage caused by .NET optimization service.
For now you can use Vultr until I have time to fix that.

## HTTPS and SSL

This script configures a vanilla Sharepoint site with pure HTTP access for tests.
If you need `HTTPs`, you can update the site with a self-signed SSL certificate manually.

The certificate is already created by the script and named `spap.example.com`.
It is already added to the Windows certificate store on the Sharepoint machine,
just add it to the test site as follows:
- Open IIS manager `Start > All Apps > Internet Information Services (IIS) Manager`
  (ignore _Manager 6.0_)
- Expand `Sites` and select your _test web application_ from the navigation tree
- Click on the `Bindings` link from the right hand panel
- Click `Add...` in the Bindings dialog
- In the `Add Site Binding` dialog, select HTTPS from the `Type` drop down
- Leave the IP address as `All Unassigned`, the Port should say 443
- Enter the `Host name` as `spap.example.com`
- Select the `spap.example.com` SSL certificate from the drop-down menu and click OK

Configure alternate HTTPS access mapping for the site:
- Open the Sharepoint 2016 `Central Administration` tool from Windows start menu
  or open site `http://spap:2016/` in Internet Explorer
- Click on `Application Management > Configure alternate access mappings`
- Click on `Edit Public URLs` and pick your _Test Web Application_
- Enter the HTTPs URL `https://spap.example.com` in the `Intranet` (and optionally `Internet`) zone

Tell Windows to trust the site certificate without confirmation:
- Open `Control Panel > Internet Options > Content > Certificates > Intermediate Certificate Authorities`
- Select your SSL certificate `spap.example.com` and click `Export`
- Export it as `DER encoded binary` to the desktop.
  Choose any name you like, for example `self-signed.cer`
- Switch certificate store window to the `Trusted Root Certificate Authorities` tab
- Import the certificate, confirm

Open new _HTTPs_ address `https://spap.example.com/sites/test` with Internet Explorer.
After you enter your password credendials for `example\spAdmin`, Sharepoint
will re-create the initial content from templates and do the warm-up.
This should be done only once.

Now you can mount the site document library as a network disk:
- Open Windows explorer and point to `This PC`
- Click `Computer > Map Network Drive` in the menu
- Type `https://spap.example.com/sites/test/Shared%20Documents`
  in the `Folder` field and click OK
- Enter your credentials when prompted

If you want to access the site from the Linux test box, you will have to
make Ubuntu trust the self-signed certificate.
Copy it from Windows to Ubuntu, convert from the CER/DER format to PEM/CRT
and make it trusted as follows:
```
openssl x509 -in self-signed.cer -inform der -out self-signed.crt
sudo cp self-signed.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

Now the following command should work without SSL errors,
however it can require NTLM authorization:
```
curl -v -4 --ntlm --negotiate -u spadmin:YOURPASS https://spap.example.com/sites/test/Shared%20Documents
```

## References

- Installing Sharepoint with Powershell:
  - http://www.luisevalencia.com/2016/09/25/installing-sharepoint-server-2016-with-powershell/
- Example of Sharepoint install using Terraform:
  - https://github.com/eschu21/terraform_sharepoint_automation
- How to set up Active Directory:
  - https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/install-active-directory-domain-services--level-100-
  - https://theitbros.com/unable-to-find-a-default-server-with-active-directory-web-services-running/
  - https://docs.microsoft.com/en-us/archive/blogs/adpowershell/disable-loading-the-default-drive-ad-during-import-module
- Why New-SPConfigurationDatabase fails with _RPC Server Unavailable_:
  - https://docs.microsoft.com/en-us/powershell/module/sharepoint-server/new-spconfigurationdatabase?view=sharepoint-ps
  - https://www.sharepointdiary.com/2016/09/failed-to-create-the-configuration-database-the-rpc-server-is-unavailable.html
  - https://www.spguides.com/the-rpc-server-is-unavailable-sharepoint-2016/
  - http://www.harbar.net/archive/2018/06/25/RPC-Server-Unavailable-when-creating-a-SharePoint-Farmhellip-the-curse.aspx
- How to prioritize network adapters in Windows:
  - https://social.technet.microsoft.com/Forums/en-US/cb8dac7f-5f04-42b1-8065-a95c946f6ec2/change-network-adapter-priority-order
- How to query Active Directory users using Powershell:
  - http://woshub.com/get-aduser-getting-active-directory-users-data-via-powershell/
- How to run SQL Server commands from Powershell:
  - https://stackoverflow.com/questions/9714054/how-to-execute-sqlcmd-from-powershell
- Creating a Sharepoint site:
  - https://docs.microsoft.com/en-us/SharePoint/sites/create-a-site-collection?redirectedfrom=MSDN#create-a-site-collection-by-using-microsoft-powershell
  - http://tomkupka.com/sharepoint/create-web-application-and-site-collection-in-sharepoint-2016-using-powershell/
- How to change a Sharepoint web application from HTTP to HTTPS:
  - https://www.sharepointdiary.com/2012/03/configuring-ssl-certificates-in-sharepoint-2010.html
  - https://www.sharepointdiary.com/2017/08/how-to-change-sharepoint-web-application-from-http-to-https.html
  - https://stackoverflow.com/questions/15697157/using-curl-with-ntlm-auth-to-make-a-post-is-failing
- How to map Sharepoint network drives using Powershell:
  - https://stackoverflow.com/questions/30298850/powershell-map-persistent-sharepoint-path
- List of Amazon EC2 AMIs:
  - https://eu-central-1.console.aws.amazon.com/ec2/v2/home?region=eu-central-1#Images:visibility=public-images%3Bsort=name
  - https://cloud-images.ubuntu.com/locator/ec2/
  - https://awsregion.info/

## License

MIT
