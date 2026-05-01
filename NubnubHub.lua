local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local speedValue = 16
local jumpValue = 50
local spinSpeed = 0
local spinning = false

local infiniteJump = false -- 🔥 추가

local espEnabled = false
local showName = false
local showBackpack = false
local showTeam = false
local showTracer = false

local rainbowEnabled = false
local rainbowTime = 0
local rainbowSpeed = 0.00025

-- 색상
local function getColor()
	if rainbowEnabled then
		rainbowTime += rainbowSpeed
		return Color3.fromHSV(rainbowTime % 1, 1, 1)
	else
		return Color3.fromRGB(0,255,0)
	end
end

-- 스탯 적용
local function applyStats(char)
	local hum = char:FindFirstChild("Humanoid")
	if hum then
		hum.WalkSpeed = speedValue
		
		hum.UseJumpPower = true
		hum.JumpPower = jumpValue
		
		task.defer(function()
			if hum and hum.Parent then
				hum.JumpHeight = jumpValue / 2
			end
		end)
	end
end

-- 스핀
local function startSpin(char)
	if spinning then return end
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

-- 캐릭터 리스폰
LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(1)
	applyStats(char)
	
	if spinSpeed > 0 then
		startSpin(char)
	end
end)

-- 지속 적용
task.spawn(function()
	while true do
		task.wait(0.2)
		if LocalPlayer.Character then
			applyStats(LocalPlayer.Character)
		end
	end
end)

-- 🔥 점프 (무한 점프 토글 포함)
UIS.JumpRequest:Connect(function()
	local char = LocalPlayer.Character
	if not char then return end
	
	local hum = char:FindFirstChild("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	
	if hum and hrp then
		if infiniteJump then
			-- 무한 점프
			hrp.Velocity = Vector3.new(0, jumpValue * 2, 0)
		else
			-- 일반 점프
			if hum.FloorMaterial ~= Enum.Material.Air then
				hrp.Velocity = Vector3.new(0, jumpValue * 2, 0)
			end
		end
	end
end)

-- UI
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

-- 버튼
MainTab:CreateButton({
	Name = "인피니티 야드 실행",
	Callback = function()
		loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
	end
})

-- TP
MainTab:CreateInput({
	Name = "TP",
	PlaceholderText = "닉네임(앞부분)",
	RemoveTextAfterFocusLost = false,
	Callback = function(text)
		text = string.lower(text)
		local found = {}

		for _,p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then
				if string.find(string.lower(p.Name), text, 1, true) == 1 then
					table.insert(found, p)
				end
			end
		end

		if #found == 1 then
			local target = found[1]
			if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
				LocalPlayer.Character:MoveTo(
					target.Character.HumanoidRootPart.Position + Vector3.new(0,3,0)
				)
			end
		elseif #found > 1 then
			warn("닉네임 겹침")
		else
			warn("플레이어 없음")
		end
	end
})

-- 스피드
MainTab:CreateSlider({
	Name = "스피드",
	Range = {0,500},
	Increment = 1,
	CurrentValue = speedValue,
	Callback = function(v)
		speedValue = v
		if LocalPlayer.Character then
			applyStats(LocalPlayer.Character)
		end
	end
})

-- 점프
MainTab:CreateSlider({
	Name = "점프",
	Range = {0,500},
	Increment = 1,
	CurrentValue = jumpValue,
	Callback = function(v)
		jumpValue = v
		if LocalPlayer.Character then
			applyStats(LocalPlayer.Character)
		end
	end
})

-- 🔥 무한 점프 토글
MainTab:CreateToggle({
	Name = "무한 점프",
	CurrentValue = false,
	Callback = function(Value)
		infiniteJump = Value
	end
})
MainTab:CreateSlider({
	Name = "스핀",
	Range = {0,10000},
	Increment = 1,
	CurrentValue = 0,
	Callback = function(v)
		spinSpeed = v
		
		if v > 0 then
			if LocalPlayer.Character then
				startSpin(LocalPlayer.Character)
			end
		else
			stopSpin()
		end
	end
})

local function addESP(player)
	if player == LocalPlayer then return end
	if not player.Character then return end
	
	local char = player.Character
	local head = char:FindFirstChild("Head")
	if not head then return end
	
	if char:FindFirstChild("ESP") then return end
	
	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP"
	highlight.FillTransparency = 0.35
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = char
	
	local gui = Instance.new("BillboardGui")
	gui.Name = "ESP_GUI"
	gui.Size = UDim2.new(0,120,0,40)
	gui.StudsOffset = Vector3.new(0,2.5,0)
	gui.AlwaysOnTop = true
	gui.Parent = head
	
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1,0,1,0)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.new(1,1,1)
	text.TextStrokeColor3 = Color3.new(0,0,0)
	text.TextStrokeTransparency = 0
	text.TextScaled = false
	text.Font = Enum.Font.SourceSansBold
	text.TextSize = 14
	text.Parent = gui
	
	task.spawn(function()
		while char.Parent and espEnabled do
			local color = getColor()
			highlight.FillColor = color
			highlight.OutlineColor = color
			
			local lines = {}
			
			if showName then table.insert(lines, player.Name) end
			
			if showTeam then
				local team = player.Team and player.Team.Name or "없음"
				table.insert(lines, "Team: "..team)
			end
			
			if showBackpack then
				local bp = player:FindFirstChild("Backpack")
				if bp then
					local items = {}
					for _,v in ipairs(bp:GetChildren()) do
						table.insert(items, v.Name)
					end
					table.insert(lines, "Backpack: "..table.concat(items,", "))
				end
			end
			
			text.Text = table.concat(lines,"\n")
			
			local dist = (camera.CFrame.Position - head.Position).Magnitude
			text.TextSize = math.clamp(30/(dist/20),10,18)
			
			task.wait(0.1)
		end
	end)
end
local function removeESP(player)
	if player.Character then
		local char = player.Character
		
		local esp = char:FindFirstChild("ESP")
		if esp then esp:Destroy() end
		
		local head = char:FindFirstChild("Head")
		if head then
			local gui = head:FindFirstChild("ESP_GUI")
			if gui then gui:Destroy() end
		end
	end
end
local function createTracer(player)
	if player == LocalPlayer then return end
	
	local line = Drawing.new("Line")
	line.Thickness = 2
	line.Transparency = 1
	
	task.spawn(function()
		while showTracer do
			line.Color = getColor()
			
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local pos, onScreen = camera:WorldToViewportPoint(
					player.Character.HumanoidRootPart.Position
				)
				
				if onScreen then
					line.Visible = true
					line.From = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
					line.To = Vector2.new(pos.X, pos.Y)
				else
					line.Visible = false
				end
			else
				line.Visible = false
			end
			
			task.wait()
		end
		
		line:Remove()
	end)
end
ESPTab:CreateToggle({
	Name = "ESP",
	CurrentValue = false,
	Callback = function(v)
		espEnabled = v
		for _,p in ipairs(Players:GetPlayers()) do
			if v then addESP(p) else removeESP(p) end
		end
	end
})
ESPTab:CreateToggle({
	Name = "트레이서",
	CurrentValue = false,
	Callback = function(v)
		showTracer = v
		if v then
			for _,p in ipairs(Players:GetPlayers()) do
				createTracer(p)
			end
		end
	end
})
ESPTab:CreateToggle({
	Name = "레인보우",
	CurrentValue = false,
	Callback = function(v)
		rainbowEnabled = v
	end
})
ESPTab:CreateToggle({Name="닉네임 표시",CurrentValue=false,Callback=function(v)showName=v end})
ESPTab:CreateToggle({Name="백팩 표시",CurrentValue=false,Callback=function(v)showBackpack=v end})
ESPTab:CreateToggle({Name="팀 표시",CurrentValue=false,Callback=function(v)showTeam=v end})
local function onCharacterAdded(player,char)
	if espEnabled then task.wait(1) addESP(player) end
	if showTracer then task.wait(1) createTracer(player) end
end

for _,p in ipairs(Players:GetPlayers()) do
	p.CharacterAdded:Connect(function(c) onCharacterAdded(p,c) end)
end

Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function(c) onCharacterAdded(p,c) end)
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
		loadstring(game:HttpGet("https://apigetunx.vercel.app/UNX.lua",true))()
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
