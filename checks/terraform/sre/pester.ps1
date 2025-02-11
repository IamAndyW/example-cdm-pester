param (
    [Parameter(Mandatory = $true)]
    [hashtable] $parentConfiguration
)

BeforeDiscovery {
    # installing dependencies
    # to avoid a potential clash with the YamlDotNet libary always load the module 'powershell-yaml' last
    Install-PowerShellModules -moduleNames ("powershell-yaml")

    $configurationFilename = $parentConfiguration.configurationFilename

    # loading check configuration
    if (-not (Test-Path -Path $configurationFilename)) {
        throw ("Missing configuration file: {0}" -f $configurationFilename)
    }

    $checkConfiguration = Get-Content -Path $configurationFilename | ConvertFrom-Yaml

    # building the discovery objects
    $discovery = $checkConfiguration
} 

Describe $parentConfiguration.jobDisplayName -ForEach $discovery {

    Context "Required Version: <_>" -ForEach $_.requiredVersionConstraints {
        BeforeAll {
            $testFilePath = "./version.tf"
        }

        BeforeEach {
            @"
            terraform {
                # https://developer.hashicorp.com/terraform/language/expressions/version-constraints
                required_version = "$_"
            }
"@ | Set-Content -Path $testFilePath -Force
        }

        It "'terraform init' should return an Exit Code of 0" {            
            terraform init
            $LASTEXITCODE | Should -Be 0 
        }

        AfterEach {
            Remove-Item -Path $testFilePath -Force
        }

        AfterAll {
            Clear-Variable -Name testFilePath
        }
    }

    AfterAll {
        Write-Information -MessageData ("`nInstalled Terraform version: {0}" -f $(terraform --version))
        Write-Information -MessageData ("`nRunbook: {0}`n" -f $_.runbook)
    }
}
