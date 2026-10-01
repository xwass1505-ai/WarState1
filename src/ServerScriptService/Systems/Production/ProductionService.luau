-- ProductionService: PLANNED placeholder.
-- Industry chains (Oil Well -> Refinery -> Fuel, Steel, Supplies). Not active yet.
-- This module intentionally contains NO gameplay mechanics. It only reserves the interface.

local ProductionService = {}
ProductionService.Name = "ProductionService"
ProductionService.Status = "PLANNED"
ProductionService.Active = false
ProductionService.Description = "Industry chains (Oil Well -> Refinery -> Fuel, Steel, Supplies). Not active yet."

function ProductionService.init(_services) end

function ProductionService.start() end

return ProductionService
