# WAR STATE - PROJECT.md (LIVE)

**Version 0.3.0-phase1 · branch `warstate-v0.3` · Rojo 7.7.0 (real `rojo build` in GitHub Actions).**
Status columns: **Code** = implemented in source and covered by automated tests in CI.
**Studio** = verified in Roblox Studio Play. Studio is not available in the CI / AI build environment,
so every new item is **N/A** until it is checked in Studio (`RuntimeSelfTest` prints the result).

## Build pipeline (source of truth = GitHub)
```
GitHub push -> GitHub Actions (windows-latest)
  -> unpack rojo-7.7.0-windows-x86_64.zip (committed) + prebuild: tools/gen_static_map.py (static map sources)
  -> rojo --version (must be 7.7.0)
  -> rojo build default.project.json -o build/WarState.rbxlx      (REAL Rojo, fresh every run)
  -> tools/verify_build.py (fresh file, required instances incl. static map)
  -> python -m unittest (Python, Luau parser/names/heuristics, config, gameplay, security, static map,
     real-build XML checks via WARSTATE_ROJO_BUILD)
  -> tools/make_release_zip.py -> WarState_READY_BUILD.zip -> uploaded as workflow artifact
```
`tools/rojo_build.py` is only a structure mirror for unit tests and is **never** reported as a Rojo build.
Old build files are never committed (`build/`, `dist/`, ZIPs and the generated map are in `.gitignore`).
Local: `python build_war_state.py` (generates the map, runs tests, runs the real `rojo build`).

## Game flow
MAIN MENU (WAR STATE + 3 slots) -> CREATE COUNTRY (Name -> Continent -> Flag (195) -> Technology -> Review)
-> PLOT SELECTION (6 plots, occupied ones disabled) -> spawn on the claimed plot. No plot is ever auto-assigned.

## Feature status
| Feature | Code | Studio | Notes |
|---|---|---|---|
| 195 countries, flags, 6 continents, technology branches | IMPLEMENTED | VERIFIED (v0.2) | unchanged |
| 3 save slots (1 FREE, 2-3 LOCKED), DataStore schema 2 + migration | IMPLEMENTED | VERIFIED (v0.2) | unchanged |
| Plot selection (6 plots), server claim, owner panel (name, flag, country) | IMPLEMENTED | VERIFIED (v0.2) | panel now attached to the static `OwnerSign` |
| **Static map in the place file** (Phase 1) | IMPLEMENTED | N/A | `src/Workspace/Map/*.model.json`, serialized by real Rojo |
| Map generation on PlayerAdded / at runtime | REMOVED | - | WorldService no longer creates map geometry |
| Big central island 520x520 (was 360) | IMPLEMENTED | N/A | beach 22, plaza radius 18, lobby spawn |
| Island spacing x3 (water gap 42 -> 126 studs), plots 1/2 and 5/6 400 studs apart | IMPLEMENTED | N/A | tested in `test_static_map` |
| Real Roblox Terrain water + sand seabed | IMPLEMENTED | N/A | filled at server start (before players) in 256-stud chunks |
| Invisible boundaries (4 walls, half-size 720, water continues to 860) | IMPLEMENTED | N/A | `Transparency 1`, `CanCollide`, `CanQuery=false` |
| Trees (round + pine), bushes, rocks, trodden dirt paths, plaza | IMPLEMENTED | N/A | seeded, deterministic, avoid paths |
| Improved bridges: deck, asphalt lane, curbs, rails, posts, pillars, lamps | IMPLEMENTED | N/A | one per plot exit |
| Plot exits (exit lane, gate posts, beam) | IMPLEMENTED | N/A | geometry mirrors `Plots.getExit` |
| Small buildings, Straight Road drag build, junction curbs, demolish | IMPLEMENTED | VERIFIED (v0.2) | unchanged in Phase 1 |
| WaterService / PowerService / Stats / construction bars | IMPLEMENTED | VERIFIED (v0.2) | unchanged in Phase 1 |

## Static map (Phase 1)
* Source: `GameConfig.Map` -> `tools/gen_static_map.py` -> `src/Workspace/Map/`
  (`CentralIsland.model.json`, `Boundaries.model.json`, `Plots/Plot_1..6.model.json`, ~960 parts).
  The generator is deterministic; CI runs it before `rojo build` and `--check` guarantees the files match the config.
* Property encoding = the format verified with the real Rojo 7.7.0 probe (`tools/rojo_probe/a_map`).
* Layout: plots 1/2 at z=-464 (x=-200/200), 3 at x=-464, 4 at x=464, 5/6 at z=464. Each island = 128 plot + 14 sand rim.
  Bridges run straight from the rim to the central beach (148 studs). Exits face the central island.
* `WorldService.init` (server start): `fillTerrainWater()` (Terrain:FillBlock Sand + Water), `validateStaticMap()`
  (warns if something is missing, never rebuilds it), owner panels on `OwnerSign`. `PlayerAdded` only hooks
  `CharacterAdded` (teleport back to the owned plot).
* Placement raycasts include `Workspace.Map`; boundary walls have `CanQuery=false` so they never block the cursor.

## Architecture / files
```
ReplicatedStorage/Shared
  Config/  GameConfig (Map: Terrain, Boundary, CentralIsland, Plots, Decorations ...), PlacementConfig, RoadConfig,
           BuildingConfig, BuildMenuConfig, TechnologyConfig, CountryRegistry, ThemeConfig
  Modules/ GridMath, Plots, PlacementRules, RoadGraph, RoadModels, BuildingModels, UtilityGrid, Countries, DefaultCountry
ServerScriptService/Systems  Data, World, Resources, Roads, Buildings, Construction, Water, Power, Population, Stats,
                             Country, Research, Production, Economy, Vehicles, Military
ServerScriptService/Tests/RuntimeSelfTest (Studio only; now also checks static map + terrain water)
StarterPlayerScripts  ClientMain, Controllers/*        StarterGui/MainUI  Components/UIKit, Screens/*
Workspace  Terrain (water look), Map (static), Buildings/Plot_n, Roads/Plot_n, Vehicles/Plot_n, NPCs
tools/  gen_static_map.py, ci_unpack_rojo.py (CI prebuild), verify_build.py (+ required_build_paths.txt),
        make_release_zip.py, rojo_build.py (structure mirror for tests), countries.py, write_configs.py, rojo_probe/
tests/  test_config, test_countries, test_structure, test_luau_static, test_gameplay_rules, test_security,
        test_static_map, test_rojo_build (structure + REAL build XML)
```

## Plot ownership & security (server)
WorldService.claim validates index / free / one plot per player. Placement, road lines, demolish and construction use
only the requester's own plot bounds and own records; requests are rate-limited and NaN-guarded.

## Known limitations
* Terrain water is filled at server start (Rojo cannot serialize terrain voxels); everything else is static content.
* No DataStore session locking (last write wins). Construction advances only while the owner is online.
* Flags are emoji fallbacks (no verified image ids).

## Studio checklist (Phase 1)
Play -> Output shows `[WarState] Server ready` and `[WarState SelfTest] PASS` -> fly around: central island with trees,
bushes, rocks, dirt paths and plaza -> 6 islands with exits and lit bridges -> water is real terrain water ->
swim outward: invisible wall stops you -> create country -> claim plot -> owner panel shows name / flag / country.
