class k8Namespace : k8 {
#Region Properties
    #### Spec ####
    # Finalizers?

    #### Status ####
    [string]$Status #todo create a type/enum for this?
    [string]$ResourceVersion

#EndRegion
    
    k8Namespace([Object]$rawData) : base($rawData)
    {
#Region Set Properties
        
        $this.ResourceVersion = $this._Raw.metadata.ResourceVersion
        $this.status = $this._Raw.status.phase

#EndRegion
        # Default Display Set
        $defaultdisplay = @('Name','Ready','Status','Restarts','Age')
        ([k8]$this).addDefaultDisplaySet($defaultdisplay)
    }

    [string] getAgeDisplay() {
        return ([k8]$this).getAge($this.creationTime)
    }
}