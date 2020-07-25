Class PSLocalGalleryInformation {
    [string]$Name
    [string]$Path
    [bool]$Exists
    [int]$PackageTotal
    [int]$PackageUnique
    [bool]$IsRegistered

    PSLocalGalleryInformation ([string]$Name, [string]$Path, [bool]$Exists, [int]$PackageTotal, [int]$PackageUnique, [bool]$IsRegistered) {
        $this.Name = $Name
        $this.Path = $Path
        $this.Exists = $Exists
        $this.PackageTotal = $PackageTotal
        $this.PackageUnique = $PackageUnique
        $this.IsRegistered = $IsRegistered
    }

    [string]ToString() {
        return ("{0}" -f $this.Name)
    }
}
