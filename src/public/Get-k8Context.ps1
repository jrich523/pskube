# This is mostly because the prompt shows the context and there is a slight delay to query that
# this also applies to the auto complete, it appears it does the query each tab, rather than cycle from the first query
function Get-k8Context {
[cmdletBinding()]
param(
    $Name,
    [switch]$Current,
    [switch]$Refresh
)
    $cacheObject = $script:K8CTXCACHE

    $cacheObject = getCachedData $cacheObject -refresh:$Refresh
    if($cacheObject.updated)
    {
        $cacheObject.data = $cacheObject.data | % { $_ -replace "\s{2,}","," } | ConvertFrom-Csv
        $cacheObject.data | % {$_.pstypenames.insert(0,'k8s.context')}
        $cacheObject.updated = $false
    }
    $contexts = $cacheObject.data
    if($current)
    {
        if($env:KUBECTL_CONTEXT)
        {
            Write-Verbose "[Get-k8Context] Filtering for current context by Env Context"
            $context | where-object {$_.name -eq $env:KUBECTL_CONTEXT}
        }
        else {
            Write-Verbose "[Get-k8Context] Filtering for current context"
            $contexts | Where-Object {$_.current} 
        }
    }
    elseif ($name) {
        Write-Verbose "[Get-k8Context] Filtering name by $name"
        $contexts | Where-Object {$_.name -like $Name}
    }
    else
    {
        write-verbose "[Get-k8Context] Returning all"
        $contexts
    }
}