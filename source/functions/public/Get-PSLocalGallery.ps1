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
        PSLocalGalleryInformation
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
    Write-Output $(New-Object -TypeName PSLocalGalleryInformation -ArgumentList $PSLocalGalleryPath,
                                                                        $Exists,
                                                                        $PackageCount,
                                                                        $IsRegistered)
}