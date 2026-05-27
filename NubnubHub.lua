local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = '눕눕 에임핵',
    Center = true,
    AutoShow = true,
})

local Tabs = {
    Main = Window:AddTab('Main'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local CombatGroup = Tabs.Main:AddLeftGroupbox('Aimbot')
local VisualGroup = Tabs.Main:AddRightGroupbox('Visuals')
local TrollingGroup = Tabs.Main:AddRightGroupbox('Trolling')
local ESPGroup = Tabs.Main:AddRightGroupbox('ESP Settings')

-- ==================== SETTINGS ====================
local AimSettings = {
    Enabled = false,
    TeamCheck = false,
    WallCheck = false,
    FOVEnabled = false,
    AimPart = "Head",
    Smoothness = 0.35,
    FOV = 90,
    ShowFOVCircle = false,
    Triggerbot = false,
    TriggerDelay = 0.12,
    FOVColor = Color3.fromRGB(255, 255, 255),
}

local TrollingSettings = { TeleportBehind = false, TeamCheck = false }

local ESPSettings = {
    Box = false, Name = false, HealthBar = false, Chams = false, Tracer = false,
    TeamCheck = false,
    BoxColor = Color3.fromRGB(255, 255, 255),
    NameColor = Color3.fromRGB(255, 255, 255),
    ChamsColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(255, 255, 255),
}

-- ==================== UI ====================
CombatGroup:AddToggle('AimbotToggle', { Text = 'Camera Aimbot', Default = false, Callback = function(v) AimSettings.Enabled = v end })
CombatGroup:AddToggle('TeamCheckToggle', { Text = 'Aimbot Team Check', Default = false, Callback = function(v) AimSettings.TeamCheck = v end })
CombatGroup:AddToggle('WallCheckToggle', { Text = 'Wall Check', Default = false, Callback = function(v) AimSettings.WallCheck = v end })
CombatGroup:AddSlider('SmoothnessSlider', { Text = 'Smoothness', Default = 0.35, Min = 0.1, Max = 1.0, Rounding = 2, Callback = function(v) AimSettings.Smoothness = v end })
CombatGroup:AddToggle('FOVEnabledToggle', { Text = 'Aimbot FOV Enabled', Default = false, Callback = function(v) AimSettings.FOVEnabled = v end })
CombatGroup:AddSlider('FOVSlider', { Text = 'Aimbot FOV Size', Default = 90, Min = 30, Max = 800, Rounding = 0, Callback = function(v) AimSettings.FOV = v end })
CombatGroup:AddLabel('Aimbot FOV Color'):AddColorPicker('FOVColorPicker', { Default = Color3.fromRGB(255, 255, 255), Callback = function(v) AimSettings.FOVColor = v end })
CombatGroup:AddToggle('ShowFOVCircleToggle', { Text = 'Show FOV Circle', Default = false, Callback = function(v) AimSettings.ShowFOVCircle = v end })
CombatGroup:AddDropdown('AimPartDropdown', { Text = 'Aim Part', Values = {'Head', 'Body', 'Legs'}, Default = 1, Callback = function(v) AimSettings.AimPart = v end })
CombatGroup:AddToggle('TriggerbotToggle', { Text = 'Triggerbot (홀드)', Default = false, Callback = function(v) AimSettings.Triggerbot = v end })
CombatGroup:AddSlider('TriggerDelaySlider', { Text = 'Trigger Delay (sec)', Default = 0.12, Min = 0.05, Max = 1.0, Rounding = 2, Callback = function(v) AimSettings.TriggerDelay = v end })

VisualGroup:AddSlider('CameraFOVSlider', { Text = 'Camera FOV (Zoom)', Default = 70, Min = 70, Max = 120, Rounding = 0, Callback = function(v) workspace.CurrentCamera.FieldOfView = v end })

TrollingGroup:AddToggle('TeleportBehindToggle', { Text = 'Teleport Behind Players', Default = false, Callback = function(v) TrollingSettings.TeleportBehind = v end })
TrollingGroup:AddToggle('TrollingTeamCheckToggle', { Text = 'Trolling Team Check', Default = false, Callback = function(v) TrollingSettings.TeamCheck = v end })

ESPGroup:AddToggle('BoxToggle', { Text = 'Box ESP', Default = false, Callback = function(v) ESPSettings.Box = v end })
ESPGroup:AddToggle('NameToggle', { Text = 'Name ESP', Default = false, Callback = function(v) ESPSettings.Name = v end })
ESPGroup:AddToggle('HealthBarToggle', { Text = 'Health Bar', Default = false, Callback = function(v) ESPSettings.HealthBar = v end })
ESPGroup:AddToggle('ChamsToggle', { Text = 'Chams', Default = false, Callback = function(v) ESPSettings.Chams = v end })
ESPGroup:AddToggle('TracerToggle', { Text = 'Tracer', Default = false, Callback = function(v) ESPSettings.Tracer = v end })
ESPGroup:AddToggle('ESPTeamCheckToggle', { Text = 'ESP Team Check', Default = false, Callback = function(v) ESPSettings.TeamCheck = v end })

ESPGroup:AddLabel('Box Color'):AddColorPicker('BoxColor', { Default = Color3.fromRGB(255, 255, 255), Callback = function(v) ESPSettings.BoxColor = v end })
ESPGroup:AddLabel('Name Color'):AddColorPicker('NameColor', { Default = Color3.fromRGB(255, 255, 255), Callback = function(v) ESPSettings.NameColor = v end })
ESPGroup:AddLabel('Chams Color'):AddColorPicker('ChamsColor', { Default = Color3.fromRGB(255, 255, 255), Callback = function(v) ESPSettings.ChamsColor = v end })
ESPGroup:AddLabel('Tracer Color'):AddColorPicker('TracerColor', { Default = Color3.fromRGB(255, 255, 255), Callback = function(v) ESPSettings.TracerColor = v end })

-- ==================== Services & Variables ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")

local ESPObjects = {}
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Transparency = 0.7

local TriggerbotHolding = false

-- ==================== Humanization Variables ====================
local CurrentAimTarget = nil          -- Aimbot 전용
local CurrentTrollingTarget = nil     -- Teleport 전용

local TargetAcquiredTime = 0
local TrackingLossTime = 0
local IsTrackingLost = false
local HumanState = "idle"             -- idle, acquiring, tracking, hesitating, correcting

local LastAimPos = nil
local AimInertia = Vector3.new(0,0,0)

-- Correction Phase
local CorrectionPhase = 0             -- 0: none, 1: overshoot, 2: reverse, 3: stabilization
local CorrectionStartTime = 0

-- Micro Jitter
local JitterTime = 0

-- Teleport Variables
local TeleportedThisCycle = {}
local LastTargetChange = 0
local TargetChangeInterval = 1.6

-- ==================== Functions ====================
local function IsSameTeam(plr)
    if not plr.Team or not LocalPlayer.Team then return false end
    return plr.Team == LocalPlayer.Team
end

local function IsVisible(targetPart)
    if not AimSettings.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true
    local result = workspace:Raycast(origin, direction, raycastParams)
    return not (result and not result.Instance:IsDescendantOf(targetPart.Parent))
end

local function GetAimPart(char)
    if AimSettings.AimPart == "Head" then return char:FindFirstChild("Head")
    elseif AimSettings.AimPart == "Body" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
    elseif AimSettings.AimPart == "Legs" then return char:FindFirstChild("LowerTorso") or char:FindFirstChild("LeftLeg") or char:FindFirstChild("RightLeg")
    end
    return char:FindFirstChild("Head")
end

local function GetClosestPlayer()
    local closest, dist = nil, math.huge
    local screenCenter = Camera.ViewportSize / 2
    local useDistanceOnly = not AimSettings.FOVEnabled

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            if AimSettings.TeamCheck and IsSameTeam(plr) then continue end
            local part = GetAimPart(plr.Character)
            if part then
                local distance = (part.Position - Camera.CFrame.Position).Magnitude
                if useDistanceOnly then
                    if distance < dist and IsVisible(part) then
                        dist = distance
                        closest = plr
                    end
                else
                    local vp, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local screenDist = (Vector2.new(vp.X, vp.Y) - screenCenter).Magnitude
                        if screenDist <= AimSettings.FOV and IsVisible(part) and screenDist < dist then
                            dist = screenDist
                            closest = plr
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function GetRandomUnusedPlayer()
    local candidates = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            if TrollingSettings.TeamCheck and IsSameTeam(plr) then continue end
            if not TeleportedThisCycle[plr] then
                table.insert(candidates, plr)
            end
        end
    end
    if #candidates == 0 then
        TeleportedThisCycle = {}
        return GetRandomUnusedPlayer()
    end
    local chosen = candidates[math.random(1, #candidates)]
    TeleportedThisCycle[chosen] = true
    return chosen
end

local function ReleaseTriggerbot()
    if TriggerbotHolding then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        TriggerbotHolding = false
    end
end

-- ==================== Improved Humanized Aimbot ====================
RunService.RenderStepped:Connect(function(dt)
    if not AimSettings.Enabled then
        ReleaseTriggerbot()
        HumanState = "idle"
        CurrentAimTarget = nil
        return
    end

    local closest = GetClosestPlayer()

    if closest ~= CurrentAimTarget then
        CurrentAimTarget = closest
        TargetAcquiredTime = tick()
        HumanState = "acquiring"
        IsTrackingLost = false
        CorrectionPhase = 0
    end

    if not CurrentAimTarget or not CurrentAimTarget.Character then
        ReleaseTriggerbot()
        HumanState = "idle"
        return
    end

    local targetPart = GetAimPart(CurrentAimTarget.Character)
    if not targetPart then return end

    local now = tick()
    local timeSinceAcquire = now - TargetAcquiredTime

    if HumanState == "acquiring" and timeSinceAcquire < (0.12 + math.random(0, 280)/1000) then
        return
    elseif HumanState == "acquiring" then
        HumanState = "tracking"
    end

    -- Tracking Loss
    if not IsTrackingLost and math.random(1, 280) == 1 then
        IsTrackingLost = true
        TrackingLossTime = now
    end

    if IsTrackingLost then
        if now - TrackingLossTime > 0.18 + math.random(0,15)/100 then
            IsTrackingLost = false
        else
            Camera.CFrame = Camera.CFrame * CFrame.Angles(0, math.random(-8,8)/300, 0)
            return
        end
    end

    -- ==================== Humanized Behavior ====================
    local targetPos = targetPart.Position

    if LastAimPos then
        AimInertia = (targetPos - LastAimPos) * 0.65
    end
    LastAimPos = targetPos

    -- Micro Jitter (비주기성 저강도)
    JitterTime = JitterTime + dt * (1.8 + math.random(-30,30)/100)
    local microJitter = Vector3.new(
        math.sin(JitterTime * 3.7) * 0.035 + (math.random(-100,100)/2800),
        math.cos(JitterTime * 2.9) * 0.028 + (math.random(-100,100)/3200),
        math.random(-80,80)/4500
    )

    -- Behavior Offset
    local behaviorOffset = Vector3.new(
        math.random(-16,16)/100,
        math.random(-20,20)/100,
        math.random(-10,10)/100
    )

    -- Multi-phase Correction
    local correctionOffset = Vector3.new(0,0,0)
    if math.random(1, 55) == 1 and CorrectionPhase == 0 then
        CorrectionPhase = 1
        CorrectionStartTime = now
        HumanState = "correcting"
    end

    if CorrectionPhase == 1 then -- Overshoot
        correctionOffset = AimInertia * (0.85 + math.random(10,60)/100)
        if now - CorrectionStartTime > 0.13 then
            CorrectionPhase = 2
            CorrectionStartTime = now
        end
    elseif CorrectionPhase == 2 then -- Reverse Correction
        correctionOffset = AimInertia * -0.55
        if now - CorrectionStartTime > 0.17 then
            CorrectionPhase = 3
            CorrectionStartTime = now
        end
    elseif CorrectionPhase == 3 then -- Stabilization
        correctionOffset = correctionOffset * 0.4
        if now - CorrectionStartTime > 0.22 then
            CorrectionPhase = 0
            HumanState = "tracking"
        end
    end

    local finalTarget = targetPos + behaviorOffset + microJitter + correctionOffset * 0.75

    local targetCFrame = CFrame.new(Camera.CFrame.Position, finalTarget)

    -- Dynamic Smoothness
    local baseSmooth = AimSettings.Smoothness
    local dynamicSmooth = baseSmooth

    if HumanState == "acquiring" then
        dynamicSmooth = baseSmooth * 0.72
    elseif HumanState == "correcting" then
        dynamicSmooth = baseSmooth * (CorrectionPhase == 1 and 1.4 or 1.1)
    elseif HumanState == "hesitating" then
        dynamicSmooth = baseSmooth * 0.42
    end

    dynamicSmooth = dynamicSmooth + (math.random(-14,14)/220)
    dynamicSmooth = math.clamp(dynamicSmooth, 0.13, 0.76)

    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, dynamicSmooth)

    -- Triggerbot
    if AimSettings.Triggerbot then
        local distance = (targetPart.Position - Camera.CFrame.Position).Magnitude
        local reactionChance = 68
        if distance < 30 then reactionChance = 89 end
        if HumanState == "hesitating" then reactionChance = 23 end
        if CorrectionPhase > 0 then reactionChance = reactionChance - 12 end

        if not TriggerbotHolding and math.random(1,100) <= reactionChance then
            task.wait(AimSettings.TriggerDelay * (0.55 + math.random(0,90)/100))
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            TriggerbotHolding = true
        end
    else
        ReleaseTriggerbot()
    end
end)

-- ==================== Teleport Behind ====================
RunService.Heartbeat:Connect(function()
    if not TrollingSettings.TeleportBehind then
        CurrentTrollingTarget = nil
        return
    end

    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

    local currentTime = tick()

    if not CurrentTrollingTarget or currentTime - LastTargetChange > TargetChangeInterval
        or not CurrentTrollingTarget.Character or not CurrentTrollingTarget.Character:FindFirstChild("Humanoid")
        or CurrentTrollingTarget.Character.Humanoid.Health <= 0 then
        
        CurrentTrollingTarget = GetRandomUnusedPlayer()
        LastTargetChange = currentTime
    end

    if CurrentTrollingTarget and CurrentTrollingTarget.Character and CurrentTrollingTarget.Character:FindFirstChild("HumanoidRootPart") then
        local root = CurrentTrollingTarget.Character.HumanoidRootPart
        local lpRoot = LocalPlayer.Character.HumanoidRootPart
        local behindCFrame = root.CFrame * CFrame.new(0, -2.8, 5.5)
        lpRoot.CFrame = behindCFrame
    end
end)

-- ==================== ESP ====================
local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end
    local Box = Drawing.new("Square"); Box.Thickness = 2; Box.Filled = false; Box.Transparency = 1
    local Name = Drawing.new("Text"); Name.Size = 14; Name.Center = true; Name.Outline = true; Name.Transparency = 1
    local Tracer = Drawing.new("Line"); Tracer.Thickness = 2; Tracer.Transparency = 1
    local HealthBG = Drawing.new("Square")
    local HealthFill = Drawing.new("Square")
    ESPObjects[player] = {Box = Box, Name = Name, Tracer = Tracer, HealthBG = HealthBG, HealthFill = HealthFill, Chams = nil}
end

local function ShouldShowESP(player)
    if ESPSettings.TeamCheck and IsSameTeam(player) then return false end
    return true
end

local function UpdateESP()
    FOVCircle.Visible = AimSettings.FOVEnabled and AimSettings.ShowFOVCircle
    FOVCircle.Radius = AimSettings.FOV
    FOVCircle.Position = Camera.ViewportSize / 2
    FOVCircle.Color = AimSettings.FOVColor

    for player, obj in pairs(ESPObjects) do
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 and ShouldShowESP(player) then
            local Root = char:FindFirstChild("HumanoidRootPart")
            local Head = char:FindFirstChild("Head")
            if Root and Head then
                local vp, OnScreen = Camera:WorldToViewportPoint(Root.Position)
                if ESPSettings.Tracer then
                    local screenCenter = Camera.ViewportSize / 2
                    local toPos = OnScreen and Vector2.new(vp.X, vp.Y) or (screenCenter + (Vector2.new(vp.X, vp.Y) - screenCenter).Unit * 1200)
                    obj.Tracer.From = screenCenter
                    obj.Tracer.To = toPos
                    obj.Tracer.Color = ESPSettings.TracerColor
                    obj.Tracer.Visible = true
                else
                    obj.Tracer.Visible = false
                end

                if OnScreen then
                    local Top = Camera:WorldToViewportPoint(Head.Position + Vector3.new(0,0.5,0))
                    local Bottom = Camera:WorldToViewportPoint(Root.Position - Vector3.new(0,3,0))
                    local Height = Bottom.Y - Top.Y
                    local Width = Height * 0.6

                    obj.Box.Size = Vector2.new(Width, Height)
                    obj.Box.Position = Vector2.new(Top.X - Width/2, Top.Y)
                    obj.Box.Color = ESPSettings.BoxColor
                    obj.Box.Visible = ESPSettings.Box

                    obj.Name.Text = player.Name
                    obj.Name.Position = Vector2.new(Top.X, Top.Y - 20)
                    obj.Name.Color = ESPSettings.NameColor
                    obj.Name.Visible = ESPSettings.Name

                    if ESPSettings.HealthBar then
                        local hpRatio = math.clamp(char.Humanoid.Health / char.Humanoid.MaxHealth, 0, 1)
                        obj.HealthBG.Size = Vector2.new(4, Height)
                        obj.HealthBG.Position = Vector2.new(Top.X - Width/2 - 8, Top.Y)
                        obj.HealthBG.Color = Color3.fromRGB(0,0,0)
                        obj.HealthBG.Visible = true

                        obj.HealthFill.Size = Vector2.new(4, Height * hpRatio)
                        obj.HealthFill.Position = Vector2.new(Top.X - Width/2 - 8, Top.Y + Height * (1 - hpRatio))
                        obj.HealthFill.Color = Color3.fromRGB(0, 255, 0)
                        obj.HealthFill.Visible = true
                    else
                        obj.HealthBG.Visible = false
                        obj.HealthFill.Visible = false
                    end
                else
                    obj.Box.Visible = false
                    obj.Name.Visible = false
                    obj.HealthBG.Visible = false
                    obj.HealthFill.Visible = false
                end

                if ESPSettings.Chams then
                    if not obj.Chams then
                        obj.Chams = Instance.new("Highlight")
                        obj.Chams.Adornee = char
                        obj.Chams.FillColor = ESPSettings.ChamsColor
                        obj.Chams.OutlineColor = ESPSettings.ChamsColor
                        obj.Chams.FillTransparency = 0.7
                        obj.Chams.Parent = char
                    end
                elseif obj.Chams then
                    obj.Chams:Destroy()
                    obj.Chams = nil
                end
            end
        else
            for _, v in pairs({obj.Box, obj.Name, obj.Tracer, obj.HealthBG, obj.HealthFill}) do
                if v then v.Visible = false end
            end
            if obj.Chams then
                obj.Chams:Destroy()
                obj.Chams = nil
            end
        end
    end
end

RunService.RenderStepped:Connect(UpdateESP)

-- ==================== Player Handling & UI ====================
local function OnPlayerAdded(plr)
    if plr == LocalPlayer then return end
    CreateESP(plr)
    plr.CharacterAdded:Connect(function() task.wait(0.4) CreateESP(plr) end)
end

for _, plr in pairs(Players:GetPlayers()) do OnPlayerAdded(plr) end
Players.PlayerAdded:Connect(OnPlayerAdded)

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddButton({Text = 'Unload', Func = function() Library:Unload() end})
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true })
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({'MenuKeybind'})
ThemeManager:SetFolder('AdvAimbotHub')
SaveManager:SetFolder('AdvAimbotHub')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()

Library.Unloaded:Connect(function()
    ReleaseTriggerbot()
    Camera.FieldOfView = 70
    for _, obj in pairs(ESPObjects) do
        for _, v in pairs(obj) do
            if typeof(v) == "Instance" then v:Destroy() end
        end
    end
end)
