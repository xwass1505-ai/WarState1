-- EconomyService: PLANNED placeholder.
-- Civilian traffic and economy (trips House -> Road -> Shop). Not active yet.
-- This module intentionally contains NO gameplay mechanics. It only reserves the interface.

local EconomyService = {}
EconomyService.Name = "EconomyService"
EconomyService.Status = "PLANNED"
EconomyService.Active = false
EconomyService.Description = "Civilian traffic and economy (trips House -> Road -> Shop). Not active yet."

function EconomyService.init(_services) end

function EconomyService.start() end

return EconomyService
