class k8Pod : k8Namespaced {
#Region Properties
    #### Custom ####
    ## these are typically derived from multiple fields, need to look to kubectl to see what it does
    [string]$Ready
    [int]$Restarts

    #### Spec ####
    [array]$Containers
    [string]$DNSPolicy
    [bool]$EnableServiceLinks
    [string]$NodeName
    [int]$Priority #todo probably an enum?
    [string]$RestartPolicy #todo enum?
    [string]$ScheduleName
    [string]$securityContext #not sure what this is, probably need to convert to a hash table
    [string]$ServiceAccount
    [string]$ServiceAccountName
    [int]$TerminationGracePeriodSeconds #timespan? probably not
    #need to probably udpate these types, or at least set the array type
    [Array]$Tolerations
    [Array]$Volumes

    #### Status ####
    #conditions - address
    #containerStatuses - address
    [ipaddress]$HostIP
    [string]$Status #PHASE: Does a pod have a status? currently just using Phase, might need more
    [ipaddress]$PodIP
    [string]$QOSClass
    [nullable[Datetime]]$StartTime

    #Common labels
    [string] $App
    [version] $Version
#EndRegion

    k8Pod([Object]$rawData, $context) : base($rawData, $context)
    {
#Region Set Properties
        Write-Debug "Creating pod $($this.name) in namespace $($this.namespace)"
        $this.Ready = $this._Raw.status.containerStatuses.Ready | measure -sum | %{ "$([int]$_.sum)/$([int]$_.count)"}
        #$this.Status = $this._Raw.status.phase
        $this.HostIP = $this._Raw.status.HostIP
        $this.PodIP = $this._Raw.status.PodIP
        $this.QOSClass = $this._Raw.status.qosClass
        $this.startTime = if($this._Raw.status.startTime){(get-date $this._Raw.status.startTime).ToLocalTime()}
        $this.Restarts = $this._Raw.status.containerStatuses.restartCount | Measure-Object -sum | Select-Object -ExpandProperty sum

        #Metadata
        
        #Spec
        $this.containers = $this._Raw.spec.containers #todo object conversion
        $this.DNSPolicy = $this._Raw.spec.dnsPolicy
        $this.EnableServiceLinks = $this._Raw.spec.EnableServiceLinks
        $this.NodeName = $this._Raw.spec.NodeName
        $this.priority = $this._Raw.spec.priority
        $this.RestartPolicy = $this._Raw.spec.RestartPolicy
        $this.ScheduleName = $this._Raw.spec.ScheduleName
        $this.securityContext = $this._Raw.spec.securityContext
        $this.ServiceAccount = $this._Raw.spec.ServiceAccount
        $this.serviceAccountName = $this._Raw.spec.serviceAccountName
        $this.TerminationGracePeriodSeconds = $this._Raw.spec.TerminationGracePeriodSeconds
        $this.tolerations = $this._Raw.spec.tolerations #todo object conversion
        $this.Volumes = $this._Raw.spec.volumes #todo object conversion

        #Common labels
        $this.App = $this.labels.app

        $stripversion = $this.labels.version -replace 'v',''
        $this.Version = if($stripversion -as [version]){$stripversion}

        #Status
        $this.psobject.properties.add(
            (new-object PSScriptProperty 'Status', {$this._getStatus()})
        )
        
#EndRegion
        # Default Display Set
        $defaultdisplay = @('Name','Ready','Status','Restarts','Age','App','Version')
        ([k8]$this).addDefaultDisplaySet($defaultdisplay)
    }

    hidden [string] _getStatus() {
        $sts = if($this._raw.metadata.deletiontimestamp){
            "Terminating"
        }
        else {
            $this._raw.status.phase
        }

        return $sts
    }
}