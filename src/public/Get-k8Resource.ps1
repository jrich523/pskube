function Get-K8Resource {
param(
        $Context
    )
    $cmds = "api-resources","-o=wide"
    if($context){$cmds += "--context=$context"}
    $resources = convertfromfixedsize (kubeWrapper -kubeArgs $cmds)

    $resources | foreach {
        $_.VERBS = $_.VERBS.trim('[]').split(' ')
        $_.SHORTNAMES = $_.SHORTNAMES.split(',')
    }
    $resources
}