Function New-PSLocalGallery {
    <#
    .EXTERNALHELP PSLocalGallery-help.xml
    #>
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param()

    $PSLocalGalleryPath = 'C:\ProgramData\PSLocalGallery\Repository'
    If (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        If ((Test-Path -Path "$PSLocalGalleryPath") -eq $False) {
            Try {
                If ($PSCmdlet.ShouldProcess("Creating PSLocalGalleryPath: $PSLocalGalleryPath")) {
                    [void](New-Item -Path $PSLocalGalleryPath -ItemType Directory -Force -ErrorAction Stop)
                }
            } Catch {
                Throw "$($_.Exception.Message)"
            }
        } Else {
            Write-Verbose "PSLocalGallery path already exists: $PSLocalGalleryPath"
        }
    } Else {
        Throw "This function requires Administrator permissions"
    }
}