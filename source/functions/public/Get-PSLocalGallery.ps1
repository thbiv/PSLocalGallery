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
        If ($PackageCount -ne 0) {
            $Names = $Packages.name
            $Unique = $Names | ForEach-Object {
                $_.split('.')[0]
            } | Select-Object -Unique
            $UniqueCount = $Unique.count
        } Else {
            $UniqueCount = 0
        }
    } Else {
        $PackageCount = 0
        $UniqueCount = 0
    }
    Write-Output $(New-Object -TypeName PSLocalGalleryInformation -ArgumentList 'PSLocalGallery',
                                                                        $PSLocalGalleryPath,
                                                                        $Exists,
                                                                        $PackageCount,
                                                                        $UniqueCount,
                                                                        $IsRegistered)
}