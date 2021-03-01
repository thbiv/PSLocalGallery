# PSLocalGallery

[GitHub Workflow Status](https://img.shields.io/github/workflow/status/thbiv/PSLocalGallery/Module-Build)
![GitHub](https://img.shields.io/github/license/thbiv/PSLocalGallery)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/thbiv/PSLocalGallery)

![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/PSLocalGallery)
![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/PSLocalGallery)
![PowerShell Gallery](https://img.shields.io/powershellgallery/p/PSLocalGallery)

---

#### Table of Contents

-   [Synopsis](#Synopsis)
-   [Commands](#Commands)
-   [Installing PSLocalGallery](#Installing-PSLocalGallery)
-   [Usage](#Usage)
-   [The Repository](#The-Repository)
-   [Licensing](#Licensing)
-   [Release Notes](#Release-Notes)

---

## Synopsis

PSLocalGallery allows you to create a simple folder-based Powershell repository to be used with the PowershellGet module. The module only creates a single repository. Creating multiple repositories is not supported (and really, why would you need more than one). The repository is really only designed to be used for testing.

---

## Commands

[New-PSLocalGallery](docs\New-PSLocalGallery.md)

Creates the folder that will be used as the repository and registers that repository as ```PSLocalGallery```.

[Get-PSLocalGallery](docs\Get-PSLocalGallery)

Outputs details on the repository as well as a few stats.

-   Name - The name of the repository. Will always be ```PSLocalGallery```.
-   Path - Path to the folder the contains all of the packages.
-   Exists - Indicates whether or not the repository path exists.
-   IsRegistered - Indicates whether or not ```PSLocalGallery``` is registered as a PSRepository.
-   PackageTotal - The number of total packages in the repository.
-   PackageUnique - The number of unique packages in the repository.

---

## Installing PSLocalGallery

```Powershell
Install-Module -Name PSLocalGallery
```

---

## Usage

Using the PSLocalGallery is very simple at the moment. There are only commands with no parameters. To create the repository, use ```New-PSLocalGallery```. This command does require you to run with administrative access.

```Powershell
New-PSLocalGallery
```

After creating the repository, you will need to register the repository before you can start using it. To easily register the 
repository, use ```Register-PSLocalGallery```.

```Powerhell
Register-PSLocalGallery
```

To get some details on the repository, use ```Get-PSLocalGallery```.

```Powershell
Get-PSLocalGallery
```

---

## The Repository

The repository will always be located in the same directory. I found it much easier to use and I didn't need to make any permission changes is i use the ```ProgramData``` instead of just using the root of the ```C:\``` drive. The full path is:

```
C:\ProgramData\PSLocalGallery\Repository
```

The packages are all placed in the ```Repository``` folder under the ```PSLocalGallery``` folder. This was done in case the repository becomes more advanced later with other folders and files.

---

## Licensing

PSNavigation is licensed under the [MIT License](LICENSE)

---

## Release Notes

Please refer to [Release Notes](Release-Notes.md)