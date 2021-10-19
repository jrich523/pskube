#todo: add metadata to base class since its consistent across objects

class k8 {
    hidden [object]$_Raw
    #### Metadata ####
    [hashtable]$Annotations
    [datetime]$CreationTime
    [hashtable]$Labels
    [string]$Name
    [string]$Namespace
    [string]$ClusterContext
    #resourceVersion                     #probably dont need this
    #SelfLink                            #probably dont need it
    [GUID]$uid

    k8([object]$rawData){
        
        $this._Raw = $rawData
        $this.ClusterContext = Get-k8Context -Current | select-object -ExpandProperty name
        $this.name = $this._Raw.metadata.Name
        $this.creationTime = (get-date $this._Raw.metadata.creationTimestamp).ToLocalTime()
        #convert labels to a hash table for easier lookups/searching
        $this.labels = ([k8]$this).convertToHash($this._Raw.metadata.labels)
        $this.Annotations = ([k8]$this).convertToHash($this._Raw.metadata.annotations)
        $this.Namespace = $this._Raw.metadata.namespace
        $this.uid = [GUID]$this._Raw.metadata.uid
    }

    [string] ToString(){
        return $this.name
    }

    hidden addDefaultDisplaySet([string[]]$defaultDisplaySet)
    {
        #set is an array of property names
        # set to [string[]]?
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',[string[]]$defaultDisplaySet)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
        Add-Member -InputObject $this -MemberType MemberSet -Name PSStandardMembers -Value $PSStandardMembers
    }

    hidden [string] getAge([Datetime]$startDate)
    {
        return $this.getAge($startDate,(get-date))
    }

    hidden [string] getAge([Datetime]$startDate, [Datetime]$endDate)
    {
        $rtn = "Err!"
        $ts = new-timespan  -Start (get-date $startDate) -end (get-date $endDate)
        
        if($ts.Days)
        {
            $rtn = "$($ts.Days)d"
            if($ts.days -lt 5 -and $ts.Hours -gt 3)
            {
                $rtn += "$($ts.Hours)h"
            }
        }
        elseif ($ts.Hours) {
            $rtn = "$($ts.Hours)h"
            if($ts.Hours -lt 3 -and $ts.Minutes -gt 15)
            {
                $rtn += "$($ts.Minutes)m"
            }
        }
        elseif ($ts.Minutes) {
            $rtn = "$($ts.minutes)m"
            if($ts.Minutes -lt 5 -and $ts.seconds -gt 15)
            {
                $rtn += "$($ts.seconds)s"
            }
        }
        else {
            $rtn = "$($ts.Seconds)s"
        }
        return $rtn
    }

    hidden [hashtable] convertToHash([object]$obj){
        return $obj.psobject.properties | foreach-object {$hash=@{}} {$hash."$($_.name)" = $_.value } {$hash}
    }
}