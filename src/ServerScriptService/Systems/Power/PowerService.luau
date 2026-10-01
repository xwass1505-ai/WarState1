-- PowerService: server-side electricity system.
-- Sources: Wind Generator (small: cheap, low production, small radius) and Substation /
-- Advanced Power Source (expensive, high production, large radius, higher resource upkeep).
-- Every building record gets PowerRequired / PowerSupplied / PowerStatus
-- (GREEN supplied, RED insufficient / no electricity, GREY not required).
-- Coverage is recomputed on events only. Upkeep (e.g. Fuel) is charged per utility tick only
-- while ResourceService is active; a source that cannot pay its upkeep goes offline.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local GameConfig = require(Config:WaitForChild("GameConfig"))
local BuildingConfig = require(Config:WaitForChild("BuildingConfig"))
local Constants = require(Shared:WaitForChild("Constants"):WaitForChild("Constants"))
local UtilityGrid = require(Shared:WaitForChild("Modules"):WaitForChild("UtilityGrid"))

local PowerService = {}
PowerService.Name = "PowerService"
PowerService.Kind = "Power"

local services
local defsById = {}
for _, def in ipairs(BuildingConfig.Buildings) do
	defsById[def.Id] = def
end

local function infra(country)
	country.Infrastructure = country.Infrastructure or {}
	local i = country.Infrastructure
	i.Power = i.Power or { Production = 0, Demand = 0 }
	return i
end

function PowerService.recompute(player: Player): boolean
	local country = services.DataService.getCountry(player)
	if not country then
		return false
	end
	local i = infra(country)
	local result = UtilityGrid.compute(country.Buildings, defsById, "Power")
	local changed = UtilityGrid.apply(country.Buildings, "Power", result)
	i.Power.Production = result.production
	i.Power.Demand = result.demand
	i.Power.Supplied = result.supplied
	services.BuildingService.refreshUtilityAttributes(player)
	return changed
end

-- Upkeep step: returns true when a source changed online/offline state.
local function upkeepStep(country): boolean
	if not services.ResourceService.Active then
		return false
	end
	local changed = false
	for _, record in pairs(country.Buildings) do
		local def = defsById[record.Type]
		local spec = def and def.Power
		if spec and (spec.Production or 0) > 0 and record.State == Constants.BuildState.Completed then
			local upkeep = spec.Upkeep or {}
			local affordable = services.ResourceService.canAfford(country, upkeep)
			local offline = not affordable
			if offline ~= (record.PowerOffline == true) then
				changed = true
			end
			record.PowerOffline = offline or nil
			if affordable then
				services.ResourceService.charge(country, upkeep)
			end
		end
	end
	return changed
end

function PowerService.init(allServices)
	services = allServices
end

function PowerService.start()
	task.spawn(function()
		while true do
			task.wait(GameConfig.Utilities.TickSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				local country = services.DataService.getCountry(player)
				if country and services.WorldService.getPlotIndex(player) then
					local ok, result = pcall(upkeepStep, country)
					if ok and result then
						PowerService.recompute(player)
						services.DataService.markDirty(player)
						services.CountryService.push(player)
					elseif not ok then
						warn("[PowerService] " .. tostring(result))
					end
				end
			end
		end
	end)
end

return PowerService
