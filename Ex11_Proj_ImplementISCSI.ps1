<###############################################################################################
Author: Angel L Moreno

Ex11  Proj: Implement ISCSI
###############################################################################################>
$vhdxpath = 'C:\Users\Public\Documents\Hyper-V\Virtual hard disks\Servers'
$Con1 = 'ContosoDC1'
$ConM1 = 'ContosoMem1'
$vhdxpath = 'C:\Users\Public\Documents\Hyper-V\Virtual hard disks\Servers'
$VmDU = 'Contoso.com\Administrator'
$VmDPword = ConvertTo-SecureString -string 'P@ssw0rd' -AsPlainText -force 
$VmDCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VmDU,$VmDPword

New-VMSwitch -Name 'Lab_ISCSI' -SwitchType Internal 
Get-NetIPAddress | ?{$_.InterfaceAlias -like '*Lab_ISCSI*'} | New-NetIPAddress -IPAddress 192.168.20.1 -PrefixLength 24
new-vhd -Path $vhdxpath\ISCSI_Drive.vhdx -Fixed -SizeBytes 15GB
Add-VMHardDiskDrive -Path $vhdxpath\ISCSI_Drive.vhdx -VMName $ConM1
Add-VMNetworkAdapter -VMName $Con1 -SwitchName 'Lab_ISCSI' -Name 'ISCSI_NIC1'
Add-VMNetworkAdapter -VMName $Con1 -SwitchName 'Lab_ISCSI' -Name 'ISCSI_NIC2'
Add-VMNetworkAdapter -VMName $ConM1 -SwitchName 'Lab_ISCSI' -Name 'ISCSI_NIC1'
Add-VMNetworkAdapter -VMName $ConM1 -SwitchName 'Lab_ISCSI' -Name 'ISCSI_NIC2' -DeviceNaming On
Invoke-Command -VMName $ConM1 -Credential $VmDCred -ScriptBlock {
Install-WindowsFeature -Name FS-iSCSITarget-Server -IncludeAllSubFeature -IncludeManagementTools
Install-WindowsFeature -Name Multipath-IO -IncludeAllSubFeature -IncludeManagementTools
shutdown -r -t 0
}
Invoke-Command -VMName $ConM1 -Credential $VmDCred -ScriptBlock {
get-disk | ?{$_.OperationalStatus -eq 'offline'} | Initialize-Disk `
 | New-Partition -AssignDriveLetter -UseMaximumSize | format-volume -FileSystem NTFS -Confirm:$false -force 
$disk = get-disk | ?{$_.BootFromDisk -eq $false}
New-NetIPAddress -InterfaceAlias 'Ethernet 4' -IPAddress 192.168.20.2 -PrefixLength 24 -DefaultGateway 192.168.20.1
New-NetIPAddress -InterfaceAlias 'Ethernet 5' -IPAddress 192.168.20.3 -PrefixLength 24 -DefaultGateway 192.168.20.1
get-service -Name MSiSCSI | Set-Service -StartupType Automatic
Start-Service -name msiscsi
New-Volume -Disk $disk -FileSystem NTFS -DriveLetter I -FriendlyName 'ISCSI'
mkdir I:\ISCSI
New-IscsiVirtualDisk -Path I:\ISCSI\ISCSI_D1.vhdx -SizeBytes 2GB 
New-IscsiVirtualDisk -Path I:\ISCSI\ISCSI_D2.vhdx -SizeBytes 2GB
New-IscsiServerTarget -TargetName 'Contoso-ISCSI' 
Add-IscsiVirtualDiskTargetMapping -TargetName 'Contoso-ISCSI' -Path I:\ISCSI\ISCSI_D1.vhdx
Add-IscsiVirtualDiskTargetMapping -TargetName 'Contoso-ISCSI' -Path I:\ISCSI\ISCSI_D2.vhdx 
New-IscsiTargetPortal -TargetPortalAddress 192.168.20.2 -TargetPortalPortNumber 3260 -InitiatorPortalAddress 192.168.20.2 `
-InitiatorInstanceName ROOT\ISCSIPRT\0000_0 -IsDataDigest $False -IsHeaderDigest $False 
New-IscsiTargetPortal -TargetPortalAddress 192.168.20.2 -TargetPortalPortNumber 3260 -InitiatorPortalAddress 192.168.20.3 `
-InitiatorInstanceName ROOT\ISCSIPRT\0000_0 -IsDataDigest $False -IsHeaderDigest $False
Set-IscsiServerTarget -TargetName 'Contoso-ISCSI' -InitiatorIds ("IPAddress:192.168.20.2","IPAddress:192.168.20.3","IPAddress:192.168.20.4","IPAddress:192.168.20.5") -Enable $true
restart-serivce MSISCSI
Get-IscsiTarget | Connect-IscsiTarget -TargetPortalAddress 192.168.20.2 -IsPersistent $true -IsMultipathEnabled $true `
-InitiatorPortalAddress 192.168.20.2 -TargetPortalPortNumber 3260
}
Invoke-Command -VMName $con1 -Credential $VmDCred -ScriptBlock {
get-service -Name MSiSCSI | Set-Service -StartupType Automatic
Start-Service -name msiscsi
install-windowsfeature -name Multipath-IO -IncludeAllSubFeature -IncludeManagementTools 
shutdown -r -t 0
}
Invoke-Command -VMName $Con1 -Credential $VmDCred -ScriptBlock {
New-NetIPAddress -InterfaceAlias 'Ethernet 4' -IPAddress 192.168.20.4 -PrefixLength 24 -DefaultGateway 192.168.20.1
New-NetIPAddress -InterfaceAlias 'Ethernet 5' -IPAddress 192.168.20.5 -PrefixLength 24 -DefaultGateway 192.168.20.1
New-IscsiTargetPortal -TargetPortalAddress 192.168.20.4 -TargetPortalPortNumber 3260 -InitiatorPortalAddress 192.168.20.4 `
-InitiatorInstanceName ROOT\ISCSIPRT\0000_0 -IsDataDigest $False -IsHeaderDigest $False 
New-IscsiTargetPortal -TargetPortalAddress 192.168.20.4 -TargetPortalPortNumber 3260 -InitiatorPortalAddress 192.168.20.5 `
-InitiatorInstanceName ROOT\ISCSIPRT\0000_0 -IsDataDigest $False -IsHeaderDigest $False
Update-IscsiTarget
Get-IscsiTarget | Connect-IscsiTarget 
Get-IscsiVirtualDisk
get-disk | ?{$_.FriendlyName -like '*msft virtual hd*'} | Initialize-Disk `
 | New-Partition -AssignDriveLetter -UseMaximumSize | format-volume -FileSystem NTFS -Confirm:$false -force 
$iscsi1 = get-disk | ?{$_.Number -eq 2}
$iscsi2 = get-disk | ?{$_.Number -eq 3}
New-Volume -Disk $iscsi1 -FileSystem NTFS -FriendlyName 'Contoso_ISCSI_1' -DriveLetter I
New-Volume -Disk $iscsi2 -FileSystem NTFS -FriendlyName 'Contoso_ISCSI_2' -DriveLetter J
}

 #End of Ex11 Proj