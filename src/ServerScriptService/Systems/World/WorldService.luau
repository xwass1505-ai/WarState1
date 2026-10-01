-- WorldService: builds the game map once (ocean, central island, 6 player islands, exits, bridges)
-- and owns plot ownership. Plots are NEVER auto-assigned: the player picks a free plot after
-- creating/loading a country (ClaimPlot). No buildings, roads or citizens are pre-placed.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local GameConfig = require(Config:WaitForChild("GameConfig"))
local Theme = require(Config:WaitForChild("ThemeConfig"))
local Constants = require(Shared:WaitForChild("Constants"):WaitForChild("Constants"))
local Plots = require(Shared:WaitForChild("Modules"):WaitForChild("Plots"))
local Countries = require(Shared:WaitForChild("Modules"):WaitForChild("Countries"))

local WorldService = {}
WorldService.Name = "WorldService"

local services
local remotes
local plotOwners = {} -- [index] = { player = Player, countryName = string, flagId = string }
local playerPlots = {} -- [Player] = index
local plotModels = {} -- [index] = Model
local signs = {} -- [index] = { gui, name, flag, country }

local function ensureFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function rootFolders()
	return {
		Map = ensureFolder(Workspace, "Map"),
		Buildings = ensureFolder(Workspace, "Buildings"),
		Roads = ensureFolder(Workspace, "Roads"),
		Vehicles = ensureFolder(Workspace, "Vehicles"),
		NPCs = ensureFolder(Workspace, "NPCs"),
	}
end

local function color(t)
	return Color3.new(t[1], t[2], t[3])
end

local function block(parent, name, size: Vector3, cframe: CFrame, col: Color3, material, collide: boolean?)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = collide ~= false
	p.CanTouch = false
	p.Size = size
	p.CFrame = cframe
	p.Color = col
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- OCEAN + CENTRAL ISLAND -------------------------------------------------------------------
local function buildOcean(map)
	local m = GameConfig.Map
	local old = map:FindFirstChild("Ocean")
	if old then
		old:Destroy()
	end
	local ocean = Instance.new("Model")
	ocean.Name = "Ocean"
	block(ocean, "Seabed", Vector3.new(m.WaterSize, 2, m.WaterSize), CFrame.new(0, m.SeabedY - 1, 0), color(m.SeabedColor), Enum.Material.Sand)
	local water = block(
		ocean,
		"Water",
		Vector3.new(m.WaterSize, 0.4, m.WaterSize),
		CFrame.new(0, m.WaterLevel - 0.2, 0),
		color(m.WaterColor),
		Enum.Material.SmoothPlastic,
		false
	)
	water.Transparency = 0.2
	water.CanQuery = false
	water.CastShadow = false
	ocean.Parent = map
end

local function tree(parent, x: number, z: number, scale: number, rng)
	local trunkH = 2.2 * scale
	block(parent, "Trunk", Vector3.new(0.5 * scale, trunkH, 0.5 * scale), CFrame.new(x, trunkH / 2, z), Color3.fromRGB(150, 112, 80), Enum.Material.Wood, false)
	local leaf = Color3.fromRGB(112 + rng:NextInteger(0, 20), 162 + rng:NextInteger(0, 20), 98)
	block(parent, "Leaves", Vector3.new(2.2 * scale, 1.6 * scale, 2.2 * scale), CFrame.new(x, trunkH + 0.6 * scale, z), leaf, Enum.Material.SmoothPlastic, false)
	block(parent, "LeavesTop", Vector3.new(1.4 * scale, 1.1 * scale, 1.4 * scale), CFrame.new(x, trunkH + 1.8 * scale, z), leaf:Lerp(Color3.new(1, 1, 1), 0.08), Enum.Material.SmoothPlastic, false)
end

local function rock(parent, x: number, z: number, scale: number)
	block(
		parent,
		"Rock",
		Vector3.new(1.6 * scale, 1.0 * scale, 1.3 * scale),
		CFrame.new(x, 0.3 * scale, z) * CFrame.Angles(0, scale, 0.1),
		Color3.fromRGB(178, 182, 186),
		Enum.Material.Slate,
		false
	)
end

local function buildCentralIsland(map)
	local c = GameConfig.Map.CentralIsland
	local old = map:FindFirstChild("CentralIsland")
	if old then
		old:Destroy()
	end
	local island = Instance.new("Model")
	island.Name = "CentralIsland"
	island:SetAttribute("Purpose", "Future land battles")
	local sand = color(GameConfig.Territory.SandColor)
	block(island, "Beach", Vector3.new(c.Size, 6, c.Size), CFrame.new(c.CenterX, -3.15, c.CenterZ), sand, Enum.Material.Sand)
	local inner = c.Size - c.BeachWidth * 2
	local ground = block(island, "Ground", Vector3.new(inner, 6, inner), CFrame.new(c.CenterX, -3, c.CenterZ), color(c.Color), Enum.Material.Grass)
	island.PrimaryPart = ground

	local deco = Instance.new("Folder")
	deco.Name = "Decorations"
	deco.Parent = island
	local d = GameConfig.Map.Decorations
	local rng = Random.new(d.Seed)
	local limit = inner / 2 - 6
	local placed = 0
	local attempts = 0
	while placed < d.Trees and attempts < 200 do
		attempts += 1
		local x = rng:NextNumber(-limit, limit)
		local z = rng:NextNumber(-limit, limit)
		if math.abs(x) > 26 or math.abs(z) > 26 then
			tree(deco, c.CenterX + x, c.CenterZ + z, rng:NextNumber(0.9, 1.4), rng)
			placed += 1
		end
	end
	for _ = 1, d.Rocks do
		local x = rng:NextNumber(-limit, limit)
		local z = rng:NextNumber(-limit, limit)
		rock(deco, c.CenterX + x, c.CenterZ + z, rng:NextNumber(0.8, 1.6))
	end

	local lobby = GameConfig.Map.LobbySpawn
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(8, 0.4, 8)
	spawn.CFrame = CFrame.new(lobby[1], 0.2, lobby[3])
	spawn.Color = Theme.Colors.AccentSoft
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = island
	island.Parent = map
end

-- PLAYER PLOTS -------------------------------------------------------------------------------
local function createSign(index: number, plotModel: Model, bounds)
	local anchor = Instance.new("Part")
	anchor.Name = "OwnerSign"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.CFrame = CFrame.new(bounds.centerX, bounds.surfaceY + 20, bounds.centerZ)
	anchor.Parent = plotModel

	local gui = Instance.new("BillboardGui")
	gui.Name = "OwnerPanel"
	gui.Size = UDim2.fromOffset(176, 84)
	gui.MaxDistance = 700
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.ResetOnSpawn = false
	gui.Adornee = anchor
	gui.Parent = anchor

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Theme.Colors.Background
	card.BackgroundTransparency = 0.04
	card.BorderSizePixel = 0
	card.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colors.Accent
	stroke.Thickness = 1.5
	stroke.Transparency = 0.3
	stroke.Parent = card

	local function text(name, y, h, font, size, col)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.BackgroundTransparency = 1
		l.Position = UDim2.new(0, 8, 0, y)
		l.Size = UDim2.new(1, -16, 0, h)
		l.Font = font
		l.TextSize = size
		l.TextColor3 = col
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.Text = ""
		l.Parent = card
		return l
	end
	local nameLabel = text("PlayerName", 6, 18, Theme.Fonts.Bold, 14, Theme.Colors.Text)
	local flagLabel = text("Flag", 25, 28, Theme.Fonts.Regular, 24, Theme.Colors.Text)
	local flagImage = Instance.new("ImageLabel")
	flagImage.Name = "FlagImage"
	flagImage.BackgroundTransparency = 1
	flagImage.AnchorPoint = Vector2.new(0.5, 0)
	flagImage.Position = UDim2.new(0.5, 0, 0, 27)
	flagImage.Size = UDim2.fromOffset(36, 24)
	flagImage.ScaleType = Enum.ScaleType.Crop
	flagImage.Visible = false
	flagImage.Parent = card
	local countryLabel = text("CountryName", 58, 18, Theme.Fonts.Medium, 13, Theme.Colors.AccentDark)
	signs[index] = { gui = gui, name = nameLabel, flag = flagLabel, flagImage = flagImage, country = countryLabel }
end

local function updateSign(index: number)
	local sign = signs[index]
	if not sign then
		return
	end
	local owner = plotOwners[index]
	if owner then
		sign.name.Text = owner.player.Name
		local entry = Countries.get(owner.flagId or "")
		if entry and Countries.hasRealFlag(entry) then
			sign.flagImage.Image = entry.FlagAsset
			sign.flagImage.Visible = true
			sign.flag.Text = ""
		else
			sign.flagImage.Visible = false
			sign.flag.Text = entry and entry.EmojiFallback or ""
		end
		sign.country.Text = owner.countryName or ""
	else
		sign.name.Text = "PLOT " .. index
		sign.flagImage.Visible = false
		sign.flag.Text = ""
		sign.country.Text = "Free"
	end
end

local function buildExit(plotModel: Model, index: number, bounds)
	local exit = Plots.getExit(index)
	local m = GameConfig.Map
	local width = m.BridgeWidth
	local y = bounds.surfaceY
	local folder = Instance.new("Model")
	folder.Name = "Exit"
	folder:SetAttribute("ExitSide", exit.side)
	folder:SetAttribute("ExitIx", exit.ix)
	folder:SetAttribute("ExitIz", exit.iz)

	local function strip(name, ax, az, bx, bz, w, thick, col, material, top)
		local dx, dz = bx - ax, bz - az
		local length = math.sqrt(dx * dx + dz * dz)
		if length < 0.05 then
			return nil
		end
		local mid = Vector3.new((ax + bx) / 2, top - thick / 2, (az + bz) / 2)
		local cf = CFrame.lookAt(mid, mid + Vector3.new(dx, 0, dz))
		return block(folder, name, Vector3.new(w, thick, length), cf, col, material)
	end
	local asphalt = Color3.fromRGB(124, 128, 134)
	-- Exit lane across the sand rim (plot edge -> bridge start)
	strip("ExitLane", exit.edgeX, exit.edgeZ, exit.bridgeStartX, exit.bridgeStartZ, width, 0.4, asphalt, Enum.Material.Concrete, y + 0.08)
	-- Bridge over water (bridge start -> central island landing)
	strip("Bridge", exit.bridgeStartX, exit.bridgeStartZ, exit.bridgeEndX, exit.bridgeEndZ, width, 0.8, color(m.BridgeColor), Enum.Material.Concrete, y + 0.08)
	local v = Plots.SideVector[exit.side]
	local px, pz = -v[2], v[1] -- perpendicular
	for _, s in ipairs({ -1, 1 }) do
		local ox, oz = px * s * (width / 2 + 0.15), pz * s * (width / 2 + 0.15)
		strip("Rail", exit.bridgeStartX + ox, exit.bridgeStartZ + oz, exit.bridgeEndX + ox, exit.bridgeEndZ + oz, 0.3, 0.6, color(m.BridgeRailColor), Enum.Material.SmoothPlastic, y + 0.6)
		-- Gate posts at the plot edge
		block(
			folder,
			"GatePost",
			Vector3.new(0.5, 3, 0.5),
			CFrame.new(exit.edgeX + px * s * (width / 2 + 0.6), y + 1.5, exit.edgeZ + pz * s * (width / 2 + 0.6)),
			Theme.Colors.Accent,
			Enum.Material.SmoothPlastic,
			false
		)
	end
	local beamLength = width + 1.7
	local beamSize = (v[1] == 0) and Vector3.new(beamLength, 0.4, 0.4) or Vector3.new(0.4, 0.4, beamLength)
	block(folder, "GateBeam", beamSize, CFrame.new(exit.edgeX, y + 3.1, exit.edgeZ), Theme.Colors.Background, Enum.Material.SmoothPlastic, false)
	folder.Parent = plotModel
end

local function buildPlot(map, index: number)
	local bounds = Plots.getBounds(index)
	local t = GameConfig.Territory
	local plotsFolder = ensureFolder(map, "Plots")
	local old = plotsFolder:FindFirstChild("Plot_" .. index)
	if old then
		old:Destroy()
	end
	local plotModel = Instance.new("Model")
	plotModel.Name = "Plot_" .. index
	plotModel:SetAttribute(Constants.Attributes.PlotIndex, index)
	plotModel:SetAttribute("OwnerUserId", 0)

	local islandSize = t.Size + t.RimWidth * 2
	block(plotModel, "Rim", Vector3.new(islandSize, 6, islandSize), CFrame.new(bounds.centerX, bounds.surfaceY - 3.12, bounds.centerZ), color(t.SandColor), Enum.Material.Sand)
	local ground = block(plotModel, "Ground", Vector3.new(t.Size, t.Thickness, t.Size), CFrame.new(bounds.centerX, bounds.surfaceY - t.Thickness / 2, bounds.centerZ), color(t.Color), Enum.Material.Grass)
	ground:SetAttribute(Constants.Attributes.PlotIndex, index)
	plotModel.PrimaryPart = ground

	local border = t.BorderWidth
	local sides = {
		{ Vector3.new(t.Size, 0.06, border), Vector3.new(0, 0, -t.Size / 2 + border / 2) },
		{ Vector3.new(t.Size, 0.06, border), Vector3.new(0, 0, t.Size / 2 - border / 2) },
		{ Vector3.new(border, 0.06, t.Size), Vector3.new(-t.Size / 2 + border / 2, 0, 0) },
		{ Vector3.new(border, 0.06, t.Size), Vector3.new(t.Size / 2 - border / 2, 0, 0) },
	}
	for i, side in ipairs(sides) do
		local p = block(plotModel, "Border" .. i, side[1], CFrame.new(bounds.centerX, bounds.surfaceY + 0.03, bounds.centerZ) + side[2], color(t.BorderColor), Enum.Material.SmoothPlastic, false)
		p.CanQuery = false
	end
	buildExit(plotModel, index, bounds)
	createSign(index, plotModel, bounds)
	plotModel.Parent = plotsFolder
	plotModels[index] = plotModel
	updateSign(index)
end

local function buildMap()
	local folders = rootFolders()
	buildOcean(folders.Map)
	buildCentralIsland(folders.Map)
	for index = 1, Plots.maxPlots() do
		buildPlot(folders.Map, index)
	end
end

-- OWNERSHIP ----------------------------------------------------------------------------------
local function createPlotFolders(index: number, owner: Player)
	local folders = rootFolders()
	for _, key in ipairs({ "Buildings", "Roads" }) do
		local plotFolderName = "Plot_" .. index
		local old = folders[key]:FindFirstChild(plotFolderName)
		if old then
			old:Destroy()
		end
		local folder = Instance.new("Folder")
		folder.Name = plotFolderName
		folder:SetAttribute(Constants.Attributes.PlotIndex, index)
		folder:SetAttribute(Constants.Attributes.OwnerUserId, owner.UserId)
		folder.Parent = folders[key]
	end
end

local function destroyPlotFolders(index: number)
	local folders = rootFolders()
	for _, key in ipairs({ "Buildings", "Roads" }) do
		local inst = folders[key]:FindFirstChild("Plot_" .. index)
		if inst then
			inst:Destroy()
		end
	end
end

local function broadcast()
	if remotes and remotes[Constants.Remotes.PlotsChanged] then
		remotes[Constants.Remotes.PlotsChanged]:FireAllClients(WorldService.listPlots())
	end
end

function WorldService.listPlots()
	local list = {}
	for index = 1, Plots.maxPlots() do
		local owner = plotOwners[index]
		table.insert(list, {
			Index = index,
			Free = owner == nil,
			OwnerName = owner and owner.player.Name or nil,
			OwnerUserId = owner and owner.player.UserId or nil,
			CountryName = owner and owner.countryName or nil,
			FlagId = owner and owner.flagId or nil,
		})
	end
	return list
end

function WorldService.isPlotFree(index: number): boolean
	return Plots.isValidIndex(index) and plotOwners[index] == nil
end

function WorldService.getOwner(index: number): Player?
	local owner = plotOwners[index]
	return owner and owner.player or nil
end

function WorldService.getPlotIndex(player: Player): number?
	return playerPlots[player]
end

function WorldService.getBounds(player: Player)
	local index = playerPlots[player]
	if not index then
		return nil
	end
	return Plots.getBounds(index)
end

function WorldService.getExit(player: Player)
	local index = playerPlots[player]
	return index and Plots.getExit(index) or nil
end

function WorldService.getPlotFolder(player: Player, kind: string): Folder?
	local index = playerPlots[player]
	if not index then
		return nil
	end
	local root = Workspace:FindFirstChild(kind)
	return root and root:FindFirstChild("Plot_" .. index) or nil
end

local function spawnCFrame(index: number)
	local bounds = Plots.getBounds(index)
	local v = Plots.SideVector[bounds.exitSide]
	local offset = bounds.size / 2 - 6
	local pos = Vector3.new(bounds.centerX + v[1] * offset, bounds.surfaceY + 4, bounds.centerZ + v[2] * offset)
	return CFrame.lookAt(pos, Vector3.new(bounds.centerX, pos.Y, bounds.centerZ))
end

function WorldService.teleportToPlot(player: Player)
	local index = playerPlots[player]
	local character = player.Character
	if index and character then
		character:PivotTo(spawnCFrame(index))
	end
end

function WorldService.teleportToLobby(player: Player)
	local lobby = GameConfig.Map.LobbySpawn
	local character = player.Character
	if character then
		character:PivotTo(CFrame.new(lobby[1], lobby[2] + 4, lobby[3]))
	end
end

-- Server-authoritative claim. Returns ok, error.
function WorldService.claim(player: Player, index: any, country): (boolean, string?)
	if not Plots.isValidIndex(index) then
		return false, "Invalid plot"
	end
	if playerPlots[player] then
		return false, "You already own a plot"
	end
	if plotOwners[index] ~= nil then
		return false, "This plot is already taken"
	end
	plotOwners[index] = {
		player = player,
		countryName = country and country.Name or "",
		flagId = country and country.FlagId or "",
	}
	playerPlots[player] = index
	createPlotFolders(index, player)
	local model = plotModels[index]
	if model then
		model:SetAttribute("OwnerUserId", player.UserId)
		model:SetAttribute("OwnerName", player.Name)
		model:SetAttribute("CountryName", country and country.Name or "")
	end
	player:SetAttribute(Constants.Attributes.PlotIndex, index)
	updateSign(index)
	broadcast()
	return true, nil
end

function WorldService.release(player: Player)
	local index = playerPlots[player]
	if not index then
		return
	end
	destroyPlotFolders(index)
	plotOwners[index] = nil
	playerPlots[player] = nil
	local model = plotModels[index]
	if model then
		model:SetAttribute("OwnerUserId", 0)
		model:SetAttribute("OwnerName", nil)
		model:SetAttribute("CountryName", nil)
	end
	if player.Parent then
		player:SetAttribute(Constants.Attributes.PlotIndex, nil)
	end
	updateSign(index)
	broadcast()
end

-- Kept for older callers: plots are no longer assigned automatically.
function WorldService.leave(player: Player)
	WorldService.release(player)
end

function WorldService.init(allServices)
	services = allServices
	remotes = allServices.Remotes
	buildMap()
end

local function hookCharacter(player: Player)
	player.CharacterAdded:Connect(function()
		task.defer(function()
			if playerPlots[player] then
				WorldService.teleportToPlot(player)
			end
		end)
	end)
end

function WorldService.start()
	remotes[Constants.Remotes.GetPlots].OnServerInvoke = function(_player)
		return { ok = true, plots = WorldService.listPlots() }
	end
	Players.PlayerAdded:Connect(hookCharacter)
	for _, player in ipairs(Players:GetPlayers()) do
		hookCharacter(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		WorldService.release(player)
	end)
end

return WorldService
