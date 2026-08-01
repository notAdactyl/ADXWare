getgenv().SilentKeyy = 'q'
getgenv().PredictionAmmount = 0.137

--// Main Libarys \\--
local libary = loadstring(game:HttpGet("https://raw.githubusercontent.com/imagoodpersond/puppyware/main/lib"))()
local NotifyLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/imagoodpersond/puppyware/main/notify"))()
local Notify = NotifyLibrary.Notify
--// Service Handler \\--
local GetService = setmetatable({}, {
	__index = function(self, key)
		return game:GetService(key)
	end
})
--// Services \\--
local RunService = GetService.RunService
local Players = GetService.Players
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local CurrentCamera = workspace.CurrentCamera
local UserInputService = GetService.UserInputService
local Unpack = table.unpack
local GuiInset = GetService.GuiService:GetGuiInset()
local Insert = table.insert
local Network = GetService.NetworkClient
local StarterGui = GetService.StarterGui
local tweenService = GetService.TweenService
local ReplicatedStorage = GetService.ReplicatedStorage
local http = GetService.HttpService
local lighting = GetService.Lighting
local coreGui = (gethui and gethui()) or game:GetService("CoreGui") or localplayer:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local mobsfolder = workspace.Mobs

local PlayersNameList = {}
local selectedplayer:Player = nil


-- \\ HELPERS // --

local function getPlayer(nameString)
	nameString = nameString:lower()
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1, #nameString) == nameString or p.DisplayName:lower():sub(1, #nameString) == nameString then
			return p
		end
	end
	return nil
end


local rarityColors = {
	[0] = Color3.fromRGB(180, 180, 185), -- Common
	[1] = Color3.fromRGB(100, 220, 120), -- Uncommon
	[2] = Color3.fromRGB(235, 75, 75),   -- Rare
	[3] = Color3.fromRGB(255, 160, 50),  -- Legendary
}

local itemRarities = {
	-- Legendary
	["Flamethrower"] = 3,
	["LMG"] = 3,
	["Grenade Launcher"] = 3,

	-- Rare
	["Double Barrel Shotgun"] = 2,
	["Shotgun Ammo Pack"] = 2,
	["The Stuff"] = 2,

	-- Uncommon
	["Armor Pack"] = 1,
	["AK47"] = 1,
	["SMG"] = 1,
	["Revolver"] = 1,
}


--// Get rarity from an item name
local function getItemRarity(itemName)
	local lowerName = itemName:lower()

	-- Anything containing "Blessing" is Legendary
	if lowerName:find("blessing", 1, true) then
		return 3
	end

	-- Check normal rarity list
	for itemNamePattern, rarity in pairs(itemRarities) do
		if lowerName:find(itemNamePattern:lower(), 1, true) then
			return rarity
		end
	end

	-- Anything not listed is Common
	return 0
end


--// Add rounded corners
local function corner(object, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = object
end


--// Add outline
local function stroke(object, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.Transparency = 0.25
	s.Parent = object
end


--// Create a text label
local function label(parent, text, size, position, textSize, color)
	local l = Instance.new("TextLabel")

	l.Size = size
	l.Position = position
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = color or Color3.fromRGB(230, 230, 235)
	l.Font = Enum.Font.Gotham
	l.TextSize = textSize or 13
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent

	return l
end


--// Create an item card
local function createItemCard(parent, item)
	local rarity = getItemRarity(item.name)
	local rarityColor = rarityColors[rarity]

	-- Card
	local card = Instance.new("Frame")
	card.Name = item.name
	card.Size = UDim2.new(1, -6, 0, 54)

	card.BackgroundColor3 = item.equipped
		and Color3.fromRGB(32, 45, 37)
		or Color3.fromRGB(26, 26, 32)

	card.BorderSizePixel = 0
	card.Parent = parent

	corner(card, 7)

	stroke(
		card,
		item.equipped
			and Color3.fromRGB(65, 120, 80)
			or Color3.fromRGB(43, 43, 52)
	)

	-- Rarity indicator
	local indicator = Instance.new("Frame")
	indicator.Size = UDim2.fromOffset(3, 34)
	indicator.Position = UDim2.fromOffset(8, 10)
	indicator.BackgroundColor3 = rarityColor
	indicator.BorderSizePixel = 0
	indicator.Parent = card

	corner(indicator, 3)

	-- Item name
	label(
		card,
		item.name,
		UDim2.new(1, -125, 0, 22),
		UDim2.fromOffset(20, 6),
		13,
		rarityColor
	)

	-- Description
	label(
		card,
		item.equipped and "Currently equipped" or "Stored in backpack",
		UDim2.new(1, -125, 0, 16),
		UDim2.fromOffset(20, 30),
		10,
		Color3.fromRGB(120, 120, 135)
	)

	-- Rarity badge
	local rarityNames = {
		[0] = "COMMON",
		[1] = "UNCOMMON",
		[2] = "RARE",
		[3] = "LEGENDARY",
	}

	local rarityName = rarityNames[rarity]

	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.fromOffset(
		rarity == 3 and 82
			or rarity == 2 and 55
			or rarity == 1 and 72
			or 62,
		22
	)

	badge.Position = UDim2.new(1, -10, 0.5, 0)
	badge.AnchorPoint = Vector2.new(1, 0.5)

	badge.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
	badge.BorderSizePixel = 0
	badge.Text = rarityName
	badge.TextColor3 = rarityColor
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 8
	badge.Parent = card

	corner(badge, 5)

	-- Equipped indicator
	if item.equipped then
		badge.Text = "EQUIPPED"
		badge.TextColor3 = Color3.fromRGB(150, 255, 170)
		badge.BackgroundColor3 = Color3.fromRGB(45, 75, 52)
	end

	return card
end


--// =========================
--// Backpack UI
--// =========================

local function showBackpackUI(targetPlayer)
	-- Remove existing UI
	local existing = coreGui:FindFirstChild("BackpackViewerUI")

	if existing then
		existing:Destroy()
	end

	-- ScreenGui
	local sg = Instance.new("ScreenGui")
	sg.Name = "BackpackViewerUI"
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = coreGui


	--// Main window
	local frame = Instance.new("Frame")

	frame.Size = UDim2.fromOffset(400, 490)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)

	frame.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
	frame.BorderSizePixel = 0

	frame.Active = true
	frame.Draggable = true

	frame.Parent = sg

	corner(frame, 10)
	stroke(frame, Color3.fromRGB(70, 70, 82))


	--// Header
	local header = Instance.new("Frame")

	header.Size = UDim2.new(1, 0, 0, 60)
	header.BackgroundColor3 = Color3.fromRGB(29, 29, 36)
	header.BorderSizePixel = 0

	header.Parent = frame

	corner(header, 10)


	-- Accent line
	local accent = Instance.new("Frame")

	accent.Size = UDim2.new(1, 0, 0, 2)
	accent.Position = UDim2.new(0, 0, 1, -2)

	accent.BackgroundColor3 = Color3.fromRGB(220, 80, 100)
	accent.BorderSizePixel = 0

	accent.Parent = header


	-- Title
	label(
		header,
		targetPlayer.Name,
		UDim2.new(1, -60, 0, 25),
		UDim2.fromOffset(15, 7),
		16,
		Color3.fromRGB(245, 245, 248)
	)


	-- Subtitle
	label(
		header,
		"Backpack contents",
		UDim2.new(1, -60, 0, 18),
		UDim2.fromOffset(15, 32),
		10,
		Color3.fromRGB(145, 145, 158)
	)


	--// Close button
	local close = Instance.new("TextButton")

	close.Size = UDim2.fromOffset(32, 32)
	close.Position = UDim2.new(1, -42, 0, 14)

	close.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
	close.BorderSizePixel = 0

	close.Text = "×"
	close.TextColor3 = Color3.fromRGB(220, 220, 225)
	close.TextSize = 22
	close.Font = Enum.Font.GothamMedium

	close.AutoButtonColor = false
	close.Parent = header

	corner(close, 7)


	-- Close hover
	close.MouseEnter:Connect(function()
		close.BackgroundColor3 = Color3.fromRGB(180, 55, 75)
		close.TextColor3 = Color3.fromRGB(255, 255, 255)
	end)

	close.MouseLeave:Connect(function()
		close.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
		close.TextColor3 = Color3.fromRGB(220, 220, 225)
	end)

	close.MouseButton1Click:Connect(function()
		sg:Destroy()
	end)


	--// Scrolling frame
	local scroll = Instance.new("ScrollingFrame")

	scroll.Size = UDim2.new(1, -20, 1, -75)
	scroll.Position = UDim2.fromOffset(10, 65)

	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0

	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = Color3.fromRGB(220, 80, 100)

	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

	scroll.Parent = frame


	-- Padding
	local padding = Instance.new("UIPadding")

	padding.PaddingTop = UDim.new(0, 2)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 2)
	padding.PaddingRight = UDim.new(0, 2)

	padding.Parent = scroll


	-- Layout
	local layout = Instance.new("UIListLayout")

	layout.Padding = UDim.new(0, 7)
	layout.SortOrder = Enum.SortOrder.LayoutOrder

	layout.Parent = scroll


	--// Get items
	local backpack = targetPlayer:FindFirstChild("Backpack")
	local character = targetPlayer.Character

	local items = {}


	-- Equipped items
	if character then
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Tool") or item:IsA("HopperBin") then
				table.insert(items, {
					name = item.Name,
					equipped = true
				})
			end
		end
	end


	-- Backpack items
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") or item:IsA("HopperBin") then
				table.insert(items, {
					name = item.Name,
					equipped = false
				})
			end
		end
	end


	--// Empty inventory
	if #items == 0 then

		local empty = Instance.new("Frame")

		empty.Size = UDim2.new(1, -6, 0, 110)
		empty.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
		empty.BorderSizePixel = 0

		empty.Parent = scroll

		corner(empty, 8)
		stroke(empty, Color3.fromRGB(43, 43, 52))


		label(
			empty,
			"◇",
			UDim2.new(1, 0, 0, 40),
			UDim2.fromOffset(0, 20),
			28,
			Color3.fromRGB(90, 90, 105)
		).TextXAlignment = Enum.TextXAlignment.Center


		local emptyText = label(
			empty,
			"Inventory is empty",
			UDim2.new(1, 0, 0, 25),
			UDim2.fromOffset(0, 65),
			13,
			Color3.fromRGB(145, 145, 158)
		)

		emptyText.TextXAlignment = Enum.TextXAlignment.Center

	else

		--// Sort items by rarity
		table.sort(items, function(a, b)
			local rarityA = getItemRarity(a.name)
			local rarityB = getItemRarity(b.name)

			-- Higher rarity first
			if rarityA ~= rarityB then
				return rarityA > rarityB
			end

			-- Equipped items first within the same rarity
			if a.equipped ~= b.equipped then
				return a.equipped
			end

			-- Alphabetical within the same rarity
			return a.name:lower() < b.name:lower()
		end)

		--// Create item cards
		for index, item in ipairs(items) do
			local card = createItemCard(scroll, item)
			card.LayoutOrder = index
		end

	end


	--// Update scroll size
	local function updateCanvas()
		scroll.CanvasSize = UDim2.new(
			0,
			0,
			0,
			layout.AbsoluteContentSize.Y + 12
		)
	end

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

	updateCanvas()
end



--// =========================
--// Inventory Statistics
--// =========================

local function getPlayerInventoryStats(player)
	local stats = {
		total = 0,
		common = 0,
		uncommon = 0,
		rare = 0,
		legendary = 0,
		score = 0
	}

	local items = {}

	-- Equipped items
	if player.Character then
		for _, item in ipairs(player.Character:GetChildren()) do
			if item:IsA("Tool") or item:IsA("HopperBin") then
				table.insert(items, item)
			end
		end
	end

	-- Backpack items
	local backpack = player:FindFirstChild("Backpack")

	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") or item:IsA("HopperBin") then
				table.insert(items, item)
			end
		end
	end

	-- Calculate stats
	for _, item in ipairs(items) do
		local rarity = getItemRarity(item.Name)

		stats.total += 1

		if rarity == 0 then
			stats.common += 1
			stats.score += 1

		elseif rarity == 1 then
			stats.uncommon += 1
			stats.score += 2

		elseif rarity == 2 then
			stats.rare += 1
			stats.score += 4

		elseif rarity == 3 then
			stats.legendary += 1
			stats.score += 8
		end
	end

	return stats
end


--// =========================
--// Leaderboard UI
--// =========================

local function showInventoryLeaderboard()
	local existing = coreGui:FindFirstChild("InventoryLeaderboardUI")

	if existing then
		existing:Destroy()
	end

	local sg = Instance.new("ScreenGui")
	sg.Name = "InventoryLeaderboardUI"
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = coreGui


	--// Main window
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(500, 560)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Draggable = true
	frame.Parent = sg

	corner(frame, 10)
	stroke(frame, Color3.fromRGB(70, 70, 82))


	--// Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 64)
	header.BackgroundColor3 = Color3.fromRGB(29, 29, 36)
	header.BorderSizePixel = 0
	header.Parent = frame

	corner(header, 10)


	-- Accent
	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(1, 0, 0, 2)
	accent.Position = UDim2.new(0, 0, 1, -2)
	accent.BackgroundColor3 = Color3.fromRGB(220, 80, 100)
	accent.BorderSizePixel = 0
	accent.Parent = header


	label(
		header,
		"ITEM LEADERBOARD",
		UDim2.new(1, -60, 0, 25),
		UDim2.fromOffset(15, 8),
		16,
		Color3.fromRGB(245, 245, 248)
	)


	label(
		header,
		"Server inventory rankings",
		UDim2.new(1, -60, 0, 18),
		UDim2.fromOffset(15, 34),
		10,
		Color3.fromRGB(145, 145, 158)
	)


	--// Close button
	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(32, 32)
	close.Position = UDim2.new(1, -42, 0, 16)
	close.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
	close.BorderSizePixel = 0
	close.Text = "×"
	close.TextColor3 = Color3.fromRGB(220, 220, 225)
	close.TextSize = 22
	close.Font = Enum.Font.GothamMedium
	close.AutoButtonColor = false
	close.Parent = header

	corner(close, 7)

	close.MouseEnter:Connect(function()
		close.BackgroundColor3 = Color3.fromRGB(180, 55, 75)
		close.TextColor3 = Color3.fromRGB(255, 255, 255)
	end)

	close.MouseLeave:Connect(function()
		close.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
		close.TextColor3 = Color3.fromRGB(220, 220, 225)
	end)

	close.MouseButton1Click:Connect(function()
		sg:Destroy()
	end)


	--// Sort buttons
	local tabs = Instance.new("Frame")
	tabs.Size = UDim2.new(1, -20, 0, 42)
	tabs.Position = UDim2.fromOffset(10, 74)
	tabs.BackgroundTransparency = 1
	tabs.Parent = frame


	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabLayout.Padding = UDim.new(0, 5)
	tabLayout.Parent = tabs


	local currentMode = "rarity"


	local modes = {
		{
			id = "rarity",
			name = "RARITY"
		},
		{
			id = "total",
			name = "TOTAL"
		},
		{
			id = "legendary",
			name = "LEGENDARY"
		},
		{
			id = "rare",
			name = "RARE"
		},
		{
			id = "uncommon",
			name = "UNCOMMON"
		},
		{
			id = "score",
			name = "SCORE"
		}
	}


	local buttons = {}


	--// Content
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -20, 1, -130)
	scroll.Position = UDim2.fromOffset(10, 125)
	scroll.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = Color3.fromRGB(220, 80, 100)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Parent = frame

	corner(scroll, 8)
	stroke(scroll, Color3.fromRGB(45, 45, 54))


	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = scroll


	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll


	--// Build leaderboard
	local function refreshLeaderboard()
		-- Clear old entries
		for _, child in ipairs(scroll:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end


		-- Gather players
		local playerData = {}

		for _, player in ipairs(Players:GetPlayers()) do
			local stats = getPlayerInventoryStats(player)

			table.insert(playerData, {
				player = player,
				stats = stats
			})
		end


		-- Sort
		table.sort(playerData, function(a, b)
			local sa = a.stats
			local sb = b.stats

			if currentMode == "total" then
				if sa.total ~= sb.total then
					return sa.total > sb.total
				end

			elseif currentMode == "legendary" then
				if sa.legendary ~= sb.legendary then
					return sa.legendary > sb.legendary
				end

			elseif currentMode == "rare" then
				if sa.rare ~= sb.rare then
					return sa.rare > sb.rare
				end

			elseif currentMode == "uncommon" then
				if sa.uncommon ~= sb.uncommon then
					return sa.uncommon > sb.uncommon
				end

			elseif currentMode == "score" then
				if sa.score ~= sb.score then
					return sa.score > sb.score
				end

			else
				-- Rarity ranking:
				-- Legendary > Rare > Uncommon > Common
				if sa.legendary ~= sb.legendary then
					return sa.legendary > sb.legendary
				end

				if sa.rare ~= sb.rare then
					return sa.rare > sb.rare
				end

				if sa.uncommon ~= sb.uncommon then
					return sa.uncommon > sb.uncommon
				end
			end

			-- Total is the secondary sort
			if sa.total ~= sb.total then
				return sa.total > sb.total
			end

			return a.player.Name:lower() < b.player.Name:lower()
		end)


		--// Create entries
		for index, data in ipairs(playerData) do
			local player = data.player
			local stats = data.stats

			local entry = Instance.new("Frame")
			entry.Size = UDim2.new(1, 0, 0, 76)
			entry.BackgroundColor3 = index <= 3
				and Color3.fromRGB(31, 31, 39)
				or Color3.fromRGB(25, 25, 30)
			entry.BorderSizePixel = 0
			entry.LayoutOrder = index
			entry.Parent = scroll

			corner(entry, 7)

			stroke(
				entry,
				index == 1
					and Color3.fromRGB(255, 160, 50)
					or Color3.fromRGB(43, 43, 52)
			)


			-- Rank
			local rankColor = index == 1
				and Color3.fromRGB(255, 190, 70)
				or index == 2
				and Color3.fromRGB(190, 190, 200)
				or index == 3
				and Color3.fromRGB(190, 130, 90)
				or Color3.fromRGB(120, 120, 135)


			local rank = label(
				entry,
				"#" .. index,
				UDim2.fromOffset(45, 30),
				UDim2.fromOffset(10, 23),
				16,
				rankColor
			)

			rank.Font = Enum.Font.GothamBold


			-- Player name
			local name = label(
				entry,
				player.Name,
				UDim2.new(1, -240, 0, 22),
				UDim2.fromOffset(58, 8),
				13,
				Color3.fromRGB(235, 235, 240)
			)

			name.Font = Enum.Font.GothamBold


			-- Stats line
			label(
				entry,
				string.format(
					"%d total  •  %d legendary  •  %d rare  •  %d uncommon",
					stats.total,
					stats.legendary,
					stats.rare,
					stats.uncommon
				),
				UDim2.new(1, -70, 0, 18),
				UDim2.fromOffset(58, 34),
				10,
				Color3.fromRGB(125, 125, 140)
			)


			-- Score
			local scoreText

			if currentMode == "total" then
				scoreText = tostring(stats.total)

			elseif currentMode == "legendary" then
				scoreText = tostring(stats.legendary)

			elseif currentMode == "rare" then
				scoreText = tostring(stats.rare)

			elseif currentMode == "uncommon" then
				scoreText = tostring(stats.uncommon)

			elseif currentMode == "score" then
				scoreText = tostring(stats.score) .. " pts"

			else
				scoreText = string.format(
					"%d / %d / %d",
					stats.legendary,
					stats.rare,
					stats.uncommon
				)
			end


			local score = label(
				entry,
				scoreText,
				UDim2.fromOffset(150, 28),
				UDim2.new(1, -160, 0.5, -14),
				14,
				Color3.fromRGB(220, 220, 225)
			)

			score.TextXAlignment = Enum.TextXAlignment.Right
			score.Font = Enum.Font.GothamBold
		end


		scroll.CanvasSize = UDim2.new(
			0,
			0,
			0,
			layout.AbsoluteContentSize.Y + 16
		)
	end


	--// Create tabs
	for _, mode in ipairs(modes) do
		local button = Instance.new("TextButton")

		button.Size = UDim2.fromOffset(72, 34)
		button.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
		button.BorderSizePixel = 0

		button.Text = mode.name
		button.TextColor3 = Color3.fromRGB(150, 150, 160)

		button.Font = Enum.Font.GothamBold
		button.TextSize = 8

		button.AutoButtonColor = false
		button.Parent = tabs

		corner(button, 6)

		buttons[mode.id] = button


		button.MouseButton1Click:Connect(function()
			currentMode = mode.id

			for id, otherButton in pairs(buttons) do
				if id == currentMode then
					otherButton.BackgroundColor3 = Color3.fromRGB(220, 80, 100)
					otherButton.TextColor3 = Color3.fromRGB(255, 255, 255)
				else
					otherButton.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
					otherButton.TextColor3 = Color3.fromRGB(150, 150, 160)
				end
			end

			refreshLeaderboard()
		end)
	end


	-- Select default tab
	buttons.rarity.BackgroundColor3 = Color3.fromRGB(220, 80, 100)
	buttons.rarity.TextColor3 = Color3.fromRGB(255, 255, 255)


	--// Initial population
	refreshLeaderboard()


	--// Automatically refresh when players join/leave
	local connections = {}

	connections[#connections + 1] = Players.PlayerAdded:Connect(function()
		if sg.Parent then
			refreshLeaderboard()
		end
	end)

	connections[#connections + 1] = Players.PlayerRemoving:Connect(function()
		if sg.Parent then
			refreshLeaderboard()
		end
	end)


	-- Clean up connections when UI closes
	sg.Destroying:Connect(function()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end)
end



-- \\ ESP // --

--// =========================
--// SETTINGS
--// =========================

local AdxSettings = {
	pESP = {
		Enabled = false,
		ShowBounty = false,
		ShowHealth = false,
		ShowDistance = false,
		Chams = false,
	},

	mESP = {
		Enabled = false,
		Outline = false,
		Distance = false,
		Health = false,
		Value = false,
		OutlineColor = Color3.fromRGB(255, 255, 255)
	},

	CFrameSpeed = {
		Enabled = false,
		Speed = 1,
		Keybind = Enum.KeyCode.V
	},
}


--// =========================
--// ESP STORAGE
--// =========================

local PlayerESP = {}
local MobESP = {}

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ADXWareESP"
ESPFolder.Parent = coreGui


--// =========================
--// UTILITIES
--// =========================

local function getCharacterRoot(character)
	return character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
end


local function getDistanceFromLocal(character)
	local localCharacter = Players.LocalPlayer.Character

	if not localCharacter then
		return nil
	end

	local localRoot = getCharacterRoot(localCharacter)
	local targetRoot = getCharacterRoot(character)

	if not localRoot or not targetRoot then
		return nil
	end

	return math.floor((localRoot.Position - targetRoot.Position).Magnitude)
end


local function getMobValue(model)
	-- Look for a Value object named "Value"
	local valueObject = model:FindFirstChild("Value", true)

	if valueObject then
		if valueObject:IsA("NumberValue")
			or valueObject:IsA("IntValue")
			or valueObject:IsA("StringValue") then

			return tostring(valueObject.Value)
		end
	end

	-- Also check attributes
	local attributeValue = model:GetAttribute("Value")

	if attributeValue ~= nil then
		return tostring(attributeValue)
	end

	return nil
end


--// =========================
--// PLAYER ESP
--// =========================

local function removePlayerESP(player)
	local data = PlayerESP[player]

	if not data then
		return
	end

	if data.highlight then
		data.highlight:Destroy()
	end

	if data.billboard then
		data.billboard:Destroy()
	end

	PlayerESP[player] = nil
end


local function createPlayerESP(player)
	if player == Players.LocalPlayer then
		return
	end

	removePlayerESP(player)

	local character = player.Character

	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return
	end

	local root = getCharacterRoot(character)

	if not root then
		return
	end

	local data = {}
	PlayerESP[player] = data


	--// Chams
	local highlight = Instance.new("Highlight")
	highlight.Name = "ADX_PlayerChams"
	highlight.Adornee = character
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = Color3.fromRGB(244, 95, 115)
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.75
	highlight.OutlineTransparency = 0
	highlight.Enabled = AdxSettings.pESP.Enabled
		and AdxSettings.pESP.Chams

	highlight.Parent = ESPFolder

	data.highlight = highlight


	--// Billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ADX_PlayerESP"
	billboard.Adornee = root
	billboard.Size = UDim2.fromOffset(220, 80)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Enabled = AdxSettings.pESP.Enabled
	billboard.Parent = ESPFolder

	data.billboard = billboard


	local container = Instance.new("Frame")
	container.Size = UDim2.fromScale(1, 1)
	container.BackgroundTransparency = 1
	container.Parent = billboard


	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container


	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 18)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = player.DisplayName ~= player.Name
		and player.DisplayName .. " [" .. player.Name .. "]"
		or player.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 13
	nameLabel.LayoutOrder = 1
	nameLabel.Parent = container

	data.nameLabel = nameLabel


	-- Info
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, 0, 0, 16)
	infoLabel.BackgroundTransparency = 1
	infoLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	infoLabel.TextStrokeTransparency = 0
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.TextSize = 11
	infoLabel.LayoutOrder = 2
	infoLabel.Parent = container

	data.infoLabel = infoLabel


	--// Update function
	local function update()
		if not character.Parent then
			return
		end

		local enabled = AdxSettings.pESP.Enabled

		billboard.Enabled = enabled
		highlight.Enabled = enabled and AdxSettings.pESP.Chams

		if not enabled then
			return
		end

		local info = {}

		if AdxSettings.pESP.ShowHealth then
			local health = math.max(0, math.floor(humanoid.Health))
			local maxHealth = math.max(1, math.floor(humanoid.MaxHealth))

			table.insert(
				info,
				string.format("HP: %d/%d", health, maxHealth)
			)
		end


		if AdxSettings.pESP.ShowDistance then
			local distance = getDistanceFromLocal(character)

			if distance then
				table.insert(info, distance .. " studs")
			end
		end


		if AdxSettings.pESP.ShowBounty then
			local leaderstats = player:FindFirstChild("leaderstats")
			local bounty = leaderstats and leaderstats:FindFirstChild("Bounty")

			if bounty then
				table.insert(info, tostring(bounty.Value))
			end
		end

		infoLabel.Text = table.concat(info, "  |  ")
	end

	data.update = update

	update()
end


--// =========================
--// MOB ESP
--// =========================

local function removeMobESP(model)
	local data = MobESP[model]

	if not data then
		return
	end

	if data.highlight then
		data.highlight:Destroy()
	end

	if data.billboard then
		data.billboard:Destroy()
	end

	MobESP[model] = nil
end


local function isMob(model)
	if not model:IsA("Model") then
		return false
	end

	-- Player characters aren't mobs
	if Players:GetPlayerFromCharacter(model) then
		return false
	end

	return model:FindFirstChildOfClass("Humanoid") ~= nil
end


local function createMobESP(model)
	if not isMob(model) then
		return
	end

	removeMobESP(model)

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = getCharacterRoot(model)

	if not humanoid or not root then
		return
	end

	local data = {}
	MobESP[model] = data


	--// Mob outline
	local highlight = Instance.new("Highlight")
	highlight.Name = "ADX_MobOutline"
	highlight.Adornee = model
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = AdxSettings.mESP.OutlineColor
	highlight.OutlineColor = AdxSettings.mESP.OutlineColor
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.Enabled = AdxSettings.mESP.Enabled
		and AdxSettings.mESP.Outline

	highlight.Parent = model

	data.highlight = highlight


	--// Billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ADX_MobESP"
	billboard.Adornee = root
	billboard.Size = UDim2.fromOffset(220, 90)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Enabled = AdxSettings.mESP.Enabled
	billboard.Parent = ESPFolder

	data.billboard = billboard


	local container = Instance.new("Frame")
	container.Size = UDim2.fromScale(1, 1)
	container.BackgroundTransparency = 1
	container.Parent = billboard


	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.Parent = container


	-- Mob name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 18)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = model.Name
	nameLabel.TextColor3 = AdxSettings.mESP.OutlineColor
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 13
	nameLabel.Parent = container

	data.nameLabel = nameLabel


	-- Mob info
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, 0, 0, 18)
	infoLabel.BackgroundTransparency = 1
	infoLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	infoLabel.TextStrokeTransparency = 0
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.TextSize = 11
	infoLabel.Parent = container

	data.infoLabel = infoLabel


	--// Update
	local function update()
		if not model.Parent then
			return
		end

		local enabled = AdxSettings.mESP.Enabled

		billboard.Enabled = enabled
		highlight.Enabled = enabled and AdxSettings.mESP.Outline

		highlight.OutlineColor = AdxSettings.mESP.OutlineColor
		nameLabel.TextColor3 = AdxSettings.mESP.OutlineColor

		if not enabled then
			return
		end

		local info = {}


		if AdxSettings.mESP.Health then
			local health = math.max(0, math.floor(humanoid.Health))
			local maxHealth = math.max(1, math.floor(humanoid.MaxHealth))

			table.insert(
				info,
				string.format("HP: %d/%d", health, maxHealth)
			)
		end


		if AdxSettings.mESP.Distance then
			local distance = getDistanceFromLocal(model)

			if distance then
				table.insert(info, distance .. " studs")
			end
		end


		if AdxSettings.mESP.Value then
			local value = getMobValue(model)

			if value then
				table.insert(info, "Value: " .. value)
			end
		end

		infoLabel.Text = table.concat(info, "  |  ")
	end

	data.update = update

	update()
end


--// =========================
--// REFRESH ESP
--// =========================

local function refreshPlayerESP()
	for player, data in pairs(PlayerESP) do
		if not player.Parent then
			removePlayerESP(player)
		elseif data.update then
			data.update()
		end
	end

	if AdxSettings.pESP.Enabled then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= Players.LocalPlayer then
				if not PlayerESP[player] then
					createPlayerESP(player)
				end
			end
		end
	end
end


local function refreshMobESP()
	for model, data in pairs(MobESP) do
		if not model.Parent then
			removeMobESP(model)
		elseif data.update then
			data.update()
		end
	end

	if AdxSettings.mESP.Enabled then
		for _, object in ipairs(mobsfolder:GetChildren()) do
			if object:IsA("Model") and isMob(object) then
				if not MobESP[object] then
					createMobESP(object)
				end
			end
		end
	end
end


local function refreshESP()
	refreshPlayerESP()
	refreshMobESP()
end



Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)

		if AdxSettings.pESP.Enabled then
			createPlayerESP(player)
		end
	end)
end)


Players.PlayerRemoving:Connect(function(player)
	removePlayerESP(player)
end)


for _, player in ipairs(Players:GetPlayers()) do
	if player ~= Players.LocalPlayer then
		player.CharacterAdded:Connect(function()
			task.wait(0.5)

			if AdxSettings.pESP.Enabled then
				createPlayerESP(player)
			end
		end)
	end
end



mobsfolder.ChildAdded:Connect(function(object)
	if not AdxSettings.mESP.Enabled then
		return
	end

	if object:IsA("Model") then
		task.wait()

		if isMob(object) then
			createMobESP(object)
		end
	end
end)


mobsfolder.ChildAdded:Connect(function(object)
	if MobESP[object] then
		removeMobESP(object)
	end
end)




RunService.Heartbeat:Connect(function()
	if AdxSettings.pESP.Enabled then
		for player, data in pairs(PlayerESP) do
			if data.update then
				data.update()
			end
		end
	end

	if AdxSettings.mESP.Enabled then
		for model, data in pairs(MobESP) do
			if data.update then
				data.update()
			end
		end
	end
end)

-- \\ UI SETUP // --

local Window = libary:new({name = "ADXWare || V1", accent = Color3.fromRGB(244, 95, 115), textsize = 13})
local PlayerTab = Window:page({name = "Players"})
local VisualTab = Window:page({name = "Visuals"})
local CombatTab = Window:page({name = "Combat"})
local LocalTab = Window:page({name = "Local"})
local MiscTab = Window:page({name = "Misc"})

local CMovementSection = LocalTab:section({name = "CFrame Movement", side = "left", size = 200})
local PBackpackSection = PlayerTab:section({name = "Backpack", side = "left", size = 200})


CMovementSection:toggle({name = "CFrame Movement", def = false, callback = function(Boolean)
	AdxSettings.CFrameSpeed.Enabled = Boolean
end})

CMovementSection:slider({name = "Speed", def = 1, max = 10, min = 0, callback = function(Value)
	AdxSettings.CFrameSpeed.Speed = Value
end})


PBackpackSection:textbox({name = "Player Name", def = "", placeholder = "Player Name", callback = function(Text)
	if getPlayer(Text) then
		selectedplayer = getPlayer(Text)
	end
end})

PBackpackSection:button({name = "Show Backpack", callback = function()
	if selectedplayer then
		showBackpackUI(selectedplayer)
	end
end})
PBackpackSection:button({name = "Show Leaderboard", callback = function()
	showInventoryLeaderboard()
end})

--// Player ESP
local PESPSection = VisualTab:section({name = "Player ESP", side = "left", size = 200})

PESPSection:toggle({name = "Player ESP", def = false, callback = function(Boolean)
	AdxSettings.pESP.Enabled = Boolean
	refreshPlayerESP()
end})

PESPSection:toggle({name = "Chams", def = false, callback = function(Boolean)
	AdxSettings.pESP.Chams = Boolean
	refreshPlayerESP()
end})

PESPSection:toggle({name = "Show Bounty", def = false, callback = function(Boolean)
	AdxSettings.pESP.ShowBounty = Boolean
	refreshPlayerESP()
end})

PESPSection:toggle({name = "Show Health", def = false, callback = function(Boolean)
	AdxSettings.pESP.ShowHealth = Boolean
	refreshPlayerESP()
end})

PESPSection:toggle({name = "Show Distance", def = false, callback = function(Boolean)
	AdxSettings.pESP.ShowDistance = Boolean
	refreshPlayerESP()
end})


--// Mob ESP
local MESPSection = VisualTab:section({name = "Mob ESP", side = "right", size = 200})

MESPSection:toggle({name = "Mob ESP", def = false, callback = function(Boolean)
	AdxSettings.mESP.Enabled = Boolean
	refreshMobESP()
end})

MESPSection:toggle({name = "Outline", def = false, callback = function(Boolean)
	AdxSettings.mESP.Outline = Boolean
	refreshMobESP()
end})

MESPSection:toggle({name = "Health", def = false, callback = function(Boolean)
	AdxSettings.mESP.Health = Boolean
	refreshMobESP()
end})

MESPSection:toggle({name = "Distance", def = false, callback = function(Boolean)
	AdxSettings.mESP.Distance = Boolean
	refreshMobESP()
end})

MESPSection:toggle({name = "Value", def = false, callback = function(Boolean)
	AdxSettings.mESP.Value = Boolean
	refreshMobESP()
end})

-- \\ FUNCTIONS // --

function emptyfunc()
	return
end


function updatenamelist()
	PlayersNameList = {}
	for _, player in pairs(Players:GetPlayers()) do
		table.insert(PlayersNameList, player.Name)
	end
end



RunService.Heartbeat:Connect(function(delta)
	if AdxSettings.CFrameSpeed.Enabled then
		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame + game.Players.LocalPlayer.Character.Humanoid.MoveDirection * AdxSettings.CFrameSpeed.Speed
	end
end)

updatenamelist()

