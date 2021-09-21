class k8Condition {
    [datetime]$LastHeartbeatTimestamp
    [datetime]$LastTransitionTimestamp
    [string]$Message
    [string]$Reason
    [bool]$Status
    [string]$Type #todo: enum
}

class k8Resources {
    
}
#https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.17/#serviceport-v1-core
class k8ServicePort {
    
    [string]$Name
    [int]$NodePort
    [int]$Port
    [string]$Protocol #todo: convert to enum: tcp/udp/sctp default: tcp
    <#
    Number or name of the port to access on the pods targeted by the service.
    Number must be in the range 1 to 65535. Name must be an IANA_SVC_NAME.
    If this is a string, it will be looked up as a named port in the target Pod's container ports.
    If this is not specified, the value of the 'port' field is used (an identity map).
    This field is ignored for services with clusterIP=None, and should be omitted or set equal to the 'port' field.
    More info: https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service
    #>
    $targetPort #todo: type depends on returned data, int/string

    k8ServicePort($servicePort){
        $this.name = $servicePort.name
        $this.NodePort = $servicePort.NodePort
        $this.Port = $servicePort.Port
        $this.Protocol = $servicePort.Protocol
    }
    [string] ToString(){
        return "$($this.port)/$($this.protocol)"
    }

}