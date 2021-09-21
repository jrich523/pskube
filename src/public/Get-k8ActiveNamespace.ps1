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