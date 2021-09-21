function Get-K8Ingress {
[cmdletBinding(DefaultParameterSetName="allns")]
[Alias("gki")]
param(
    $Name='*',
    [Parameter(ParameterSetName="namespace")]
    $Namespace,
    [Parameter(ParameterSetName="all")]
    [switch]$all,
    $Context
)
    $cmds = "get", "ingress","-o=json"
    
    if($all){$cmds += "--all-namespaces"}
    elseif($namespace){$cmds += "--namespace=$namespace"}

    if($context){$cmds += "--context=$context"}

    $ings = kubeWrapper -kubeArgs $cmds | ConvertFrom-Json | newk8object
    $ings | Where-Object { $_.name -like $Name}
}