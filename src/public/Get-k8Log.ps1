function Get-k8Log {
    [cmdletBinding()]
    [Alias("gkl")]
    param(
        $Name,
        $Container,
        [int]$Tail=30,
        [switch]$Follow,
        [switch]$Previous,
        $Namespace,
        $Context
    )
    $cmd = @("logs")
    if($Follow) {
        $cmd += "-f"
    }
    if($Previous) {
        $cmd += "-p"
    }
    
    $cmd += "$name"

    if($Container) {
        $cmd += "-c $Container"
    }

    if($PSBoundParameters.Tail){
        $cmd += "--tail=$tail"
    }

    if($Namespace){$cmd += "--namespace=$Namespace"}
    if($conxtext){$cmd += "--conxtext=$conxtext"}

    kubeWrapper -kubeArgs $cmd
}
