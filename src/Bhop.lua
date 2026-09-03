-- movement physics (bhop and autostrafe)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local CharacterClass = require(ReplicatedStorage.Classes.Character)
local Buttons = require(ReplicatedStorage.MovementV2.Buttons)

local Bhop = {
    IsHoldingSpace = false,
    Connections = {},
    Initialized = false
}

local originalSampleInput = nil
local jumpTickToggle = false
local strafeTick = 0
local lastLookYaw = nil

function Bhop.init(Config)
    if Bhop.Initialized then return end
    Bhop.Initialized = true

    local beganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.Space then
            Bhop.IsHoldingSpace = true
        end
    end)
    table.insert(Bhop.Connections, beganConn)

    local endedConn = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.Space then
            Bhop.IsHoldingSpace = false
        end
    end)
    table.insert(Bhop.Connections, endedConn)

    if not _G.__originalSampleInput then
        _G.__originalSampleInput = CharacterClass.SampleInput
    end
    originalSampleInput = _G.__originalSampleInput

    CharacterClass.SampleInput = function(self, p2)
        local sample = originalSampleInput(self, p2)
        if not sample then return sample end

        -- bhop jump toggle
        local bhopEnabled = (Config.BHOP_ENABLED ~= false)
        local isSpaceDown = Bhop.IsHoldingSpace or UserInputService:IsKeyDown(Enum.KeyCode.Space)
        if bhopEnabled and isSpaceDown then
            jumpTickToggle = not jumpTickToggle
            sample.Buttons = Buttons.with(sample.Buttons, Buttons.Jump, jumpTickToggle)
        elseif not isSpaceDown then
            jumpTickToggle = false
        end

        -- air autostrafe
        local autoStrafeEnabled = (Config.AUTO_STRAFE_ENABLED ~= false)
        local lookYaw = sample.LookYaw or (self and self.CurrentFrameLookYaw) or 0

        if autoStrafeEnabled and self and self.OnGround == false then
            local vel = self.GlobalVelocity or Vector3.zero
            local hVel = Vector3.new(vel.X, 0, vel.Z)
            local speed = hVel.Magnitude

            local isDDown = UserInputService:IsKeyDown(Enum.KeyCode.D)
            local isADown = UserInputService:IsKeyDown(Enum.KeyCode.A)
            local isSDown = UserInputService:IsKeyDown(Enum.KeyCode.S)
            local isWDown = UserInputService:IsKeyDown(Enum.KeyCode.W)

            local deltaYaw = 0
            if lastLookYaw then
                deltaYaw = math.atan2(math.sin(lookYaw - lastLookYaw), math.cos(lookYaw - lastLookYaw))
            end

            local wish = nil

            if speed < 3 then
                local cosY = math.cos(lookYaw)
                local sinY = math.sin(lookYaw)
                local F = Vector3.new(sinY, 0, -cosY)
                local R = Vector3.new(cosY, 0, sinY)
                local dir = Vector3.zero
                if isWDown then dir = dir + F end
                if isSDown then dir = dir - F end
                if isDDown then dir = dir + R end
                if isADown then dir = dir - R end
                if dir.Magnitude > 0.1 then
                    wish = dir.Unit
                end
            else
                local vDir = hVel / speed
                local perpRight = vDir:Cross(Vector3.new(0, 1, 0)).Unit
                local perpLeft = -perpRight

                if math.abs(deltaYaw) > 0.0006 then
                    wish = (deltaYaw < 0) and perpRight or perpLeft
                elseif isDDown and not isADown then
                    wish = perpRight
                elseif isADown and not isDDown then
                    wish = perpLeft
                elseif isSDown and not isWDown then
                    wish = perpRight
                elseif isSpaceDown or isWDown then
                    strafeTick = strafeTick + 1
                    local side = (math.floor(strafeTick / 6) % 2 == 0) and 1 or -1
                    local perp = (side == 1) and perpRight or perpLeft
                    wish = (vDir * 0.15 + perp * 0.98).Unit
                end
            end

            if wish then
                local cosY = math.cos(lookYaw)
                local sinY = math.sin(lookYaw)
                local mx = cosY * wish.X - sinY * wish.Z
                local my = sinY * wish.X + cosY * wish.Z
                sample.Move = Vector2.new(math.clamp(mx, -1, 1), math.clamp(my, -1, 1))
            end
        else
            strafeTick = 0
        end

        lastLookYaw = lookYaw
        return sample
    end
end

function Bhop.cleanup()
    if originalSampleInput then
        pcall(function() CharacterClass.SampleInput = originalSampleInput end)
    end
    for _, c in ipairs(Bhop.Connections) do
        pcall(function() c:Disconnect() end)
    end
    Bhop.Connections = {}
    Bhop.IsHoldingSpace = false
    Bhop.Initialized = false
    _G.__originalSampleInput = nil
    lastLookYaw = nil
end

return Bhop
