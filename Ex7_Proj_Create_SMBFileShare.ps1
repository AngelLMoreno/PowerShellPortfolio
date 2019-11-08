<###############################################################################################
Author: Angel L Moreno

Ex 7 Proj: Create a file share
###############################################################################################>
$VmDU = 'Contoso.com\Administrator'
$VmDPword = ConvertTo-SecureString -string 'P@ssw0rd' -AsPlainText -force 
$VmDCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VmDU,$VmDPword
$Con1 = 'ContosoDC1'
$vhdxpath = 'C:\Users\Public\Documents\Hyper-V\Virtual hard disks\Servers'

new-vhd -Path $vhdxpath\Contoso_ShareDrive.vhdx -Fixed -SizeBytes 15GB
Add-VMHardDiskDrive -Path $vhdxpath\Contoso_ShareDrive.vhdx -VMName $con1
start-vm -vmname $Con1 
Invoke-Command -VMName $Con1 -Credential $VmDCred -ScriptBlock {
get-disk | ?{$_.OperationalStatus -eq 'offline'} | Initialize-Disk `
 | New-Partition -AssignDriveLetter -UseMaximumSize | format-volume -FileSystem NTFS -Confirm:$false -force 
$disk = get-disk | ?{$_.BootFromDisk -eq $false}
New-Volume -Disk $disk -FileSystem NTFS -DriveLetter S -FriendlyName 'Contoso_Share'
mkdir s:\Share
New-smbshare -name 'Contoso_Share' -Path s:\share -Description 'Share for the Contoso domain'
}

#end of Ex7 Proj 