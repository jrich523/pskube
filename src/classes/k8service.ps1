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