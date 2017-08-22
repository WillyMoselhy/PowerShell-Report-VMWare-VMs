<#
    Created by Walid AlMoselhy - www.almoselhy.com
    Available on GitHub: https://github.com/WillyMoselhy/PowerShell-Report-VMWare-VMs

    Usage: Run after importing VMWare Core module with Prefix "VMWare" then connect to vSphere.

    Produces three variable containing reports on VMs, Disks, and NICs.
#>
$VMWareVMs = Get-VMWareVM

$VMWareVMsReport = @()
$VMWareDisksReport = @()
$VMWareNICsReport = @()

foreach ($VM in $VMWareVMs) {
    #Object for VM
    $VMObject = New-Object -TypeName psobject
    Add-Member -InputObject $VMObject -MemberType NoteProperty -Name "VMName" -Value $VM.Name
    Add-Member -InputObject $VMObject -MemberType NoteProperty -Name "FQDN" -Value $VM.Guest.HostName
    Add-Member -InputObject $VMObject -MemberType NoteProperty -Name "OperatingSystem" -Value $VM.Guest.OSFullName
    Add-Member -InputObject $VMObject -MemberType NoteProperty -Name "PowerState" -Value $VM.PowerState
    Add-Member -InputObject $VMObject -MemberType NoteProperty -Name "CPUs" -Value $VM.NumCpu
    Add-Member -InputObject $VMObject -MemberType NoteProperty -Name "Memory" -Value $VM.MemoryGB
    Add-Member -InputObject $VMObject -MemberType NoteProperty -Name "Firmware" -Value $VM.ExtensionData.Config.Firmware
    Add-Member -InputObject $VMObject -MemberType NoteProperty -Name "VMWareToolsStatus" -Value $VM.ExtensionData.Guest.ToolsStatus
    Add-Member -InputObject $VMObject -MemberType NoteProperty -Name "VMWareToolsVersion" -Value $VM.ExtensionData.Guest.ToolsVersion

    #region: Disks
        #Get all disks
    $VMDisks = @()+ (Get-VMWareHardDisk -VM $VM)
        
    Add-Member -InputObject $VMObject -MemberType NoteProperty -Name "NumberOfDisks" -Value $VMDisks.Count
    if($VMDisks.Count -gt 0){    
            #Check for non 'flat' disks
        if(($VMDisks | select Disktype |Where-Object {$_.Disktype -ne "Flat"})) {$HasNonFlat = $true} else {$HasNonFlat = $false}
            
        Add-Member -InputObject $VMObject -MemberType NoteProperty -Name "HasNonFlatDisks" -Value $HasNonFlat
                
            #Concatenate disk capacities
        $DisksConcat = ""
        $VMDisks  | foreach {
            $DisksConcat += "$([int] $_.CapacityGB);"

            $DiskObject = New-Object -TypeName psobject
            Add-Member -InputObject $DiskObject -MemberType NoteProperty -Name "VMName" -Value $VM.Name
            Add-Member -InputObject $DiskObject -MemberType NoteProperty -Name "DiskCapacityGB" -Value $_.CapacityGB
            Add-Member -InputObject $DiskObject -MemberType NoteProperty -Name "DiskType" -Value $_.DiskType
            Add-Member -InputObject $DiskObject -MemberType NoteProperty -Name "DiskFileName" -Value $_.Filename

            $Datastore = Get-VMWareDatastore -Id ($_.ExtensionData.Backing.Datastore)
            Add-Member -InputObject $DiskObject -MemberType NoteProperty -Name "DiskDataStore" -Value $Datastore.Name

            $VMWareDisksReport += $DiskObject
        }
        $DisksConcat = $DisksConcat.Substring(0,$DisksConcat.Length - 1)

        Add-Member -InputObject $VMObject -MemberType NoteProperty -Name "DisksCapacityGB" -Value $DisksConcat
            #Calculate total capacity
        $TotalCapacity = [int]($VMDisks | Measure-Object -Property CapacityGB -sum).sum
            
        Add-Member -InputObject $VMObject -MemberType NoteProperty -Name "TotalCapacityGB" -Value $TotalCapacity
    }

    
        
    #endregion
    
    #region: Network
        #Get all network adapters
    $NICs = @()+ ($VM | Get-VMWareNetworkAdapter)
    Add-Member -InputObject $VMObject -MemberType NoteProperty -Name "NumberOfNICs" -Value $NICs.Count
        
        #Collect NIC info
    if($NICs.Count -gt 0){
        $MACsConcat = ""
        $NetworkNamesConcat=""
        $NICTypeConcat = ""
        $StartConnectedConcat = ""
        $NICs | foreach{
            $MACsConcat += "$($_.MacAddress);"
            $NetworkNamesConcat += "$($_.NetworkName);"
            $NICTypeConcat += "$($_.Type);"
            $StartConnectedConcat += "$($_.ConnectionState.StartConnected);"

            $NICsObject = New-Object -TypeName psobject
            Add-Member -InputObject $NICsObject -MemberType NoteProperty -Name "VMName" -Value $VM.Name
            Add-Member -InputObject $NICsObject -MemberType NoteProperty -Name "MACAddress" -Value $_.MacAddress
            Add-Member -InputObject $NICsObject -MemberType NoteProperty -Name "NetworkName" -Value $_.NetworkName
            Add-Member -InputObject $NICsObject -MemberType NoteProperty -Name "NICType" -Value $_.Type
            Add-Member -InputObject $NICsObject -MemberType NoteProperty -Name "NICStartConnected" -Value $_.ConnectionState.StartConnected

            $VMWareNICsReport += $NICsObject
        }
        $MACsConcat = $MACsConcat.Substring(0,$MACsConcat.Length - 1)
        $NetworkNamesConcat= $NetworkNamesConcat.Substring(0,$NetworkNamesConcat.Length - 1)
        $NICTypeConcat = $NICTypeConcat.Substring(0,$NICTypeConcat.Length - 1)
        $StartConnectedConcat = $StartConnectedConcat.Substring(0,$StartConnectedConcat.Length - 1)

        Add-Member -InputObject $VMObject -MemberType NoteProperty -Name "NicMACAddress" -Value $MACsConcat
        Add-Member -InputObject $VMObject -MemberType NoteProperty -Name "NicNetworkName" -Value $NetworkNamesConcat
        Add-Member -InputObject $VMObject -MemberType NoteProperty -Name "NicType" -Value $NICTypeConcat
        Add-Member -InputObject $VMObject -MemberType NoteProperty -Name "NicStartConnected" -Value $StartConnectedConcat
    }
    #endregion    
    
    #region: IP Addresses
        $IPs = $() + ($VM.Guest.IPAddress)
        if($IPs.Count -gt 0){
            $IPv4Concat = ""
            $Ipv6Concat = ""
            $IPv4 = $false
            $IPv6 = $false
            $IPs | foreach{    
                #IPv4
                if($_.indexOf(":") -eq -1){
                    $IPv4Concat += "$($_);"
                    $IPv4=$true
                }
                #IPv6
                else{
                    $IPv6Concat += "$($_);"
                    $IPv6=$true
                }
            }
            if($IPv4) {$IPv4Concat = $IPv4Concat.Substring(0,$IPv4Concat.Length - 1)}
            if($Ipv6) {$Ipv6Concat = $Ipv6Concat.Substring(0,$Ipv6Concat.Length - 1)}

            Add-Member -InputObject $VMObject -MemberType NoteProperty -Name "IPv4Addresses" -Value $IPv4Concat
            Add-Member -InputObject $VMObject -MemberType NoteProperty -Name "IPv6Addresses" -Value $Ipv6Concat
        }
    #endregion

    $VMWareVMsReport += $VMObject | Select-Object VMName,FQDN,OperatingSystem,PowerState,CPUs,Memory,Firmware,VMWareToolsStatus,VMWareToolsVersion,`
                        NumberOfDisks,HasNonFlatDisks,DisksCapacityGB,TotalCapacityGB,`
                        NumberOfNICs,NicMACAddress,NicNetworkName,NicType,NicStartConnected,`
                        IPv4Addresses,IPv6Addresses
} 

#region: Produce reports using grid view - this can be changed to export to CSV or any desired format
    #All VMs
$VMWareVMsReport |Select-Object VMName,FQDN,OperatingSystem,PowerState,CPUs,Memory,VMWareToolsStatus,VMWareToolsVersion,`
                        NumberOfDisks,HasNonFlatDisks,DisksCapacityGB,TotalCapacityGB,`
                        NumberOfNICs,NicMACAddress,NicNetworkName,NicType,NicStartConnected,`
                        IPv4Addresses,IPv6Addresses | ogv -Title "VMWare VMs Report" #| Export-Csv -Path D:\temp\VMWareReports\VMWareVMs.csv -NoTypeInformation

    #All Disks
$VMWareDisksReport | Select-Object VMName, DiskCapacityGB, DiskType, DiskFileName, DiskDataStore | ogv -Title "VMWare Disks Report"

    #All NICs
$VMWareNICsReport | Select-Object VMName, MACAddress, NetworkName, NicType, NICStartConnected |ogv -Title "VMWare NICs Report"
#endregion