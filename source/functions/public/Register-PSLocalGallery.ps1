Function Register-PSLocalGallery {
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param()

    $PSLocalGalleryPath = 'C:\ProgramData\PSLocalGallery\Repository'
    $RegParams = @{
        Name = 'PSLocalGallery'
        SourceLocation = $PSLocalGalleryPath
        PublishLocation = $PSLocalGalleryPath
        InstallationPolicy = 'Trusted'
    }
    Try {
        If ($PSCmdlet.ShouldProcess("Registering PSLocalGallery")) {
            Register-PSRepository @RegParams -ErrorAction Stop
        }
    } Catch {
        Throw "$($_.Exception.Message)"
    }
}