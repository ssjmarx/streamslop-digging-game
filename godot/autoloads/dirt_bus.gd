## DirtBus -- the only bus. Signals may be appended, never removed; there
## will never be a second bus. Every gameplay signal carries by_peer
## (1 = you) from day one: the v0.2 shape ships before v0.1 does.
extends Node
## The game's one communication bus (GDD §13). Future systems read DirtBus;
## nothing ever changes digging to talk to them.

# -- Signals (GDD Appendix B; append-only) ------

signal dirt_dug(amount: int, voxel_pos: Vector3i, depth: float, by_peer: int)
signal dirt_sold(amount: int, price: int, by_peer: int)
signal depth_changed(depth: float, by_peer: int)
signal player_noise(level: float, by_peer: int)
signal asset_seen(id: String)
signal surrendered(strength: int)
