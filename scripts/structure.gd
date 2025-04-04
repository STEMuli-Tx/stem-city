extends Resource
class_name Structure

enum StructureType {
	ROAD,
	RESIDENTIAL_BUILDING,
	COMMERCIAL_BUILDING,
	INDUSTRIAL_BUILDING,
	SPECIAL_BUILDING,
	DECORATION,
	TERRAIN,
	POWER_PLANT
}


@export_subgroup("Model")
@export var model:PackedScene # Model of the structure

@export_subgroup("Gameplay")
@export var type:StructureType
@export var price:int # Price of the structure when building

@export_subgroup("Population")
@export var population_count:int = 0 # How many residents this structure adds

@export_subgroup("Electricity")
@export var kW_usage:float = 0.0 # How much electricity this structure uses
@export var kW_production:float = 0.0 # How much electricity this structure produces
