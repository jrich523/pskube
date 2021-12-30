$script:get_namespaced = @'
function Get-K8<<KIND>>
{
    [cmdletBinding(DefaultParameterSetName="allns")]
    <<ALIAS>>
    param(
            $Name='*',
            [Parameter(Mandatory=$false, ParameterSetName="namespace")]
            $Namespace,
            [Parameter(Mandatory=$false, ParameterSetName="allns")]
            [switch]$all,
            $Context
        )
        $cmds = "get", "<<KIND>>","-o=json"
        if($all){$cmds += "--all-namespaces"}
        elseif($namespace){$cmds += "--namespace=$namespace"}
        if($context){$cmds += "--context=$context"}
        kubeWrapper -kubeArgs $cmds | ConvertFrom-Json | newk8object | Where-Object { $_.name -like $Name}
}
'@

$script:get_cluster = @'
function Get-K8<<KIND>>
{
    <<ALIAS>>
    param(
            $Name='*',
            $Context
        )
        $cmds = "get", "<<KIND>>","-o=json"
        if($context){$cmds += "--context=$context"}
        kubeWrapper -kubeArgs $cmds | ConvertFrom-Json | newk8object | Where-Object { $_.name -like $Name}
}
'@