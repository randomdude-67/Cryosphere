#Requires -Version 5.1
<#
.SYNOPSIS
Packages Cryosphere and installs it into the Steam edition of Mindustry.
.PARAMETER SteamPath
Optional Steam client directory. Its libraryfolders.vdf is also searched.
.EXAMPLE
.\deploy.ps1
.EXAMPLE
.\deploy.ps1 -SteamPath 'D:\Steam'
#>
[CmdletBinding()]
param(
    [string] $SteamPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Find-MindustrySteamInstall {
    param([string] $SteamRoot)

    $steamRoots = @()
    if ($SteamRoot) {
        $steamRoots += $SteamRoot
    } else {
        $registryLocations = @(
            @{ Path = 'HKCU:\Software\Valve\Steam'; Name = 'SteamPath' }
            @{ Path = 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam'; Name = 'InstallPath' }
            @{ Path = 'HKLM:\SOFTWARE\Valve\Steam'; Name = 'InstallPath' }
        )
        foreach ($location in $registryLocations) {
            $value = Get-ItemPropertyValue -LiteralPath $location.Path -Name $location.Name -ErrorAction SilentlyContinue
            if ($value) {
                $steamRoots += $value
            }
        }
        foreach ($programFiles in @(${env:ProgramFiles(x86)}, $env:ProgramFiles)) {
            if ($programFiles) {
                $steamRoots += Join-Path $programFiles 'Steam'
            }
        }
    }

    foreach ($root in ($steamRoots | Select-Object -Unique)) {
        $libraries = @($root)
        $libraryFile = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $libraryFile -PathType Leaf) {
            $libraryData = Get-Content -LiteralPath $libraryFile -Raw
            foreach ($match in [regex]::Matches($libraryData, '(?m)^\s*"path"\s+"([^"]+)"')) {
                $libraries += $match.Groups[1].Value.Replace('\\', '\')
            }
        }

        foreach ($library in ($libraries | Select-Object -Unique)) {
            $manifest = Join-Path $library 'steamapps\appmanifest_1127400.acf'
            if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
                continue
            }

            $manifestData = Get-Content -LiteralPath $manifest -Raw
            if ($manifestData -notmatch '"appid"\s+"1127400"') {
                continue
            }
            $installMatch = [regex]::Match($manifestData, '"installdir"\s+"([^"]+)"')
            if (-not $installMatch.Success) {
                continue
            }

            $installName = $installMatch.Groups[1].Value
            if ($installName -in @('.', '..') -or $installName -match '[\\/:]') {
                throw "Unexpected Mindustry install directory in Steam manifest: $manifest"
            }
            $gameDirectory = Join-Path (Join-Path $library 'steamapps\common') $installName
            if (Test-Path -LiteralPath (Join-Path $gameDirectory 'Mindustry.exe') -PathType Leaf) {
                return (Get-Item -LiteralPath $gameDirectory).FullName
            }
        }
    }

    throw 'Mindustry was not found in the Steam libraries. Install it through Steam, or pass -SteamPath with the Steam client directory. No AppData fallback is used.'
}

# Resolve the Steam destination before creating or replacing any archives.
$gameDirectory = Find-MindustrySteamInstall -SteamRoot $SteamPath
$modsDirectory = Join-Path $gameDirectory 'saves\mods'
$projectDirectory = $PSScriptRoot
$metadata = Join-Path $projectDirectory 'mod.hjson'
if (-not (Test-Path -LiteralPath $metadata -PathType Leaf)) {
    throw "Mod metadata is missing: $metadata"
}

# Match tools/package.py: only runtime assets and optional documentation.
$files = @((Get-Item -LiteralPath $metadata))
foreach ($optional in @('icon.png', 'LICENSE', 'README.md')) {
    $path = Join-Path $projectDirectory $optional
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        $files += Get-Item -LiteralPath $path
    }
}
foreach ($directory in @('bundles', 'content', 'maps', 'music', 'schematics', 'sounds', 'sprites')) {
    $path = Join-Path $projectDirectory $directory
    if (Test-Path -LiteralPath $path -PathType Container) {
        $files += Get-ChildItem -LiteralPath $path -Recurse -File -Force | Where-Object {
            $relativePath = $_.FullName.Substring($projectDirectory.Length + 1).Replace('\', '/')
            $relativePath -notmatch '(^|/)\.'
        }
    }
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$outputDirectory = Join-Path $projectDirectory 'dist'
[System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
$archivePath = Join-Path $outputDirectory 'cryosphere.zip'
$stream = [System.IO.File]::Open($archivePath, [System.IO.FileMode]::Create)
try {
    $archive = [System.IO.Compression.ZipArchive]::new($stream, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($file in ($files | Sort-Object FullName)) {
            $entryName = $file.FullName.Substring($projectDirectory.Length + 1).Replace('\', '/')
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $archive, $file.FullName, $entryName, [System.IO.Compression.CompressionLevel]::Optimal
            ) | Out-Null
        }
    } finally {
        $archive.Dispose()
    }
} finally {
    $stream.Dispose()
}

[System.IO.Directory]::CreateDirectory($modsDirectory) | Out-Null
$destination = Join-Path $modsDirectory 'cryosphere.zip'
Copy-Item -LiteralPath $archivePath -Destination $destination -Force

Write-Host "Packaged: $archivePath"
Write-Host "Deployed to Steam: $destination"
Write-Host 'Restart Mindustry to load the updated mod.'
