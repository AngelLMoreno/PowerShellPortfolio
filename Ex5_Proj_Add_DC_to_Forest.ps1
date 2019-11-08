<###############################################################################################
Author: Angel L Moreno

Ex5 Proj: Add additional Domain Controller to an existing Forest

The creation of the vm was executed in the Ex2 Proj section
###############################################################################################>
$VmSU = '.\Administrator'
$VmSPword = ConvertTo-SecureString -string 'P@ssw0rd' -AsPlainText -force 
$VmSCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VmSU,$VmSPword
$VmDU = 'Contoso.com\Administrator'
$VmDPword = ConvertTo-SecureString -string 'P@ssw0rd' -AsPlainText -force 
$VmDCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VmDU,$VmDPword
$DomainName = 'Contoso.com'
$ADDSMod = import-module ActiveDirectory
$DisableFW = Set-NetFirewallProfile -Name Domain,Private,Public -Enabled False
$DomainPword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -force
$SetZone = set-timezone -id 'Pacific Standard Time' -PassThru
$Day = Get-Date

#Config ContosoDC2
$Con2 = 'ContosoDC2'
Start-vm $Con2
while ((icm -VMName $Con2 -Credential $vmscred {"Test"} -ea SilentlyContinue)-ne "Test") {sleep -Seconds 1}
Invoke-Command -VMName $con2 -Credential $VmSCred -ScriptBlock {
Rename-Computer ContosoDC2
Get-NetIPInterface | ?{$_.ifAlias -like 'ethernet*' -and $_.AddressFamily -eq 'ipv4'} |New-NetIPAddress -AddressFamily IPv4 -IPAddress 192.168.10.3 -PrefixLength 24 -DefaultGateway 192.168.10.1
Get-NetIPInterface | ?{$_.ifAlias -like 'ethernet*' -and $_.AddressFamily -eq 'ipv4'} |Set-DnsClientServerAddress -ServerAddresses ('192.168.10.2','127.0.0.1')
$Using:SetZone
set-date -date $Using:Day
$Using:DisableFW
shutdown -r -t 0
}
start-vm $Con2
while ((icm -VMName $Con2 -Credential $vmscred {"Test"} -ea SilentlyContinue)-ne "Test") {sleep -Seconds 1}
Invoke-Command -VMName $Con2 -Credential $VmSCred -ScriptBlock {
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Add-Computer -DomainName $Using:DomainName -Credential $Using:VmDCred 
$Using:ADDSMod
Install-ADDSDomainController -InstallDns -DomainName $Using:DomainName -Credential $Using:VmDCred -SafeModeAdministratorPassword ($Using:DomainPword)
} 

#End of Ex5 Proj