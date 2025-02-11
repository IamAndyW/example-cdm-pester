
<#
    This is the entrypoint into the CDM check ADO integration which performs validation and sets common configuration.

    This script will invoke a custom PowerShell script for the ADO organisation, project and action
    Example: cdm_library/integrations/ado/ensonodigitaluk/sre/CreateWorkitem.ps1
#>

$InformationPreference = "Continue"
$ErrorActionPreference = "Stop"


$script:adoDirectory = ("{0}/{1}/{2}/{3}" -f $env:CDM_INTEGRATION_DIRECTORY, "ado", $env:ADO_ORGANISATION_NAME, $env:ADO_PROJECT_NAME)

if (Test-Path -Path ("{0}/{1}.ps1" -f $adoDirectory, $env:ADO_ACTION)) {
    $script:adoActionFilename = ("{0}/{1}.ps1" -f $adoDirectory, $env:ADO_ACTION)
} else {
    $script:adoActionFilename = ("{0}/{1}/{2}.ps1" -f $env:CDM_LIBRARY_DIRECTORY, $adoDirectory, $env:ADO_ACTION)
}

$script:configurationFilename = ("{0}/{1}" -f $adoDirectory , "configuration.yml")


if (Test-Path -Path $adoActionFilename) {
    Write-Information -MessageData ("Running ADO action from '{0}'" -f $adoActionFilename)
} else {
    throw ("ADO action filename '{0}' cannot be found" -f $adoActionFilename)
}

if (Test-Path -Path $configurationFilename) {
    Write-Information -MessageData ("Loading configuration from '{0}'`n" -f $configurationFilename)
} else {
    throw ("Configuration filename '{0}' cannot be found" -f $configurationFilename)
}

$parentConfiguration = @{
    checkName = $env:CHECK_NAME
    configurationFilename = $configurationFilename
    collectionUrl = ("{0}/{1}/" -f "https://dev.azure.com", $env:ADO_ORGANISATION_NAME)
    baseUrl = ("{0}/{1}/{2}" -f "https://dev.azure.com", $env:ADO_ORGANISATION_NAME, $env:ADO_PROJECT_NAME)
    clientName = $env:CLIENT_NAME
    accessToken = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($env:ADO_ACCESS_TOKEN)"))
    action = $env:ADO_ACTION
    stageDisplayName = $env:STAGE_DISPLAY_NAME
    stageId = $env:STAGE_ID
    jobDisplayName = $env:JOB_DISPLAY_NAME
    jobId = $env:JOB_ID
    buildProjectName = $env:ADO_BUILD_PROJECT_NAME
    buildId = $env:ADO_BUILD_ID
    buildNumber = $env:ADO_BUILD_NUMBER
}

& $adoActionFilename
