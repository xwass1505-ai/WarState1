-- StatsService: builds the REAL statistics shown in the client Stats panel.
-- Every number is derived from the authoritative country data (no fake values).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local BuildingConfig = require(Config:WaitForChild("BuildingConfig"))
local Constants = require(Shared:WaitForChild("Constants"):WaitForChild("Constants"))
local UtilityGrid = require(Shared:WaitForChild("Modules"):WaitForChild("UtilityGrid"))

local StatsService = {}
StatsService.Name = "StatsService"
StatsService.RoadListLimit = 6
StatsService.BuildingListLimit = 60

local defsById = {}
for _, def in ipairs(BuildingConfig.Buildings) do
	defsById[def.Id] = def
end

local function idNumber(id: string): number
	return tonumber(string.match(id or "", "%d+")) or 0
end

-- Returns { Stats = {...}, Water = {...}, Power = {...}, WaterList = {...}, PowerList = {...} }
function StatsService.build(country)
	local stats = {
		Population = country.Population or 0,
		HousingCapacity = country.HousingCapacity or 0,
		Workers = country.Workers or 0,
		Houses = 0,
		Businesses = 0,
		Factories = 0,
		Roads = 0,
		Buildings = 0,
		UnderConstruction = 0,
		WaterTowers = 0,
		PowerSources = 0,
	}
	local waterList, powerList = {}, {}
	local counters = {}
	local records = UtilityGrid.sortedRecords(country.Buildings)
	for _, record in ipairs(records) do
		local def = defsById[record.Type]
		if def then
			stats.Buildings += 1
			local completed = record.State == Constants.BuildState.Completed
			if not completed then
				stats.UnderConstruction += 1
			end
			local group = def.StatsGroup
			if group and stats[group] ~= nil and completed then
				stats[group] += 1
			end
			local short = def.ShortName or def.DisplayName
			counters[short] = (counters[short] or 0) + 1
			local label = short .. " #" .. counters[short]
			if #waterList < StatsService.BuildingListLimit then
				table.insert(waterList, {
					Label = label,
					Id = record.Id,
					Status = record.WaterStatus or "GREY",
					Required = record.WaterRequired or 0,
					Supplied = record.WaterSupplied or 0,
					Pending = not completed,
				})
				table.insert(powerList, {
					Label = label,
					Id = record.Id,
					Status = record.PowerStatus or "GREY",
					Required = record.PowerRequired or 0,
					Supplied = record.PowerSupplied or 0,
					Pending = not completed,
				})
			end
		end
	end
	local roadIds = {}
	for id in pairs(country.Roads) do
		table.insert(roadIds, id)
	end
	table.sort(roadIds, function(a, b)
		return idNumber(a) < idNumber(b)
	end)
	stats.Roads = #roadIds
	for i, id in ipairs(roadIds) do
		if i > StatsService.RoadListLimit then
			break
		end
		local row = { Label = "Road #" .. i, Id = id, Status = "GREY", Required = 0, Supplied = 0, Pending = false }
		table.insert(waterList, row)
		table.insert(powerList, row)
	end
	local extraRoads = math.max(0, #roadIds - StatsService.RoadListLimit)
	local infra = country.Infrastructure or {}
	local water = infra.Water or {}
	local power = infra.Power or {}
	local shortage = infra.Shortage or {}
	return {
		Stats = stats,
		Water = {
			Production = water.Production or 0,
			Demand = water.Demand or 0,
			Supplied = water.Supplied or 0,
			Stored = water.Stored or 0,
			Capacity = water.Capacity or 0,
			Stage = shortage.Stage or Constants.ShortageStage.Normal,
			ShortageSeconds = shortage.Seconds or 0,
		},
		Power = {
			Production = power.Production or 0,
			Demand = power.Demand or 0,
			Supplied = power.Supplied or 0,
		},
		WaterList = waterList,
		PowerList = powerList,
		ExtraRoads = extraRoads,
	}
end

function StatsService.init(_services) end

function StatsService.start() end

return StatsService
