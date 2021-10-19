function Get-K8Node {
    [cmdletBinding()]
    [Alias("gkno")]
    param(
        $Name='*',
        $Context
    )
        $cmds = "get", "node","-o=json"
        if($context){$cmds += "--context=$context"}
        
        $nodes = kubeWrapper -kubeargs $cmds | ConvertFrom-Json | newk8object
        $nodes | Where-Object { $_.name -like $Name}
    }