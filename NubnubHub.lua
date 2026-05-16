local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local speedValue = 16
local jumpValue = 50
local spinSpeed = 0
local spinning = false
local infiniteJump = false

local espEnabled = false
local showName = false
local showBackpack = false
local showTeam = false
local showTracer = false

local noclipEnabled = false
local noclipConn = nil
local noclipDescConn = nil

local wallPhaseEnabled = false
local wallPhaseConn = nil
local wallPhaseDistance = 6
local wallPhaseCooldown = 0.12
local lastPhase = 0

local flyEnabled = false
local flySpeed = 60

local flyBV = nil
local flyBG = nil
local flyConn = nil
local inputBeganConn = nil
local inputEndedConn = nil
local inputState = {
	W = false,
	A = false,
	S = false,
	D = false,
	Space = false,
	Ctrl = false
}

local NOCLIP_GROUP = "NubNoClip"
local DEFAULT_GROUP = "Default"
local ESP_COLOR = Color3.fromRGB(0, 255, 0)

local visualState = {}

local function getColor()
	return ESP_COLOR
end

local function applyStats(char)
	local hum = char:FindFirstChild("Humanoid")
	if hum then
		hum.WalkSpeed = speedValue
		hum.UseJumpPower = true
		hum.JumpPower = jumpValue
	end
end

local function startSpin(char)
	if spinning then
		return
	end
	spinning = true
	local hrp = char:WaitForChild("HumanoidRootPart")
	task.spawn(function()
		while spinning and hrp and hrp.Parent do
			hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
			task.wait()
		end
	end)
end

local function stopSpin()
	spinning = false
end

pcall(function()
	PhysicsService:RegisterCollisionGroup(NOCLIP_GROUP)
end)
pcall(function()
	PhysicsService:CollisionGroupSetCollidable(NOCLIP_GROUP, DEFAULT_GROUP, false)
	PhysicsService:CollisionGroupSetCollidable(NOCLIP_GROUP, NOCLIP_GROUP, false)
end)

local function setPartNoClip(part)
	if part:IsA("BasePart") then
		part.CanCollide = false
		part.CollisionGroup = NOCLIP_GROUP
	end
end

local function setPartDefaultCollision(part)
	if part:IsA("BasePart") then
		part.CollisionGroup = DEFAULT_GROUP
	end
end

local function applyCharacterNoClip(char)
	for _, obj in ipairs(char:GetDescendants()) do
		if obj:IsA("BasePart") then
			setPartNoClip(obj)
		end
	end
end

local function restoreCharacterCollision(char)
	for _, obj in ipairs(char:GetDescendants()) do
		if obj:IsA("BasePart") then
			setPartDefaultCollision(obj)
		end
	end
end

local function startNoclip()
	if noclipConn then
		return
	end

	local char = LocalPlayer.Character
	if char then
		applyCharacterNoClip(char)
	end

	noclipConn = RunService.Stepped:Connect(function()
		if not noclipEnabled then
			return
		end
		local c = LocalPlayer.Character
		if not c then
			return
		end
		applyCharacterNoClip(c)
	end)

	if noclipDescConn then
		noclipDescConn:Disconnect()
		noclipDescConn = nil
	end

	if char then
		noclipDescConn = char.DescendantAdded:Connect(function(obj)
			if noclipEnabled and obj:IsA("BasePart") then
				setPartNoClip(obj)
			end
		end)
	end
end

local function stopNoclip()
	if noclipConn then
		noclipConn:Disconnect()
		noclipConn = nil
	end
	if noclipDescConn then
		noclipDescConn:Disconnect()
		noclipDescConn = nil
	end

	local char = LocalPlayer.Character
	if char then
		restoreCharacterCollision(char)
	end
end

local function startWallPhase()
	if wallPhaseConn then
		return
	end

	wallPhaseConn = RunService.Heartbeat:Connect(function()
		if not wallPhaseEnabled then return end

		local char = LocalPlayer.Character
		if not char then return end

		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then return end
		if hum.MoveDirection.Magnitude < 0.1 then return end

		local now = os.clock()
		if now - lastPhase < wallPhaseCooldown then return end

		local dir = hum.MoveDirection.Unit
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Blacklist
		params.FilterDescendantsInstances = {char}
		params.IgnoreWater = true

		local hit = workspace:Raycast(hrp.Position, dir * wallPhaseDistance, params)
		if hit then
			local targetPos = hit.Position + dir * 3
			hrp.CFrame = CFrame.new(targetPos, targetPos + hrp.CFrame.LookVector)
			lastPhase = now
		end
	end)
end

local function stopWallPhase()
	if wallPhaseConn then
		wallPhaseConn:Disconnect()
		wallPhaseConn = nil
	end
end

local function stopFly()
	flyEnabled = false
	if flyConn then flyConn:Disconnect() flyConn = nil end
	if inputBeganConn then inputBeganConn:Disconnect() inputBeganConn = nil end
	if inputEndedConn then inputEndedConn:Disconnect() inputEndedConn = nil end
	if flyBV then flyBV:Destroy() flyBV = nil end
	if flyBG then flyBG:Destroy() flyBG = nil end
	inputState.W = false
	inputState.A = false
	inputState.S = false
	inputState.D = false
	inputState.Space = false
	inputState.Ctrl = false
end

local function startFly()
	if flyEnabled then
		return
	end

	local char = LocalPlayer.Character
	if not char then
		return
	end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then
		return
	end

	flyEnabled = true
	hum.PlatformStand = true

	flyBV = Instance.new("BodyVelocity")
	flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	flyBV.Velocity = Vector3.zero
	flyBV.Parent = hrp

	flyBG = Instance.new("BodyGyro")
	flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	flyBG.P = 1e5
	flyBG.CFrame = camera.CFrame
	flyBG.Parent = hrp

	inputBeganConn = UIS.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.W then inputState.W = true end
		if input.KeyCode == Enum.KeyCode.A then inputState.A = true end
		if input.KeyCode == Enum.KeyCode.S then inputState.S = true end
		if input.KeyCode == Enum.KeyCode.D then inputState.D = true end
		if input.KeyCode == Enum.KeyCode.Space then inputState.Space = true end
		if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
			inputState.Ctrl = true
		end
	end)

	inputEndedConn = UIS.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.W then inputState.W = false end
		if input.KeyCode == Enum.KeyCode.A then inputState.A = false end
		if input.KeyCode == Enum.KeyCode.S then inputState.S = false end
		if input.KeyCode == Enum.KeyCode.D then inputState.D = false end
		if input.KeyCode == Enum.KeyCode.Space then inputState.Space = false end
		if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
			inputState.Ctrl = false
		end
	end)

	flyConn = RunService.RenderStepped:Connect(function()
		local currentChar = LocalPlayer.Character
		local currentHrp = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
		local currentHum = currentChar and currentChar:FindFirstChildOfClass("Humanoid")

		if not flyEnabled or not currentChar or not currentHrp or not currentHum or not flyBV or not flyBG then
			stopFly()
			if currentHum then currentHum.PlatformStand = false end
			return
		end

		local camCF = camera.CFrame
		local moveDir = Vector3.zero

		if inputState.W then moveDir += camCF.LookVector end
		if inputState.S then moveDir -= camCF.LookVector end
		if inputState.A then moveDir -= camCF.RightVector end
		if inputState.D then moveDir += camCF.RightVector end
		if inputState.Space then moveDir += Vector3.new(0, 1, 0) end
		if inputState.Ctrl then moveDir -= Vector3.new(0, 1, 0) end

		if moveDir.Magnitude > 0 then
			moveDir = moveDir.Unit
		end

		flyBV.Velocity = moveDir * flySpeed
		flyBG.CFrame = camCF
		currentHum.PlatformStand = true
	end)
end

local function wantsAnyEspVisual()
	return espEnabled or showName or showBackpack or showTeam or showTracer
end

local function clearVisual(player)
	local state = visualState[player]
	if not state then return end

	if state.updateConn then state.updateConn:Disconnect() end
	if state.highlight then state.highlight:Destroy() end
	if state.gui then state.gui:Destroy() end
	if state.line then state.line:Remove() end
	visualState[player] = nil
end

local function createVisual(player)
	if player == LocalPlayer then return end
	if not player.Character then return end
	if not wantsAnyEspVisual() then
		clearVisual(player)
		return
	end

	local char = player.Character
	local head = char:FindFirstChild("Head")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not head or not hrp then return end

	clearVisual(player)

	local state = {}
	visualState[player] = state

	if espEnabled then
		local highlight = Instance.new("Highlight")
		highlight.Name = "ESP"
		highlight.FillTransparency = 0.35
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.FillColor = getColor()
		highlight.OutlineColor = getColor()
		highlight.Parent = char
		state.highlight = highlight
	end

	if showName or showBackpack or showTeam then
		local gui = Instance.new("BillboardGui")
		gui.Name = "ESP_GUI"
		gui.Size = UDim2.new(0, 160, 0, 60)
		gui.StudsOffset = Vector3.new(0, 2.8, 0)
		gui.AlwaysOnTop = true
		gui.Parent = head

		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundTransparency = 1
		text.TextColor3 = Color3.new(1, 1, 1)
		text.TextStrokeColor3 = Color3.new(0, 0, 0)
		text.TextStrokeTransparency = 0
		text.TextScaled = false
		text.Font = Enum.Font.SourceSansBold
		text.TextSize = 14
		text.Parent = gui

		state.gui = gui
		state.text = text
	end

	if showTracer then
		local line = Drawing.new("Line")
		line.Thickness = 2
		line.Transparency = 1
		line.Color = getColor()
		line.Visible = false
		state.line = line
	end

	state.updateConn = RunService.RenderStepped:Connect(function()
		if not player.Character or not player.Character.Parent then
			clearVisual(player)
			return
		end

		local currentChar = player.Character
		local currentHead = currentChar:FindFirstChild("Head")
		local currentHrp = currentChar:FindFirstChild("HumanoidRootPart")
		if not currentHead or not currentHrp then
			clearVisual(player)
			return
		end

		local color = getColor()

		if state.highlight then
			state.highlight.FillColor = color
			state.highlight.OutlineColor = color
		end

		if state.text then
			local lines = {}

			if showName then
				table.insert(lines, player.Name)
			end

			if showTeam then
				local team = player.Team and player.Team.Name or "없음"
				table.insert(lines, "Team: " .. team)
			end

			if showBackpack then
				local bp = player:FindFirstChild("Backpack")
				if bp then
					local items = {}
					for _, v in ipairs(bp:GetChildren()) do
						table.insert(items, v.Name)
					end
					table.insert(lines, "Backpack: " .. table.concat(items, ", "))
				end
			end

			state.text.Text = table.concat(lines, "\n")
			local dist = (camera.CFrame.Position - currentHead.Position).Magnitude
			state.text.TextSize = math.clamp(30 / (dist / 20), 10, 18)
		end

		if state.line then
			state.line.Color = color
			local pos, onScreen = camera:WorldToViewportPoint(currentHrp.Position)
			if onScreen then
				state.line.Visible = true
				state.line.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
				state.line.To = Vector2.new(pos.X, pos.Y)
			else
				state.line.Visible = false
			end
		end
	end)
end

local function refreshAllVisuals()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			createVisual(p)
		end
	end
end

LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(1)
	applyStats(char)

	if spinSpeed > 0 then startSpin(char) end

	if noclipEnabled then
		stopNoclip()
		task.wait(0.1)
		startNoclip()
	end

	if flyEnabled then
		stopFly()
		task.wait(0.2)
		startFly()
	end
end)

task.spawn(function()
	while true do
		task.wait(0.2)
		local char = LocalPlayer.Character
		if char then
			applyStats(char)
		end
	end
end)

UIS.JumpRequest:Connect(function()
	if not infiniteJump then
		return
	end

	local char = LocalPlayer.Character
	if not char then return end

	local hum = char:FindFirstChild("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end

	hrp.Velocity = Vector3.new(0, jumpValue, 0)
	hum:ChangeState(Enum.HumanoidStateType.Jumping)
	hum.Jump = true
end)

local Window = Rayfield:CreateWindow({
	Name = "눕눕 허브",
	ToggleUIKeybind = "K"
})

local MainTab = Window:CreateTab("메인", nil)
MainTab:CreateSection("메인 옵션")

local ESPTab = Window:CreateTab("ESP", nil)
ESPTab:CreateSection("ESP 옵션")

local HubTab = Window:CreateTab("스크립트 허브", nil)
HubTab:CreateSection("스크립트 허브들")

local UtilityTab = Window:CreateTab("유틸", nil)
UtilityTab:CreateSection("안전 유틸리티")

MainTab:CreateButton({
	Name = "인피니티 야드 실행",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
	end
})

MainTab:CreateInput({
	Name = "TP",
	PlaceholderText = "닉네임(앞부분)",
	RemoveTextAfterFocusLost = false,
	Callback = function(text)
		text = string.lower(text)
		local found = {}

		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and string.find(string.lower(p.Name), text, 1, true) == 1 then
				table.insert(found, p)
			end
		end

		if #found == 1 then
			local target = found[1]
			if target.Character and target.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
				LocalPlayer.Character:MoveTo(target.Character.HumanoidRootPart.Position + Vector3.new(0, 3, 0))
			end
		elseif #found > 1 then
			warn("닉네임 겹침")
		else
			warn("플레이어 없음")
		end
	end
})

MainTab:CreateSlider({
	Name = "스피드",
	Range = {0, 500},
	Increment = 1,
	CurrentValue = speedValue,
	Callback = function(v)
		speedValue = v
		if LocalPlayer.Character then applyStats(LocalPlayer.Character) end
	end
})

MainTab:CreateSlider({
	Name = "점프",
	Range = {25, 100},
	Increment = 1,
	CurrentValue = jumpValue,
	Callback = function(v)
		jumpValue = v
		if LocalPlayer.Character then applyStats(LocalPlayer.Character) end
	end
})

MainTab:CreateToggle({
	Name = "무한 점프",
	CurrentValue = false,
	Callback = function(v)
		infiniteJump = v
	end
})

MainTab:CreateSlider({
	Name = "스핀",
	Range = {0, 10000},
	Increment = 1,
	CurrentValue = 0,
	Callback = function(v)
		spinSpeed = v
		if v > 0 then
			if LocalPlayer.Character then startSpin(LocalPlayer.Character) end
		else
			stopSpin()
		end
	end
})

MainTab:CreateToggle({
	Name = "노클립",
	CurrentValue = false,
	Callback = function(v)
		noclipEnabled = v
		if v then
			startNoclip()
		else
			stopNoclip()
		end
	end
})

MainTab:CreateToggle({
	Name = "벽통과 보조",
	CurrentValue = false,
	Callback = function(v)
		wallPhaseEnabled = v
		if v then
			startWallPhase()
		else
			stopWallPhase()
		end
	end
})

MainTab:CreateToggle({
	Name = "플라이",
	CurrentValue = false,
	Callback = function(v)
		if v then
			startFly()
		else
			local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			stopFly()
			if hum then hum.PlatformStand = false end
		end
	end
})

MainTab:CreateSlider({
	Name = "플라이 속도",
	Range = {10, 300},
	Increment = 1,
	CurrentValue = flySpeed,
	Callback = function(v)
		flySpeed = v
	end
})

ESPTab:CreateToggle({
	Name = "ESP 하이라이트",
	CurrentValue = false,
	Callback = function(v)
		espEnabled = v
		refreshAllVisuals()
	end
})

ESPTab:CreateToggle({
	Name = "닉네임 표시",
	CurrentValue = false,
	Callback = function(v)
		showName = v
		refreshAllVisuals()
	end
})

ESPTab:CreateToggle({
	Name = "백팩 표시",
	CurrentValue = false,
	Callback = function(v)
		showBackpack = v
		refreshAllVisuals()
	end
})

ESPTab:CreateToggle({
	Name = "팀 표시",
	CurrentValue = false,
	Callback = function(v)
		showTeam = v
		refreshAllVisuals()
	end
})

ESPTab:CreateToggle({
	Name = "트레이서",
	CurrentValue = false,
	Callback = function(v)
		showTracer = v
		refreshAllVisuals()
	end
})

local function onCharacterAdded(player)
	task.wait(1)
	createVisual(player)
end

for _, p in ipairs(Players:GetPlayers()) do
	if p ~= LocalPlayer then
		p.CharacterAdded:Connect(function()
			onCharacterAdded(p)
		end)
		createVisual(p)
	end
end

Players.PlayerAdded:Connect(function(p)
	if p == LocalPlayer then return end
	p.CharacterAdded:Connect(function()
		onCharacterAdded(p)
	end)
	createVisual(p)
end)

Players.PlayerRemoving:Connect(function(p)
	clearVisual(p)
end)

HubTab:CreateButton({
	Name = "칼 올킬 (클래식 칼)",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Luk-Script/Kil-All/main/Kill-all.lua"))()
	end
})

HubTab:CreateButton({
	Name = "에임 핵",
	Callback = function()
		loadstring(game:HttpGet("https://apigetunx.vercel.app/UNX.lua", true))()
	end
})

HubTab:CreateButton({
	Name = "한국 머더",
	Callback = function()
		loadstring(game:HttpGet("https://nil-ware.vercel.app/"))()
	end
})

HubTab:CreateButton({
	Name = "프리즌 라이프",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/zenss555a/script/refs/heads/main/Prison-Life.lua", true))()
	end
})

UtilityTab:CreateButton({
	Name = "캐릭터 리스폰",
	Callback = function()
		local char = LocalPlayer.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then hum.Health = 0 end
		end
	end
})

UtilityTab:CreateButton({
	Name = "스탯 초기화",
	Callback = function()
		speedValue = 16
		jumpValue = 50
		if LocalPlayer.Character then
			applyStats(LocalPlayer.Character)
		end
	end
})
