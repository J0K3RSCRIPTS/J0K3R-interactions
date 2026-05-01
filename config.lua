-- J0K3R-interactions configuration. Restart the resource after changing values.

Config = {}

-- Raw RedM keyboard hashes. Use these named entries with Config.OpenKey below
-- for readability. Add more keys here if you need a key that is not listed.
Config.Keys = {
    A = 0x7065027D, B = 0x4CC0E2FE, C = 0x9959A6F0, D = 0xB4E465B4,
    E = 0xCEFD9220, F = 0xB2F377E8, G = 0x760A9C6F, H = 0x24978A28,
    I = 0xC1989F95, J = 0xF3830D8E, L = 0x80F28E95, M = 0xE31C6A41,
    N = 0x4BC9DABB, O = 0xF1301666, P = 0xD82E0BD2, Q = 0xDE794E3E,
    R = 0xE30CD707, S = 0xD27782E3, U = 0xD8F73058, V = 0x7F8D09B8,
    W = 0x8FD015D8, X = 0x8CC9CD42, Z = 0x26E9DC00,

    NUM1 = 0xE6F612E4, NUM2 = 0x1CE6D9EB, NUM3 = 0x4F49CC4C,
    NUM4 = 0x8F9F9E58, NUM5 = 0xAB62E997, NUM6 = 0xA1FDE2A6,
    NUM7 = 0xB03A913B, NUM8 = 0x42385422,

    F1 = 0xA8E3F467, F4 = 0x1F6D95E5, F6 = 0x3C0A40F2,

    CTRL      = 0xDB096B85,
    TAB       = 0xB238FE0B,
    SHIFT     = 0x8FFC75D6,
    SPACEBAR  = 0xD9D0E1C0,
    ENTER     = 0xC7B5340A,
    BACKSPACE = 0x156F7119,
    LALT      = 0x8AAA0AD4,
    DEL       = 0x4AF4D473,
    PGUP      = 0x446258B6,
    PGDN      = 0x3C3DD371,

    LEFTBRACKET  = 0x430593AA,
    RIGHTBRACKET = 0xA5BDCD3C,

    MOUSE1 = 0x07CE1E61,
    MOUSE2 = 0xF84FA74F,
    MOUSE3 = 0xCEE12B50,
}

-- Active language. Must match a file in locales/ (e.g. 'de' loads locales/de.lua).
-- To add a new language, copy locales/en.lua and follow the README.
Config.Locale = 'de'

-- Hotkey to open the interaction picker when an interactable is in range.
-- The on-screen uiprompt automatically renders the matching key glyph.
-- Raw key hashes are bound to the physical key and cannot be rebound from the
-- in-game settings menu. To change the key, edit this value.
Config.OpenKey = Config.Keys.U

-- In-menu navigation. These are RedM input actions (not raw key hashes) and
-- follow the player's standard keybind settings, so arrow keys / Enter / Esc
-- work as expected even if the player has remapped them.
Config.Controls = {
    menuUp     = `INPUT_GAME_MENU_UP`,
    menuDown   = `INPUT_GAME_MENU_DOWN`,
    menuAccept = `INPUT_GAME_MENU_ACCEPT`,
    menuCancel = `INPUT_GAME_MENU_CANCEL`,
}

-- Marker drawn on the currently-highlighted interactable while the picker is
-- open. `type` is a marker hash; `color` is RGBA where each channel is 0..255.
Config.Marker = {
    type  = 0x94FDAE17,
    color = { r = 254, g = 127, b = 156, a = 128 },
}

-- Visual theme of the picker menu. These values are applied to CSS custom
-- properties at runtime, so you never need to edit the CSS file directly.
Config.Theme = {
    position           = 'right',                       -- 'left', 'right' or 'center'
    width              = '18vw',                        -- any valid CSS length
    fontFamily         = 'J0K3R Font',                  -- must be loaded by the NUI page
    fontSize           = '1vw',
    titleFontSize      = '1.25vw',
    backgroundColor    = 'rgba(15, 15, 15, 0.78)',      -- picker container background
    titleBackground    = 'rgba(0, 0, 0, 0.85)',         -- title bar background
    textColor          = '#f5f5f5',
    selectedBackground = '#f5f5f5',
    selectedTextColor  = '#111111',
    accentColor        = '#c9a96e',                     -- selection border + title underline
    borderRadius       = '4px',
    itemPadding        = '0.55vh 0.8vw',                -- vertical horizontal
    showCategoryDot    = true,                          -- small colored dot next to each entry
    maxItems           = 50,                            -- list height before scrolling kicks in

    -- Logo settings. Replace ui/logo.png with your own server logo to brand
    -- the menu, or change `logoUrl` to point to a different file in ui/.
    showLogo           = true,
    logoUrl            = 'logo.png',
    logoSize           = '8vw',                         -- e.g. '6vw' (smaller), '10vw' (larger)
    showTitle          = true,                          -- text title below the logo
}

-- How often (in milliseconds) the script scans the world for nearby
-- interactables. Lower values feel more responsive but use more CPU at idle.
-- 750 ms is a good balance for most servers.
Config.NearbyCheckInterval = 750

-- Effect callbacks referenced by entries in shared/interactions.lua.
-- `clean` runs after the player finishes a bath and washes off dirt and blood.
-- Add your own callbacks here and reference them by key from interaction entries.
Config.Effects = {
    clean = function()
        local ped = PlayerPedId()
        ClearPedEnvDirt(ped)
        ClearPedDamageDecalByZone(ped, 10, 'ALL')
        ClearPedBloodDamage(ped)
    end,
}
