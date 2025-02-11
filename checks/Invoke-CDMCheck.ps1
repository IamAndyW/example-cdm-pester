<#
    This is the entrypoint into a CDM check which performs common validation and sets common configuration.

    This script will invoke a custom PowerShell script for the check
    Example: checks/terraform/check.ps1
#>

$InformationPreference = "Continue"
$ErrorActionPreference = "Stop"

# dot-sourcing functions
$functions = (
   "Retry-Command.ps1",
   "Install-PowerShellModules.ps1" 
)

foreach ($function in $functions) {
    . ("{0}/powershell/functions/{1}" -f $env:CDM_LIBRARY_DIRECTORY, $function)
}

# time format and zones
$script:targetTimeZone = Get-TimeZone -ListAvailable | Where-Object {$_.id -eq $env:CDM_DATE_TIMEZONE}
$script:dateTime = [System.TimeZoneInfo]::ConvertTime($([datetime]::ParseExact($(Get-Date -Format $env:CDM_DATE_FORMAT), $env:CDM_DATE_FORMAT, $null).ToUniversalTime()), $targetTimeZone)
$script:skipUntilDateTime = [datetime]::ParseExact($env:SKIP_UNTIL, $env:CDM_DATE_FORMAT, $null)

Write-Information -MessageData ("Date: {0} {1}`n" -f $dateTime.ToString($env:CDM_DATE_FORMAT), $targetTimeZone.DisplayName)

# defining runtime paths
$script:checkDirectory = ("{0}/{1}" -f $env:CDM_CHECKS_DIRECTORY, $env:CHECK_NAME)

# check file
$script:checkFilename = ("{0}/{1}" -f $checkDirectory, "check.ps1")

# pester filename
$script:pesterFilename = ("{0}/{1}" -f $checkDirectory, "pester.ps1")

if ([string]::IsNullOrEmpty($env:PESTER_VARIANT_NAME)) {
    $script:pesterFilename = ("{0}/{1}" -f $checkDirectory , "pester.ps1")
} else {
    $script:pesterFilename = ("{0}/{1}/{2}/{3}" -f $env:CDM_LIBRARY_DIRECTORY, $checkDirectory, $env:PESTER_VARIANT_NAME, "pester.ps1")
}

# configuration file
if ([string]::IsNullOrEmpty($env:CHECK_VARIANT_NAME)) {
    $script:configurationFilename = ("{0}/{1}" -f $checkDirectory , "configuration.yml")
} else {
    $script:configurationFilename = ("{0}/{1}/{2}" -f $checkDirectory, $env:CHECK_VARIANT_NAME, "configuration.yml")
}

if (Test-Path -Path $checkFilename) {
    Write-Information -MessageData ("Running check from '{0}'" -f $checkFilename)
} else {
    throw ("Check filename '{0}' cannot be found" -f $checkFilename)
}

if (Test-Path -Path $pesterFilename) {
    Write-Information -MessageData ("Running Pester from '{0}'" -f $pesterFilename)
} else {
    throw ("Pester filename '{0}' cannot be found" -f $pesterFilename)
}

if (Test-Path -Path $configurationFilename) {
    Write-Information -MessageData ("Loading configuration from '{0}'`n" -f $configurationFilename)
} else {
    throw ("Configuration filename '{0}' cannot be found" -f $configurationFilename)
}

if ($skipUntilDateTime -gt $dateTime) {
    Write-Warning ("Skipping CDM check '{0}' until '{1}'`n" -f $env:CHECK_DISPLAY_NAME, $skipUntilDateTime.ToString($env:CDM_DATE_FORMAT))
    Write-Host "##vso[task.complete result=SucceededWithIssues]Skipping CDM check"
} else {
    $parentConfiguration = @{
        pesterFilename = $pesterFilename   
        configurationFilename = $configurationFilename
        resultsFilename = ("{0}_{1}_results.xml" -f "cdm", "check")
        jobDisplayName = $env:JOB_DISPLAY_NAME
        dateFormat = $env:CDM_DATE_FORMAT
        dateTime = $dateTime
        stageName = $env:STAGE_NAME
    }

    & $checkFilename
}
