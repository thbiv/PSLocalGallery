Write-Host "Loading Config File"
[xml]$ModuleConfig = Get-Content Module.Config.xml
Write-Host "Nuget PackageProvider"
If (-not(Get-PackageProvider -Name Nuget)) {
    Write-Host "  - Installing..." -NoNewline
    Install-PackageProvider -Name Nuget -Force -Scope CurrentUser
    Write-Host "Done" -ForegroundColor Green
} Else {Write-Host "  - Already installed" -ForegroundColor Green}

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
        Install-Module @Params
        Write-Host "Done" -ForegroundColor Green
    } Else {Write-Host "  - Already Installed" -ForegroundColor Green}
    If (-not(Get-Module -Name $($Module.name))) {
        Write-Host "  - Importing..." -NoNewline
        Import-Module -Name $($Module.name)
        Write-Host "Done" -ForegroundColor Green
    } Else {Write-Host "  - Already Imported" -ForegroundColor Green}
}
Invoke-Build