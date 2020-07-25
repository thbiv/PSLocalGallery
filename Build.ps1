[CmdletBinding()]
Param (
    [Parameter(Mandatory=$False,Position=0)]
    [ValidateSet('.','Testing')]
    [string]$BuildTask = '.',

    [Parameter(ParameterSetName='VersionChange')]
    [switch]$BumpMajorVersion,

    [Parameter(ParameterSetName='VersionChange')]
    [switch]$BumpMinorVersion,

    [Parameter(ParameterSetName='NoVersionChange')]
    [switch]$NoVersionChange
)

Write-Host "Bootstrap Environment"
Write-Host "Loading Config File"
[xml]$ModuleConfig = Get-Content Module.Config.xml
Write-Host "Nuget PackageProvider"
If (-not(Get-PackageProvider -Name Nuget)) {
    Write-Host "  - Installing..." -NoNewline
    Install-PackageProvider -Name Nuget -Force -Scope CurrentUser
    Write-Host "Done" -ForegroundColor Green
} Else {Write-Host "  - Already installed" -ForegroundColor Green}

Write-Host "Repositories"
If (((Get-PSRepository -Name PSGallery).InstallationPolicy) -ne 'Trusted') {
    Write-Host "  - Setting PSGallery to Trusted..." -NoNewline
    Set-PSRepository -Name PSGallery -InstallationPolicy 'Trusted'
    Write-Host "Done" -ForegroundColor Green
} Else { Write-Host "  - PSGallery is Trusted"}
Write-Host "Module Dependencies"
$RequiredModules = $ModuleConfig.config.requiredmodules.module
ForEach ($Module in $RequiredModules) {
    Write-Host "  $($Module.name)"
    If (-not(Get-Module -Name $($Module.name) -ListAvailable)) {
        Write-Host "  - Installing..." -NoNewline
        $Params = @{
            Name = $($Module.name)
            Scope = 'CurrentUser'
            Force = $True
        }
        If ($Null -ne $Module.requiredversion) {$Params += @{RequiredVersion = $($Module.requiredversion)}}
        If ($Null -ne $Module.repository) {$Params += @{Repository = $($Module.repository)}}
        Install-Module @Params
        Write-Host "Done" -ForegroundColor Green
    } Else {Write-Host "  - Already Installed" -ForegroundColor Green}
    If (-not(Get-Module -Name $($Module.name))) {
        Write-Host "  - Importing..." -NoNewline
        Import-Module -Name $($Module.name)
        Write-Host "Done" -ForegroundColor Green
    } Else {Write-Host "  - Already Imported" -ForegroundColor Green}
}

$Params = @{
    Task = $BuildTask
    File = 'PSLocalGallery.build.ps1'
}
If ($NoVersionChange) {
    $Params.Add('NoVersionChange',$True)
}
If ($BumpMajorVersion) {
    $Params.Add('BumpMajorVersion',$True)
}
If ($BumpMinorVersion) {
    $Params.Add('BumpMinorVersion',$True)
}
Invoke-Build @Params