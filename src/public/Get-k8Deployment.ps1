function Get-K8Deployment {
    [cmdletBinding(DefaultParameterSetName="allns")]
    [Alias("gkd")]
    param(
        $Name='*',
        [Parameter(Mandatory=$false, ParameterSetName="namespace")]
        $Namespace,
        [Parameter(Mandatory=$false, ParameterSetName="allns")]
        [switch]$all,
        $context
    )

    $cmds = "get", "deployment","-o=json"
    if($all){$cmds += "--all-namespaces"}
    elseif ($namespace){$cmds += "--namespace=$namespace"}
    if($context){$cmds += "--context=$context"}

    $svcs = kubeWrapper -kubeArgs $cmds | ConvertFrom-Json | newk8object
    $svcs | Where-Object { $_.name -like $Name}
}