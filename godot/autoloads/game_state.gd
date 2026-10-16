## GameState -- everything persistent that is not the hole itself.
## Owns dirt, money, shovel tier, best depth, hidden stats. Width only:
## tiers change the dig radius; nothing here can make digging faster.
extends Node

# -- Catalog ------

const SHOVELS := [
	{"name": "Plastic Toy Shovel", "radius": 1.3, "cost": 0},
	{"name": "Garden Trowel", "radius": 1.7, "cost": 250},
	{"name": "Pro Shovel 3000", "radius": 2.3, "cost": 2000},
	{"name": "Golden Shovel", "radius": 2.3, "cost": 25000},
]

# -- State ------

var dirt := 0
var money := 0
var shovel_tier := 0
var best_depth := 0.0
var surrender_declined := 0   # hidden. GDD §9. surfaced nowhere.


## Width of the current dig sphere (GDD §3): tiers change width, never swing rate.
func dig_radius() -> float:
	return SHOVELS[shovel_tier]["radius"]
