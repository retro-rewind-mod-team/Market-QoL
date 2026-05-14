-- ============================================================
--  Retro Rewind - Market QoL
--  Version: 1.4
--
--  Generates additional bundles in the shop each day based
--  on your configuration. Bundles are appended after the
--  game's native generation and saved to disk, so they
--  persist across reloads without being duplicated.
--
--  HOW IT WORKS:
--  After the game saves its daily market data, this mod calls
--  the same native bundle generator once per config entry with
--  the configured genre, size, and count. The results are
--  appended to Marketplace Movie Bundles of the Day and saved
--  to disk in a follow-up save call.
--
--  Genres unlock gradually as the store levels up, matching
--  the game's own progression curve. This can be disabled
--  via ignoreLevelCurve in config.lua.
--
--  USAGE:
--  Edit config.lua, then start a new in-game day. Your
--  additional bundles will appear in the shop computer.
-- ============================================================

local CONFIG = require("config")

-- ============================================================
-- INTERNAL
-- ============================================================

local P = "[Market-QoL] "

local function log(msg)
    print(P .. msg)
end

local function debug(msg)
    if CONFIG.Debug then
        log(msg)
    end
end

local function safe(label, fn, ...)
    local results = {pcall(fn, ...)}
    if not results[1] then
        log(label .. " FAILED: " .. tostring(results[2]))
        return nil
    end
    return true
end

-- isInjecting: prevents recursive hook triggering while our injection runs.
-- hasInjectedToday: prevents injecting twice if the game calls Save more
-- than once per day. Reset at day end.
-- isSaving: prevents the re-save after injection from re-triggering the hook.
local isInjecting      = false
local hasInjectedToday = false
local isSaving         = false

local function resetGuards()
    isInjecting      = false
    hasInjectedToday = false
    isSaving         = false
end

local registeredHooks = {}

local function registerHookOptional(path, callback)
    if registeredHooks[path] then return end
    registeredHooks[path] = true
    local ok, err = pcall(function() RegisterHook(path, callback) end)
    if ok then
        debug("Hook active: " .. path)
    else
        log("Hook error: " .. path .. " / " .. tostring(err))
    end
end

-- ============================================================
-- GENRE MAP
-- Byte values confirmed via ObjectDump and in-game cassette
-- pickup testing (Genre_27_8F38DC364314469FC08A2AB858AC3CF8
-- in BoxData, Movie_Genre_Tags enum).
-- Mixed (0) confirmed by reading native bundle SpecificGenre
-- directly from Market_C at runtime.
-- ============================================================

local GENRE_MAP = {
    ["Mixed"]   =  0,   -- no genre filter, game picks from entire catalog
    ["Action"]  =  1,
    ["Comedy"]  =  3,
    ["Drama"]   =  4,
    ["Horror"]  =  5,
    ["Sci-Fi"]  =  6,
    ["Fantasy"] =  7,
    ["Romance"] = 10,
    ["Kids"]    = 12,
    ["Police"]  = 14,
    ["Adult"]   = 16,
    ["Western"] = 17,
    ["Xmas"]    = 18,
}

-- Minimum store level required per genre, matching the game's
-- own progression curve. Mixed, Horror, and Drama are available
-- from the start. Adult is excluded from the normal market
-- and requires enableAdult = true in config.lua.
local GENRE_MIN_LEVEL = {
    ["Mixed"]   =  0,
    ["Horror"]  =  0,
    ["Drama"]   =  0,
    ["Sci-Fi"]  =  3,
    ["Action"]  =  5,
    ["Romance"] =  7,
    ["Xmas"]    =  9,
    ["Fantasy"] = 11,
    ["Kids"]    = 13,
    ["Comedy"]  = 15,
    ["Police"]  = 17,
    ["Western"] = 19,
    -- Adult is gated by enableAdult, not the level curve, so this entry is never read.
}

-- ============================================================
-- HELPER: Read current store level from Core_Gamemode_C.
-- Returns nil if the gamemode is not yet available so callers
-- can distinguish "level 0" from "level unknown".
-- ============================================================

local function getStoreLevel()
    local gms = FindAllOf("Core_Gamemode_C")
    if not gms or not gms[1] then return nil end
    local ok, level = pcall(function() return gms[1]["Level"] end)
    return (ok and type(level) == "number") and level or nil
end

-- ============================================================
-- VALIDATION
-- Runs once at startup to catch config errors early.
-- Returns false if any entry is invalid, but does not prevent
-- valid entries from running -- invalid ones are skipped.
-- ============================================================

local function validateConfig()
    if type(CONFIG.bundles) ~= "table" then
        log("Config error: 'bundles' must be a table")
        return false
    end

    local allValid = true

    for i, entry in ipairs(CONFIG.bundles) do
        local prefix = "Entry [" .. i .. "] (" .. tostring(entry.genre) .. "): "

        -- genreByte can be 0 (Mixed), so check for nil explicitly
        if GENRE_MAP[entry.genre] == nil then
            log(prefix .. "unknown genre -- entry will be skipped")
            allValid = false
        end

        if type(entry.size) ~= "number" or entry.size < 1 then
            log(prefix .. "'size' must be a positive number -- entry will be skipped")
            allValid = false
        end

        if type(entry.count) ~= "number" or entry.count < 1 then
            log(prefix .. "'count' must be a positive number -- entry will be skipped")
            allValid = false
        end
    end

    return allValid
end

-- ============================================================
-- CORE: Inject configured bundles into the market.
-- Calls Generate Movie Bundles For The Day once per config
-- entry on the same Market_C instance the game just used.
-- Level curve is checked per entry unless ignoreLevelCurve
-- is set in config.lua.
-- ============================================================

local function injectBundles(market)

    local storeLevel    = getStoreLevel()
    local levelKnown    = storeLevel ~= nil
    local totalInjected = 0
    local totalSkipped  = 0

    if levelKnown then
        debug("Store level: " .. storeLevel)
    else
        log("Warning: Core_Gamemode_C unavailable -- level curve bypassed for this run")
    end

    for _, entry in ipairs(CONFIG.bundles) do
        -- genreByte can legitimately be 0 (Mixed), check for nil explicitly
        local genreByte = GENRE_MAP[entry.genre]

        if genreByte ~= nil
        and type(entry.size)  == "number" and entry.size  >= 1
        and type(entry.count) == "number" and entry.count >= 1
        then
            local minLevel = GENRE_MIN_LEVEL[entry.genre] or 0
            local isAdult  = (entry.genre == "Adult")

            -- Adult requires explicit opt-in; when allowed it bypasses the level curve
            if isAdult and not CONFIG.enableAdult then
                debug("Skipping Adult -- enableAdult is false")
                totalSkipped = totalSkipped + 1

            -- Level curve: skipped for Adult (handled above), unknown level, or ignoreLevelCurve
            elseif not isAdult and levelKnown and not CONFIG.ignoreLevelCurve and storeLevel < minLevel then
                debug("Skipping " .. entry.genre .. " -- requires level " ..
                      minLevel .. " (current: " .. storeLevel .. ")")
                totalSkipped = totalSkipped + 1

            else
                local bundleSize  = entry.size
                local bundleCount = entry.count
                local isFree      = CONFIG.freeAll == true

                local ok = safe("inject " .. entry.genre, function()
                    -- Calls the native bundle generator with our parameters.
                    -- Signature (confirmed via ObjectDump):
                    --   Force a Number of Bundle  [Int]  -- how many bundles to generate
                    --   Make it Free              [Bool] -- override price to zero
                    --   Force Bundle Genre        [Byte] -- genre enum value
                    --   Bundle Movie Size         [Int]  -- cassettes per bundle
                    --   Random Movie Size         [Bool] -- false = use our exact size
                    market["Generate Movie Bundles For The Day"](
                        bundleCount,
                        isFree,
                        genreByte,
                        bundleSize,
                        false
                    )
                end)

                if ok then
                    totalInjected = totalInjected + bundleCount
                    log("Added " .. bundleCount .. "x " .. entry.genre ..
                        " bundle(s) | size: " .. bundleSize ..
                        (isFree and " | FREE" or ""))
                end
            end
        end
    end

    log("Done -- " .. totalInjected .. " bundle(s) added" ..
        (totalSkipped > 0 and " | " .. totalSkipped .. " skipped" or ""))
end

-- ============================================================
-- HOOK REGISTRATION
-- ============================================================

ExecuteWithDelay(3000, function()

    -- Hook on Market_C:Save rather than Generate Movie Bundles For The Day.
    -- A game update changed Generate Movie Bundles For The Day to clear and
    -- rewrite the array on every call instead of appending. Hooking Save
    -- ensures all native bundles are already in the array before we inject.
    -- After injection we call Save again (guarded by isSaving) so our bundles
    -- are written to disk and survive a save reload.
    registerHookOptional(
        "/Game/VideoStore/core/blueprint/Market.Market_C:Save",
        function(self)
            -- isSaving blocks our own re-save from re-triggering this hook
            if isSaving then return end
            if isInjecting or hasInjectedToday then return end
            isInjecting = true

            local market = self:get()

            -- Defer one tick so the native Save hook completes before we read market state.
            ExecuteWithDelay(0, function()
                if not market or not market:IsValid() then
                    log("Market reference invalid after delay -- skipping injection")
                    isInjecting = false
                    return
                end

                safe("injectBundles", function()
                    injectBundles(market)
                end)
                hasInjectedToday = true
                isInjecting = false

                -- Re-save so injected bundles are written to disk.
                -- isSaving prevents this call from re-triggering the hook.
                isSaving = true
                safe("re-save market", function()
                    market["Save"]()
                end)
                isSaving = false
            end)
        end
    )

    -- On save reload: release recursion guards and block re-injection.
    -- The Lua VM resets on reload, so hasInjectedToday starts as false even
    -- if bundles were already written to disk. Setting it true here prevents
    -- Market_C:Save (which may fire during load) from injecting again.
    registerHookOptional(
        "/Game/VideoStore/asset/outside/WeatherSystem.WeatherSystem_C:ReceiveBeginPlay",
        function()
            isInjecting      = false
            isSaving         = false
            hasInjectedToday = true
            debug("Save reloaded - all guards set, re-injection blocked")
        end
    )

    -- On day end: reset all guards so the next day gets a fresh injection pass.
    registerHookOptional(
        "/Game/VideoStore/core/gamemode/Core_Gamemode.Core_Gamemode_C:End of the day",
        function()
            resetGuards()
            debug("Day ended - guards reset")
        end
    )

    log("Hooks active -- bundles will be injected on next new day")
end)

-- ============================================================
if not validateConfig() then
    log("Config has errors -- invalid entries will be skipped")
end
log("Market QoL loaded.")
log("Edit config.lua, then start a new in-game day.")