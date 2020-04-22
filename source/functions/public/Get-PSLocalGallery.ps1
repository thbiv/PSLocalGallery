Function Get-PSLocalGallery {
    <#
    .SYNOPSIS
        Retrieves information the local powershell repository named PSLocalGallery.
    .DESCRIPTION
        {{Long description}}
    .EXAMPLE
        PS C:\> Get-PSLocalGallery
    .INPUTS
        None
    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    Param()

    $PSLocalGalleryPath = 'C:\ProgramData\PSLocalGallery\Repository'
    $IsRegistered = $(Test-PSLocalGalleryRegistration)
    $Exists = $(Test-Path -Path $PSLocalGalleryPath)
    If ($Exists) {
        $Packages = Get-ChildItem -Path $PSLocalGalleryPath -File | Where-Object {$_.Extension -eq '.nupkg'}
        $PackageCount = $Packages.Count
    } Else {
        $PackageCount = 0
    }
    $Props = [ordered]@{
        'Path' = $PSLocalGalleryPath
        'Exists' = $Exists
        'PackageCount' = $PackageCount
        'IsRegistered' = $IsRegistered
    }
    Write-Output $(New-Object -TypeName PSObject -Property $Props)
}
