-- skin changer and knife customizer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local WeaponComponent = require(ReplicatedStorage.Classes.WeaponComponent)
local SkinsLib = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local SkinsFolder = ReplicatedStorage:FindFirstChild("Assets")
if SkinsFolder then SkinsFolder = SkinsFolder:FindFirstChild("Skins") end

local SkinChanger = {
    Connections = {},
    Initialized = false,
    RandomCache = {}
}

-- curated special and covert skins
SkinChanger.TopTierSkins = {
    -- knives
    ["Butterfly Knife"] = "Fade",
    ["Karambit"]        = "Fade",
    ["M9 Bayonet"]      = "Fade",
    ["Skeleton Knife"]  = "Fade",
    ["Stiletto Knife"]  = "Whiteout",
    ["Flip Knife"]      = "Fade",
    ["Gut Knife"]       = "Fade",
    ["LightSaber"]      = "Ren",
    ["CT Knife"]        = "Lebron James",
    ["T Knife"]         = "Vanilla",

    -- rifles
    ["AK-47"]           = "Midas",
    ["AWP"]             = "Lore",
    ["M4A4"]            = "The Ambassador",
    ["M4A1-S"]          = "Bloggd",
    ["SSG 08"]          = "Prototype",
    ["Galil AR"]        = "Limewire",
    ["FAMAS"]           = "Wallpaper",
    ["SG 553"]          = "Cryo",
    ["AUG"]             = "Hero of Hell",

    -- pistols
    ["Desert Eagle"]    = "Lore",
    ["Glock-18"]        = "Fade",
    ["USP-S"]           = "SpecOps",
    ["Tec-9"]           = "Vice",
    ["P250"]            = "Zen",
    ["Five-SeveN"]      = "NoMercy",
    ["Dual Berettas"]   = "Overclock",
    ["R8 Revolver"]     = "Heatseeka",

    -- smgs and heavy
    ["MP9"]             = "Hibiki",
    ["MAC-10"]          = "Parcel",
    ["P90"]             = "Visions",
    ["UMP-45"]          = "Primal Saber",
    ["Nova"]            = "Mecha",
    ["XM1014"]          = "BloxoBlasto",
    ["MAG-7"]           = "Ambulance",
    ["Negev"]           = "Rotary Power",
    ["Sawed-Off"]       = "Memento"
}

SkinChanger.SelectedSkins = {}

local function isLocalPlayerAlive()
    local charsFolder = Workspace:FindFirstChild("Characters")
    local myChar = LocalPlayer.Character
    if not myChar or not charsFolder or myChar.Parent ~= charsFolder then
        return false
    end
    if myChar:GetAttribute("Dead") == true then
        return false
    end
    return true
end

local function isViewingLocalPlayer()
    if not isLocalPlayerAlive() then
        return false
    end
    local myChar = LocalPlayer.Character
    local subject = Camera.CameraSubject
    if not subject then
        return true
    end
    if subject == myChar or subject:IsDescendantOf(myChar) then
        return true
    end
    return false
end

local function isKnife(weaponName)
    if typeof(weaponName) ~= "string" then return false end
    if weaponName == "Zeus x27" or weaponName:find("Zeus") or weaponName:find("Taser") then
        return false
    end
    if weaponName == "CT Knife" or weaponName == "T Knife" or weaponName == "Butterfly Knife" or weaponName:find("Knife") or weaponName:find("Bayonet") or weaponName:find("Karambit") or weaponName == "LightSaber" then
        return true
    end
    return false
end

local function isExemptUtility(weaponName)
    if typeof(weaponName) ~= "string" then return false end
    if weaponName == "Zeus x27" or weaponName:find("Grenade") or weaponName == "Molotov" or weaponName == "Flashbang" or weaponName == "C4" then
        return true
    end
    return false
end

-- knife model and skin resolver
function SkinChanger.getKnifeSelection(Config)
    local targetKnife = (Config and Config.KNIFE_MODEL) or "Butterfly Knife"
    if targetKnife == "Default" or targetKnife == "Vanilla" then
        return nil, nil
    end

    local skinMode = (Config and Config.SKIN_MODE) or "Special"
    local skinName = "Fade"

    if skinMode == "Random" then
        if not SkinChanger.RandomCache[targetKnife] then
            local folder = SkinsFolder and SkinsFolder:FindFirstChild(targetKnife)
            if folder then
                local validSkins = {}
                for _, s in ipairs(folder:GetChildren()) do
                    if s.Name ~= "Stock" and s.Name ~= "Vanilla" then
                        table.insert(validSkins, s.Name)
                    end
                end
                if #validSkins > 0 then
                    SkinChanger.RandomCache[targetKnife] = validSkins[math.random(1, #validSkins)]
                else
                    SkinChanger.RandomCache[targetKnife] = "Fade"
                end
            else
                SkinChanger.RandomCache[targetKnife] = "Fade"
            end
        end
        skinName = SkinChanger.RandomCache[targetKnife]
    else
        skinName = SkinChanger.TopTierSkins[targetKnife] or "Fade"
    end

    return targetKnife, skinName
end

-- gun skin resolver
function SkinChanger.getValidSkin(weaponName, Config)
    if not SkinsFolder or not weaponName or isExemptUtility(weaponName) then return nil end
    local folder = SkinsFolder:FindFirstChild(weaponName)
    if not folder then return nil end

    local skinMode = (Config and Config.SKIN_MODE) or "Special"

    if skinMode == "Random" then
        if not SkinChanger.RandomCache[weaponName] then
            local validSkins = {}
            for _, s in ipairs(folder:GetChildren()) do
                if s.Name ~= "Stock" and s.Name ~= "Vanilla" and not s.Name:find("PATTERN") and s.Name ~= "Terrorists" and s.Name ~= "Counter-Terrorists" then
                    table.insert(validSkins, s.Name)
                end
            end
            if #validSkins > 0 then
                SkinChanger.RandomCache[weaponName] = validSkins[math.random(1, #validSkins)]
            else
                SkinChanger.RandomCache[weaponName] = "Stock"
            end
        end
        return SkinChanger.RandomCache[weaponName], "Factory New"
    end

    local custom = (Config and Config.SELECTED_SKINS and Config.SELECTED_SKINS[weaponName]) or SkinChanger.SelectedSkins[weaponName]
    if custom and folder:FindFirstChild(custom.Skin or custom) then
        local skinName = custom.Skin or custom
        local wear = custom.Wear or "Factory New"
        return skinName, wear
    end

    local pref = SkinChanger.TopTierSkins[weaponName]
    if pref and folder:FindFirstChild(pref) then
        return pref, "Factory New"
    end

    local children = folder:GetChildren()
    for i = #children, 1, -1 do
        local name = children[i].Name
        if name ~= "Stock" and name ~= "Vanilla" and not name:find("PATTERN") and name ~= "Terrorists" and name ~= "Counter-Terrorists" then
            return name, "Factory New"
        end
    end

    return nil
end

function SkinChanger.applySkinToViewModel(viewmodel, weaponName, skinName, wear)
    if not SkinsFolder or not viewmodel or not weaponName or not skinName or isExemptUtility(weaponName) then return false end
    local weaponFolder = SkinsFolder:FindFirstChild(weaponName)
    if not weaponFolder then return false end

    local skin = weaponFolder:FindFirstChild(skinName)
    if not skin then return false end

    local camFolder = skin:FindFirstChild("Camera") or skin
    local wearFolder = camFolder:FindFirstChild(wear or "Factory New") 
        or camFolder:FindFirstChild("Factory New")
        or camFolder:FindFirstChild("Minimal Wear")
        or camFolder:FindFirstChild("Field-Tested")
        or camFolder:GetChildren()[1]

    if not wearFolder then return false end

    pcall(function()
        for _, sa in ipairs(wearFolder:GetChildren()) do
            if sa:IsA("SurfaceAppearance") then
                local targetPart = viewmodel:FindFirstChild(sa.Name, true)
                if targetPart and (targetPart:IsA("MeshPart") or targetPart:IsA("BasePart")) then
                    local old = targetPart:FindFirstChildOfClass("SurfaceAppearance")
                    if old then pcall(function() old:Destroy() end) end

                    local clone = sa:Clone()
                    clone.Parent = targetPart
                end
            end
        end
    end)
    return true
end

function SkinChanger.rerollRandomSkins(Config)
    SkinChanger.RandomCache = {}
    SkinChanger.refreshActiveViewmodels(Config)
end

function SkinChanger.refreshActiveViewmodels(Config)
    if not isViewingLocalPlayer() then return end

    for _, child in ipairs(Camera:GetChildren()) do
        if child:IsA("Model") and (child:FindFirstChild("Weapon") or child:FindFirstChild("WeaponL") or child:FindFirstChild("WeaponR")) then
            local weaponName = child.Name
            if not isExemptUtility(weaponName) then
                local skinName, wear = SkinChanger.getValidSkin(weaponName, Config)
                if skinName then
                    SkinChanger.applySkinToViewModel(child, weaponName, skinName, wear)
                end
            end
        end
    end
end

local originalWeaponNew = nil
local originalGetCameraModel = nil
local originalGetCharacterModel = nil

function SkinChanger.init(Config)
    if SkinChanger.Initialized then return end
    SkinChanger.Initialized = true

    if not _G.__originalWeaponComponentNew then
        _G.__originalWeaponComponentNew = WeaponComponent.new
    end
    originalWeaponNew = _G.__originalWeaponComponentNew

    if not _G.__originalGetCameraModel then
        _G.__originalGetCameraModel = SkinsLib.GetCameraModel
    end
    originalGetCameraModel = _G.__originalGetCameraModel

    if not _G.__originalGetCharacterModel then
        _G.__originalGetCharacterModel = SkinsLib.GetCharacterModel
    end
    originalGetCharacterModel = _G.__originalGetCharacterModel

    -- knife component hook
    WeaponComponent.new = function(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, ...)
        local enabled = (Config.CUSTOM_PRESETS ~= false and Config.SKINS_ENABLED ~= false)
        if not enabled or p1 ~= LocalPlayer or not isLocalPlayerAlive() then
            return originalWeaponNew(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, ...)
        end

        if isKnife(p5, p4) then
            local targetKnife, skinName = SkinChanger.getKnifeSelection(Config)
            if targetKnife then
                return originalWeaponNew(p1, p2, p3, p4, targetKnife, skinName, 0.001, p8, p9, p10, p11, p12, ...)
            end
        end

        return originalWeaponNew(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, ...)
    end

    -- knife viewmodel hook
    SkinsLib.GetCameraModel = function(weaponName, skinName, float, statTrack, nameTag, charm, stickers, team)
        local enabled = (Config.CUSTOM_PRESETS ~= false and Config.SKINS_ENABLED ~= false)
        if not enabled or not isViewingLocalPlayer() then
            return originalGetCameraModel(weaponName, skinName, float, statTrack, nameTag, charm, stickers, team)
        end

        if isKnife(weaponName) then
            local targetKnife, knifeSkin = SkinChanger.getKnifeSelection(Config)
            if targetKnife then
                local model = originalGetCameraModel(targetKnife, knifeSkin, 0.001, statTrack, nameTag, charm, stickers, team)
                if model then
                    model.Name = targetKnife
                end
                return model
            end
        end

        return originalGetCameraModel(weaponName, skinName, float, statTrack, nameTag, charm, stickers, team)
    end

    SkinsLib.GetCharacterModel = function(weaponName, skinName, float, statTrack, nameTag, charm, stickers, team)
        return originalGetCharacterModel(weaponName, skinName, float, statTrack, nameTag, charm, stickers, team)
    end

    -- viewmodel texture hook
    local cameraConn = Camera.ChildAdded:Connect(function(child)
        local enabled = (Config.CUSTOM_PRESETS ~= false and Config.SKINS_ENABLED ~= false)
        if not enabled or not isViewingLocalPlayer() then return end

        if child:IsA("Model") and (child:FindFirstChild("Weapon") or child:FindFirstChild("WeaponL") or child:FindFirstChild("WeaponR")) then
            local weaponName = child.Name
            if not isExemptUtility(weaponName) and not isKnife(weaponName) then
                task.defer(function()
                    task.wait(0.04)
                    if (Config.CUSTOM_PRESETS ~= false and Config.SKINS_ENABLED ~= false) and isViewingLocalPlayer() then
                        local skinName, wear = SkinChanger.getValidSkin(weaponName, Config)
                        if skinName then
                            SkinChanger.applySkinToViewModel(child, weaponName, skinName, wear)
                        end
                    end
                end)
            end
        end
    end)
    table.insert(SkinChanger.Connections, cameraConn)

    -- round change listener
    local function onRoundChange()
        local enabled = (Config.CUSTOM_PRESETS ~= false and Config.SKINS_ENABLED ~= false)
        if not enabled then return end
        if Config.SKIN_MODE == "Random" then
            SkinChanger.RandomCache = {}
            task.delay(0.25, function()
                if (Config.CUSTOM_PRESETS ~= false and Config.SKINS_ENABLED ~= false) then
                    SkinChanger.refreshActiveViewmodels(Config)
                end
            end)
        end
    end

    local charSpawnConn = LocalPlayer.CharacterAdded:Connect(function(char)
        onRoundChange()
    end)
    table.insert(SkinChanger.Connections, charSpawnConn)

    local nr = ReplicatedStorage:FindFirstChild("NetworkRemotes")
    if nr and nr:FindFirstChild("UI") and nr.UI:FindFirstChild("RoundWinner") then
        local roundEndConn = nr.UI.RoundWinner.OnClientEvent:Connect(function()
            onRoundChange()
        end)
        table.insert(SkinChanger.Connections, roundEndConn)
    end

    SkinChanger.refreshActiveViewmodels(Config)
end

function SkinChanger.cleanup()
    for _, c in ipairs(SkinChanger.Connections) do
        pcall(function() c:Disconnect() end)
    end
    SkinChanger.Connections = {}

    if originalWeaponNew then
        WeaponComponent.new = originalWeaponNew
    end
    if originalGetCameraModel then
        SkinsLib.GetCameraModel = originalGetCameraModel
    end
    if originalGetCharacterModel then
        SkinsLib.GetCharacterModel = originalGetCharacterModel
    end

    originalWeaponNew = nil
    originalGetCameraModel = nil
    originalGetCharacterModel = nil
    _G.__originalWeaponComponentNew = nil
    _G.__originalGetCameraModel = nil
    _G.__originalGetCharacterModel = nil
    SkinChanger.RandomCache = {}
    SkinChanger.Initialized = false
end

return SkinChanger
