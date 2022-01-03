#todo: add metadata to base class since its consistent across objects

class k8 {
    hidden [object]$_Raw
    #### Metadata ####
    [hashtable]$Annotations
    [datetime]$CreationTime
    [Age]$Age
    [hashtable]$Labels
    [string]$Name
    [string]$ClusterContext
    #resourceVersion                     #probably dont need this
    #SelfLink                            #probably dont need it
    [GUID]$uid

    k8([object]$rawData, $context){
        
        $this._Raw = $rawData
        $this.ClusterContext = $context
        $this.name = $this._Raw.metadata.Name
        $this.creationTime = (get-date $this._Raw.metadata.creationTimestamp).ToLocalTime()
        $this.Age = [Age]::New($this.CreationTime)
        #convert labels to a hash table for easier lookups/searching
        $this.labels = ([k8]$this).convertToHash($this._Raw.metadata.labels)
        $this.Annotations = ([k8]$this).convertToHash($this._Raw.metadata.annotations)
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

    hidden [hashtable] convertToHash([object]$obj){
        return $obj.psobject.properties | foreach-object {$hash=@{}} {$hash."$($_.name)" = $_.value } {$hash}
    }
}