<###############################################################################################
Author: Angel L Moreno

Ex8  Proj: Create OUs and User Objects
###############################################################################################>
$VmDU = 'Contoso.com\Administrator'
$VmDPword = ConvertTo-SecureString -string 'P@ssw0rd' -AsPlainText -force 
$VmDCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VmDU,$VmDPword
$Con1 = 'ContosoDC1'
$GenPop = 'OU=GenPop,DC=Contoso,DC=Com'
$Administrators = 'OU=Administrators,DC=Contoso,DC=Com'
$DA = 'OU=Domain Administrators,OU=Administrators,DC=Contoso,DC=Com'
$U = 'OU=Users,OU=GenPop,DC=Contoso,DC=Com'

Invoke-Command -vmname $con1 -credential $vmdcred -scriptblock {
New-ADOrganizationalUnit -Name 'GenPop' -Path 'DC=contoso,DC=Com' 
New-ADOrganizationalUnit -Name 'Users' -Path $Using:GenPop
New-ADOrganizationalUnit -Name 'Computers' -Path $Using:GenPop
New-ADOrganizationalUnit -Name 'Administrators' -Path 'DC=contoso,DC=Com'
New-ADOrganizationalUnit -Name 'Domain Administrators' -Path $Using:Administrators
New-ADOrganizationalUnit -Name 'Computers' -Path $Using:Administrators
New-ADUser -Name 'Chester Cheeto DA' -GivenName 'Chester' -Surname 'Cheeto' `
-SamAccountName 'Chester.Cheeto.DA' -UserPrincipalName 'Chester.Cheeto.DA@Contoso.com' `
-Path $Using:DA -AccountPassword (ConvertTo-SecureString -string 'P@ssw0rd' -AsPlainText -Force) `
-Enabled $true 
New-ADUser -Name 'Aunt Jemima DA' -GivenName 'Aunt' -Surname 'Jemima' `
-SamAccountName 'Aunt.Jemima.DA' -UserPrincipalName 'Aunt.Jemima.DA@Contoso.com' `
-Path $Using:DA -AccountPassword (ConvertTo-SecureString -string 'P@ssw0rd' -AsPlainText -Force) `
-Enabled $true 
New-ADUser -Name 'Tony Tiger' -GivenName 'Tony' -Surname 'Tiger' `
-SamAccountName 'Tony.Tiger' -UserPrincipalName 'Tony.Tiger@Contoso.com' `
-Path $Using:U -AccountPassword (ConvertTo-SecureString -string 'P@ssw0rd' -AsPlainText -Force) `
-Enabled $true 
New-ADUser -Name 'Captain Crunch' -GivenName 'Captain' -Surname 'Crunch' `
-SamAccountName 'Captain.Crunch' -UserPrincipalName 'Captain.Crunch@Contoso.com' `
-Path $Using:U -AccountPassword (ConvertTo-SecureString -string 'P@ssw0rd' -AsPlainText -Force) `
-Enabled $true 
}

#End of Ex 8 Proj