function Get-K8Pod {
[cmdletBinding(DefaultParameterSetName="allns")]
[Alias("gkp")]
param(
        $Name='*',
        [Parameter(Mandatory=$false, ParameterSetName="namespace")]
        $Namespace,
        [Parameter(Mandatory=$false, ParameterSetName="allns")]
        [switch]$all,
        $Context
    )
    $cmds = "get", "pod","-o=json"
    if($all){$cmds += "--all-namespaces"}
    elseif($namespace){$cmds += "--namespace=$namespace"}
    if($context){$cmds += "--context=$context"}
    $pods = kubeWrapper -kubeArgs $cmds | ConvertFrom-Json | newk8object
    $pods | Where-Object { $_.name -like $Name}
}