class Age : System.IComparable {
    [datetime]$CreationTime
    static hidden [regex] $regex = [regex]'^(\d+\w)+$'

    age([datetime]$CreationTime){
        $this.CreationTime = $CreationTime
        $this.SharedConstructor()
    }

    age([String]$CreationTime){
        if($CreationTime -as [datetime]){
            $this.CreationTime = [datetime]$CreationTime
        }
        elseif ($CreationTime -match [age]::regex)
        {
            $this.CreationTime = [age]::ConvertFromString($CreationTime).CreationTime
        }
        else{
            # This probably needs to throw an actual error
            write-error "Invalid value"
        }
        $this.SharedConstructor()
    }

    age(){
        $this.CreationTime = Get-Date
        $this.SharedConstructor()
    }
    
    hidden SharedConstructor(){
        $this.psobject.properties.add(
            (new-object PSScriptProperty 'Age', {$this.ToString()})
        )
    }

    static [Age] ConvertFromString([string]$age)
    {
        if($age -as [datetime])
        {
            return [Age]::New([datetime]$age)
        }
        elseif(($m=[age]::regex.Match($age)).success){
            $ts = New-Object timespan
            $units=$m.groups[1].captures.value
            foreach ($u in $units) {
                $digit = $u.trimEnd('d','h','m','s') # dont cast to int incase an unsupported unit is provided.
                switch ($u[-1]) {
                    "d" {$ts += New-TimeSpan -Days $digit }
                    "h" {$ts += New-TimeSpan -Hours $digit}
                    "m" {$ts += New-TimeSpan -Minutes $digit}
                    "s" {$ts += New-TimeSpan -Seconds $digit}
                    Default { write-error "Invalid unit type!" }
                }
            }
            $dt = (get-date).AddSeconds($ts.TotalSeconds *-1 )
            return [age]::new($dt)
        }
        else {
            write-error "Invalid String format!"
            return $null
        }
    }

    [timespan]GetTimeSpan(){
        return New-TimeSpan -Start $this.CreationTime -End (get-date)
    }

    [string] ToString(){
        $rtn = "Err!"
        $ts = $this.GetTimeSpan()
        
        if($ts.Days)
        {
            $rtn = "$($ts.Days)d"
            if($ts.days -lt 5 -and $ts.Hours -gt 3)
            {
                $rtn += "$($ts.Hours)h"
            }
        }
        elseif ($ts.Hours) {
            $rtn = "$($ts.Hours)h"
            if($ts.Hours -lt 3 -and $ts.Minutes -gt 15)
            {
                $rtn += "$($ts.Minutes)m"
            }
        }
        elseif ($ts.Minutes) {
            $rtn = "$($ts.minutes)m"
            if($ts.Minutes -lt 5 -and $ts.seconds -gt 15)
            {
                $rtn += "$($ts.seconds)s"
            }
        }
        else {
            $rtn = "$($ts.Seconds)s"
        }
        return $rtn
    }

    [int] CompareTo([object] $obj) {
        # If is a string in the 1m14s type notation
        if($obj -is [string] -and $obj -match [age]::regex){
            $obj = [Age]::ConvertFromString($obj)
        }
        # If its an age object provided, or convert from above If
        if($obj -is [age]){
            # convert to datetime for next If
            $obj = $obj.CreationTime
        }
        if($obj -as [datetime]) { # the -as allows handling of datetime in string format
            if ($this.CreationTime -gt $obj) {return -1}
            if ($this.CreationTime -eq $obj) {return 0}
            if ($this.CreationTime -lt $obj) {return 1}
            return $null
        }
        if ($obj -is [timespan]) {
            if ($this.GetTimeSpan() -gt $obj) {return -1}
            if ($this.GetTimeSpan() -eq $obj) {return 0}
            if ($this.GetTimeSpan() -lt $obj) {return 1}
            return $null
        }
        return $null
    }
}