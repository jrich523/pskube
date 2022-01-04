#Region '.\classes\age.ps1' 0
class Age : System.IComparable {
    [datetime]$CreationTime
    static hidden [regex] $regex = [regex]'^(\d+\w)+$'

    age([datetime]$CreationTime){
        $this.CreationTime = $CreationTime
        $this.SharedConstructor()
    }

    age([String]$CreationTime){
        if($CreationTime -as [datetime]){
            $this.CreationTime = [datetime]$CreationTime
        }
        elseif ($CreationTime -match [age]::regex)
        {
            $this.CreationTime = [age]::ConvertFromString($CreationTime).CreationTime
        }
        else{
            # This probably needs to throw an actual error
            write-error "Invalid value"
        }
        $this.SharedConstructor()
    }

    age(){
        $this.CreationTime = Get-Date
        $this.SharedConstructor()
    }
    
    hidden SharedConstructor(){
        $this.psobject.properties.add(
            (new-object PSScriptProperty 'Age', {$this.ToString()})
        )
    }

    static [Age] ConvertFromString([string]$age)
    {
        if($age -as [datetime])
        {
            return [Age]::New([datetime]$age)
        }
        elseif(($m=[age]::regex.Match($age)).success){
            $ts = New-Object timespan
            $units=$m.groups[1].captures.value
            foreach ($u in $units) {
                $digit = $u.trimEnd('d','h','m','s') # dont cast to int incase an unsupported unit is provided.
                switch ($u[-1]) {
                    "d" {$ts += New-TimeSpan -Days $digit }
                    "h" {$ts += New-TimeSpan -Hours $digit}
                    "m" {$ts += New-TimeSpan -Minutes $digit}
                    "s" {$ts += New-TimeSpan -Seconds $digit}
                    Default { write-error "Invalid unit type!" }
                }
            }
            $dt = (get-date).AddSeconds($ts.TotalSeconds *-1 )
            return [age]::new($dt)
        }
        else {
            write-error "Invalid String format!"
            return $null
        }
    }

    [timespan]GetTimeSpan(){
        return New-TimeSpan -Start $this.CreationTime -End (get-date)
    }

    [string] ToString(){
        $rtn = "Err!"
        $ts = $this.GetTimeSpan()
        
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

    [int] CompareTo([object] $obj) {
        # If is a string in the 1m14s type notation
        if($obj -is [string] -and $obj -match [age]::regex){
            $obj = [Age]::ConvertFromString($obj)
        }
        # If its an age object provided, or convert from above If
        if($obj -is [age]){
            # convert to datetime for next If
            $obj = $obj.CreationTime
        }
        if($obj -as [datetime]) { # the -as allows handling of datetime in string format
            if ($this.CreationTime -gt $obj) {return -1}
            if ($this.CreationTime -eq $obj) {return 0}
            if ($this.CreationTime -lt $obj) {return 1}
            return $null
        }
        if ($obj -is [timespan]) {
            if ($this.GetTimeSpan() -gt $obj) {return -1}
            if ($this.GetTimeSpan() -eq $obj) {return 0}
            if ($this.GetTimeSpan() -lt $obj) {return 1}
            return $null
        }
        return $null
    }
}
#EndRegion '.\classes\age.ps1' 125
#Region '.\classes\helperClasses.ps1' 0
class k8Condition {
    [datetime]$LastHeartbeatTimestamp
    [datetime]$LastTransitionTimestamp
    [string]$Message
    [string]$Reason
    [bool]$Status
    [string]$Type #todo: enum
}

class k8Resources {
    
}
#https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.17/#serviceport-v1-core
class k8ServicePort {
    
    [string]$Name
    [int]$NodePort
    [int]$Port
    [string]$Protocol #todo: convert to enum: tcp/udp/sctp default: tcp
    <#
    Number or name of the port to access on the pods targeted by the service.
    Number must be in the range 1 to 65535. Name must be an IANA_SVC_NAME.
    If this is a string, it will be looked up as a named port in the target Pod's container ports.
    If this is not specified, the value of the 'port' field is used (an identity map).
    This field is ignored for services with clusterIP=None, and should be omitted or set equal to the 'port' field.
    More info: https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service
    #>
    $targetPort #todo: type depends on returned data, int/string

    k8ServicePort($servicePort){
        $this.name = $servicePort.name
        $this.NodePort = $servicePort.NodePort
        $this.Port = $servicePort.Port
        $this.Protocol = $servicePort.Protocol
    }
    [string] ToString(){
        return "$($this.port)/$($this.protocol)"
    }

}
#EndRegion '.\classes\helperClasses.ps1' 41
#Region '.\classes\k8.ps1' 0
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
<#
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
#>
    hidden [hashtable] convertToHash([object]$obj){
        return $obj.psobject.properties | foreach-object {$hash=@{}} {$hash."$($_.name)" = $_.value } {$hash}
    }
}
#EndRegion '.\classes\k8.ps1' 84
#Region '.\classes\k8deployment.ps1' 0
#https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.17/#deployment-v1-apps

class k8Deployment : k8 {
    #Region Properties
        #### Spec ####
        [int]$minReadySeconds
        [bool]$paused
        [int]$progressDeadlineSeconds
        [int]$replicaSpec
        [int]$revisionHistoryLimit #default: 10
        [object]$selector
        [object]$strategy
        [object]$template

        #### Status ####
        [int]$availableReplicas
        [int]$collisionCount
        [object]$conditions
        [int]$observedGeneration
        [int]$readyReplicas
        [int]$replicas
        [int]$unavailableReplicas
        [int]$updatedReplicas


    #EndRegion
    
        k8Deployment([Object]$rawData, $context) : base($rawData, $context)
        {
    #Region Set Properties
            $this.minReadySeconds = $this._Raw.spec.minReadySeconds
            $this.paused = $this._Raw.spec.paused
            $this.progressDeadlineSeconds = $this._Raw.spec.progressDeadlineSeconds
            $this.replicaSpec = $this._Raw.spec.replicas
            $this.revisionHistoryLimit = $this._Raw.spec.revisionHistoryLimit
            $this.selector = $this._Raw.spec.selector
            $this.strategy = $this._Raw.spec.strategy
            $this.template = $this._Raw.spec.template
            
            #Status
            $this.availableReplicas = $this._Raw.status.availableReplicas
            $this.collisionCount = $this._Raw.status.collisionCount
            $this.conditions = $this._Raw.status.conditions
            $this.observedGeneration = $this._Raw.status.observedGeneration
            $this.readyReplicas = $this._Raw.status.readyReplicas
            $this.replicas = $this._Raw.status.replicas
            $this.unavailableReplicas = $this._Raw.status.unavailableReplicas
            $this.updatedReplicas = $this._Raw.status.updatedReplicas
            
    #EndRegion
            # Default Display Set
            $defaultdisplay = @('Name','Ready','updatedReplicas','readyreplicas','Age')
            ([k8]$this).addDefaultDisplaySet($defaultdisplay)
        }
    
        [string] getAgeDisplay() {
            return ([k8]$this).getAge($this.CreationTime)
        }
    }
#EndRegion '.\classes\k8deployment.ps1' 60
#Region '.\classes\k8ingress.ps1' 0
class k8Ingress : k8 {
    #Region Properties
        #### Spec ####
        $Hosts #dont set type so it adapts to array only when needed
        $Ports ##same
        $Controller
        $Rules

        #### Status ####
        #none of value?

    #EndRegion
    
        k8Ingress([Object]$rawData, $context) : base($rawData, $context)
        {
    #Region Set Properties          
            #Spec
            #todo this should probably be changes, since its masking that the port is per host
            $this.hosts = $this._Raw.spec.rules.host
            $this.ports = $this._Raw.spec.rules.http.paths.backend.serviceport | Get-Unique
            $this.controller = $this.annotations.'kubernetes.io/ingress.class'
            $this.rules = $this._raw.spec.rules
            #Status
            
    #EndRegion
            # Default Display Set
            $defaultdisplay = @('Name','Hosts','Ports','Age')
            ([k8]$this).addDefaultDisplaySet($defaultdisplay)
        }
    
        [string] getAgeDisplay() {
            return ([k8]$this).getAge($this.CreationTime)
        }
    }
#EndRegion '.\classes\k8ingress.ps1' 35
#Region '.\classes\k8namespace.ps1' 0
class k8Namespaced : k8 {
#Region Properties
    #### Metadata ####
    [string]$Namespace
#EndRegion
    
    k8Namespaced([Object]$rawData, $context) : base($rawData, $context)
    {
#Region Set Properties
        
    $this.Namespace = $this._Raw.metadata.namespace
#EndRegion
        # Default Display Set
        #$defaultdisplay = @('Name','Ready','Status','Restarts','Age')
        #([k8]$this).addDefaultDisplaySet($defaultdisplay)
    }
    <#
    [string] getAgeDisplay() {
        return ([k8]$this).getAge($this.creationTime)
    }
    #>
}
#EndRegion '.\classes\k8namespace.ps1' 23
#Region '.\classes\k8node.ps1' 0
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
#EndRegion '.\classes\k8node.ps1' 76
#Region '.\classes\k8pod.ps1' 0
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
<#
    [string] getAgeDisplay() {
        if($this.startTime)
        {
            return ([k8]$this).getAge($this.startTime)
        }
        return $null
    }
#>
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
#EndRegion '.\classes\k8pod.ps1' 103
#Region '.\classes\k8service.ps1' 0
#https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.17/#service-v1-core

class k8Service : k8 {
    #Region Properties
        [string]    $ELB
        #### Spec ####
        [string]    $clusterIP               #use ipaddress type
        [string[]]  $externalIP              #use ipaddress type
        [string]    $externalName
        [string]    $externalTrafficPolicy
        [int]       $healthCheckNodePort
        [string]    $ipFamily
        [string]    $loadBalancerIP
        [string[]]  $loadBalancerSourceRanges
                    $ports                   #class -> ServicePort
        [bool]      $publishNotReadyAddresses
        [object]    $selector                #hash?
        [string]    $sessionAffinity
                    $sessionAffinityConfig   #custom type SessionAffinityConfig
        [string[]]  $topologyKeys
        [string]    $type
        
        #### Status ####
        [object]    $loadBalancer           #custom type LoadBalancerStatus
    #EndRegion
    
        k8Service([Object]$rawData, $context) : base($rawData, $context)
        {
    #Region Set Properties
            $this.clusterip = $this._raw.spec.clusterip
            $this.externalname = $this._raw.spec.externalname
            $this.externaltrafficpolicy = $this._raw.spec.externaltrafficpolicy
            $this.healthCheckNodePort = $this._raw.spec.healthCheckNodePort
            $this.ipFamily = $this._raw.spec.ipFamily
            $this.loadbalancerip = $this._raw.spec.loadbalancerip
            $this.loadbalancersourceranges = $this._raw.spec.loadbalancersourceranges
            $this.ports = $this._Raw.spec.ports | %{ new-object k8serviceport $_}
            $this.publishNotReadyAddresses = $this._raw.spec.publishNotReadyAddresses
            $this.selector = $this._raw.spec.selector
            $this.sessionAffinity = $this._raw.spec.sessionAffinity
            $this.sessionAffinityConfig = $this._raw.spec.sessionAffinityConfig
            $this.topologyKeys = $this._raw.spec.topologyKeys
            $this.type = $this._raw.spec.type
            
            #Status
            $this.loadBalancer = $this._raw.status.loadBalancer
            $this.elb = $this.loadbalancer.ingress.hostname
            #this is a standard field that im overwritting, might be a bad idea
            $this.externalIP = if($this._raw.spec.externalip){$this._raw.spec.externalip}else{$this.elb}

    #EndRegion
            # Default Display Set
            $defaultdisplay = @('Name','Type','ClusterIP','ExternalIP','Ports','Age')
            ([k8]$this).addDefaultDisplaySet($defaultdisplay)
        }
    
        [string] getAgeDisplay() {
            return ([k8]$this).getAge($this.CreationTime)
        }
    }
#EndRegion '.\classes\k8service.ps1' 61
#Region '.\private\completers.ps1' 0
[scriptblock]$ctxCompleter = {
    param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $allCtx = get-k8context | select -ExpandProperty name
    $allCtx | ? {$_ -like "*$wordToComplete*"}
}
[scriptblock]$podCompleter = {
    param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $allCtx = get-k8pod | select -ExpandProperty name
    $allCtx | ? {$_ -like "*$wordToComplete*"}
}

[scriptblock]$nsCompleter = {
    param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $allCtx = get-k8namespace | select -ExpandProperty name
    $allCtx | ? {$_ -like "*$wordToComplete*"}
}


Register-ArgumentCompleter -CommandName 'set-k8context','switch-k8Context' -ParameterName 'Name' -ScriptBlock $ctxCompleter
Register-ArgumentCompleter -CommandName 'Get-K8Pod','Get-K8PodLog','Enter-k8Pod' -ParameterName 'Name' -ScriptBlock $podCompleter
Register-ArgumentCompleter -CommandName 'get-k8namespace','Set-k8ActiveNamespace' -ParameterName 'Name' -ScriptBlock $nsCompleter


$both = @(
    'Enter-k8Pod',
    'Get-K8Deployment',
    'Get-K8Ingress',
    'Get-k8Log',
    'Get-K8Pod',
    'Get-K8Service'
)


Register-ArgumentCompleter -commandName $both -parameterName 'Namespace' -scriptblock $nsCompleter
$contextOnly =  $both + 'Get-K8Namespace'
Register-ArgumentCompleter -commandName $contextOnly -parameterName 'Context' -scriptblock $ctxCompleter
#EndRegion '.\private\completers.ps1' 37
#Region '.\private\config.ps1' 0
#todo this should be handled by the config manager

# CONFIGURATION OPTIONS


$script:K8CTXCACHE = @{
    lastUpdate=$null;
    data=$null;
    updated=$false
    timeout= new-timespan -Seconds 2;
    command="config", "get-contexts";
}

$script:K8NSCACHE = @{
    lastUpdate=$null;
    data=$null;
    updated=$false;
    timeout=new-timespan -Seconds 2; ## short timeout because in many cases this is called twice in short order
    command="get","ns","-o=json"
}

$script:K8DEFAULTNS = 'default' #in case for some reason you dont use default as the default
#EndRegion '.\private\config.ps1' 23
#Region '.\private\ConvertFromFixedSize.ps1' 0
function ConvertFromFixedSize
{
    [cmdletbinding()]
    param(
    [Parameter(Mandatory=$true,
               ValueFromPipeline=$true)]
    $data
    )

    function wordIndex{
        param($header)

        $indexes = @()
        $isWord = $false
        $chars = $header.ToCharArray()
        for($i =0; $i -lt $chars.Length; $i++ ){
            $c = $chars[$i]
            if($c -match "\s" -and $isWord){
                $isWord=$false
            }
            elseif ($c -notmatch "\s" -and -not $isWord) {
                $isWord=$true
                $indexes+=$i
            }
        }
        return $indexes
    }
    function chopData{
        param($str,$indexes)
            $current = $indexes[0]
            $indexes | select -skip 1 | %{
                $str.substring($current,($_ - $current)).trim();
                $current = $_
            
            }
            $str.substring($current).trim()
    }
    #if($data -isnot [array]){$data = $data -split "`n"}
    #$data = $data |%{$_.trimend()} | ? {$_} 

    #assume header
    $indexes = wordIndex $data[0]
    Write-Verbose -Verbose "Indexes $($indexes -join ' ')"

    #under the assumption that the first row is header, use those for property names
    $header = chopData $data[0] $indexes
    Write-Verbose -Verbose "headers: $header"

    #chop up data and spit out objects
    $data | Select -skip 1 | %{ chopData $_ $indexes | %{$i=0;$h=@{}}{ $h.($header[$i]) = $_;$i++}{[pscustomobject]$h}}
}

#EndRegion '.\private\ConvertFromFixedSize.ps1' 53
#Region '.\private\functionTemplates.ps1' 0
$script:get_namespaced = @'
function Get-K8<<KIND>>
{
    [cmdletBinding(DefaultParameterSetName="allns")]
    <<ALIAS>>
    param(
            $Name='*',
            [Parameter(Mandatory=$false, ParameterSetName="namespace")]
            $Namespace,
            [Parameter(Mandatory=$false, ParameterSetName="allns")]
            [switch]$all,
            $Context
        )
        $cmds = "get", "<<KIND>>","-o=json"
        if($all){$cmds += "--all-namespaces"}
        elseif($namespace){$cmds += "--namespace=$namespace"}
        if($context){$cmds += "--context=$context"}
        kubeWrapper -kubeArgs $cmds | ConvertFrom-Json | newk8object | Where-Object { $_.name -like $Name}
}
'@

$script:get_cluster = @'
function Get-K8<<KIND>>
{
    <<ALIAS>>
    param(
            $Name='*',
            $Context
        )
        $cmds = "get", "<<KIND>>","-o=json"
        if($context){$cmds += "--context=$context"}
        kubeWrapper -kubeArgs $cmds | ConvertFrom-Json | newk8object | Where-Object { $_.name -like $Name}
}
'@
#EndRegion '.\private\functionTemplates.ps1' 35
#Region '.\private\getCachedData.ps1' 0
function GetCachedData {
[cmdletBinding()]
param(
    $CacheObject,
    [switch]$Refresh
)
    $lastUpdate = $CacheObject.lastUpdate
    $needsUpdate = if($lastUpdate){
        (New-TimeSpan -Start $lastUpdate -End (get-date)) -gt $CacheObject.timeout
    }else{$true}

    # forcing an update if you request current. Feels like that could be problematic otherwise
    if($needsUpdate -OR $Refresh)
    {
        Write-Verbose "[GetCachedData] Updading object Cache"
        $CacheObject.data = kubeWrapper -kubeArgs ($CacheObject.command)
        $CacheObject.lastUpdate = Get-Date
        $CacheObject.updated = $true
    }
    else
    {
        Write-Verbose "[GetCachedData] Using Cache"
        $CacheObject.updated = $false   
    }
    $CacheObject
}
#EndRegion '.\private\getCachedData.ps1' 27
#Region '.\private\newk8objects.ps1' 0

function newK8Object {
    [cmdletBinding()]
    param (
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true)]
        $inputObject,
        $Context
    )  
    begin{
        if(!$Context)
        {
            $Context=Get-k8Context -Current | select-object -ExpandProperty name
        }
    }
    process {
        if($inputObject.kind) #k8 object
        {
            $class = "k8$($inputObject.kind)"
            write-debug "[newK8Object] K8 Object detected"
            if($inputObject.kind -eq "List")
            {
                write-debug "[newK8Object] Detected list, processing sub items"
                $inputObject.items | newK8Object
            }
            elseif ( $class -as [type]) {
                write-debug "[newK8Object] Creating object from kind $($inputobject.kind)"
                new-object -TypeName $class -ArgumentList $inputObject, $Context
            }
            else {
                if($inputObject.metadata.namespace)
                {
                    write-debug "[newK8Object] Creating object from kind $($inputobject.kind) as K8namespaced object"
                    $objs = new-object -TypeName "k8namespaced" -ArgumentList $inputObject, $context
                }
                else
                {
                    write-debug "[newK8Object] Creating object from kind $($inputobject.kind) as K8 object"
                    $objs = new-object -TypeName "k8" -ArgumentList $inputObject, $context
                }
                $objs | ForEach-Object { $_.PSObject.TypeNames.Insert(0,$class)}
                $objs
            }
        }
        else {
            Write-Error "unable to process object! No 'Kind' Found!"
        }
    }
    end {}
    }
#EndRegion '.\private\newk8objects.ps1' 51
#Region '.\private\utilities.ps1' 0
<#
# in public for now so that i can easily use the kubectl cmds diretly
function kubeWrapper {
    $ns = if($env:KUBECTL_NAMESPACE){$env:KUBECTL_NAMESPACE}else{'default'; $env:KUBECTL_NAMESPACE = 'default'}
    $args = @("--namespace=$ns") + $args | %{$_}
    Write-Verbose "Arguments: $args"
    kubectl $args
}
#>

#EndRegion '.\private\utilities.ps1' 11
#Region '.\public\Enter-k8Pod.ps1' 0
function Enter-k8Pod {
[cmdletBinding()]    
[Alias("ekp")]
param(
    $Name,
    $container,
    [switch]$sh,
    $Namespace,
    $Context
)
    $cmd = if($sh){ 'sh'} else { 'bash'}
    $containerArg = if($container){ "-c $container"}
    $cmdArgs = ("exec","-it",$Name,$containerArg,"--",$cmd)
    if($namespace){$cmdArgs += "--namespace=$namespace"}
    if($context){$cmdArgs += "--conext=$conext"}

    kubeWrapper -kubeArgs $cmdArgs
}
#EndRegion '.\public\Enter-k8Pod.ps1' 19
#Region '.\public\Get-k8ActiveNamespace.ps1' 0
function Get-k8ActiveNamespace {
[Alias("gkan")]
param()
    if($env:KUBECTL_NAMESPACE){
        $env:KUBECTL_NAMESPACE
    }
    else {
        $script:K8DEFAULTNS
    }
}
#EndRegion '.\public\Get-k8ActiveNamespace.ps1' 11
#Region '.\public\Get-k8Context.ps1' 0
# This is mostly because the prompt shows the context and there is a slight delay to query that
# this also applies to the auto complete, it appears it does the query each tab, rather than cycle from the first query
function Get-k8Context {
[cmdletBinding()]
param(
    $Name,
    [switch]$Current,
    [switch]$Refresh
)
    $cacheObject = $script:K8CTXCACHE

    $cacheObject = getCachedData $cacheObject -refresh:$Refresh
    if($cacheObject.updated)
    {
        $cacheObject.data = $cacheObject.data | % { $_ -replace "\s{2,}","," } | ConvertFrom-Csv
        $cacheObject.data | % {$_.pstypenames.insert(0,'k8s.context')}
        $cacheObject.updated = $false
    }
    $contexts = $cacheObject.data
    if($current)
    {
        if($env:KUBECTL_CONTEXT)
        {
            Write-Verbose "[Get-k8Context] Filtering for current context by Env Context"
            $context | where-object {$_.name -eq $env:KUBECTL_CONTEXT}
        }
        else {
            Write-Verbose "[Get-k8Context] Filtering for current context"
            $contexts | Where-Object {$_.current} 
        }
    }
    elseif ($name) {
        Write-Verbose "[Get-k8Context] Filtering name by $name"
        $contexts | Where-Object {$_.name -like $Name}
    }
    else
    {
        write-verbose "[Get-k8Context] Returning all"
        $contexts
    }
}
#EndRegion '.\public\Get-k8Context.ps1' 42
#Region '.\public\Get-k8Deployment.ps1' 0
function Get-K8Deployment {
    [cmdletBinding(DefaultParameterSetName="allns")]
    [Alias("gkd")]
    param(
        $Name='*',
        [Parameter(Mandatory=$false, ParameterSetName="namespace")]
        $Namespace,
        [Parameter(Mandatory=$false, ParameterSetName="allns")]
        [switch]$all,
        $context
    )

    $cmds = "get", "deployment","-o=json"
    if($all){$cmds += "--all-namespaces"}
    elseif ($namespace){$cmds += "--namespace=$namespace"}
    if($context){$cmds += "--context=$context"}

    $svcs = kubeWrapper -kubeArgs $cmds | ConvertFrom-Json | newk8object -context $context
    $svcs | Where-Object { $_.name -like $Name}
}
#EndRegion '.\public\Get-k8Deployment.ps1' 21
#Region '.\public\Get-k8Ingress.ps1' 0
function Get-K8Ingress {
[cmdletBinding(DefaultParameterSetName="allns")]
[Alias("gki")]
param(
    $Name='*',
    [Parameter(ParameterSetName="namespace")]
    $Namespace,
    [Parameter(ParameterSetName="all")]
    [switch]$all,
    $Context
)
    $cmds = "get", "ingress","-o=json"
    
    if($all){$cmds += "--all-namespaces"}
    elseif($namespace){$cmds += "--namespace=$namespace"}

    if($context){$cmds += "--context=$context"}

    $ings = kubeWrapper -kubeArgs $cmds | ConvertFrom-Json | newk8object
    $ings | Where-Object { $_.name -like $Name}
}
#EndRegion '.\public\Get-k8Ingress.ps1' 22
#Region '.\public\Get-k8Log.ps1' 0
function Get-k8Log {
    [cmdletBinding()]
    [Alias("gkl")]
    param(
        $Name,
        $Container,
        [int]$Tail=30,
        [switch]$Follow,
        [switch]$Previous,
        $Namespace,
        $Context
    )
    $cmd = @("logs")
    if($Follow) {
        $cmd += "-f"
    }
    if($Previous) {
        $cmd += "-p"
    }
    
    $cmd += "$name"

    if($Container) {
        $cmd += "-c $Container"
    }

    if($PSBoundParameters.Tail){
        $cmd += "--tail=$tail"
    }

    if($Namespace){$cmd += "--namespace=$Namespace"}
    if($conxtext){$cmd += "--conxtext=$conxtext"}

    kubeWrapper -kubeArgs $cmd
}
#EndRegion '.\public\Get-k8Log.ps1' 36
#Region '.\public\Get-k8Namespace.ps1' 0
function Get-K8Namespace {
[Alias("gkns")]
param(
    $Name='*',
    #todo: cant use refresh and context together but has no impact
    [switch]$Refresh,
    $Context
    )
    
    $ns = if($context){
        $cmd = "get","ns","-o=json","--context=$context"
        kubeWrapper -kubeArgs $cmd
    }
    else{
        $cacheObject = getCachedData $Script:K8NSCACHE -Refresh:$Refresh
        $cacheObject.data
    } 
    $ns | ConvertFrom-Json | newk8object| where-object { $_.name -like $name }
}
#EndRegion '.\public\Get-k8Namespace.ps1' 20
#Region '.\public\Get-k8Node.ps1' 0
function Get-K8Node {
    [cmdletBinding()]
    [Alias("gkno")]
    param(
        $Name='*',
        $Context
    )
        $cmds = "get", "node","-o=json"
        if($context){$cmds += "--context=$context"}
        
        $nodes = kubeWrapper -kubeargs $cmds | ConvertFrom-Json | newk8object
        $nodes | Where-Object { $_.name -like $Name}
    }
#EndRegion '.\public\Get-k8Node.ps1' 14
#Region '.\public\Get-K8Pod.ps1' 0
function Get-K8Pod {
[cmdletBinding(DefaultParameterSetName="allns")]
[Alias("gkp")]
param(
        $Name='*',
        [Parameter(Mandatory=$false, ParameterSetName="namespace")]
        $Namespace,
        [Parameter(Mandatory=$false, ParameterSetName="allns")]
        [switch]$all,
        $Context
    )
    $cmds = "get", "pod","-o=json"
    if($all){$cmds += "--all-namespaces"}
    elseif($namespace){$cmds += "--namespace=$namespace"}
    if($context){$cmds += "--context=$context"}
    $pods = kubeWrapper -kubeArgs $cmds | ConvertFrom-Json | newk8object -context $Context
    $pods | Where-Object { $_.name -like $Name}
}
#EndRegion '.\public\Get-K8Pod.ps1' 19
#Region '.\public\Get-k8Resource.ps1' 0
function Get-K8Resource {
param(
        $Context
    )
    $cmds = "api-resources","-o=wide"
    if($context){$cmds += "--context=$context"}
    $resources = convertfromfixedsize (kubeWrapper -kubeArgs $cmds)

    $resources | foreach {
        $_.VERBS = $_.VERBS.trim('[]').split(' ')
        $_.SHORTNAMES = $_.SHORTNAMES.split(',')
    }
    $resources
}
#EndRegion '.\public\Get-k8Resource.ps1' 15
#Region '.\public\Get-k8Service.ps1' 0
function Get-K8Service {
[cmdletBinding(DefaultParameterSetName="allns")]
[Alias("gks")]
param(
    $Name='*',
    [Parameter(Mandatory=$false, ParameterSetName="namespace")]
    $Namespace,
    [Parameter(Mandatory=$false, ParameterSetName="allns")]
    [switch]$all,
    $Context
)
    
$cmds = "get", "service","-o=json"

if($all){$cmds += "--all-namespaces"}
elseif($namespace){$cmds += "--namespace=$namespace"}

if($context){$cmds += "--context=$context"}

$svcs = kubeWrapper -kubeargs $cmds -namespace $namespace | ConvertFrom-Json | newk8object
$svcs | Where-Object { $_.name -like $Name}
}
#EndRegion '.\public\Get-k8Service.ps1' 23
#Region '.\public\Invoke-k8ClusterCommand.ps1' 0
function Invoke-K8ClusterCommand {
  [cmdletBinding()]
  [Alias("ikcc")]
  param(
    [Parameter(ValueFromPipeline=$true)]  
    $Cluster=@('*'),
    [scriptblock]$script
  )
  begin{
    $currentContext = Get-k8Context -Current
  }
  process{
    foreach($c in $cluster){
      Set-k8Context $c
      & $script
    }
  }
  end{
    Set-k8Context $currentContext.name
  }  
  # if i put this in to a job/runspace it might have its own pid, which would then allow it to not screw with the current session
  #Clusters should be an array or filter? make both work? different params?
    
}
#EndRegion '.\public\Invoke-k8ClusterCommand.ps1' 25
#Region '.\public\kubewrapper.ps1' 0
function kubeWrapper {
    [cmdletBinding()]
    [Alias("k")]
    param(
        # Args to pass to kubectl
        [Parameter(ValueFromRemainingArguments)]
        $kubeArgs
    )


    $nsPat = '^--?n(amespace)?($|=)'
    $contextPat = '^--context'
    
    ## Namespace handler
    if($kubeArgs | where-object {$_ -cmatch $nsPat}){
        Write-Verbose "[kubeWrapper] Using Provided Namespace"
    }else{
        if($env:KUBECTL_NAMESPACE){
            Write-Verbose "[kubeWrapper] Using Env based Namespace" 
        }else{
            Write-Verbose "[kubeWrapper] Using Default Namespace"
            $env:KUBECTL_NAMESPACE = 'default'
        }
        $kubeArgs += "--namespace=$($env:KUBECTL_NAMESPACE)"
    }

    ## context handler
    if($kubeArgs | where-object {$_ -cnotmatch $contextPat}){
        if($script:context){
            Write-Verbose "[kubeWrapper] Using Provided Context"
            $kubeArgs += "--context=$($ENV:KUBECTL_CONTEXT)"
        }
        ## use select context from kubeconfig
        Write-Verbose "[kubeWrapper] Using kube config Context"
    }
    else{
        Write-Verbose "[kubeWrapper] Using stored Context"
    }

    Write-Verbose "[kubeWrapper] Arguments: $kubeArgs"
    Write-Verbose ($kubeArgs | ConvertTo-Json)
    kubectl $kubeArgs
}
#EndRegion '.\public\kubewrapper.ps1' 44
#Region '.\public\Set-k8ActiveNamespace.ps1' 0
function Set-k8ActiveNamespace {
    [Alias("skan")]
    param($Name=$script:K8DEFAULTNS)
    #todo: add validation of some kind i guess
    # use force to set to "anything" and by default validate its acceptable based on current ctx
    $env:KUBECTL_NAMESPACE = $Name
}
#EndRegion '.\public\Set-k8ActiveNamespace.ps1' 8
#Region '.\public\Set-k8Context.ps1' 0

function Set-k8Context {
    [CmdletBinding()]
    # Name or Context object to set as the active context.
    param($Name)
    
    #if its a context obj, get the name
    if($name.name){
        $name = $name.name
    }else{
        #todo its a string, validate that its valid
    }
    #env or script var?
    $env:KUBECTL_CONTEXT = $name
    #dont use kube config, use env and append to each cmd
    #kubeWrapper -kubeArgs @("config","use-context",$Name) | out-null
    write-verbose "[Set-k8Context] Set to $name"
    $script:K8CTXCACHE.lastUpdate = $null #force update on next get call
}
#EndRegion '.\public\Set-k8Context.ps1' 20
#Region '.\public\Switch-k8Context.ps1' 0
function Switch-k8Context {
    [cmdletBinding()]
    [Alias("ctx")]
    param($Name)
        if($Name)
        {
            set-k8context $Name
            #reset NS to default on context switch
            Set-k8ActiveNamespace 'default'
        }
        else {
            #todo perhaps make this, no params, toggle to the last used context since i assume the tab complete feature should make this worthless?
            get-k8Context | Select-Object -ExpandProperty name
        }
    }
#EndRegion '.\public\Switch-k8Context.ps1' 16
#Region '.\public\Update-k8Command.ps1' 0
function Update-k8command {
param(
        $Context
    )
    
    $resources = Get-K8Resource
    $functions = ""
    foreach($resource in $resources)
    {
        Write-Debug -Debug "Kind: $($resource.KIND)"
        foreach($verb in $resource.verbs)
        {
            switch ($verb)
            {
                "get" {
                    #build Get-k8<type> function
                    if($resource.namespaced -eq "true")
                    {
                        write-debug -debug "NAMESPACED Getter: $($resource.kind) Alias: $($resource.shortnames)"
                        
                        $alias =  if($resource.shortnames){$resource.shortnames | %{'[Alias("gk{0}")]' -f $_}}
                        $functions += $script:get_namespaced.replace('<<ALIAS>>',$alias).replace('<<KIND>>',$resource.KIND) +"`n"
                    }
                    else {
                        write-debug -debug "CLUSTER Getter: $($resource.kind) Alias: $($resource.shortnames)"
                        
                        $alias =  if($resource.shortnames){$resource.shortnames | %{'[Alias("gk{0}")]' -f $_}}
                        $functions += $script:get_cluster.replace('<<ALIAS>>',$alias).replace('<<KIND>>',$resource.KIND) +"`n"
                    }
                }
                "delete" {
                    #build Remove-k8<type> function
                }
                "create" {
                    #build New-k8<type> function
                }
                "patch" {
                    #build update-k8<type> function
                }
                "update" {
                    #build set-k8<type> function
                }
            }
        }
    }
    $functions
}
#EndRegion '.\public\Update-k8Command.ps1' 48
#Region '.\public\zLoader.ps1' 0
## since there is no fucntion, this file will just run upon module load, acting as a startup script.
# since files are loaded in alpha order, with Public being last, the file name starts with a Z to force it to load last

#initialize-k8Session

# Add in dynamic functions
update-k8Command | iex
#EndRegion '.\public\zLoader.ps1' 8
