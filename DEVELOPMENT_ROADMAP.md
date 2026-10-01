# WAR STATE - DEVELOPMENT_ROADMAP.md

> Future plan only. What exists today is in PROJECT.md.

## Done in Phase 2 (v0.2.0) - see PROJECT.md
Visual overhaul, main screen, plot selection (6 plots), plot ownership + owner panels, island map with exits/bridges,
small buildings, single Straight Road with drag build and junction curbs, demolish, construction bars,
Water/Power systems, Stats panel, save schema v2 + migration.

## Next - Phase 2b: stabilize
- Run the Studio checklist and fix runtime issues; verify with real `rojo build`
- DataStore session locking (UpdateAsync with session id)
- Offline construction progress (timestamp based)
- Verified flag image assets (only real Roblox ids)
- Water/Power overlay on the map (colored markers per building)

## Phase 3 - Economy and services
- Income -> Treasury; turn on `GameConfig.Economy.ChargeCosts`; building costs + refunds
- Services (clinic, school, police); commercial demand; power effects on businesses/industry

## Phase 4 - Resources, industry, logistics
- Oil Well -> Refinery -> Fuel (feeds Substation upkeep), Steel, Supplies
- Trucks on the RoadGraph (VehicleService.routeToCentral already returns waypoints)

## Phase 5 - Research (USSR / Russia, USA, Germany lines; no doctrine system)

## Phase 6 - Military: tanks / IFV / military vehicles leave plots through exits and fight on the central island

## Phase 7 - Unlock slots 2 and 3

## Engineering rules
Server authority for all permanent state; config in JSON; no RenderStepped on the server; event-driven recomputes;
update PROJECT.md on every major change.
