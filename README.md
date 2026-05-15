# Market QoL

Automatically generates additional movie bundles in the shop computer each day based on your configuration. Bundles are appended after the game's own generation and saved natively, so they persist across reloads without duplicating.

## How It Works

When the game generates its daily bundles, this mod calls the same native generator once per configured entry — with your chosen genre, size, and count. The results are added to the shop alongside the game's own bundles and saved to disk.

Genres unlock gradually as your store levels up, matching the game's own progression curve. This can be disabled in `config.lua` for testing or later playthroughs.

## Installation

1. Drop the `Market-QoL` folder into your UE4SS Mods directory.
2. Edit `config.lua` to configure your bundles.
3. Start a new in-game day. Your bundles will appear in the shop computer.

## Requirements

- **UE4SS** must be installed first.
  Follow the installation instructions on the [UE4SS Nexus page](https://www.nexusmods.com/retrorewindvideostoresimulator/mods/52) before proceeding.

## Configuration

Open `config.lua` to set up your bundles. Each entry generates one or more bundles of a specific genre.

```lua
return {
    freeAll          = false,
    ignoreLevelCurve = false,
    enableAdult      = false,
    Debug            = false,

    bundles = {
        { genre = "Mixed",  size = 10, count = 1 },
        { genre = "Horror", size = 15, count = 1 },
        { genre = "Sci-Fi", size = 15, count = 2 },
    }
}
```

### Bundle Fields

| Field | Description |
|-------|-------------|
| `genre` | Genre name (see list below) |
| `size` | Number of cassettes per bundle |
| `count` | How many bundles of this type to generate per day |

### Global Options

| Option | Default | Description |
|--------|---------|-------------|
| `freeAll` | `false` | Set to `true` to make all generated bundles free of charge |
| `ignoreLevelCurve` | `false` | Set to `true` to unlock all genres immediately, regardless of store level |
| `enableAdult` | `false` | Set to `true` to include Adult bundles (not normally available via the market) |
| `Debug` | `false` | Set to `true` to enable verbose logging in the UE4SS console |

### Supported Genres and Level Requirements

| Genre | Unlocks at level |
|-------|-----------------|
| `"Mixed"` | 0 — available from the start (picks from entire catalog) |
| `"Drama"` | 0 |
| `"Horror"` | 0 |
| `"Sci-Fi"` | 3 |
| `"Action"` | 5 |
| `"Romance"` | 7 |
| `"Xmas"` | 9 |
| `"Fantasy"` | 11 |
| `"Kids"` | 13 |
| `"Comedy"` | 15 |
| `"Police"` | 17 |
| `"Western"` | 19 |
| `"Adult"` | Requires `enableAdult = true` |

## Notes

- Bundles are saved natively alongside the game's own bundles. Loading a save after a new day will not duplicate them.
- `freeAll` and `ignoreLevelCurve` are intended for testing or experienced players. They are not recommended for a first playthrough.
- Adventure is not supported — the game does not generate bundles for this genre.

## Compatibility

- Retro Rewind Video Store Simulator
- UE4SS v3.0.1

## License
Shield: [![CC BY-NC-SA 4.0][cc-by-nc-sa-shield]][cc-by-nc-sa]

This work is licensed under a
[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License][cc-by-nc-sa].

[![CC BY-NC-SA 4.0][cc-by-nc-sa-image]][cc-by-nc-sa]

[cc-by-nc-sa]: http://creativecommons.org/licenses/by-nc-sa/4.0/
[cc-by-nc-sa-image]: https://licensebuttons.net/l/by-nc-sa/4.0/88x31.png
[cc-by-nc-sa-shield]: https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg
[cc-by-sa-shield]: https://img.shields.io/badge/License-CC%20BY--SA%204.0-lightgrey.svg
