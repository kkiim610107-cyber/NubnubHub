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

--서버홉 변,함수------ㅋ-ㅋ-ㅋ-ㅋㄴㅁㅇㅁㄴㅇㅁㄴㅇ-ㅁㄴㅇㅂㅈ-ㅇㄼㅈ-ㅇㅂ-

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local function ServerHop()
	TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
end

-- 움직임 관련
local SpeedEnabled = false
local SpeedValue = DefaultSpeed

local JumpEnabled = false
local JumpValue = DefaultJump

local FLYEnabled = false
local FlySpeed = 100

-- ESP 관련
local ESPEnabled = false
local ShowName = false
local TeamColorEnabled = false
local ESPColor = Color3.fromRGB(255, 255, 255)
local ESPTransparency = 0.5
local visualState = {}

--시야각 부분임
local Camera = workspace.CurrentCamera

local function SetFOV(value)
	Camera.FieldOfView = value
end

--노클립
local NoclipEnabled = false
local NoclipConnection = nil

local LEG_NAMES = {"LeftLeg", "RightLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot"}

local function IsLeg(part)
	if not part:IsA("BasePart") then return false end
	local parent = part.Parent
	if parent and parent:IsA("Accessory") then return false end
	
	for _, name in pairs(LEG_NAMES) do
		if part.Name == name then
			return true
		end
	end
	
	local root = part
	while root.Parent do
		root = root.Parent
		local humanoid = root:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local isLeg = false
			for _, legName in pairs(LEG_NAMES) do
				if part.Name == legName then
					isLeg = true
					break
				end
			end
			return isLeg
		end
	end
	return false
end

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
				if IsLeg(part) then
					part.CanCollide = false
				else
					part.CanCollide = false
				end
			end
		end
	end)
end
-- ESP
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
		text.Text = plr.DisplayName ~= plr.Name and (plr.DisplayName .. " (@" .. plr.Name .. ")") or plr.Name
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
		if plr ~= Player then
			createVisual(plr)
		end
	end
end

local function onPlayerAdded(plr)
	plr.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart", 5)
		task.wait(0.3)
		createVisual(plr)
	end)
	if plr.Character then
		createVisual(plr)
	end
end

for _, plr in ipairs(Players:GetPlayers()) do
	if plr ~= Player then
		onPlayerAdded(plr)
	end
end
Players.PlayerAdded:Connect(function(plr)
	if plr ~= Player then
		onPlayerAdded(plr)
	end
end)
Players.PlayerRemoving:Connect(function(plr)
	clearVisual(plr)
end)

-- 플라이
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

-- 캐릭터 리스폰
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
		task.wait(0.1)
		startFly()
	end
	if NoclipEnabled then
		task.wait(0.1)
		SetNoclip(true)
	end
end)

-- UI
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

local Utility = Window:Tab({
	Title = "유틸리티 탭",
	Icon = "sliders-horizontal",
	Locked = false,
})

local Scripthub = Window:Tab({
	Title = "스크립트 허브",
	Icon = "scroll-text",
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
		Default = 50,
	},
	Callback = function(value)
		FlySpeed = value
	end
})

Main:Divider()

-- ESP
Main:Toggle({
	Title = "ESP",
	Desc = "하이라이트로 사람 보이게 해줌",
	Icon = "spotlight",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		ESPEnabled = state
		refreshAllVisuals()
	end
})

Main:Toggle({
	Title = "닉네임 표시",
	Desc = "머리 위에 이름 띄워줌 (무조건 흰색)",
	Icon = "type",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		ShowName = state
		refreshAllVisuals()
	end
})

Main:Toggle({
	Title = "팀 색 ESP",
	Desc = "켜면 팀 색깔로 ESP 색 바뀜",
	Icon = "users",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		TeamColorEnabled = state
		refreshAllVisuals()
	end
})

Main:Colorpicker({
	Title = "ESP 색 정하기",
	Desc = "팀 색 꺼져있을 때 쓰는 기본 색임",
	Default = Color3.fromRGB(255, 255, 255),
	Transparency = 0,
	Locked = false,
	Callback = function(color)
		ESPColor = color
		refreshAllVisuals()
	end
})

Main:Slider({
	Title = "ESP 투명도",
	Desc = "안쪽 투명도 (1 = 완전 투명)",
	Step = 0.1,
	Value = {
		Min = 0,
		Max = 1,
		Default = 0.5,
	},
	Callback = function(value)
		ESPTransparency = value
		refreshAllVisuals()
	end
})

-- 유틸탭
local TeleportInput = Utility:Input({
	Title = "플레이어 텔레포트",
	Desc = "닉네임 앞부분만 치고 엔터 (디플닉/찐닉 둘 다 가능)",
	Placeholder = "닉네임 입력 후 엔터...",
	Value = "",
	InputIcon = "user",
	Type = "Input",
	Callback = function(text)
		text = (text or ""):match("^%s*(.-)%s*$") or ""

		if text == "" then
			return
		end

		if text == "닉넴 겹침" then
			TeleportInput:Set("")
			return
		end

		local matches = {}
		local search = string.lower(text)

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= Player then
				local uname = string.lower(plr.Name)
				local dname = string.lower(plr.DisplayName)

				if string.sub(uname, 1, #search) == search
					or string.sub(dname, 1, #search) == search then
					table.insert(matches, plr)
				end
			end
		end

		if #matches == 0 then
			return
		elseif #matches == 1 then
			local target = matches[1]
			local targetHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
			local myHRP = Character and Character:FindFirstChild("HumanoidRootPart")

			if targetHRP and myHRP then
				myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
			end
		else
			TeleportInput:Set("닉넴 겹침")
		end
	end
})

Utility:Toggle({
	Title = "노클립",
	Desc = "대충 벽통과 ㅇㅋ?",
	Icon = "hat-glasses",
	Type = "Checkbox",
	Value = false,
	Callback = function(state)
		SetNoclip(state)
	end
})

Utility:Button({
	Title = "서버 홉",
	Desc = "대충 서버 이동하는거임(같은섭 걸릴수도있음)",
	Locked = false,
	Callback = function()
		ServerHop()
	end
})

Utility:Slider({
	Title = "시야각",
	Desc = "시야각 조절하는거",
	Step = 1,
	Value = {
		Min = 10,
		Max = 120,
		Default = 70,
	},
	Callback = function(value)
		 SetFOV(value)
	end
})

--대충 그 뭐냐 스크 허브 탭

Scripthub:Button({
	Title = "눕눕 에임핵",
	Desc = "유니버설 에임핵",
	Locked = false,
	Callback = function()
		loadstring(game:HttpGet('https://raw.githubusercontent.com/kkiim610107-cyber/NubNubaAimbot/refs/heads/main/NubNubAimbot.lua'))()
	end
})

Scripthub:Button({
	Title = "눕눕 블랙홀",
	Desc = "대충 파트 끌어오는건데 자연재해가 가장 잘됨",
	Locked = false,
	Callback = function()
		loadstring(game:HttpGet('https://raw.githubusercontent.com/kkiim610107-cyber/NubNubBlackhole/refs/heads/main/NubNubBlackhole.lua'))()
	end
})

Scripthub:Button({
	Title = "칼 올킬",
	Desc = "클래식 칼만 됨",
	Locked = false,
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Luk-Script/Kil-All/main/Kill-all.lua"))()
	end
})

Scripthub:Button({
	Title = "프리즌 라이프",
	Desc = "그냥 좋은 허브임",
	Locked = false,
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/zenss555a/script/refs/heads/main/Prison-Life.lua", true))()
	end
})

Scripthub:Button({
	Title = "투명",
	Desc = "투명 핵이긴한데 안되는거 좀잇음",
	Locked = false,
	Callback = function()
		loadstring(game:HttpGet('https://pastebin.com/raw/3Rnd9rHf'))()
	end
})

Scripthub:Button({
	Title = "실행기 성능 테스트",
	Desc = "Unc,Sunc 등등 테스트",
	Locked = false,
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/GmilerlolYT/ExecutorTester/refs/heads/main/Hi"))()
	end
})
