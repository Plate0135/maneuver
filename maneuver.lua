addon.name    = 'maneuver'
addon.author  = 'Plate'
addon.version = '1.0.0'
addon.desc    = 'Puppetmaster maneuver tracker for HorizonXI'

require('common')

local imgui = require('imgui')
local chat = require('chat')
local settings = require('settings')
local d3d   = require('d3d8')
local ffi   = require('ffi')
local C     = ffi.C
local d3d8dev = d3d.get_device()

------------------------------------------------------------
-- SETTINGS
------------------------------------------------------------

local MATCH_WINDOW = 6
local MANEUVER_DURATION = 60
local POST_EXPIRE_HOLD = 0
local PUP_JOB_ID = 18

-- Default window size. ImGui remembers the user's dragged position/size.
local DEFAULT_W = 648
local DEFAULT_H = 265
local MIN_W = 470
local MIN_H = 135

-- Public-release settings. Ashita's settings library persists these
-- automatically and handles per-character setting changes.
local default_settings = T{
    visible        = T{ true, },
    auto_hide      = T{ true, },
    show_timer     = T{ true, },
    show_headers   = T{ true, },
    row_background = T{ true, },
    row_opacity    = T{ 0.94, },
    pup_only       = T{ true, },
}

local config = settings.load(default_settings)
local debug_visible = false
local reset_window_next_frame = false

settings.register('settings', 'maneuver_settings_update', function(s)
    if s ~= nil then
        config = s
    end
    settings.save()
end)

------------------------------------------------------------
-- VALUES
------------------------------------------------------------

local values = {
    Fire = 0,
    Ice = 0,
    Wind = 0,
    Earth = 0,
    Thunder = 0,
    Water = 0,
    Light = 0,
    Dark = 0
}

local display_order = {
    'Fire',
    'Ice',
    'Wind',
    'Earth',
    'Thunder',
    'Water',
    'Light',
    'Dark'
}

------------------------------------------------------------
-- CONFIRMED HORIZONXI MANEUVER IDS
------------------------------------------------------------

local maneuver_ids = {
    [141] = 'Fire',
    [142] = 'Ice',
    [143] = 'Wind',
    [144] = 'Earth',
    [145] = 'Thunder',
    [146] = 'Water',
    [147] = 'Light',
    [148] = 'Dark'
}

------------------------------------------------------------
-- MATCH STATE
------------------------------------------------------------

local pending_element = ''
local pending_time = 0

local recent_logs = {
    Fire = nil,
    Ice = nil,
    Wind = nil,
    Earth = nil,
    Thunder = nil,
    Water = nil,
    Light = nil,
    Dark = nil
}

------------------------------------------------------------
-- ACTIVE MANEUVER HUD STATE
------------------------------------------------------------

-- Each local maneuver packet adds one timed stack here. HorizonXI
-- uses the classic 60-second maneuver duration and a maximum of
-- three total active maneuvers. A fourth maneuver replaces the
-- active maneuver with the least time remaining.
local active_maneuvers = {}

local linger_until = {
    Fire = 0,
    Ice = 0,
    Wind = 0,
    Earth = 0,
    Thunder = 0,
    Water = 0,
    Light = 0,
    Dark = 0
}

------------------------------------------------------------
-- DEBUG STATE
------------------------------------------------------------

local debug_action = 'None'
local debug_packet = 'None'
local debug_message = 'None'
local debug_filter = 'None'
local debug_match = 'None'

------------------------------------------------------------
-- TEXTURE LOADING
------------------------------------------------------------

local textures = {
    panel = nil,
    Fire = nil,
    Ice = nil,
    Wind = nil,
    Earth = nil,
    Thunder = nil,
    Water = nil,
    Light = nil,
    Dark = nil
}

local function LoadTexture(filename)

    local path = addon.path .. '/assets/' .. filename

    if not ashita.fs.exists(path) then
        return nil
    end

    local ptr = ffi.new('IDirect3DTexture8*[1]')

    if C.D3DXCreateTextureFromFileA(d3d8dev, path, ptr) ~= C.S_OK then
        return nil
    end

    return d3d.gc_safe_release(
        ffi.cast('IDirect3DTexture8*', ptr[0])
    )
end

local function TextureId(texture)

    if texture == nil then
        return 0
    end

    return tonumber(
        ffi.cast('uint32_t', texture)
    )
end

local function LoadAssets()

    textures.panel   = LoadTexture('panel.png')

    textures.Fire    = LoadTexture('fire.png')
    textures.Ice     = LoadTexture('ice.png')
    textures.Wind    = LoadTexture('wind.png')
    textures.Earth   = LoadTexture('earth.png')
    textures.Thunder = LoadTexture('thunder.png')
    textures.Water   = LoadTexture('water.png')
    textures.Light   = LoadTexture('light.png')
    textures.Dark    = LoadTexture('dark.png')
end

LoadAssets()

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------

local function Now()
    return os.time()
end

local function GetDisplayPercent(value)

    local result = (value / 30.0) * 100.0

    if result < 0 then
        result = 0
    end

    if result > 100 then
        result = 100
    end

    return result
end

local function GetRiskColor(display)

    if display >= 80 then
        return { 0.96, 0.30, 0.34, 1.00 }
    elseif display >= 60 then
        return { 1.00, 0.55, 0.08, 1.00 }
    elseif display >= 40 then
        return { 1.00, 0.80, 0.05, 1.00 }
    else
        return { 0.58, 0.84, 0.28, 1.00 }
    end
end

local function GetMyServerId()

    local memory = AshitaCore:GetMemoryManager()

    if memory == nil then
        return 0
    end

    local party = memory:GetParty()

    if party == nil then
        return 0
    end

    local id = party:GetMemberServerId(0)

    if id == nil then
        return 0
    end

    return id
end

local function IsPupMain()
    local memory = AshitaCore:GetMemoryManager()
    if memory == nil then return false end
    local player = memory:GetPlayer()
    if player == nil then return false end
    return player:GetMainJob() == PUP_JOB_ID
end

local function PrintMessage(message)
    print(chat.header('Maneuver'):append(chat.message(message)))
end

local function PrintHelp()
    PrintMessage('Commands:')
    PrintMessage('/maneuver - Toggle the HUD.')
    PrintMessage('/maneuver show | hide - Show or hide the HUD.')
    PrintMessage('/maneuver clear - Clear tracked maneuver data.')
    PrintMessage('/maneuver reset - Reset settings and HUD position/size.')
    PrintMessage('/maneuver save | reload - Save or reload settings.')
    PrintMessage('/maneuver timer on|off - Show or hide maneuver timers.')
    PrintMessage('/maneuver autohide on|off - Hide when no maneuvers are active.')
    PrintMessage('/maneuver headers on|off - Show or hide column headers.')
    PrintMessage('/maneuver background on|off - Show or hide solid row backgrounds.')
    PrintMessage('/maneuver opacity 0-100 - Set row background opacity.')
    PrintMessage('/maneuver puponly on|off - Restrict the HUD to PUP main job.')
    PrintMessage('/maneuver debug - Toggle troubleshooting details.')
end

local function ParseOnOff(value)
    if value == nil then return nil end
    value = value:lower()
    if value == 'on' or value == 'true' or value == '1' or value == 'yes' then return true end
    if value == 'off' or value == 'false' or value == '0' or value == 'no' then return false end
    return nil
end

------------------------------------------------------------
-- ACTIVE MANEUVER TRACKING
------------------------------------------------------------

local function CountActiveElement(element)
    local count = 0
    for _, entry in ipairs(active_maneuvers) do
        if entry.element == element then
            count = count + 1
        end
    end
    return count
end

local function StartLingerIfInactive(element, now)
    if CountActiveElement(element) == 0 then
        linger_until[element] = now + POST_EXPIRE_HOLD
    end
end

local function CleanupManeuvers()
    local now = Now()
    local expired_elements = {}

    for i = #active_maneuvers, 1, -1 do
        local entry = active_maneuvers[i]
        if entry.expires <= now then
            expired_elements[entry.element] = true
            table.remove(active_maneuvers, i)
        end
    end

    for element, _ in pairs(expired_elements) do
        StartLingerIfInactive(element, now)
    end

    for _, element in ipairs(display_order) do
        if linger_until[element] ~= 0 and linger_until[element] <= now then
            linger_until[element] = 0
        end
    end
end

local function RegisterManeuver(element)
    local now = Now()

    CleanupManeuvers()

    -- A maximum of three maneuvers can be active. The next use
    -- replaces the maneuver with the least remaining duration.
    if #active_maneuvers >= 3 then
        local oldest_index = 1
        local oldest_expire = active_maneuvers[1].expires

        for i = 2, #active_maneuvers do
            if active_maneuvers[i].expires < oldest_expire then
                oldest_index = i
                oldest_expire = active_maneuvers[i].expires
            end
        end

        local removed = table.remove(active_maneuvers, oldest_index)
        if removed ~= nil then
            StartLingerIfInactive(removed.element, now)
        end
    end

    active_maneuvers[#active_maneuvers + 1] = {
        element = element,
        expires = now + MANEUVER_DURATION
    }

    linger_until[element] = 0
end

local function GetManeuverDisplayState(element)
    local now = Now()
    local count = 0
    local next_expire = nil

    for _, entry in ipairs(active_maneuvers) do
        if entry.element == element then
            count = count + 1
            if next_expire == nil or entry.expires < next_expire then
                next_expire = entry.expires
            end
        end
    end

    if count > 0 then
        local remaining = math.ceil(next_expire - now)
        if remaining < 0 then remaining = 0 end
        return true, count, remaining
    end

    if linger_until[element] ~= nil and linger_until[element] > now then
        return true, 0, nil
    end

    return false, 0, nil
end

local function GetVisibleManeuvers()
    CleanupManeuvers()

    local rows = {}
    for _, element in ipairs(display_order) do
        local show, stacks, remaining = GetManeuverDisplayState(element)
        if show then
            rows[#rows + 1] = {
                element = element,
                stacks = stacks,
                remaining = remaining
            }
        end
    end
    return rows
end

local function FormatTime(seconds)
    if seconds == nil then
        return ''
    end

    if seconds < 0 then seconds = 0 end
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format('%d:%02d', minutes, secs)
end

------------------------------------------------------------
-- MATCHING
------------------------------------------------------------

local function AcceptValue(element, value, direction)

    if element == nil or value == nil then
        return
    end

    if value < 0 then value = 0 end
    if value > 30 then value = 30 end

    values[element] = value

    debug_filter =
        string.format(
            'ACCEPTED %s %d%%',
            element,
            value
        )

    debug_match = direction

    pending_element = ''
    pending_time = 0
    recent_logs[element] = nil
end

local function CleanupOldState()

    local now = Now()

    if pending_element ~= '' then

        if (now - pending_time) > MATCH_WINDOW then

            debug_filter =
                'Pending ' ..
                pending_element ..
                ' expired.'

            pending_element = ''
            pending_time = 0
        end
    end

    for _, element in ipairs(display_order) do

        local entry = recent_logs[element]

        if entry ~= nil then

            if (now - entry.time) > MATCH_WINDOW then
                recent_logs[element] = nil
            end
        end
    end
end

------------------------------------------------------------
-- MANEUVER TEXT PARSER
------------------------------------------------------------

local function GetManeuverData(message)

    if message == nil then
        return nil, nil
    end

    local element, value =
        message:match(
            '([A-Za-z]+)%s+Maneuver.-(%d+)'
        )

    if element == nil or value == nil then
        return nil, nil
    end

    element =
        element:sub(1, 1):upper() ..
        element:sub(2):lower()

    if values[element] == nil then
        return nil, nil
    end

    value = tonumber(value)

    if value == nil then
        return nil, nil
    end

    return element, value
end

local function ParseOverload(message)

    if message == nil then
        return false
    end

    if message:lower():find(
        'maneuver',
        1,
        true
    ) == nil then
        return false
    end

    debug_message = message

    CleanupOldState()

    local element, value =
        GetManeuverData(message)

    if element == nil or value == nil then

        debug_filter =
            'Maneuver line could not be parsed.'

        return false
    end

    --------------------------------------------------------
    -- PACKET FIRST
    --------------------------------------------------------

    if pending_element ~= '' then

        if element == pending_element then

            AcceptValue(
                element,
                value,
                'PACKET FIRST -> TEXT MATCH'
            )

            return true
        end

        recent_logs[element] = {
            value = value,
            time = Now()
        }

        return false
    end

    --------------------------------------------------------
    -- TEXT FIRST
    --------------------------------------------------------

    recent_logs[element] = {
        value = value,
        time = Now()
    }

    debug_filter =
        string.format(
            'CACHED %s %d%%',
            element,
            value
        )

    return false
end

------------------------------------------------------------
-- CONFIRMED LOCAL ACTION PACKET
------------------------------------------------------------

ashita.events.register(
    'packet_in',
    'maneuver_packet_in',
    function(e)

        local ok, err =
            pcall(function()

                if e.id ~= 0x028 then
                    return
                end

                if config.pup_only[1] and not IsPupMain() then
                    return
                end

                local my_id =
                    GetMyServerId()

                if my_id == 0 then
                    return
                end

                local actor_id =
                    struct.unpack(
                        'I',
                        e.data,
                        0x05 + 1
                    )

                if actor_id == nil then
                    return
                end

                if actor_id ~= my_id then
                    return
                end

                local category =
                    ashita.bits.unpack_be(
                        e.data_raw,
                        0,
                        82,
                        4
                    )

                local ability_id =
                    ashita.bits.unpack_be(
                        e.data_raw,
                        0,
                        86,
                        17
                    )

                debug_packet =
                    string.format(
                        'Actor=%u Category=%d ID=%d',
                        actor_id,
                        category,
                        ability_id
                    )

                if category ~= 6 then
                    return
                end

                local element =
                    maneuver_ids[ability_id]

                if element == nil then
                    return
                end

                debug_action =
                    string.format(
                        'MY %s Maneuver detected. ID=%d',
                        element,
                        ability_id
                    )

                -- HUD timing is derived from the same confirmed local
                -- action packet used by the overload ownership filter.
                RegisterManeuver(element)

                CleanupOldState()

                local cached =
                    recent_logs[element]

                if cached ~= nil then

                    local age =
                        Now() - cached.time

                    if age <= MATCH_WINDOW then

                        AcceptValue(
                            element,
                            cached.value,
                            'TEXT FIRST -> PACKET MATCH'
                        )

                        return
                    end
                end

                pending_element = element
                pending_time = Now()

                debug_filter =
                    'Waiting for matching ' ..
                    element ..
                    ' log.'

                debug_match =
                    'Packet first'
            end)

        if not ok then

            debug_action =
                'Packet error: ' ..
                tostring(err)
        end
    end
)

------------------------------------------------------------
-- TEXT EVENT
------------------------------------------------------------

ashita.events.register(
    'text_in',
    'maneuver_text_in',
    function(e)

        if e.message_modified ~= nil then

            local accepted =
                ParseOverload(
                    e.message_modified
                )

            if accepted then
                return
            end
        end

        if e.message ~= nil then
            ParseOverload(e.message)
        end
    end
)

------------------------------------------------------------
-- COMMANDS
------------------------------------------------------------

local function ClearTrackedData()
    for _, element in ipairs(display_order) do
        values[element] = 0
        recent_logs[element] = nil
        linger_until[element] = 0
    end

    pending_element = ''
    pending_time = 0
    active_maneuvers = {}

    debug_action = 'None'
    debug_packet = 'None'
    debug_message = 'None'
    debug_filter = 'None'
    debug_match = 'None'
end

ashita.events.register(
    'command',
    'maneuver_command',
    function(e)
        local args = e.command:args()
        if #args == 0 then return end

        local command = args[1]:lower()
        if command ~= '/maneuver'
        and command ~= '/overload'
        and command ~= '/pupoverload' then
            return
        end

        e.blocked = true

        if #args == 1 then
            config.visible[1] = not config.visible[1]
            settings.save()
            return
        end

        local sub = args[2]:lower()

        if sub == 'help' then
            PrintHelp()

        elseif sub == 'show' then
            config.visible[1] = true
            settings.save()

        elseif sub == 'hide' then
            config.visible[1] = false
            settings.save()

        elseif sub == 'debug' then
            debug_visible = not debug_visible
            PrintMessage('Debug ' .. (debug_visible and 'enabled.' or 'disabled.'))

        elseif sub == 'clear' then
            ClearTrackedData()
            PrintMessage('Tracked maneuver data cleared.')

        elseif sub == 'save' then
            settings.save()
            PrintMessage('Settings saved.')

        elseif sub == 'reload' then
            settings.reload()
            PrintMessage('Settings reloaded.')

        elseif sub == 'reset' then
            settings.reset()
            ClearTrackedData()
            reset_window_next_frame = true
            PrintMessage('Settings and HUD position/size reset.')

        elseif sub == 'timer'
        or sub == 'autohide'
        or sub == 'headers'
        or sub == 'background'
        or sub == 'puponly' then
            local value = ParseOnOff(args[3])
            if value == nil then
                PrintMessage('Usage: /maneuver ' .. sub .. ' on|off')
                return
            end

            if sub == 'timer' then config.show_timer[1] = value end
            if sub == 'autohide' then config.auto_hide[1] = value end
            if sub == 'headers' then config.show_headers[1] = value end
            if sub == 'background' then config.row_background[1] = value end
            if sub == 'puponly' then config.pup_only[1] = value end

            settings.save()
            PrintMessage(sub .. ' ' .. (value and 'enabled.' or 'disabled.'))

        elseif sub == 'opacity' then
            local percent = tonumber(args[3])
            if percent == nil then
                PrintMessage('Usage: /maneuver opacity 0-100')
                return
            end
            if percent < 0 then percent = 0 end
            if percent > 100 then percent = 100 end
            config.row_opacity[1] = percent / 100.0
            settings.save()
            PrintMessage(string.format('Row background opacity set to %.0f%%.', percent))

        elseif sub == 'reloadassets' then
            LoadAssets()
            PrintMessage('Assets reloaded.')

        else
            PrintHelp()
        end
    end
)

------------------------------------------------------------
-- UI HELPERS
------------------------------------------------------------

-- The original mockup was authored at 900px wide. All horizontal
-- positions scale from the current window width. Vertical positions
-- are built from a compact header + only the maneuver rows in use.
local function GetUIScale()
    local width = imgui.GetWindowWidth()
    if width == nil or width <= 0 then
        return 0.72
    end
    return width / 900.0
end

local function PutTextScaled(x, y, text, color, scale)
    imgui.SetCursorPos({ x * scale, y * scale })
    if color ~= nil then
        imgui.TextColored(color, text)
    else
        imgui.Text(text)
    end
end

local function PutTextBoldScaled(x, y, text, color, scale)
    PutTextScaled(x, y, text, color, scale)
    PutTextScaled(x + 1.25, y, text, color, scale)
end

local function PutImageScaled(texture, x, y, w, h, scale)
    if texture == nil then
        return
    end

    imgui.SetCursorPos({ x * scale, y * scale })
    imgui.Image(
        TextureId(texture),
        { w * scale, h * scale },
        { 0, 0 },
        { 1, 1 },
        { 1, 1, 1, 1 },
        { 0, 0, 0, 0 }
    )
end

local function DrawRowBackground(row, scale)
    if not config.row_background[1] then
        return
    end

    local y = 56 + (row * 48)

    -- Solid slate background behind the entire visible maneuver line.
    -- Hover/active colors match so the strip never changes appearance.
    local bg = { 0.17, 0.20, 0.27, config.row_opacity[1] }

    imgui.SetCursorPos({ 20 * scale, y * scale })
    imgui.PushStyleVar(ImGuiStyleVar_FrameRounding, 2 * scale)
    imgui.PushStyleColor(ImGuiCol_Button, bg)
    imgui.PushStyleColor(ImGuiCol_ButtonHovered, bg)
    imgui.PushStyleColor(ImGuiCol_ButtonActive, bg)

    imgui.Button(
        '##maneuver_row_bg_' .. tostring(row),
        { 860 * scale, 42 * scale }
    )

    imgui.PopStyleColor(3)
    imgui.PopStyleVar()
end

local function DrawGauge(row_info, row, scale)
    local element = row_info.element
    local stacks = row_info.stacks
    local remaining = row_info.remaining
    local actual = values[element]
    local display = GetDisplayPercent(actual)
    local fraction = display / 100.0
    local color = GetRiskColor(display)
    local y = 60 + (row * 48)

    DrawRowBackground(row, scale)

    PutImageScaled(textures[element], 37, y, 38, 38, scale)

    local label = element
    if stacks > 0 then
        label = string.format('%s x%d', element, stacks)
    end

    PutTextBoldScaled(
        87,
        y + 10,
        label,
        { 0.96, 0.96, 0.94, 1.00 },
        scale
    )

    PutTextBoldScaled(
        218,
        y + 10,
        string.format('%d%%', actual),
        { 0.58, 0.88, 0.28, 1.00 },
        scale
    )

    imgui.SetCursorPos({
        292 * scale,
        (y + 3) * scale
    })

    imgui.PushStyleVar(ImGuiStyleVar_FrameRounding, 12 * scale)
    imgui.PushStyleColor(ImGuiCol_FrameBg, { 0.015, 0.055, 0.095, 1.00 })
    imgui.PushStyleColor(ImGuiCol_PlotHistogram, color)

    imgui.ProgressBar(
        fraction,
        { 360 * scale, 29 * scale },
        ''
    )

    imgui.PopStyleColor(2)
    imgui.PopStyleVar()

    PutTextBoldScaled(
        682,
        y + 10,
        string.format('%.0f%%', display),
        { 0.96, 0.45, 0.40, 1.00 },
        scale
    )

    -- Timer is shown only while at least one stack is actually active.
    -- The whole row disappears as soon as the final stack expires.
    if config.show_timer[1] and remaining ~= nil then
        PutTextBoldScaled(
            786,
            y + 10,
            FormatTime(remaining),
            { 0.92, 0.92, 0.90, 1.00 },
            scale
        )
    end
end

ashita.events.register('unload', 'maneuver_unload', function()
    settings.save()
end)

------------------------------------------------------------
-- RENDER
------------------------------------------------------------

ashita.events.register(
    'd3d_present',
    'maneuver_render',
    function()

        if not config.visible[1] then
            return
        end

        if config.pup_only[1] and not IsPupMain() then
            return
        end

        CleanupOldState()
        local rows = GetVisibleManeuvers()

        -- Completely hide the HUD when there is no active/recent
        -- maneuver information to display. Debug mode can still force
        -- the window open for troubleshooting.
        if config.auto_hide[1] and #rows == 0 and not debug_visible then
            return
        end

        -- ImGui remembers each player's normal position/size. Reset can
        -- force a safe default location and dimensions for one frame.
        if reset_window_next_frame then
            imgui.SetNextWindowPos({ 100, 100 }, ImGuiCond_Always)
            imgui.SetNextWindowSize({ DEFAULT_W, DEFAULT_H }, ImGuiCond_Always)
            reset_window_next_frame = false
        else
            imgui.SetNextWindowSize({ DEFAULT_W, DEFAULT_H }, ImGuiCond_FirstUseEver)
        end

        imgui.SetNextWindowSizeConstraints(
            { MIN_W, MIN_H },
            { 1400, 1000 }
        )

        local flags =
            bit.bor(
                ImGuiWindowFlags_NoTitleBar,
                ImGuiWindowFlags_NoScrollbar,
                ImGuiWindowFlags_NoScrollWithMouse,
                ImGuiWindowFlags_NoCollapse
            )

        imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, { 0, 0 })
        imgui.PushStyleVar(ImGuiStyleVar_WindowRounding, 0)
        imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0)
        imgui.PushStyleColor(ImGuiCol_WindowBg, { 0.00, 0.00, 0.00, 0.00 })

        if imgui.Begin(
            'Maneuver##maneuver',
            true,
            flags
        ) then

            local scale = GetUIScale()
            local window_w = imgui.GetWindowWidth()
            local window_h = imgui.GetWindowHeight()

            ------------------------------------------------
            -- TRANSPARENT WINDOW BACKGROUND
            -- Each active maneuver row draws its own solid background strip.
            ------------------------------------------------

            ------------------------------------------------
            -- COMPACT TOP EDGE (title, version, emblem, and close button removed)
            ------------------------------------------------

            ------------------------------------------------
            -- COLUMN HEADERS
            ------------------------------------------------
            if config.show_headers[1] then
                PutTextScaled(38, 24, 'Element', { 0.96, 0.96, 0.94, 1.00 }, scale)
                PutTextScaled(210, 24, 'Actual', { 0.96, 0.96, 0.94, 1.00 }, scale)
                PutTextScaled(405, 24, 'Overload Gauge', { 0.96, 0.96, 0.94, 1.00 }, scale)
                if config.show_timer[1] then
                    PutTextScaled(782, 24, 'Time', { 0.96, 0.96, 0.94, 1.00 }, scale)
                end
            end

            ------------------------------------------------
            -- ONLY CURRENTLY ACTIVE MANEUVERS
            ------------------------------------------------
            for row, row_info in ipairs(rows) do
                DrawGauge(row_info, row - 1, scale)
            end

            if #rows == 0 and not config.auto_hide[1] then
                PutTextBoldScaled(300, 70, 'No active maneuvers', { 0.82, 0.84, 0.88, 1.00 }, scale)
            end

            ------------------------------------------------
            -- OPTIONAL DEBUG
            ------------------------------------------------
            if debug_visible then
                local debug_y = (window_h / scale) - 60
                if debug_y < (110 + (#rows * 48)) then
                    debug_y = 110 + (#rows * 48)
                end

                imgui.SetCursorPos({ 18 * scale, debug_y * scale })
                imgui.TextWrapped(
                    debug_action ..
                    '\n' ..
                    debug_packet ..
                    '\n' ..
                    debug_filter ..
                    '\n' ..
                    debug_match ..
                    '\n' ..
                    debug_message
                )
            end
        end

        imgui.End()
        imgui.PopStyleColor()
        imgui.PopStyleVar(3)
    end
)
