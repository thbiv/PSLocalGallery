Deploy "PSLocalGallery" {
    By PSGalleryModule {
        FromSource "$PSScriptRoot\_output\PSLocalGallery"
        To "PSLocalGallery"
    }
}
