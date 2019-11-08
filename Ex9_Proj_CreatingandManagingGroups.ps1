<###############################################################################################
Author: Angel L Moreno

Ex9  Proj: Creating and Managing Groups
###############################################################################################>
$VmDU = 'Contoso.com\Administrator'
$VmDPword = ConvertTo-SecureString -string 'P@ssw0rd' -AsPlainText -force 
$VmDCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VmDU,$VmDPword
$Con1 = 'ContosoDC1'
$DA = 'OU=Domain Administrators,OU=Administrators,DC=Contoso,DC=Com'
$U = 'OU=Users,OU=GenPop,DC=Contoso,DC=Com'

Invoke-Command -VMName $Con1 -Credential $VmDCred -ScriptBlock {
$GUs = Get-aduser -filter * -searchbase $Using:U
New-ADGroup -Name 'General Users' -SamAccountName GerenalUsers -GroupCategory Security `
-GroupScope Global -DisplayName "General Users" -Path $Using:U `
-Description "Members of this group are General Users"
Add-ADGroupMember -Identity 'General Users' -Members $GUs
$DAs =  Get-aduser -filter * -searchbase $Using:DA
Get-ADGroup -Identity 'Domain Admins'| move-adobject -targetpath $Using:DA 
}  

#End of Ex9 Proj 