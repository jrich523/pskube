function Update-k8command {
param(
        $Context
    )
    
    $resources = Get-K8Resource
    $functions = ""
    foreach($resource in $resources)
    {
        Write-Debug -Debug "Kind: $($resource.KIND)"
        foreach($verb in $resource.verbs)
        {
            switch ($verb)
            {
                "get" {
                    #build Get-k8<type> function
                    if($resource.namespaced -eq "true")
                    {
                        write-debug -debug "NAMESPACED Getter: $($resource.kind) Alias: $($resource.shortnames)"
                        
                        $alias =  if($resource.shortnames){$resource.shortnames | %{'[Alias("gk{0}")]' -f $_}}
                        $functions += $script:get_namespaced.replace('<<ALIAS>>',$alias).replace('<<KIND>>',$resource.KIND) +"`n"
                    }
                    else {
                        write-debug -debug "CLUSTER Getter: $($resource.kind) Alias: $($resource.shortnames)"
                        
                        $alias =  if($resource.shortnames){$resource.shortnames | %{'[Alias("gk{0}")]' -f $_}}
                        $functions += $script:get_cluster.replace('<<ALIAS>>',$alias).replace('<<KIND>>',$resource.KIND) +"`n"
                    }
                }
                "delete" {
                    #build Remove-k8<type> function
                }
                "create" {
                    #build New-k8<type> function
                }
                "patch" {
                    #build update-k8<type> function
                }
                "update" {
                    #build set-k8<type> function
                }
            }
        }
    }
    $functions
}