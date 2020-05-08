Function Get-PSLocalGallery {
    <#
    .EXTERNALHELP PSLocalGallery-help.xml
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