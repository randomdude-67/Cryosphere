# Cryosphere

An **HJSON-only mod for Mindustry V8** (build 150 or newer). No Java,
JavaScript, Gradle, or compilation is required to install or run it.

The initial content is an independent **Tantros** orbiting the vanilla sun,
with a deep teal liquid surface, a fully opaque near-surface ice layer, and a
bright turquoise atmosphere,
and underwater environment flags. Its internal ID is `cryosphere-tantros-reborn`.
Vanilla `tantros` stays hidden and inaccessible; its definition, generator,
and sectors are not modified. The two planets have separate content IDs.

## Current scope

Tantros is currently a visible, selectable orbital body with a single
gridless placeholder sector. It is not a finished campaign: no custom blocks,
items, units, technology tree, or maps have been added yet.

Mindustry V8's HJSON loader constructs `AsteroidGenerator` for every HJSON
planet `generator` field. It cannot instantiate `TantrosPlanetGenerator`,
even with `type: TantrosPlanetGenerator`. The planet therefore uses a
supported `NoiseMesh` and `HexSkyMesh` combination to approximate Tantros's
appearance. The water is the base surface; a slightly brighter opaque ice shell
is rendered on the separate cloud layer. This does not restore the original
procedural terrain.

The HJSON loader adds a placeholder sector to each new planet. Cryosphere
keeps that placeholder so Tantros appears in the planet selector, but leaves
the planet generator unset so it cannot be mistaken for a finished campaign
sector. A future campaign will replace this with actual `.msav` maps, a
generator, and sector presets.

## Install

1. Create the installable archive with `python tools/package.py` (Python 3.9
   or newer), or download the packaged `cryosphere.zip` workflow artifact.
2. In Mindustry V8, open **Mods → Import Mod** and select the ZIP. If you
   built it locally, select `dist/cryosphere.zip`.
3. Restart the game and open the campaign planet view. The new Tantros is
   visible and selectable in the solar system, but is not a launch destination
   yet.

The packaged archive places `mod.hjson` at its root. Python is only a
developer convenience for packaging; the game does not use it. GitHub
Actions also builds the ZIP on pushes, pull requests, and manual runs.
Download the `cryosphere` workflow artifact and extract its outer wrapper
to obtain the installable `cryosphere.zip`.

### Deploy to Steam on Windows

Run this from PowerShell:

```powershell
.\deploy.ps1
```

[deploy.ps1](./deploy.ps1) locates Steam using the Windows registry and
checks its configured libraries for Mindustry (Steam app ID `1127400`).
It builds `dist/cryosphere.zip` and copies it into the game's
`saves/mods/cryosphere.zip`, replacing the previous deployed archive.
Restart Mindustry after deployment to load the changes.

The script uses PowerShell 5.1 or newer and built-in .NET ZIP support;
Python is not required. It can also be invoked by its full path from
another working directory. For a custom Steam client location, run:

```powershell
.\deploy.ps1 -SteamPath 'D:\Steam'
```

Deployment requires Mindustry's Steam manifest and executable. It never
falls back to the standalone/itch.io data directory in AppData.

## Layout

```text
mod.hjson                 Mod identity, version, and V8 minimum build
content/
  planets/
    tantros-reborn.hjson  The independent planet
  blocks/                 Reserved for future HJSON blocks
  items/                  Reserved for future HJSON items
  liquids/                Reserved for future HJSON liquids
  sectors/                Reserved for future HJSON sector presets
  statuses/               Reserved for future HJSON status effects
  units/                  Reserved for future HJSON units
  weather/                Reserved for future HJSON weather
bundles/bundle.properties English names and descriptions
maps/                     Future .msav campaign maps
sprites/                  Future PNG sprites, organized by content type
sounds/                   Future sound effects
music/                    Future music
schematics/               Future .msch schematics
tools/package.py          Standard-library ZIP packager
deploy.ps1                Package and deploy to the Steam installation
.github/workflows/        Automatic archive packaging
```

Empty asset directories contain `.gitkeep` files so Git preserves them.
These placeholders, developer tools, and GitHub configuration are excluded
from the packaged mod.

### Sprite organization

```text
sprites/
  blocks/
    crafting/
    defense/
    distribution/
    liquids/
    power/
    production/
    storage/
    turrets/
    units/                Unit factories, reconstructors, and related blocks
  environment/            Floors, walls, ores, and decoration
  items/
  liquids/
  statuses/
  ui/
  units/
    air/
    ground/
    naval/
```

These folders are for organization. Mindustry discovers sprites recursively;
use unique sprite filenames across all folders. Sprites for mod content use
the content filename as their base name; Mindustry adds the mod prefix.

Keep `name: cryosphere` and the planet filename stable once saves or other
mods use `cryosphere-tantros-reborn`. Use the fully qualified ID when referring to
this planet: the unprefixed `tantros` resolves to the vanilla planet first.
The distinct filename also avoids V8 treating a same-named content file as
a vanilla override when assigning mod ownership.

## Upstream references

- [V8 build 150](https://github.com/Anuken/Mindustry/releases/tag/v150)
- [Vanilla Tantros definition (V8 build 160.7)](https://github.com/Anuken/Mindustry/blob/v160.7/core/src/mindustry/content/Planets.java)
- [V8 HJSON planet, generator, and mesh parsing](https://github.com/Anuken/Mindustry/blob/v160.7/core/src/mindustry/mod/ContentParser.java)

## Validation

The packaged mod was loaded with the official V8 headless server for build
**160.7** without content errors. Runtime checks confirmed the new planet is
owned by Cryosphere and retains its selector-visible placeholder sector.
Comparisons against a server without the mod confirmed vanilla Tantros retains
its visibility, accessibility, sector count, generator, environment, and
appearance settings. These are loader checks; they do not verify graphical
rendering.
