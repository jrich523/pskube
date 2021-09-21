function Enter-k8Pod {
[cmdletBinding()]    
[Alias("ekp")]
param(
    $Name,
    $container,
    [switch]$sh,
    $Namespace,
    $Context
)
    $cmd = if($sh){ 'sh'} else { 'bash'}
    $containerArg = if($container){ "-c $container"}
    $cmdArgs = ("exec","-it",$Name,$containerArg,"--",$cmd)
    if($namespace){$cmdArgs += "--namespace=$namespace"}
    if($context){$cmdArgs += "--conext=$conext"}

    kubeWrapper -kubeArgs $cmdArgs
}