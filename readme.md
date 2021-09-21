# PSKube - Powershell Kuberenetes Module

This is the initial release of a module i've used personally for a while for easier inspection of Kubernetes objects. Its somewhat customized for how I work (EKS/Nodegroup data as well was app/version labels exposed)

The module works off of kubectl rather than the API (bit of a pain to work with the API without a library


## Notes

Status Types - Should they be true/false? enum? string? bool?
    node - bool
    pod - string

## API Docs

Metadata - https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.17/#objectmeta-v1-meta