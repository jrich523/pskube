#requires -Module ModuleBuilder
[CmdletBinding()]
param(
    # A specific folder to build into
    $OutputDirectory,

    # The version of the output module
    [Alias("ModuleVersion")]
    [string]$SemVer=$env:TAG #this will pull the tag from github actions
)

# Sanitize parameters to pass to Build-Module
$null = $PSBoundParameters.Remove('Test')
if (-not $Semver) { 
    $SemVer = "1.0"
    $null = $PSBoundParameters.Add("SemVer", $SemVer)
}
else {
    $PSBoundParameters.Item("SemVer") = $semver
}

write-host "Creating Version: " $SemVer

$ErrorActionPreference = "Stop"
Push-Location $PSScriptRoot -StackName BuildPSProfileManager
try {

    # Build new output
    $ParameterString = $PSBoundParameters.GetEnumerator().ForEach{ '-' + $_.Key + " '" + $_.Value + "'" } -join " "
    Write-Verbose "Build-Module src\build.psd1 $($ParameterString) -Target CleanBuild"
    Build-Module src\build.psd1 @PSBoundParameters -Target CleanBuild -Passthru -OutVariable BuildOutput | Split-Path
    Write-Verbose "Module build output in $(Split-Path $BuildOutput.Path)"
    Write-Verbose "Updating Manifest for dynamic functions"
    # for now export everything, but eventually change to '*-*'
    Update-ModuleManifest -Path "./$semver/pskube.psd1" -FunctionsToExport '*' -AliasesToExport '*' -CmdletsToExport '*'

} finally {
    Pop-Location -StackName BuildPSProfileManager
}