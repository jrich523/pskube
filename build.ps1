#requires -Module ModuleBuilder, Configuration
[CmdletBinding()]
param(
    # A specific folder to build into
    $OutputDirectory,

    # The version of the output module
    [Alias("ModuleVersion")]
    [string]$SemVer
)

# Sanitize parameters to pass to Build-Module
$null = $PSBoundParameters.Remove('Test')

if (-not $Semver) {
    #todo probably do something about this
    if ($semver = "1.0") {
        $null = $PSBoundParameters.Add("SemVer", $SemVer)
    }
}


$ErrorActionPreference = "Stop"
Push-Location $PSScriptRoot -StackName BuildPSProfileManager
try {

    # Build new output
    $ParameterString = $PSBoundParameters.GetEnumerator().ForEach{ '-' + $_.Key + " '" + $_.Value + "'" } -join " "
    Write-Verbose "Build-Module src\build.psd1 $($ParameterString) -Target CleanBuild"
    Build-Module src\build.psd1 @PSBoundParameters -Target CleanBuild -Passthru -OutVariable BuildOutput | Split-Path
    Write-Verbose "Module build output in $(Split-Path $BuildOutput.Path)"

} finally {
    Pop-Location -StackName BuildPSProfileManager
}