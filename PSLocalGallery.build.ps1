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

# Synopsis: Empty the _output and _testresults folders
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

Task CompileModuleFile {
# Synopsis: Compile the module file (PSM1)
    If (Test-Path -Path "$SourceRoot\classes") {
        Write-Host "Compiling Classes"
        Get-ChildItem -Path "$SourceRoot\classes" -file | ForEach-Object {
            $_ | Get-Content | Add-Content -Path $Dest_PSM1
            Write-Host "  - $($_.BaseName)"
        }
    } 

    If (Test-Path -Path "$SourceRoot\functions\private") {
        Write-Host "Compiling Private Functions"
        Get-ChildItem -Path "$SourceRoot\functions\private" -file | ForEach-Object {
            $_ | Get-Content | Add-Content -Path $Dest_PSM1
            Write-Host "  - $($_.BaseName)"
        }
    }

    If (Test-Path -Path "$SourceRoot\functions\public") {
        Write-Host "Compiling Public Functions"
        Get-ChildItem -Path "$SourceRoot\functions\public" -File | ForEach-Object {
            $_ | Get-Content | Add-Content -Path  $Dest_PSM1
            Write-Host "  - $($_.BaseName)"
        }
    }
}

# Synopsis: Compile/Copy formats files (PS1XML)
Task CompileFormats {
    If (Test-Path -Path "$SourceRoot\formats") {
        Write-Host "Copying Formats Files"
        Get-ChildItem -Path "$SourceRoot\formats" -File | ForEach-Object {
            Copy-Item -Path $($_.FullName) -Destination "$OutputRoot\$ModuleName" | Out-Null
            Write-Host "  - $($_.Name)"
        }
    }
}

# Synopsis: Compile the manifest file (PSD1)
Task CompileManifestFile {   
    # Find Aliases to Export
    $Code = Get-Content ".\_output\$ModuleName\$($ModuleName).psm1" -Raw
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
        ModuleVersion = [version]$($ModuleConfig.config.manifest.moduleversion)
        Author = $($ModuleConfig.config.manifest.author)
        Description = $($ModuleConfig.config.manifest.description)
        Copyright = $($ModuleConfig.config.manifest.copyright)
        ProjectUri = $($ModuleConfig.config.manifest.projecturi)
        LicenseUri = $($ModuleConfig.config.manifest.licenseuri)
        ReleaseNotes = $($ModuleConfig.config.manifest.releasenotes)
        Tags = $($($ModuleConfig.config.manifest.tags).split(','))
        FunctionsToExport = $(((Get-ChildItem -Path "$SourceRoot\functions\public").basename))
        FormatsToProcess = $() #$(((Get-ChildItem -Path "$SourceRoot\formats").Name))
        CompatiblePSEditions = "Desktop","Core"
        PowershellVersion = '5.1'
        CmdletsToExport = @()
        AliasesToExport = $ExportAlias
        VariablesToExport = @()
    }

    New-ModuleManifest @Params
    $Content = Get-Content -Path $Dest_PSD1
    $Content | ForEach-Object {$_.TrimEnd()} | Set-Content -Path $Dest_PSD1 -Force
}

# Synopsis: Compile the help MAML file from Markdown documents
Task CompileHelp {
    If (Test-Path -Path $DocsRoot) {
        Write-Host 'Creating External Help'
        New-ExternalHelp -Path $DocsRoot -OutputPath "$OutputRoot\$ModuleName" -Force | Out-Null
        If (Test-Path -Path "$DocsRoot\about_help") {
            Write-Host 'Creating About Help file(s)'
            New-ExternalHelp -Path "$DocsRoot\about_help" -OutputPath "$OutputRoot\$ModuleName\en-US" -Force | Out-Null
        }
    }
}

# Synopsis: Copy LICENSE file to the module folder
Task CopyLicense {
    If (Test-Path -Path "$BuildRoot\LICENSE") {
        Write-Host 'Adding license file'
        Copy-Item -Path "$BuildRoot\LICENSE" -Destination "$OutputRoot\$ModuleName\LICENSE"
    }
}

Task Build CompileModuleFile, CompileManifestFile, CompileFormats, CompileHelp, CopyLicense

# Synopsis: Test the Project
Task PesterTest {
    $PesterBasic = @{
        Script = @{Path="$TestsRoot\BasicModule.tests.ps1";Parameters=@{Path=$OutputRoot;ProjectName=$ModuleName}}
        PassThru = $True
    }
    $Script:Results = Invoke-Pester @PesterBasic
    
    If ($Results.FailedCount -ne 0) {Throw "One or more Basic Module Tests Failed"}
    Else {Write-Host "All tests have passed."}
}

# Synopsis: Convert XML Test Results to Readable HTML format
Task ConvertTestResultsToHTML {
    $Script:Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

    $PreContent = @()
    $PreContent += "Total Count: $($Results.TotalCount)"
    $PreContent += "Passed Count: $($Results.PassedCount)"
    $PreContent += "Failed Count: $($Results.FailedCount)"
    $PreContent += "Duration: $($Results.Time)"
    
    $FileName = 'Pester-Test-Results'
    $HTML = $($Results.TestResult | ConvertTo-Html -Property Describe,Context,Name,Result,Time,FailureMessage,StackTrace,ErrorRecord -Head $Header -PreContent $($PreContent -join '<BR>') | Out-String)
    $HTML | Out-File -FilePath "$TestResultsRoot\$FileName.html"
}

Task Test PesterTest, ConvertTestResultsToHTML

# Synopsis: Get Release Notes
Task GetReleaseNotes {
    $ChangeLog = Get-ChangelogData
    $EmptyChangeLog = $True
    $ReleaseNotes = ForEach ($Property in $ChangeLog.Unreleased[0].Data.PSObject.Properties.Name) {
        $Data = $ChangeLog.Unreleased[0].Data.$Property
        If ($Data) {
            $EmptyChangeLog = $False
            Write-Output $Property
            ForEach ($Item in $Data) {
                Write-Output ("- {0}" -f $Item)
            }
        }
    }
    If ($EmptyChangeLog -eq $True -Or $ReleaseNotes.Count -eq 0) {
        $ReleaseNotes = "None"
    }
    Write-Output "Release notes:"
    Write-Output $ReleaseNotes
    Set-Content -Value $ReleaseNotes -Path $OutputRoot\Release-Notes.txt -Force
}

# Synopsis: Move unlreleased changes to a release version
Task UpdateChangeLog {
    $Params = @{
        ReleaseVersion = $($env:ModuleVersion)
        LinkMode = 'None'
    }
    Update-Changelog @Params
}

# Synopsis: Produce File Hash for all output files
Task Hash {
    $Files = Get-ChildItem -Path "$OutputRoot\$ModuleName" -File -Recurse
    $HashOutput = @()
    ForEach ($File in $Files) {
        $HashOutput += Get-FileHash -Path $File.fullname
    }
    $HashExportFile = "FileHash.xml"
    $HashOutput | Export-Clixml -Path "$FileHashRoot\$HashExportFile"
}

Task . CleanAndPrep, Build, Test
Task Release CleanAndPrep, Build, Test, GetReleaseNotes, UpdateChangeLog, Hash