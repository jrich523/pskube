function Set-k8ActiveNamespace {
    [Alias("skan")]
    param($Name=$script:K8DEFAULTNS)
    #todo: add validation of some kind i guess
    # use force to set to "anything" and by default validate its acceptable based on current ctx
    $env:KUBECTL_NAMESPACE = $Name
}
