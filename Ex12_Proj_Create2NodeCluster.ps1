 <###############################################################################################
Ex12  Proj: Create a 2-node failover cluster 

For this project I decided to create two other vms they are both running windows server 2016 and
 are also member servers. The names of these member servers are ContosoMem2 and 3. I did it via 
 the gui and used the windows server vhdx that I have as a template. I also syspreped the systems
 and connected them to the ISCSI target.
###############################################################################################>
$vhdxpath = 'C:\Users\Public\Documents\Hyper-V\Virtual hard disks\Servers'
$Con1 = 'ContosoDC1'
$ConM1 = 'ContosoMem1'
$ConM2 = 'ContosoMem2'
$ConM3 = 'ContosoMem3'
$vhdxpath = 'C:\Users\Public\Documents\Hyper-V\Virtual hard disks\Servers'
$VmDU = 'Contoso.com\Administrator'
$VmDPword = ConvertTo-SecureString -string 'P@ssw0rd' -AsPlainText -force 
$VmDCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VmDU,$VmDPword
$VmSU = '.\Administrator'
$VmSPword = ConvertTo-SecureString -string 'P@ssw0rd' -AsPlainText -force 
$VmSCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VmSU,$VmSPword
$VmSU = '.\Administrator'
$VmSPword = ConvertTo-SecureString -string 'P@ssw0rd' -AsPlainText -force 
$VmSCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VmSU,$VmSPword

#Add the IPs of  ContosoMem2 and 3 to ContosoMem1 
Invoke-Command -VMName $ConM1 -Credential $VmDCred -ScriptBlock {
Set-IscsiServerTarget -TargetName 'Contoso-ISCSI' -InitiatorIds ("IPAddress:192.168.20.2","IPAddress:192.168.20.3","IPAddress:192.168.20.4","IPAddress:192.168.20.5","IPAddress:192.168.20.6","IPAddress:192.168.20.8") -Enable $true
}
#Configure, add to the domain and connect to ISCSI target hosted on ContosMem3 on ContosoMem2 
start-vm $ConM2
Invoke-Command -VMName $ConM2 -Credential $VmsCred -ScriptBlock {
Rename-Computer ContosoMem2
Get-NetIPInterface | ?{$_.ifAlias -like 'ethernet*' -and $_.AddressFamily -eq 'ipv4'} |New-NetIPAddress -AddressFamily IPv4 -IPAddress 192.168.10.5 -PrefixLength 24 -DefaultGateway 192.168.10.1
Get-NetIPInterface | ?{$_.ifAlias -like 'ethernet*' -and $_.AddressFamily -eq 'ipv4'} |Set-DnsClientServerAddress -ServerAddresses ('192.168.10.3','192.168.10.2')
set-netfirewallprofile -name domain,private,public -Enabled False
shutdown -r -t 0
}
Add-VMNetworkAdapter -VMName $ConM2 -SwitchName 'Lab_ISCSI' -Name 'ISCSI_NIC1'
Add-VMNetworkAdapter -VMName $Conm2 -SwitchName 'Lab_ISCSI' -Name 'ISCSI_NIC2'
Invoke-Command -VMName $ConM2 -Credential $VmSCred -ScriptBlock {
Add-Computer -DomainName contoso.com -Credential $using:VmDCred -Restart
}
Invoke-Command -VMName $ConM2 -Credential $VmDCred -ScriptBlock {
Install-WindowsFeature -name FS-Fileserver -IncludeAllSubFeature -IncludeManagementTools
New-NetIPAddress -InterfaceAlias 'Ethernet 4' -IPAddress 192.168.20.6 -PrefixLength 24 -DefaultGateway 192.168.20.1
New-NetIPAddress -InterfaceAlias 'Ethernet 5' -IPAddress 192.168.20.7 -PrefixLength 24 -DefaultGateway 192.168.20.1
get-service -name ClusSvc| set-service -StartupType Automatic
Start-Service -name MSiSCSI
Set-Service -name MSiSCSI -StartupType Automatic
New-IscsiTargetPortal -TargetPortalAddress 192.168.20.2 
New-IscsiTargetPortal -TargetPortalAddress 192.168.20.3 
Update-IscsiTarget
Get-IscsiTarget | Connect-IscsiTarget -IsPersistent $true
get-disk|?{$_.IsOffline -eq $true}| set-disk -IsOffline $false
}
#Configure, add to the domain and connect to ISCSI target hosted in ContosoMem1 on ContosoMem3 
start-vm $ConM3
Invoke-Command -VMName $ConM3 -Credential $VmsCred -ScriptBlock {
Rename-Computer ContosoMem3
Get-NetIPInterface | ?{$_.ifAlias -like 'ethernet*' -and $_.AddressFamily -eq 'ipv4'} |New-NetIPAddress -AddressFamily IPv4 -IPAddress 192.168.10.6 -PrefixLength 24 -DefaultGateway 192.168.10.1
Get-NetIPInterface | ?{$_.ifAlias -like 'ethernet*' -and $_.AddressFamily -eq 'ipv4'} |Set-DnsClientServerAddress -ServerAddresses ('192.168.10.3','192.168.10.2')
set-netfirewallprofile -name domain,private,public -Enabled False
shutdown -r -t 0
}
Invoke-Command -VMName $ConM3 -Credential $VmSCred -ScriptBlock {
Add-Computer -DomainName contoso.com -Credential $using:VmDCred -Restart
}
Add-VMNetworkAdapter -VMName $ConM3 -SwitchName 'Lab_ISCSI' -Name 'ISCSI_NIC1'
Add-VMNetworkAdapter -VMName $ConM3 -SwitchName 'Lab_ISCSI' -Name 'ISCSI_NIC2'
Invoke-Command -VMName $ConM3 -Credential $VmDCred -ScriptBlock {
Install-WindowsFeature -name FS-Fileserver -IncludeAllSubFeature -IncludeManagementTools
New-NetIPAddress -InterfaceAlias 'Ethernet 4' -IPAddress 192.168.20.8 -PrefixLength 24 -DefaultGateway 192.168.20.1
New-NetIPAddress -InterfaceAlias 'Ethernet 5' -IPAddress 192.168.20.9 -PrefixLength 24 -DefaultGateway 192.168.20.1
get-service -name ClusSvc| set-service -StartupType Automatic
Start-Service -name MSiSCSI
Set-Service -name MSiSCSI -StartupType Automatic
New-IscsiTargetPortal -TargetPortalAddress 192.168.20.2 
New-IscsiTargetPortal -TargetPortalAddress 192.168.20.3 
Update-IscsiTarget
Get-IscsiTarget | Connect-IscsiTarget -IsPersistent $true
get-disk|?{$_.IsOffline -eq $true}| set-disk -IsOffline $false
}
#Putting all computer objects participating in the failover cluster in the same OU
Invoke-Command -VMName $Con1 -Credential $VmDCred -ScriptBlock {
New-ADOrganizationalUnit -Name Failover_Cluster -Path "ou=computers,ou=administrators,dc=contoso,dc=com"
New-ADOrganizationalUnit -Name Servers -Path "ou=administrators,dc=contoso,dc=com"
Get-ADComputer -Filter {name -like 'contosomem*'} | Move-ADObject -TargetPath 'ou=failover_cluster,ou=computers,ou=administrators,dc=contoso,dc=com'
Get-ADComputer -Filter {name -like 'contosomem1'} | Move-ADObject -TargetPath 'ou=Servers,ou=administrators,dc=contoso,dc=com'
}
#Create checkpoint of all vms before implementing the cluster
get-vm | ?{$_.Name -like 'contosomem*'}| Checkpoint-VM -SnapshotName AtThisPointTheMemberServersDontHaveFAILOVERClusteringInstalled
#Install Windows Failover Cluster on all of the participating servers : ContosoMem2 and 3
Invoke-Command -VMName $ConM2 -Credential $VmDCred -ScriptBlock {
Install-WindowsFeature -name failover-clustering -IncludeAllSubFeature -IncludeManagementTools 
}
Restart-VM $ConM2 -Force
Invoke-Command -VMName $ConM3 -Credential $VmDCred -ScriptBlock {
Install-WindowsFeature -name failover-clustering -IncludeAllSubFeature -IncludeManagementTools 
}
Restart-VM $ConM3 -Force
#
#Create Cluster Contoso-Cluster
Invoke-Command -VMName $ConM1 -Credential $VmDCred -ScriptBlock {
New-Cluster -Name Contoso-Cluster -Node contosomem2,contosomem3 -StaticAddress 192.168.10.7,192.168.20.10 
}
#A Simple 2 node cluster has now been created. ContosoMem1 is hosting the ISCSI disks used by the two nodes in the failover cluster. 
#One of the iscsi disk on the target is used as the witness and the other is used for storage

#End of Ex12 Proj