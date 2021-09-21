#todo this should be handled by the config manager

# CONFIGURATION OPTIONS


$script:K8CTXCACHE = @{
    lastUpdate=$null;
    data=$null;
    updated=$false
    timeout= new-timespan -Seconds 2;
    command="config", "get-contexts";
}

$script:K8NSCACHE = @{
    lastUpdate=$null;
    data=$null;
    updated=$false;
    timeout=new-timespan -Seconds 2; ## short timeout because in many cases this is called twice in short order
    command="get","ns","-o=json"
}

$script:K8DEFAULTNS = 'default' #in case for some reason you dont use default as the default
