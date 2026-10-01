-- Constants: remote names, build states, attribute names and status values.
-- Keep in sync with the Remotes folder in default.project.json (tests/test_structure.py checks it).

local Constants = {}

Constants.Remotes = {
	GetProfile = "GetProfile",
	CreateCountry = "CreateCountry",
	LoadSlot = "LoadSlot",
	DeleteSlot = "DeleteSlot",
	LeaveState = "LeaveState",
	SaveNow = "SaveNow",
	GetPlots = "GetPlots",
	ClaimPlot = "ClaimPlot",
	PlaceRoad = "PlaceRoad",
	PlaceRoadLine = "PlaceRoadLine",
	PlaceBuilding = "PlaceBuilding",
	Demolish = "Demolish",
	StateChanged = "StateChanged",
	PlotsChanged = "PlotsChanged",
	Notify = "Notify",
}

Constants.RemoteFunctions = {
	"GetProfile",
	"CreateCountry",
	"LoadSlot",
	"DeleteSlot",
	"LeaveState",
	"SaveNow",
	"GetPlots",
	"ClaimPlot",
	"PlaceRoad",
	"PlaceRoadLine",
	"PlaceBuilding",
	"Demolish",
}

Constants.RemoteEvents = {
	"StateChanged",
	"PlotsChanged",
	"Notify",
}

Constants.BuildState = {
	Planned = "PLANNED",
	UnderConstruction = "UNDER_CONSTRUCTION",
	Completed = "COMPLETED",
}

Constants.UtilityStatus = {
	Green = "GREEN", -- supplied
	Red = "RED", -- shortage / not supplied
	Grey = "GREY", -- not required (or not built yet)
}

Constants.ShortageStage = {
	Normal = "NORMAL",
	Warning = "WARNING",
	Prolonged = "PROLONGED_SHORTAGE",
	Problems = "POPULATION_PROBLEMS",
	Decrease = "GRADUAL_POPULATION_DECREASE",
}

Constants.ShortageOrder = {
	"NORMAL",
	"WARNING",
	"PROLONGED_SHORTAGE",
	"POPULATION_PROBLEMS",
	"GRADUAL_POPULATION_DECREASE",
}

Constants.Attributes = {
	PlotIndex = "PlotIndex",
	OwnerUserId = "OwnerUserId",
	Kind = "Kind",
	TypeId = "TypeId",
}

return Constants
