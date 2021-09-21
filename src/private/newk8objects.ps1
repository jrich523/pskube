
function newK8Object {
    [cmdletBinding()]
    param (
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true)]
        $inputObject
    )  
    begin{}
    process {
        if($inputObject.kind) #k8 object
        {
            write-debug "[newK8Object] K8 Object detected"
            if($inputObject.kind -eq "List")
            {
                write-debug "[newK8Object] Detected list, processing sub items"
                $inputObject.items | newK8Object
            }
            else
            {
                write-debug "[newK8Object] Creating object from kind $($inputobject.kind)"
                new-object -TypeName "k8$($inputobject.kind)" -ArgumentList $inputObject
            }
        }
        else {
            Write-Error "unable to process object! No 'Kind' Found!"
        }
    }
    end {}
    }