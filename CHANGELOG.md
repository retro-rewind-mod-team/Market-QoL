# Changelog

## 1.4.1
- Added Market-QoL.yaml for RRMM (Retro Rewind Mod Manager) support

## 1.4
- Fixed a bug where reloading a save file reset the Lua VM state, causing `hasInjectedToday`
  to be `false` even though bundles were already written to disk — a subsequent manual save
  would then re-inject bundles, resulting in duplicates
- `ReceiveBeginPlay` now also sets `hasInjectedToday = true` so that any `Market_C:Save`
  call after a reload is correctly blocked

## 1.3
- Fixed compatibility with a game update that changed `Generate Movie Bundles For The Day`
  to clear and rewrite the bundle array on every call instead of appending to it; previously
  only the last injected bundle would appear in the shop
- Hook moved from `Generate Movie Bundles For The Day` to `Market_C:Save` so all native
  bundles are already in the array before injection runs
- Added re-save after injection so bundles are written to disk and survive a save reload
- Added `isSaving` guard to prevent the re-save from re-triggering the injection hook
- `ReceiveBeginPlay` now also resets `isSaving` in case it gets stuck after an unexpected error

## 1.2
- Added `hasInjectedToday` guard to prevent double injection when the game calls the bundle
  generator more than once per day (e.g. during the tutorial)
- Fixed save reload behaviour: recursion guard is released on reload, but the daily injection
  flag stays set so bundles are not added again to an already-injected day
- `getStoreLevel()` now returns nil when Core_Gamemode_C is unavailable, allowing the mod to
  distinguish between level 0 and level unknown — level curve is bypassed with a warning log
  when level cannot be determined
- Adult genre handling improved: when `enableAdult = true`, Adult bypasses the level curve
  check explicitly rather than relying on `math.huge` comparison

## 1.1
- Added level curve: genres unlock gradually as the store levels up, matching the game's own progression
- Added `ignoreLevelCurve` option in config — disables level requirements for testing or later playthroughs
- Added `enableAdult` option in config — Adult bundles are not normally available via the market and require explicit opt-in
- Replaced per-entry `free` flag with global `freeAll` option for simpler configuration
- Fixed a timing bug where bundles could be injected twice per day if the game called the bundle generator in quick succession
- Added `Debug` option in config for verbose logging

## 1.0
- Initial release
- Configurable bundles per genre with size and count
- Supports all 13 genres including Mixed, Comedy, Fantasy, and Kids
- Bundles saved natively — persist across reloads without duplicating
