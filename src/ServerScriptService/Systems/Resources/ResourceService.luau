-- ResourceService: PARTIAL.
-- Resources (Treasury, Oil, Fuel, Steel, Supplies) exist in country data and are replicated.
-- A new country starts with ZERO of everything; nothing is ever granted automatically.
-- Costs are defined in config (Cost = { Treasury = n }) and checked here on the SERVER.
-- GameConfig.Economy.ChargeCosts = false while no income source exists (otherwise an empty
-- country could never build anything); flip it to true once production/economy ships.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("GameConfig"))

local ResourceService = {}
ResourceService.Name = "ResourceService"
ResourceService.Status = "PARTIAL"
ResourceService.ResourceKeys = { "Treasury", "Oil", "Fuel", "Steel", "Supplies" }
ResourceService.Active = GameConfig.Economy.ChargeCosts == true

local services

function ResourceService.get(player: Player)
	local country = services.DataService.getCountry(player)
	if not country then
		return nil
	end
	local result = {}
	for _, key in ipairs(ResourceService.ResourceKeys) do
		result[key] = country[key] or 0
	end
	return result
end

-- cost = { Treasury = 10, Steel = 2 } (optional multiplier for road lines)
function ResourceService.canAfford(country, cost, multiplier: number?): (boolean, string?)
	if not ResourceService.Active or type(cost) ~= "table" then
		return true, nil
	end
	local m = multiplier or 1
	for key, amount in pairs(cost) do
		if type(amount) == "number" and amount > 0 and (country[key] or 0) < amount * m then
			return false, "Not enough " .. key
		end
	end
	return true, nil
end

function ResourceService.charge(country, cost, multiplier: number?)
	if not ResourceService.Active or type(cost) ~= "table" then
		return
	end
	local m = multiplier or 1
	for key, amount in pairs(cost) do
		if type(amount) == "number" and amount > 0 then
			country[key] = math.max(0, (country[key] or 0) - amount * m)
		end
	end
end

function ResourceService.init(allServices)
	services = allServices
end

function ResourceService.start() end

return ResourceService
