function ConvertFromFixedSize
{
    [cmdletbinding()]
    param(
    [Parameter(Mandatory=$true,
               ValueFromPipeline=$true)]
    $data
    )

    function wordIndex{
        param($header)

        $indexes = @()
        $isWord = $false
        $chars = $header.ToCharArray()
        for($i =0; $i -lt $chars.Length; $i++ ){
            $c = $chars[$i]
            if($c -match "\s" -and $isWord){
                $isWord=$false
            }
            elseif ($c -notmatch "\s" -and -not $isWord) {
                $isWord=$true
                $indexes+=$i
            }
        }
        return $indexes
    }
    function chopData{
        param($str,$indexes)
            $current = $indexes[0]
            $indexes | select -skip 1 | %{
                $str.substring($current,($_ - $current)).trim();
                $current = $_
            
            }
            $str.substring($current).trim()
    }
    #if($data -isnot [array]){$data = $data -split "`n"}
    #$data = $data |%{$_.trimend()} | ? {$_} 

    #assume header
    $indexes = wordIndex $data[0]
    Write-Verbose -Verbose "Indexes $($indexes -join ' ')"

    #under the assumption that the first row is header, use those for property names
    $header = chopData $data[0] $indexes
    Write-Verbose -Verbose "headers: $header"

    #chop up data and spit out objects
    $data | Select -skip 1 | %{ chopData $_ $indexes | %{$i=0;$h=@{}}{ $h.($header[$i]) = $_;$i++}{[pscustomobject]$h}}
}

