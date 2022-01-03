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
}