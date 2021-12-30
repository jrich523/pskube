class k8Node : k8 {
    #Region Properties
        #### Custom ####
        ## these are typically derived from multiple fields, need to look to kubectl to see what it does
        [string]$Status
        [string]$Role #based off label data
    
        #### Spec ####
        [string]$ProviderID
    
        #### Status ####
        [hashtable]$Addresses
        ## collapse to single Resource property
        [object]$Resources #todo: create class
        [object]$DaemonEndpoints
        [object]$Images
        [hashtable]$OsInfo

        #EKS labels
        [string]$Zone
        [string]$Nodegroup
        [string]$InstanceId
        [string]$Region
        [string]$EksCluster
        [string]$InstanceType



    #EndRegion
    
        k8Node([Object]$rawData, $context) : base($rawData, $context)
        {
            #Region Set Properties 
            #$this.Status = $this._Raw.status.conditions | ? type -eq 'Ready' | select -ExpandProperty status
            $this.role = $this.labels.'kubernetes.io/role'
            #Spec
            $this.ProviderID = $this._Raw.spec.providerID
            #Status
            $this.Addresses = $this._raw.status.addresses | %{$h=@{}}{ $h[$_.type]=$_.value}{$h}
            $this.OsInfo = ([k8]$this).convertToHash($this._raw.status.nodeInfo)
            $this.images = $this._raw.status.images

            #Expose EKS Labels
            $this.zone = $this.labels.'failure-domain.beta.kubernetes.io/zone'
            $this.nodegroup = $this.labels.'alpha.eksctl.io/nodegroup-name'
            $this.instanceId = $this.labels.'alpha.eksctl.io/instance-id'
            $this.region = $this.labels.'failure-domain.beta.kubernetes.io/region'
            $this.eksCluster = $this.labels.'alpha.eksctl.io/cluster-name'
            $this.instanceType = $this.labels.'beta.kubernetes.io/instance-type'
            
            $this.psobject.properties.add(
            (new-object PSScriptProperty 'Status', {$this._getStatus()})
            )

    #EndRegion
            # Default Display Set
            $defaultdisplay = @('Name','Status','Role', 'Age','Version')
            ([k8]$this).addDefaultDisplaySet($defaultdisplay)
        }
    
        [string] getAgeDisplay() {
            return ([k8]$this).getAge($this.creationTime)
        }

        hidden [string] _getStatus() {
            $sts = "Not Ready" #default status
            if($st = $this._Raw.status.conditions | ? reason -eq 'KubeletReady' | select -ExpandProperty Type){$sts = $st}
            if($this._Raw.spec.taints.key -contains 'node.kubernetes.io/unschedulable')
            {
                $sts += ", SchedulingDisabled"
            }
    
            return $sts
        }
}