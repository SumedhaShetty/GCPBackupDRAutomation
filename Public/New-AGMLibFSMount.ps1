Function New-AGMLibFSMount ([string]$appid,[string]$appname,[string]$targethostname,[string]$targethostid,[string]$imageid,[string]$imagename,[string]$label,[string]$mountmode,[string]$volumes,[string]$mapdiskstoallesxhosts,[string]$mountdriveperimage,[string]$mountpointperimage,[switch][alias("g")]$guided,[switch][alias("m")]$monitor,[switch][alias("w")]$wait) 
{
    <#
    .SYNOPSIS
    Mounts a file system image

    .EXAMPLE
    New-AGMLibFSMount 

    Runs a guided menu to mount an image of an image to a host

    .DESCRIPTION
    A function to mount file system images to an existing host

    #>

    if ( (!($AGMSESSIONID)) -or (!($AGMIP)) )
    {
        Get-AGMErrorMessage -messagetoprint "Not logged in or session expired. Please login using Connect-AGM"
        return
    }
    else 
    {
        $sessiontest = (Get-AGMSession).session_id
        if ($sessiontest -ne $AGMSESSIONID)
        {
            Get-AGMErrorMessage -messagetoprint "Not logged in or session expired. Please login using Connect-AGM"
            return
        }
    }

    # if the user gave an AppID lets check it and grab an image, need to expand outside snapshots
    if ($appid)
    {
        $imagegrab = Get-AGMLibLatestImage $appid
        if (!($imagegrab.backupname))
        {
            Get-AGMErrorMessage -messagetoprint "Failed to find snapshot for AppID using:  Get-AGMLatestImage $appid"
            return
        }   
        else 
        {
            $imagename = $imagegrab.backupname
            $imageid = $imagegrab.id
        }
    }


    # if the user gave us nothing to start work, then ask for a VMware VM name
    if ( (!($appname)) -and (!($imagename)) -and (!($imageid)) -and (!($appid)) )
    {
        $guided = $true
        Clear-Host
        Write-host "File System source selection menu"
        Write-host ""
        $appgrab = Get-AGMApplication -filtervalue "apptype=FileSystem&apptype=SystemState&apptype=ConsistGrp&managed=True" | sort-object apptype,appname
        if ($appgrab.count -eq 0)
        {
            Get-AGMErrorMessage -messagetoprint "There are no File System, System State or Consistency Group apps to list"
            return
        }
        if ($appgrab.count -eq 1)
        {
            $appname =  $appgrab.appname
            $appid = $appgrab.id
            write-host "Found one $($appgrab.apptype) app $appname on $($appgrab.cluster.name)"
            write-host ""
        }
        else 
        {
            $i = 1
            foreach ($app in $appgrab)
            { 
            $app | Add-Member -NotePropertyName select -NotePropertyValue $i
            $app | Add-Member -NotePropertyName appliancename -NotePropertyValue $app.cluster.name
            $app | Add-Member -NotePropertyName hostname -NotePropertyValue $app.host.name
            $i++
            }
            Clear-Host
            write-host "Select an application"
            Write-host ""
            $appgrab | select-object select,apptype,hostname,appname,id,appliancename | Format-table *
            While ($true) 
            {
                Write-host ""
                $listmax = $appgrab.id.count
                [int]$userselection = Read-Host "Please select an app to work with (1-$listmax)"
                if ($userselection -lt 1 -or $userselection -gt $listmax)
                {
                    Write-Host -Object "Invalid selection. Please enter a number in range [1-$($listmax)]"
                } 
                else
                {
                    break
                }
            }
            $appid = $appgrab.id[($userselection - 1)]
            $appname =  $appgrab.appname[($userselection - 1)]
        }
        
        #image selection time
        Clear-Host
        $imagelist = Get-AGMImage -filtervalue "appid=$appid&jobclass=snapshot&jobclass=StreamSnap&jobclass=OnVault&jobclass=dedupasync"  | Sort-Object consistencydate,jobclasscode | select-object -Property backupname,consistencydate,id,jobclass,cluster
        if ($imagelist.backupname.count -eq 0)
        {
            Get-AGMErrorMessage -messagetoprint "Failed to fetch any snapshot, streamsnap, onvault or dedupasync Images for appid $appid"
            return
        }
        if ($imagelist.backupname.count -eq 1)
        {
            $imagegrab = Get-AGMImage -id ($imagelist).id
            $imagename = $imagegrab.backupname                
            $restorableobjects = $imagegrab.restorableobjects
        } 
        else
        {
            Clear-Host
            Write-Host "Image list.  Choose the best consistency date and jobclass."
            $i = 1
            foreach ($image in $imagelist)
            { 
                $image | Add-Member -NotePropertyName select -NotePropertyValue $i
                $image | Add-Member -NotePropertyName appliancename -NotePropertyValue $image.cluster.name
                $i++
            }

            $imagelist | select-object select,consistencydate,jobclass,appliancename,backupname,id | Format-table *
            While ($true) 
            {
                Write-host ""
                $listmax = $imagelist.Length
                [int]$imageselection = Read-Host "Please select an image (1-$listmax)"
                if ($imageselection -lt 1 -or $imageselection -gt $imagelist.Length)
                {
                    Write-Host -Object "Invalid selection. Please enter a number in range [1-$($imagelist.Length)]"
                } 
                else
                {
                    break
                }
            }
            $imageid =  $imagelist[($imageselection - 1)].id
            $imagegrab = Get-AGMImage -id $imageid
            $imagename = $imagegrab.backupname                
            $restorableobjects = $imagegrab.restorableobjects
            $mountapplianceid = $imagegrab.cluster.clusterid
            $mountappliancename = $imagegrab.cluster.name
        }
    }


    # if we got a VMware appname lets check it right now
    if ( ($appname) -and (!($appid)) )
    {
        $appgrab = Get-AGMApplication -filtervalue "appname=$appname&apptype=VMBackup"
        if ($appgrab.id.count -ne 1)
        { 
            Get-AGMErrorMessage -messagetoprint "Failed to resolve $appname to a unique valid VMBackup app.  Use Get-AGMLibApplicationID and try again specifying -appid."
            return
        }
        else {
            $appid = $appgrab.id
        }
    }

    if ($targethostname)
    {
        $hostcheck = Get-AGMHost -filtervalue hostname=$targethostname
        if ($hostcheck.id.count -ne 1)
        { 
            Get-AGMErrorMessage -messagetoprint "Failed to resolve $targethostname to a single host ID.  Use Get-AGMLibHostID and try again specifying -targethostid"
            return
        }
        else 
        {
            $hostgrab = Get-AGMHost -id $hostcheck.id
            $targethostid = $hostgrab.id
            $vmtype = $hostgrab.vmtype
            $transport = $hostgrab.transport
            $diskpref = $hostgrab.diskpref
            $vcenterid = $hostgrab.vcenterhost.id
            #if the VM doesn't have a transport, then the vCenter must have one
            if ( ($vmtype -eq "vmware") -and (!($transport)) )
            {
                $vcgrab = Get-AGMHost -filtervalue id=$vcenterid 
                $transport = $vcgrab.transport
            }
        }
    }

    # if we got a target ID lets check it
    if ($targethostid)
    {
        $hostgrab = Get-AGMHost -filtervalue id=$targethostid
        if ($hostgrab.id.count -eq -0)
        {
            Get-AGMErrorMessage -messagetoprint "Failed to resolve $targethostid to a single host ID.  Use Get-AGMLibHostID and try again specifying -targethostid"
            return
        }
        $targethostname=$hostgrab.hostname
        $vmtype = $hostgrab.vmtype
        $transport = $hostgrab.transport
        $diskpref = $hostgrab.diskpref
        $vcenterid = $hostgrab.vcenterhost.id
        if ( ($vmtype -eq "vmware") -and (!($transport)) )
        {
            $vcgrab = Get-AGMHost -filtervalue id=$vcenterid 
            $transport = $vcgrab.transport
        }
    }
    



 

    # this if for guided menu
    if ($guided)
    {
        if (!($label))
        {
            Clear-Host
            [string]$label = Read-host "Label"
        }

        # mountedhost menu
        if (!($targethostid))
        {
            $hostgrab = Get-AGMHost -filtervalue "clusterid=$mountapplianceid&hosttype!VMCluster&hosttype!esxhost" | sort-object vmtype,hostname
            if ($hostgrab.id.count -eq -0)
            {
                Get-AGMErrorMessage -messagetoprint "Failed to find any hosts on $mountappliancename"
                return
            }
            if ($hostgrab.id.count -eq 1)
            {
                $targethostid = $hostgrab.id
                $targethostname = $hostgrab.hostname
            } 
            else
            {
                Clear-Host
                Write-Host "Host List."
                $i = 1
                foreach ($hostid in $hostgrab)
                { 
                    $hostid | Add-Member -NotePropertyName select -NotePropertyValue $i
                    if (!($hostid.vmtype))
                    {
                        $hostid | Add-Member -NotePropertyName vmtype -NotePropertyValue "Physical"
                    }
                    $i++
                }

                $hostgrab | select-object select,vmtype,hostname,id | Format-table *
                While ($true) 
                {
                    Write-host ""
                    $listmax = $hostgrab.count
                    [int]$userselection = Read-Host "Please select an image (1-$listmax)"
                    if ($userselection -lt 1 -or $userselection -gt $hostgrab.Length)
                    {
                        Write-Host -Object "Invalid selection. Please enter a number in range [1-$($hostgrab.count)]"
                    } 
                    else
                    {
                        break
                    }
                }
                $targethostid = $hostgrab.id[($userselection - 1)]
                $targethostname = $hostgrab.hostname[($userselection - 1)]
                $vmtype = $hostgrab.vmtype[($userselection - 1)]
                $transport = $hostgrab.transport[($userselection - 1)]
                $diskpref = $hostgrab.diskpref[($userselection - 1)]
                $vcenterid = $hostgrab.vcenterhostid[($userselection - 1)]
                if ( ($vmtype -eq "vmware") -and (!($transport)) )
                {
                    $vcgrab = Get-AGMHost -filtervalue id=$vcenterid 
                    $transport = $vcgrab.transport
                }
            }
        }
         # if this is a VMTarget
         if ($vmtype -eq "vmware")
         {
             if (($diskpref -eq "BLOCK") -and ($transport -ne "GUESTVMISCSI"))
             {
                 Clear-Host
                 Write-Host "Mount mode" 
                 if ($transport -eq "NFS")
                 {
                     $defaultmode = 3
                     Write-Host "1`: vrdm"
                     Write-Host "2`: prdm"
                     Write-Host "3`: nfs(default)"
                 }
                 else 
                 {
                     $defaultmode = 1
                     Write-Host "1`: vrdm(default)"
                     Write-Host "2`: prdm"
                     Write-Host "3`: nfs"
                 }
                 Write-Host ""
                 [int]$userselection = Read-Host "Please select from this list (1-3)"
                 if ($userselection -eq "") { $userselection = $defaultmode }
                 if ($userselection -eq 1) {  $mountmode = "vrdm"  }
                 if ($userselection -eq 2) {  $mountmode = "prdm"  }
                 if ($userselection -eq 3) {  $mountmode = "nfs"  }
         
                 # map to all ESX host 
                 Clear-Host
                 Write-Host "Map to all ESX Hosts"
                 Write-Host "1`: Do not map to all ESX Hosts(default)"
                 Write-Host "2`: Map to all ESX Hosts"
                 Write-Host ""
                 [int]$userselection = Read-Host "Please select from this list (1-2)"
                 if ($userselection -eq "") { $userselection = 1 }
                 if ($userselection -eq 1) {  $mapdiskstoallesxhosts = "false"  }
                 if ($userselection -eq 2) {  $mapdiskstoallesxhosts = "true"  }
             }
         }

        # see if user wants mount drive or point per image
        Clear-Host
        $mountdriveperimage = ""
        $mountdriveperimage = Read-Host "Mount Drive for the image (Windows only, optional)"
        if ($mountdriveperimage -eq "")
        {
            $mountpointperimage = ""
            $mountpointperimage = Read-Host "Mount Point for the image (optional)"
        }
        # now see if user wants mount points or drives per volume
        $vollist = $restorableobjects | select-object name | sort-object name
    
        if ($vollist.count -eq 1) 
        {
            $selectedobjects = @(
                    [pscustomobject]@{restorableobject=$vollist.name}
            )
            $uservolumelistfinal = $vollist.name
        }
        else
        {
            Clear-Host
            Write-Host "Volume list (either enter 0 or a comma separated list e.g.   1,2)"
            Write-Host "0`: All volumes (default)"
            $i = 1
            foreach ($volume in $vollist.name)
            { 
                Write-Host -Object "$i`: $volume"
                $i++
            }
            [string]$userselection = Read-Host "Please select from this list (0 or comma separated list)"
            $uservolumelist = ""
            if (($userselection -eq "0") -or ($userselection -eq ""))
            {
                $selectedobjects = @(
                    foreach ($volume in $vollist.name)
                    {
                        [pscustomobject]@{restorableobject=$volume}
                    }   
                )
                foreach ($volume in $vollist.name)
                {
                    $uservolumelist = $uservolumelist + "," + $volume 
                }
                $uservolumelistfinal = $uservolumelist.substring(1)
            }
            else
            {
                $selectedobjects = @(
                    foreach ($selection in $userselection.Split(","))
                    {
                        [pscustomobject]@{restorableobject=$vollist.name[($selection - 1)]}
                    }   
                )
                foreach ($selection in $userselection.Split(","))
                {
                    $uservolumelist = $uservolumelist + "," + $vollist.name[($selection - 1)] 
                }
                $uservolumelistfinal = $uservolumelist.substring(1)
            }
        }

        Clear-Host
        Write-Host "Guided selection is complete.  The values entered would result in the following command:"
        Write-Host ""
        Write-Host -nonewline "New-AGMLibFSMount -targethostid $targethostid -imageid $imageid  -volumes `"$uservolumelistfinal`""
        if ($mountmode)
        {
            Write-Host -nonewline " -mountmode $mountmode -mapdiskstoallesxhosts $mapdiskstoallesxhosts"
        }
        if ($mountdriveperimage)
        {
            Write-Host -nonewline " -mountdriveperimage `"$mountdriveperimage`""
        }
        if ($mountpointperimage)
        {
            Write-Host -nonewline " -mountpointperimage `"$mountpointperimage`""
        }
        Write-Host ""
        Write-Host "1`: Run the command now (default)"
        Write-Host "2`: Show the JSON used to run this command, but don't run it"
        Write-Host "3`: Exit without running the command"
        $userchoice = Read-Host "Please select from this list (1-3)"
        if ($userchoice -eq 2)
        {
            $jsonprint = "yes"
        }
        if ($userchoice -eq 3)
        {
            return
        }
    }
        
    # if user asked for volumes
    if ($volumes)
    {
        $selectedobjects = @(
            foreach ($volume in $volumes.Split(","))
            {
                [pscustomobject]@{restorableobject=$volume}
            }   
        )
    }
    
    if (!($imageid))
    {
        [string]$imageid = Read-Host "ImageID to mount"
    }

    if (!($imagename))
    {
        $imagename = (Get-AGMImage -id $imageid).backupname
    }

    if (!($mountmode))
    {
        $physicalrdm = 0
        $rdmmode = "independentvirtual"
    }
    else 
    {
        if ($mountmode -eq "vrdm")
        {
            $physicalrdm = 0
            $rdmmode = "independentvirtual"
        }
        if ($mountmode -eq "prdm")
        {
            $physicalrdm = 1
            $rdmmode = "physical"
        }
        if ($mountmode -eq "nfs")
        {
            $physicalrdm = 2
            $rdmmode = "nfs"
        }
    }

    if ($mapdiskstoallesxhosts)
    {
        if (($mapdiskstoallesxhosts -ne "true") -and  ($mapdiskstoallesxhosts -ne "false"))
        {
            Get-AGMErrorMessage -messagetoprint "The value of Map to all ESX hosts of $mapdiskstoallesxhosts is not valid.  Must be true or false"
            return
        }
        $restoreoptions = @(
            @{
                name = 'mapdiskstoallesxhosts'
                value = "$mapdiskstoallesxhosts"
            }
        )
    }

    if ($mountpointperimage)
    {
        if ($restoreoptions)
        {
            $imagemountpoint = @{
                name = 'mountpointperimage'
                value = "$mountpointperimage"
            }
            $restoreoptions = $restoreoptions + $imagemountpoint
        }
        else 
        {
            $restoreoptions = @(
            @{
                name = 'mountpointperimage'
                value = "$mountpointperimage"
            }
        )
        }
    }

    if ($mountdriveperimage)
    {
        if ($restoreoptions)
        {
            $imagemountpoint = @{
                name = 'mountdriveperimage'
                value = "$mountdriveperimage"
            }
            $restoreoptions = $restoreoptions + $imagemountpoint
        }
        else 
        {
            $restoreoptions = @(
            @{
                name = 'mountdriveperimage'
                value = "$mountdriveperimage"
            }
        )
        }
    }


    if (!($label))
    {
        $label = ""
    }

    $body = [ordered]@{
        label = $label;
        image = $imagename;
        host = @{id=$targethostid}
        migratevm = "false";
    }
    if ($restoreoptions)
    {
        $body = $body + [ordered]@{ restoreoptions = $restoreoptions }
    }
    if ($selectedobjects)
    {
        $body = $body + [ordered]@{ selectedobjects = $selectedobjects }
    }
    if ($mountmode)
    {
        $body = $body + @{ physicalrdm = $physicalrdm }
        $body = $body + @{ rdmmode = $rdmmode }
    }
    if ($restoreobjectmappings)
    {
        $body = $body + @{ restoreobjectmappings = $restoreobjectmappings }
    }


    $json = $body | ConvertTo-Json

    if ($monitor)
    {
        $wait = "y"
    }

    if ($jsonprint -eq "yes")
    {
        $compressedjson = $body | ConvertTo-Json -compress
        Write-host "This is the final command:"
        Write-host ""
        Write-host "Post-AGMAPIData  -endpoint /backup/$imageid/mount -body `'$compressedjson`'"
        return
    }

    Post-AGMAPIData  -endpoint /backup/$imageid/mount -body $json
    if ($wait)
    {
        Start-Sleep -s 15
        $jobgrab = Get-AGMJob -filtervalue "appid=$appid&jobclasscode=5&isscheduled=false&targethost=$targethostname" -sort queuedate:desc -limit 1 
        if (!($jobgrab.jobname))
        {
            Start-Sleep -s 15
            $jobgrab = Get-AGMJob -filtervalue "appid=$appid&jobclasscode=5&isscheduled=false&targethost=$targethostname" -sort queuedate:desc -limit 1 
            if (!($jobgrab.jobname))
            {
                return
            }
        }
        else
        {   
            $jobgrab| select-object jobname,status,queuedate,startdate,targethost
            
        }
        if (($jobgrab.jobname) -and ($monitor))
        {
            Get-AGMFollowJobStatus $jobgrab.jobname
        }
    }
}
