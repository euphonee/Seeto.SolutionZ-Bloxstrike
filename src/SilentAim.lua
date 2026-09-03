-- silent aim and recoil hook
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SilentAim = {}

local BulletModule = require(ReplicatedStorage.Components.Weapon.Classes.Bullet)
local GetRayIgnore = require(ReplicatedStorage.Components.Common.GetRayIgnore)
local Raycast = require(ReplicatedStorage.Shared.Raycast)
local AimAssistController = require(ReplicatedStorage.Controllers.AimAssistController)

local cast = Raycast.cast
local castThrough = Raycast.castThrough

local min = math.min
local rad = math.rad
local abs = math.abs

local _originalGetRecoilAssistMultiplier = nil

-- fallback screen center raycast
local function defaultRaycast(self, spread)
    local ignoreList = GetRayIgnore()
    local cam = Workspace.CurrentCamera
    local vpCenter = cam.ViewportSize * 0.5
    local vpRay = cam:ViewportPointToRay(vpCenter.X, vpCenter.Y)
    
    local dir = vpRay.Direction
    local LookVector = (dir.Magnitude > 0) and dir.Unit or Vector3.new(0, 0, 1)
    local Origin = vpRay.Origin
    
    local penetration = (self.Properties and self.Properties.Penetration) or 0
    local range = (self.Properties and self.Properties.Range) or 500
    
    local t2 = {
        Distance = 0,
        Origin = Origin,
        Direction = LookVector,
        Hits = {}
    }
    
    local hitInfo = cast(Origin, LookVector * range, nil, ignoreList)
    if not hitInfo or not hitInfo.instance then
        t2.Distance = range
        return t2
    end
    
    local position = hitInfo.position
    t2.Distance = (position - Origin).Magnitude
    
    local penetrationHits = castThrough(position + LookVector * -0.001, LookVector * (penetration + 0.001), penetration, ignoreList)
    if penetrationHits then
        local Hits = t2.Hits
        for i = 1, #penetrationHits do
            local v14 = penetrationHits[i]
            if v14.instance and v14.material then
                table.insert(Hits, {
                    Position = v14.position,
                    Instance = v14.instance,
                    Material = (v14.material and v14.material.Name) or tostring(v14.material),
                    Normal = v14.normal or Vector3.new(0, 0, 0),
                    Exit = (i % 2 == 0)
                })
            end
        end
    end
    
    return t2
end

function SilentAim.init(Config)
    if not _G.__originalPerformRaycast then
        _G.__originalPerformRaycast = BulletModule._performRaycast
    end

    -- recoil compensation
    if not _originalGetRecoilAssistMultiplier then
        _originalGetRecoilAssistMultiplier = AimAssistController.GetRecoilAssistMultiplier
    end
    AimAssistController.GetRecoilAssistMultiplier = function()
        if Config.SILENT_AIM_ENABLED and Config.CurrentTargetPart then
            return 1.0
        end
        if _originalGetRecoilAssistMultiplier then
            return _originalGetRecoilAssistMultiplier()
        end
        return 0
    end

    -- bullet raycast redirection
    local function silentAimPerformRaycast(self, spread)
        local targetPart = Config.CurrentTargetPart

        if Config.SILENT_AIM_ENABLED and targetPart and targetPart.Parent and targetPart:IsDescendantOf(Workspace) then
            local char = targetPart.Parent
            if not (char:GetAttribute("Dead") == true) then
                local success, result = pcall(function()
                    local ignoreList = GetRayIgnore()
                    local cam = Workspace.CurrentCamera
                    local vpCenter = cam.ViewportSize * 0.5
                    local vpRay = cam:ViewportPointToRay(vpCenter.X, vpCenter.Y)
                    local Origin = vpRay.Origin

                    local targetPos = targetPart.Position
                    local LookVector = (targetPos - Origin).Unit
                    local totalDistance = (targetPos - Origin).Magnitude
                    local range = math.max((self.Properties and self.Properties.Range) or 500, totalDistance + 50)
                    local penetration = (self.Properties and self.Properties.Penetration) or 0

                    local hitData = {
                        Distance = totalDistance,
                        Origin = Origin,
                        Direction = LookVector,
                        Hits = {}
                    }

                    local hitInfo = cast(Origin, LookVector * range, nil, ignoreList)
                    if hitInfo and hitInfo.instance then
                        local hitPos = hitInfo.position
                        hitData.Distance = (hitPos - Origin).Magnitude

                        local penetrationHits = castThrough(hitPos + LookVector * -0.001, LookVector * (penetration + 0.001), penetration, ignoreList)
                        if penetrationHits then
                            for i = 1, #penetrationHits do
                                local pHit = penetrationHits[i]
                                if pHit.instance and pHit.material then
                                    table.insert(hitData.Hits, {
                                        Position = pHit.position,
                                        Instance = pHit.instance,
                                        Material = (pHit.material and pHit.material.Name) or tostring(pHit.material),
                                        Normal = pHit.normal or Vector3.new(0, 0, 0),
                                        Exit = (i % 2 == 0)
                                    })
                                end
                            end
                        end
                    end

                    return hitData
                end)

                if success and result and result.Hits then
                    return result
                end
            end
        end

        if _G.__originalPerformRaycast then
            return _G.__originalPerformRaycast(self, spread)
        end
        return defaultRaycast(self, spread)
    end

    BulletModule._performRaycast = silentAimPerformRaycast
end

function SilentAim.cleanup()
    if _G.__originalPerformRaycast then
        pcall(function() BulletModule._performRaycast = _G.__originalPerformRaycast end)
    end
    _G.__originalPerformRaycast = nil

    if _originalGetRecoilAssistMultiplier then
        pcall(function() AimAssistController.GetRecoilAssistMultiplier = _originalGetRecoilAssistMultiplier end)
    end
    _originalGetRecoilAssistMultiplier = nil
end

return SilentAim
