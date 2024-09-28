# Detect-StarfieldFolder.ps1

function Find-StarfieldInMuiCache {
    $MuiCachePath = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"

    $MuiCacheProperties = Get-ItemProperty -Path $MuiCachePath -ErrorAction SilentlyContinue

    if ($MuiCacheProperties) {
        $MuiCacheEntries = @()

        foreach ($property in $MuiCacheProperties.PSObject.Properties) {
            if ($property.Name -notlike 'PS*') {
                $MuiCacheEntries += $property.Name
            }
        }

        # Look for keys that end with "Starfield.exe.FriendlyAppName"
        $StarfieldEntries = $MuiCacheEntries | Where-Object { $_ -match "Starfield\.exe\.FriendlyAppName$" }

        foreach ($entry in $StarfieldEntries) {
            # Remove ".FriendlyAppName" from the key name to get the path
            $exePath = $entry -replace '\.FriendlyAppName$', ''

            if (Test-Path $exePath) {
                # Get the directory of the executable
                $StarfieldFolderPath = [System.IO.Path]::GetDirectoryName($exePath)
                return "`"$StarfieldFolderPath`""
            }
        }
    }

    return $null
}

function Find-StarfieldInUninstallKeys {
    # Paths to uninstall registry keys
    $UninstallKeys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    )

    foreach ($keyPath in $UninstallKeys) {
        $subkeys = Get-ChildItem -Path $keyPath -ErrorAction SilentlyContinue

        foreach ($subkey in $subkeys) {
            $properties = Get-ItemProperty -Path $subkey.PSPath -ErrorAction SilentlyContinue
            $displayName = $properties.DisplayName
            $installLocation = $properties.InstallLocation

            if ($displayName -like '*Starfield*' -and $installLocation -and (Test-Path $installLocation)) {
                return "`"$installLocation`""
            }
        }
    }

    return $null
}

function Find-StarfieldInSteamLibraries {
    # Get the path to Steam installation
    $SteamRegistryKey = "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam"
    $SteamPath = (Get-ItemProperty -Path $SteamRegistryKey -ErrorAction SilentlyContinue).InstallPath

    if (!$SteamPath) {
        $SteamRegistryKey = "HKLM:\SOFTWARE\Valve\Steam"
        $SteamPath = (Get-ItemProperty -Path $SteamRegistryKey -ErrorAction SilentlyContinue).InstallPath
    }

    if ($SteamPath) {
        # Get library folders from Steam configuration files
        $LibraryFoldersVDF = Join-Path $SteamPath "steamapps\libraryfolders.vdf"

        if (Test-Path $LibraryFoldersVDF) {
            $LibraryPaths = @()

            # Read the libraryfolders.vdf file
            $content = Get-Content $LibraryFoldersVDF -Raw

            # Parse the VDF file to extract library paths
            $matches = [regex]::Matches($content, '"path"\s+"([^"]+)"')
            foreach ($match in $matches) {
                $path = $match.Groups[1].Value
                $LibraryPaths += (Join-Path $path "steamapps")
            }

            # Add default steamapps folder
            $LibraryPaths += (Join-Path $SteamPath "steamapps")

            # For each library path, check for starfield.exe
            foreach ($libPath in $LibraryPaths) {
                $StarfieldExePath = Join-Path $libPath "common\Starfield\Starfield.exe"

                if (Test-Path $StarfieldExePath) {
                    # Get the directory of the executable
                    $StarfieldFolderPath = [System.IO.Path]::GetDirectoryName($StarfieldExePath)
                    return "`"$StarfieldFolderPath`""
                }
            }
        }
    }

    return $null
}

function Find-StarfieldInCommonPaths {
    $PossiblePaths = @(
        "C:\Program Files\Starfield\Starfield.exe",
        "C:\Program Files (x86)\Starfield\Starfield.exe",
        "C:\Games\Starfield\Starfield.exe",
        "C:\XboxGames\Starfield\Content\Starfield.exe",
        "D:\XboxGames\Starfield\Content\Starfield.exe",
        "E:\XboxGames\Starfield\Content\Starfield.exe",
        "F:\XboxGames\Starfield\Content\Starfield.exe"
    )

    foreach ($path in $PossiblePaths) {
        if (Test-Path $path) {
            # Get the directory of the executable
            $StarfieldFolderPath = [System.IO.Path]::GetDirectoryName($path)
            return "`"$StarfieldFolderPath`""
        }
    }

    return $null
}

# Main script

$StarfieldPath = Find-StarfieldInMuiCache

if (!$StarfieldPath) {
    $StarfieldPath = Find-StarfieldInUninstallKeys
}

if (!$StarfieldPath) {
    $StarfieldPath = Find-StarfieldInSteamLibraries
}

if (!$StarfieldPath) {
    $StarfieldPath = Find-StarfieldInCommonPaths
}

if ($StarfieldPath) {
    Write-Output $StarfieldPath
} else {
    throw "Could not find the Starfield directory."
}
