-- ui manager
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local UIManager = {
    Initialized = false,
    Library = nil,
    Window = nil,
    Connections = {}
}

function UIManager.init(Config, Library, SkinChanger, unloadCallback)
    if UIManager.Initialized then return end
    UIManager.Initialized = true
    UIManager.Library = Library

    -- apply theme
    if Config.UI_THEME then
        for prop, val in pairs(Config.UI_THEME) do
            if Library[prop] ~= nil then
                Library[prop] = val
            end
        end
    end

    -- auto save debounce
    local saveDebounce = nil
    local function queueAutoSave()
        if saveDebounce then
            task.cancel(saveDebounce)
        end
        saveDebounce = task.delay(0.35, function()
            Config.save()
            saveDebounce = nil
        end)
    end

    local function updateSetting(key, newVal)
        if Config[key] ~= newVal then
            Config[key] = newVal
            queueAutoSave()
        end
    end

    -- window
    local Window = Library:CreateWindow({
        Title = "Seeto.SolutionZ / Bloxstrike / v2.1",
        Center = true,
        AutoShow = (Config.MENU_OPEN ~= false),
        TabPadding = 8,
        MenuFadeTime = 0.2
    })
    UIManager.Window = Window

    local Tabs = {
        Aim = Window:AddTab("Aim"),
        Visuals = Window:AddTab("Visuals"),
        Movement = Window:AddTab("Movement"),
        Skins = Window:AddTab("Skins"),
        Settings = Window:AddTab("Settings")
    }

    -- aim tab
    local AimMain = Tabs.Aim:AddLeftGroupbox("Silent Aim and Targeting")

    AimMain:AddToggle("SilentAim", {
        Text = "Silent aim",
        Default = (Config.SILENT_AIM_ENABLED ~= false),
        Tooltip = "Redirects bullets directly to optimal enemy hitbox within FOV cone",
        Callback = function(Value)
            updateSetting("SILENT_AIM_ENABLED", Value)
        end
    })

    AimMain:AddToggle("KeepLock", {
        Text = "Keep target lock",
        Default = (Config.KEEP_TARGET_LOCK ~= false),
        Tooltip = "Maintains lock on current target while firing",
        Callback = function(Value)
            updateSetting("KEEP_TARGET_LOCK", Value)
        end
    })

    AimMain:AddDropdown("TargetPriority", {
        Values = { "Auto", "Head", "Torso", "Random" },
        Default = Config.TARGET_PRIORITY or "Auto",
        Multi = false,
        Text = "Target priority",
        Tooltip = "Auto: Lethal damage calculation and occlusion scanner\nHead: Strictly headshots\nTorso: Upper and lower torso\nRandom: Random visible hitbox",
        Callback = function(Value)
            updateSetting("TARGET_PRIORITY", Value)
        end
    })

    -- visuals tab
    local EspMain = Tabs.Visuals:AddLeftGroupbox("ESP Elements")
    local VisualSettings = Tabs.Visuals:AddRightGroupbox("FOV & Utilities")

    EspMain:AddToggle("EspMaster", {
        Text = "Enable ESP",
        Default = (Config.ESP_ENABLED ~= false),
        Tooltip = "Master switch to enable or disable all visual ESP features",
        Callback = function(Value)
            updateSetting("ESP_ENABLED", Value)
        end
    })

    EspMain:AddToggle("SkeletonEsp", {
        Text = "Skeleton ESP",
        Default = (Config.SKELETON_ENABLED ~= false),
        Tooltip = "Renders 3D bone skeletons and health bars on characters",
        Callback = function(Value)
            updateSetting("SKELETON_ENABLED", Value)
        end
    })

    EspMain:AddToggle("ViewAngle", {
        Text = "View angle",
        Default = (Config.VIEWANGLE_ENABLED ~= false),
        Tooltip = "Renders head look direction indicator ray",
        Callback = function(Value)
            updateSetting("VIEWANGLE_ENABLED", Value)
        end
    })

    EspMain:AddToggle("OffscreenArrows", {
        Text = "Offscreen arrows",
        Default = (Config.OFFSCREEN_ARROWS ~= false),
        Tooltip = "Directional triangle pointers for out-of-view enemies with distance fade",
        Callback = function(Value)
            updateSetting("OFFSCREEN_ARROWS", Value)
        end
    })

    EspMain:AddToggle("TargetPartHl", {
        Text = "Visualize target part",
        Default = (Config.BODYPART_TARGET_HL ~= false),
        Tooltip = "Highlights active targeted limb with yellow outline",
        Callback = function(Value)
            updateSetting("BODYPART_TARGET_HL", Value)
        end
    })

    EspMain:AddToggle("DisableTeammates", {
        Text = "Disable teammates",
        Default = (Config.DISABLE_TEAMMATES == true),
        Tooltip = "Hides ESP and offscreen arrows for friendly teammates",
        Callback = function(Value)
            updateSetting("DISABLE_TEAMMATES", Value)
        end
    })

    EspMain:AddToggle("OcclusionCheck", {
        Text = "Occlusion check",
        Default = (Config.OCCLUSION_CHECK_ENABLED ~= false),
        Tooltip = "Dims skeleton bone color when character is behind walls",
        Callback = function(Value)
            updateSetting("OCCLUSION_CHECK_ENABLED", Value)
        end
    })

    EspMain:AddToggle("SpectatorChecker", {
        Text = "Spectator counter",
        Default = (Config.SPECTATE_CHECKER_ENABLED ~= false),
        Tooltip = "HUD widget displaying players spectating your camera",
        Callback = function(Value)
            updateSetting("SPECTATE_CHECKER_ENABLED", Value)
        end
    })

    VisualSettings:AddToggle("ShowFov", {
        Text = "Show FOV circle",
        Default = (Config.FOV_CIRCLE_ENABLED ~= false),
        Tooltip = "Renders screen-center FOV boundary",
        Callback = function(Value)
            updateSetting("FOV_CIRCLE_ENABLED", Value)
        end
    })

    VisualSettings:AddSlider("FovAngle", {
        Text = "FOV angle",
        Default = Config.FOV_DEG or 30,
        Min = 1,
        Max = 180,
        Rounding = 0,
        Compact = false,
        Suffix = "°",
        Callback = function(Value)
            updateSetting("FOV_DEG", Value)
        end
    })

    VisualSettings:AddSlider("FovOpacity", {
        Text = "FOV opacity",
        Default = math.floor((Config.FOV_CIRCLE_TRANSPARENCY or 0.5) * 100),
        Min = 5,
        Max = 100,
        Rounding = 0,
        Compact = false,
        Suffix = "%",
        Callback = function(Value)
            updateSetting("FOV_CIRCLE_TRANSPARENCY", Value / 100)
        end
    })

    VisualSettings:AddToggle("AntiFlash", {
        Text = "Anti-flash",
        Default = (Config.ANTI_FLASH_ENABLED ~= false),
        Tooltip = "Neutralizes blinding white screen flashes and blindness effects",
        Callback = function(Value)
            updateSetting("ANTI_FLASH_ENABLED", Value)
        end
    })

    VisualSettings:AddSlider("FlashOpacity", {
        Text = "Flash opacity",
        Default = math.floor((Config.ANTI_FLASH_TRANSPARENCY or 0.85) * 100),
        Min = 5,
        Max = 100,
        Rounding = 0,
        Compact = false,
        Suffix = "%",
        Callback = function(Value)
            updateSetting("ANTI_FLASH_TRANSPARENCY", Value / 100)
        end
    })

    -- movement tab
    local MoveMain = Tabs.Movement:AddLeftGroupbox("Movement Physics")

    MoveMain:AddToggle("Bhop", {
        Text = "Bunny hop",
        Default = (Config.BHOP_ENABLED ~= false),
        Tooltip = "Automatic jump execution via native MovementV2 physics",
        Callback = function(Value)
            updateSetting("BHOP_ENABLED", Value)
        end
    })

    -- skins tab
    local SkinsMain = Tabs.Skins:AddLeftGroupbox("Knife & Skin Settings")
    local SkinsActions = Tabs.Skins:AddRightGroupbox("Actions & Presets")

    SkinsMain:AddToggle("CustomPresets", {
        Text = "Enable skins",
        Default = (Config.SKINS_ENABLED ~= false),
        Tooltip = "Enables custom viewmodel skins and knife model overrides",
        Callback = function(Value)
            updateSetting("SKINS_ENABLED", Value)
            Config.CUSTOM_PRESETS = Value
            if SkinChanger and SkinChanger.refreshActiveViewmodels then
                SkinChanger.refreshActiveViewmodels(Config)
            end
        end
    })

    SkinsMain:AddDropdown("KnifeModel", {
        Values = { "Default", "Butterfly Knife", "Karambit", "M9 Bayonet", "Skeleton Knife", "Stiletto Knife", "Flip Knife", "Gut Knife", "LightSaber" },
        Default = Config.KNIFE_MODEL or "Butterfly Knife",
        Multi = false,
        Text = "Knife model",
        Tooltip = "Select custom knife model replacement for slot 3",
        Callback = function(Value)
            updateSetting("KNIFE_MODEL", Value)
            if SkinChanger and SkinChanger.refreshActiveViewmodels then
                SkinChanger.refreshActiveViewmodels(Config)
            end
        end
    })

    SkinsMain:AddDropdown("SkinMode", {
        Values = { "Special", "Random" },
        Default = (Config.SKIN_MODE == "Random") and "Random" or "Special",
        Multi = false,
        Text = "Skin selection",
        Tooltip = "Special: Applies top-tier Special & Covert skins (Fade, Lore, Midas, etc.)\nRandom: Automatically randomizes all skins every new round",
        Callback = function(Value)
            updateSetting("SKIN_MODE", Value)
            if SkinChanger then
                if Value == "Random" and SkinChanger.rerollRandomSkins then
                    SkinChanger.rerollRandomSkins(Config)
                elseif SkinChanger.refreshActiveViewmodels then
                    SkinChanger.refreshActiveViewmodels(Config)
                end
            end
        end
    })

    SkinsActions:AddButton({
        Text = "Refresh viewmodels",
        Func = function()
            if SkinChanger and SkinChanger.refreshActiveViewmodels then
                SkinChanger.refreshActiveViewmodels(Config)
                Library:Notify("Viewmodels refreshed successfully", 2)
            end
        end,
        DoubleClick = false,
        Tooltip = "Re-applies custom weapon skins and viewmodel rigs"
    })

    SkinsActions:AddLabel("Random skins automatically cycle at the start of every new round.", true)

    -- settings tab
    local MenuGroup = Tabs.Settings:AddLeftGroupbox("Keybinds")
    local ActionsGroup = Tabs.Settings:AddRightGroupbox("Actions")

    local defaultMenuKey = (Config.TOGGLE_UI_KEY and Config.TOGGLE_UI_KEY.Name) or "Insert"
    MenuGroup:AddLabel("Menu toggle"):AddKeyPicker("MenuKeybind", {
        Default = defaultMenuKey,
        NoUI = true,
        Text = "Menu Key",
        ChangedCallback = function(NewKey)
            local key = (NewKey ~= "None") and Enum.KeyCode[NewKey] or nil
            updateSetting("TOGGLE_UI_KEY", key)
        end
    })

    local defaultAimKey = (Config.TOGGLE_AIM_KEY and Config.TOGGLE_AIM_KEY.Name) or "None"
    MenuGroup:AddLabel("Silent aim bind"):AddKeyPicker("AimKeybind", {
        Default = defaultAimKey,
        NoUI = true,
        Text = "Silent aim bind",
        ChangedCallback = function(NewKey)
            local key = (NewKey ~= "None") and Enum.KeyCode[NewKey] or nil
            updateSetting("TOGGLE_AIM_KEY", key)
        end
    })

    MenuGroup:AddDropdown("AimBindMode", {
        Values = { "Toggle", "Hold" },
        Default = Config.AIM_BIND_MODE or "Toggle",
        Multi = false,
        Text = "Aim bind mode",
        Tooltip = "Toggle: Press key to toggle silent aim on/off\nHold: Hold key to activate silent aim",
        Callback = function(Value)
            updateSetting("AIM_BIND_MODE", Value)
        end
    })

    local defaultEspKey = (Config.TOGGLE_ESP_KEY and Config.TOGGLE_ESP_KEY.Name) or "None"
    MenuGroup:AddLabel("Master ESP bind"):AddKeyPicker("EspKeybind", {
        Default = defaultEspKey,
        NoUI = true,
        Text = "Master ESP bind",
        ChangedCallback = function(NewKey)
            local key = (NewKey ~= "None") and Enum.KeyCode[NewKey] or nil
            updateSetting("TOGGLE_ESP_KEY", key)
        end
    })

    local defaultUnloadKey = (Config.UNLOAD_KEY and Config.UNLOAD_KEY.Name) or "K"
    MenuGroup:AddLabel("Unload / Kill script"):AddKeyPicker("UnloadKeybind", {
        Default = defaultUnloadKey,
        NoUI = true,
        Text = "Kill script",
        ChangedCallback = function(NewKey)
            local key = (NewKey ~= "None") and Enum.KeyCode[NewKey] or nil
            updateSetting("UNLOAD_KEY", key)
        end
    })

    Library.ToggleKeybind = Options.MenuKeybind

    ActionsGroup:AddButton({
        Text = "Reset defaults",
        Func = function()
            Config.reset()

            if Toggles.SilentAim then Toggles.SilentAim:SetValue(Config.SILENT_AIM_ENABLED) end
            if Toggles.KeepLock then Toggles.KeepLock:SetValue(Config.KEEP_TARGET_LOCK) end
            if Options.TargetPriority then Options.TargetPriority:SetValue(Config.TARGET_PRIORITY or "Auto") end

            if Toggles.EspMaster then Toggles.EspMaster:SetValue(Config.ESP_ENABLED) end
            if Toggles.SkeletonEsp then Toggles.SkeletonEsp:SetValue(Config.SKELETON_ENABLED) end
            if Toggles.ViewAngle then Toggles.ViewAngle:SetValue(Config.VIEWANGLE_ENABLED) end
            if Toggles.OffscreenArrows then Toggles.OffscreenArrows:SetValue(Config.OFFSCREEN_ARROWS) end
            if Toggles.TargetPartHl then Toggles.TargetPartHl:SetValue(Config.BODYPART_TARGET_HL) end
            if Toggles.DisableTeammates then Toggles.DisableTeammates:SetValue(Config.DISABLE_TEAMMATES) end
            if Toggles.OcclusionCheck then Toggles.OcclusionCheck:SetValue(Config.OCCLUSION_CHECK_ENABLED) end
            if Toggles.SpectateChecker then Toggles.SpectateChecker:SetValue(Config.SPECTATE_CHECKER_ENABLED) end

            if Toggles.ShowFov then Toggles.ShowFov:SetValue(Config.FOV_CIRCLE_ENABLED) end
            if Options.FovAngle then Options.FovAngle:SetValue(Config.FOV_DEG or 30) end
            if Options.FovOpacity then Options.FovOpacity:SetValue(math.floor((Config.FOV_CIRCLE_TRANSPARENCY or 0.5) * 100)) end
            if Toggles.AntiFlash then Toggles.AntiFlash:SetValue(Config.ANTI_FLASH_ENABLED) end
            if Options.FlashOpacity then Options.FlashOpacity:SetValue(math.floor((Config.ANTI_FLASH_TRANSPARENCY or 0.85) * 100)) end

            if Toggles.Bhop then Toggles.Bhop:SetValue(Config.BHOP_ENABLED) end
            if Toggles.CustomPresets then Toggles.CustomPresets:SetValue(Config.SKINS_ENABLED) end
            if Options.KnifeModel then Options.KnifeModel:SetValue(Config.KNIFE_MODEL or "Butterfly Knife") end
            if Options.SkinMode then Options.SkinMode:SetValue(Config.SKIN_MODE or "Special") end

            if Options.MenuKeybind then Options.MenuKeybind:SetValue("Insert") end
            if Options.AimKeybind then Options.AimKeybind:SetValue("None") end
            if Options.AimBindMode then Options.AimBindMode:SetValue("Toggle") end
            if Options.EspKeybind then Options.EspKeybind:SetValue("None") end
            if Options.UnloadKeybind then Options.UnloadKeybind:SetValue("K") end

            queueAutoSave()
            Library:Notify("Settings reset to defaults", 2)
        end,
        DoubleClick = false,
        Tooltip = "Resets all features and sliders to factory defaults"
    })

    ActionsGroup:AddButton({
        Text = "Unload suite",
        Func = function()
            if type(unloadCallback) == "function" then
                unloadCallback()
            elseif _G.__bloxstrikeJanitor then
                _G.__bloxstrikeJanitor()
            end
        end,
        DoubleClick = true,
        Tooltip = "Double click to completely unload the suite"
    })

    -- key listeners
    local bindInputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or (Library and Library.IsPickingKey) then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if Config.TOGGLE_AIM_KEY and input.KeyCode == Config.TOGGLE_AIM_KEY then
                if Config.AIM_BIND_MODE == "Hold" then
                    updateSetting("SILENT_AIM_ENABLED", true)
                    if Toggles.SilentAim and Toggles.SilentAim.Value ~= true then
                        Toggles.SilentAim:SetValue(true)
                    end
                else
                    local nextState = not Config.SILENT_AIM_ENABLED
                    updateSetting("SILENT_AIM_ENABLED", nextState)
                    if Toggles.SilentAim and Toggles.SilentAim.Value ~= nextState then
                        Toggles.SilentAim:SetValue(nextState)
                    end
                end
            elseif Config.TOGGLE_ESP_KEY and input.KeyCode == Config.TOGGLE_ESP_KEY then
                local nextState = not Config.ESP_ENABLED
                updateSetting("ESP_ENABLED", nextState)
                if Toggles.EspMaster and Toggles.EspMaster.Value ~= nextState then
                    Toggles.EspMaster:SetValue(nextState)
                end
            elseif Config.TOGGLE_UI_KEY_ALT and input.KeyCode == Config.TOGGLE_UI_KEY_ALT then
                if Window and Window.Holder then
                    Window.Holder.Visible = not Window.Holder.Visible
                end
            end
        end
    end)
    table.insert(UIManager.Connections, bindInputBegan)

    local bindInputEnded = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if Library and Library.IsPickingKey then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if Config.TOGGLE_AIM_KEY and input.KeyCode == Config.TOGGLE_AIM_KEY and Config.AIM_BIND_MODE == "Hold" then
                updateSetting("SILENT_AIM_ENABLED", false)
                if Toggles.SilentAim and Toggles.SilentAim.Value ~= false then
                    Toggles.SilentAim:SetValue(false)
                end
            end
        end
    end)
    table.insert(UIManager.Connections, bindInputEnded)

    Library:Notify("Seeto.SolutionZ / Bloxstrike / v2.1 Loaded!", 3)
end

function UIManager.cleanup()
    for _, c in ipairs(UIManager.Connections) do
        pcall(function() c:Disconnect() end)
    end
    UIManager.Connections = {}

    local Library = UIManager.Library
    if Library and Library.Unload then
        pcall(function() Library:Unload() end)
    end

    UIManager.Library = nil
    UIManager.Window = nil
    UIManager.Initialized = false
end

return UIManager
