$Report = foreach ($VM in $VMWareVMs) {
    $Object = New-Object -TypeName psobject
    Add-Member -InputObject $Object -MemberType NoteProperty -Name "Name" -Value $VM.Name
    Add-Member -InputObject $Object -MemberType NoteProperty -Name "FQDN" -Value $VM.Guest.HostName
    Add-Member -InputObject $Object -MemberType NoteProperty -Name "OperatingSystem" -Value $VM.Guest.OSFullName
    Add-Member -InputObject $Object -MemberType NoteProperty -Name "PowerState" -Value $VM.PowerState
    Add-Member -InputObject $Object -MemberType NoteProperty -Name "CPUs" -Value $VM.NumCpu
    Add-Member -InputObject $Object -MemberType NoteProperty -Name "Memory" -Value $VM.MemoryGB
    Add-Member -InputObject $Object -MemberType NoteProperty -Name "VMWareToolsStatus" -Value $VM.ExtensionData.Guest.ToolsStatus
    Add-Member -InputObject $Object -MemberType NoteProperty -Name "VMWareToolsVersion" -Value $VM.ExtensionData.Guest.ToolsVersion

    #region: Disks
        #Get all disks
    $VMDisks = @()+ (Get-VMWareHardDisk -VM $VM)
        
    Add-Member -InputObject $Object -MemberType NoteProperty -Name "NumberOfDisks" -Value $VMDisks.Count
    if($VMDisks.Count -gt 0){    
            #Check for non 'flat' disks
        if(($VMDisks | select Disktype |Where-Object {$_.Disktype -ne "Flat"})) {$HasNonFlat = $true} else {$HasNonFlat = $false}
            
        Add-Member -InputObject $Object -MemberType NoteProperty -Name "HasNonFlatDisks" -Value $HasNonFlat
                
            #Concatenate disk capacities
        $DisksConcat = ""
        $VMDisks  | foreach {$DisksConcat += "$([int] $_.CapacityGB);"}
        $DisksConcat = $DisksConcat.Substring(0,$DisksConcat.Length - 1)

        Add-Member -InputObject $Object -MemberType NoteProperty -Name "DisksCapacityGB" -Value $DisksConcat
            #Calculate total capacity
        $TotalCapacity = [int]($VMDisks | Measure-Object -Property CapacityGB -sum).sum
            
        Add-Member -InputObject $Object -MemberType NoteProperty -Name "TotalCapacityGB" -Value $TotalCapacity
    }
    #endregion
    
    #region: Network
        #Get all network adapters
    $NICs = @()+ ($VM | Get-VMWareNetworkAdapter)
    Add-Member -InputObject $Object -MemberType NoteProperty -Name "NumberOfNICs" -Value $NICs.Count
        
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
        }
        $MACsConcat = $MACsConcat.Substring(0,$MACsConcat.Length - 1)
        $NetworkNamesConcat= $NetworkNamesConcat.Substring(0,$NetworkNamesConcat.Length - 1)
        $NICTypeConcat = $NICTypeConcat.Substring(0,$NICTypeConcat.Length - 1)
        $StartConnectedConcat = $StartConnectedConcat.Substring(0,$StartConnectedConcat.Length - 1)

        Add-Member -InputObject $Object -MemberType NoteProperty -Name "NicMACAddress" -Value $MACsConcat
        Add-Member -InputObject $Object -MemberType NoteProperty -Name "NicNetworkName" -Value $NetworkNamesConcat
        Add-Member -InputObject $Object -MemberType NoteProperty -Name "NicType" -Value $NICTypeConcat
        Add-Member -InputObject $Object -MemberType NoteProperty -Name "NicStartConnected" -Value $StartConnectedConcat
    }
        
        #IP Addresses
        $IPs = $() + ($VM2.Guest.IPAddress)
        if($IPs.Count -gt 0){
            $IPv4Concat = ""
            $Ipv6Concat = ""
            $IPs | foreach{    
                #IPv4
                if($_.indexOf(":") -eq -1){
                    $IPv4Concat += "$($_);"
                }
                #IPv6
                else{
                    $IPv6Concat += "$($_);"
                }
            }
            $IPv4Concat = $IPv4Concat.Substring(0,$IPv4Concat.Length - 1)
            $Ipv6Concat = $Ipv6Concat.Substring(0,$Ipv6Concat.Length - 1)

            Add-Member -InputObject $Object -MemberType NoteProperty -Name "IPv4Addresses" -Value $IPv4Concat
            Add-Member -InputObject $Object -MemberType NoteProperty -Name "IPv6Addresses" -Value $Ipv6Concat
        }
    #endregion

    $Object | Select-Object Name,FQDN,OperatingSystem,PowerState,CPUs,Memory,VMWareToolsStatus,VMWareToolsVersion,`
                        NumberOfDisks,HasNonFlatDisks,DisksCapacityGB,TotalCapacityGB,`
                        NumberOfNICs,NicMACAddress,NicNetworkName,NicType,NicStartConnected,`
                        IPv4Addresses,IPv6Addresses
} 
$Report | ogv