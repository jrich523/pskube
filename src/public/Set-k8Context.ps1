
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