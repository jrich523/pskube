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

    [string] getAgeDisplay() {
        return ([k8]$this).getAge($this.creationTime)
    }
}