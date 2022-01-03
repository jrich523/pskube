# PSKube - Powershell Kuberenetes Module

This is the initial release of a module i've used personally for a while for easier inspection of Kubernetes objects. Its somewhat customized for how I work (EKS/Nodegroup data as well was app/version labels exposed)

The module works off of kubectl rather than the API (bit of a pain to work with the API without a library)

## Notes

All objects have a `_Raw` property that has the raw JSON returned from `kubectl get <type> -o json`

## Using this module

## Customization
Check out the Examples folder

## API Docs

Metadata - https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.17/#objectmeta-v1-meta


## Testing and Development
A quick way to reload and test this module, but you'll need to update the paths based on where you've cloned it.
```
function load {
    $path='D:\repos\gh\jrich523\pskube'
    iex $path\build.ps1
    remove-module pskube
    ipmo $path -verbose -force -debug
}
```
To have access to the classes directly you need to import them with
`using module path/to/pskube`

### Notes
Status Types - Should they be true/false? enum? string? bool?
    node - bool
    pod - string

### Todo
- Create more class/formats
- Adjust to properties better for dynamic objects

