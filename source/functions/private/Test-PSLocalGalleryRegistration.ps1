Function Test-PSLocalGalleryRegistration {
    <#
    .SYNOPSIS
        Test if the PSLocalGallery is registered.
    .DESCRIPTION
        Test if the PSLocalGallery is registered.
        Returns either $True or $False
    .EXAMPLE
        PS C:\> Test-PSLocalGalleryRegistration
    .INPUTS
        None
    .OUTPUTS
        Boolean
    #>
    [CmdletBinding()]
    Param()

    $A = Get-PSRepository -Name 'PSLocalGallery' -ErrorAction SilentlyContinue
    If ($A) {Write-Output $True} Else {Write-Output $False}
}
