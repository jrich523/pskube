function kubeWrapper {
    [cmdletBinding()]
    [Alias("k")]
    param(
        # Args to pass to kubectl
        [Parameter(ValueFromRemainingArguments)]
        $kubeArgs
    )


    $nsPat = '^--?n(amespace)?($|=)'
    $contextPat = '^--context'
    
    ## Namespace handler
    if($kubeArgs | where-object {$_ -cmatch $nsPat}){
        Write-Verbose "[kubeWrapper] Using Provided Namespace"
    }else{
        if($env:KUBECTL_NAMESPACE){
            Write-Verbose "[kubeWrapper] Using Env based Namespace" 
        }else{
            Write-Verbose "[kubeWrapper] Using Default Namespace"
            $env:KUBECTL_NAMESPACE = 'default'
        }
        $kubeArgs += "--namespace=$($env:KUBECTL_NAMESPACE)"
    }

    ## context handler
    if($kubeArgs | where-object {$_ -cnotmatch $contextPat}){
        if($script:context){
            Write-Verbose "[kubeWrapper] Using Provided Context"
            $kubeArgs += "--context=$($ENV:KUBECTL_CONTEXT)"
        }
        ## use select context from kubeconfig
        Write-Verbose "[kubeWrapper] Using kube config Context"
    }
    else{
        Write-Verbose "[kubeWrapper] Using stored Context"
    }

    Write-Verbose "[kubeWrapper] Arguments: $kubeArgs"
    Write-Verbose ($kubeArgs | ConvertTo-Json)
    kubectl $kubeArgs
}