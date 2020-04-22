Param(
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,

    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectName
)

$ModuleName = $ProjectName
$ModuleManifest = Join-Path -Path $Path -ChildPath "$ModuleName\$ModuleName.psd1"
Import-Module $ModuleManifest

Describe "Powershell validation" {
    $Scripts = Get-ChildItem $Path -Include *.ps1, *.psm1, *.psd1 -Recurse
    ForEach ($Script in $Scripts) {
        Context "$($Script.Name)" {
            It "Script should be valid powershell"  {
                $Script.FullName | Should Exist
                $Contents = Get-Content -Path $Script.FullName -ErrorAction Stop
                $Errors = $Null
                $Null = [System.Management.Automation.PSParser]::Tokenize($Contents, [ref]$Errors)
                $Errors.Count | Should Be 0
            }
        }
    }
}

Add-Type -AssemblyName System.Drawing
Describe 'PSSA Standard Rules' {
	$Scripts = Get-ChildItem $Path -Include *.ps1, *.psm1, *.psd1 -Recurse
	ForEach ($Script in $Scripts) {
		Context "$($Script.Name)" {
            $PSSAProps = @{
                'Path' = $($Script.FullName)
            }
            If(Test-Path -Path "$PSScriptRoot\PSScriptAnalyzerSettings.psd1") {
                $PSSAProps.Add('Settings',"$PSScriptRoot\PSScriptAnalyzerSettings.psd1")
            }
			$Analysis = Invoke-ScriptAnalyzer @PSSAProps
			$ScriptAnalyzerRules = Get-ScriptAnalyzerRule
			ForEach ($Rule in $ScriptAnalyzerRules) {
				It "Should pass $Rule" {
					If ($Analysis.RuleName -contains $Rule) {
						$Analysis |	Where-Object RuleName -EQ $Rule -OutVariable Failures | Out-Default
						$Failures.Count | Should Be 0
					}
				}
			}
		}
	}
}

Describe 'Module Information' {
    Context 'Manifest Testing' {
        It 'Valid Module Manifest' {
            {
                $Script:Manifest = Test-ModuleManifest -Path $ModuleManifest -ErrorAction Stop -WarningAction SilentlyContinue
            } | Should Not Throw
        }
        It 'Valid Manifest Name' {
            $Script:Manifest.Name | Should be $ModuleName
        }
        It 'Generic Version Check' {
            $Script:Manifest.Version -as [Version] | Should Not BeNullOrEmpty
        }
        It 'Valid Manifest Description' {
            $Script:Manifest.Description | Should Not BeNullOrEmpty
        }
        It 'Valid Manifest Root Module' {
            $Script:Manifest.RootModule | Should Be "$ModuleName.psm1"
        }
        It 'Valid Manifest GUID' {
            $Script:Manifest.Guid | SHould be '3c4360d3-f08e-4662-ac6f-43e7950efc2f'
        }
        It 'No Format File' {
            $Script:Manifest.ExportedFormatFiles | Should BeNullOrEmpty
        }

        It 'Required Modules' {
            $Script:Manifest.RequiredModules | Should BeNullOrEmpty
        }
    }

    Context 'Exported Functions' {
        It 'Proper Number of Functions Exported' {
            $ExportedCount = Get-Command -Module $ModuleName | Measure-Object | Select-Object -ExpandProperty Count
            $FileCount = Get-ChildItem -Path "$PSScriptRoot\..\source\functions\Public" -Filter *.ps1 | Measure-Object | Select-Object -ExpandProperty Count
            $ExportedCount | Should be $FileCount

        }
    }
}

Get-Command -Module $ModuleName | ForEach-Object {
    Describe 'Help' -Tags 'Help' {
        Context "Function - $_" {
            It 'Synopsis' {
                Get-Help $_ | Select-Object -ExpandProperty synopsis | should not benullorempty
            }
            It 'Description' {
                Get-Help $_ | Select-Object -ExpandProperty Description | should not benullorempty
            }
            It 'Examples' {
                $Examples = Get-Help $_ | Select-Object -ExpandProperty Examples | Measure-Object
                $Examples.Count -gt 0 | Should be $true
            }
        }
    }
}

