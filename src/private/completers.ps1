[scriptblock]$ctxCompleter = {
    param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $allCtx = get-k8context | select -ExpandProperty name
    $allCtx | ? {$_ -like "*$wordToComplete*"}
}
[scriptblock]$podCompleter = {
    param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $allCtx = get-k8pod | select -ExpandProperty name
    $allCtx | ? {$_ -like "*$wordToComplete*"}
}

[scriptblock]$nsCompleter = {
    param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $allCtx = get-k8namespace | select -ExpandProperty name
    $allCtx | ? {$_ -like "*$wordToComplete*"}
}


Register-ArgumentCompleter -CommandName 'set-k8context','switch-k8Context' -ParameterName 'Name' -ScriptBlock $ctxCompleter
Register-ArgumentCompleter -CommandName 'Get-K8Pod','Get-K8PodLog','Enter-k8Pod' -ParameterName 'Name' -ScriptBlock $podCompleter
Register-ArgumentCompleter -CommandName 'get-k8namespace','Set-k8ActiveNamespace' -ParameterName 'Name' -ScriptBlock $nsCompleter


$both = @(
    'Enter-k8Pod',
    'Get-K8Deployment',
    'Get-K8Ingress',
    'Get-k8Log',
    'Get-K8Pod',
    'Get-K8Service'
)


Register-ArgumentCompleter -commandName $both -parameterName 'Namespace' -scriptblock $nsCompleter
$contextOnly =  $both + 'Get-K8Namespace'
Register-ArgumentCompleter -commandName $contextOnly -parameterName 'Context' -scriptblock $ctxCompleter