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

## References

- Installing Sharepoint with Powershell:
  - http://www.luisevalencia.com/2016/09/25/installing-sharepoint-server-2016-with-powershell/
- Example of Sharepoint install using Terraform:
  - https://github.com/eschu21/terraform_sharepoint_automation
- How to set up Active Directory:
  - https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/install-active-directory-domain-services--level-100-
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
- How to map Sharepoint network drives using Powershell:
  - https://stackoverflow.com/questions/30298850/powershell-map-persistent-sharepoint-path
- List of Amazon EC2 AMIs:
  - https://eu-central-1.console.aws.amazon.com/ec2/v2/home?region=eu-central-1#Images:visibility=public-images%3Bsort=name
  - https://cloud-images.ubuntu.com/locator/ec2/
  - https://awsregion.info/

## License

MIT
