
function newK8Object {
    [cmdletBinding()]
    param (
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true)]
        $inputObject,
        $Context
    )  
    begin{
        if(!$Context)
        {
            $Context=Get-k8Context -Current | select-object -ExpandProperty name
        }
    }
    process {
        if($inputObject.kind) #k8 object
        {
            $class = "k8$($inputObject.kind)"
            write-debug "[newK8Object] K8 Object detected"
            if($inputObject.kind -eq "List")
            {
                write-debug "[newK8Object] Detected list, processing sub items"
                $inputObject.items | newK8Object
            }
            elseif ( $class -as [type]) {
                write-debug "[newK8Object] Creating object from kind $($inputobject.kind)"
                new-object -TypeName $class -ArgumentList $inputObject, $Context
            }
            else {
                if($inputObject.metadata.namespace)
                {
                    write-debug "[newK8Object] Creating object from kind $($inputobject.kind) as K8namespaced object"
                    $objs = new-object -TypeName "k8namespaced" -ArgumentList $inputObject, $context
                }
                else
                {
                    write-debug "[newK8Object] Creating object from kind $($inputobject.kind) as K8 object"
                    $objs = new-object -TypeName "k8" -ArgumentList $inputObject, $context
                }
                $objs | ForEach-Object { $_.PSObject.TypeNames.Insert(0,$class)}
                $objs
            }
        }
        else {
            Write-Error "unable to process object! No 'Kind' Found!"
        }
    }
    end {}
    }