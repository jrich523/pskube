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
