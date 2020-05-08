Function Test-PSLocalGalleryRegistration {
    [CmdletBinding()]
    Param()

    $A = Get-PSRepository -Name 'PSLocalGallery' -ErrorAction SilentlyContinue
    If ($A) {Write-Output $True} Else {Write-Output $False}
}
