<#
Author: Angel L Moreno

Required resources : Windows Server 2016 and Windows 10 VHDX with unattend files embedded.
                     Two CSVs. One for servers and Clients.                     
Concerns with the script so far : 
                1.Cannot sysprep autonomosly so administrators must turn on the vms, console in and sysprep VM.
                2.DCs is held up by gpsvc on reboot, messes up the flow of the script so admins must wait till it is done to before moving
                on to other sections. Becuase ADDS may not be started untill then.
#>
<###############################################################################################
Ex2 Proj: Install Hyper-V, create and configure vms

**Part of Ex5 Proj is in this first part: The creation and configuration of DC2**  

This lab environment was created on a windows 10 system so the syntax in regards to installing hyper-v is for that os.
To enable Hyper-V you need to ensure that your system supports virtualization and that it is enabled.
The vms will be created based off of the contents of the csv specified in $hosts
Paths for the vhdx's will be under VMclient and VMserver variable
###############################################################################################>

#Install Hyper-V 
#Enable-WindowsOptionalFeature -online -FeatureName Microsoft-Hyper-V -All -NoRestart
#Import-Module Hyper-V

#variables
$svrsizebytes = 35GB
$MemStartUp = 2048MB
$MaxMem = 2GB
$int_lab = 'lab_internal'
$Use_int_lab = 'lab_internal'
$Shosts = Get-Content $home\Desktop\Shosts.csv
$Chosts = Get-Content $home\Desktop\Chosts.csv
$VmServerVHDX = "c:\users\wwstudent\Desktop\win_server_2016.vhdx"
$vmClientVHDX = "c:\users\wwstudent\Desktop\win_10_ent.vhdx"
$VmSU = '.\Administrator'
$VmSPword = ConvertTo-SecureString -string 'P@ssw0rd' -AsPlainText -force 
$VmSCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VmSU,$VmSPword
$VmCU = '.\Admin'
$VmCPword = ConvertTo-SecureString -string 'P@ssw0rd' -AsPlainText -force
$VmCCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VmCU,$VmCPword
$time = Get-Date

#Creating the VSwitch
#New-VMSwitch -Name 'Lab_Internal' -SwitchType Internal
#Get-NetIPAddress | ?{$_.InterfaceAlias -like '*lab_internal*'} | New-NetIPAddress -IPAddress 192.168.10.1 -PrefixLength 24

#loop configuring all the Server vms from the content in the csv specified
mkdir 'C:\Users\Public\Documents\Hyper-V\Virtual hard disks\Servers'
mkdir 'C:\Users\Public\Documents\Hyper-V\Virtual hard disks\Clients'

foreach ($hostsvm in $Shosts){
$time = Get-Date
$vhdxpath = 'C:\Users\Public\Documents\Hyper-V\Virtual hard disks\Servers'
$hostsvhdxpath = "$vhdxpath\$hostsvm.vhdx"
$vmpath = 'C:\ProgramData\Microsoft\Windows\Hyper-V'
Copy-Item -Path $VmServerVHDX -Destination $vhdxpath 
rename-item -Path $vhdxpath\win_server_2016.vhdx -NewName "$hostsvm.vhdx"
new-vm  -Name $hostsvm -MemoryStartupBytes $MemStartUp -SwitchName $Use_int_lab -VHDPath $hostsvhdxpath -Generation 2
set-vm -name $hostsvm -ProcessorCount 1 -MemoryMinimumBytes $memstartup -MemoryMaximumBytes $maxmem
Add-VMDvdDrive -VMName $hostsvm -Path $null
 Write-Verbose "[$hostsvm] has been syspreped and shutting down at [$time]" -verbose
}

#loop configuring all the Clientsvms from the content in the csv specified
foreach ($hostsvm in $Chosts){
$vhdxpath = 'C:\Users\Public\Documents\Hyper-V\Virtual hard disks\Clients'
$hostsvhdxpath = "$vhdxpath\$hostsvm.vhdx"
$vmpath = 'C:\ProgramData\Microsoft\Windows\Hyper-V'
Copy-Item -Path $VmClientVHDX -Destination $vhdxpath 
rename-item -Path $vhdxpath\win_10_ent.vhdx -NewName "$hostsvm.vhdx"
new-vm  -Name $hostsvm -MemoryStartupBytes $MemStartUp -SwitchName $Use_int_lab -VHDPath $hostsvhdxpath -Generation 2
set-vm -name $hostsvm -ProcessorCount 1 -MemoryMinimumBytes $memstartup -MemoryMaximumBytes $maxmem
Add-VMDvdDrive -VMName $hostsvm -Path $null
}

<# 
#############################################################################################################################
#Now that the vms have been created the administrators have to COPY AND PASTE the commands below into the vm console via powershell
#IMPORTANT!!! administrators have to make sure they have created, configured and placed an autounattend.xml in the sysprep path.

$sysprep = 'C:\Windows\System32\Sysprep\sysprep.exe'
$arg = ' /oobe /generalize /shutdown /mode:vm /unattend:c:\windows\panther\autounattend.xml'
$sysprep += $arg 
invoke-expression $sysprep
##############################################################################################################################
#>

#The configurations of the vms could not be put into a loop due to the fact that they are different systems with different needs
#This section is for the variables used from this point on and the configuration
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
$DomainPword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -force
$ADDSDepMod = import-module ADDSDeployment | out-null
$DisableFW = Set-NetFirewallProfile -Name Domain,Private,Public -Enabled False
$Day = Get-Date
$SetZone = set-timezone -id 'Pacific Standard Time' -PassThru
$time = Get-Date

Write-Verbose "starting the configuration of [$Con1]" -verbose
#Config ContosoDC1
$Con1 = 'ContosoDC1'
start-vm $Con1
Write-Verbose "[$Con1] started at [$time]" -verbose
while ((icm -VMName $con1 -Credential $vmscred {"Test"} -ea SilentlyContinue)-ne "Test") {sleep -Seconds 1}
Invoke-Command -VMName $Con1 -Credential $VmSCred -ScriptBlock {
Rename-Computer ContosoDC1
Get-NetIPInterface | ?{$_.ifAlias -like 'ethernet*' -and $_.AddressFamily -eq 'ipv4'} |New-NetIPAddress -AddressFamily IPv4 -IPAddress 192.168.10.2 -PrefixLength 24 -DefaultGateway 192.168.10.1
Get-NetIPInterface | ?{$_.ifAlias -like 'ethernet*' -and $_.AddressFamily -eq 'ipv4'} |Set-DnsClientServerAddress -ServerAddresses ('192.168.10.3','127.0.0.1')
$Using:DisableFW
}-AsJob | wait-job -force 
stop-vm $Con1 -AsJob | Wait-Job -Force
Write-Verbose "completed networking for [$Con1] at [$time]" -verbose
start-vm $Con1 -AsJob| Wait-Job -force
Write-Verbose "[$Con1] started at [$time] for installation of roles and congiguration of ADDS Forest" -verbose
while ((icm -VMName $con1 -Credential $vmscred {"Test"} -ea SilentlyContinue)-ne "Test") {sleep -Seconds 1}
invoke-command -VMName $Con1 -Credential $VmSCred -scriptblock {
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -IncludeAllSubFeature
import-module ADDSDeployment
$psswd = ConvertTo-SecureString -AsPlainText P@ssw0rd  -force
Install-ADDSForest -DomainName Contoso.com -InstallDns:$True -CreateDnsDelegation:$false `
 -DomainMode WinThreshold -safemodeadministratorpassword $psswd `
-ForestMode WinThreshold  -DomainNetbiosName Contoso -Force:$True `
-NoRebootOnCompletion:$true
}
while ((icm -VMName $con1 -Credential $vmscred {"Test"} -ea SilentlyContinue)-ne "Test") {sleep -Seconds 1}
Write-Verbose "[$Con1] completed installation and configuration of ADDS Forest at [$time]" -verbose
start-vm $Con1
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
Write-Verbose "Completed the intallation and configuration of DHCP on [$Con1] at [$time]" -verbose
stop-vm $Con1 -AsJob | wait-job -Force
start-vm $Con1 -AsJob | wait-job 
Write-Verbose "waiting for [$Con1] to complete boot up" -verbose
while ((icm -VMName $con1 -Credential $vmdcred {"Test"} -ea SilentlyContinue)-ne "Test") {sleep -Seconds 1}

#Config ContosoMem1
$ConM1 = 'ContosoMem1'
start-vm $ConM1
Write-Verbose "[$ConM1] was started at [$time]" -Verbose 
start-vm $ConM1
while ((icm -VMName $conm1 -Credential $vmscred {"Test"} -ea SilentlyContinue)-ne "Test") {sleep -Seconds 1}
Invoke-Command -VMName $ConM1 -Credential $VmSCred -ScriptBlock {
Rename-Computer ContosoMem1
$Using:SetZone
set-date -date $Using:Day
Get-NetIPInterface | ?{$_.ifAlias -like 'ethernet*' -and $_.AddressFamily -eq 'ipv4'} |New-NetIPAddress -AddressFamily IPv4 -IPAddress 192.168.10.4 -PrefixLength 24 -DefaultGateway 192.168.10.1
Get-NetIPInterface | ?{$_.ifAlias -like 'ethernet*' -and $_.AddressFamily -eq 'ipv4'} |Set-DnsClientServerAddress -ServerAddresses ('192.168.10.2','192.168.10.3')
$Using:DisableFW
shutdown -r -t 0
} -AsJob | wait-job -force 
while ((icm -VMName $conm1 -Credential $vmscred {"Test"} -ea SilentlyContinue)-ne "Test") {sleep -Seconds 1}
invoke-command -VMName $ConM1 -Credential $VmSCred -ScriptBlock {
add-computer -DomainName $using:DomainName -Credential $using:vmdcred
shutdown -r -t 0
}
while ((icm -VMName $conm1 -Credential $vmdcred {"Test"} -ea SilentlyContinue)-ne "Test") {sleep -Seconds 1}

#Config ContosoClient1
$ConC1 = 'ContosoClient1'
Start-VM $ConC1
Invoke-Command -VMName $ConC1 -Credential $VmCCred -ScriptBlock {
Rename-Computer ContosoClient1 
$Using:SetZone
set-date -date $Using:Day
$Using:DisableFW
shutdown -r -t 0
}
while ((icm -VMName $conC1 -Credential $vmccred {"Test"} -ea SilentlyContinue)-ne "Test") {sleep -Seconds 1}
Invoke-Command -VMName ContosoClient1 -Credential $VmCCred -ScriptBlock {
ipconfig /release
ipconfig /renew
}

#End of Ex2 Proj