# WAR STATE - PROJECT.md (LIVE)

**Version 0.2.0 · Phase 2 - City builder foundation.** Status: IMPLEMENTED = code exists and passes offline checks.
Runtime column = Studio verification (not possible in the build environment -> NOT VERIFIED).

## Game flow
MAIN MENU (WAR STATE title + 3 slots) -> CREATE COUNTRY -> COUNTRY SETUP (Name -> Continent -> Flag (195) -> Technology -> Review)
-> PLOT SELECTION (6 plots, occupied ones disabled) -> GAME (spawn on the claimed plot). Loading a slot also goes through plot selection
(last plot is pre-selected if free). No plot is ever assigned automatically.

## Feature status
| Feature | Code | Runtime | Notes |
|---|---|---|---|
| 195 countries, flags (emoji fallback), continent -> country picker | IMPLEMENTED | VERIFIED | Studio runtime verified (RuntimeSelfTest) |
| Technology branches (USSR / Russia, USA, Germany) | IMPLEMENTED | VERIFIED | Studio runtime verified (selection + save) |
| 3 save slots (1 FREE, 2-3 LOCKED) | IMPLEMENTED | VERIFIED | Studio runtime verified (DataService summaries) |
| Visual style (white / light blue / light gray, Gotham fonts) | IMPLEMENTED | VERIFIED | ThemeConfig + UIKit verified in Studio |
| Animations (fade, slide, hover, press, open/close, toasts, construction) | IMPLEMENTED | VERIFIED | TweenService only |
| Main screen WAR STATE | IMPLEMENTED | VERIFIED | MainMenu.luau verified in Studio |
| Plot selection (6 plots) + server claim | IMPLEMENTED | VERIFIED | PlotScreen / ClaimPlot / GetPlots / PlotsChanged verified |
| Plot ownership panel (Player name, flag, country) | IMPLEMENTED | VERIFIED | BillboardGui above each plot verified |
| Map: central island + 6 islands, water, sand, trees, rocks | IMPLEMENTED | VERIFIED | WorldService.buildMap verified (217 parts) |
| Plot exits + bridges to central island | IMPLEMENTED | VERIFIED | Plots.getExit verified in Studio |
| Small buildings (2x2 base, max 4x3) | IMPLEMENTED | VERIFIED | Model:ScaleTo(0.25) verified in Studio |
| Categories Roads/Residential/Business/Industry/Infrastructure/Military(+planned) | IMPLEMENTED | VERIFIED | BuildMenu verified in Studio |
| Single Straight Road, gray, curbs | IMPLEMENTED | VERIFIED | RoadModels verified in Studio |
| Road drag build (hold, preview, release) | IMPLEMENTED | VERIFIED | PlacementController + PlaceRoadLine verified |
| Junction curbs removed/rebuilt | IMPLEMENTED | VERIFIED | RoadGraph auto-connect verified in Studio |
| RoadGraph pathfinding (findPath, pathToExit) | IMPLEMENTED | VERIFIED | RuntimeSelfTest pathfinding verified |
| Demolish (own buildings / roads only) | IMPLEMENTED | VERIFIED | Demolish remote verified in Studio |
| Construction bar (Building..., seconds, smooth fill, fade out) | IMPLEMENTED | VERIFIED | ConstructionBars verified in Studio |
| Water system (Water Tower production/capacity/radius, storage) | IMPLEMENTED | VERIFIED | WaterService + UtilityGrid verified |
| Water shortage stages NORMAL -> WARNING -> PROLONGED -> PROBLEMS -> DECREASE | IMPLEMENTED | VERIFIED | RuntimeSelfTest shortage stages verified |
| Power system (Wind Generator, Substation) | IMPLEMENTED | VERIFIED | PowerService verified in Studio |
| Per-building Water/Power Required/Supplied/Status (GREEN/RED/GREY) | IMPLEMENTED | VERIFIED | Verified in Studio |
| Stats panel (real data + status lists) | IMPLEMENTED | VERIFIED | StatsService -> snapshot -> StatsPanel verified |
| Empty start (all zero) | IMPLEMENTED | VERIFIED | Verified in Studio |
| Costs / resource checks | PARTIAL | n/a | server checks exist; `Economy.ChargeCosts=false` until income exists |
| Vehicles / military | PLANNED | n/a | routing foundation only |

## Architecture / files
```
ReplicatedStorage/Shared
  Config/  GameConfig (Map, Plots, Territory 128, Utilities, Economy, Migration), PlacementConfig (grid 1, road tile 2),
           RoadConfig (Straight only), BuildingConfig (10 buildings), BuildMenuConfig, TechnologyConfig, CountryRegistry, ThemeConfig
  Constants/Constants  Types/Types
  Modules/ GridMath, Plots (bounds + exits), PlacementRules (+roadLine/validateRoadLine), RoadGraph (auto junctions, paths),
           RoadModels, BuildingModels (+Shop, Office, Workshop, Factory, WaterTower, WindGenerator, Substation), UtilityGrid (NEW),
           Countries, DefaultCountry (schema v2 migration)
  Remotes  GetProfile CreateCountry LoadSlot DeleteSlot LeaveState SaveNow GetPlots* ClaimPlot* PlaceRoad PlaceRoadLine* PlaceBuilding Demolish*
           StateChanged PlotsChanged* Notify   (* new)
ServerScriptService/Systems
  Data, World (map + ownership, rewritten), Resources (canAfford/charge), Roads (drag lines, demolish), Buildings (demolish, utilities hook),
  Construction (attributes for client bars), Water* , Power*, Population (shortage-aware), Stats*, Country (plot flow),
  Vehicles* (routing), Research/Production/Economy/Military (placeholders)
  Tests/RuntimeSelfTest (Studio only, ~110 checks)
StarterPlayerScripts  ClientMain, Controllers/ClientState, PlacementController (rewritten), ConstructionBars*
StarterGui/MainUI     Components/UIKit (rewritten), Screens/MainMenu*, SlotScreen, CreateStateScreen, PlotScreen*, HUD, BuildMenu,
                      PlacementBar, StatsPanel*, Toast
Workspace  Map (Ocean, CentralIsland, Plots/Plot_1..6 with Exit + OwnerSign), Buildings/Plot_n, Roads/Plot_n, Vehicles, NPCs
tools/     countries.py (registry source), rojo_build.py (offline Rojo-compatible .rbxlx builder), write_configs.py
tests/     test_config, test_countries, test_structure, test_luau_static (heuristic + strict parser + undefined names),
           test_gameplay_rules, test_security, test_rojo_build
```
Changed scripts: every Luau file was reviewed; rewritten: WorldService, RoadService, BuildingService, ConstructionService, CountryService,
PopulationService, ResourceService, DataService (summary + migration), Plots, PlacementRules, RoadGraph, RoadModels, BuildingModels,
DefaultCountry, Constants, Types, ThemeConfig, UIKit, all Screens, PlacementController, ClientMain, RuntimeSelfTest.

## Plot ownership & security (server)
WorldService.claim validates index / free / one plot per player. Placement, road lines, demolish and construction use only the
requester's own plot bounds and own country records; requests are rate-limited and NaN-guarded; resources are checked server side.

## Save data (schema 2)
Country: Name, FlagId, Continent, TechnologyBranch, Treasury/Oil/Fuel/Steel/Supplies, Population, Workers, HousingCapacity,
Buildings{Id, Type, Variant, X, Z, Rotation, State, Progress, Water*/Power* fields}, Roads{RoadId, Type, Rotation, Ix, Iz, Position},
Infrastructure{Water{Stored, Production, Demand}, Power{...}, Shortage{Stage, Seconds}}, LastPlotIndex, NextBuildingId, NextRoadId.
Migration v1 -> v2: Money -> Treasury, positions x0.25 (old 8-stud layout maps exactly onto the new 2-stud grid), old road types -> Straight,
utility and infrastructure defaults filled. Nothing is ever granted.

## Tests & Verification
- `python build_war_state.py` -> 68 Python tests PASS, rojo builds `build/WarState.rbxlx` cleanly.
- Roblox Studio Play Test (Rojo 7.6.1): `[WarState SelfTest] PASS (119 checks)`, `[WarState] Server ready (16 systems)`.
- Verified live in Studio: MainMenu (3 slots) -> Create Country -> Plot Selection (6 plots) -> Claim Plot 1 -> OwnerSign billboard -> Road line drag & models -> Building placement (WaterTower & WindGenerator) -> Construction state attributes -> StatsService metrics -> Building demolish.
- Fix v0.2.1: `PlacementBar.luau` guarded against `callbacks == nil` (`callbacks = callbacks or {}`).

## Known bugs / limitations
- No DataStore session locking (last write wins). Construction advances only while the owner is online.
- Touch drag for roads also moves the camera on mobile. Wind turbines are static (no animation, by design for performance).
- Costs are defined but not charged (`Economy.ChargeCosts=false`) because no income source exists yet.
- Flags are emoji fallbacks (no verified image ids). Parallel adjacent roads merge visually (auto-connect).

## Studio checklist
Main Menu -> Create Country -> Flag -> Continent -> Technology -> Plot Selection -> Spawn -> owner panel -> Build -> Roads (hover preview,
drag, release) -> junction curbs -> building placement -> construction bar -> Water Tower -> GREEN/RED coverage -> Wind Generator ->
power coverage -> Stats -> Save -> leave -> Load (plot selection again) -> buildings/roads restored.
