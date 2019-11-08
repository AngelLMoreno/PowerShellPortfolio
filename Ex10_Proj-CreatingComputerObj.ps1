<###############################################################################################
Author: Angel L Moreno

Ex10  Proj: Creating Computer Objects
###############################################################################################>
$VmDU = 'Contoso.com\Administrator'
$VmDPword = ConvertTo-SecureString -string 'P@ssw0rd' -AsPlainText -force 
$VmDCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VmDU,$VmDPword
$VmDCC = 'Contoso.com\Captain.Crunch'
$VmDCCPword = ConvertTo-SecureString -string 'P@ssw0rd' -AsPlainText -force 
$VmDCCCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VmDCC,$VmDCCPword
$ConC1 = 'ContosoClient1'
$Con1 = 'ContosoDC1'
$DomainName = 'Contoso.com'
$CompPath = 'OU=Computers,ou=genpop,dc=contoso,dc=com'

Invoke-Command -VMName $con1 -Credential $VmDCred -scriptblock{
New-ADComputer -Name ContosoClient1 -DisplayName ContosoClient1 -Path $Using:CompPath
cd ad:
$comp = get-adcomputer -filter {name -like 'ContosoClient1'}
$acl = get-acl -path ($comp.DistinguishedName)
$user = [System.Security.Principal.NTAccount]'contoso.com\Captain.Crunch'
$ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($user,[System.DirectoryServices.ActiveDirectoryRights]::GenericAll,[System.Security.AccessControl.AccessControlType]::Allow)
$acl.AddAccessRule($ace)
set-acl $comp.DistinguishedName $acl
cd c:\
}
start-vm $ConC1
Invoke-Command -VMName $ConC1 -Credential $VmCCred -ScriptBlock {
Add-Computer -DomainName $Using:DomainName -Credential $Using:VmDCCCred -Restart
}
invoke-command -VMName $Con1 -Credential $VmDCred -ScriptBlock{
$wherecomp = get-adcomputer $using:ConC1 
$wherecomp | move-adobject -targetpath 'dc=contoso,dc=com'
$wherecomp = get-adcomputer $using:ConC1 
write-verbose "[$wherecomp]" -Verbose
$wherecomp | move-adobject -targetpath $Using:CompPath
$wherecomp = get-adcomputer $using:ConC1 
write-verbose "[$wherecomp]" -Verbose
}
 
#End of Ex10 Proj 