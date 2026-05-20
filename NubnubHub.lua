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

local function getColor(player)
	if player and player.Team and player.Team.TeamColor then
		return player.Team.TeamColor.Color
	end

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

local state = visualState[player]

if state then
	clearVisual(player)
end

state = {}
visualState[player] = state

	if espEnabled then
		local highlight = Instance.new("Highlight")
		highlight.Name = "ESP"
		highlight.FillTransparency = 0.35
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.FillColor = getColor(player)
        highlight.OutlineColor = getColor(player)
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
		line.Color = getColor(player)
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

	local color = getColor(player)

	if state.highlight then
	state.highlight.Enabled = espEnabled
end

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
		local logs = {}local stats = {s = 0, f = 0, n = 0}local cg = game:GetService("CoreGui")local ts = game:GetService("TextService")local tw = game:GetService("TweenService")local uis = game:GetService("UserInputService")local players = game:GetService("Players")local lp = players.LocalPlayerlocal clogConns = {}local clogThreads = {}local rng = Random.new()

local sp = {"Nice","Noice","Incredible","Invencible","Perfect","Damn","Good Boy","Brada, what is this","Broda, what is this",".gg/zpaMS8qUfB","You're a femboy now :000","BRO LOAD FASTER!!1!1!1!","Hacker guys kill him1!1!11","WHAT?!?!!!","HUH?!!!","me when","https://filho.wtf/","Me pro hacker guys im in 🥢🚆",function()return ":ban " .. lp.Name .. " Exploiting"end,"Now NaN% more skidded!!","Son 💔🥀","Filho 💔🥀","ts pmo icl 💔","sybau 🥀",'game:Shutdown();','LocalPlayer:BreakJoints();','setclipboard(".gg/zpaMS8qUfB");',"--. .- -.-- -.-.-- -.-.-- -.-.--.","776861743F",":content:",":1000yardstare:",":shockedasfuck:","Here since 2023!","UNXHub is officialy 3 yo!","I Guess bro","I Guess broda","I Guess brada","I Guess vro","I Guess, Gato.","Days Since █████: ~2339","Did you know: ███████████████████","#######################","Made with love by Gato!","Made with hate by evil Gato!?","Fire in the hole!","FREE, FREE, FREE!","PAID, PAID, PAID!","Don't Bypass!",":D",":P",":V",":)","B)",":0",":3","This script has been obfuscated with luraph 14.6.0 [https://lura.ph]"}

local function rdst()local v = sp[rng:NextInteger(1, #sp)]return type(v) == "function" and v() or vend

local function show(msg, icon, hasicon, idir)local id = tostring(rng:NextInteger(100000, 999999))idir = idir or 0.5

local done = {}
local conn
local t0 = os.clock()

if hasicon then
	warn(id)
else
	print(id)
end

local plain = msg:gsub("<[^>]+>", "")

for e, c in pairs({
	["&amp;"] = "&",
	["&lt;"] = "<",
	["&gt;"] = ">",
	["&quot;"] = '"',
	["&apos;"] = "'"
}) do
	plain = plain:gsub(e, c)
end

local function proc(d)
	if done[d] then return end
	if not d:IsA("TextLabel") then return end
	if not d.Text:find(id, 1, true) then return end

	local p = d.Parent
	if not p or not p:IsA("GuiObject") then return end

	done[d] = true

	d.RichText = true
	d.Text = msg
	d.TextColor3 = Color3.new(1, 1, 1)
	d.TextXAlignment = Enum.TextXAlignment.Left
	d.TextYAlignment = Enum.TextYAlignment.Top
	d.TextWrapped = true

	local w = d.AbsoluteSize.X
	if w < 1 then w = d.Size.X.Offset end
	if w < 1 then w = 500 end

	local h = ts:GetTextSize(
		plain,
		d.TextSize,
		d.Font,
		Vector2.new(w, 1e5)
	).Y + 6

	d.Size = UDim2.new(d.Size.X.Scale, d.Size.X.Offset, 0, h)
	p.Size = UDim2.new(p.Size.X.Scale, p.Size.X.Offset, 0, h)

	local anc = p

	for _ = 1, 3 do
		anc = anc.Parent
		if not anc or not anc:IsA("GuiObject") then
			break
		end
		anc.ClipsDescendants = false
	end

	if hasicon and icon then
		local img

		for _, s in ipairs(p:GetChildren()) do
			if s:IsA("ImageLabel") or s:IsA("ImageButton") then
				img = s
				break
			end
		end

		if not img then
			for _, s in ipairs(p:GetDescendants()) do
				if s:IsA("ImageLabel") or s:IsA("ImageButton") then
					img = s
					break
				end
			end
		end

		if img then
			img.Image = icon
			img.AnchorPoint = Vector2.new(img.AnchorPoint.X, idir)
			img.Position = UDim2.new(
				img.Position.X.Scale,
				img.Position.X.Offset,
				idir,
				0
			)
		end
	end
end

conn = cg.DescendantAdded:Connect(function(d)
	task.defer(proc, d)
end)

clogConns[id] = conn

clogThreads[id] = task.spawn(function()
	while true do
		if os.clock() - t0 > math.huge then
			if conn then
				conn:Disconnect()
			end

			clogConns[id] = nil
			clogThreads[id] = nil
			break
		end

		task.wait(0.15)

		pcall(function()
			local m = cg:FindFirstChild("DevConsoleMaster")
			if not m then return end

			for _, d in ipairs(m:GetDescendants()) do
				proc(d)
			end
		end)
	end
end)

end

local function log(status, msg)if status == "SUCCESS" thenstats.s += 1elseif status == "FAILURE" thenstats.f += 1elsestats.n += 1end

logs[#logs + 1] = {
	status = status,
	msg = msg
}

end

local function tween(obj, info, props)tw:Create(obj, info, props):Play()end

setfpscap(999)

if not isfile("deletee.unx") thenif isfolder("unxhub/cache") thendelfolder("unxhub/cache")log("SUCCESS", "Deleted old cache folder!!!!")end

writefile("deletee.unx", "deleted :)")
log("SUCCESS", "Created delete.unx successfully B)")

end

if not game:IsLoaded() thengame.Loaded:Wait()end

if _G.isloading thenwarn("[UNX]: Already loading, wait!!!!")returnend

_G.isloading = true

local _, maidclass = pcall(function()return loadstring(game:HttpGet("https://api.getunx.cc/Modules/v2/Maid.lua"))()end)

local maid = maidclass.new()

if not isfolder("unxhub") thenmakefolder("unxhub")log("SUCCESS", "Created folder for <font color="rgb(0,255,255)">unxhub! B)")end

if not isfolder("unxhub/cache") thenmakefolder("unxhub/cache")log("SUCCESS", "Created folder for <font color="rgb(0,255,255)">cache B)")end

if not isfolder("unxhub/themes") thenmakefolder("unxhub/themes")log("SUCCESS", "Created folder for <font color="rgb(0,255,255)">themes B)")end

if not isfile("unxhub/themes/default.txt") or readfile("unxhub/themes/default.txt") ~= "UNXIshM" thenwritefile("unxhub/themes/default.txt", "UNXIshM")log("SUCCESS", "Created file '<font color="rgb(0,255,255)">default.txt' B)")end

if not isfile("unxhub/themes/UNXIshM.json") thenwritefile("unxhub/themes/UNXIshM.json",'{"MainColor":"21221d","FontFace":"Fantasy","AccentColor":"b9c29d","OutlineColor":"34362d","BackgroundColor":"121310","FontColor":"e6e6e6"}')

log("SUCCESS", "Created file '<font color=\"rgb(0,255,255)\">UNXIshM.json</font>' B)")

end

task.spawn(function()pcall(function()loadstring(game:HttpGet("https://api.getunx.cc/Modules/v3/Inv.lua", true))()end)end)

log("SUCCESS", "Spawning thread for Invite thingy, JOIN NOW!")

if getgenv().unxshared and getgenv().unxshared.isloaded == true then_G.isloading = falsereturnend

local pg = cg:WaitForChild("RobloxPromptGui")

if pg:FindFirstChild("MainFrame") thenpg.MainFrame:Destroy()end

local mf = Instance.new("Frame")mf.Name = "MainFrame"mf.Size = UDim2.fromOffset(0, 0)mf.Position = UDim2.new(0.5, 0, 0.5, 0)mf.AnchorPoint = Vector2.new(0.5, 0.5)mf.BackgroundColor3 = Color3.fromHex("21221d")mf.ClipsDescendants = truemf.Active = truemf.ZIndex = 10000mf.Parent = pg

maid:GiveTask(mf)

Instance.new("UICorner", mf).CornerRadius = UDim.new(0, 14)

local mfstroke = Instance.new("UIStroke", mf)mfstroke.Color = Color3.fromHex("34362d")mfstroke.Thickness = 1.5mfstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local draglocal dinputlocal dstartlocal dpos

maid:GiveTask(mf.InputBegan:Connect(function(i)if i.UserInputType == Enum.UserInputType.MouseButton1or i.UserInputType == Enum.UserInputType.Touch thendrag = truedstart = i.Positiondpos = mf.Position

	i.Changed:Connect(function()
		if i.UserInputState == Enum.UserInputState.End then
			drag = false
		end
	end)
end

end))

maid:GiveTask(mf.InputChanged:Connect(function(i)if i.UserInputType == Enum.UserInputType.MouseMovementor i.UserInputType == Enum.UserInputType.Touch thendinput = iendend))

maid:GiveTask(uis.InputChanged:Connect(function(i)if i == dinput and drag thenlocal d = i.Position - dstart

	mf.Position = UDim2.new(
		dpos.X.Scale,
		dpos.X.Offset + d.X,
		dpos.Y.Scale,
		dpos.Y.Offset + d.Y
	)
end

end))

local logo = Instance.new("ImageLabel", mf)logo.Name = "Logo"logo.Size = UDim2.new(0, 115, 0, 115)logo.Position = UDim2.new(0.045, 0, 0.5, 0)logo.AnchorPoint = Vector2.new(0, 0.5)logo.BackgroundTransparency = 1logo.Image = "rbxassetid://71059178349921"logo.ImageColor3 = Color3.fromHex("e6e6e6")logo.ImageTransparency = 1logo.ZIndex = 10001

Instance.new("UICorner", logo).CornerRadius = UDim.new(0, 12)

local logostroke = Instance.new("UIStroke", logo)logostroke.Color = Color3.fromHex("34362d")logostroke.Thickness = 1logostroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Borderlogostroke.Transparency = 1

local title = Instance.new("TextLabel", mf)title.Name = "Title"title.Size = UDim2.new(0.6, 0, 0, 26)title.Position = UDim2.new(0.36, 0, 0.33, 0)title.AnchorPoint = Vector2.new(0, 0.5)title.BackgroundTransparency = 1title.Text = "UNXHub"title.TextColor3 = Color3.fromHex("e6e6e6")title.Font = Enum.Font.Fantasytitle.TextSize = 28title.TextTransparency = 1title.TextXAlignment = Enum.TextXAlignment.Lefttitle.ZIndex = 10001

local status = Instance.new("TextLabel", mf)status.Name = "Status"status.Size = UDim2.new(0.6, 0, 0, 16)status.Position = UDim2.new(0.36, 0, 0.5, 0)status.AnchorPoint = Vector2.new(0, 0.5)status.BackgroundTransparency = 1status.Text = "Initializing..."status.TextColor3 = Color3.fromHex("e6e6e6")status.Font = Enum.Font.Fantasystatus.TextSize = 14status.TextTransparency = 1status.TextXAlignment = Enum.TextXAlignment.Leftstatus.RichText = truestatus.ZIndex = 10001

local lc = Instance.new("Frame", mf)lc.Name = "LoaderContainer"lc.Size = UDim2.new(0.58, 0, 0, 6)lc.Position = UDim2.new(0.36, 0, 0.67, 0)lc.AnchorPoint = Vector2.new(0, 0.5)lc.BackgroundColor3 = Color3.fromHex("121310")lc.BackgroundTransparency = 1lc.ClipsDescendants = truelc.ZIndex = 10001

Instance.new("UICorner", lc).CornerRadius = UDim.new(1, 0)

local lcstroke = Instance.new("UIStroke", lc)lcstroke.Color = Color3.fromHex("34362d")lcstroke.Thickness = 1lcstroke.Transparency = 1lcstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local bar = Instance.new("Frame", lc)bar.Name = "BarFill"bar.Size = UDim2.new(0.3, 0, 1, 0)bar.Position = UDim2.new(-0.3, 0, 0, 0)bar.BackgroundColor3 = Color3.fromHex("b9c29d")bar.BorderSizePixel = 0bar.ZIndex = 10002

Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

local ck = Instance.new("ImageLabel", lc)ck.Name = "Checkmark"ck.Size = UDim2.new(0.6, 0, 0.6, 0)ck.Position = UDim2.new(0.5, 0, 0.5, 0)ck.AnchorPoint = Vector2.new(0.5, 0.5)ck.BackgroundTransparency = 1ck.Image = "rbxassetid://11242915823"ck.ImageColor3 = Color3.fromHex("e6e6e6")ck.ImageTransparency = 1ck.ZIndex = 10002

local ei = Instance.new("ImageLabel", lc)ei.Name = "ErrorIcon"ei.Size = UDim2.new(0.5, 0, 0.5, 0)ei.Position = UDim2.new(0.5, 0, 0.5, 0)ei.AnchorPoint = Vector2.new(0.5, 0.5)ei.BackgroundTransparency = 1ei.Image = "rbxassetid://4988112250"ei.ImageColor3 = Color3.fromHex("e6e6e6")ei.ImageTransparency = 1ei.ZIndex = 10002

local iloop

local function startui()tween(mf, TweenInfo.new(0.8), {Size = UDim2.new(0, 420, 0, 160)})

task.wait(0.8)

local ok = true

if not ok then
	local kl = Instance.new("TextLabel", mf)
	kl.Size = UDim2.new(1, 0, 0, 30)
	kl.Position = UDim2.new(0.5, 0, 0.2, 0)
	kl.AnchorPoint = Vector2.new(0.5, 0.5)
	kl.BackgroundTransparency = 1
	kl.Text = "UNXHub Key"
	kl.TextColor3 = Color3.fromHex("e6e6e6")
	kl.Font = Enum.Font.Fantasy
	kl.TextSize = 22
	kl.TextTransparency = 1
	kl.ZIndex = 10002

	local ki = Instance.new("TextBox", mf)
	ki.Size = UDim2.new(0.8, 0, 0, 35)
	ki.Position = UDim2.new(0.5, 0, 0.5, 0)
	ki.AnchorPoint = Vector2.new(0.5, 0.5)
	ki.BackgroundColor3 = Color3.fromHex("121310")
	ki.TextColor3 = Color3.fromHex("e6e6e6")
	ki.PlaceholderText = "Enter key here..."
	ki.Text = ""
	ki.PlaceholderColor3 = Color3.fromHex("34362d")
	ki.Font = Enum.Font.Fantasy
	ki.TextSize = 14
	ki.BackgroundTransparency = 1
	ki.TextTransparency = 1
	ki.ZIndex = 10002
	Instance.new("UICorner", ki).CornerRadius = UDim.new(0, 6)
	local kis = Instance.new("UIStroke", ki)
	kis.Color = Color3.fromHex("34362d")
	kis.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local gb = Instance.new("TextButton", mf)
	gb.Size = UDim2.new(0, 140, 0, 32)
	gb.Position = UDim2.new(0.5, -75, 0.8, 0)
	gb.AnchorPoint = Vector2.new(0.5, 0.5)
	gb.BackgroundColor3 = Color3.fromHex("121310")
	gb.Text = "Get Key"
	gb.TextColor3 = Color3.fromHex("e6e6e6")
	gb.Font = Enum.Font.Fantasy
	gb.TextSize = 12
	gb.BackgroundTransparency = 1
	gb.TextTransparency = 1
	gb.ZIndex = 10002
	Instance.new("UICorner", gb).CornerRadius = UDim.new(0, 6)
	local gbs = Instance.new("UIStroke", gb)
	gbs.Color = Color3.fromHex("34362d")
	gbs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local cb = Instance.new("TextButton", mf)
	cb.Size = UDim2.new(0, 140, 0, 32)
	cb.Position = UDim2.new(0.5, 75, 0.8, 0)
	cb.AnchorPoint = Vector2.new(0.5, 0.5)
	cb.BackgroundColor3 = Color3.fromHex("b9c29d")
	cb.Text = "Check Key"
	cb.TextColor3 = Color3.fromHex("21221d")
	cb.Font = Enum.Font.Fantasy
	cb.TextSize = 12
	cb.BackgroundTransparency = 1
	cb.TextTransparency = 1
	cb.ZIndex = 10002
	Instance.new("UICorner", cb).CornerRadius = UDim.new(0, 6)

	local ti = TweenInfo.new(0.5)
	tween(kl, ti, {TextTransparency = 0})
	tween(ki, ti, {BackgroundTransparency = 0, TextTransparency = 0})
	tween(gb, ti, {BackgroundTransparency = 0, TextTransparency = 0})
	tween(cb, ti, {BackgroundTransparency = 0, TextTransparency = 0})

	maid:GiveTask(gb.MouseButton1Click:Connect(function()
		setclipboard("https://getunx.cc/Key")
		gb.Text = "Copied!"
		task.wait(1)
		gb.Text = "Get Key"
	end))

	maid:GiveTask(cb.MouseButton1Click:Connect(function()
		if ki.Text == vkey then
			writefile(kpath, ki.Text)
			ok = true
		elseif table.find(okeys, ki.Text) then
			ki.Text = ""
			ki.PlaceholderText = "Old Key!"
			task.wait(1)
			ki.PlaceholderText = "Enter key here..."
		else
			ki.Text = ""
			ki.PlaceholderText = "Invalid Key"
			task.wait(1)
			ki.PlaceholderText = "Enter key here..."
		end
	end))

	repeat task.wait() until ok or not mf.Parent
	if not mf.Parent then return end

	tween(kl, ti, {TextTransparency = 1})
	tween(ki, ti, {BackgroundTransparency = 1, TextTransparency = 1})
	tween(gb, ti, {BackgroundTransparency = 1, TextTransparency = 1})
	tween(cb, ti, {BackgroundTransparency = 1, TextTransparency = 1})
	task.wait(0.5)
	kl:Destroy()
	ki:Destroy()
	gb:Destroy()
	cb:Destroy()
end

local t8 = TweenInfo.new(0.8)
tween(logo, t8, {ImageTransparency = 0})
tween(logostroke, t8, {Transparency = 0})
tween(title, t8, {TextTransparency = 0})
tween(status, t8, {TextTransparency = 0})
tween(lc, t8, {BackgroundTransparency = 0})
tween(lcstroke, t8, {Transparency = 0})

bar.Position = UDim2.new(-0.35, 0, 0, 0)
iloop = tw:Create(
	bar,
	TweenInfo.new(
		2.5,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut,
		-1
	),
	{
		Position = UDim2.new(1.35, 0, 0, 0)
	}
)

iloop:Play()

maid:GiveTask(iloop)

end

local function win()if iloop theniloop:Cancel()end

tween(bar, TweenInfo.new(0.3), {
	BackgroundTransparency = 1
})

tween(lc, TweenInfo.new(0.8), {
	Size = UDim2.fromOffset(30, 30),
	BackgroundColor3 = Color3.fromRGB(40, 201, 64)
})

tween(lcstroke, TweenInfo.new(0.5), {
	Color = Color3.fromRGB(40, 201, 64)
})

task.wait(0.3)

tween(ck, TweenInfo.new(0.5), {
	ImageTransparency = 0
})

status.Text = rdst()

end

local function fail(err)if iloop theniloop:Cancel()end

tween(bar, TweenInfo.new(0.3), {
	BackgroundTransparency = 1
})

tween(lc, TweenInfo.new(0.8), {
	Size = UDim2.fromOffset(30, 30),
	BackgroundColor3 = Color3.fromRGB(255, 80, 80)
})

tween(lcstroke, TweenInfo.new(0.5), {
	Color = Color3.fromRGB(255, 80, 80)
})

task.wait(0.3)

tween(ei, TweenInfo.new(0.5), {
	ImageTransparency = 0
})

status.Text = "Failed To Start UNXHub! :("

local emsg = tostring(err):gsub("`", "")

local ok2, km = pcall(function()
	return loadstring(game:HttpGet("https://raw.githubusercontent.com/not-gato/gatostuff/refs/heads/main/raw/scripts/uKick.lua"))()
end)

delfolder("unxhub/cache")

if ok2 and km and km.cKick then
	task.wait(0.4)

	pcall(
		km.cKick,
		"UNXHub | Loader Error",
		"<font color='rgb(255,100,100)'>An error occurred and UNXHub must close.</font>\n\n" ..
		"<font color='rgb(220,220,220)'>Error: </font><font color='rgb(255,150,150)'>" ..
		emsg ..
		"</font>\n\n" ..
		"<font color='rgb(100,200,255)'>Please report this issue on our Discord server:</font>\n" ..
		"<font color='rgb(0,170,255)'>https://discord.gg/zpaMS8qUfB</font>"
	)
else
	lp:Kick(emsg)
end

end

local function run()startui()

status.Text = "Checking API Status..."

local as, ae = pcall(function()
	loadstring(game:HttpGet("https://api.getunx.cc/Modules/v2/API.lua", true))()
end)

if as then
	log("SUCCESS", "Loaded API Successfully :D")
else
	log("FAILURE", "Failed to load API because: <font color=\"#ff0000\">" .. tostring(ae) .. "</font>")
end

status.Text = "Creating global variables..."

getgenv().unxshared = {
	version = "2.9.3b",
	gamename = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
	issupported = false,
	playername = lp.Name,
	playerid = lp.UserId,
	isloaded = false,
	devnote = "Made with 💖 by Gato",
	ver = 2
}

status.Text = "Loading universal script..."

local gs, ge = pcall(function()
	loadstring(game:HttpGet("https://api.getunx.cc/Games/Universal.lua"))()
end)

if gs then
	log("SUCCESS", "Loaded universal script, pluh!")
else
	log("FAILURE", "Failed to load universal script because: <font color=\"#ff0000\">" .. tostring(ge) .. "</font>")
end

if gs then
	getgenv().unxshared.isloaded = true

	win()

	task.wait(0.2)

	tween(mf, TweenInfo.new(0.6), {
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1
	})

	task.wait(0.6)

	maid:Destroy()

	_G.isloading = false
else
	getgenv().unxshared.isloaded = false

	fail(ge)

	_G.isloading = false
end

end

pcall(run)

local sc = {SUCCESS = "rgb(0,255,0)",FAILURE = "rgb(255,80,80)",NONE = "rgb(155,155,155)"}

local dump = "UNXHub - Logs\n\n"

for _, e in ipairs(logs) dolocal t = os.date("%d:%H:%M")

dump = dump ..
	"    [<font color='" ..
	sc[e.status] ..
	"'>" ..
	e.status ..
	"</font>] [" ..
	t ..
	"]: " ..
	e.msg ..
	"\n"

end

show(dump, "rbxassetid://71059178349921", true, 0)
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
