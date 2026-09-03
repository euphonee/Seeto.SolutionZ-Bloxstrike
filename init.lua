-- Seeto.SolutionZ / Bloxstrike / v2.1

-- cleanup existing instances
if _G.__agScriptJanitor then pcall(_G.__agScriptJanitor) _G.__agScriptJanitor = nil end
if _G.__bloxstrikeJanitor then pcall(_G.__bloxstrikeJanitor) _G.__bloxstrikeJanitor = nil end
if _G.__shotAdvisorJanitor then pcall(_G.__shotAdvisorJanitor) _G.__shotAdvisorJanitor = nil end
if _G.__spectatorUIJanitor then pcall(_G.__spectatorUIJanitor) _G.__spectatorUIJanitor = nil end
if _G.__standaloneRCS then pcall(_G.__standaloneRCS) _G.__standaloneRCS = nil end
if _G.__passiveSuiteJanitor then pcall(_G.__passiveSuiteJanitor) _G.__passiveSuiteJanitor = nil end
if _G.__antiFlashJanitor then pcall(_G.__antiFlashJanitor) _G.__antiFlashJanitor = nil end
if _G.__bhopJanitor then pcall(_G.__bhopJanitor) _G.__bhopJanitor = nil end
if _G.__skinChangerJanitor then pcall(_G.__skinChangerJanitor) _G.__skinChangerJanitor = nil end

if _G.__bulletOriginHook then
    local ok, b = pcall(function() return require(game:GetService("ReplicatedStorage").Components.Weapon.Classes.Bullet) end)
    if ok and b and _G.__bulletOriginHook then
        b._performRaycast = _G.__bulletOriginHook
    end
    _G.__bulletOriginHook = nil
end

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera

-- module loader
local modules = {}
local function import(moduleName)
    if modules[moduleName] then return modules[moduleName] end
    
    if type(readfile) == "function" then
        local paths = {
            "Bloxstrike/src/" .. moduleName .. ".lua",
            "src/" .. moduleName .. ".lua",
            moduleName .. ".lua"
        }
        for _, path in ipairs(paths) do
            local ok, content = pcall(readfile, path)
            if ok and content then
                local fn, loadErr = loadstring(content)
                if fn then
                    local res = fn()
                    modules[moduleName] = res
                    return res
                end
            end
        end
    end
    
    if _G.__BloxstrikeModules and _G.__BloxstrikeModules[moduleName] then
        local res = _G.__BloxstrikeModules[moduleName]()
        modules[moduleName] = res
        return res
    end
    
    -- remote github fallback
    local okHttp, remoteContent = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/euphonee/Bloxstrike/main/src/" .. moduleName .. ".lua")
    end)
    if okHttp and remoteContent and #remoteContent > 0 then
        local fn, loadErr = loadstring(remoteContent)
        if fn then
            local res = fn()
            modules[moduleName] = res
            return res
        end
    end

    error("[Bloxstrike] Failed to import module: " .. tostring(moduleName))
end

-- imports
local Config           = import("Config")
local Utils            = import("Utils")
local DamageEngine     = import("DamageEngine")
local SkeletonRenderer = import("SkeletonRenderer")
local TargetEngine     = import("TargetEngine")
local ESPManager       = import("ESPManager")
local SilentAim        = import("SilentAim")
local SpectateChecker  = import("SpectateChecker")
local Bhop             = import("Bhop")
local AntiFlash        = import("AntiFlash")
local SkinChanger      = import("SkinChanger")
local LinoriaLib       = import("LinoriaLib")
local UIManager        = import("UIManager")

-- load config
Config.load()

-- setup primitives
ESPManager.init(Config, Utils, SkeletonRenderer)
SpectateChecker.init(Config)
TargetEngine.init(Config)

-- fov circle
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.NumSides = 64
fovCircle.Radius = Config.FOV_RADIUS
fovCircle.Filled = false
fovCircle.Transparency = Config.FOV_CIRCLE_TRANSPARENCY or 0.5
fovCircle.Color = Config.FOV_CIRCLE_COLOR or Color3.fromRGB(255, 255, 255)
fovCircle.ZIndex = 1
fovCircle.Visible = Config.FOV_CIRCLE_ENABLED

-- init subsystems
SilentAim.init(Config)
Bhop.init(Config)
AntiFlash.init(Config)
SkinChanger.init(Config)

-- cleanup
local renderConn = nil
local keyConn = nil

local function cleanup()
    print("[Bloxstrike] Unloading suite...")
    
    if renderConn then pcall(function() renderConn:Disconnect() end) end
    if keyConn then pcall(function() keyConn:Disconnect() end) end
    
    UIManager.cleanup()
    Bhop.cleanup()
    AntiFlash.cleanup()
    SkinChanger.cleanup()
    SilentAim.cleanup()
    TargetEngine.cleanup()
    ESPManager.cleanup(SkeletonRenderer)
    SpectateChecker.cleanup()
    
    pcall(function() fovCircle:Remove() end)
    
    _G.__bloxstrikeJanitor = nil
    print("[Bloxstrike] Unloaded successfully.")
end

_G.__bloxstrikeJanitor = cleanup

-- init ui
UIManager.init(Config, LinoriaLib, SkinChanger, cleanup)

-- render loop
renderConn = RunService.RenderStepped:Connect(function(dt)
    local vpCenter = Camera.ViewportSize * 0.5
    fovCircle.Position = Vector2.new(vpCenter.X, vpCenter.Y)

    -- angular fov projection
    local fovDeg = Config.FOV_DEG or 30
    if fovDeg >= 180 then
        fovCircle.Radius = math.max(Camera.ViewportSize.X, Camera.ViewportSize.Y) * 2
    else
        local camFov = math.clamp(Camera.FieldOfView, 1, 120)
        local focalLength = (Camera.ViewportSize.Y * 0.5) / math.tan(math.rad(camFov * 0.5))
        local radiusPx = focalLength * math.tan(math.rad(math.min(fovDeg, 89.5)))
        fovCircle.Radius = radiusPx
    end

    fovCircle.Color = Config.FOV_CIRCLE_COLOR
    fovCircle.Transparency = Config.FOV_CIRCLE_TRANSPARENCY
    fovCircle.Visible = (Config.FOV_CIRCLE_ENABLED ~= false) and (Config.ESP_ENABLED ~= false)

    TargetEngine.update(Config, Utils, DamageEngine)
    ESPManager.update(Config, Utils, SkeletonRenderer)
    SpectateChecker.update(Config)
end)

-- unload key listener
keyConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if LinoriaLib and LinoriaLib.IsPickingKey then return end
    if Config.UNLOAD_KEY and input.KeyCode == Config.UNLOAD_KEY then
        cleanup()
    end
end)

print("[Bloxstrike] Seeto.SolutionZ / Bloxstrike / v2.1 Loaded Successfully!")
print("[Bloxstrike] Menu: [Insert] or [Right Shift] | Panic / Unload: [" .. (Config.UNLOAD_KEY and Config.UNLOAD_KEY.Name or "K") .. "]")
return "Seeto.SolutionZ / Bloxstrike / v2.1 Loaded"
