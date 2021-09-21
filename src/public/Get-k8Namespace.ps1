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