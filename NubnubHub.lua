local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local Stats = game:GetService("Stats")
local Camera = workspace.CurrentCamera

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

local DefaultSpeed = Humanoid.WalkSpeed
local DefaultJump = Humanoid.JumpPower
local DefaultGravity = workspace.Gravity

-- Server Hop & Rejoin
local function ServerHop()
	TeleportService:Teleport(game.PlaceId, Player)
end

local function RejoinServer()
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
end

-- Movement Variables
local SpeedEnabled = false
local SpeedValue = DefaultSpeed

local JumpEnabled = false
local JumpValue = DefaultJump

local FLYEnabled = false
local FlySpeed = 100

local InfJumpEnabled = false
local InfJumpConnection = nil

local SpinEnabled = false
local SpinSpeed = 20
local SpinConnection = nil

local WallClimbEnabled = false
local WallClimbConnection = nil

local ShiftLockEnabled = false
local ShiftLockConnection = nil

-- Visual Variables
local NoFogEnabled = false
local DefaultFogEnd = Lighting.FogEnd

local RGBAuraEnabled = false
local RGBAuraConnection = nil

local BlurEffectObj = nil

-- Utility Variables
local AntiAFKEnabled = false
local AntiAFKConnection = nil

local FullbrightEnabled = false
local DefaultBrightness = Lighting.Brightness
local DefaultClockTime = Lighting.ClockTime
local DefaultGlobalShadows = Lighting.GlobalShadows

local ClickTPEnabled = false
local ClickTPConnection = nil

local SavedCFrame = nil
local SpectateTarget = nil

-- Watermark & Toggle GUI Variables
local WatermarkGui = nil
local WatermarkConnection = nil
local ToggleBtnGui = nil

-- ESP Variables
local ESPEnabled = false
local ShowName = false
local TeamColorEnabled = false
local ESPColor = Color3.fromRGB(255, 255, 255)
local ESPTransparency = 0.5
local visualState = {}

-- FOV
local function SetFOV(value)
	Camera.FieldOfView = value
end

-- Noclip
local NoclipEnabled = false
local NoclipConnection = nil

local function SetNoclip(enabled)
	NoclipEnabled = enabled
	if NoclipConnection then
		NoclipConnection:Disconnect()
		NoclipConnection = nil
	end

	if not enabled then
		local character = Player.Character
		if character then
			for _, part in pairs(character:GetDescendants()) do
				if part:IsA("BasePart") and not part:FindFirstAncestorOfClass("Accessory") then
					part.CanCollide = true
				end
			end
		end
		return
	end

	NoclipConnection = RunService.Stepped:Connect(function()
		local character = Player.Character
		if not character then return end

		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end)
end

-- Inf Jump
local function SetInfJump(enabled)
	InfJumpEnabled = enabled
	if InfJumpConnection then
		InfJumpConnection:Disconnect()
		InfJumpConnection = nil
	end

	if enabled then
		InfJumpConnection = UserInputService.JumpRequest:Connect(function()
			if InfJumpEnabled and Humanoid then
				Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	end
end

-- Spinbot
local function SetSpin(enabled)
	SpinEnabled = enabled
	if SpinConnection then
		SpinConnection:Disconnect()
		SpinConnection = nil
	end

	if enabled then
		SpinConnection = RunService.RenderStepped:Connect(function()
			local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
			if hrp and SpinEnabled then
				hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(SpinSpeed), 0)
			end
		end)
	end
end

-- Spider (Wall Climb)
local function SetWallClimb(enabled)
	WallClimbEnabled = enabled
	if WallClimbConnection then
		WallClimbConnection:Disconnect()
		WallClimbConnection = nil
	end

	if enabled then
		WallClimbConnection = RunService.RenderStepped:Connect(function()
			if WallClimbEnabled and Character and Character:FindFirstChild("HumanoidRootPart") then
				local hrp = Character.HumanoidRootPart
				local ray = Ray.new(hrp.Position, hrp.CFrame.LookVector * 3)
				local hit = workspace:FindPartOnRayWithIgnoreList(ray, {Character})
				if hit and UserInputService:IsKeyDown(Enum.KeyCode.W) then
					hrp.Velocity = Vector3.new(hrp.Velocity.X, 35, hrp.Velocity.Z)
				end
			end
		end)
	end
end

-- 시프트 락 강제 활성화
local function SetShiftLock(enabled)
	ShiftLockEnabled = enabled
	Player.DevEnableMouseLock = true
	if ShiftLockConnection then
		ShiftLockConnection:Disconnect()
		ShiftLockConnection = nil
	end
	if enabled then
		ShiftLockConnection = RunService.RenderStepped:Connect(function()
			if ShiftLockEnabled then
				Player.DevEnableMouseLock = true
			end
		end)
	end
end

-- 워크스페이스 아이템 일괄 줍기
local function PickUpAllItems()
	local char = Player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Tool") and obj:FindFirstChild("Handle") and not obj:IsDescendantOf(char) and not Players:GetPlayerFromCharacter(obj.Parent) then
			local handle = obj.Handle :: BasePart
			if firetouchinterest then
				firetouchinterest(hrp, handle, 0)
				firetouchinterest(hrp, handle, 1)
			else
				handle.CFrame = hrp.CFrame
			end
		end
	end
end

-- RGB Aura
local function SetRGBAura(enabled)
	RGBAuraEnabled = enabled
	if RGBAuraConnection then
		RGBAuraConnection:Disconnect()
		RGBAuraConnection = nil
	end

	if enabled then
		local highlight = Character:FindFirstChild("RGBAuraHL") or Instance.new("Highlight")
		highlight.Name = "RGBAuraHL"
		highlight.FillTransparency = 0.5
		highlight.OutlineTransparency = 0
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Parent = Character

		RGBAuraConnection = RunService.RenderStepped:Connect(function()
			local hue = (tick() % 3) / 3
			local color = Color3.fromHSV(hue, 1, 1)
			highlight.FillColor = color
			highlight.OutlineColor = color
		end)
	else
		local hl = Character:FindFirstChild("RGBAuraHL")
		if hl then hl:Destroy() end
	end
end

-- No Fog
local function SetNoFog(enabled)
	NoFogEnabled = enabled
	if enabled then
		Lighting.FogEnd = 999999
	else
		Lighting.FogEnd = DefaultFogEnd
	end
end

-- Blur Effect
local function SetBlurSize(size)
	if size <= 0 then
		if BlurEffectObj then BlurEffectObj:Destroy(); BlurEffectObj = nil end
	else
		if not BlurEffectObj then
			BlurEffectObj = Instance.new("BlurEffect")
			BlurEffectObj.Name = "NubBlurEffect"
			BlurEffectObj.Parent = Lighting
		end
		BlurEffectObj.Size = size
	end
end

-- Click TP
local function SetClickTP(enabled)
	ClickTPEnabled = enabled
	if ClickTPConnection then
		ClickTPConnection:Disconnect()
		ClickTPConnection = nil
	end

	if enabled then
		ClickTPConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
				local mouse = Player:GetMouse()
				local targetPos = mouse.Hit.Position
				local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
				if hrp and targetPos then
					hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
				end
			end
		end)
	end
end

-- 위치 저장 및 순간이동
local function SaveCurrentLocation()
	local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		SavedCFrame = hrp.CFrame
	end
end

local function TeleportToSavedLocation()
	local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
	if hrp and SavedCFrame then
		hrp.CFrame = SavedCFrame
	end
end

-- 파트 부수기 툴만 지급 (Hammer / Delete Tool)
local function GiveHammerTool()
	local tool = Instance.new("HopperBin")
	tool.Name = "파트 부수기"
	tool.BinType = Enum.BinType.Hammer
	tool.Parent = Player:FindFirstChildOfClass("Backpack")
end

-- Anti AFK
local function SetAntiAFK(enabled)
	AntiAFKEnabled = enabled
	if enabled then
		if not AntiAFKConnection then
			AntiAFKConnection = Player.Idled:Connect(function()
				if AntiAFKEnabled then
					VirtualUser:CaptureController()
					VirtualUser:ClickButton2(Vector2.new())
				end
			end)
		end
	else
		if AntiAFKConnection then
			AntiAFKConnection:Disconnect()
			AntiAFKConnection = nil
		end
	end
end

-- Full Bright
local function SetFullbright(enabled)
	FullbrightEnabled = enabled
	if enabled then
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 100000
	else
		Lighting.Brightness = DefaultBrightness
		Lighting.ClockTime = DefaultClockTime
		Lighting.GlobalShadows = DefaultGlobalShadows
		Lighting.FogEnd = DefaultFogEnd
	end
end

-- Spectate
local function SpectatePlayer(targetPlr)
	if targetPlr and targetPlr.Character and targetPlr.Character:FindFirstChildOfClass("Humanoid") then
		Camera.CameraSubject = targetPlr.Character:FindFirstChildOfClass("Humanoid")
		SpectateTarget = targetPlr
	else
		if Character and Character:FindFirstChildOfClass("Humanoid") then
			Camera.CameraSubject = Character:FindFirstChildOfClass("Humanoid")
		end
		SpectateTarget = nil
	end
end

-- FPS & Ping Watermark (검은색 배경 + 흰색 글씨)
local function ToggleWatermark(enabled)
	if not enabled then
		if WatermarkGui then WatermarkGui:Destroy(); WatermarkGui = nil end
		if WatermarkConnection then WatermarkConnection:Disconnect(); WatermarkConnection = nil end
		return
	end

	if WatermarkGui then return end

	WatermarkGui = Instance.new("ScreenGui")
	WatermarkGui.Name = "NubNubWatermark"
	WatermarkGui.ResetOnSpawn = false
	WatermarkGui.Parent = Player:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 170, 0, 28)
	frame.Position = UDim2.new(0, 15, 0, 15)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BorderSizePixel = 0
	frame.Parent = WatermarkGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(40, 40, 40)
	stroke.Thickness = 1
	stroke.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = 13
	label.Text = "FPS: ... | Ping: ..."
	label.Parent = frame

	local lastUpdate = 0
	WatermarkConnection = RunService.RenderStepped:Connect(function(dt)
		lastUpdate = lastUpdate + dt
		if lastUpdate >= 0.5 then
			lastUpdate = 0
			local fps = math.floor(1 / dt)
			local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
			label.Text = string.format("FPS: %d | Ping: %d ms", fps, ping)
		end
	end)
end

-- ESP System
local function getESPColor(plr)
	if TeamColorEnabled and plr and plr.Team and plr.Team.TeamColor then
		return plr.Team.TeamColor.Color
	end
	return ESPColor
end

local function clearVisual(plr)
	local state = visualState[plr]
	if not state then return end
	if state.updateConn then state.updateConn:Disconnect() end
	if state.highlight then state.highlight:Destroy() end
	if state.gui then state.gui:Destroy() end
	visualState[plr] = nil
end

local function createVisual(plr)
	if plr == Player then return end
	if not plr.Character then return end
	if not ESPEnabled and not ShowName then
		clearVisual(plr)
		return
	end

	local char = plr.Character
	local head = char:FindFirstChild("Head")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not head or not hrp then return end

	clearVisual(plr)

	local state = {}
	visualState[plr] = state

	if ESPEnabled then
		local highlight = Instance.new("Highlight")
		highlight.Name = "ESPHighlight"
		highlight.FillTransparency = ESPTransparency
		highlight.OutlineTransparency = 0
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.FillColor = getESPColor(plr)
		highlight.OutlineColor = getESPColor(plr)
		highlight.Parent = char
		state.highlight = highlight
	end

	if ShowName then
		local gui = Instance.new("BillboardGui")
		gui.Name = "ESP_Name"
		gui.Size = UDim2.new(0, 160, 0, 40)
		gui.StudsOffset = Vector3.new(0, 2.8, 0)
		gui.AlwaysOnTop = true
		gui.Parent = head

		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundTransparency = 1
		text.TextColor3 = Color3.fromRGB(255, 255, 255)
		text.TextStrokeColor3 = Color3.new(0, 0, 0)
		text.TextStrokeTransparency = 0
		text.TextScaled = false
		text.Font = Enum.Font.SourceSansBold
		text.TextSize = 14
		text.Text = plr.DisplayName ~= plr.Name and (plr.DisplayName .. " @" .. plr.Name) or plr.Name
		text.Parent = gui

		state.gui = gui
		state.text = text
	end

	state.updateConn = RunService.RenderStepped:Connect(function()
		if not plr.Character or not plr.Character.Parent then
			clearVisual(plr)
			return
		end

		local currentChar = plr.Character
		local currentHead = currentChar:FindFirstChild("Head")
		local currentHrp = currentChar:FindFirstChild("HumanoidRootPart")
		if not currentHead or not currentHrp then
			clearVisual(plr)
			return
		end

		local color = getESPColor(plr)

		if state.highlight then
			state.highlight.Enabled = ESPEnabled
			state.highlight.FillColor = color
			state.highlight.OutlineColor = color
			state.highlight.FillTransparency = ESPTransparency
		end

		if state.text then
			local dist = (Camera.CFrame.Position - currentHead.Position).Magnitude
			state.text.TextSize = math.clamp(30 / (dist / 20), 10, 18)
		end
	end)
end

local function refreshAllVisuals()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= Player then createVisual(plr) end
	end
end

local function onPlayerAdded(plr)
	plr.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart", 5)
		task.wait(0.3)
		createVisual(plr)
	end)
	if plr.Character then createVisual(plr) end
end

for _, plr in ipairs(Players:GetPlayers()) do
	if plr ~= Player then onPlayerAdded(plr) end
end
Players.PlayerAdded:Connect(function(plr)
	if plr ~= Player then onPlayerAdded(plr) end
end)
Players.PlayerRemoving:Connect(function(plr)
	clearVisual(plr)
end)

-- Fly
local flyConnection = nil
local bodyVelocity = nil
local bodyGyro = nil

local function stopFly()
	if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
	if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
	if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
	if Humanoid then Humanoid.PlatformStand = false end
end

local function startFly()
	stopFly()
	local char = Player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end

	Humanoid = hum
	Character = char
	hum.PlatformStand = true

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "NubFlyBV"
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = hrp

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.Name = "NubFlyBG"
	bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bodyGyro.P = 1e5
	bodyGyro.D = 500
	bodyGyro.Parent = hrp

	flyConnection = RunService.RenderStepped:Connect(function()
		if not FLYEnabled or not hrp or not hrp.Parent or not bodyVelocity or not bodyGyro then
			stopFly()
			return
		end

		bodyGyro.CFrame = Camera.CFrame
		local direction = Vector3.zero

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += Camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= Camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= Camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += Camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then direction -= Vector3.new(0, 1, 0) end

		if direction.Magnitude > 0 then direction = direction.Unit end
		bodyVelocity.Velocity = direction * FlySpeed
	end)
end

-- Respawn Handler
Player.CharacterAdded:Connect(function(char)
	Character = char
	Humanoid = char:WaitForChild("Humanoid")

	if SpeedEnabled then Humanoid.WalkSpeed = SpeedValue end
	if JumpEnabled then Humanoid.JumpPower = JumpValue end
	if FLYEnabled then task.wait(0.1); startFly() end
	if NoclipEnabled then task.wait(0.1); SetNoclip(true) end
	if InfJumpEnabled then SetInfJump(true) end
	if SpinEnabled then SetSpin(true) end
	if WallClimbEnabled then SetWallClimb(true) end
	if ShiftLockEnabled then SetShiftLock(true) end
	if RGBAuraEnabled then SetRGBAura(true) end
	if SpectateTarget then SpectatePlayer(SpectateTarget) end
end)

--------------------------------------------------------------------------------
-- UI Creation (WindUI)
--------------------------------------------------------------------------------
local Window = WindUI:CreateWindow({
	Title = "눕눕 허브 V2",
	Icon = "sparkles",
	Author = "내가 만듦",
	Folder = "NubNubHub",
})

-- UI 토글 버튼 (검은색 배경 + 흰색 글씨)
local function CreateUIToggleButton()
	if ToggleBtnGui then ToggleBtnGui:Destroy() end

	ToggleBtnGui = Instance.new("ScreenGui")
	ToggleBtnGui.Name = "NubNubOpenButton"
	ToggleBtnGui.ResetOnSpawn = false
	ToggleBtnGui.Parent = Player:WaitForChild("PlayerGui")

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 120, 0, 28)
	btn.Position = UDim2.new(0, 15, 0, 48)
	btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	btn.BorderSizePixel = 0
	btn.Text = "UI 열기 / 닫기"
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 13
	btn.Parent = ToggleBtnGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(40, 40, 40)
	stroke.Thickness = 1
	stroke.Parent = btn

	btn.MouseButton1Click:Connect(function()
		if Window and Window.Toggle then
			Window:Toggle()
		else
			for _, gui in ipairs(Player.PlayerGui:GetChildren()) do
				if gui:IsA("ScreenGui") and gui ~= ToggleBtnGui and (gui.Name:find("WindUI") or gui.Name:find("NubNubHub")) then
					gui.Enabled = not gui.Enabled
				end
			end
		end
	end)
end

CreateUIToggleButton()

-- 탭 생성
local Main = Window:Tab({
	Title = "메인",
	Icon = "house",
	Locked = false,
})

local Utility = Window:Tab({
	Title = "유틸리티",
	Icon = "sliders-horizontal",
	Locked = false,
})

local Visuals = Window:Tab({
	Title = "비쥬얼",
	Icon = "palette",
	Locked = false,
})

local DevTab = Window:Tab({
	Title = "개발",
	Icon = "code",
	Locked = false,
})

local Scripthub = Window:Tab({
	Title = "스크립트 허브",
	Icon = "scroll-text",
	Locked = false,
})

Main:Select()

--------------------------------------------------------------------------------
-- 1. 메인 탭 (인피니티 야드 / 이동 / 캐릭터 조작)
--------------------------------------------------------------------------------
Main:Button({
	Title = "인피니티 야드",
	Desc = "인피니티 야드 실행",
	Locked = false,
	Callback = function()
		loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
	end
})

Main:Divider()

Main:Toggle({
	Title = "스피드",
	Desc = "스피드 핵 활성화",
	Icon = "sport-shoe",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		SpeedEnabled = state
		if Humanoid then Humanoid.WalkSpeed = SpeedEnabled and SpeedValue or DefaultSpeed end
	end
})

Main:Slider({
	Title = "스피드 값",
	Desc = "스피드 값 조절",
	Step = 1,
	Value = { Min = 1, Max = 500, Default = DefaultSpeed },
	Callback = function(value)
		SpeedValue = value
		if SpeedEnabled and Humanoid then Humanoid.WalkSpeed = value end
	end
})

Main:Toggle({
	Title = "점프 파워",
	Desc = "점프 핵 활성화",
	Icon = "footprints",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		JumpEnabled = state
		if Humanoid then Humanoid.JumpPower = JumpEnabled and JumpValue or DefaultJump end
	end
})

Main:Slider({
	Title = "점프 파워 값",
	Desc = "점프 파워 조절",
	Step = 1,
	Value = { Min = 1, Max = 500, Default = DefaultJump },
	Callback = function(value)
		JumpValue = value
		if JumpEnabled and Humanoid then Humanoid.JumpPower = value end
	end
})

Main:Toggle({
	Title = "무한 점프",
	Desc = "무한 연속 점프",
	Icon = "arrow-up-circle",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		SetInfJump(state)
	end
})

Main:Toggle({
	Title = "플라이",
	Desc = "당연히 닉값대로 날라다니는 거죠",
	Icon = "plane",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		FLYEnabled = state
		if state then startFly() else stopFly() end
	end
})

Main:Slider({
	Title = "플라이 속도",
	Desc = "플라이 속도 조절",
	Step = 1,
	Value = { Min = 1, Max = 500, Default = 50 },
	Callback = function(value)
		FlySpeed = value
	end
})

Main:Toggle({
	Title = "스핀",
	Desc = "캐릭터 회전",
	Icon = "rotate-cw",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		SetSpin(state)
	end
})

Main:Slider({
	Title = "스핀 속도",
	Desc = "스핀 속도 조절",
	Step = 1,
	Value = { Min = 1, Max = 1000, Default = 10 },
	Callback = function(value)
		SpinSpeed = value
	end
})

Main:Divider()

Main:Toggle({
	Title = "시프트 락",
	Desc = "시프트 락 강제 활성화",
	Icon = "lock",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		SetShiftLock(state)
	end
})

Main:Toggle({
	Title = "벽 타기",
	Desc = "대충 벽으로 가면 올려줌",
	Icon = "arrow-up-right",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		SetWallClimb(state)
	end
})

Main:Toggle({
	Title = "Noclip",
	Desc = "벽 통과 기능",
	Icon = "hat-glasses",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		SetNoclip(state)
	end
})

Main:Divider()

Main:Button({
	Title = "자살 하기",
	Desc = "그냥 딸깍 재설정",
	Locked = false,
	Callback = function()
		if Humanoid then Humanoid.Health = 0 end
	end
})

--------------------------------------------------------------------------------
-- 2. 비주얼 탭 (화면 / ESP / 조명)
--------------------------------------------------------------------------------
Visuals:Toggle({
	Title = "ESP",
	Desc = "플레이어 외곽선 하이라이트",
	Icon = "spotlight",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		ESPEnabled = state
		refreshAllVisuals()
	end
})

Visuals:Toggle({
	Title = "Name ESP",
	Desc = "머리 위 플레이어 이름 표시",
	Icon = "type",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		ShowName = state
		refreshAllVisuals()
	end
})

Visuals:Toggle({
	Title = "Team Color ESP",
	Desc = "팀 색상으로 ESP 표시",
	Icon = "users",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		TeamColorEnabled = state
		refreshAllVisuals()
	end
})

Visuals:Colorpicker({
	Title = "ESP Color",
	Desc = "기본 색상 설정",
	Default = Color3.fromRGB(255, 255, 255),
	Transparency = 0,
	Locked = false,
	Callback = function(color)
		ESPColor = color
		refreshAllVisuals()
	end
})

Visuals:Slider({
	Title = "ESP Transparency",
	Desc = "ESP 배경 투명도 조절",
	Step = 0.1,
	Value = { Min = 0, Max = 1, Default = 0.5 },
	Callback = function(value)
		ESPTransparency = value
		refreshAllVisuals()
	end
})

Visuals:Divider()

Visuals:Toggle({
	Title = "Full Bright",
	Desc = "화면 밝게 하기",
	Icon = "sun",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		SetFullbright(state)
	end
})

Visuals:Toggle({
	Title = "No Fog",
	Desc = "맵 안개 제거",
	Icon = "cloud-off",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		SetNoFog(state)
	end
})

Visuals:Toggle({
	Title = "본인 무지개",
	Desc = "캐릭터 무지개 빛 효과",
	Icon = "sparkle",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		SetRGBAura(state)
	end
})

Visuals:Divider()

Visuals:Slider({
	Title = "시간 조절",
	Desc = "맵 시간대 변경",
	Step = 0.5,
	Value = { Min = 0, Max = 24, Default = 14 },
	Callback = function(value)
		Lighting.ClockTime = value
	end
})

Visuals:Slider({
	Title = "FOV",
	Desc = "카메라 시야각 조절",
	Step = 1,
	Value = { Min = 10, Max = 120, Default = 70 },
	Callback = function(value)
		SetFOV(value)
	end
})

Visuals:Slider({
	Title = "화면 블러",
	Desc = "화면 블러 효과 조절",
	Step = 1,
	Value = { Min = 0, Max = 30, Default = 0 },
	Callback = function(value)
		SetBlurSize(value)
	end
})

Visuals:Slider({
	Title = "Gravity",
	Desc = "맵 중력 조절",
	Step = 1,
	Value = { Min = 0, Max = 500, Default = DefaultGravity },
	Callback = function(value)
		workspace.Gravity = value
	end
})

--------------------------------------------------------------------------------
-- 3. 유틸리티 탭 (텔포 / 노클립 / 관전 / 아이템 / 안티AFK / FPS&Ping / 서버홉)
--------------------------------------------------------------------------------
Utility:Input({
	Title = "플레이어 텔레포트",
	Desc = "닉네임 입력 후 엔터 시 텔포",
	Placeholder = "닉네임 입력...",
	Value = "",
	InputIcon = "user",
	Type = "Input",
	Callback = function(text)
		text = (text or ""):match("^%s*(.-)%s*$") or ""
		if text == "" then return end

		local matches = {}
		local search = string.lower(text)

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= Player then
				local uname = string.lower(plr.Name)
				local dname = string.lower(plr.DisplayName)

				if string.sub(uname, 1, #search) == search or string.sub(dname, 1, #search) == search then
					table.insert(matches, plr)
				end
			end
		end

		if #matches == 1 then
			local target = matches[1]
			local targetHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
			local myHRP = Character and Character:FindFirstChild("HumanoidRootPart")
			if targetHRP and myHRP then
				myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
			end
		end
	end
})

Utility:Toggle({
	Title = "Click TP",
	Desc = "Ctrl + 마우스 클릭 지점으로 순간이동",
	Icon = "mouse-pointer",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		SetClickTP(state)
	end
})

Utility:Button({
	Title = "위치 저장",
	Desc = "현재 좌표 저장",
	Locked = false,
	Callback = function()
		SaveCurrentLocation()
	end
})

Utility:Button({
	Title = "저장 위치 이동",
	Desc = "저장 위치로 텔포",
	Locked = false,
	Callback = function()
		TeleportToSavedLocation()
	end
})

Utility:Divider()

Utility:Button({
	Title = "파트 부수기",
	Desc = "클라이언트",
	Locked = false,
	Callback = function()
		GiveHammerTool()
	end
})

Utility:Button({
	Title = "Item Pick Up",
	Desc = "워크스페이스 내 아이템 일괄 줍기",
	Locked = false,
	Callback = function()
		PickUpAllItems()
	end
})

Utility:Divider()

local spectateSearchPlayer = nil

Utility:Input({
	Title = "관전",
	Desc = "닉네임 입력 후 엔터 시 관전",
	Placeholder = "닉네임 입력...",
	Value = "",
	InputIcon = "eye",
	Type = "Input",
	Callback = function(text)
		text = (text or ""):match("^%s*(.-)%s*$") or ""
		if text == "" then SpectatePlayer(nil); return end

		local matches = {}
		local search = string.lower(text)

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= Player then
				local uname = string.lower(plr.Name)
				local dname = string.lower(plr.DisplayName)

				if string.sub(uname, 1, #search) == search or string.sub(dname, 1, #search) == search then
					table.insert(matches, plr)
				end
			end
		end

		if #matches == 1 then
			spectateSearchPlayer = matches[1]
			SpectatePlayer(spectateSearchPlayer)
		end
	end
})

Utility:Button({
	Title = "관전 해제",
	Desc = "내 캐릭터 시점으로 복귀",
	Locked = false,
	Callback = function()
		SpectatePlayer(nil)
	end
})

Utility:Divider()

Utility:Toggle({
	Title = "Anti AFK",
	Desc = "튕김 방지",
	Icon = "shield-check",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		SetAntiAFK(state)
	end
})

Utility:Toggle({
	Title = "FPS & Ping",
	Desc = "화면 좌측 상단 성능 표시",
	Icon = "activity",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		ToggleWatermark(state)
	end
})

Utility:Button({
	Title = "Server Hop",
	Desc = "다른 무작위 서버로 이동",
	Locked = false,
	Callback = function()
		ServerHop()
	end
})

Utility:Button({
	Title = "Rejoin",
	Desc = "현재 접속 중인 서버로 재접속",
	Locked = false,
	Callback = function()
		RejoinServer()
	end
})

--------------------------------------------------------------------------------
-- 4. 개발 탭 (Dev Tools)
--------------------------------------------------------------------------------
DevTab:Button({
	Title = "Dex",
	Desc = "맵 구조 보기",
	Locked = false,
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
	end
})

DevTab:Button({
	Title = "SimpleSpy",
	Desc = "리모트 보는거",
	Locked = false,
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"))()
	end
})

DevTab:Button({
	Title = "Cobalt",
	Desc = "리모트 보는거 더 세부화됨",
	Locked = false,
	Callback = function()
		loadstring(game:HttpGet("https://gitlab.com/upio/cobalt/-/releases/permalink/latest/downloads/Cobalt.luau"))()
	end
})

--------------------------------------------------------------------------------
-- 5. 스크립트 허브 탭
--------------------------------------------------------------------------------
Scripthub:Button({
	Title = "눕눕 에임핵",
	Desc = "유니버설 에임 스크립트",
	Locked = false,
	Callback = function()
		loadstring(game:HttpGet('https://raw.githubusercontent.com/kkiim610107-cyber/NubNubaAimbot/refs/heads/main/NubNubAimbot.lua'))()
	end
})

Scripthub:Button({
	Title = "눕눕 블랙홀",
	Desc = "오브젝트 끌어오기 스크립트",
	Locked = false,
	Callback = function()
		loadstring(game:HttpGet('https://raw.githubusercontent.com/kkiim610107-cyber/NubNubBlackhole/refs/heads/main/NubNubBlackhole.lua'))()
	end
})

Scripthub:Button({
	Title = "칼 올킬",
	Desc = "클래식 칼 전용 스크립트",
	Locked = false,
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Luk-Script/Kil-All/main/Kill-all.lua"))()
	end
})

Scripthub:Button({
	Title = "프리즌 라이프",
	Desc = "프리즌 라이프 전용 스크립트",
	Locked = false,
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/zenss555a/script/refs/heads/main/Prison-Life.lua", true))()
	end
})

Scripthub:Button({
	Title = "투명",
	Desc = "투명화 스크립트",
	Locked = false,
	Callback = function()
		loadstring(game:HttpGet('https://pastebin.com/raw/3Rnd9rHf'))()
	end
})

Scripthub:Button({
	Title = "실행기 성능 테스트",
	Desc = "실행기 성능 검사",
	Locked = false,
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/GmilerlolYT/ExecutorTester/refs/heads/main/Hi"))()
	end
})
