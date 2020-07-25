Param (
    [switch]$BumpMajorVersion,
    [switch]$BumpMinorVersion,
    [switch]$NoVersionChange
)

$Script:ModuleName = Split-Path -Path $PSScriptRoot -Leaf
$Script:SourceRoot = "$BuildRoot\source"
$Script:DocsRoot = "$BuildRoot\docs"
$Script:OutputRoot = "$BuildRoot\_output"
$Script:TestResultsRoot = "$BuildRoot\_testresults"
$Script:TestsRoot = "$BuildRoot\tests"
$Script:FileHashRoot = "$BuildRoot\_filehash"
$Script:Dest_PSD1 = "$OutputRoot\$ModuleName\$ModuleName.psd1"
$Script:Dest_PSM1 = "$OutputRoot\$ModuleName\$ModuleName.psm1"
$Script:ModuleConfig = [xml]$(Get-Content -Path '.\Module.Config.xml')
$Script:Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

# Synopsis: Empty the _output, _testresults, and _filehash folders
Task CleanAndPrep {
    If (Test-Path -Path $OutputRoot) {
        Get-ChildItem -Path $OutputRoot -Recurse | Remove-Item -Force -Recurse
    } Else {
        New-Item -Path $OutputRoot -ItemType Directory -Force | Out-Null
    }
    New-Item -Path "$OutputRoot\$ModuleName" -ItemType Directory | Out-Null
    If (Test-Path -Path $TestResultsRoot) {
        Get-ChildItem -Path $TestResultsRoot -Recurse | Remove-Item -Force -Recurse
    } Else {
        New-Item -Path $TestResultsRoot -ItemType Directory -Force | Out-Null
    }
    If (Test-Path -Path $FileHashRoot) {
        Get-ChildItem -Path $FileHashRoot -Recurse | Remove-Item -Force -Recurse
    } Else {
        New-Item -Path $FileHashRoot -ItemType Directory -Force | Out-Null
}
}

# Synopsis: Compile the module file (PSM1)
Task CompileModuleFile {
    If (Test-Path -Path "$SourceRoot\functions\classes") {
        Write-Host "Compiling Classes"
        Get-ChildItem -Path "$SourceRoot\functions\classes" -file | ForEach-Object {
            $_ | Get-Content | Add-Content -Path $Dest_PSM1
        }
    } 

    If (Test-Path -Path "$SourceRoot\functions\private") {
        Write-Host "Compiling Private Functions"
        Get-ChildItem -Path "$SourceRoot\functions\private" -file | ForEach-Object {
            $_ | Get-Content | Add-Content -Path $Dest_PSM1
        }
    }

    If (Test-Path -Path "$SourceRoot\functions\public") {
        Write-Host "Compiling Public Functions"
        Get-ChildItem -Path "$SourceRoot\functions\public" -File | ForEach-Object {
            $_ | Get-Content | Add-Content -Path  $Dest_PSM1
        }
    }
}

# Synopsis: Compile the manifest file (PSD1)
Task CompileManifestFile {
    If (-not($NoVersionChange)) {
        $Version = [version]$($ModuleConfig.config.manifest.moduleversion)
        If ($BumpMajorVersion) {$MajorVersion = $($Version.Major + 1)}
        Else {
            $MajorVersion = $($Version.Major)
            $MinorVersion = 0
        }
        If ($BumpMinorVersion) {$MinorVersion = $($Version.Minor + 1)}
        Else {$MinorVersion = $($Version.Minor)}
        $NewVersion = "{0}.{1}.{2}" -f $MajorVersion,$MinorVersion,$($Version.Build + 1)
    } Else {
        $NewVersion = $($ModuleConfig.config.manifest.moduleversion)
    }
    
    # Find Aliases to Export
    $Code = Get-Content "$Dest_PSM1" -Raw
    $Tokens = [System.Management.Automation.PSParser]::Tokenize($code,[ref]$null)
    $SetAlias = $Tokens | Where-Object {($_.Type -eq 'Command') -and ($_.Content -eq 'Set-Alias') -and ($_.StartColumn -eq 1)}
    $ExportAlias = @()
    ForEach ($Item in $SetAlias) {
        $Line = $Tokens | Where-Object {$_.StartLine -eq $($Item.StartLine)}
        $NameEnd = ($Line | Where-Object {($_.Type -eq 'CommandParameter') -and ($_.Content -eq '-Name')}).EndCOlumn
        $Content = ($Line | Where-Object {($_.Type -eq 'CommandArgument') -and ($_.StartColumn -eq $($NameEnd + 1))}).Content
        $ExportAlias += $Content
}

    $Params = @{
        Path = $Dest_PSD1
        RootModule = "$ModuleName.psm1"
        GUID = $($ModuleConfig.config.manifest.guid)
        ModuleVersion = $NewVersion
        Author = $($ModuleConfig.config.manifest.author)
        Description = $($ModuleConfig.config.manifest.description)
        Copyright = $($ModuleConfig.config.manifest.copyright)
        ProjectUri = $($ModuleConfig.config.manifest.projecturi)
        LicenseUri = $($ModuleConfig.config.manifest.licenseuri)
        ReleaseNotes = $($ModuleConfig.config.manifest.releasenotes)
        Tags = $($($ModuleConfig.config.manifest.tags).split(','))
        FunctionsToExport = $(((Get-ChildItem -Path "$SourceRoot\functions\public").basename))
        FormatsToProcess = @()
        CompatiblePSEditions = "Desktop","Core"
        PowershellVersion = '5.1'
        CmdletsToExport = @()
        AliasesToExport = $ExportAlias
        VariablesToExport = @()
    }
    New-ModuleManifest @Params
    $Content = Get-Content -Path $Dest_PSD1
    $Content | ForEach-Object {$_.TrimEnd()} | Set-Content -Path $Dest_PSD1 -Force
    $ModuleConfig.config.manifest.moduleversion = $NewVersion
    $ModuleConfig.Save('Module.Config.xml')
}

# Synopsis: Compile/Copy formats file (PS1XML)
Task CompileFormats {
    If (Test-Path -Path "$SourceRoot\$ModuleName.format.ps1xml") {
        Write-Host "Copying Formats File"
        Copy-Item -Path "$SourceRoot\$ModuleName.format.ps1xml" -Destination "$OutputRoot\$ModuleName\$ModuleName.format.ps1xml"
    }
}

# Synopsis: Compile the help MAML file from Markdown documents
Task CompileHelp {
    If (Test-Path -Path $DocsRoot) {
        Write-Host 'Creating External Help'
        New-ExternalHelp -Path $DocsRoot -OutputPath "$OutputRoot\$ModuleName" -Force
        If (Test-Path -Path "$DocsRoot\about_help") {
            Write-Host 'Creating About Help file(s)'
            New-ExternalHelp -Path "$DocsRoot\about_help" -OutputPath "$OutputRoot\$ModuleName\en-US" -Force
        }
    }
    If (Test-Path -Path "$BuildRoot\LICENSE") {
        Write-Host 'Adding license file'
        Copy-Item -Path "$BuildRoot\LICENSE" -Destination "$OutputRoot\$ModuleName\LICENSE"
    }
}

Task Build CompileModuleFile, CompileManifestFile, CompileFormats, CompileHelp

# Synopsis: Test the Project
Task Test {
    $PesterBasic = @{
        Script = @{Path="$TestsRoot\BasicModule.tests.ps1";Parameters=@{Path=$OutputRoot;ProjectName=$ModuleName}}
        PassThru = $True
    }
    $Results = Invoke-Pester @PesterBasic
    $Manifest = Import-PowerShellDataFile -Path $Dest_PSD1
    $FileName = "Results_{0}_{1}" -f $ModuleName, $($Manifest.ModuleVersion)
    $Results | Export-Clixml -Path "$TestResultsRoot\$FileName.xml"
    Write-Host "Processing Pester Results"
    $PreContent = @()
    $PreContent += "Total Count: $($Results.TotalCount)"
    $PreContent += "Passed Count: $($Results.PassedCount)"
    $PreContent += "Failed Count: $($Results.FailedCount)"
    $PreContent += "Duration: $($Results.Time)"
    
    $HTML = $($Results.TestResult | ConvertTo-Html -Property Describe,Context,Name,Result,Time,FailureMessage,StackTrace,ErrorRecord -Head $Header -PreContent $($PreContent -join '<BR>') | Out-String)
    $HTML | Out-File -FilePath "$TestResultsRoot\$FileName.html"
    If ($Results.FailedCount -ne 0) {Throw "One or more Basic Module Tests Failed"}
    Else {Write-Host "All tests have passed."}
}

# Synopsis: Save test result files for later analysis
Task SaveResults {
    Write-Host "Copying Test Results"
    If (Test-Path -Path $($ModuleConfig.config.deployment.testresults)) {
        Copy-Item -Path "$TestResultsRoot\*.xml" -Destination "$($ModuleConfig.config.deployment.testresults)\XML" -Force | Out-Null
        Copy-Item -Path "$TestResultsRoot\*.html" -Destination "$($ModuleConfig.config.deployment.testresults)\HTML" -Force | Out-Null
    }
}

# Synopsis: Produce File Hash for all output files
Task Hash {
    $Manifest = Import-PowerShellDataFile -Path $Dest_PSD1
    $Files = Get-ChildItem -Path "$OutputRoot\$ModuleName" -File -Recurse
    $HashOutput = @()
    ForEach ($File in $Files) {
        $HashOutput += Get-FileHash -Path $File.fullname
    }
    $HashExportFile = "ModuleFiles_Hash_$ModuleName.$($Manifest.ModuleVersion).xml"
    $HashOutput | Export-Clixml -Path "$FileHashRoot\$HashExportFile"
}

# Synopsis: Save filehash file for future reference
Task SaveHash {
    Write-Host "Copying FileHash data"
    Copy-Item -Path $FileHashRoot -Destination "$($ModuleConfig.config.deployment.filehash)" -Force | Out-Null
}

# Synopsis: Publish to repository
Task Deploy {
    $SecureString = Get-Content -Path "$HOME\Documents\NugetAPIKey.txt" | ConvertTo-SecureString
    $ApiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR((($SecureString))))
    $Repository = $ModuleConfig.config.deployment.repository
    Write-Host "Publishing Module to $Repository"
    $Params = @{
        Path = "$OutputRoot\$ModuleName"
        Repository = $Repository
        NuGetApiKey = $ApiKey
        Force = $True
    }
    Publish-Module @Params
}

Task . CleanAndPrep, Build, Test, SaveResults, Hash, SaveHash, Deploy
Task Testing CleanAndPrep, Build, Test, SaveResults