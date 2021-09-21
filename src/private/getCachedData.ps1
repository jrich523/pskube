function GetCachedData {
[cmdletBinding()]
param(
    $CacheObject,
    [switch]$Refresh
)
    $lastUpdate = $CacheObject.lastUpdate
    $needsUpdate = if($lastUpdate){
        (New-TimeSpan -Start $lastUpdate -End (get-date)) -gt $CacheObject.timeout
    }else{$true}

    # forcing an update if you request current. Feels like that could be problematic otherwise
    if($needsUpdate -OR $Refresh)
    {
        Write-Verbose "[GetCachedData] Updading object Cache"
        $CacheObject.data = kubeWrapper -kubeArgs ($CacheObject.command)
        $CacheObject.lastUpdate = Get-Date
        $CacheObject.updated = $true
    }
    else
    {
        Write-Verbose "[GetCachedData] Using Cache"
        $CacheObject.updated = $false   
    }
    $CacheObject
}