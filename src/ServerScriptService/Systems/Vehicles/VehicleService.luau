-- VehicleService: PARTIAL. Routing foundation for future vehicles (tanks, IFV, trucks,
-- military vehicles). No vehicles are spawned yet (no mass NPC / vehicle simulation).
-- Route: PLAYER PLOT (road graph) -> EXIT tile -> bridge -> MAIN MAP -> CENTRAL ISLAND.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Modules = Shared:WaitForChild("Modules")
local RoadGraph = require(Modules:WaitForChild("RoadGraph"))

local VehicleService = {}
VehicleService.Name = "VehicleService"
VehicleService.Status = "PARTIAL"
VehicleService.Active = false
VehicleService.VehicleClasses = {
	{ Id = "Truck", Category = "Logistics", Status = "PLANNED" },
	{ Id = "Tank", Category = "Military", Status = "PLANNED" },
	{ Id = "IFV", Category = "Military", Status = "PLANNED" },
	{ Id = "MilitaryVehicle", Category = "Military", Status = "PLANNED" },
}

local services

-- Returns world waypoints { Vector3, ... } from a road tile to the central island, or nil + reason.
function VehicleService.routeToCentral(player: Player, fromRoadId: string)
	local bounds = services.WorldService.getBounds(player)
	local exit = services.WorldService.getExit(player)
	if not bounds or not exit then
		return nil, "No plot"
	end
	local segmentsById = services.RoadService.getSegmentsById(player)
	local path = RoadGraph.pathToExit(segmentsById, fromRoadId)
	if not path then
		return nil, "Road is not connected to the plot exit"
	end
	local waypoints = {}
	for _, roadId in ipairs(path) do
		local segment = segmentsById[roadId]
		table.insert(waypoints, Vector3.new(bounds.minX + segment.Position.X, bounds.surfaceY, bounds.minZ + segment.Position.Z))
	end
	for i, point in ipairs(exit.waypoints) do
		if i > 1 then
			table.insert(waypoints, Vector3.new(point.X, bounds.surfaceY, point.Z))
		end
	end
	return waypoints, nil
end

-- True when at least one road tile of the player touches the exit.
function VehicleService.hasExitAccess(player: Player): boolean
	for _, segment in pairs(services.RoadService.getSegmentsById(player)) do
		if segment.ExitConnected then
			return true
		end
	end
	return false
end

function VehicleService.init(allServices)
	services = allServices
end

function VehicleService.start() end

return VehicleService
