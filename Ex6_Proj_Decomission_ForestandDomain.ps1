<###############################################################################################
Author: Angel L Moreno

Ex6 Proj: Decomission a Forest and Domain, Verify Domain

This project has 2 parts
Part 1: Decomssioned domain in the order of removing systems from domain then decomission
forest from ContosoDC1 
###############################################################################################>
$VmSU = '.\Administrator'
$VmSPword = ConvertTo-SecureString -string 'P@ssw0rd' -AsPlainText -force 
$VmSCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VmSU,$VmSPword
$VmCU = '.\Admin'
$VmCPword = ConvertTo-SecureString -string 'P@ssw0rd' -AsPlainText -force
$VmCCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VmCU,$VmCPword
$VmDU = 'Contoso.com\Administrator'
$VmDPword = ConvertTo-SecureString -string 'P@ssw0rd' -AsPlainText -force 
$VmDCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VmDU,$VmDPword
$DomainName = 'Contoso.com'
$DomainPword = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VmDPword
$Con1 = 'ContosoDC1'
$Con2 = 'ContosoDC2'
$ConM1 = 'ContosoMem1'
$ConC1 = 'ContosoClient1'
$time = Get-Date

start-vm $ConC1 
Invoke-Command -VMName $ConC1 -Credential $VMDCred -ScriptBlock {
Remove-Computer -UnjoinDomainCredential $Using:VmDCred -LocalCredential $using:vmccred -Force
shutdown -r -t 0
}
Start-VM $ConM1
Invoke-Command -VMName $ConM1 -Credential $VmDCred -ScriptBlock {
Remove-Computer -UnjoinDomainCredential $Using:VmDCred -LocalCredential $using:vmscred -Force
shutdown -s -t 0
}
start-Vm $Con2
Invoke-Command -VMName $Con2 -Credential $VmDCred -ScriptBlock {
Import-Module ADDSDeployment
Uninstall-ADDSDomainController -ForceRemoval -SkipPreChecks -localadministratorpassword (ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force) `
-norebootoncompletion:$false -force -demoteoperationmasterrole
}
start-vm $Con1
Invoke-Command -VMName $Con1 -Credential $VmDCred -ScriptBlock {
remove-dhcpserverindc
remove-windowsfeature -name DHCP
Uninstall-addsdomaincontroller -skipPreChecks -localadministratorpassword (ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force) -demoteoperationmasterrole -lastdomaincontrollerindomain:$true -norebootoncompletion:$false -force -ignorelastdcindomainmismatch
}
write-verbobse "The domain has been decomissioned on [$Con1]and the systems removed from the domain"

<################################################################################################
Part 2: Re-install the roles, rebuild and configure the AD environment. Add systems to the domain 
################################################################################################>

Write-Verbose "[$Con1] started at [$time] for installation of roles and congiguration of ADDS Forest" -verbose
while ((icm -VMName $con1 -Credential $vmscred {"Test"} -ea SilentlyContinue)-ne "Test") {sleep -Seconds 1}
invoke-command -VMName $Con1 -Credential $VmSCred -scriptblock {
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -IncludeAllSubFeature
import-module ADDSDeployment
$psswd = ConvertTo-SecureString -AsPlainText P@ssw0rd  -force
Install-ADDSForest -DomainName Contoso.com -InstallDns:$True -CreateDnsDelegation:$false `
 -DomainMode WinThreshold -safemodeadministratorpassword $psswd `
-ForestMode WinThreshold  -DomainNetbiosName Contoso -Force:$True `
-NoRebootOnCompletion:$false
}
while ((icm -VMName $con1 -Credential $vmscred {"Test"} -ea SilentlyContinue)-ne "Test") {sleep -Seconds 1}
invoke-command -VMName $Con1 -Credential $VmDCred -scriptblock {
Write-Verbose " Initiating the intallation and configuration of DHCP on [$Con1] at [$time]" -verbose
Install-WindowsFeature -Name DHCP -IncludeManagementTools -IncludeAllSubFeature
netsh dhcp add securitygroups
add-dhcpserversecuritygroup
Restart-Service dhcpserver
Add-DHCPServerv4Scope -Name 'User Scope' -StartRange 192.168.10.10 -EndRange 192.168.10.30 `
-SubnetMask 255.255.255.0 -State Active
Set-DhcpServerv4Scope -ScopeId 192.168.10.0 -LeaseDuration 4.00:00:00
Set-DhcpServerv4OptionValue -ScopeId 192.168.10.0 -DnsDomain Contoso.com -DnsServer 192.168.10.2 `
-Router 192.168.10.1
Add-DhcpServerInDC 
}-AsJob | wait-job -force
start-vm $Con2
Invoke-Command -VMName $Con2 -Credential $VmSCred -ScriptBlock {
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Add-Computer -DomainName $Using:DomainName -Credential $Using:VmDCred 
$Using:ADDSMod
Install-ADDSDomainController -InstallDns -DomainName $Using:DomainName -Credential $Using:VmDCred -SafeModeAdministratorPassword ($Using:DomainPword)
} 
start-vm $ConM1
while ((icm -VMName $conm1 -Credential $vmscred {"Test"} -ea SilentlyContinue)-ne "Test") {sleep -Seconds 1}
invoke-command -VMName $ConM1 -Credential $VmSCred -ScriptBlock {
add-computer -DomainName $using:DomainName -Credential $using:vmdcred
shutdown -r -t 0
}
start-vm $ConC1
while ((icm -VMName $conC1 -Credential $vmccred {"Test"} -ea SilentlyContinue)-ne "Test") {sleep -Seconds 1}
Invoke-Command -VMName ContosoClient1 -Credential $VmCCred -ScriptBlock {
ipconfig /release
ipconfig /renew
Add-Computer -DomainName $Using:DomainName -Credential $Using:VmDCred 
shutdown -r -t 0
}

#End of Ex6 Proj