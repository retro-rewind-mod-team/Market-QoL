-- ============================================================
--  Retro Rewind - Market QoL
--  CONFIGURATION FILE
--
--  Each entry generates additional bundles in the shop.
--
--  genre  = genre name (see supported list below)
--  size   = number of cassettes per bundle (5, 10, 15, ...)
--  count  = number of bundles to generate for this entry
--
--  Supported genres:
--    "Mixed"                              (random, picks from entire catalog)
--    "Action"   "Comedy"  "Drama"    "Fantasy"  "Horror"
--    "Kids"     "Police"  "Adult"    "Romance"  "Sci-Fi"
--    "Western"  "Xmas"
--
--  freeAll = false
--    Set to true to make all generated bundles free of charge.
--
--  ignoreLevelCurve = false
--    Genres unlock gradually as your store levels up.
--    Set to true to unlock all genres immediately -- useful
--    for testing or if you are on a second or third playthrough.
--
--  enableAdult = false
--    Adult bundles are not normally available via the market.
--    Set to true to include them regardless of level curve.
--
--  Debug = false
--    Set to true to enable verbose logging in the UE4SS console.
-- ============================================================

return {
    freeAll          = false,
    ignoreLevelCurve = false,
    enableAdult      = false,
    Debug            = false,

    bundles = {
        { genre = "Mixed",   size = 10, count = 1 },
        { genre = "Action",  size = 15, count = 1 },
        { genre = "Drama",   size = 15, count = 1 },
        { genre = "Horror",  size = 15, count = 1 },
        { genre = "Sci-Fi",  size = 15, count = 1 },
        { genre = "Romance", size = 15, count = 1 },
        { genre = "Police",  size = 15, count = 1 },
        { genre = "Adult",   size = 15, count = 1 },
        { genre = "Western", size = 15, count = 1 },
        { genre = "Xmas",    size = 15, count = 1 },
        { genre = "Comedy",  size = 15, count = 1 },
        { genre = "Fantasy", size = 20, count = 1 },
        { genre = "Kids",    size = 15, count = 1 },
    }
}