<#
# in public for now so that i can easily use the kubectl cmds diretly
function kubeWrapper {
    $ns = if($env:KUBECTL_NAMESPACE){$env:KUBECTL_NAMESPACE}else{'default'; $env:KUBECTL_NAMESPACE = 'default'}
    $args = @("--namespace=$ns") + $args | %{$_}
    Write-Verbose "Arguments: $args"
    kubectl $args
}
#>

