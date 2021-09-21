function Switch-k8Context {
    [cmdletBinding()]
    [Alias("ctx")]
    param($Name)
        if($Name)
        {
            set-k8context $Name
            #reset NS to default on context switch
            Set-k8ActiveNamespace 'default'
        }
        else {
            #todo perhaps make this, no params, toggle to the last used context since i assume the tab complete feature should make this worthless?
            get-k8Context | Select-Object -ExpandProperty name
        }
    }