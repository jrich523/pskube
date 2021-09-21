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
    
        k8Deployment([Object]$rawData) : base($rawData)
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