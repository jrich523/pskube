function Get-K8Service {
[cmdletBinding(DefaultParameterSetName="allns")]
[Alias("gks")]
param(
    $Name='*',
    [Parameter(Mandatory=$false, ParameterSetName="namespace")]
    $Namespace,
    [Parameter(Mandatory=$false, ParameterSetName="allns")]
    [switch]$all,
    $Context
)
    
$cmds = "get", "service","-o=json"

if($all){$cmds += "--all-namespaces"}
elseif($namespace){$cmds += "--namespace=$namespace"}

if($context){$cmds += "--context=$context"}

$svcs = kubeWrapper -kubeargs $cmds -namespace $namespace | ConvertFrom-Json | newk8object
$svcs | Where-Object { $_.name -like $Name}
}