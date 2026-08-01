local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

local DefaultSpeed = Humanoid.WalkSpeed
local DefaultJump = Humanoid.JumpPower

-- 움직임 관련
local SpeedEnabled = false
local SpeedValue = DefaultSpeed

local JumpEnabled = false
local JumpValue = DefaultJump

local FLYEnabled = false
local FlySpeed = 100

-- ESP 관련
local ESPEnabled = false
local ESPColor = Color3.fromRGB(255, 255, 255)
local ESPTransparency = 0.5

-------------------------------------------------
-- ESP 함수
-------------------------------------------------
local function addHighlight(character)
	if not character or character:FindFirstChildOfClass("Highlight") then
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ESPHighlight"
	highlight.FillColor = ESPColor
	highlight.OutlineColor = ESPColor
	highlight.FillTransparency = ESPTransparency
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character
end

local function removeHighlight(character)
	if not character then return end
	local hl = character:FindFirstChildOfClass("Highlight")
	if hl then
		hl:Destroy()
	end
end

local function applyESPToAll()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			if ESPEnabled then
				addHighlight(plr.Character)
			else
				removeHighlight(plr.Character)
			end
		end
	end
end

local function onPlayerAdded(plr)
	plr.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart", 5)
		if ESPEnabled then
			addHighlight(char)
		end
	end)

	if plr.Character and ESPEnabled then
		addHighlight(plr.Character)
	end
end

for _, plr in ipairs(Players:GetPlayers()) do
	onPlayerAdded(plr)
end
Players.PlayerAdded:Connect(onPlayerAdded)

-------------------------------------------------
-- 플라이 함수
-------------------------------------------------
local flyConnection = nil
local bodyVelocity = nil
local bodyGyro = nil

local function stopFly()
	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end
	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end
	if bodyGyro then
		bodyGyro:Destroy()
		bodyGyro = nil
	end
	if Humanoid then
		Humanoid.PlatformStand = false
	end
end

local function startFly()
	stopFly()

	if not Character or not Humanoid then return end
	local hrp = Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	Humanoid.PlatformStand = true

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = hrp

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bodyGyro.P = 9e4
	bodyGyro.Parent = hrp

	flyConnection = RunService.Heartbeat:Connect(function()
		if not FLYEnabled or not hrp or not hrp.Parent then
			stopFly()
			return
		end

		bodyGyro.CFrame = Camera.CFrame

		local direction = Vector3.zero

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			direction += Camera.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			direction -= Camera.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			direction -= Camera.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			direction += Camera.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			direction += Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then
			direction -= Vector3.new(0, 1, 0)
		end

		if direction.Magnitude > 0 then
			direction = direction.Unit
		end

		bodyVelocity.Velocity = direction * FlySpeed
	end)
end

-------------------------------------------------
-- 캐릭터 리스폰 처리
-------------------------------------------------
Player.CharacterAdded:Connect(function(char)
	Character = char
	Humanoid = char:WaitForChild("Humanoid")

	if SpeedEnabled then
		Humanoid.WalkSpeed = SpeedValue
	end
	if JumpEnabled then
		Humanoid.JumpPower = JumpValue
	end
	if FLYEnabled then
		task.wait(0.1) -- 약간의 딜레이 후 플라이 재시작
		startFly()
	end
end)

-------------------------------------------------
-- UI
-------------------------------------------------
local Window = WindUI:CreateWindow({
	Title = "눕눕 허브 V2",
	Icon = "thumbs-up",
	Author = "내가 만듦",
	Folder = "NubNubHub",
})

local Main = Window:Tab({
	Title = "메인 탭",
	Icon = "house",
	Locked = false,
})

Main:Select()

Main:Button({
	Title = "인피니티 야드 실행",
	Desc = "Infinity Yield",
	Locked = false,
	Callback = function()
		loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
	end
})

-- 스피드
Main:Toggle({
	Title = "스피드",
	Desc = "대충 이거 켜져있어야 스피드 조절 가능 ㅇㅇ",
	Icon = "sport-shoe",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		SpeedEnabled = state
		if Humanoid then
			Humanoid.WalkSpeed = SpeedEnabled and SpeedValue or DefaultSpeed
		end
	end
})

Main:Slider({
	Title = "스피드",
	Desc = "스피드 조절하는거임",
	Step = 1,
	Value = {
		Min = 1,
		Max = 500,
		Default = DefaultSpeed,
	},
	Callback = function(value)
		SpeedValue = value
		if SpeedEnabled and Humanoid then
			Humanoid.WalkSpeed = value
		end
	end
})

-- 점프
Main:Toggle({
	Title = "점프",
	Desc = "대충 이거 켜져있어야 점프파워 조절 가능 ㅇㅇ",
	Icon = "footprints",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		JumpEnabled = state
		if Humanoid then
			Humanoid.JumpPower = JumpEnabled and JumpValue or DefaultJump
		end
	end
})

Main:Slider({
	Title = "점프 파워",
	Desc = "점프 파워 조절하는거임",
	Step = 1,
	Value = {
		Min = 1,
		Max = 500,
		Default = DefaultJump,
	},
	Callback = function(value)
		JumpValue = value
		if JumpEnabled and Humanoid then
			Humanoid.JumpPower = value
		end
	end
})

-- 플라이
Main:Toggle({
	Title = "플라이",
	Desc = "시발 당연히 날라다니는거임",
	Icon = "plane",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		FLYEnabled = state
		if state then
			startFly()
		else
			stopFly()
		end
	end
})

Main:Slider({
	Title = "플라이 속도",
	Desc = "플라이 속도 조절하는거임",
	Step = 1,
	Value = {
		Min = 1,
		Max = 500,
		Default = 100,
	},
	Callback = function(value)
		FlySpeed = value
	end
})

Main:Divider()

-- ESP
Main:Toggle({
	Title = "ESP",
	Desc = "이거 키면 하이라이트로 보여줌",
	Icon = "spotlight",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		ESPEnabled = state
		applyESPToAll()
	end
})

Main:Colorpicker({
	Title = "ESP 색 정하기",
	Desc = "색 바꾸고 토글 껐다 키면 적용됨",
	Default = Color3.fromRGB(255, 255, 255),
	Transparency = 0,
	Locked = false,
	Callback = function(color)
		ESPColor = color
	end
})

Main:Slider({
	Title = "ESP 투명도",
	Desc = "안쪽 투명도 (1 = 투명) / 토글 껐다 키면 적용",
	Step = 0.1,
	Value = {
		Min = 0,
		Max = 1,
		Default = 0.5,
	},
	Callback = function(value)
		ESPTransparency = value
	end
})
