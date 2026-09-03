-- config and state
local HttpService = game:GetService("HttpService")

local CONFIG_FOLDER = "Bloxstrike"
local CONFIG_FILE = "Bloxstrike/config.json"

local function ensureDirectory()
    if type(makefolder) == "function" then
        if type(isfolder) == "function" then
            if not isfolder(CONFIG_FOLDER) then
                pcall(makefolder, CONFIG_FOLDER)
            end
        else
            pcall(makefolder, CONFIG_FOLDER)
        end
    end
end

local Config = {
    -- aim
    SILENT_AIM_ENABLED = true,
    KEEP_TARGET_LOCK = true,
    FOV_DEG = 30,
    FALLOFF_REF = 500,
    FOV_CIRCLE_ENABLED = true,
    FOV_CIRCLE_TRANSPARENCY = 0.5,
    FOV_CIRCLE_COLOR = Color3.fromRGB(255, 255, 255),
    BODYPART_TARGET_HL = true,
    BODYPART_HL_COLOR = Color3.fromRGB(255, 255, 0),
    TARGET_PRIORITY = "Auto",

    -- visuals
    ESP_ENABLED = true,
    ESP_HIGHLIGHT_ENABLED = false,
    SKELETON_ENABLED = true,
    VIEWANGLE_ENABLED = true,
    OFFSCREEN_ARROWS = true,
    OFFSCREEN_ARROW_RADIUS = 0.72,
    OFFSCREEN_ARROW_SIZE = 13,
    OFFSCREEN_ARROW_MAX_DIST = 350,
    OFFSCREEN_ARROW_FADE_DIST = 80,
    DISABLE_TEAMMATES = false,
    OCCLUSION_CHECK_ENABLED = true,
    OCCLUDED_COLOR_FACTOR = 0.45,
    SPECTATE_CHECKER_ENABLED = true,

    -- movement
    BHOP_ENABLED = true,
    AUTO_STRAFE_ENABLED = true,

    -- utilities
    ANTI_FLASH_ENABLED = true,
    ANTI_FLASH_TRANSPARENCY = 0.85,

    -- skins
    SKINS_ENABLED = true,
    KNIFE_MODEL = "Butterfly Knife",
    SKIN_MODE = "Special",
    EQUIP_BUTTERFLY_KNIFE = true,
    SELECTED_SKINS = {},

    -- keybinds
    TOGGLE_UI_KEY = Enum.KeyCode.Insert,
    TOGGLE_UI_KEY_ALT = Enum.KeyCode.RightShift,
    TOGGLE_AIM_KEY = nil,
    AIM_BIND_MODE = "Toggle",
    TOGGLE_ESP_KEY = nil,
    UNLOAD_KEY = Enum.KeyCode.K,

    -- ui state
    MENU_OPEN = true,

    -- visual colors
    CT_COLOR = Color3.fromRGB(0, 160, 255),
    CT_OUTLINE = Color3.fromRGB(150, 220, 255),
    T_COLOR = Color3.fromRGB(255, 140, 0),
    T_OUTLINE = Color3.fromRGB(255, 220, 100),
    TARGET_COLOR = Color3.fromRGB(0, 255, 0),
    TARGET_OUTLINE = Color3.fromRGB(0, 200, 0),

    -- theme (cs2 orange)
    UI_THEME = {
        FontColor       = Color3.fromRGB(250, 250, 250),
        MainColor       = Color3.fromRGB(26, 26, 30),
        BackgroundColor = Color3.fromRGB(18, 18, 22),
        AccentColor     = Color3.fromRGB(245, 125, 25),
        OutlineColor    = Color3.fromRGB(52, 54, 62),
        RiskColor       = Color3.fromRGB(255, 60, 60)
    },

    -- runtime target state
    CurrentTargetChar = nil,
    CurrentTargetPart = nil,
    LockedTargetChar = nil,
    WaitingForM1Release = false
}

-- defaults
local DEFAULT_VALUES = {
    SILENT_AIM_ENABLED = true,
    KEEP_TARGET_LOCK = true,
    FOV_DEG = 30,
    FOV_CIRCLE_ENABLED = true,
    FOV_CIRCLE_TRANSPARENCY = 0.5,
    BODYPART_TARGET_HL = true,
    TARGET_PRIORITY = "Auto",
    ESP_ENABLED = true,
    SKELETON_ENABLED = true,
    VIEWANGLE_ENABLED = true,
    OFFSCREEN_ARROWS = true,
    DISABLE_TEAMMATES = false,
    OCCLUSION_CHECK_ENABLED = true,
    SPECTATE_CHECKER_ENABLED = true,
    BHOP_ENABLED = true,
    AUTO_STRAFE_ENABLED = false,
    ANTI_FLASH_ENABLED = true,
    ANTI_FLASH_TRANSPARENCY = 0.85,
    SKINS_ENABLED = true,
    KNIFE_MODEL = "Butterfly Knife",
    SKIN_MODE = "Special",
    EQUIP_BUTTERFLY_KNIFE = true,
    TOGGLE_UI_KEY = "Insert",
    TOGGLE_UI_KEY_ALT = "RightShift",
    TOGGLE_AIM_KEY = "None",
    AIM_BIND_MODE = "Toggle",
    TOGGLE_ESP_KEY = "None",
    UNLOAD_KEY = "K"
}

-- save settings
function Config.save()
    if type(writefile) ~= "function" then return false, "writefile not available" end

    local payload = {
        SILENT_AIM_ENABLED = Config.SILENT_AIM_ENABLED,
        KEEP_TARGET_LOCK = Config.KEEP_TARGET_LOCK,
        FOV_DEG = Config.FOV_DEG or 30,
        FOV_CIRCLE_ENABLED = Config.FOV_CIRCLE_ENABLED,
        FOV_CIRCLE_TRANSPARENCY = Config.FOV_CIRCLE_TRANSPARENCY,
        BODYPART_TARGET_HL = Config.BODYPART_TARGET_HL,
        TARGET_PRIORITY = Config.TARGET_PRIORITY or "Auto",

        ESP_ENABLED = Config.ESP_ENABLED,
        SKELETON_ENABLED = Config.SKELETON_ENABLED,
        VIEWANGLE_ENABLED = Config.VIEWANGLE_ENABLED,
        OFFSCREEN_ARROWS = Config.OFFSCREEN_ARROWS,
        DISABLE_TEAMMATES = Config.DISABLE_TEAMMATES,
        OCCLUSION_CHECK_ENABLED = Config.OCCLUSION_CHECK_ENABLED,
        SPECTATE_CHECKER_ENABLED = Config.SPECTATE_CHECKER_ENABLED,

        BHOP_ENABLED = Config.BHOP_ENABLED,
        AUTO_STRAFE_ENABLED = Config.AUTO_STRAFE_ENABLED,

        ANTI_FLASH_ENABLED = Config.ANTI_FLASH_ENABLED,
        ANTI_FLASH_TRANSPARENCY = Config.ANTI_FLASH_TRANSPARENCY,

        SKINS_ENABLED = Config.SKINS_ENABLED,
        KNIFE_MODEL = Config.KNIFE_MODEL or "Butterfly Knife",
        SKIN_MODE = Config.SKIN_MODE or "Special",
        EQUIP_BUTTERFLY_KNIFE = Config.EQUIP_BUTTERFLY_KNIFE,

        TOGGLE_UI_KEY = Config.TOGGLE_UI_KEY and Config.TOGGLE_UI_KEY.Name or "None",
        TOGGLE_UI_KEY_ALT = Config.TOGGLE_UI_KEY_ALT and Config.TOGGLE_UI_KEY_ALT.Name or "None",
        TOGGLE_AIM_KEY = Config.TOGGLE_AIM_KEY and Config.TOGGLE_AIM_KEY.Name or "None",
        AIM_BIND_MODE = Config.AIM_BIND_MODE or "Toggle",
        TOGGLE_ESP_KEY = Config.TOGGLE_ESP_KEY and Config.TOGGLE_ESP_KEY.Name or "None",
        UNLOAD_KEY = Config.UNLOAD_KEY and Config.UNLOAD_KEY.Name or "None"
    }

    ensureDirectory()
    local ok, encoded = pcall(function() return HttpService:JSONEncode(payload) end)
    if ok and encoded then
        local writeOk, err = pcall(writefile, CONFIG_FILE, encoded)
        if writeOk then
            return true
        end
    end
    return false
end

-- load settings
function Config.load()
    if type(readfile) ~= "function" then return false end

    local exists = false
    if type(isfile) == "function" then
        exists = isfile(CONFIG_FILE)
    else
        local testOk, testData = pcall(readfile, CONFIG_FILE)
        exists = testOk and (testData ~= nil and #testData > 0)
    end

    if not exists then return false end

    local ok, raw = pcall(readfile, CONFIG_FILE)
    if not ok or not raw or #raw == 0 then return false end

    local decodeOk, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not decodeOk or type(data) ~= "table" then return false end

    for key, val in pairs(data) do
        if key == "TOGGLE_UI_KEY" or key == "TOGGLE_UI_KEY_ALT" or key == "TOGGLE_AIM_KEY" or key == "TOGGLE_ESP_KEY" or key == "UNLOAD_KEY" then
            if val == "None" or val == nil or val == "" then
                Config[key] = nil
            else
                local kc = Enum.KeyCode[val]
                Config[key] = kc or nil
            end
        elseif key == "AIM_BIND_MODE" then
            Config.AIM_BIND_MODE = (val == "Hold") and "Hold" or "Toggle"
        elseif key == "KNIFE_MODEL" then
            Config.KNIFE_MODEL = tostring(val)
        elseif key == "SKIN_MODE" then
            local str = tostring(val)
            Config.SKIN_MODE = (str == "Random") and "Random" or "Special"
        elseif key == "FOV_DEG" then
            Config.FOV_DEG = tonumber(val) or 30
        elseif key == "FOV_RADIUS" and not data.FOV_DEG then
            local num = tonumber(val) or 30
            Config.FOV_DEG = (num > 180) and 30 or num
        elseif Config[key] ~= nil and type(Config[key]) == type(val) then
            Config[key] = val
        end
    end

    return true
end

-- reset defaults
function Config.reset()
    for key, val in pairs(DEFAULT_VALUES) do
        if key == "TOGGLE_UI_KEY" or key == "TOGGLE_UI_KEY_ALT" or key == "TOGGLE_AIM_KEY" or key == "UNLOAD_KEY" then
            local kc = Enum.KeyCode[val]
            if kc then Config[key] = kc end
        else
            Config[key] = val
        end
    end
    Config.save()
end

return Config
