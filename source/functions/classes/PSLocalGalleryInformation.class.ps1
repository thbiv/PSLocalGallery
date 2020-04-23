Class PSLocalGalleryInformation {
    [string]$Path
    [bool]$Exists
    [int]$PackageCount
    [bool]$IsRegistered

    PSLocalGalleryInformation ([string]$Path, [bool]$Exists, [int]$PackageCount, [bool]$IsRegistered) {
        $this.Path = $Path
        $this.Exists = $Exists
        $this.PackageCount = $PackageCount
        $this.IsRegistered = $IsRegistered
    }

    [string]ToString() {
        return ("[{0}][{1}][{2}][{3}]" -f $this.Path, $this.Exists, $this.PackageCount, $this.IsRegistered)
    }
}
