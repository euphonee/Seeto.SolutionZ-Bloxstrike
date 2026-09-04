-- movement physics (bhop and autostrafe)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
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

        if autoStrafeEnabled and self and self.OnGround == false then
            local vel = self.GlobalVelocity or Vector3.zero
            local hVel = Vector3.new(vel.X, 0, vel.Z)
            local speed = hVel.Magnitude

            -- only engage when moving in midair
            if speed >= 3 then
                local isDDown = UserInputService:IsKeyDown(Enum.KeyCode.D)
                local isADown = UserInputService:IsKeyDown(Enum.KeyCode.A)
                local isSDown = UserInputService:IsKeyDown(Enum.KeyCode.S)
                local isWDown = UserInputService:IsKeyDown(Enum.KeyCode.W)

                -- 1. manual key priority
                if isADown and not isDDown then
                    sample.Move = Vector2.new(-1, 0)
                elseif isDDown and not isADown then
                    sample.Move = Vector2.new(1, 0)
                elseif isSDown and not isWDown then
                    sample.Move = Vector2.new(0, -1)
                else
                    -- 2. mouse-guided precision autostrafe
                    local cam = Workspace.CurrentCamera
                    local look = cam and cam.CFrame.LookVector
                    local mouseDeltaX = UserInputService:GetMouseDelta().X

                    local lookYaw = sample.LookYaw or (self and self.CurrentFrameLookYaw)
                    local deltaYaw = 0
                    if lookYaw and lastLookYaw then
                        deltaYaw = math.atan2(math.sin(lookYaw - lastLookYaw), math.cos(lookYaw - lastLookYaw))
                    end

                    if look then
                        local cDir = Vector3.new(look.X, 0, look.Z).Unit
                        local vDir = hVel / speed

                        -- cross product: >0 when view leads right, <0 when view leads left
                        local crossY = vDir.X * cDir.Z - vDir.Z * cDir.X

                        local steerRight = (crossY > 0.012) or (mouseDeltaX > 0.6) or (deltaYaw < -0.0008)
                        local steerLeft  = (crossY < -0.012) or (mouseDeltaX < -0.6) or (deltaYaw > 0.0008)

                        if steerRight and not steerLeft then
                            sample.Move = Vector2.new(1, 0)
                        elseif steerLeft and not steerRight then
                            sample.Move = Vector2.new(-1, 0)
                        else
                            -- straight flight: keep smooth forward momentum
                            if isWDown or isSpaceDown then
                                sample.Move = Vector2.new(0, 1)
                            end
                        end
                    end
                end
            end
        end

        lastLookYaw = sample.LookYaw or (self and self.CurrentFrameLookYaw)
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
