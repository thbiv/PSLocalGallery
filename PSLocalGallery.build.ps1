$Script:ModuleName = Split-Path -Path $PSScriptRoot -Leaf
$Script:SourceRoot = "$BuildRoot\source"
$Script:OutputRoot = "$BuildRoot\_output"
$Script:TestResultsRoot = "$BuildRoot\_testresults"
$Script:TestsRoot = "$BuildRoot\tests"
$Script:FileHashRoot = "$BuildRoot\_filehash"
$Script:Manifest = Import-PowerShellDataFile -Path "$SourceRoot\$ModuleName.psd1"
$Script:Source_PSD1 = "$SourceRoot\$ModuleName.psd1"
$Script:Dest_PSD1 = "$OutputRoot\$ModuleName\$ModuleName.psd1"
$Script:Dest_PSM1 = "$OutputRoot\$ModuleName\$ModuleName.psm1"

Task . Clean, Build, Test, Hash, Deploy
Task Testing Clean, Build, Test

# Synopsis: Empty the _output and _testresults folders
Task Clean {
    If (Test-Path -Path $OutputRoot) {
        Get-ChildItem -Path $OutputRoot -Recurse | Remove-Item -Force
    }
    If (Test-Path -Path $TestResultsRoot) {
        Get-ChildItem -Path $TestResultsRoot -Recurse | Remove-Item -Force
    }
}

# Synopsis: Compile and build the project
Task Build {
    Write-Host "Building Powershell Module '$ModuleName' $($Manifest.ModuleVersion)"
    New-Item -Path "$OutputRoot\$ModuleName" -ItemType Directory | Out-Null

    Write-Host "Compiling Classes"
    Get-ChildItem -Path "$SourceRoot\functions\classes" -file | ForEach-Object {
        $_ | Get-Content | Add-Content -Path $Dest_PSM1
    }

    Write-Host "Compiling Private Functions"
    Get-ChildItem -Path "$SourceRoot\functions\private" -file | ForEach-Object {
        $_ | Get-Content | Add-Content -Path $Dest_PSM1
    }

    Write-Host "Compiling Public Functions"
    Get-ChildItem -Path $SourceRoot\functions\public -File | ForEach-Object {
        $_ | Get-Content | Add-Content -Path  $Dest_PSM1
    }

    If (Test-Path -Path "$SourceRoot\en-US") {
        Write-Host "Creating 'en-US' folder"
        New-Item -Path "$OutputRoot\$ModuleName\en-US" -ItemType Directory | Out-Null
        Write-Host "Copying about_help files"
        Get-ChildItem -Path "$SourceRoot\en-US" -file | ForEach-Object {
            Write-Host "Copying About_Help file: $($_.Name)"
            Copy-Item -Path $_.FullName -Destination "$OutputRoot\$ModuleName\en-US\$($_.Name)" -Force
        }
    }

    If (Test-Path -Path "$SourceRoot\$ModuleName.format.ps1xml") {
        Write-Host "Copying Formats File"
        Copy-Item -Path "$SourceRoot\$ModuleName.format.ps1xml" -Destination "$OutputRoot\$ModuleName\$ModuleName.format.ps1xml"
    }

    Write-Host "Copying Module Manifest"
    Copy-Item -Path $Source_PSD1 -Destination $Dest_PSD1
}

# Synopsis: Test the Project
Task Test {
    $PesterBasic = @{
        OutputFile = "$TestResultsRoot\BasicModuleTestResults.xml"
        OutputFormat = 'NUnitXml'
        Script = @{Path="$TestsRoot\BasicModule.tests.ps1";Parameters=@{Path=$OutputRoot;ProjectName=$ModuleName}}
    }
    $BasicResults = Invoke-Pester @PesterBasic -PassThru
    Write-Host "Processing Pester Results"
    $FPesterParams = @{
        PesterResult = @($BasicResults)
        Path = "$TestResultsRoot"
        Format = 'HTML'
        Include = 'Passed','Failed'
        BaseFileName = "PesterResults_$ModuleName.$($Manifest.ModuleVersion)"
        ReportTitle = "Pester Results - $ModuleName - $($Manifest.ModuleVersion)"
    }
    Format-Pester @FPesterParams
    If ($BasicResults.FailedCount -ne 0) {Throw "One or more Basic Module Tests Failed"}
    Else {Write-Host "All tests have passed...Build can continue."}
}

# Synopsis: Produce File Hash for all output files
Task Hash {
    $Files = Get-ChildItem -Path "$OutputRoot\$ModuleName" -File -Recurse
    $HashOutput = @()
    ForEach ($File in $Files) {
        $HashOutput += Get-FileHash -Path $File.fullname
    }
    $HashExportFile = "ModuleFiles_Hash_$ModuleName.$($Manifest.ModuleVersion).xml"
    $HashOutput | Export-Clixml -Path "$FileHashRoot\$HashExportFile"
}

# Synopsis: Publish to repository
Task Deploy {
    Invoke-PSDeploy -Force -Verbose
}